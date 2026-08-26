---
name: flutter-ci-cd-fastlane-shorebird
description: The ultimate architectural standard for Enterprise Flutter CI/CD, Fastlane (iOS/Android match & signing), Shorebird Code Push (Over-The-Air live patching), and GitHub Actions Store Pipelines.
author: Diego Villanueva
trigger: When configuring Flutter CI/CD, automating App Store/Google Play deployments, setting up Fastlane, or implementing Shorebird Over-The-Air (OTA) live code push.
---

# Enterprise Flutter CI/CD & Shorebird OTA Architecture

Enterprise mobile release management requires automated signing, continuous integration pipelines, and **Shorebird Code Push** to deploy critical Dart bug fixes and feature updates instantly to users without waiting for Apple App Store or Google Play review.

---

## 1. Shorebird Over-The-Air (OTA) Code Push

Shorebird provides seamless Over-The-Air live patching for Flutter applications by replacing the Flutter Dart runtime with an updater-enabled engine.

```bash
# Install Shorebird CLI
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Initialize Shorebird in Flutter project
shorebird init
```

### The Shorebird Release & Patch Workflow:

1. **Create Base Store Release**:
   ```bash
   shorebird release android
   shorebird release ios
   ```
2. **Deploy Instant OTA Patch (No App Store Review Required!)**:
   ```bash
   # Modifies Dart code, fixes bug, and pushes live instantly
   shorebird patch android
   shorebird patch ios
   ```

---

## 2. Fastlane Configuration for Flutter

### iOS Fastfile (`ios/fastlane/Fastfile`)

```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    setup_ci if ENV['CI']
    match(type: "appstore", readonly: true)
    
    # Update build number
    increment_build_number(
      xcodeproj: "Runner.xcodeproj",
      build_number: ENV['GITHUB_RUN_NUMBER']
    )

    # Build IPA using Flutter
    sh("flutter build ipa --release --export-options-plist=ios/ExportOptions.plist")

    # Upload to Apple TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      api_key_path: "fastlane/app_store_key.json"
    )
  end
end
```

### Android Fastfile (`android/fastlane/Fastfile`)

```ruby
default_platform(:android)

platform :android do
  desc "Build and upload Android App Bundle (.aab) to Google Play Internal Track"
  lane :internal do
    sh("flutter build appbundle --release")

    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      json_key: "fastlane/google_play_key.json"
    )
  end
end
```

---

## 3. GitHub Actions Enterprise Pipeline

```yaml
# .github/workflows/deploy-flutter.yml
name: Flutter CI/CD Pipeline

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        run: flutter pub get

      - name: Run Unit & Widget Tests
        run: flutter test --coverage

      - name: Setup Shorebird
        uses: shorebirdtech/actions/setup-shorebird@v1
        with:
          shorebird-token: ${{ secrets.SHOREBIRD_TOKEN }}

      - name: Build & Deploy iOS TestFlight via Fastlane
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
        run: |
          cd ios
          bundle exec fastlane beta
```

---

**Execution Protocol**
1. **Always use Fastlane match with Git repo storage**: Eliminates local code signing certificate chaos.
2. **Never commit `.keystore`, `.jks`, or `.p8` API keys**: Store them encrypted in CI/CD secrets.
3. **Use Shorebird for hotfixes & UI updates**: Reserve App Store binary submissions for native plugin/manifest permission changes.
4. **Enforce `flutter analyze` and `flutter test` as blocking CI steps**: Fail builds before Fastlane triggers.
