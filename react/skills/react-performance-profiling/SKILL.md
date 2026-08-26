---
name: react-performance-profiling
description: The ultimate architectural standard for React Performance Profiling, <Profiler> API, React DevTools Flamegraphs, Memory Leak Diagnostics, and Web Vitals.
author: Diego Villanueva
trigger: When diagnosing sluggish React UI, analyzing flamegraphs, locating memory leaks, measuring render durations, or monitoring Core Web Vitals.
---

# Enterprise React Performance Profiling & Diagnostics

Performance bottlenecks in React applications stem from unnecessary re-renders, heavy synchronous calculations during render, unbounded memory retention in closures, and layout thrashing. An Enterprise React Architect relies on rigorous profiling data rather than guesswork.

---

## 1. The React `<Profiler>` API

Measure render performance and commit times programmatically in development and staging builds:

```tsx
import { Profiler, type ProfilerOnRenderCallback } from 'react';

const onRenderCallback: ProfilerOnRenderCallback = (
  id,           // the "id" prop of the Profiler tree that has just committed
  phase,        // either "mount" (if the tree just mounted) or "update" (if it re-rendered)
  actualDuration,   // time spent rendering the committed update
  baseDuration,     // estimated time to render the entire subtree without memoization
  startTime,        // when React began rendering this update
  commitTime        // when React committed this update
) => {
  if (actualDuration > 16) { // Flag frames taking longer than 16ms (60fps budget)
    console.warn(`[Profiler Alert: ${id}] Phase: ${phase} took ${actualDuration.toFixed(2)}ms`);
    
    // Dispatch to analytics/telemetry if desired
    // reportMetric({ id, phase, actualDuration });
  }
};

export function AuditedDashboard({ children }: { children: React.ReactNode }) {
  return (
    <Profiler id="EnterpriseDashboard" onRender={onRenderCallback}>
      {children}
    </Profiler>
  );
}
```

---

## 2. Diagnosing Re-renders with React DevTools

When profiling in React DevTools (Components & Profiler tabs):

1. **Highlight Updates**: Enable "Highlight updates when components render" in DevTools settings. A component flashing green/yellow repeatedly without user interaction indicates a runaway state update.
2. **Record Why Each Component Rendered**: Enable "Record why each component rendered while profiling". DevTools will explicitly state: `"Props changed: [filter]"`, `"Hook 2 changed"`, or `"Parent component rendered"`.
3. **Flamegraph Analysis**: Look for wide yellow/orange bars. The wider the bar, the longer the component took to render.

---

## 3. Detecting Memory Leaks in Hooks

Memory leaks commonly occur when asynchronous subscriptions, event listeners, or timers outlive the component lifecycle.

```tsx
// ❌ LEAK: Missing cleanup function keeps timer and closure alive in memory
function TimerWidget() {
  useEffect(() => {
    setInterval(() => {
      console.log('Ticking...');
    }, 1000);
  }, []);
}

// ✅ ALWAYS: Return cleanup function to release memory immediately
function TimerWidget() {
  useEffect(() => {
    const id = setInterval(() => {
      console.log('Ticking...');
    }, 1000);

    return () => clearInterval(id); // Releases reference on unmount
  }, []);
}
```

### AbortController for In-Flight Fetches

```tsx
useEffect(() => {
  const controller = new AbortController();

  async function loadData() {
    try {
      const res = await fetch('/api/heavy-data', { signal: controller.signal });
      const data = await res.json();
      setData(data);
    } catch (err: any) {
      if (err.name !== 'AbortError') console.error(err);
    }
  }

  loadData();
  return () => controller.abort(); // Cancel request if component unmounts before response returns
}, []);
```

---

## 4. Measuring Web Vitals in React

```typescript
import { onCLS, onINP, onLCP } from 'web-vitals';

export function reportWebVitals(onPerfEntry?: (metric: any) => void) {
  if (onPerfEntry && onPerfEntry instanceof Function) {
    onCLS(onPerfEntry); // Cumulative Layout Shift
    onINP(onPerfEntry); // Interaction to Next Paint
    onLCP(onPerfEntry); // Largest Contentful Paint
  }
}
```

---

**Execution Protocol**
1. **Always profile production-like builds**: Development mode includes extra debugging checks that skew timing measurements.
2. **Target sub-16ms render duration**: Guarantees buttery-smooth 60fps animations and transitions.
3. **Always pair `addEventListener` / `setInterval` with cleanup**: Prevent memory retention.
4. **Use AbortController for async network tasks**: Cleanly aborts work on unmount.
