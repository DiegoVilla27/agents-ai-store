---
name: web-typescript-react
description: The ultimate architectural standard for combining React with strict TypeScript, covering generics, polymorphism, advanced hooks, and type safety.
author: Diego Villanueva
trigger: When building React components, custom hooks, defining prop types, or extending native HTML elements with TypeScript.
---

# React + TypeScript Engineering Mastery

React and TypeScript are a phenomenal pair, provided you use TypeScript to enforce the component's contract strictly. You are building UI primitives and features that must be highly predictable, safely extensible, and strictly typed. 

## 1. Component Declaration (The Standard)

Do not use `React.FC` or `React.FunctionComponent`. It provides little benefit, implicitly adds `children` in older React versions, and breaks when returning strings or numbers. Use standard function declarations or arrow functions with explicit return types if needed.

```tsx
// ✅ ALWAYS: Standard function or arrow function
interface ButtonProps {
  label: string;
}

export function Button({ label }: ButtonProps) {
  return <button>{label}</button>;
}

// ❌ NEVER: React.FC
export const Button: React.FC<ButtonProps> = ({ label }) => { ... }
```

## 2. Extending Native HTML Elements

When building reusable UI components (Buttons, Inputs), they must accept all native HTML attributes without you having to manually define them.

```tsx
import { type ComponentPropsWithoutRef } from 'react';

// ✅ ALWAYS: Extend native props safely
interface ButtonProps extends ComponentPropsWithoutRef<'button'> {
  variant?: 'primary' | 'secondary';
  // 'type', 'onClick', 'disabled' are automatically inherited!
}

export function Button({ variant = 'primary', className, ...props }: ButtonProps) {
  return <button className={`btn-${variant} ${className}`} {...props} />;
}
```

*Note: Use `ComponentPropsWithRef<'button'>` if the component uses `forwardRef`.*

## 3. Typing `children`

Do not default to `any`. React provides specific types for children.

```tsx
// ✅ ALWAYS: React.ReactNode for anything renderable (strings, elements, null, arrays)
interface LayoutProps {
  children: React.ReactNode; 
}

// ✅ ALWAYS: React.ReactElement for strictly requiring a single JSX element
interface ModalProps {
  children: React.ReactElement; 
}

// ✅ ALWAYS: Render Props (Function as Child)
interface DataProviderProps {
  children: (data: User[]) => React.ReactNode;
}
```

## 4. Typing Events & Handlers

Do not type the event handler's parameters manually `(e: any) => void`. Let React infer it, or use the precise event types.

```tsx
import type { MouseEvent, ChangeEvent, FormEvent } from 'react';

// Mouse Events
const handleClick = (event: MouseEvent<HTMLButtonElement>) => {
  event.preventDefault();
};

// Input Changes
const handleChange = (event: ChangeEvent<HTMLInputElement>) => {
  console.log(event.target.value);
};

// Form Submissions
const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
  event.preventDefault();
};
```

## 5. Discriminated Unions for Prop Contracts

If a component's props are mutually exclusive, use a discriminated union to prevent impossible combinations.

```tsx
// ❌ WRONG: It's possible to pass BOTH href and onClick, which makes no sense.
interface LinkOrButtonProps {
  href?: string;
  onClick?: () => void;
  text: string;
}

// ✅ ALWAYS: Discriminated Unions
type LinkProps = { as: 'link'; href: string; text: string };
type ButtonProps = { as: 'button'; onClick: () => void; text: string };

type ActionProps = LinkProps | ButtonProps;

export function Action(props: ActionProps) {
  if (props.as === 'link') return <a href={props.href}>{props.text}</a>;
  return <button onClick={props.onClick}>{props.text}</button>;
}
```

## 6. Generic Components

Components can accept type parameters to maintain strict typing between their props.

```tsx
interface ListProps<T> {
  items: T[];
  renderItem: (item: T, index: number) => React.ReactNode;
}

// ✅ ALWAYS: The generic <T> flows from `items` to `renderItem`
export function List<T>({ items, renderItem }: ListProps<T>) {
  return <ul>{items.map((item, i) => <li key={i}>{renderItem(item, i)}</li>)}</ul>;
}

// Usage: Type is inferred automatically!
// <List items={[{ name: 'Diego' }]} renderItem={(user) => user.name} />
```

## 7. Polymorphic Components (`as` prop)

Building components that can render as any HTML tag while keeping type safety.

```tsx
import type { ElementType, ComponentPropsWithoutRef } from 'react';

type TextProps<C extends ElementType> = {
  as?: C;
  className?: string;
} & ComponentPropsWithoutRef<C>;

// ✅ ALWAYS: The props will dynamically adapt based on the `as` tag provided.
export function Text<C extends ElementType = 'span'>({ 
  as, 
  ...props 
}: TextProps<C>) {
  const Component = as || 'span';
  return <Component {...props} />;
}

// Usage:
// <Text as="a" href="/home">Link</Text> // ✅ Valid (href is required for 'a')
// <Text as="button" href="/home">Btn</Text> // ❌ Error (href is invalid on 'button')
```

## 8. Typing Hooks Strictly

### `useState`
```tsx
// Inferenced (Good)
const [count, setCount] = useState(0); 

// Explicit (Required when state can be null/undefined initially)
const [user, setUser] = useState<User | null>(null); 
```

### `useRef`
```tsx
// DOM Elements: Requires `null` initialization
const inputRef = useRef<HTMLInputElement>(null);

// Mutable Values: Does NOT require `null`
const timerRef = useRef<number | undefined>(undefined);
```

### `forwardRef` & `useImperativeHandle`
When exposing custom methods from a child to a parent.

```tsx
import { forwardRef, useImperativeHandle, useRef } from 'react';

export interface ModalHandle {
  open: () => void;
  close: () => void;
}

export const Modal = forwardRef<ModalHandle, { title: string }>(({ title }, ref) => {
  useImperativeHandle(ref, () => ({
    open: () => console.log('Opened'),
    close: () => console.log('Closed')
  }));
  return <div>{title}</div>;
});
```

## 9. Context API (Strict & Safe)

The biggest mistake with Context is forcing developers to deal with `undefined`.

```tsx
import { createContext, useContext, type ReactNode } from 'react';

interface AuthContextType {
  user: User;
  logout: () => void;
}

// 1. Create context with `null`
const AuthContext = createContext<AuthContextType | null>(null);

// 2. Create a custom hook that throws if used outside the provider
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context; // TS now guarantees this is AuthContextType (no longer null)
}

// 3. Provider Component
export function AuthProvider({ children }: { children: ReactNode }) {
  return <AuthContext.Provider value={{ user, logout }}>{children}</AuthContext.Provider>;
}
```

## 10. CSS Properties & Inline Styles

When you absolutely must use inline styles, type them strictly.

```tsx
import type { CSSProperties } from 'react';

interface BoxProps {
  style?: CSSProperties;
}
```

---

**Execution Protocol**
1. **Prop Types vs TS Interfaces**: Never use `prop-types` library. TypeScript handles this at compile time.
2. **Export Prop Interfaces**: Always export the Prop interfaces of your components (`export interface ButtonProps {}`). Other components or pages may need to compose them.
3. **No Index Signatures for Props**: Do not use `[key: string]: any` to blindly accept remaining props. Always use `ComponentPropsWithoutRef`.
