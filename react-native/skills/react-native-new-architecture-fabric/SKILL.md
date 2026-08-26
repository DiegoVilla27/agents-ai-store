---
name: react-native-new-architecture-fabric
description: The ultimate architectural standard for React Native New Architecture with Fabric Renderer, TurboModules, C++ JSI direct calls, and Bridgeless Mode (RN 0.76+).
author: Diego Villanueva
trigger: When developing with the React Native New Architecture, configuring Fabric native components, writing TurboModules with JSI, or migrating to Bridgeless mode in RN 0.76+.
---

# Enterprise React Native New Architecture (Fabric & TurboModules)

React Native's legacy architecture relied on an asynchronous JSON bridge across the JavaScript thread and the Native Main thread, causing serialization overhead and dropped frames. The **New Architecture (Fabric & TurboModules)** replaces the bridge with direct synchronous **C++ JavaScript Interface (JSI)** memory bindings.

---

## 1. Enabling New Architecture in Expo & React Native

In React Native 0.76+ / Expo SDK 52+, the New Architecture is enabled by default.

```json
// app.json (Expo SDK 52+)
{
  "expo": {
    "name": "EnterpriseApp",
    "slug": "enterprise-app",
    "newArchEnabled": true,
    "ios": {
      "supportsTablet": true
    },
    "android": {
      "newArchEnabled": true
    }
  }
}
```

---

## 2. Fabric Native Component Architecture (Codegen Spec)

Fabric components render UI with native thread-safe layout algorithms and zero bridge serialization.

### TypeScript Spec Definition (`NativeCustomCanvasView.ts`):

```typescript
// src/native-components/NativeCustomCanvasView.ts
import type { ViewProps } from 'react-native';
import type { DirectEventHandler, Double } from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export interface OnDrawEvent {
  canvasWidth: Double;
  canvasHeight: Double;
}

export interface NativeProps extends ViewProps {
  brushColor?: string;
  strokeWidth?: Double;
  onDrawCompleted?: DirectEventHandler<OnDrawEvent>;
}

export default codegenNativeComponent<NativeProps>('NativeCustomCanvasView');
```

---

## 3. TurboModules with C++ JSI (Direct Synchronous Memory Access)

Unlike legacy modules that had to be asynchronous promises over the bridge, TurboModules can execute synchronous native calculations with zero serialization cost via JSI.

### TypeScript Spec (`NativeCryptoEngine.ts`):

```typescript
// src/native-modules/NativeCryptoEngine.ts
import { TurboModule, TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  // Synchronous C++ native cryptographic hash calculation!
  hashFastSha256(input: string): string;
  
  // Asynchronous hardware key generation
  generateSecureKey(keyAlias: string): Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCryptoEngine');
```

### Consuming in App:

```typescript
import NativeCryptoEngine from '@/native-modules/NativeCryptoEngine';

export function hashSensitivePayload(payload: string): string {
  // Instant synchronous execution on C++ native layer
  return NativeCryptoEngine.hashFastSha256(payload);
}
```

---

## 4. Bridgeless Mode Benefits & Rules

1. **Synchronous Layout & Painting**: Layout calculations happen synchronously during render passes, eliminating layout pop-in.
2. **Concurrent React 19 Integration**: Native views support React 19 concurrent features (`startTransition`, `useDeferredValue`).
3. **No Global JS Context Pollution**: Native modules are lazily initialized only when requested via JSI lookup.

---

**Execution Protocol**
1. **Never use legacy `NativeModules.MyModule`**: Always declare typed specs with `TurboModuleRegistry.getEnforcing<Spec>()`.
2. **Always define Codegen specs for native UI views**: Run `npx react-native codegen` or `npx expo prebuild` to generate C++ bridges automatically.
3. **Audit third-party libraries for New Architecture compatibility**: Ensure all native dependencies support Fabric/TurboModules.
