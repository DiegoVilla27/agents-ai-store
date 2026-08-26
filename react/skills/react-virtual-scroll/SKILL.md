---
name: react-virtual-scroll
description: The ultimate architectural standard for Virtual Scrolling in React with @tanstack/react-virtual, Massive List/Grid/Table rendering at 120 FPS, and Dynamic Sizing.
author: Diego Villanueva
trigger: When rendering massive datasets, handling infinite virtual lists, optimizing large tables/grids, or preventing DOM node explosion in React.
---

# Enterprise React Virtual Scrolling Architecture

Rendering thousands of DOM nodes causes memory bloat, browser garbage collection pauses, and scroll jank. With **`@tanstack/react-virtual`**, React applications maintain a fixed, lightweight DOM footprint while seamlessly displaying 100,000+ items at a steady 60/120 FPS.

---

## 1. Fixed-Size Virtual List Implementation

```bash
npm install @tanstack/react-virtual
```

```tsx
import { useRef } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';

interface Transaction {
  id: string;
  description: string;
  amount: number;
  date: string;
}

export function VirtualTransactionList({ transactions }: { transactions: Transaction[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  // Initialize the virtualizer
  const rowVirtualizer = useVirtualizer({
    count: transactions.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 64, // Estimated row height in pixels
    overscan: 5,            // Render 5 items above and below visible area for smooth scrolling
  });

  return (
    <div
      ref={parentRef}
      className="h-[600px] w-full overflow-auto border rounded-lg bg-white shadow-sm"
    >
      <div
        style={{
          height: `${rowVirtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {rowVirtualizer.getVirtualItems().map((virtualRow) => {
          const item = transactions[virtualRow.index];
          return (
            <div
              key={item.id}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: `${virtualRow.size}px`,
                transform: `translateY(${virtualRow.start}px)`,
              }}
              className="flex items-center justify-between px-6 border-b hover:bg-gray-50 transition-colors"
            >
              <div>
                <p className="font-medium text-gray-900">{item.description}</p>
                <p className="text-xs text-gray-500">{item.date}</p>
              </div>
              <span className={`font-semibold ${item.amount < 0 ? 'text-red-600' : 'text-emerald-600'}`}>
                ${item.amount.toFixed(2)}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

---

## 2. Dynamic Height Virtual List (Auto-Measuring)

When items have varying heights (e.g. social media posts, comments with text expansion):

```tsx
import { useRef } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';

export function DynamicPostFeed({ posts }: { posts: { id: string; content: string }[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: posts.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 120, // Default baseline height
  });

  return (
    <div ref={parentRef} className="h-[700px] overflow-auto">
      <div style={{ height: `${virtualizer.getTotalSize()}px`, width: '100%', position: 'relative' }}>
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            data-index={virtualItem.index}
            ref={virtualizer.measureElement} // Measures real DOM height dynamically!
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              transform: `translateY(${virtualItem.start}px)`,
            }}
            className="p-4 border-b"
          >
            <p>{posts[virtualItem.index].content}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## 3. Infinite Virtual Scroll with TanStack Query

Combine `@tanstack/react-virtual` with `useInfiniteQuery`:

```tsx
export function InfiniteFeed() {
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = useInfiniteQuery({
    queryKey: ['feed'],
    queryFn: ({ pageParam = 1 }) => fetchFeedPage(pageParam),
    getNextPageParam: (lastPage) => lastPage.nextPage,
    initialPageParam: 1,
  });

  const allRows = data ? data.pages.flatMap((page) => page.items) : [];
  const parentRef = useRef<HTMLDivElement>(null);

  const rowVirtualizer = useVirtualizer({
    count: hasNextPage ? allRows.length + 1 : allRows.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 80,
  });

  const [lastItem] = [...rowVirtualizer.getVirtualItems()].reverse();

  if (lastItem && lastItem.index >= allRows.length - 1 && hasNextPage && !isFetchingNextPage) {
    fetchNextPage(); // Trigger next page load automatically
  }

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      {/* Virtual render layout */}
    </div>
  );
}
```

---

**Execution Protocol**
1. **Always use `transform: translateY(start)` for item positioning**: Far superior in performance to animating `top`.
2. **Always set `overscan` (3-5 items)**: Prevents white flash artifacts during rapid scrolling.
3. **Use `ref={virtualizer.measureElement}` on dynamic items**: Guarantees accurate layout recalculation for variable text lengths.
4. **Never render flat lists > 100 items without virtualization**: Protects low-end mobile devices from crashing.
