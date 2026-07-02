---
name: conventional-commits
description: An exhaustive, enterprise-grade standard for writing clean, semantic, and automated Git commit messages.
author: Diego Villanueva
trigger: When writing git commit messages, reviewing pull requests, or documenting changelogs.
---

# Conventional Commits Mastery

You are the architect of the project's historical record. Your primary objective is to maintain an impeccable, machine-readable, and human-friendly Git history. A disciplined commit history enables automated semantic versioning, effortless changelog generation, and immediate context for future developers.

## 1. The Anatomy of a Commit (REQUIRED)

Every commit message must strictly adhere to the following structure:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

- **Type**: Communicates the intent of the change.
- **Scope**: (Optional but highly recommended) A noun describing the section of the codebase affected.
- **Description**: A short, imperative summary of the change.
- **Body**: (Optional) Detailed explanation providing context (the "why" and "what", not the "how").
- **Footer**: (Optional) Used for referencing issues, PRs, or denoting breaking changes.

## 2. Comprehensive Commit Types

Use the exact type that matches the nature of your change.

| Type | Semantic Versioning | Purpose |
|------|---------------------|---------|
| **`feat`** | Minor (1.**X**.0) | Introduces a new feature to the codebase. |
| **`fix`** | Patch (1.0.**X**) | Patches a bug in the codebase. |
| **`docs`** | None | Changes only to documentation (`README.md`, comments, etc.). |
| **`style`** | None | Formatting, missing semi-colons, white-space; no production code change. |
| **`refactor`** | None | A code change that neither fixes a bug nor adds a feature (e.g., renaming). |
| **`perf`** | Patch (1.0.**X**) | A code change that specifically improves performance. |
| **`test`** | None | Adding missing tests or correcting existing tests. |
| **`build`** | None | Changes affecting the build system or external dependencies (npm, pip, Gradle). |
| **`ci`** | None | Changes to CI configuration files and scripts (GitHub Actions, Travis). |
| **`chore`** | None | Maintenance tasks, tool configurations, or minor structural changes. |
| **`revert`** | Patch (1.0.**X**) | Reverts a previous commit. Must include the hash of the reverted commit. |

## 3. Scope Conventions

The scope provides immediate context about *where* the change occurred.
- Must consist of a noun describing a section of the codebase (e.g., `auth`, `router`, `ui-button`, `api`).
- Must be enclosed in parentheses: `feat(auth): ...`
- If a change spans multiple scopes, omit the scope or use `*` only if absolutely necessary, but prefer atomic commits.

## 4. Description Conventions

The description is the most critical part of the commit.
- **Imperative Mood**: Write as if giving a command. Use "add", "fix", "change" instead of "added", "fixes", "changing". (e.g., *If applied, this commit will __[description]__*).
- **Lowercase**: Start with a lowercase letter.
- **No Punctuation**: Do not end the description with a period (`.`).
- **Conciseness**: Keep the first line under 50-72 characters.

## 5. Body and Footer Conventions

- **Body**: Use the body to explain *why* the change is being made and the contrast with previous behavior. Wrap lines at 72 characters. Separate from the description with a blank line.
- **Footer**: Use the footer to reference issue trackers (e.g., `Fixes #123`, `Closes JIRA-456`) or to explicitly declare breaking changes.

## 6. Breaking Changes (CRITICAL)

A breaking change translates to a **Major** version bump in Semantic Versioning (e.g., **X**.0.0).

- **Indicator `!`**: Append a `!` to the type/scope immediately before the `:` to draw immediate attention.
  - *Example*: `feat(api)!: remove v1 endpoints`
- **Footer Declaration**: Alternatively or additionally, use `BREAKING CHANGE:` in the footer, followed by an explanation of what broke and migration instructions.

## 7. Atomicity of Commits

Commits must be atomic.
- **One Concept per Commit**: Do not mix a feature addition with a completely unrelated refactor in the same commit.
- **Deployable State**: The codebase should compile and pass tests at every single commit. Do not commit broken intermediate states.

## 8. Examples: Good vs. Bad

```bash
# ✅ PERFECT EXAMPLES
feat(payment): add stripe integration for subscriptions
fix(auth): resolve token refresh infinite loop
refactor(ui): extract primary button to reusable component
docs(readme): update installation instructions
perf(db): add index to user email column for faster login
feat(core)!: upgrade minimum node version to 18

# ❌ ATROCIOUS EXAMPLES (NEVER DO THIS)
Update files
fixed the bug in login
added some things
WIP
feat: added payment, fixed login, and updated tests # NOT ATOMIC
Refactored the database connection. # NOT IMPERATIVE, HAS PERIOD, CAPITALIZED
```

---

**Execution Protocol**
1. **Pre-commit Hooks**: Enforce commit message linting (e.g., using `commitlint` and `husky`).
2. **Squash and Merge**: If working on a PR with messy WIP commits, always Squash and Merge, providing a clean Conventional Commit for the final merge.
3. **No Ghost Commits**: Every commit must justify its existence. Empty or "trigger CI" commits must be avoided or squashed.
