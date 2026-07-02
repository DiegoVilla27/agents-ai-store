---
name: vite-react-optimization
description: The ultimate architectural standard for Web Performance, Bundle Optimization, and Code Splitting in Vite + React applications.
author: Diego Villanueva
trigger: When configuring vite.config.ts, setting up routing, debugging slow load times, or optimizing the production build size.
---

# Vite & React Performance Architecture

Vite feels blindingly fast during development because it uses native ESM and esbuild. However, for production, it uses Rollup to bundle your code. If you do not configure your chunking strategy and lazy loading correctly, your users will download a massive, multi-megabyte `index-[hash].js` file on initial load, destroying your Core Web Vitals.

## 1. Route-Level Code Splitting (React.lazy)

Never import all your pages at the top of your router file. This forces the browser to download the JavaScript for the "Settings" page even if the user is just looking at the "Login" page.

```tsx
// ❌ ATROCIOUS: Downloads the entire app on initial load
import Dashboard from './pages/Dashboard';
import Settings from './pages/Settings';

// ✅ ALWAYS: Lazy load routes
import { lazy, Suspense } from 'react';
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

export function AppRouter() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

## 2. Heavy Library Splitting (Dynamic Imports)

If you have a heavy library (like `recharts`, `pdfmake`, or `three.js`) that is only used when a user clicks a specific button or opens a modal, do NOT import it at the top of the file.

```tsx
// ✅ ALWAYS: Dynamically import massive dependencies only when needed
async function downloadReport() {
  // The browser only downloads xlsx.js when the user clicks this button
  const { utils, writeFile } = await import('xlsx');
  
  const ws = utils.json_to_sheet(data);
  const wb = utils.book_new();
  writeFile(wb, "report.xlsx");
}
```

## 3. Rollup Chunking Strategy (`vite.config.ts`)

By default, Vite tries to split chunks automatically, but for enterprise apps, you must define a `manualChunks` strategy to cache long-term dependencies (like React) separately from your rapidly changing app code.

```typescript
// ✅ ALWAYS: Separate vendor code from application code
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          // Put React and React DOM into their own chunk
          if (id.includes('node_modules/react/') || id.includes('node_modules/react-dom/')) {
            return 'vendor-react';
          }
          // Put massive libraries into their own chunks
          if (id.includes('node_modules/recharts/')) {
            return 'vendor-charts';
          }
          // Group remaining node_modules
          if (id.includes('node_modules')) {
            return 'vendor';
          }
        }
      }
    }
  }
});
```

## 4. Tree Shaking & Import Hygiene

Rollup is excellent at removing dead code (Tree Shaking), but it only works if you use ES Modules.

```typescript
// ❌ ATROCIOUS: Imports the entire lodash library (70kb+)
import _ from 'lodash';
import { debounce } from 'lodash';

// ✅ ALWAYS: Use lodash-es for native ESM tree shaking (1kb)
import { debounce } from 'lodash-es';

// ✅ ALWAYS: Import exactly the icons you need
import { Activity } from 'lucide-react'; 
// (Ensure your library supports tree-shaking, otherwise use path imports: import Activity from 'lucide-react/dist/esm/icons/activity')
```

## 5. Asset Optimization (Images & Fonts)

Images and fonts are the #1 cause of slow Largest Contentful Paint (LCP).

- **WebP / AVIF**: Never serve `.png` or `.jpg` to the client. Always convert them to WebP or AVIF.
- **Vite Image Optimizer**: Use `vite-plugin-image-optimizer` to compress assets automatically during the build step.
- **Font Preloading**: If you self-host fonts, you MUST preload them in your `index.html` to prevent Flash of Unstyled Text (FOUT).

```html
<!-- ✅ ALWAYS: Preload critical fonts in index.html -->
<link rel="preload" href="/fonts/Inter-Regular.woff2" as="font" type="font/woff2" crossorigin>
```

## 6. Bundle Analysis

You cannot optimize what you cannot measure. You must regularly visualize your bundle to hunt down rogue dependencies.

- Install `rollup-plugin-visualizer`.
- Add it to your `vite.config.ts`.
- Run `npm run build`. It will generate a `stats.html` file showing a treemap of exactly what is taking up space in your JS bundle.

```typescript
// ✅ ALWAYS: Audit your bundle size
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  plugins: [
    react(),
    visualizer({
      open: true, // Automatically opens the HTML report after build
      gzipSize: true, // Shows the realistic network size
    }),
  ],
});
```

---

**Execution Protocol**
1. **Never mock performance**: If your dev server is fast but production is slow, you failed to optimize the build. Always test performance on the output of `npm run preview` (which serves the production build), never on `npm run dev`.
2. **Avoid CSS-in-JS for large apps**: Libraries like `styled-components` add JS overhead and delay rendering until the JS is parsed. Strongly prefer CSS Modules or Tailwind CSS, which Vite extracts into highly optimized, minified static `.css` files that the browser can parse instantly in parallel.
3. **Module Preload**: Vite automatically injects `<link rel="modulepreload">` for your entry chunks. Do not disable this feature unless you have a highly specific micro-frontend architecture.
