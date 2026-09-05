---
name: unity-ci-cd-devops
description: CI/CD and DevOps for Unity projects including GameCI GitHub Actions, Unity Cloud Build, Jenkins pipelines, automated testing, and store submission automation.
author: Diego Villanueva
trigger: When setting up continuous integration, automated builds, test pipelines, or store deployment automation for Unity projects.
---

# CI/CD & DevOps for Unity

Manual Unity builds are slow, error-prone, and unscalable. Automate everything: test on commit, build nightly, deploy to stores automatically.

## 1. GameCI (GitHub Actions)

```yaml
# ✅ .github/workflows/unity-ci.yml
name: Unity CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        testMode: [EditMode, PlayMode]
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - uses: actions/cache@v4
        with:
          path: Library
          key: Library-${{ hashFiles('Assets/**', 'Packages/**', 'ProjectSettings/**') }}

      - uses: game-ci/unity-test-runner@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          testMode: ${{ matrix.testMode }}
          artifactsPath: TestResults
          checkName: ${{ matrix.testMode }} Test Results

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: Test-${{ matrix.testMode }}
          path: TestResults

  build:
    name: Build (${{ matrix.targetPlatform }})
    needs: test
    runs-on: ubuntu-latest
    strategy:
      matrix:
        targetPlatform:
          - StandaloneWindows64
          - StandaloneLinux64
          - Android
          - iOS
          - WebGL
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - uses: actions/cache@v4
        with:
          path: Library
          key: Library-${{ matrix.targetPlatform }}-${{ hashFiles('Assets/**', 'Packages/**') }}

      - uses: game-ci/unity-builder@v4
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
        with:
          targetPlatform: ${{ matrix.targetPlatform }}
          buildName: MyGame
          versioning: Semantic

      - uses: actions/upload-artifact@v4
        with:
          name: Build-${{ matrix.targetPlatform }}
          path: build/${{ matrix.targetPlatform }}
```

## 2. Unity License Activation

```yaml
# ✅ One-time license activation workflow
name: Activate Unity License
on: workflow_dispatch
jobs:
  activate:
    runs-on: ubuntu-latest
    steps:
      - uses: game-ci/unity-activate@v4
        with:
          unityVersion: 6000.0.0f1
        env:
          UNITY_LICENSE: ${{ secrets.UNITY_LICENSE }}
          UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}
          UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}
```

## 3. Semantic Versioning

```csharp
// ✅ Auto-version from Git tags
// GameCI's `versioning: Semantic` reads git tags
// Tag: v1.2.3 → PlayerSettings.bundleVersion = "1.2.3"

// Manual versioning in build script:
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Build;

public class BuildVersioning : IPreprocessBuildWithReport
{
    public int callbackOrder => 0;

    public void OnPreprocessBuild(UnityEditor.Build.Reporting.BuildReport report)
    {
        string version = System.Environment.GetEnvironmentVariable("BUILD_VERSION") ?? "0.0.1";
        PlayerSettings.bundleVersion = version;
        PlayerSettings.Android.bundleVersionCode = GetBuildNumber();
        PlayerSettings.iOS.buildNumber = GetBuildNumber().ToString();
    }

    private int GetBuildNumber()
    {
        string buildNum = System.Environment.GetEnvironmentVariable("BUILD_NUMBER") ?? "1";
        return int.Parse(buildNum);
    }
}
#endif
```

## 4. Platform-Specific Build Scripts

```csharp
// ✅ Custom build script for advanced configuration
#if UNITY_EDITOR
using UnityEditor;

public static class BuildScript
{
    [MenuItem("Build/Build Android")]
    public static void BuildAndroid()
    {
        PlayerSettings.Android.keystoreName = "keystore.jks";
        PlayerSettings.Android.keystorePass = System.Environment.GetEnvironmentVariable("KEYSTORE_PASS");
        PlayerSettings.Android.keyaliasName = "release";
        PlayerSettings.Android.keyaliasPass = System.Environment.GetEnvironmentVariable("KEY_PASS");

        var options = new BuildPlayerOptions
        {
            scenes = GetEnabledScenes(),
            locationPathName = "build/Android/game.aab",
            target = BuildTarget.Android,
            options = BuildOptions.CompressWithLz4HC
        };

        BuildPipeline.BuildPlayer(options);
    }

    private static string[] GetEnabledScenes()
    {
        return EditorBuildSettings.scenes
            .Where(s => s.enabled)
            .Select(s => s.path)
            .ToArray();
    }
}
#endif
```

## 5. Deployment Automation

```text
✅ Store Deployment Pipeline:
├── Google Play: Use Fastlane + supply gem
│   fastlane supply --aab build/game.aab --track internal
├── Apple App Store: Use Fastlane + deliver
│   fastlane deliver --ipa build/game.ipa --skip_screenshots
├── Steam: Use steamcmd + depot upload
│   steamcmd +login user pass +run_app_build build.vdf +quit
└── itch.io: Use butler CLI
    butler push build/WebGL user/game:html5
```

---

**Execution Protocol**
1. **Test Before Build**: CI pipeline MUST run Edit Mode + Play Mode tests BEFORE building.
2. **Cache Library Folder**: ALWAYS cache the `Library/` folder in CI to avoid 30+ minute import times.
3. **LFS for Assets**: Use `actions/checkout` with `lfs: true` for projects using Git LFS.
4. **Secrets Management**: NEVER commit Unity licenses, keystores, or API keys. Use CI secrets.
5. **Build Matrix**: Build all target platforms in parallel using matrix strategy.
