---
description: 'Optimizing Build and Development Performance with Vite'
author: 'Diego Villanueva'
trigger: 'When configuring build pipelines, bundle splitting, or optimizing HMR speed.'
---

# Vite + React Optimization

Maximizing performance in the development and production lifecycle.

## ✅ ALWAYS
- Use **Code Splitting** via `React.lazy()` and dynamic `import()`.
- Configure `manualChunks` in `vite.config.ts` to separate large dependencies (e.g., vendor bundle).
- Use `vite-plugin-image-optimizer` to compress assets at build time.
- Implement **Prefetching/Preloading** for critical chunks.
- Use `plugin-react-swc` for the fastest HMR and compilation.

## ❌ NEVER
- Import large libraries (Lodash, Moment) without tree-shaking or alternatives (date-fns).
- Ship source maps to production unless required for debugging.
- Ignore the bundle size analysis; use `rollup-plugin-visualizer`.

## 🛠 Patterns
- **Library Splitting**: Separating UI components from business logic chunks.
- **Dynamic Imports**: Loading "heavy" features only when the user interacts with them.
