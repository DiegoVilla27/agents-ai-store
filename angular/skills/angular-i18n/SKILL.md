---
name: angular-i18n
description: The ultimate architectural standard for Enterprise Angular i18n Native @angular/localize (AOT), Transloco (Runtime), Pluralization, and Locale Formatting.
author: Diego Villanueva
trigger: When building multi-language support, formatting dates/currencies by locale, or implementing translation keys.
---

# Enterprise Angular Internationalization (i18n)

In a global enterprise application, hardcoding strings like `<button>Submit</button>` is a critical architectural failure. 

Every piece of text, every date, and every currency symbol MUST be abstracted and driven by the user's Locale.

## 1. The Two Paradigms: AOT vs Runtime

Angular offers two entirely different ways to handle translations. You must choose the right one for the business requirements:

1. **Native `@angular/localize` (AOT)**: Translates the app during the build process. It generates a separate physical `index.html` and JS bundle for every language (e.g., `/en/`, `/es/`). 
   - *Pros*: Zero performance overhead. Fastest initial load. No external libraries.
   - *Cons*: Cannot switch language dynamically without a full page reload to the new URL.

2. **Transloco / ngx-translate (Runtime)**: Loads JSON translation files asynchronously over HTTP while the app is running.
   - *Pros*: Users can switch languages instantly without reloading the page. Easier for CI/CD (only one build artifact).
   - *Cons*: Slight performance overhead parsing JSON at runtime.

**CRITICAL RULE**: In modern enterprise apps requiring instant language switching, **Transloco** is the industry standard. `ngx-translate` is considered legacy.

## 2. Implementing Transloco (Runtime Switching)

If the app requires runtime switching, you MUST use Transloco.

**❌ NEVER** use the `transloco` pipe extensively in large lists, as it creates a subscription per pipe and degrades performance.
**✅ ALWAYS** use the `*transloco` structural directive to inject translations efficiently.

```html
<!-- ❌ ATROCIOUS: Creates 3 separate subscriptions -->
<h1>{{ 'home.title' | transloco }}</h1>
<p>{{ 'home.subtitle' | transloco }}</p>
<button>{{ 'home.submit' | transloco }}</button>

<!-- ✅ ALWAYS: Creates 1 subscription and scopes the translations -->
<ng-container *transloco="let t; read: 'home'">
  <h1>{{ t('title') }}</h1>
  <p>{{ t('subtitle') }}</p>
  <button>{{ t('submit') }}</button>
</ng-container>
```

To translate text inside TypeScript (e.g., for error messages or toasts), inject the `TranslocoService`.

```typescript
export class CheckoutService {
  private readonly transloco = inject(TranslocoService);
  private readonly toast = inject(ToastService);

  showError() {
    // ✅ ALWAYS: Translate dynamic messages before showing them
    const msg = this.transloco.translate('errors.payment_failed');
    this.toast.error(msg);
  }
}
```

## 3. Implementing Native `@angular/localize` (AOT)

If the app uses Native i18n, you must use the `i18n` attribute in templates. The CLI will extract these into an `.xlf` file.

**✅ ALWAYS** provide a description and meaning to help the translators.

```html
<!-- ✅ ALWAYS: Provide context for the translator -->
<h1 i18n="Site header|Greeting message to the user@@home.greeting">
  Welcome to our Enterprise Platform
</h1>
```

To translate text inside TypeScript with Native i18n, use the global `$localize` tag.

```typescript
// ✅ ALWAYS: Use $localize for TS translations
const errorMessage = $localize `:@@errors.payment_failed:Your payment was declined. Please try again.`;
```

## 4. The Golden Rule: Never Concatenate Strings

Different languages have different grammar and word orders. 
"Hello Diego, you have 5 new messages" in another language might be "You have 5 new messages, Diego, Hello."

**❌ NEVER** do this: `'Hello ' + name + ', you have ' + count + ' new messages'`.
**✅ ALWAYS** use placeholders.

```json
// en.json (Transloco)
{
  "greeting": "Hello {{ name }}, you have {{ count }} new messages"
}
```
```html
<!-- Usage -->
<p>{{ t('greeting', { name: user.name, count: unreadCount }) }}</p>
```

## 5. Pluralization & ICU Expressions

Handling plurals is famously difficult (e.g., 0 items, 1 item, 2 items). You MUST use ICU (International Components for Unicode) syntax or Transloco's pluralization engine.

```html
<!-- ✅ ALWAYS: Handle plurals correctly. Never write "item(s)" -->
<span i18n>
  {itemCount, plural, 
    =0 {You have no items in your cart.}
    =1 {You have one item in your cart.}
    other {You have {itemCount} items in your cart.}
  }
</span>
```

## 6. Formatting (Dates, Numbers, Currencies)

Never manually format a date as `MM/DD/YYYY`. In Europe, that is invalid (`DD/MM/YYYY`). You MUST rely on Angular's native pipes, which automatically format based on the active `LOCALE_ID`.

```html
<!-- ✅ ALWAYS: Use native pipes. They adapt to the locale automatically. -->

<!-- In the US: Dec 31, 2026. In ES: 31 dic 2026 -->
<p>Joined: {{ user.createdAt | date:'mediumDate' }}</p>

<!-- In the US: $1,234.56. In ES: 1.234,56 € -->
<p>Price: {{ product.price | currency:'EUR' }}</p>

<!-- In the US: 1,000,000. In ES: 1.000.000 -->
<p>Views: {{ video.views | number }}</p>
```

---

**Execution Protocol**
1. **Locale Data**: If using Native i18n, you must register locale data in `app.config.ts` for any non-US locales, or the Date/Currency pipes will throw errors: `registerLocaleData(localeEs, 'es');`
2. **Dynamic Locales**: If using Transloco (Runtime), Angular's native pipes (`DatePipe`) will NOT automatically know when the user switches the language. You must manually pass the active language to the pipe or provide a custom `LOCALE_ID` strategy.
3. **RTL (Right-To-Left)**: For languages like Arabic or Hebrew, do not hardcode `margin-left` or `float: right`. ALWAYS use logical CSS properties: `margin-inline-start` or `padding-inline-end`. The browser will flip them automatically based on the `<html dir="rtl">` tag.
