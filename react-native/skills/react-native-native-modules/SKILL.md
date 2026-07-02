---
name: react-native-native-modules
description: The ultimate architectural standard for bridging JavaScript and Native Code (Swift/Kotlin/C++) using Expo Modules, JSI, and TurboModules.
author: Diego Villanueva
trigger: When building native integrations, writing Swift/Kotlin for React Native, or wrapping native SDKs.
---

# Native Modules & JSI Architecture

React Native allows you to write JavaScript, but you are ultimately shipping a native application. When you hit the ceiling of JavaScript's capabilities—whether for performance, cryptography, or accessing proprietary device APIs (like ARKit or Bluetooth)—you must drop down to the native layer. 

This skill defines how to do so professionally, safely, and with maximum performance.

## 1. The Paradigm Shift (Expo Modules API)

The legacy React Native Bridge required writing Objective-C and Java boilerplate, and all communication was asynchronous and serialized. This is obsolete.

- **ALWAYS use the Expo Modules API** for new native modules.
- **Why?** It allows you to write pure Swift and pure Kotlin. It automatically handles type conversions between JS and Native. It is synchronous (if needed) and fully supports the New Architecture (TurboModules) out of the box.

```swift
// ✅ ALWAYS: Expo Modules API (Swift)
import ExpoModulesCore

public class MyHardwareModule: Module {
  public func definition() -> ModuleDefinition {
    Name("MyHardware")

    // Synchronous function call
    Function("getBatteryLevel") { () -> Double in
      return UIDevice.current.batteryLevel
    }

    // Asynchronous Promise
    AsyncFunction("processImage") { (path: String, promise: Promise) in
      // Heavy work in background
      DispatchQueue.global().async {
        let result = process(path)
        promise.resolve(result)
      }
    }
  }
}
```

## 2. JSI (JavaScript Interface) & High Performance

If you are building a database (like WatermelonDB) or a high-frequency sensor reader, even the Expo Modules API might have too much overhead.

- **JSI (C++)**: JSI allows JavaScript to hold references to C++ host objects. This means calling a C++ function from JS is as fast as calling a normal JS function—no JSON serialization, no bridge delays.
- **When to use JSI**: For ultra-low-latency requirements (e.g., `< 5ms` execution), large data transfers (passing MBs of image data), or sharing memory between JS and Native.

## 3. The Legacy Bridge (`NativeModules`)

If you are maintaining an older app, you will encounter the legacy bridge.

- **Asynchronous Only**: Every call across the legacy bridge is asynchronous. You cannot return a value immediately; you must use a Promise or a Callback.
- **Serialization Bottleneck**: Every argument passed across the legacy bridge is serialized to a JSON string. **NEVER pass large arrays or base64 images across the legacy bridge.** It will block the JS thread and drop frames. Write the data to a file on the native side and pass the file path (string) to JS.

## 4. Native UI Components

Sometimes you don't just need a function; you need a full native view (like a custom Video Player or a Map).

- **Expo View Modules**: Use the Expo Modules API to wrap `UIView` (iOS) or `View` (Android).
- **Props Validation**: Strongly type the props in TypeScript and define strict prop listeners on the native side to react to changes from React.

```kotlin
// ✅ ALWAYS: Native View Binding (Kotlin)
View(MyCustomVideoPlayer::class) {
  Prop("url") { view: MyCustomVideoPlayer, url: String ->
    view.loadVideo(url)
  }
  
  Events("onPlaybackFinished")
}
```

## 5. Native-to-JS Communication (Events)

When the native side needs to proactively tell JS something happened (e.g., "Bluetooth Device Found", "Download Progress 50%"), use Event Emitters.

- **Expo Modules `sendEvent`**: Declare the events in your module definition and use `sendEvent` from Swift/Kotlin.
- **Cleanup**: Always ensure that JS listeners are cleaned up (`useEffect` return) to prevent memory leaks in the React bridge.

```tsx
// ✅ ALWAYS: Strictly typed event listeners in JS
import { useEffect } from 'react';
import { useEvent } from 'expo-modules-core';
import MyHardware from './MyHardware';

export function useBluetoothScanner() {
  useEffect(() => {
    const subscription = MyHardware.addListener('onDeviceFound', (device) => {
      console.log(device.name);
    });
    
    return () => subscription.remove(); // CRITICAL
  }, []);
}
```

## 6. Threading & Blocking

The cardinal rule of native mobile development: **Never block the Main Thread (UI Thread).**

- **JS Thread**: Where React runs.
- **Main/UI Thread**: Where iOS/Android render the screen. If you run a heavy crypto function here, the entire app freezes.
- **Background Threads**: Always dispatch heavy processing to background threads (e.g., `DispatchQueue.global().async` in Swift or `CoroutineScope(Dispatchers.IO).launch` in Kotlin) before resolving the Promise back to JS.

## 7. TypeScript Safety

A native module without strict TypeScript definitions is a ticking time bomb.

- **Wrapper Layer**: Never expose the raw `NativeModules.MyModule` to the app. Create a `index.ts` file that wraps every native call, enforcing input and output types.

```typescript
// ✅ ALWAYS: Strict TypeScript Wrapper
import { NativeModules } from 'react-native';

interface ImageProcessorType {
  blurImage(path: string, radius: number): Promise<string>;
}

const ImageProcessor = NativeModules.ImageProcessor as ImageProcessorType;

export async function safelyBlurImage(path: string, radius: number): Promise<string> {
  if (radius < 0 || radius > 100) throw new Error("Radius must be 0-100");
  return await ImageProcessor.blurImage(path, radius);
}
```

---

**Execution Protocol**
1. **Prefer Community Libraries**: Before writing a native module, thoroughly research if a high-quality, actively maintained community library exists (e.g., don't write your own BLE library; use `react-native-ble-plx`).
2. **Swift & Kotlin First**: Do not write new modules in Objective-C or Java unless interfacing with a legacy SDK that strictly requires it. Modern Swift and Kotlin are safer and easier to maintain.
3. **Graceful Fallbacks**: If a native module fails or a hardware feature (like FaceID) is unavailable on the device, the native code must catch the error and cleanly reject the Promise. The JS code must have a `.catch` or `try/catch` block to handle it gracefully and inform the user.
