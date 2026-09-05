---
name: unity-editor-tools
description: Unity Editor extensibility mastery including Custom EditorWindows, PropertyDrawers, custom inspectors, Gizmos, SceneView overlays, and editor automation tools.
author: Diego Villanueva
trigger: When creating custom editor tools, inspector customization, debug visualization, editor windows, or level design tools for the Unity Editor.
---

# Editor Tools & Extensibility

Custom Editor tools transform Unity from a generic engine into a bespoke development environment tailored to your game. Invest in tools early — they compound productivity over the entire project.

## 1. Custom Inspector

```csharp
// ✅ Custom Inspector for better UX
#if UNITY_EDITOR
using UnityEditor;

[CustomEditor(typeof(EnemyConfig))]
public class EnemyConfigEditor : Editor
{
    private SerializedProperty _name, _health, _speed, _damage;
    private SerializedProperty _aiType, _patrolRadius;
    private bool _showCombat = true;
    private bool _showAI = true;

    private void OnEnable()
    {
        _name = serializedObject.FindProperty("enemyName");
        _health = serializedObject.FindProperty("maxHealth");
        _speed = serializedObject.FindProperty("moveSpeed");
        _damage = serializedObject.FindProperty("attackDamage");
        _aiType = serializedObject.FindProperty("aiType");
        _patrolRadius = serializedObject.FindProperty("patrolRadius");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.PropertyField(_name);
        EditorGUILayout.Space(10);

        _showCombat = EditorGUILayout.Foldout(_showCombat, "Combat Stats", true);
        if (_showCombat)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.IntSlider(_health, 1, 1000, new GUIContent("Max Health"));
            EditorGUILayout.Slider(_speed, 0f, 20f, new GUIContent("Move Speed"));
            EditorGUILayout.IntSlider(_damage, 1, 100, new GUIContent("Attack Damage"));

            // Visual health bar preview
            var rect = GUILayoutUtility.GetRect(18, 18, "TextField");
            EditorGUI.ProgressBar(rect, _health.intValue / 1000f, $"HP: {_health.intValue}");
            EditorGUI.indentLevel--;
        }

        _showAI = EditorGUILayout.Foldout(_showAI, "AI Settings", true);
        if (_showAI)
        {
            EditorGUI.indentLevel++;
            EditorGUILayout.PropertyField(_aiType);
            if (_aiType.enumValueIndex == 1) // Patrol type
                EditorGUILayout.PropertyField(_patrolRadius);
            EditorGUI.indentLevel--;
        }

        serializedObject.ApplyModifiedProperties();
    }
}
#endif
```

## 2. Property Drawers

```csharp
// ✅ Custom attribute + drawer for reusable Inspector widgets
public class MinMaxRangeAttribute : PropertyAttribute
{
    public float Min, Max;
    public MinMaxRangeAttribute(float min, float max) { Min = min; Max = max; }
}

#if UNITY_EDITOR
[CustomPropertyDrawer(typeof(MinMaxRangeAttribute))]
public class MinMaxRangeDrawer : PropertyDrawer
{
    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {
        var attr = (MinMaxRangeAttribute)attribute;
        var minProp = property.FindPropertyRelative("min");
        var maxProp = property.FindPropertyRelative("max");

        float min = minProp.floatValue;
        float max = maxProp.floatValue;

        var labelRect = new Rect(position.x, position.y, EditorGUIUtility.labelWidth, position.height);
        var sliderRect = new Rect(labelRect.xMax, position.y, position.width - labelRect.width - 110, position.height);
        var minRect = new Rect(sliderRect.xMax + 5, position.y, 50, position.height);
        var maxRect = new Rect(minRect.xMax + 5, position.y, 50, position.height);

        EditorGUI.LabelField(labelRect, label);
        EditorGUI.MinMaxSlider(sliderRect, ref min, ref max, attr.Min, attr.Max);
        min = EditorGUI.FloatField(minRect, Mathf.Round(min * 100f) / 100f);
        max = EditorGUI.FloatField(maxRect, Mathf.Round(max * 100f) / 100f);

        minProp.floatValue = Mathf.Clamp(min, attr.Min, max);
        maxProp.floatValue = Mathf.Clamp(max, min, attr.Max);
    }
}
#endif

// Usage:
[System.Serializable]
public struct FloatRange
{
    public float min, max;
}

public class EnemySpawner : MonoBehaviour
{
    [MinMaxRange(0.5f, 10f)]
    public FloatRange spawnInterval; // Shows as min-max slider in Inspector!
}
```

