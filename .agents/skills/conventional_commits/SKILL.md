---
name: conventional-commits
description: >
  Expert in maintaining an impeccable, readable, and semantic Git history.
  Trigger: When writing git commit messages or documenting changes.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Commit Standard Format (REQUIRED)

Every message must follow the structure: `<type>(<scope>): <description>`

```bash
# ✅ ALWAYS: Semantic and concise
feat(auth): add face-id biometric support
fix(router): resolve redirect loop in private routes

# ❌ NEVER: Generic or messy messages
update
fixed bugs
changes in screens
ASDF!!!
```

---

## Defined Commit Types (REQUIRED)

| Type | When to use |
|------|-------------|
| **feat** | A new feature for the user. |
| **fix** | A bug fix. |
| **docs** | Documentation-only changes. |
| **style** | Formatting, missing semi-colons, etc. (no code changes). |
| **refactor** | Code change that neither fixes a bug nor adds a feature. |
| **perf** | Code change that improves performance. |
| **test** | Adding missing tests or correcting existing ones. |
| **build** | Changes to build system or dependencies (Gradle, Pubspec). |
| **ci** | Changes to CI configuration (GitHub Actions). |
| **chore** | Other changes that don't modify src or test files. |

---

## Breaking Changes & Atomicity (REQUIRED)

Ensure commits are small and focused.

```bash
# ✅ ALWAYS: Use ! for breaking changes
feat(api)!: change user response structure

# ❌ NEVER: Mixing types in one commit
# Do not mix feat and refactor in the same commit.
```

---

## Execution Protocol (REQUIRED)

1. **Stage**: Group only files related to the specific change.
2. **Review**: Check the diff to ensure no log or temporary files are included.
3. **Draft**: Complete the sentence: "If applied, this commit will [description]".
4. **Audit**: Verify the message is clear and free of typos before pushing.

---

## Uncompromising Constraints

- **Lowercase**: Type and scope must always be in lowercase.
- **No Periods**: Do not use periods at the end of the commit description.
- **No Generic Messages**: Use of "update", "fix", or "changes" without context is strictly prohibited.
