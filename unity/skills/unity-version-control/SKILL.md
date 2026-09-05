---
name: unity-version-control
description: Version control mastery for Unity projects including Git LFS configuration, PlasticSCM, .gitignore best practices, branching strategies, and scene/prefab merge conflict resolution.
author: Diego Villanueva
trigger: When setting up version control for Unity projects, configuring Git LFS, resolving merge conflicts in scenes/prefabs, or defining branching strategies.
---

# Version Control for Unity

Unity projects contain massive binary assets (textures, models, audio) that break standard Git workflows. You MUST use Git LFS or PlasticSCM, and you MUST have a proper `.gitignore`.

## 1. .gitignore (Essential)

```gitignore
# ✅ Unity .gitignore
/[Ll]ibrary/
/[Tt]emp/
/[Oo]bj/
/[Bb]uild/
/[Bb]uilds/
/[Ll]ogs/
/[Uu]ser[Ss]ettings/
/[Mm]emoryCaptures/
/[Rr]ecordings/

# Asset meta files (KEEP .meta files, they store import settings!)
# ❌ NEVER add *.meta to gitignore

# IDE
.vs/
.idea/
*.csproj
*.sln
*.suo
*.user
*.pidb
*.booproj

# OS
.DS_Store
Thumbs.db

# Unity specific
*.apk
*.aab
*.unitypackage
crashlytics-build.properties
```

## 2. Git LFS Configuration

```gitattributes
# ✅ .gitattributes for Git LFS
*.psd filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.tga filter=lfs diff=lfs merge=lfs -text
*.tif filter=lfs diff=lfs merge=lfs -text
*.exr filter=lfs diff=lfs merge=lfs -text
*.hdr filter=lfs diff=lfs merge=lfs -text
*.fbx filter=lfs diff=lfs merge=lfs -text
*.obj filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
*.mb filter=lfs diff=lfs merge=lfs -text
*.ma filter=lfs diff=lfs merge=lfs -text
*.max filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.aif filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.ttf filter=lfs diff=lfs merge=lfs -text
*.otf filter=lfs diff=lfs merge=lfs -text
*.cubemap filter=lfs diff=lfs merge=lfs -text
*.unitypackage filter=lfs diff=lfs merge=lfs -text
```

## 3. Unity Project Settings for VCS

```text
✅ Edit → Project Settings → Editor:
├── Version Control Mode: Visible Meta Files
├── Asset Serialization Mode: Force Text
└── These settings ensure:
    - .meta files are generated (track asset import settings)
    - Scenes/Prefabs are saved as text YAML (diff-able, mergeable)
```

## 4. Branching Strategy

```text
✅ Git Flow for Game Development:
├── main            → Production-ready builds (tagged releases)
├── develop         → Integration branch (nightly builds)
├── feature/*       → Feature branches (feature/combat-system)
├── bugfix/*        → Bug fixes (bugfix/player-stuck-on-wall)
├── release/*       → Release candidates (release/1.2.0)
└── hotfix/*        → Emergency production fixes

✅ Rules:
- Feature branches merge into develop via PR
- Release branches merge into main AND develop
- Hotfix branches merge into main AND develop
- NEVER commit directly to main
```

## 5. Scene & Prefab Merge Conflicts

```text
Problem: Unity scenes and prefabs are YAML files with GUIDs.
         Two developers editing the same scene = merge conflict hell.

✅ Solutions:
1. Scene Splitting: Split levels into multiple additive scenes
   - Level_01_Environment.unity (artist)
   - Level_01_Gameplay.unity (designer)
   - Level_01_Lighting.unity (lighting artist)

2. Prefab-First Workflow: Build everything as prefabs, scenes only reference prefabs
   - Changes to a prefab = changes to the prefab file, not the scene

3. Smart Merge Tool: Unity's YAML Merge tool
   git config merge.unityyamlmerge.driver "path/to/UnityYAMLMerge merge -p %O %A %B %A"

4. Lock Files: Use Git LFS file locking for binary assets and scenes
   git lfs lock Assets/Scenes/Level_01.unity
   git lfs unlock Assets/Scenes/Level_01.unity
```

---

**Execution Protocol**
1. **Force Text Serialization**: ALWAYS set Asset Serialization Mode to "Force Text".
2. **Never Ignore .meta Files**: `.meta` files contain import settings and GUID references. Losing them breaks all asset references.
3. **Git LFS for Binary Assets**: ALL textures, models, audio, and video MUST use Git LFS.
4. **Split Scenes**: Large scenes MUST be split into additive scenes to minimize merge conflicts.
5. **Lock Binary Files**: Use `git lfs lock` when editing scenes or large binary assets collaboratively.
