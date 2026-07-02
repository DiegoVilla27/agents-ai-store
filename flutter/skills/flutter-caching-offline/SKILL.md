---
name: flutter-caching-offline
description: The ultimate architectural standard for Offline-First Flutter Apps The Single Source of Truth, Optimistic Updates, Isar/Drift Local Databases, and Sync Queues.
author: Diego Villanueva
trigger: When building offline support, caching APIs, choosing local databases, or implementing background sync.
---

# Flutter Caching & Offline-First Architecture

Mobile devices lose network connections constantly: riding the subway, entering an elevator, or driving through rural areas. If your app freezes on a loading spinner every time the network drops, your architecture is fundamentally flawed.

Enterprise mobile apps must be **Offline-First**. The Local Database is the Single Source of Truth. The Remote Server is merely an asynchronous synchronization mechanism.

## 1. The Single Source of Truth (The Repository Pattern)

In a poorly architected app, the UI asks the API for data, and if the API fails, it asks the local cache. **This is wrong.**

In an Offline-First app, the State Management (Riverpod/Bloc) ONLY listens to the Local Database (via Streams). The Repository fetches data from the API in the background, writes it to the Local DB, and the Local DB automatically updates the UI.

```dart
// ✅ ALWAYS: The Local DB is the Source of Truth
class ArticleRepository {
  final LocalDataSource localDb;
  final RemoteDataSource remoteApi;

  // 1. The UI subscribes to this Stream. It INSTANTLY yields cached data.
  Stream<List<Article>> watchArticles() {
    return localDb.watchArticles();
  }

  // 2. A background refresh function (called on app start or pull-to-refresh)
  Future<void> syncArticles() async {
    try {
      // Fetch fresh data from the API
      final remoteArticles = await remoteApi.fetchArticles();
      // Write it to the Local DB. 
      // Because the UI is watching the Local DB stream, it will update automatically!
      await localDb.saveArticles(remoteArticles);
    } catch (e) {
      // If offline, silently fail (or log). The UI already has the cached data.
      log('Sync failed, using offline cache: $e');
    }
  }
}
```

## 2. Choosing the Right Local Database

Do not use `SharedPreferences` for complex data or large lists. It is strictly for key-value pairs (like `theme: dark`).

- **For Extreme Performance & NoSQL**: Use **Isar**. Built by the creator of Hive, it is wildly fast, supports complex queries, and natively supports Streams (perfect for the architecture above).
- **For Relational Data & SQL**: Use **Drift** (formerly Moor). It provides type-safe SQLite and also supports Streams.

```dart
// ✅ ALWAYS: Use Isar for high-speed offline caching
@collection
class ArticleEntity {
  Id id = Isar.autoIncrement; // Isar specific ID
  
  @Index(unique: true, replace: true)
  late String serverId; // The real ID from your backend
  
  late String title;
  late String content;
  late DateTime updatedAt;
}
```

## 3. Optimistic UI Updates & The Sync Queue

When a user performs an action (e.g., "Likes a post") while completely offline, what happens?
If you wait for the API to respond, the app looks broken. You MUST use **Optimistic Updates**.

1. **Update Local**: Immediately write the "Like" to the local database. The UI updates instantly.
2. **Queue Action**: Add an object representing the action to a local "Sync Queue" table.
3. **Background Sync**: When the network returns, a background process reads the Sync Queue and fires the API calls.

```dart
// ✅ ALWAYS: Queue mutations for later sync if offline
Future<void> likeArticle(String articleId) async {
  // 1. Optimistic Update: Change local state immediately
  await localDb.incrementLike(articleId);

  // 2. Check connection
  if (await networkInfo.isConnected) {
    try {
      await remoteApi.likeArticle(articleId);
      return; // Success!
    } catch (e) {
      // API failed, fallback to queue
    }
  }

  // 3. Queue the action for later if offline or API failed
  await localDb.savePendingMutation(
    MutationEntity(
      type: 'LIKE_ARTICLE',
      payload: {'articleId': articleId},
      createdAt: DateTime.now(),
    )
  );
}
```

## 4. Background Workers (Workmanager)

To process that Sync Queue when the app is closed but the network returns, you MUST use OS-level background tasks.

```dart
// ✅ ALWAYS: Use Workmanager to sync data in the background
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "syncPendingMutations") {
      final db = await openLocalDb();
      final pendingMutations = await db.getPendingMutations();
      
      for (var mutation in pendingMutations) {
        // Fire API calls based on mutation.type
        await processMutation(mutation);
        await db.deleteMutation(mutation.id);
      }
    }
    return Future.value(true);
  });
}
```

## 5. Media Caching (Images)

Never download the same image twice. If your app has lists with avatars, you will destroy the user's data plan.

```dart
// ❌ ATROCIOUS: Downloads the image every time it scrolls into view
Image.network('https://acme.com/avatar.png');

// ✅ ALWAYS: Use cached_network_image for automatic disk caching
CachedNetworkImage(
  imageUrl: 'https://acme.com/avatar.png',
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  // Optionally define specific cache managers with TTLs (Time To Live)
);
```

---

**Execution Protocol**
1. **Security**: If your local database caches PII (Personally Identifiable Information), HIPAA data, or financial data, you MUST encrypt the database. Both Isar and Drift support 256-bit AES encryption. Store the encryption key in the device's Secure Enclave using `flutter_secure_storage`.
2. **Delta Syncs**: If you have a massive dataset (e.g., 50,000 products), never download the whole list on every app start. Your backend MUST support `last_updated` timestamps, allowing the app to request: "Give me only the products that changed since my `lastSyncDate`".
3. **Conflict Resolution**: If the user edits an article offline, but someone else edited it on the server, you need a conflict strategy. The simplest is "Last Write Wins" (based on timestamps), but enterprise apps may require "Merge" or prompting the user.
