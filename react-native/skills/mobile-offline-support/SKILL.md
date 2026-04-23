---
description: 'High-Performance Persistence and Offline-First Architecture'
author: 'Diego Villanueva'
trigger: 'When implementing local storage, offline data sync, or caching.'
---

# Mobile Offline-First

Mastery of local persistence and sync strategies for reliable mobile apps.

## ✅ ALWAYS
- Use **react-native-mmkv** for ultra-fast key-value storage.
- Use **WatermelonDB** or **SQLite** for large, relational datasets.
- Implement the **Repository Pattern** to abstract data sourcing.
- Use `NetInfo` to detect connectivity changes and queue offline mutations.
- Implement "Optimistic UI" to keep the app responsive without a network.

## ❌ NEVER
- Use `AsyncStorage` for high-frequency or large data operations (it is slow and serial).
- Sync the entire database on every app launch; use delta/incremental sync.
- Store sensitive data in plaintext; use `react-native-keychain` or `expo-secure-store`.

## 🛠 Patterns
- **Sync Orchestrator**: A centralized service for reconciliation between local and remote state.
- **Cache TTL**: Managing the lifecycle of local data to avoid staleness.
