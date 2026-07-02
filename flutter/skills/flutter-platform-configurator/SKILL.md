---
name: flutter-platform-configurator
description: The ultimate architectural protocol for the AI when modifying Native iOS (Info.plist, Podfile) and Android (AndroidManifest, Gradle) build configurations.
author: Diego Villanueva
trigger: When configuring native platform settings, fixing build errors, adding permissions (Camera, Location, Biometrics), or managing CocoaPods/Gradle.
---

# Native Platform Configurator Protocol

Flutter perfectly abstracts the UI, but it cannot abstract OS-level security, permissions, and build pipelines. When instructed to modify the `ios/` or `android/` directories, you must temporarily stop thinking as a Flutter Developer and act as a **Senior Native Engineer**.

Any mistake in these files will cause catastrophic build failures or instant rejection from the Apple App Store / Google Play Store.

## 1. iOS Configuration (`ios/`)

The two most dangerous files in a Flutter project are the `Info.plist` and the `Podfile`.

### A. The `Info.plist` (Permissions & Security)
If you add a plugin for Camera, Location, or Biometrics, you **MUST** add the corresponding `NSUsageDescription` to `ios/Runner/Info.plist`. 
If you forget this, the app will crash instantly when requesting the permission, and Apple will reject the binary.

```xml
<!-- ✅ ALWAYS: Add highly descriptive reasons for permissions -->
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to scan QR codes for inventory management.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>This app requires location access to find nearby stores while you are using the app.</string>

<key>ITSAppUsesNonExemptEncryption</key>
<false/> <!-- CRITICAL: Add this to bypass the annoying Export Compliance prompt in App Store Connect -->
```

### B. The `Podfile` (Dependency Management)
By default, Flutter sets a very low iOS deployment target. Many modern packages require iOS 12 or 13.

```ruby
# ✅ ALWAYS: Ensure the Podfile deployment target matches the Xcode project
# In ios/Podfile:
platform :ios, '13.0' # Update this if packages complain about deployment targets
```
*Note: If you change the Podfile, you must run `cd ios && pod install`.*

## 2. Android Configuration (`android/`)

Android configuration is split across `AndroidManifest.xml` and multiple `build.gradle` files.

### A. `AndroidManifest.xml`
You must declare permissions explicitly. If the app needs the internet (it always does), you must declare it.

```xml
<!-- ✅ ALWAYS: Declare required Android permissions -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    
    <application
        android:label="Enterprise App"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"> <!-- Use ONLY in dev if connecting to local HTTP servers -->
        ...
    </application>
</manifest>
```

### B. Gradle Configuration (`build.gradle`)
There are TWO `build.gradle` files. 
- `android/build.gradle` (Project level): Defines the Kotlin version and global classpath.
- `android/app/build.gradle` (App level): Defines SDK versions, application ID, and signing configs.

```groovy
// ✅ ALWAYS: Manage Android SDK versions in android/app/build.gradle
android {
    namespace "com.acme.enterprise"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.acme.enterprise"
        minSdkVersion 24 // Don't use 16 or 19. 21 or 24 is the modern standard.
        targetSdkVersion 34
    }
}
```

## 3. The "Nuclear" Clean Build Protocol

Flutter relies heavily on native caching (Gradle caches, CocoaPods caches). These caches corrupt easily when switching Git branches or upgrading Flutter versions.

If the user reports an inexplicable native build error (e.g., `Lexical or Preprocessor Issue`, `Symbol not found`, or `Gradle task failed`), you MUST execute the **Nuclear Option**.

```bash
# ✅ ALWAYS: The Ultimate Clean Script for catastrophic build failures
flutter clean
flutter pub get

# For iOS issues:
cd ios
rm -rf Pods/
rm -rf Podfile.lock
rm -rf .symlinks/
pod deintegrate
pod cache clean --all
pod install --repo-update
cd ..

# For Android issues:
cd android
./gradlew clean
cd ..
```

## 4. Keystores & Security (NEVER COMMIT)

When configuring Android for release, you will generate a `key.jks` (Java Keystore) and a `key.properties` file.

- **❌ NEVER**: Commit `key.jks` or `key.properties` to version control.
- **✅ ALWAYS**: Add `*.jks` and `key.properties` to the `.gitignore`. If an attacker gets these files, they can publish malicious updates to your app on the Google Play Store.

## 5. Proguard & Code Shrinking (Android)

When building for Android Release, R8 (Proguard) shrinks and obfuscates the Java/Kotlin code. Sometimes this accidentally deletes code needed by native plugins (especially Firebase or complex background tasks).

```groovy
// ✅ ALWAYS: Ensure Proguard is configured for release
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```
*If a release build crashes on startup but works in debug, it's a Proguard issue. Add `-keep` rules to `proguard-rules.pro`.*

---

**Execution Protocol**
1. **Never guess Native Syntax**: If you don't know the exact XML or Plist syntax, do not invent it. A single missing `</string>` in iOS will brick the entire build.
2. **Namespace vs Package**: In modern Android (AGP 8.0+), `package="com.example.app"` is removed from the `AndroidManifest.xml` and moved to `namespace "com.example.app"` in `android/app/build.gradle`. Respect this modern standard.
3. **App Icons**: Do not manually replace icon files. Use the `flutter_launcher_icons` package to auto-generate the complex matrix of iOS/Android icon resolutions.
