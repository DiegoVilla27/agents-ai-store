---
name: flutter-offline-sync-drift
description: The ultimate architectural standard for Offline-First Flutter Apps with Drift (Reactive Type-Safe SQLite), Outbox Sync Queues, and Conflict Resolution.
author: Diego Villanueva
trigger: When building offline-first Flutter architectures, using Drift/SQLite for local persistence, implementing outbox sync engines, or resolving data conflicts.
---

# Enterprise Flutter Offline-First Architecture (Drift & SQLite)

Mobile applications must provide instantaneous response times regardless of network reliability. **Offline-First** means local SQLite persistence (via **Drift**) acts as the single immediate source of truth, while a background **Outbox Sync Engine** synchronizes mutations with the remote backend.

---

## 1. Schema Definition with Drift (`drift`)

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.18.0
  drift_flutter: ^0.1.0

dev_dependencies:
  drift_dev: ^2.18.0
  build_runner: ^2.4.0
```

```dart
// core/database/tables/tasks_table.dart
import 'package:drift/drift.dart';

class Tasks extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()(); // Epoch milliseconds
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class OutboxMutations extends Table {
  TextColumn get id => text()();
  TextColumn get entityName => text()(); // e.g. 'tasks'
  TextColumn get operation => text()();  // 'INSERT', 'UPDATE', 'DELETE'
  TextColumn get payloadJson => text()();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// core/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, OutboxMutations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'enterprise_app_db');
  }

  // Reactive Stream Query for UI
  Stream<List<Task>> watchAllTasks() {
    return (select(tasks)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }
}
```

---

## 2. Optimistic UI Mutations & Outbox Enqueueing

```dart
// features/tasks/repositories/task_repository_impl.dart
class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;
  final ApiClient _api;
  final SyncEngine _syncEngine;

  TaskRepositoryImpl(this._db, this._api, this._syncEngine);

  @override
  Future<void> createTask(String title, String description) async {
    final taskId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final taskCompanion = TasksCompanion.insert(
      id: taskId,
      title: title,
      description: Value(description),
      updatedAt: now,
      isSynced: const Value(false), // Mark as pending sync
    );

    // 1. Write immediately to local SQLite (UI updates instantly via Drift Stream!)
    await _db.into(_db.tasks).insert(taskCompanion);

    // 2. Enqueue in Outbox
    await _db.into(_db.outboxMutations).insert(
      OutboxMutationsCompanion.insert(
        id: const Uuid().v4(),
        entityName: 'tasks',
        operation: 'INSERT',
        payloadJson: jsonEncode({'id': taskId, 'title': title, 'description': description}),
        createdAt: now,
      ),
    );

    // 3. Trigger sync engine in background
    _syncEngine.triggerSync();
  }
}
```

---

## 3. Background Sync Engine

```dart
// core/sync/sync_engine.dart
class SyncEngine {
  final AppDatabase _db;
  final ApiClient _api;
  bool _isSyncing = false;

  SyncEngine(this._db, this._api);

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await (_db.select(_db.outboxMutations)
            ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
          .get();

      for (final mutation in pending) {
        try {
          await _dispatchToServer(mutation);
          // Delete from outbox on successful server ack
          await (_db.delete(_db.outboxMutations)..where((m) => m.id.equals(mutation.id))).go();
        } catch (e) {
          // Increment retry count
          await (_db.update(_db.outboxMutations)..where((m) => m.id.equals(mutation.id))).write(
            OutboxMutationsCompanion(retryCount: Value(mutation.retryCount + 1)),
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _dispatchToServer(OutboxMutation mutation) async {
    final data = jsonDecode(mutation.payloadJson);
    if (mutation.operation == 'INSERT') {
      await _api.post('/api/tasks', data);
    }
  }
}
```

---

## 4. Consuming Drift Streams in Riverpod

```dart
@riverpod
Stream<List<Task>> taskList(TaskListRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllTasks(); // Automatically emits on any DB change!
}
```

---

**Execution Protocol**
1. **Always read UI state from Drift reactive streams (`.watch()`)**: Guarantees zero-latency optimistic updates.
2. **Never send mutations directly to remote APIs without local outbox queueing**: Prevents data loss during network drops.
3. **Handle schema migrations explicitly**: Implement `MigrationStrategy` in Drift when modifying tables.
4. **Use Last-Write-Wins (LWW) with server timestamps for conflict resolution**: Keep synchronization deterministic.
