---
name: nextjs-shadcn-ui
description: The ultimate architectural standard for building accessible, themeable, and highly customizable UI components using Shadcn UI, Radix, and Tailwind CSS.
author: Diego Villanueva
trigger: When building UI components, forms, modals, or implementing dark mode and design systems.
---

# Next.js + Shadcn UI Architecture

Shadcn UI is **NOT** a traditional component library like Material UI or Chakra. It is a collection of beautifully designed, accessible (Radix UI) components that you **copy and paste** into your codebase. You own the code, you own the styling, and you own the accessibility.

## 1. Installation & Ownership

Never install a shadcn component by copy-pasting from GitHub manually. Always use the CLI to ensure dependencies (like Radix primitives or `lucide-react`) are installed correctly.

```bash
# ✅ ALWAYS: Use the CLI to add components
npx shadcn@latest add button dialog form
```

**Architectural Boundary**: All raw Shadcn components must live in the `components/ui` folder. Do NOT mix them with your domain-specific business components (like `UserProfileCard` or `CheckoutForm`), which should live in `components/features`.

## 2. The `cn()` Utility (Tailwind Merge)

When building variants or accepting `className` props in your own components, you will run into Tailwind specificity conflicts (e.g., `px-4 px-8` might resolve unpredictably). 

You MUST wrap all dynamic classes in the `cn()` utility, which uses `clsx` for conditional logic and `tailwind-merge` to resolve conflicts safely.

```tsx
// ❌ ATROCIOUS: Unpredictable specificity if className contains 'bg-red-500'
export function CustomCard({ className, isActive }) {
  return <div className={`bg-white p-4 ${isActive ? 'shadow-lg' : ''} ${className}`} />;
}

// ✅ ALWAYS: Use cn() to merge and resolve Tailwind classes safely
import { cn } from "@/lib/utils";

export function CustomCard({ className, isActive }: { className?: string, isActive?: boolean }) {
  return (
    <div 
      className={cn(
        "bg-white p-4 transition-all",
        isActive && "shadow-lg scale-105",
        className // If className is "p-8 bg-black", it safely overrides the defaults
      )} 
    />
  );
}
```

## 3. Server vs Client Components (RSC)

Many Shadcn components (like Dialogs, Dropdowns, and Accordions) require React state to track whether they are open or closed. Therefore, they include the `"use client"` directive.

**CRITICAL RULE**: Just because a Shadcn Modal is a Client Component does NOT mean your entire page must be a Client Component. You can pass Server Components as `children` to Client Components!

```tsx
// ✅ ALWAYS: Pass Server Components as children to Client UI primitives
import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";

export default async function Dashboard() {
  const secureData = await db.fetchSecretData(); // SERVER SIDE

  return (
    <Dialog>
      <DialogTrigger>Open Secret</DialogTrigger>
      {/* DialogContent is a Client Component, but secureData was fetched securely on the server! */}
      <DialogContent>
        <p>The secret is: {secureData}</p> 
      </DialogContent>
    </Dialog>
  );
}
```

## 4. CSS Variables for Theming

Shadcn uses CSS variables (`hsl`) in `globals.css` to define colors, rather than hardcoding Tailwind classes like `bg-blue-500`. This allows for instant Dark Mode swapping without writing `dark:bg-blue-900` on every single element.

```css
/* ✅ ALWAYS: Use CSS variables for design system tokens (globals.css) */
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 47.4% 11.2%;
  }
}
```
*In your components, you simply write `className="bg-primary text-primary-foreground"`. Tailwind handles the rest.*

## 5. Forms: The Holy Trinity (Shadcn + RHF + Zod)

Forms are the most complex part of React. Shadcn provides a `<Form>` wrapper that perfectly integrates `react-hook-form` (for state) and `zod` (for validation) while automatically handling ARIA accessibility attributes for screen readers.

```tsx
// ✅ ALWAYS: Use the Shadcn Form pattern for complex inputs
"use client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

const schema = z.object({ email: z.string().email() });

export function NewsletterForm() {
  const form = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: { email: "" },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(data => console.log(data))}>
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                {/* 
                  The Input automatically receives aria-invalid="true" 
                  if validation fails! 
                */}
                <Input placeholder="you@acme.com" {...field} />
              </FormControl>
              {/* Error messages render here automatically */}
              <FormMessage /> 
            </FormItem>
          )}
        />
        <Button type="submit">Subscribe</Button>
      </form>
    </Form>
  );
}
```

---

**Execution Protocol**
1. **Never edit `node_modules`**: Because Shadcn places raw `.tsx` files in your `components/ui` folder, you CAN and SHOULD edit them to match your enterprise design system. Want all buttons to have a specific shadow? Edit `components/ui/button.tsx`.
2. **Icons**: Shadcn defaults to `lucide-react`. Always import icons from this library to maintain consistent stroke widths and visual language across the platform.
3. **Avoid Client Side Rendering where possible**: Even though Shadcn gives you access to beautifully animated Client Components, always prefer standard HTML elements (`<a>` instead of `<Button onClick={() => router.push()}>`) if no complex interactivity is needed, to maximize SEO and minimize JS payload.
