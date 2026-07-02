---
name: react-native-expo
description: The ultimate architectural standard for modern React Native development utilizing the Expo framework, Continuous Native Generation (CNG), and EAS.
author: Diego Villanueva
trigger: When configuring a React Native project, managing native dependencies, setting up CI/CD pipelines with EAS, or implementing routing via Expo Router.
---

# Expo Framework & Architecture Mastery

You are building modern mobile applications. Expo is no longer just a "sandbox" for beginners; it is the definitive framework for React Native. If React Native is the React of mobile, Expo is its Next.js. You must master the managed workflow, native code generation, and cloud build services.

## 1. The Core Philosophy: Continuous Native Generation (CNG)

Gone are the days of manually tweaking Xcode (`.pbxproj`) and Android Studio (`build.gradle`) files. 

- **The `ios/` and `android/` folders are build artifacts**: You should treat them like the `node_modules` folder. You can generate them at any time by running `npx expo prebuild`.
- **Config Plugins**: If a third-party native module requires changes to `AndroidManifest.xml` or `Info.plist`, you MUST do this via Expo Config Plugins in your `app.json` or `app.config.js`. NEVER modify the native folders directly.
- **Never Eject**: "Ejecting" is a legacy concept. With Expo Prebuild and Config Plugins, there is no native code you cannot integrate into a Managed Workflow.

## 2. Custom Development Clients (`expo-dev-client`)

The standard "Expo Go" app from the App Store is only for prototyping. It cannot run custom native code (like custom C++ JSI modules, Stripe, or WebRTC).

- **Always Build a Dev Client**: Once your app needs a custom native module, install `expo-dev-client` and build a custom development app using EAS (`eas build --profile development`).
- **Local Native Compilation**: Use `npx expo run:ios` or `npx expo run:android` to compile the app locally with your custom native code, retaining the hot-reloading magic of the Expo CLI.

## 3. Expo Router (File-Based Navigation)

Expo Router brings the paradigm of Next.js to mobile apps.

- **File-System Routing**: Pages are defined by their file structure in the `app/` directory (e.g., `app/(tabs)/index.tsx`).
- **Universal Deep Linking**: Every file automatically generates a valid deep link URL. This is critical for push notifications and sharing.
- **Layouts (`_layout.tsx`)**: Use layout files to define standard UI shells (like Tab Bars or Stack Navigators) that wrap child routes.
- **API Routes**: Expo Router supports `app/api/hello+api.ts` to deploy serverless backend endpoints directly alongside your mobile code.

## 4. Expo Application Services (EAS)

EAS is the CI/CD pipeline built specifically for Expo.

- **EAS Build**: Offload your iOS and Android compilations to the cloud. Do not rely on local developer machines for production builds. Use `eas.json` to define build profiles (development, preview, production).
- **EAS Submit**: Automate pushing the compiled `.ipa` and `.aab` files directly to TestFlight and the Google Play Console.
- **EAS Update (OTA)**: Push critical bug fixes instantly to users Over-The-Air without going through App Store review processes. 
  - *Rule*: OTA updates can only change JavaScript and assets. If you add a new native library (e.g., adding `react-native-camera`), you MUST release a new binary via the App Store.

## 5. Configuration (`app.json` & `app.config.js`)

This is the single source of truth for your app's metadata.

- **Dynamic Configs**: Prefer `app.config.js` over `app.json` if you need to dynamically change the bundle identifier, app name, or icon based on environment variables (e.g., distinguishing between "MyApp (Staging)" and "MyApp").
- **Permissions**: Explicitly request permissions (Camera, Location) via config plugins here, not in native files.

```javascript
// ✅ ALWAYS: Dynamic app.config.js for environment handling
export default ({ config }) => {
  const isProd = process.env.APP_ENV === 'production';
  return {
    ...config,
    name: isProd ? 'My App' : 'My App (Staging)',
    ios: {
      bundleIdentifier: isProd ? 'com.myorg.app' : 'com.myorg.app.staging',
    },
    plugins: [
      [
        "expo-camera",
        {
          "cameraPermission": "Allow My App to access your camera for avatars."
        }
      ]
    ]
  };
};
```

## 6. Environment Variables and Secrets

- **`.env` files**: Expo automatically loads `.env` files. Variables prefixed with `EXPO_PUBLIC_` are statically injected into the JavaScript bundle at build time (like `NEXT_PUBLIC_`).
- **EAS Secrets**: Never commit sensitive API keys (like AWS access keys used in scripts) to Git. Store them in EAS Secrets (`eas secret:create`), which are injected securely during the cloud build process.

## 7. Version Management & Upgrading

Expo SDKs bundle perfectly compatible versions of React, React Native, and popular libraries.

- **`npx expo install`**: ALWAYS use this instead of `npm install` for native libraries. Expo will automatically pick the version of the library that is known to work with your current Expo SDK version.
- **`npx expo-doctor`**: Run this command to check for version mismatches or broken dependencies in your project.
- **Upgrading**: Upgrading React Native used to be a nightmare. Now, it's as simple as bumping the Expo SDK version in `package.json` and running `npx expo install --fix`.

## 8. Expo for Web

Expo allows the exact same codebase to run in the browser.

- **Universal Components**: Use standard React Native components (`View`, `Text`, `Pressable`). Expo translates them to highly optimized Web DOM elements (`div`, `span`).
- **Metro for Web**: Use the Metro bundler for web (now the default) instead of Webpack for a unified compilation pipeline and faster Hot Module Replacement (HMR).

---

**Execution Protocol**
1. **Never Touch Native Folders**: If a developer modifies `ios/Podfile` or `android/app/build.gradle` directly, the PR must be rejected. Use a Config Plugin instead.
2. **Profile-Driven Builds**: Always maintain at least three EAS build profiles: `development` (for the dev client), `preview` (for internal QA sharing), and `production` (for App Stores).
3. **Deep Linking by Default**: Every new screen created must be testable via a deep link URL in the simulator.
