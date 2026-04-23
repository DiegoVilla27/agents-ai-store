# 🌌 Agents AI Store

> **"A meticulously curated vault of expert-level AI instructions and engineering patterns designed for the professional modern developer."**

[![Author: Diego Villanueva](https://img.shields.io/badge/Author-Diego%20Villanueva-blue.svg)](https://github.com/DiegoVilla27)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/DiegoVilla27/agents-ai-store)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Welcome to the **Agents AI Store**. This repository is a premium ecosystem of specialized AI capabilities designed to transform large language models (LLMs) into world-class software engineers across multiple domains.

---

## 🚀 The Mission

This project bridges the gap between general-purpose AI and **specialized engineering authority**. Every "Skill" and "Instruction" in this store is not just a prompt; it is a full **System Protocol** that enforces:
- **Architectural Integrity**: Clean Architecture (Domain, Application, Infrastructure, Presentation).
- **Vertical Slicing**: Modular features that are self-contained and scalable.
- **Performance Excellence**: Core Web Vitals, 60/120 FPS, and minimal bundle sizes.
- **Security-First Development**: Biometrics, secure storage, and token management.

---

## 🏛️ Strict Architectural Scaffolding

This store follows a **Zero Tolerance** policy for poor architecture. All instructions are hard-coded to enforce a specific scaffolding pattern based on the technology:

### Web Ecosystem (Angular, React, Next.js, NestJS)
Features are organized into **Vertical Slices** with nested **Clean Architecture** layers:
```text
/features/[name]/
├── domain/         # Entities & Repository Interfaces
├── application/    # Use Cases & Mappers
├── infrastructure/ # Repository Implementations & Data Sources
└── presentation/   # Components, Signals/Stores, & Views
```

### Flutter Ecosystem
Features follow the **Tripartite Pattern**:
```text
lib/features/[name]/
├── domain/         # Entities & Interfaces
├── data/           # DTOs, Mappers & Implementations
└── presentation/   # Widgets & Controllers
```

---

## ⚡ Quick Start

Integrate these expert-level engineering standards into any project in seconds.

### 1. Download the Synchronizer
Run this command in the root of your project:
```bash
curl -O https://raw.githubusercontent.com/DiegoVilla27/agents-ai-store/main/async_agents.sh && chmod +x async_agents.sh
```

### 2. Synchronize Assets
Sync everything (Skills + Instructions) with one command:
```bash
./async_agents.sh
```

### 3. Start Coding
Once the `.agents/` folder is created, your AI agent (Antigravity, Cursor, etc.) will automatically adopt the professional standards documented in the store.## 📂 Project Structure

```text
.agents/
├── angular/           # Agents, Instructions, and Skills for Angular
├── react/             # Agents, Instructions, and Skills for React
├── flutter/           # Agents, Instructions, and Skills for Flutter
├── nextjs/            # Agents, Instructions, and Skills for Next.js
├── nestjs/            # Agents, Instructions, and Skills for NestJS
├── react-native/      # Agents, Instructions, and Skills for React Native
└── shared/            # Common skills (Clean Code, Web Standards, etc.)
```

---

## 🤖 Expert Personas (Agents)

Agents are high-level blueprints that combine specific instructions and skills to create a domain expert. Syncing an agent automatically downloads all its dependencies.

| Agent Persona | Mission | Configuration |
|:---|:---|:---|
| `angular-agent` | Senior Master in Signals and Zoneless architecture. | [JSON](./angular/agents/angular-agent.json) |
| `react-agent` | Master in React 19, Server Components, and State. | [JSON](./react/agents/react-agent.json) |
| `nextjs-agent` | Full-stack Next.js Specialist (App Router & Actions). | [JSON](./nextjs/agents/nextjs-agent.json) |
| `react-native-agent` | Mobile Engineer specialized in Expo and Performance. | [JSON](./react-native/agents/react-native-agent.json) |
| `flutter-agent` | Senior Flutter Architect (Riverpod & Security). | [JSON](./flutter/agents/flutter-agent.json) |
| `nestjs-agent` | Master of Backend Scalability and Clean Architecture. | [JSON](./nestjs/agents/nestjs-agent.json) |

### 🛠 How to Activate an Agent
Once synchronized, you can activate a specific persona in your AI chat (Antigravity, Cursor, etc.) using one of these methods:

1. **Explicit Identification**: Mention the agent name in your first prompt:
   > *"Act as the **nextjs-agent**. Let's build a new feature."*
2. **Implicit Detection**: The AI automatically reads the `.agents/` folder and adopts the instructions and skills present in your workspace.
3. **Role Matching**: If you work in a project with a specific `agent.json`, the AI will align its behavior with the `"role"` defined in that blueprint.

---
## 📜 Strategic Development Instructions

This repository implements **Automatic System Protocols** through specialized instruction files. When an AI agent (like Antigravity) enters a workspace with these files, it automatically adopts the following high-level engineering standards:

| Framework | Instruction Name | Protocol Path | Architectural Pillars |
|:---|:---|:---|:---|
| **Angular** | `angular-coding` | [INSTRUCTION.md](./angular/instructions/angular-coding/INSTRUCTION.md) | Signals, `@defer`, Zoneless, Barrels. |
| **React** | `react-coding` | [INSTRUCTION.md](./react/instructions/react-coding/INSTRUCTION.md) | React 19, Compiler, Zustand, Index Pattern. |
| **Flutter** | `flutter-coding` | [INSTRUCTION.md](./flutter/instructions/flutter-coding/INSTRUCTION.md) | Snake_case, Riverpod, No-Index Barrels. |
| **Next.js** | `nextjs-coding` | [INSTRUCTION.md](./nextjs/instructions/nextjs-coding/INSTRUCTION.md) | App Router, Server Actions, Private Folders. |
| **React Native** | `react-native-coding` | [INSTRUCTION.md](./react-native/instructions/react-native-coding/INSTRUCTION.md) | **Styled Components**, Expo, FlatList Opt. |
| **NestJS** | `nestjs-coding` | [INSTRUCTION.md](./nestjs/instructions/nestjs-coding/INSTRUCTION.md) | Clean Architecture, DDD, Zod, Layers. |

---

## 🏛️ Global Architectural Standards

Every framework in this store is governed by two uncompromising architectural rules:

1.  **Modular Architecture (Vertical Slicing)**: We do not organize by "type" (all components in one folder, all hooks in another). We organize by **feature**. Each feature folder is a self-contained module containing its own components, hooks, validations, and data models.
2.  **Index Pattern (Clean Imports)**: We use `index.ts/tsx` files (except in Flutter) to expose the public API of a module. This ensures that imports are clean, professional, and decoupled from the internal file structure.

---

## 📚 Full Specialized Skills Catalog (34 Skills)

Our library is organized by ecosystem and domain. All skills are authored and maintained by **Diego Villanueva**.

### 🛠 Core Engineering & Languages (Shared)
The foundation of high-quality software development.
| Skill Name | Documentation | Mission |
|:---|:---|:---|
| `clean-code` | [SKILL.md](./shared/skills/clean-code/SKILL.md) | Universal engineering excellence and sustainability. |
| `conventional-commits` | [SKILL.md](./shared/skills/conventional-commits/SKILL.md) | Semantic and impeccable Git history. |
| `web-typescript` | [SKILL.md](./shared/skills/web-typescript/SKILL.md) | Strict typing and advanced generic patterns. |
| `web-javascript` | [SKILL.md](./shared/skills/web-javascript/SKILL.md) | Deep runtime behavior and optimized ESNext. |
| `web-tsdoc` | [SKILL.md](./shared/skills/web-tsdoc/SKILL.md) | Standardized TSDoc documentation for TypeScript projects. |

### ⚛️ React & Next.js Ecosystem
State-of-the-art patterns for the React universe.
| Skill Name | Documentation | Focus |
|:---|:---|:---|
| `react-core` | [SKILL.md](./react/skills/react-core/SKILL.md) | React 19, Compiler optimization, and Server Components. |
| `next-core` | [SKILL.md](./nextjs/skills/next-core/SKILL.md) | Next.js 15 App Router, Actions, and Streaming. |
| `next-routes` | [SKILL.md](./nextjs/skills/next-routes/SKILL.md) | Advanced App Router patterns: Parallel & Intercepting routes. |
| `nextjs-server-actions` | [SKILL.md](./nextjs/skills/nextjs-server-actions/SKILL.md) | RPC-like mutations and on-demand revalidation. |
| `nextjs-safe-action` | [SKILL.md](./nextjs/skills/nextjs-safe-action/SKILL.md) | Typed and secure actions with middleware. |
| `nextjs-auth-js` | [SKILL.md](./nextjs/skills/nextjs-auth-js/SKILL.md) | OAuth, JWT sessions, and route protection. |
| `nextjs-orm-prisma` | [SKILL.md](./nextjs/skills/nextjs-orm-prisma/SKILL.md) | Type-safe DB access and singleton clients. |
| `nextjs-seo-metadata` | [SKILL.md](./nextjs/skills/nextjs-seo-metadata/SKILL.md) | Metadata API, Dynamic OG, and Sitemap gen. |
| `nextjs-i18n-intl` | [SKILL.md](./nextjs/skills/nextjs-i18n-intl/SKILL.md) | next-intl, localized routing, and RTL support. |
| `nextjs-caching-isr` | [SKILL.md](./nextjs/skills/nextjs-caching-isr/SKILL.md) | Data cache, ISR, and tagging strategies. |
| `nextjs-middleware` | [SKILL.md](./nextjs/skills/nextjs-middleware/SKILL.md) | Edge Runtime logic, Geo, and global redirects. |
| `nextjs-shadcn-ui` | [SKILL.md](./nextjs/skills/nextjs-shadcn-ui/SKILL.md) | Accessible UI components with Radix & Tailwind. |
| `framer-motion` | [SKILL.md](./react/skills/framer-motion/SKILL.md) | High-end animations and complex gesture handling. |
| `react-hook-form` | [SKILL.md](./react/skills/react-hook-form/SKILL.md) | Performant and flexible form management. |
| `react-hook-form-zod` | [SKILL.md](./react/skills/react-hook-form-zod/SKILL.md) | Schema-based validation for React Hook Form. |
| `react-tanstack-query` | [SKILL.md](./react/skills/react-tanstack-query/SKILL.md) | v5 Server state, caching, and optimistic updates. |
| `react-zustand` | [SKILL.md](./react/skills/react-zustand/SKILL.md) | Global state with selectors, slices, and persistence. |
| `redux-toolkit` | [SKILL.md](./react/skills/redux-toolkit/SKILL.md) | Enterprise state management and RTK Query. |
| `react-zod` | [SKILL.md](./react/skills/react-zod/SKILL.md) | Zod 4 schema validation and type inference. |
| `react-a11y` | [SKILL.md](./react/skills/react-a11y/SKILL.md) | Accessibility and inclusive UI standards. |
| `react-view-transitions` | [SKILL.md](./react/skills/react-view-transitions/SKILL.md) | Native-like page transitions with Browser API. |
| `vite-react-optimization` | [SKILL.md](./react/skills/vite-react-optimization/SKILL.md) | Build performance, code splitting, and preloading. |
| `web-typescript-react` | [SKILL.md](./shared/skills/web-typescript-react/SKILL.md) | Advanced TS patterns for React and Next.js. |
| `react-native-core` | [SKILL.md](./react-native/skills/react-native-core/SKILL.md) | Universal mobile development and native performance. |
| `react-native-expo` | [SKILL.md](./react-native/skills/react-native-expo/SKILL.md) | Managed workflow, EAS, and Expo Router. |
| `react-native-navigation-advanced` | [SKILL.md](./react-native/skills/react-native-navigation-advanced/SKILL.md) | Nested navigators, deep links, and transitions. |
| `react-native-reanimated` | [SKILL.md](./react-native/skills/react-native-reanimated/SKILL.md) | Worklets, shared values, and 60fps animations. |
| `react-native-performance` | [SKILL.md](./react-native/skills/react-native-performance/SKILL.md) | FlashList, Hermes, and memory optimization. |
| `react-native-native-modules` | [SKILL.md](./react-native/skills/react-native-native-modules/SKILL.md) | Bridging Swift/Kotlin and Expo Modules API. |
| `mobile-offline-support` | [SKILL.md](./react-native/skills/mobile-offline-support/SKILL.md) | MMKV, WatermelonDB, and sync strategies. |
| `react-native-testing-library` | [SKILL.md](./react-native/skills/react-native-testing-library/SKILL.md) | User-centric unit and integration testing. |
| `react-native-styling-tailwind` | [SKILL.md](./react-native/skills/react-native-styling-tailwind/SKILL.md) | NativeWind v4 and utility-first mobile UI. |
| `mobile-debugging-sentry` | [SKILL.md](./react-native/skills/mobile-debugging-sentry/SKILL.md) | Crash reporting and performance monitoring. |

### 🟢 NestJS Ecosystem
Production-grade backend patterns using NestJS 10+.
| Skill Name | Documentation | Focus |
|:---|:---|:---|
| `nestjs-core` | [SKILL.md](./nestjs/skills/nestjs-core/SKILL.md) | DI, Dynamic Modules, Interceptors & Filters. |
| `nestjs-security` | [SKILL.md](./nestjs/skills/nestjs-security/SKILL.md) | JWT, Passport, Guards and RBAC. |
| `nestjs-persistence` | [SKILL.md](./nestjs/skills/nestjs-persistence/SKILL.md) | Repository Pattern, Prisma/TypeORM & Mappers. |
| `nestjs-testing-expert` | [SKILL.md](./nestjs/skills/nestjs-testing-expert/SKILL.md) | Advanced unit, integration, and E2E testing. |
| `nestjs-websocket` | [SKILL.md](./nestjs/skills/nestjs-websocket/SKILL.md) | Real-time gateways, rooms, and socket.io. |
| `nestjs-openapi-docs` | [SKILL.md](./nestjs/skills/nestjs-openapi-docs/SKILL.md) | Swagger integration and API documentation. |
| `nestjs-queue-architect`| [SKILL.md](./nestjs/skills/nestjs-queue-architect/SKILL.md) | BullMQ background jobs and Redis queues. |
| `nestjs-health-audit` | [SKILL.md](./nestjs/skills/nestjs-health-audit/SKILL.md) | Terminus health checks and readiness probes. |
| `nestjs-patterns` | [SKILL.md](./nestjs/skills/nestjs-patterns/SKILL.md) | Strategy, Factory, and SOLID in NestJS. |
| `nestjs-guards-interceptors` | [SKILL.md](./nestjs/skills/nestjs-guards-interceptors/SKILL.md) | Request lifecycle and response mapping. |
| `nestjs-lgtm-metrics` | [SKILL.md](./nestjs/skills/nestjs-lgtm-metrics/SKILL.md) | Prometheus metrics, logging, and tracing. |
| `nestjs-modular-monolith`| [SKILL.md](./nestjs/skills/nestjs-modular-monolith/SKILL.md) | Scaling with Bounded Contexts and DDD. |


### 🅰️ Angular Ecosystem
Enterprise-grade patterns for modern Angular apps.
| Skill Name | Documentation | Focus |
|:---|:---|:---|
| `angular-core` | [SKILL.md](./angular/skills/angular-core/SKILL.md) | Standalone components and modern Signal inputs. |
| `angular-signals` | [SKILL.md](./angular/signals/SKILL.md) | Fine-grained reactivity, computed and effects. |
| `angular-architecture` | [SKILL.md](./angular/skills/angular-architecture/SKILL.md) | Clean Architecture and Vertical Slicing. |
| `angular-routing` | [SKILL.md](./angular/skills/angular-routing/SKILL.md) | Functional guards, lazy loading, and deep links. |
| `angular-http` | [SKILL.md](./angular/skills/angular-http/SKILL.md) | Type-safe API communication and rxResource. |
| `angular-di` | [SKILL.md](./angular/skills/angular-di/SKILL.md) | Mastery of inject() and modern DI patterns. |
| `angular-forms` | [SKILL.md](./angular/skills/angular-forms/SKILL.md) | Reactive Forms and advanced validation. |
| `angular-performance` | [SKILL.md](./angular/skills/angular-performance/SKILL.md) | Zoneless, @defer, and SSR optimizations. |
| `angular-ssr-hydration` | [SKILL.md](./angular/skills/angular-ssr-hydration/SKILL.md) | Non-destructive hydration and TransferState. |
| `angular-animations` | [SKILL.md](./angular/skills/angular-animations/SKILL.md) | DSL animations, coordinated triggers and staggering. |
| `angular-i18n` | [SKILL.md](./angular/skills/angular-i18n/SKILL.md) | Internationalization and localized formatting. |
| `angular-material-cdk` | [SKILL.md](./angular/skills/angular-material-cdk/SKILL.md) | Official UI components and low-level behaviors. |
| `ngrx-signal-store` | [SKILL.md](./angular/skills/ngrx-signal-store/SKILL.md) | Modern state management with SignalStore. |
| `angular-query` | [SKILL.md](./angular/skills/angular-query/SKILL.md) | Asynchronous server state with TanStack. |
| `angular-modern-syntax` | [SKILL.md](./angular/skills/angular-modern-syntax/SKILL.md) | New control flow (@if, @for) and @defer. |
| `angular-security` | [SKILL.md](./angular/skills/angular-security/SKILL.md) | Auth, Interceptors, and Sanitization. |
| `rxjs-advanced` | [SKILL.md](./angular/skills/rxjs-advanced/SKILL.md) | Mastery of operators and action streams. |
| `nx-monorepo` | [SKILL.md](./angular/skills/nx-monorepo/SKILL.md) | Scaling with libraries and workspace tags. |
| `angular-pwa` | [SKILL.md](./angular/skills/angular-pwa/SKILL.md) | Service Workers and offline reliability. |

### 💙 Flutter Ecosystem
Comprehensive suite for high-performance Cross-Platform apps.
| Skill Name | Documentation | Focus |
|:---|:---|:---|
| `flutter-architect` | [SKILL.md](./flutter/skills/flutter-architect/SKILL.md) | Atomic scoping and modular go_router setup. |
| `flutter-riverpod` | [SKILL.md](./flutter/skills/flutter-riverpod/SKILL.md) | Reactive data flow with code generation. |
| `flutter-performance` | [SKILL.md](./flutter/skills/flutter-performance/SKILL.md) | 120 FPS rendering and memory management. |
| `flutter-biometrics` | [SKILL.md](./flutter/skills/flutter-biometrics/SKILL.md) | Face ID / Fingerprint implementation. |
| `flutter-security-architect` | [SKILL.md](./flutter/skills/flutter-security-architect/SKILL.md) | Secure storage and encryption protocols. |
| `flutter-platform-configurator`| [SKILL.md](./flutter/skills/flutter-platform-configurator/SKILL.md) | Native iOS/Android configurations and Gradle. |
| `flutter-ui-ux` | [SKILL.md](./flutter/skills/flutter-ui-ux/SKILL.md) | Premium micro-interactions and animations. |
| `flutter-animations` | [SKILL.md](./flutter/skills/flutter-animations/SKILL.md) | Complex motion, physics, and staggered animations. |
| `flutter-theming` | [SKILL.md](./flutter/skills/flutter-theming/SKILL.md) | Material 3, dynamic color, and theme extensions. |
| `flutter-navigation-routing` | [SKILL.md](./flutter/skills/flutter-navigation-routing/SKILL.md) | Declarative routing and deep links with GoRouter. |
| `flutter-caching-offline` | [SKILL.md](./flutter/skills/flutter-caching-offline/SKILL.md) | Local persistence (Hive/Isar) and sync logic. |
| `flutter-http-json` | [SKILL.md](./flutter/skills/flutter-http-json/SKILL.md) | Advanced API clients with Dio and Type-safety. |
| `flutter-concurrency` | [SKILL.md](./flutter/skills/flutter-concurrency/SKILL.md) | Isolate-based multithreading and heavy tasks. |
| `flutter-layouts` | [SKILL.md](./flutter/skills/flutter-layouts/SKILL.md) | Slivers, adaptive UI, and complex constraints. |

### 🧪 Testing Strategies
Ensuring software remains immune to regressions.
| Skill Name | Documentation | Stack |
|:---|:---|:---|
| `web-modern-testing` | [SKILL.md](./shared/skills/web-modern-testing/SKILL.md) | Vitest, MSW, and Playwright (A11y focus). |
| `react-testing-jest` | [SKILL.md](./react/skills/react-testing-jest/SKILL.md) | Industry-standard Jest + Testing Library. |
| `angular-testing-jasmine` | [SKILL.md](./angular/skills/angular-testing-jasmine/SKILL.md) | Enterprise-standard Jasmine & Karma. |
| `flutter-testing` | [SKILL.md](./flutter/skills/flutter-testing/SKILL.md) | Unit, Widget, and Integration tests in Flutter. |

### 🎨 Advanced UI, Performance & Architecture (Shared)
| Skill Name | Documentation | Focus |
|:---|:---|:---|
| `web-tailwind` | [SKILL.md](./shared/skills/web-tailwind/SKILL.md) | Tailwind CSS 4, semantic tokens, and `cn()`. |
| `web-advanced-ui-ux` | [SKILL.md](./shared/skills/web-advanced-ui-ux/SKILL.md) | Container Queries, CSS Layers, and Anchor Positioning. |
| `web-performance` | [SKILL.md](./shared/skills/web-performance/SKILL.md) | Core Web Vitals (LCP, CLS, INP) optimization. |
| `web-micro-frontends` | [SKILL.md](./shared/skills/web-micro-frontends/SKILL.md) | Module Federation and Vite orchestrations. |

---

## 🛠 Automation: `async_agents.sh`

Integrate these skills and instructions into any project instantly. No manual copy-pasting required.

### Usage:
```bash
# Give execution permissions
chmod +x async_agents.sh

# Sync everything (all technologies)
./async_agents.sh

# Sync a specific technology stack (RECOMMENDED)
./async_agents.sh angular
./async_agents.sh react
./async_agents.sh flutter

# Sync specific assets
./async_agents.sh react-core flutter-coding angular-performance

# Use local store (Dev Mode)
./async_agents.sh --local ~/path/to/store
```

---

## ✍️ Contribution & Standards

Every skill in this store must follow the **Diego Villanueva instructional format**:
1. **YAML Frontmatter**: Metadata, author, and `Trigger` field.
2. **(REQUIRED) Headers**: Enforced standards for specific topics.
3. **Always/Never Blocks**: Code patterns with `// ✅ ALWAYS` and `// ❌ NEVER` for unambiguous AI execution.

---

Made with 🌌 by **Diego Villanueva** | *Empowering the next generation of AI-native developers.*
 by **Diego Villanueva** | *Empowering the next generation of AI-native developers.*
