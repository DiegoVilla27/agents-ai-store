---
name: ionic-storage
description: The ultimate architectural standard for Data Persistence in Ionic with @ionic/storage, Capacitor Preferences, SQLite, and Encryption Strategies.
author: Diego Villanueva
trigger: When implementing local data persistence, key-value storage, database operations, or managing cached data in an Ionic/Capacitor app.
---

# Enterprise Ionic Storage Architecture

Mobile apps MUST work offline, persist user preferences, and cache data efficiently. Ionic provides multiple storage tiers depending on data size and sensitivity.

## 1. Storage Tier Matrix

| Tier | Technology | Use Case | Data Size | Encrypted? |
|---|---|---|---|---|
| **Preferences** | `@capacitor/preferences` | Settings, flags, small config | < 1KB per key | ❌ |
| **Key-Value** | `@ionic/storage` (with SQLite driver) | Cached API responses, user data | < 10MB | Optional |
| **Relational** | `@capacitor-community/sqlite` | Complex queries, large datasets | Unlimited | ✅ |
| **Secure** | `@capacitor-community/secure-storage` | JWT tokens, API keys, PII | < 1KB per key | ✅ (Keychain/Keystore) |
| **Files** | `@capacitor/filesystem` | Images, documents, exports | Unlimited | ❌ |

## 2. @capacitor/preferences (Simple Key-Value)

For small, non-sensitive settings like "has seen onboarding" or "preferred language".

```typescript
// core/services/preferences.service.ts
import { Injectable } from '@angular/core';
import { Preferences } from '@capacitor/preferences';

@Injectable({ providedIn: 'root' })
export class PreferencesService {
  async get<T>(key: string): Promise<T | null> {
    const { value } = await Preferences.get({ key });
    return value ? JSON.parse(value) : null;
  }

  async set(key: string, value: unknown): Promise<void> {
    await Preferences.set({ key, value: JSON.stringify(value) });
  }

  async remove(key: string): Promise<void> {
    await Preferences.remove({ key });
  }

  async clear(): Promise<void> {
    await Preferences.clear();
  }
}
```

## 3. @ionic/storage (Recommended Default)

`@ionic/storage` provides a unified key-value API with pluggable drivers. On native, use the SQLite driver for reliability.

```bash
npm install @ionic/storage @ionic/storage-angular
# For native SQLite backend (recommended):
npm install cordova-sqlite-storage localforage-cordovasqlitedriver
```

```typescript
// core/services/storage.service.ts
import { Injectable } from '@angular/core';
import { Storage } from '@ionic/storage-angular';
import * as CordovaSQLiteDriver from 'localforage-cordovasqlitedriver';

@Injectable({ providedIn: 'root' })
export class StorageService {
  private storage: Storage | null = null;

  constructor(private readonly storageEngine: Storage) {}

  async init(): Promise<void> {
    if (this.storage) return;
    
    // Define driver order: SQLite (native) → IndexedDB (web) → localStorage (fallback)
    await this.storageEngine.defineDriver(CordovaSQLiteDriver);
    this.storage = await this.storageEngine.create();
  }

  async get<T>(key: string): Promise<T | null> {
    await this.init();
    return this.storage!.get(key);
  }

  async set(key: string, value: unknown): Promise<void> {
    await this.init();
    await this.storage!.set(key, value);
  }

  async remove(key: string): Promise<void> {
    await this.init();
    await this.storage!.remove(key);
  }

  async keys(): Promise<string[]> {
    await this.init();
    return this.storage!.keys();
  }

  async clear(): Promise<void> {
    await this.init();
    await this.storage!.clear();
  }
}
```

## 4. Cached Repository Pattern

Create a generic caching layer that wraps API calls with automatic storage fallback:

```typescript
// core/services/cached-repository.service.ts
@Injectable({ providedIn: 'root' })
export class CachedRepository {
  private readonly storage = inject(StorageService);

  async fetchWithCache<T>(
    key: string,
    apiFn: () => Observable<T>,
    ttlMinutes = 15
  ): Promise<T> {
    // 1. Check cache first
    const cached = await this.storage.get<{ data: T; timestamp: number }>(key);

    if (cached) {
      const age = (Date.now() - cached.timestamp) / 60000;
      if (age < ttlMinutes) return cached.data; // Cache hit
    }

    // 2. Fetch from API
    try {
      const data = await firstValueFrom(apiFn());
      await this.storage.set(key, { data, timestamp: Date.now() });
      return data;
    } catch (error) {
      // 3. Offline fallback: return stale cache
      if (cached) return cached.data;
      throw error;
    }
  }

  async invalidate(key: string): Promise<void> {
    await this.storage.remove(key);
  }
}
```

## 5. Secure Storage (Tokens & Secrets)

**❌ NEVER** store sensitive data in `@ionic/storage`, `localStorage`, or `@capacitor/preferences`.
**✅ ALWAYS** use `@capacitor-community/secure-storage` for JWT tokens, API keys, and PII.

```typescript
// core/services/secure-storage.service.ts
import { Injectable } from '@angular/core';
import { SecureStoragePlugin } from '@capacitor-community/secure-storage';
import { Capacitor } from '@capacitor/core';

@Injectable({ providedIn: 'root' })
export class SecureStorageService {
  private readonly isNative = Capacitor.isNativePlatform();

  async set(key: string, value: string): Promise<void> {
    if (this.isNative) {
      await SecureStoragePlugin.set({ key, value });
    } else {
      // Web fallback (not truly secure — only for dev)
      sessionStorage.setItem(key, value);
    }
  }

  async get(key: string): Promise<string | null> {
    if (this.isNative) {
      try {
        const result = await SecureStoragePlugin.get({ key });
        return result.value;
      } catch {
        return null; // Key not found
      }
    }
    return sessionStorage.getItem(key);
  }

  async remove(key: string): Promise<void> {
    if (this.isNative) {
      await SecureStoragePlugin.remove({ key });
    } else {
      sessionStorage.removeItem(key);
    }
  }
}
```

---

**Execution Protocol**
1. **Choose the right storage tier**: Use the Storage Tier Matrix to pick the correct technology for each data type.
2. **Never store secrets in `localStorage`**: Use `SecureStorageService` for any sensitive data.
3. **Always implement cache-first patterns**: Mobile apps must be usable offline. Cache API responses and fall back to stale data when offline.
4. **Always initialize `@ionic/storage` with SQLite driver**: On native platforms, IndexedDB/localStorage can be wiped by the OS under memory pressure. SQLite is persistent.
5. **Always wrap storage access in services**: Never call storage APIs directly from components.
