---
name: react-native-navigation-advanced
description: The ultimate architectural standard for complex navigation flows, strict type-safety, deep linking, and transition animations in React Native.
author: Diego Villanueva
trigger: When configuring React Navigation, Expo Router, defining route parameters, setting up deep links, or structuring nested navigators.
---

# Advanced Navigation Architecture

Navigation in mobile apps is not just changing screens; it is a complex state machine that interacts with hardware buttons, deep links, push notifications, and the operating system's memory management. A poorly structured navigation tree is the #1 cause of spaghetti code and untraceable memory leaks in React Native.

## 1. The Parameter Anti-Pattern (CRITICAL)

The navigation state is serialized and preserved by the OS (and deep links). You must **NEVER** pass large objects, arrays, or functions as navigation parameters.

```typescript
// ❌ ATROCIOUS: Passing the full object or functions
navigation.navigate('Profile', { user: { id: 1, name: 'Diego', avatar: '...' }, onSave: () => {} });

// ✅ ALWAYS: Pass IDs. The target screen fetches or selects the data.
navigation.navigate('Profile', { userId: 1 });
```
*Why?* 
1. Deep links only support strings. If a user clicks `myapp://profile/1`, you only have the ID. 
2. Passing objects creates stale data (the object changes in the DB, but the screen holds an old copy in its route params).

## 2. Strict Type Safety

Every route must be statically typed. If a developer typos a route name or forgets a required parameter, the compilation must fail.

```typescript
// ✅ ALWAYS: Define the ParamList globally
export type RootStackParamList = {
  Home: undefined;
  Profile: { userId: string };
  Settings: undefined;
};

// Strongly typing Hooks
import { useRoute, RouteProp, useNavigation, NavigationProp } from '@react-navigation/native';

export function ProfileScreen() {
  const route = useRoute<RouteProp<RootStackParamList, 'Profile'>>();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  
  return <Text>User: {route.params.userId}</Text>;
}
```

## 3. The Authentication Flow (State-Driven Navigation)

Never imperatively navigate to the Login screen (`navigation.navigate('Login')`). Navigation must react declaratively to the authentication state.

```tsx
// ✅ ALWAYS: State-driven Auth Flow
export function RootNavigator() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) return <SplashScreen />;

  return (
    <Stack.Navigator>
      {isAuthenticated ? (
        // User is signed in
        <>
          <Stack.Screen name="Home" component={HomeTabs} />
          <Stack.Screen name="Profile" component={ProfileScreen} />
        </>
      ) : (
        // User is NOT signed in
        <Stack.Screen name="Login" component={LoginScreen} />
      )}
    </Stack.Navigator>
  );
}
```

## 4. Deep Linking & Universal Links

Your app must be fully indexable from the outside world. Every screen should theoretically be accessible via a URL.

- **Configuration**: Define the prefix (`myapp://` or `https://myweb.com`) and map the paths to your strict route names.
- **Expo Router**: If using Expo Router, deep linking is automatic based on the file system (`app/user/[id].tsx` naturally resolves to `/user/123`).

```typescript
// React Navigation Deep Link Config
const linking = {
  prefixes: ['myapp://', 'https://myapp.com'],
  config: {
    screens: {
      Home: '',
      Profile: 'user/:userId', // Maps to myapp://user/123
      Settings: 'settings',
    },
  },
};
```

## 5. Nesting Navigators Safely

Nesting a Stack inside a Tab, inside a Drawer, inside a Root Stack is a common requirement but degrades performance and complicates typing.

- **Limit Depth**: Never nest more than 3 levels deep.
- **Typing Nested Navigators**: Use `CompositeNavigationProp` to allow a child screen to navigate to a parent screen without TS errors.

```typescript
import type { CompositeNavigationProp } from '@react-navigation/native';
import type { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import type { StackNavigationProp } from '@react-navigation/stack';

type ProfileScreenNavigationProp = CompositeNavigationProp<
  BottomTabNavigationProp<TabParamList, 'Profile'>,
  StackNavigationProp<RootStackParamList>
>;
```

## 6. Hardware Back Button (Android)

Android has a physical/gesture back button. You must respect it, but sometimes you need to intercept it (e.g., closing a custom modal or preventing exit when a form is half-filled).

```typescript
// ✅ ALWAYS: Intercepting hardware back button
import { BackHandler } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';

useFocusEffect(
  useCallback(() => {
    const onBackPress = () => {
      if (isFormDirty) {
        showDiscardAlert();
        return true; // Prevent default behavior
      }
      return false; // Let the system handle it
    };

    BackHandler.addEventListener('hardwareBackPress', onBackPress);
    return () => BackHandler.removeEventListener('hardwareBackPress', onBackPress);
  }, [isFormDirty])
);
```

## 7. Modal Presentations & Transitions

React Navigation allows screens to behave as modals natively.

- **Presentation**: Use `presentation: 'modal'` (or `transparentModal`) in the screen options so it slides up from the bottom (iOS style) instead of pushing from the side.
- **Shared Element Transitions**: Use `react-native-reanimated`'s Shared Element feature to animate an image from a list smoothly into the details screen.

```tsx
<Stack.Screen 
  name="ImageGallery" 
  component={GalleryScreen} 
  options={{
    presentation: 'transparentModal',
    animation: 'fade',
    headerShown: false,
  }}
/>
```

## 8. Persistence (Developer Experience)

When writing UI, hot-reloading resets the navigation state, dropping you back to the home screen. Persist the navigation state to `AsyncStorage` (only in `__DEV__`) so you stay on the screen you are currently editing.

```tsx
// ✅ ALWAYS: Navigation Persistence (Dev only)
const [initialState, setInitialState] = useState();

useEffect(() => {
  if (__DEV__) {
    AsyncStorage.getItem('NAV_STATE').then(state => setInitialState(JSON.parse(state)));
  }
}, []);

<NavigationContainer
  initialState={initialState}
  onStateChange={(state) => {
    if (__DEV__) AsyncStorage.setItem('NAV_STATE', JSON.stringify(state));
  }}
>
```

---

**Execution Protocol**
1. **Never mutate `route.params`**: The `params` object is frozen. If you need to update it, use `navigation.setParams()`.
2. **Global Navigation Ref**: If you must navigate from outside a React component (e.g., inside a Redux saga or Axios interceptor), use a globally exported `createNavigationContainerRef`.
3. **Expo Router Migration**: If starting a greenfield project en 2024+, strongly prefer Expo Router over raw React Navigation. It brings Next.js routing paradigms to mobile, eliminating 80% of manual linking and boilerplate.