## 3. Custom Editor Window

```csharp
// ✅ Level design tool window
#if UNITY_EDITOR
public class LevelDesignerWindow : EditorWindow
{
    private GameObject _selectedPrefab;
    private float _brushSize = 1f;
    private LayerMask _paintLayer;
    private Vector2 _scrollPos;

    [MenuItem("Tools/Level Designer")]
    public static void ShowWindow()
    {
        GetWindow<LevelDesignerWindow>("Level Designer");
    }

    private void OnGUI()
    {
        GUILayout.Label("Level Design Tools", EditorStyles.boldLabel);
        EditorGUILayout.Space();

        _selectedPrefab = (GameObject)EditorGUILayout.ObjectField(
            "Prefab", _selectedPrefab, typeof(GameObject), false);

        _brushSize = EditorGUILayout.Slider("Brush Size", _brushSize, 0.5f, 10f);
        _paintLayer = EditorGUILayout.LayerField("Paint Layer", _paintLayer);

        EditorGUILayout.Space();
        if (GUILayout.Button("Clear All Placed Objects"))
        {
            if (EditorUtility.DisplayDialog("Confirm", "Delete all placed objects?", "Yes", "Cancel"))
                ClearAll();
        }
    }

    private void OnSceneGUI(SceneView sceneView)
    {
        if (_selectedPrefab == null) return;

        HandleUtility.AddDefaultControl(GUIUtility.GetControlID(FocusType.Passive));
        Event e = Event.current;

        Ray ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
        if (Physics.Raycast(ray, out var hit, 1000f, _paintLayer))
        {
            Handles.color = new Color(0, 1, 0, 0.3f);
            Handles.DrawSolidDisc(hit.point, hit.normal, _brushSize);

            if (e.type == EventType.MouseDown && e.button == 0)
            {
                PlacePrefab(hit.point, hit.normal);
                e.Use();
            }
        }
        sceneView.Repaint();
    }

    private void OnEnable() => SceneView.duringSceneGui += OnSceneGUI;
    private void OnDisable() => SceneView.duringSceneGui -= OnSceneGUI;
}
#endif
```

## 4. Gizmos (Debug Visualization)

```csharp
// ✅ Visual debugging in Scene view
public class EnemyAI : MonoBehaviour
{
    [SerializeField] private float _detectionRadius = 10f;
    [SerializeField] private float _attackRange = 2f;
    [SerializeField] private float _viewAngle = 120f;

    private void OnDrawGizmosSelected()
    {
        // Detection radius (yellow wire sphere)
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(transform.position, _detectionRadius);

        // Attack range (red wire sphere)
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, _attackRange);

        // View cone
        Gizmos.color = new Color(0, 1, 0, 0.2f);
        Vector3 leftDir = Quaternion.Euler(0, -_viewAngle / 2, 0) * transform.forward;
        Vector3 rightDir = Quaternion.Euler(0, _viewAngle / 2, 0) * transform.forward;
        Gizmos.DrawRay(transform.position, leftDir * _detectionRadius);
        Gizmos.DrawRay(transform.position, rightDir * _detectionRadius);
    }
}
```

---

**Execution Protocol**
1. **#if UNITY_EDITOR**: ALL editor code MUST be wrapped in `#if UNITY_EDITOR` or placed in an Editor assembly to avoid build errors.
2. **SerializedProperty API**: ALWAYS use `SerializedProperty` in custom inspectors for undo support and prefab overrides.
3. **Gizmos for Debug**: Every AI, trigger zone, and detection radius SHOULD have Gizmo visualization.
4. **Tools Save Time**: If a level designer or artist repeats a manual task more than 10 times, build an editor tool for it.
5. **MenuItem for Accessibility**: Register tools under `Tools/` menu with `[MenuItem]` for easy access.
