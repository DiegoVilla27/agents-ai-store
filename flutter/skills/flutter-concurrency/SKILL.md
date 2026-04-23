---
description: 'Multithreading and Background Processing with Isolates'
author: 'Diego Villanueva'
trigger: 'When performing heavy computations, file processing, or high-frequency tasks.'
---

# Flutter Concurrency & Isolates

Leveraging Flutter's isolate-based concurrency model for responsive applications.

## ✅ ALWAYS
- Use `compute()` for one-off heavy tasks (parsing, image processing).
- Create long-lived `Isolates` for continuous background work.
- Communicate between isolates using `SendPort` and `ReceivePort`.
- Offload any operation that takes more than 16ms to a separate isolate.
- Use `Future.wait` for parallel independent async operations.

## ❌ NEVER
- Attempt to access UI or `BuildContext` from a separate isolate.
- Share mutable memory between isolates (Isolates share nothing).
- Block the main isolate with long-running loops or calculations.

## 🛠 Patterns
- **Worker Pool**: Managing multiple isolates for parallel task execution.
- **Background Fetch**: Syncing data while the app is in the background.
