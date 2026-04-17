---
name: react-native-core
description: >
  Foundational patterns for React Native and Expo mobile development.
  Trigger: When starting a React Native project, building mobile UI, or optimizing list performance.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

## Semantic Mobile UI (REQUIRED)

Use native components optimized for mobile interaction.

```typescript
// ✅ ALWAYS: Use Pressable for better haptic control
<Pressable 
  onPress={handlePress} 
  style={({ pressed }) => ({ opacity: pressed ? 0.5 : 1 })}
>
  <Text>Tap me</Text>
</Pressable>

// ❌ NEVER: TouchableOpacity as default
// Pressable is the modern and more flexible alternative for all interactions.
```

---

## Performance in Lists (REQUIRED)

Never block the main thread with long lists.

| Component | When to Use |
|-----------|-------------|
| **ScrollView** | Small datasets or simple layouts that fit in memory. |
| **FlatList** | Large datasets (infinite scrolling). Uses virtualization. |
| **SectionList** | Grouped data with sticky headers. |

```typescript
// ✅ ALWAYS: Use memoized renderItem and getItemLayout for FlatList
<FlatList
  data={data}
  renderItem={renderItem}
  keyExtractor={(item) => item.id}
  initialNumToRender={10}
/>
```

---

## Platform Specifics (REQUIRED)

```typescript
// ✅ ALWAYS: Handle Safe Area and Platform differences
import { SafeAreaView, Platform, StyleSheet } from "react-native";

const styles = StyleSheet.create({
  container: {
    paddingTop: Platform.OS === "android" ? 25 : 0,
    flex: 1,
  },
});
```

---

## Execution Protocol (REQUIRED)

1. **Setup**: Use **Expo** for rapid development and EAS for builds.
2. **Layout**: Use **Flexbox** (Yoga engine) which is the default for React Native.
3. **Bridge**: Minimize passes across the bridge; keep animations in the native driver (`useNativeDriver: true`).
4. **Style**: Use `StyleSheet.create` for performance (avoid inline styles).

---

## Uncompromising Constraints

- **No Over-rendering**: Use `React.memo` for list items to prevent devastating performance drops.
- **Async Safety**: Always clear timers or listeners in `useEffect` cleanup to avoid memory leaks.
- **Feedback**: Every interaction must have immediate visual feedback (e.g., opacity change).
 Broadway.
