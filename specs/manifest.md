# File Manifest

Complete list of files to generate, in build order. Dependencies must be built before dependents.

---

## Build Order Overview

```
1. Configuration files (package.json, tsconfig, etc.)
2. Convex schema and functions
3. Shared libraries (constants, geometry, weeks)
4. React components (leaf → root)
5. Hooks
6. App shell and entry point
7. Server
8. Static files
9. Tests
```

---

## Phase 1: Configuration

| File | Purpose | Dependencies |
|------|---------|--------------|
| `package.json` | Dependencies and scripts | — |
| `tsconfig.json` | TypeScript configuration | — |
| `vitest.config.ts` | Vitest configuration for Convex tests | — |

---

## Phase 2: Convex Backend

Build order matters: schema first, then functions that depend on it.

| File | Purpose | Dependencies |
|------|---------|--------------|
| `convex/schema.ts` | Database schema | data-model.md |
| `convex/auth.config.ts` | Auth HTTP endpoint config | — |
| `convex/auth.ts` | Google OAuth provider setup | schema |
| `convex/http.ts` | HTTP router for auth callbacks | auth |
| `convex/users.ts` | User setup (primary calendar creation) | schema |
| `convex/calendars.ts` | Calendar CRUD + membership queries | schema, users |
| `convex/events.ts` | Event CRUD | schema, calendars |
| `convex/shareLinks.ts` | Share link management (CSPRNG tokens, rate limiting) | schema, calendars |
| `convex/test.setup.ts` | Test module loader for convex-test | — |

---

## Phase 3: Shared Libraries

Pure functions with no React dependencies. Build before components.

| File | Purpose | Dependencies |
|------|---------|--------------|
| `src/lib/constants.ts` | All design tokens | constants.md |
| `src/lib/geometry.ts` | Node position calculations | constants |
| `src/lib/weeks.ts` | Week date calculations | constants |
| `src/lib/priority.ts` | Priority types and utilities | constants |

---

## Phase 4: React Components

Build leaf components before parents. Grouped by dependency depth.

### Tier 1: Leaf components (no child components)

| File | Purpose | Dependencies |
|------|---------|--------------|
| `src/components/WeekNode.tsx` | Single calendar node | constants, geometry, priority |
| `src/components/MonthLabels.tsx` | Rotated month text | constants, geometry |
| `src/components/MonthDividers.tsx` | SVG divider lines | constants, geometry |
| `src/components/CenterHub.tsx` | Center circle with week counter | constants, weeks |
| `src/components/Tooltip.tsx` | Hover/tap info display | constants, weeks |
| `src/components/EventCard.tsx` | Event list item | constants, priority |
| `src/components/PriorityLegend.tsx` | Color key | constants, priority |
| `src/components/CollapsibleSection.tsx` | Expandable section wrapper | constants |
| `src/components/FloatingActionButton.tsx` | Mobile FAB | constants |
| `src/components/AuthScreen.tsx` | Google sign-in UI | — |

### Tier 2: Composite components

| File | Purpose | Dependencies |
|------|---------|--------------|
| `src/components/RadialCalendar.tsx` | SVG calendar assembly | WeekNode, MonthLabels, MonthDividers, CenterHub |
| `src/components/EventModal.tsx` | Create/edit form | constants, priority, weeks |
| `src/components/ShareModal.tsx` | Share link management | constants |
| `src/components/CalendarDropdown.tsx` | Calendar switcher | constants |

### Tier 3: Layout components

| File | Purpose | Dependencies |
|------|---------|--------------|
| `src/components/Sidebar.tsx` | Left panel assembly | CalendarDropdown, CollapsibleSection, EventCard, PriorityLegend |
| `src/components/SharedCalendarView.tsx` | Public share page (join flow states, URL sanitization) | RadialCalendar, Sidebar (read-only) |

---

## Phase 5: Hooks

| File | Purpose | Dependencies |
|------|---------|--------------|
| `src/hooks/useKeyboardShortcuts.ts` | Cmd+K, Escape handling | — |
| `src/hooks/useMobileView.ts` | Mobile view state + history (idempotent transitions, see frontend.md state table) | — |
| `src/hooks/useTooltip.ts` | Tooltip position and visibility | — |

---

## Phase 6: App Shell

