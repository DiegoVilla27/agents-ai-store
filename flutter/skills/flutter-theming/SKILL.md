---
name: flutter-theming
description: The ultimate architectural standard for Enterprise Flutter Theming Material 3 ColorSchemes, ThemeExtensions for Brand Tokens, Typography, and Dark Mode.
author: Diego Villanueva
trigger: When building UI components, applying colors/fonts, configuring dark mode, or setting up the Design System.
---

# Enterprise Flutter Theming Architecture

A design system is the bridge between Design (Figma) and Code. If developers are writing `Colors.grey[300]` or `TextStyle(fontSize: 14)` inside widgets, the bridge is broken.

**THE CORE RULE**: You MUST NEVER hardcode a color, a font size, or a padding value in a Widget. Every visual property must be drawn from the `Theme` or a `ThemeExtension`.

## 1. Material 3 `ColorScheme`

Flutter's Material 3 is heavily opinionated. It relies on a mathematical `ColorScheme` where every background color (e.g., `primary`) has a mathematically contrasting text color (e.g., `onPrimary`).

**❌ NEVER** use `Colors.black` or `Colors.white`. If you force `Colors.white` for text, it will vanish in Light Mode.

```dart
// ✅ ALWAYS: Use semantic ColorScheme tokens for perfect Dark/Light mode support
Container(
  // Surface is for cards/backgrounds
  color: Theme.of(context).colorScheme.surface, 
  child: Text(
    'Hello World',
    // onSurface guarantees the text will be readable on the surface color
    style: TextStyle(color: Theme.of(context).colorScheme.onSurface), 
  ),
)
```

## 2. Typography (`TextTheme`)

Stop creating manual `TextStyle` objects in every file. Material 3 provides 15 standard text styles (Display, Headline, Title, Body, Label - Large/Medium/Small).

```dart
// ✅ ALWAYS: Draw text styles from the central TextTheme
Text(
  'Article Title',
  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
    // You may override font weight or color if absolutely necessary, 
    // but the size and family MUST come from the Theme.
    fontWeight: FontWeight.bold, 
  ),
)
```

## 3. Global Component Theming

If you find yourself passing `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))` to 50 different `ElevatedButton`s, you have failed the architecture.

You MUST define component styles globally in `ThemeData`.

```dart
// ✅ ALWAYS: Define global component shapes and colors once
final theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      // Automatically uses colorScheme.primary for background
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
  ),
);
```

## 4. `ThemeExtension` (The Enterprise Secret)

Material 3 is great, but it lacks semantic colors for businesses (e.g., Success Green, Warning Yellow, Brand Gradients) and it doesn't handle Spacing tokens. 

You MUST use `ThemeExtension` to inject custom Design Tokens into the Flutter Theme.

```dart
// 1. Define the Extension
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;

  const AppColors({required this.success, required this.warning});

  @override
  ThemeExtension<AppColors> copyWith({Color? success, Color? warning}) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

// 2. Add it to ThemeData
final lightTheme = ThemeData(
  extensions: const [
    AppColors(success: Colors.green, warning: Colors.orange),
    // You should also create an AppSpacing extension for gap/padding tokens!
  ],
);

// 3. Use it in the UI effortlessly
Widget build(BuildContext context) {
  final appColors = Theme.of(context).extension<AppColors>()!;
  return Container(color: appColors.success);
}
```

## 5. Dynamic Color (Material You)

If you are building an Android app, users expect the app to match their system wallpaper colors (Android 12+).

Use the `dynamic_color` package to merge the system colors with your brand colors.

```dart
// ✅ ALWAYS: Support Material You on Android
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    ColorScheme lightScheme;
    if (lightDynamic != null) {
      // User's Android wallpaper colors! Harmonize them with our Brand Seed.
      lightScheme = lightDynamic.harmonized();
    } else {
      // Fallback for iOS or old Androids
      lightScheme = ColorScheme.fromSeed(seedColor: brandBlue);
    }
    
    return MaterialApp(
      theme: ThemeData(colorScheme: lightScheme),
      home: Home(),
    );
  }
)
```

---

**Execution Protocol**
1. **Semantic Naming**: Never name a variable `lightGrey`. If you change it to dark grey in Dark Mode, the name `lightGrey` becomes a lie. Name it semantically: `surfaceVariant` or `dividerColor`.
2. **Opacity in Colors**: Do not use `color.withOpacity(0.5)` frequently in the UI. If a color needs opacity, define it as a specific token in your `ThemeExtension` so it can be managed centrally.
3. **The `brightness` property**: Always rely on `Theme.of(context).brightness == Brightness.dark` to detect dark mode, NEVER rely on `MediaQuery.platformBrightness` (unless you specifically want to ignore the user's in-app theme toggle and force the OS theme).
