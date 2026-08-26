---
name: web-monorepo-turborepo-nx
description: The ultimate architectural standard for Enterprise Monorepo Orchestration with Turborepo & Nx, Workspace Package Topologies, Pipeline Task Graphs, and Remote Caching.
author: Diego Villanueva
trigger: When configuring monorepos, setting up Turborepo (turbo.json) or Nx, managing multi-package workspaces (pnpm/npm/yarn workspaces), or optimizing monorepo CI pipelines.
---

# Enterprise Monorepo Architecture (Turborepo & Nx)

Enterprise engineering teams manage multiple interconnected applications (Web, Mobile, Admin Portal, Backend API) and shared libraries (UI kit, DB client, TypeScript configs, ESLint rules) inside a single **Monorepo** to guarantee instant type safety across the entire stack.

---

## 1. Enterprise Monorepo Workspace Topology

```text
my-enterprise-monorepo/
├── apps/
│   ├── web/                 # Next.js 15 App Router
│   ├── mobile/              # React Native (Expo)
│   ├── docs/                # Astro / VitePress documentation
│   └── api/                 # NestJS / Express Backend
├── packages/
│   ├── ui/                  # Shared Tailwind & Radix UI Component Library
│   ├── database/            # Shared Prisma / Drizzle client & migrations
│   ├── ts-config/           # Shared tsconfig.base.json
│   ├── eslint-config/       # Shared ESLint & Prettier rules
│   └── api-types/           # Shared Zod schemas & TypeScript DTOs
├── package.json             # Root workspace definition
├── pnpm-workspace.yaml      # Workspace package declarations
└── turbo.json               # Pipeline task execution graph
```

---

## 2. Turborepo Pipeline Task Graph (`turbo.json`)

```json
{
  "$schema": "https://turbo.build/schema.json",
  "ui": "tui",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["src/**", "package.json", "tsconfig.json"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"]
    },
    "test": {
      "dependsOn": ["^build"],
      "inputs": ["src/**", "test/**", "**/*.test.ts"]
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "outputs": []
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

### Key Concepts:
- `"^build"` (Topological dependency): Builds upstream shared libraries (e.g. `@repo/ui`) before building downstream apps (`@repo/web`).
- `"cache": false`: Ensures dev servers reload without attempting to restore old build artifacts from disk.

---

## 3. Creating Shared TypeScript Internal Packages (`packages/api-types/`)

Shared internal packages do not need to be published to npm; they can be referenced directly using TypeScript project references or modern package exports:

```json
// packages/api-types/package.json
{
  "name": "@repo/api-types",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "lint": "eslint src/"
  },
  "dependencies": {
    "zod": "^3.23.0"
  }
}
```

### Consuming in an Application (`apps/web/package.json`):

```json
{
  "name": "web",
  "dependencies": {
    "@repo/api-types": "workspace:*",
    "@repo/ui": "workspace:*"
  }
}
```

---

## 4. Remote Caching in CI/CD (Zero Redundant Builds)

Turborepo and Nx compute cryptographic hashes of all input files. If a package has not changed since the last build, it restores the output artifact from the remote cache in **0.2 seconds** instead of re-compiling for 3 minutes.

```bash
# Link local repo to Vercel / Turborepo remote cache
npx turbo link

# Run parallel builds with remote cache
npx turbo run build --remote-only
```

---

**Execution Protocol**
1. **Never use circular dependencies between workspace packages**: `@repo/ui` cannot depend on `@repo/web`.
2. **Always use `"^build"` in Turborepo `dependsOn`**: Ensures packages compile in correct topological dependency order.
3. **Use `workspace:*` for internal dependency versioning**: Guarantees monorepo packages always consume latest local source code.
