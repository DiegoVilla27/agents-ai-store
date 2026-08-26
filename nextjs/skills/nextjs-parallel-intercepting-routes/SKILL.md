---
name: nextjs-parallel-intercepting-routes
description: The ultimate architectural standard for Advanced Next.js Routing with Parallel Routes (@slot), Intercepting Routes ((.)modal), Photo Feeds, and Contextual Modals.
author: Diego Villanueva
trigger: When implementing modal routes with unique URLs, parallel dashboard slots, contextual routing, or intercepting navigations in Next.js App Router.
---

# Enterprise Next.js Parallel & Intercepting Routes Architecture

Complex web applications require multi-pane dashboards and shareable modals (e.g. clicking an item opens an overlay modal with URL `/photos/123`, while refreshing or opening that URL directly renders the full standalone page). **Parallel Routes (`@slot`)** and **Intercepting Routes (`(.)route`)** enable this seamlessly.

---

## 1. Folder Structure Architecture

```text
src/app/
├── layout.tsx                # Accepts { children, modal } props
├── page.tsx                  # Main feed / list
├── @modal/                   # Parallel route slot named 'modal'
│   ├── default.tsx           # Fallback when modal is closed (returns null)
│   └── (.)photos/[id]/       # Intercepts navigation to /photos/[id] from feed
│       └── page.tsx          # Modal UI component
└── photos/[id]/              # Standalone hard-refresh route
    └── page.tsx              # Full-page standalone UI component
```

---

## 2. Root Layout Integration with Parallel Slot

```tsx
// src/app/layout.tsx
import React from 'react';

interface RootLayoutProps {
  children: React.ReactNode;
  modal: React.ReactNode; // Injected from @modal slot
}

export default function RootLayout({ children, modal }: RootLayoutProps) {
  return (
    <html lang="en">
      <body>
        <main>{children}</main>
        {/* Render modal slot conditionally */}
        {modal}
      </body>
    </html>
  );
}
```

---

## 3. Fallback Component (`@modal/default.tsx`)

The `default.tsx` file is mandatory in parallel route slots to prevent 404s when the modal is closed:

```tsx
// src/app/@modal/default.tsx
export default function DefaultModalSlot() {
  return null; // Renders nothing when no modal route is active
}
```

---

## 4. Intercepted Modal (`@modal/(.)photos/[id]/page.tsx`)

When navigating on the client via `<Link href="/photos/123">`, Next.js intercepts the request and renders the modal in the parallel slot:

```tsx
// src/app/@modal/(.)photos/[id]/page.tsx
import { ModalWrapper } from '@/components/ui/modal-wrapper';
import { PhotoDetailCard } from '@/features/photos/components/photo-detail-card';
import { getPhotoById } from '@/features/photos/services';

interface InterceptedPhotoModalProps {
  params: Promise<{ id: string }>;
}

export default async function InterceptedPhotoModal({ params }: InterceptedPhotoModalProps) {
  const { id } = await params;
  const photo = await getPhotoById(id);

  return (
    <ModalWrapper>
      <PhotoDetailCard photo={photo} isModal />
    </ModalWrapper>
  );
}
```

---

## 5. Modal Wrapper Component (Backdrop & Back Navigation)

```tsx
// src/components/ui/modal-wrapper.tsx
'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useCallback } from 'react';

export function ModalWrapper({ children }: { children: React.ReactNode }) {
  const router = useRouter();

  const handleDismiss = useCallback(() => {
    router.back(); // Reverts URL to previous feed page and closes modal
  }, [router]);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleDismiss();
    };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [handleDismiss]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm">
      <div className="relative max-h-[90vh] max-w-2xl overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl dark:bg-zinc-900">
        <button
          onClick={handleDismiss}
          className="absolute right-4 top-4 rounded-full p-2 text-zinc-400 hover:text-zinc-600 dark:hover:text-white"
          aria-label="Close modal"
        >
          ✕
        </button>
        {children}
      </div>
    </div>
  );
}
```

---

## 6. Standalone Full Page (`photos/[id]/page.tsx`)

Rendered when the user hard-refreshes or shares the URL directly:

```tsx
// src/app/photos/[id]/page.tsx
import { PhotoDetailCard } from '@/features/photos/components/photo-detail-card';
import { getPhotoById } from '@/features/photos/services';
import Link from 'next/link';

export default async function StandalonePhotoPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const photo = await getPhotoById(id);

  return (
    <div className="container mx-auto py-12">
      <Link href="/" className="mb-6 inline-flex items-center text-sm font-semibold text-blue-600">
        ← Back to all photos
      </Link>
      <PhotoDetailCard photo={photo} isModal={false} />
    </div>
  );
}
```

---

**Execution Protocol**
1. **Always create `default.tsx` in every parallel slot directory**: Prevents hydration and routing crashes.
2. **Use `router.back()` to dismiss intercepted modals**: Cleanly pops browser history while keeping URL state in sync.
3. **Use Interception Conventions**:
   - `(.)` matches segments on the same level.
   - `(..)` matches segments one level above.
   - `(...)` matches segments from the root `app/` directory.