| File | Purpose | Dependencies |
|------|---------|--------------|
| `src/App.tsx` | Routing, auth state, view orchestration | All components, all hooks |
| `src/main.tsx` | React entry point, ConvexProvider | App |
| `src/styles.css` | Tailwind v4 with `@theme` tokens | constants.md |

---

## Phase 7: Server

| File | Purpose | Dependencies |
|------|---------|--------------|
| `server.ts` | Bun.serve() dev/prod server | — |
| `build.ts` | Production build script | — |

---

## Phase 8: Static Files

| File | Purpose | Notes |
|------|---------|-------|
| `public/index.html` | HTML shell | Links to main.tsx (dev) or main.js (prod) |
| `public/manifest.json` | PWA manifest | App name, icons, theme |
| `public/sw.js` | Service worker | Minimal, enables PWA install |

---

## Phase 9: Tests

| File | Purpose | Dependencies |
|------|---------|--------------|
| `convex/events.test.ts` | Event CRUD tests | convex-test, schema |
| `convex/shareLinks.test.ts` | Share link security + edge cases | convex-test, schema |
| `tests/server.test.ts` | Server endpoint tests | server.ts |

---

## Phase 10: Deployment

| File | Purpose | Notes |
|------|---------|-------|
| `Dockerfile` | Multi-stage Bun build | — |
| `fly.toml` | Fly.io config | CONVEX_URL build arg |
| `.dockerignore` | Build exclusions | — |

---

## Generated Files (Do Not Edit)

| Directory | Purpose |
|-----------|---------|
| `convex/_generated/` | Convex types and API | Auto-generated by `bunx convex dev` |
| `dist/` | Production build output | Auto-generated by `bun run build` |
| `node_modules/` | Dependencies | Auto-generated by `bun install` |

---

## Component Interface Summary

Quick reference for component props. Full behavior in frontend.md.

### WeekNode
```typescript
{
  position: NodePosition;      // from geometry.ts
  events: Event[];             // events in this week
  isCurrentWeek: boolean;
  isPast: boolean;
  onClick: () => void;         // desktop: open modal
  onTouchStart: () => void;    // mobile: show tooltip
}
```

### EventCard
```typescript
{
  event: Event;
  onClick: () => void;         // open edit modal
}
```

### EventModal
```typescript
{
  isOpen: boolean;
  initialWeek?: number | null; // pre-selected week
  event?: Event;               // null = create, defined = edit
  onClose: () => void;
  onSave: (data: EventData) => void;
  onDelete?: () => void;       // only for edit mode
  isMobile?: boolean;          // full-screen takeover vs centered dialog
}

// Mobile (≤1024px): Full-screen with overflow-y: auto, min-height: 100dvh
//   - Inputs call scrollIntoView on focus (300ms delay for keyboard)
// Desktop (>1024px): Centered floating dialog with backdrop blur
```

### ShareModal
```typescript
{
  calendarId: Id<"calendars">;
  onClose: () => void;
}

// Internal behavior:
// - Generate: creates link + auto-copies to clipboard
// - Copy: clipboard.writeText with fallback to input.select()
// - Revoke: shows confirmation, then soft-deletes
// - Shows "Created X days ago" for active links
```

### CollapsibleSection
```typescript
{
  title: string;
  count: number;
  storageKey: string;          // localStorage key for state
  defaultExpanded: boolean;
  children: ReactNode;
}
```

### Tooltip
```typescript
{
  visible: boolean;
  position: { x: number; y: number };
  anchor: "cursor" | "fixed";  // desktop vs touch
  week: number;
  events: Event[];
}
```

### RadialCalendar
```typescript
{
  events: Event[];
  currentWeek: number;
  onNodeClick: (week: number) => void;
  readOnly?: boolean;          // shared view disables clicks
}
```

### Sidebar
```typescript
{
  events: Event[];
  calendars: Calendar[];
  currentCalendarId: Id<"calendars">;
  onEventClick: (event: Event) => void;
  onAddEvent: () => void;
  onCalendarChange: (id: Id<"calendars">) => void;
  readOnly?: boolean;
}
```

### SharedCalendarView
```typescript
{
  token: string;  // From URL hash, sanitized after load
}

// Internal state machine:
// - loading: data === undefined
// - invalid: data === null (never valid or revoked before viewing)
// - revoked: data transitions null → valid (detected via ref)
// - valid: data has calendar + events
// - alreadyMember: after join, JoinResult.alreadyMember
// - isOwner: after join, JoinResult.isOwner
```
