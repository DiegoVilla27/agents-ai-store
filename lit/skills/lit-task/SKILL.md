---
name: lit-task
description: The definitive standard for declarative async data fetching and loading state management using @lit/task in Lit components.
author: Diego Villanueva
trigger: When fetching async data in Lit components, managing loading/error/success states, using @lit/task, or implementing declarative data loading patterns.
---

# Lit Task Mastery (@lit/task)

`@lit/task` provides a declarative way to manage async operations (API calls, computations) with automatic lifecycle management, abort handling, and status-based rendering.

---

## 1. Basic Task

```typescript
import { LitElement, html } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import { Task } from '@lit/task';

@customElement('user-profile')
export class UserProfile extends LitElement {
  @property() userId = '';

  private _userTask = new Task(this, {
    args: () => [this.userId] as const,
    task: async ([userId], { signal }) => {
      const response = await fetch(`/api/users/${userId}`, { signal });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return response.json() as Promise<User>;
    },
  });

  render() {
    return this._userTask.render({
      initial:  () => html`<p>Enter a user ID</p>`,
      pending:  () => html`<app-spinner></app-spinner>`,
      complete: (user) => html`
        <div class="profile">
          <h2>${user.name}</h2>
          <p>${user.email}</p>
          <span class="badge">${user.role}</span>
        </div>
      `,
      error:    (err) => html`<error-banner .message=${(err as Error).message}></error-banner>`,
    });
  }
}
```

---

## 2. How Tasks Work

### A. `args` — Reactive Dependencies

The `args` function returns an array of values. When ANY value changes, the task **automatically re-runs**.

```typescript
private _searchTask = new Task(this, {
  args: () => [this.query, this.page, this.sortBy] as const,
  task: async ([query, page, sortBy], { signal }) => {
    const params = new URLSearchParams({ q: query, page: String(page), sort: sortBy });
    const res = await fetch(`/api/search?${params}`, { signal });
    return res.json();
  },
});
```

- ✅ When `this.query`, `this.page`, or `this.sortBy` change, the task re-executes.
- ✅ The previous in-flight request is automatically **aborted** via the `signal`.

### B. `TaskStatus` States

| Status | Value | When |
|--------|-------|------|
| `INITIAL` | 0 | Task has not run yet |
| `PENDING` | 1 | Task is running |
| `COMPLETE` | 2 | Task completed successfully |
| `ERROR` | 3 | Task threw an error |

```typescript
import { TaskStatus } from '@lit/task';

render() {
  if (this._task.status === TaskStatus.PENDING) {
    return html`<app-spinner></app-spinner>`;
  }
  if (this._task.status === TaskStatus.COMPLETE) {
    return html`<p>${this._task.value}</p>`;
  }
  if (this._task.status === TaskStatus.ERROR) {
    return html`<p class="error">${this._task.error}</p>`;
  }
  return html`<p>Idle</p>`;
}
```

---

## 3. Abort Signals

The `signal` parameter is an `AbortSignal` that automatically aborts when:
1. The component is disconnected.
2. The task is re-triggered (new args).

```typescript
private _dataTask = new Task(this, {
  args: () => [this.endpoint] as const,
  task: async ([endpoint], { signal }) => {
    // Pass signal to fetch — automatically cancels on re-trigger
    const res = await fetch(endpoint, { signal });
    if (!res.ok) throw new Error(`Failed: ${res.status}`);
    return res.json();
  },
});
```

---

## 4. Manual Task Execution (`autoRun: false`)

For tasks that should only run on user interaction (form submission, button click):

```typescript
private _saveTask = new Task(this, {
  autoRun: false,
  task: async ([formData]: [FormData]) => {
    const res = await fetch('/api/save', {
      method: 'POST',
      body: formData,
    });
    if (!res.ok) throw new Error('Save failed');
    return res.json();
  },
});

private _handleSubmit(e: SubmitEvent) {
  e.preventDefault();
  const formData = new FormData(e.target as HTMLFormElement);
  this._saveTask.run([formData]);
}

render() {
  return html`
    <form @submit=${this._handleSubmit}>
      <input name="title" required />
      <button type="submit" ?disabled=${this._saveTask.status === TaskStatus.PENDING}>
        ${this._saveTask.status === TaskStatus.PENDING ? 'Saving...' : 'Save'}
      </button>
    </form>
    ${this._saveTask.render({
      complete: () => html`<p class="success">Saved!</p>`,
      error: (err) => html`<p class="error">${(err as Error).message}</p>`,
    })}
  `;
}
```

---

## 5. Combining Multiple Tasks

```typescript
@customElement('dashboard-page')
export class DashboardPage extends LitElement {
  private _usersTask = new Task(this, {
    task: async (_, { signal }) => {
      const res = await fetch('/api/users', { signal });
      return res.json() as Promise<User[]>;
    },
  });

  private _statsTask = new Task(this, {
    task: async (_, { signal }) => {
      const res = await fetch('/api/stats', { signal });
      return res.json() as Promise<Stats>;
    },
  });

  render() {
    return html`
      <section class="stats">
        ${this._statsTask.render({
          pending:  () => html`<stat-skeleton></stat-skeleton>`,
          complete: (stats) => html`<stat-cards .data=${stats}></stat-cards>`,
          error:    () => html`<p>Failed to load stats</p>`,
        })}
      </section>
      <section class="users">
        ${this._usersTask.render({
          pending:  () => html`<list-skeleton></list-skeleton>`,
          complete: (users) => html`<user-table .rows=${users}></user-table>`,
          error:    () => html`<p>Failed to load users</p>`,
        })}
      </section>
    `;
  }
}
```

---

## 6. Task with Debouncing

For search inputs, debounce the args to avoid excessive API calls:

```typescript
@customElement('search-box')
export class SearchBox extends LitElement {
  @state() private _query = '';
  @state() private _debouncedQuery = '';
  private _debounceTimer?: ReturnType<typeof setTimeout>;

  private _searchTask = new Task(this, {
    args: () => [this._debouncedQuery] as const,
    task: async ([query], { signal }) => {
      if (!query) return [];
      const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`, { signal });
      return res.json() as Promise<SearchResult[]>;
    },
  });

  private _onInput(e: InputEvent) {
    this._query = (e.target as HTMLInputElement).value;
    clearTimeout(this._debounceTimer);
    this._debounceTimer = setTimeout(() => {
      this._debouncedQuery = this._query;
    }, 300);
  }

  render() {
    return html`
      <input type="search" .value=${this._query} @input=${this._onInput} placeholder="Search...">
      ${this._searchTask.render({
        pending:  () => html`<app-spinner></app-spinner>`,
        complete: (results) => html`
          <ul>${results.map(r => html`<li>${r.title}</li>`)}</ul>
        `,
      })}
    `;
  }
}
```

---

## 7. Rules

- ✅ **ALWAYS** pass the `signal` to `fetch()` — enables automatic abort on re-trigger.
- ✅ Use `autoRun: false` for user-initiated tasks (form submit, button click).
- ✅ Use the `.render()` method for clean status-based UI rendering.
- ❌ **NEVER** call async code directly in `connectedCallback` when Task can handle it declaratively.
- ❌ **NEVER** forget to handle the `error` case in `.render()`.
