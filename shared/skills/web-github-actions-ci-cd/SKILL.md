---
name: web-github-actions-ci-cd
description: The ultimate architectural standard for Enterprise CI/CD Pipelines with GitHub Actions, Matrix Builds, Dependency Caching, Automated Lint/Test/Build, and Semantic Release.
author: Diego Villanueva
trigger: When configuring GitHub Actions workflows, setting up automated CI/CD for web projects, optimizing GitHub Actions cache, or automating semantic releases.
---

# Enterprise CI/CD Pipelines with GitHub Actions

Manual deployment workflows are prone to human error, regression leaks, and downtime. An Enterprise Staff Engineer designs automated **GitHub Actions CI/CD Pipelines** with **Parallel Matrix Testing**, **Dependency Caching**, **Automated Linting/Typechecking**, and **Semantic Versioning Releases**.

---

## 1. Enterprise Continuous Integration Workflow (`.github/workflows/ci.yml`)

```yaml
# .github/workflows/ci.yml
name: Continuous Integration

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

# Cancel in-progress runs on new commits to the same PR
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  validate:
    name: Lint, Typecheck & Test
    runs-on: ubuntu-latest
    timeout-minutes: 10

    strategy:
      matrix:
        node-version: [20.x, 22.x]

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm' # Automatically caches ~/.npm directory

      - name: Install Dependencies
        run: npm ci

      - name: Code Formatting & Lint Check
        run: npm run lint

      - name: TypeScript Typecheck
        run: npm run typecheck

      - name: Execute Automated Unit & Integration Tests with Coverage
        run: npm test -- --coverage

      - name: Upload Test Coverage Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report-node-${{ matrix.node-version }}
          path: coverage/
          retention-days: 7

      - name: Production Bundle Verification
        run: npm run build
```

---

## 2. Automated Semantic Release & Changelog Generation (`.github/workflows/release.yml`)

Automatically bump versions, generate `CHANGELOG.md`, and create GitHub Releases based on Conventional Commits:

```yaml
# .github/workflows/release.yml
name: Semantic Release

on:
  push:
    branches: [main]

jobs:
  release:
    name: Semantic Release & Publish
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0 # Full git history required for changelog generation

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20.x
          cache: 'npm'

      - name: Install Dependencies
        run: npm ci

      - name: Run Semantic Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: npx semantic-release
```

---

## 3. GitHub Actions Performance Optimization Secrets

1. **`concurrency.cancel-in-progress: true`**: Saves CI runner minutes by killing stale builds when developers push new commits to an open PR.
2. **`actions/setup-node` with `cache: 'npm'`**: Speeds up `npm ci` step from 45 seconds to 5 seconds.
3. **`timeout-minutes: 10`**: Prevents runaway hung processes or infinite loops from burning all monthly GitHub Action compute quotas.

---

**Execution Protocol**
1. **Never commit hardcoded secrets**: Always use `${{ secrets.MY_SECRET }}` from repository settings.
2. **Always enforce PR branch protection rules**: Require the `Lint, Typecheck & Test` job to pass before merging into `main`.
3. **Set strict `timeout-minutes` on every job**: Eliminates silent billing leaks from hanging tests.
