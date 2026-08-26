---
name: flutter-accessibility-i18n
description: The ultimate architectural standard for Mobile Accessibility (a11y), Screen Readers (VoiceOver/TalkBack), Semantics Widgets, Multi-Language Internationalization (ARB), and RTL Layouts in Flutter.
author: Diego Villanueva
trigger: When configuring internationalization (i18n), managing ARB translation files, implementing Semantics for VoiceOver/TalkBack, supporting RTL layouts, or auditing WCAG in Flutter.
---

# Enterprise Flutter Accessibility (a11y) & Internationalization (i18n)

Enterprise mobile applications must be fully accessible to users with visual, auditory, and motor impairments (WCAG 2.2 AA Compliance, VoiceOver/TalkBack compatibility) and adapt seamlessly to different languages and text directions (LTR / RTL).

---

## 1. Multi-Language Localization (`flutter_localizations` & ARB)

Flutter provides official compile-time type-safe internationalization using **Application Resource Bundle (`.arb`)** files.

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true # Enables auto-generation of AppLocalizations
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "Enterprise Hub",
  "welcomeMessage": "Welcome back, {userName}!",
  "@welcomeMessage": {
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "Diego"
      }
    }
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "placeholders": {
      "count": {
        "type": "num"
      }
    }
  }
}
```

```json
// lib/l10n/app_es.arb
{
  "@@locale": "es",
  "appTitle": "Centro Empresarial",
  "welcomeMessage": "¡Bienvenido de nuevo, {userName}!",
  "itemCount": "{count, plural, =0{Sin elementos} =1{1 elemento} other{{count} elementos}}"
}
```

### Consuming Localized Strings in UI:

```dart
class WelcomeBanner extends StatelessWidget {
  final String userName;
  const WelcomeBanner({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(l10n.welcomeMessage(userName)),
        Text(l10n.itemCount(5)),
      ],
    );
  }
}
```

---

## 2. Right-to-Left (RTL) Layout Architecture (Arabic, Hebrew)

Flutter supports bidirectional layouts natively.

**❌ NEVER** hardcode `EdgeInsets.left` or `EdgeInsets.right`.
**✅ ALWAYS** use `EdgeInsetsDirectional.start` and `EdgeInsetsDirectional.end`.

```dart
// ❌ WRONG: Hardcoded left/right breaks in RTL (Arabic/Hebrew)
Padding(
  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
  child: const Icon(Icons.arrow_forward),
);

// ✅ ALWAYS: Directional padding automatically mirrors in RTL
Padding(
  padding: const EdgeInsetsDirectional.only(start: 16.0, end: 8.0),
  child: const Icon(Icons.adaptive.arrow_forward),
);
```

---

## 3. Screen Reader Compatibility with `Semantics`

VoiceOver (iOS) and TalkBack (Android) navigate Flutter applications using the **Semantics Tree**.

### Labeling Custom or Icon-Only Buttons:

```dart
// ✅ ALWAYS: Wrap icon-only buttons with explicit Semantics
Semantics(
  button: true,
  label: 'Delete invoice record',
  hint: 'Double tap to permanently remove this invoice',
  child: IconButton(
    icon: const Icon(Icons.delete),
    onPressed: () => onDelete(),
  ),
);
```

### Excluding Decorative Images from Screen Readers:

```dart
// Exclude background gradients, decorative stars, or abstract illustrations
ExcludeSemantics(
  child: Image.asset('assets/images/decorative_pattern.png'),
);
```

---

## 4. Touch Target Minimum Sizes & Dynamic Font Scaling

- **Touch Target**: Minimum **48x48 dp** for all interactive widgets.
- **Dynamic Text Scaling**: Never lock widgets to rigid heights that clip scaled text.

```dart
// Avoid clipping when user enables large accessibility fonts in OS settings
ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 48.0), // Allows growing
  child: ElevatedButton(
    onPressed: () {},
    child: Text(
      l10n.submitButton,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  ),
);
```

---

**Execution Protocol**
1. **Always use `.arb` files with pluralization support**: Eliminates awkward "1 items" UI bugs.
2. **Always use `EdgeInsetsDirectional`**: Guarantees seamless RTL layout mirroring.
3. **Audit custom gesture widgets with `Semantics`**: Ensure every `GestureDetector` has an accessible label.
4. **Test on device with TalkBack/VoiceOver enabled**: Verify full navigation without visual aids.
