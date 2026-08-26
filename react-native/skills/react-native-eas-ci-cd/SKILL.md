---
name: react-native-eas-ci-cd
description: The ultimate architectural standard for React Native CI/CD with Expo Application Services (EAS Build, EAS Submit, EAS Update OTA Live JS Patching), and GitHub Actions.
author: Diego Villanueva
trigger: When configuring EAS Build, automating App Store/Play Store submissions with EAS Submit, deploying Over-The-Air live updates with EAS Update, or setting up mobile CI/CD pipelines.
---

# Enterprise React Native CI/CD & EAS Update Architecture

Managing mobile releases across iOS and Android requires automated cloud compilation (**EAS Build**), direct store delivery (**EAS Submit**), and instant live JS bundle patching (**EAS Update**) without waiting for App Store or Google Play review queues.

---

## 1. EAS Configuration (`eas.json`)

```json
// eas.json
{
  "cli": {
    "version": ">= 12.0.0",
    "appVersionSource": "remote"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "channel": "development"
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview",
      "ios": {
        "simulator": true
      }
    },
    "production": {
      "channel": "production",
      "autoIncrement": true,
      "env": {
        "EXPO_PUBLIC_API_URL": "https://api.enterprise.com"
      }
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "apple-dev@enterprise.com",
        "ascAppId": "1234567890",
        "appleTeamId": "TEAM1234"
      },
      "android": {
        "serviceAccountKeyPath": "./google-service-account.json",
        "track": "internal"
      }
    }
  }
}
```

---

## 2. Instant Over-The-Air (OTA) Live Updates with `eas update`

When deploying critical bug fixes or UI tweaks that don't involve native binary changes, publish an instant OTA patch:

```bash
# 1. Publish live update to production channel
eas update --channel production --message "Fix critical checkout button calculation"

# 2. View active updates and rollbacks
eas update:list
eas update:rollback --channel production
```

### In-App Update Checker Hook (`useAutoUpdates.ts`):

```typescript
// src/hooks/useAutoUpdates.ts
import * as Updates from 'expo-updates';
import { useEffect } from 'react';
import { Alert } from 'react-native';

export function useAutoUpdates() {
  useEffect(() => {
    async function checkForUpdates() {
      if (__DEV__) return; // Disable in development

      try {
        const update = await Updates.checkForUpdateAsync();
        if (update.isAvailable) {
          await Updates.fetchUpdateAsync();
          Alert.alert(
            'Update Available',
            'A new version has been downloaded. Restart now to apply updates?',
            [
              { text: 'Later', style: 'cancel' },
              { text: 'Restart', onPress: () => Updates.reloadAsync() },
            ]
          );
        }
      } catch (error) {
        console.warn('Failed to check for OTA update:', error);
      }
    }

    checkForUpdates();
  }, []);
}
```

---

## 3. GitHub Actions Automated Release Pipeline

```yaml
# .github/workflows/deploy-mobile.yml
name: EAS Mobile CI/CD

on:
  push:
    branches: [main]

jobs:
  build-and-submit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Setup EAS CLI
        uses: expo/expo-github-action@v8
        with:
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Install Dependencies
        run: npm ci

      - name: Run Test Suite
        run: npm test

      - name: Build & Submit to Stores (iOS & Android)
        run: eas build --platform all --profile production --auto-submit --non-interactive
```

---

**Execution Protocol**
1. **Never use `eas update` for native code changes**: If modifying `app.json` plugins, permissions, or native code, run a full `eas build`.
2. **Always link build profiles to channels**: Ensures OTA updates only target the matching binary runtime version (`runtimeVersion: { policy: 'appVersion' }`).
3. **Use remote app versioning**: Let EAS auto-increment build numbers to prevent store upload rejections.
