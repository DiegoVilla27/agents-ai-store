---
name: rxjs-advanced
description: The ultimate architectural standard for Enterprise RxJS Higher-Order Mapping Operators (switchMap vs exhaustMap), shareReplay, catchError isolation, and takeUntilDestroyed.
author: Diego Villanueva
trigger: When handling complex asynchronous streams, preventing race conditions, managing WebSockets, or chaining HTTP requests.
---

# Enterprise RxJS Architecture

In modern Angular (v17+), **Signals** handle synchronous UI state. **RxJS** is reserved for what it does best: orchestrating asynchronous events over time, handling race conditions, and composing complex async workflows.

## 1. The Pyramid of Doom (Nested Subscriptions)

The most common sign of a junior developer is subscribing to an Observable, and inside that `.subscribe()`, making another HTTP request and subscribing again.

**❌ NEVER** nest `.subscribe()` blocks. This causes memory leaks and race conditions.
**✅ ALWAYS** use Higher-Order Mapping Operators to flatten the stream.

```typescript
// ❌ NEVER DO THIS (The Pyramid of Doom)
this.userService.getUser().subscribe(user => {
  this.orderService.getOrders(user.id).subscribe(orders => {
    console.log(orders);
  });
});

// ✅ ALWAYS DO THIS (Flattened Stream)
this.userService.getUser().pipe(
  switchMap(user => this.orderService.getOrders(user.id))
).subscribe(orders => console.log(orders));
```

## 2. The Four Horsemen (Higher-Order Mapping)

You must master the difference between the four mapping operators. Using the wrong one will cause catastrophic bugs.

### A. `switchMap` (The Canceller)
**Use case**: Search inputs, Autocomplete.
If a new event arrives, `switchMap` **cancels** the previous HTTP request. If the user types "A", then "B", the request for "A" is aborted in the browser's Network tab.

### B. `exhaustMap` (The Ignorer)
**Use case**: Login buttons, Form submissions.
If a request is currently pending, `exhaustMap` **ignores** all new events until the current request finishes. If the user mashes the "Submit" button 10 times, only 1 HTTP request goes out.

### C. `concatMap` (The Queue)
**Use case**: Saving items in order, strict sequences.
If 5 events arrive at once, `concatMap` executes them strictly one by one. The second request won't start until the first one completes.

### D. `mergeMap` (The Parallelizer)
**Use case**: Uploading multiple files independently.
Executes all inner Observables immediately in parallel.

## 3. Error Handling (`catchError`)

Where you place `catchError` dictates whether the stream survives or dies.

**❌ NEVER** place `catchError` at the top level of a long-living stream (like a Search Input) unless you intend for the stream to die permanently on the first error.
**✅ ALWAYS** isolate errors inside the inner Observable so the outer stream survives.

```typescript
// ✅ ALWAYS: Catch errors inside the switchMap
readonly search$ = this.searchInput$.pipe(
  switchMap(query => 
    this.http.get(`/api/search?q=${query}`).pipe(
      // If the API fails, we return an empty array.
      // The outer searchInput$ stream stays ALIVE, so the user can type again!
      catchError(error => {
        console.error('Search failed', error);
        return of([]); 
      })
    )
  )
);
```

## 4. Preventing Memory Leaks

Every time you call `.subscribe()`, you create a memory leak unless you unsubscribe.

**❌ NEVER** use `ngOnDestroy` with an array of `Subscription` objects. It is unnecessary boilerplate.
**✅ ALWAYS** use `takeUntilDestroyed()` or avoid `.subscribe()` entirely by using `toSignal()` or the `AsyncPipe`.

```typescript
import { Component, DestroyRef, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { interval } from 'rxjs';

export class TimerComponent {
  constructor() {
    interval(1000).pipe(
      // ✅ Automatically unsubscribes when this component is destroyed
      takeUntilDestroyed() 
    ).subscribe(console.log);
  }
}
```
*(Note: If you use `takeUntilDestroyed` outside the `constructor`, you MUST pass the `DestroyRef`: `takeUntilDestroyed(this.destroyRef)`).*

## 5. Caching and Multicasting (`shareReplay`)

By default, Observables are **Cold**. This means if you have 3 components subscribing to the same `http.get()` stream, Angular will execute **3 separate network requests**.

**✅ ALWAYS** use `shareReplay(1)` when you want to cache the HTTP response in memory and share it with multiple subscribers.

```typescript
import { shareReplay } from 'rxjs/operators';

export class ConfigService {
  // 1. We define the HTTP call
  // 2. We add shareReplay(1)
  // 3. The first subscriber triggers the HTTP request.
  // 4. Any future subscribers will instantly receive the cached response.
  readonly config$ = this.http.get('/api/config').pipe(
    shareReplay(1) 
  );
}
```

---

**Execution Protocol**
1. **CombineLatest vs ForkJoin**: Use `combineLatest` when you have multiple streams that emit *over time* and you need the latest value of all of them (e.g., Filtering a table). Use `forkJoin` when you have multiple HTTP requests (that complete) and you want to wait for ALL of them to finish in parallel before proceeding.
2. **BehaviorSubject vs Signal**: If you are using a `BehaviorSubject` just to store `{ name: 'Diego' }` and display it in the HTML, you are doing it wrong. Replace it with `signal()`.
3. **FromEvent**: For advanced DOM events (like Canvas drawing or Drag-and-Drop), use `fromEvent(document, 'mousemove')` combined with `takeUntil(mouseUp$)` rather than manually tracking coordinates in variables.
