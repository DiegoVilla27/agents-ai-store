---
name: flutter-platform-configurator
description: >
  Expert in bridging Flutter with native Android/iOS configurations and build pipelines.
  Trigger: When configuring permissions, native dependencies (Gradle/CocoaPods), or store requirements.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Native iOS Configuration (REQUIRED)

```ruby
# ✅ ALWAYS: Info.plist descriptions and Podfile versioning
# NSFaceIDUsageDescription: "Access to authenticate your profile."

# ❌ NEVER: Missing usage descriptions
# Forbidden: modifying native files without platform-specific syntax knowledge.
```

---

## Native Android Configuration (REQUIRED)

```xml
<!-- ✅ ALWAYS: Explicit permissions and Gradle compatibility -->
<uses-permission android:name="android.permission.USE_BIOMETRIC" />

<!-- ❌ NEVER: Uploading local secrets -->
<!-- Do not upload signing jks or local.properties to the repository. -->
```

---

## Build Pipeline & Dependency Management (REQUIRED)

Maintain a clean build environment.

| Task | Command / Action |
|------|------------------|
| Fix Build Errors | `flutter clean && rm -rf ios/Pods` |
| Refresh Dependencies | `flutter pub get` |
| Audit Native | Check Xcode/Gradle console for warnings. |

---

## Execution Protocol (REQUIRED)

1. **Config**: Edit files in `/ios` and `/android` with surgical precision.
2. **Validate**: Run native builds and monitor the console.
3. **Bridge**: Update `MainActivity` or `AppDelegate` if deep integration is needed.
4. **Docs**: Document manual steps required in the Apple/Google consoles.

---

## Uncompromising Constraints

- **Security**: Signing secrets, certificates, or private keys must never be committed.
- **Professionalism**: Permission messages must be descriptive and pass store reviews.
- **Platform Integrity**: Never apply changes that break one platform to fix another.
