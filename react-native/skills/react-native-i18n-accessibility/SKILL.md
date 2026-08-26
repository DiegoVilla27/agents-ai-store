---
name: react-native-i18n-accessibility
description: The ultimate architectural standard for Mobile Accessibility (a11y), Screen Readers (VoiceOver/TalkBack), Multi-Language Localization (i18next), and RTL Layouts in React Native.
author: Diego Villanueva
trigger: When configuring internationalization (i18n), supporting RTL layouts (Arabic/Hebrew), implementing VoiceOver/TalkBack accessibility props, or auditing WCAG AA compliance in React Native.
---

# Enterprise React Native Accessibility (a11y) & Internationalization (i18n)

Mobile apps must be accessible to users with visual, auditory, and motor impairments (WCAG 2.2 AA Compliance, VoiceOver/TalkBack) and adapt seamlessly to localized languages and bidirectional layouts (LTR / RTL).

---

## 1. Multi-Language Internationalization with `i18next`

```bash
npm install i18next react-i18next expo-localization
```

```typescript
// src/locales/i18n.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import * as Localization from 'expo-localization';

import en from './translations/en.json';
import es from './translations/es.json';
import ar from './translations/ar.json';

const resources = {
  en: { translation: en },
  es: { translation: es },
  ar: { translation: ar },
};

i18n.use(initReactI18next).init({
  resources,
  lng: Localization.getLocales()[0]?.languageCode ?? 'en',
  fallbackLng: 'en',
  interpolation: {
    escapeValue: false, // React already escapes values
  },
});

export default i18n;
```

---

## 2. Right-to-Left (RTL) Layout Architecture (Arabic, Hebrew)

React Native uses Yoga layout engine, which supports directional flex properties:

**❌ NEVER** hardcode `left` and `right` in styles.
**✅ ALWAYS** use `marginStart`, `marginEnd`, `paddingStart`, and `paddingEnd`.

```tsx
// ❌ WRONG: Hardcoded left margin breaks in Arabic RTL
<View style={{ marginLeft: 16, marginRight: 8 }} />

// ✅ ALWAYS: Automatically flips layout in RTL languages
<View style={{ marginStart: 16, marginEnd: 8 }} />
```

---

## 3. Screen Reader Accessibility (VoiceOver & TalkBack)

### A. Accessible Pressables with Explicit Roles and Hints

```tsx
// ✅ ALWAYS: Provide accessibilityLabel, accessibilityRole, and accessibilityHint
<Pressable
  accessible={true}
  accessibilityRole="button"
  accessibilityLabel="Delete item"
  accessibilityHint="Double tap to permanently remove this transaction from history"
  onPress={handleDelete}
  className="h-12 w-12 items-center justify-center rounded-full bg-red-100"
>
  <TrashIcon />
</Pressable>
```

### B. Grouping Child Elements to Reduce Cognitive Screen Reader Clutter

```tsx
// Consolidate card details into a single readable sentence for VoiceOver
<View
  accessible={true}
  accessibilityLabel={`Order number ${order.id}, total price $${order.total}, status ${order.status}`}
  className="rounded-2xl bg-white p-4"
>
  <Text>{order.id}</Text>
  <Text>${order.total}</Text>
  <Badge>{order.status}</Badge>
</View>
```

---

## 4. Minimum Touch Targets (48x48 dp) & Dynamic Font Scaling

Ensure all touchables meet the **48x48 dp** Apple/Google minimum:

```tsx
// Use hitSlop to expand clickable area without breaking visual padding
<Pressable
  hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
  onPress={onClose}
>
  <CloseIcon />
</Pressable>
```

---

**Execution Protocol**
1. **Always use directional margins/paddings (`marginStart`, `paddingEnd`)**: Guarantees effortless RTL support.
2. **Never leave icon-only buttons without `accessibilityLabel`**: Screen readers will read unhelpful raw filenames.
3. **Enforce minimum 48x48 touch targets via `hitSlop`**: Improves motor accessibility.
