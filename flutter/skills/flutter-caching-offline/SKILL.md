---
description: 'Offline-First Development and Local Persistence'
author: 'Diego Villanueva'
trigger: 'When implementing offline support, local databases, or image caching.'
---

# Flutter Caching & Offline-First

Strategies for data persistence and offline reliability.

## ✅ ALWAYS
- Use the **Repository Pattern** to abstract data sourcing (local vs remote).
- Implement `cached_network_image` for efficient media loading.
- Use `Hive` or `Isar` for lightweight, high-performance NoSQL local storage.
- Implement "Optimistic Updates" in the UI while syncing data.
- Handle "No Internet" scenarios with clear UI feedback.

## ❌ NEVER
- Block the UI thread with synchronous database operations.
- Store sensitive data in plaintext; use `flutter_secure_storage`.
- Sync massive datasets at once; implement pagination and delta updates.

## 🛠 Patterns
- **Sync Managers**: Orchestrators for local-remote reconciliation.
- **Cache Policy**: Defined TTL (Time To Live) for specific data types.
