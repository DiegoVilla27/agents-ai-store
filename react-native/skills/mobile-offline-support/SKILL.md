---
name: mobile-offline-support
description: The ultimate architectural standard for high-performance offline-first development, local persistence, and sync reconciliation in React Native.
author: Diego Villanueva
trigger: When implementing local databases, caching layers, offline sync engines, or selecting storage solutions in React Native.
---

# Mobile Offline-First Architecture

You are the architect of a seamless mobile experience. A mobile app that stops working when the user enters a subway tunnel is a broken app. Offline-first does not mean "works offline"; it means the **local database is the primary source of truth**, and the network is merely an asynchronous synchronization mechanism.

## 1. Storage Selection (The Right Tool for the Job)

The React Native bridge is a bottleneck. Serializing/deserializing massive JSON strings blocks the JS thread and drops frames. Choose your persistence layer aggressively.

- **Key-Value Store**: Use **`react-native-mmkv`**. It is synchronous, written in C++, and exponentially faster than `AsyncStorage`.
- **Relational / High-Volume Data**: Use **WatermelonDB**, **react-native-quick-sqlite**, or **PowerSync**. These utilize JSI (JavaScript Interface) to bypass the bridge entirely. WatermelonDB natively supports lazy-loading, ensuring your app boots instantly even with 100,000 records.
- **NEVER use `AsyncStorage`**: It is slow, asynchronous, serializes everything to strings, and is deprecated in modern high-performance architectures.

## 2. Security & Sensitive Data

Never store JWT tokens, PII, or API keys in plain text databases.

- **Secure Storage**: Use `react-native-keychain` or `expo-secure-store` to store authentication tokens in the iOS Keychain and Android Keystore.
- **Encrypted Databases**: If your entire MMKV or SQLite database contains sensitive health or financial data, configure them with encryption keys generated and stored securely in the Keychain.

## 3. The Repository Pattern

Never query the network or the local database directly from a React component. Abstract data sourcing through a Repository.

```typescript
// ✅ ALWAYS: Abstract the data source
class UserRepository {
  async getUser(id: string): Promise<User> {
    // 1. Try local cache first (instant)
    const localUser = await LocalDB.users.find(id);
    if (localUser) return localUser;

    // 2. Fallback to network if missing
    const remoteUser = await API.fetchUser(id);
    await LocalDB.users.save(remoteUser); // Persist
    return remoteUser;
  }
}
```

## 4. The Sync Engine (Delta & Incremental Sync)

Syncing the entire database on every app launch will kill the user's data plan and battery.

- **Watermarks (Last Sync At)**: The client must keep track of the exact timestamp it last successfully synced.
- **Delta Sync (Pull)**: The client asks the server: "Give me all records where `updated_at > last_sync_at`".
- **Soft Deletes**: Never physically `DELETE` rows on the server if clients sync locally. Set an `is_deleted = true` flag (tombstones) so the client knows to delete it locally during the next sync.

## 5. The Outbox Pattern (Mutation Queues)

When the user is offline and performs an action (e.g., "Like a post", "Create an order"), the app must not block them.

1. **Write Locally**: Immediately save the mutation to the local database.
2. **Optimistic UI**: Update the UI immediately based on the local write.
3. **Queue the Action**: Push a serialized job (e.g., `{ type: 'CREATE_ORDER', payload: orderData }`) to an Outbox table.
4. **Flush the Outbox**: When `NetInfo` detects connectivity, a background worker processes the outbox sequentially.

## 6. Idempotency (Preventing Duplicate Data)

Network requests can fail *after* the server processes them but *before* the client receives the response. If the client retries the Outbox queue, it might create a duplicate record.

- **Client-Generated IDs**: Always generate IDs (UUIDv4) on the client, not the server.
- **Idempotency Keys**: Send the UUID to the server. If the server sees a `POST /orders` with an `Idempotency-Key` it has already processed, it ignores the creation and simply returns the previous 200 OK success response.

## 7. Conflict Resolution

If a user modifies a record offline, and someone else modifies it online, a conflict occurs when the app regains connectivity.

- **Last-Write-Wins (LWW)**: The simplest approach. The server compares timestamps and accepts the most recent modification.
- **Server-Authoritative**: The server rejects the client's outdated mutation and forces the client to download the server's version.
- **CRDTs (Conflict-free Replicated Data Types)**: (Advanced) Data structures that merge mathematically without conflicts. Use if building collaborative apps (like Figma or Notion).

## 8. Network Awareness & Resilience

- **`@react-native-community/netinfo`**: Listen for connectivity changes. Do NOT blindly trust it (a device can have WiFi but no internet). Always implement timeout and retry logic on your `fetch` calls.
- **Exponential Backoff**: When the outbox fails to sync, do not retry every second. Retry after 2s, then 4s, 8s, 16s, up to a maximum cap, to avoid DDOSing your own server.

## 9. Modern Caching (TanStack Query / Zustand)

If you don't need a full SQLite relational database, use specialized caching layers.

- **TanStack Query (React Query)**: Use `persistQueryClient` with the MMKV persister. This automatically caches all your GET requests offline and handles background refetching (stale-while-revalidate) flawlessly.
- **Zustand Persist**: For global app state (e.g., User Preferences, Theme), use Zustand's `persist` middleware backed by MMKV.

---

**Execution Protocol**
1. **Zero Loading Spinners on Boot**: The app must render useful cached data instantly on boot, then fetch fresh data silently in the background.
2. **Offline-Testing Mandatory**: Developers must test every new feature con la red del simulador iOS/Android APAGADA para verificar la degradación elegante.
3. **Storage Limits**: Implement an eviction strategy (LRU cache) or TTL (Time To Live). Do not allow the local SQLite database to grow infinitely and consume all device storage.
