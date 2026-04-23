---
description: 'Bridging JavaScript and Native Code (Swift/Kotlin)'
author: 'Diego Villanueva'
trigger: 'When implementing features that require direct access to iOS/Android APIs.'
---

# React Native Native Modules

Mastery of the bridge and modern JSI (Turbo Modules) for native integration.

## ✅ ALWAYS
- Use **Expo Modules API** for creating modern, type-safe native modules.
- Use `NativeModules` for legacy bridge-based communication.
- Define clear TypeScript interfaces for all native methods.
- Handle native errors and exceptions gracefully on the JS side.
- Use `EventEmitter` for native-to-JS communication.

## ❌ NEVER
- Write native code when an existing high-quality community library exists.
- Block the native main thread with long-running JS callbacks.
- Pass massive amounts of data through the bridge; use JSI/MMKV for fast data sharing.

## 🛠 Patterns
- **Turbo Modules**: Implementing the new architecture for synchronous native calls.
- **Native UI Components**: Creating custom native views and exposing them to React.
