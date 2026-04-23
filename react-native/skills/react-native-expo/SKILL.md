---
description: 'Managed Workflow and Universal Development with Expo'
author: 'Diego Villanueva'
trigger: 'When using Expo for cross-platform mobile development, managed plugins, or OTA updates.'
---

# React Native + Expo

Mastery of the Expo ecosystem for rapid, modern, and high-quality mobile apps.

## ✅ ALWAYS
- Use the **Expo Router** for file-based navigation (Modern standard).
- Leverage **Expo Autolinking** for managing native dependencies effortlessly.
- Use **EAS (Expo Application Services)** for builds, submissions, and OTA updates.
- Use `expo-constants` for accessing environment-specific variables.
- Use `expo-dev-client` to include custom native code while keeping the managed workflow.

## ❌ NEVER
- Eject from Expo unless absolutely necessary for a missing native feature (use `expo-dev-client` instead).
- Hardcode app credentials; use EAS Secrets.
- Ignore the `app.json` or `app.config.js` as the source of truth for app metadata.

## 🛠 Patterns
- **Managed Plugins**: Using `config plugins` to modify native files during prebuild.
- **Universal Apps**: Writing code that runs seamlessly on iOS, Android, and Web.
