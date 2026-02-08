# Frontend Specification

UI behavior, interactions, and component structure for Event Tracker 2026.

**Related specs:**
- `constants.md` — All design tokens (colors, geometry, timing)
- `data-model.md` — Database schema and types
- `manifest.md` — File list and component interfaces

---

## 1. Design Philosophy

**Geometric Minimalism**: Mathematical symmetry, high-utility data visualization, restrained monochromatic palette.

**Layout Zones**:
- **Sidebar (Input Zone)**: Event creation, list management, legend
- **Canvas (Visualization Zone)**: Radial week calendar

**Inspiration**: "4K Weeks" radial life calendar, "My Year Goal Countdown" poster

---

## 2. Visual Language

All color values, typography settings, and effect values are defined in `constants.md`. This section covers how they're applied.

### Color Application

- **Empty nodes**: `borderLight` outline, white fill
- **Filled nodes**: Priority color fill (see `constants.md` Priority Colors)
- **Current week**: 3px `textPrimary` border
- **Past weeks**: 65% opacity
- **Hover states**: Border darkens to `borderDark`

### Effects

- **Modal overlay**: Desktop: 40% white backdrop with `backdrop-blur(4px)`. Mobile: full-screen takeover (see `constants.md` Modal Overlay)
- **Nodes**: Outlined rounded squares; solid priority fill when event exists
- **Shadows**: Applied per `constants.md` Effects section

**Inline style caveat**: Tailwind utilities like `ringColor` aren't valid CSS properties. Use CSS variable syntax:
```typescript
style={{
  "--tw-ring-color": getPriorityColor(p),
} as React.CSSProperties}
```

---

## 3. Radial Geometry

Geometry values (radii, sizes, offsets) are defined in `constants.md`. This section covers layout behavior.

### Canvas Sizing

- SVG viewBox is fixed at 700×700, center at (350, 350)
- **Responsive sizing**: Container uses CSS to scale proportionally
  - Desktop (>1024px): `max-width: 700px`, centered in canvas area
  - Mobile (≤1024px): `width: min(100vw - 32px, 100vh - 32px)` to fit viewport
  - Aspect ratio maintained via `aspect-ratio: 1` on container
  - SVG fills container with `width: 100%; height: 100%`

### Month Spokes

- 12 spokes at 30° intervals
- January at top (-90°), proceeding clockwise

### Week Node Position Algorithm

```javascript
angleDeg = month * 30 - 90
radius = INNER_RADIUS + (weekInMonth / (weeksInMonth - 1)) * (OUTER_RADIUS - INNER_RADIUS)
x = CENTER + radius * cos(angleDeg * PI/180)
y = CENTER + radius * sin(angleDeg * PI/180)
nodeRotation = angleDeg + 90  // Align with spoke
```

Week distribution per month defined in `constants.md` (54 total nodes, capped at 52 unique weeks).

### Month Labels

- Position: `OUTER_RADIUS + labelOffset` from center
- Rotation: `angleDeg + 90`, add 180° if `angleDeg` between 0-180 (bottom half)
- Style: Uppercase, semi-bold, `textMuted` color
- Mobile: 14px; Desktop: 12px

### Month Dividers

- 12 SVG lines at midpoint angles between spokes (offset 15°)
- Span from `dividerInner` to `dividerOuter`
- Style: `borderLight` at 50% opacity, 1px, lowest z-index

### Center Hub

- 112px diameter circle (`hubRadius * 2`), centered at SVG origin
- **Positioning**: HTML overlay with absolute centering inside relative container
- Gradient: white to `surface`
- Shadow: inset shadow + subtle ring (see `constants.md`)
- Content:
  - Top line: "2026" (bold)
  - Bottom line: "Week X of 52" (current week progress)

---

## 4. Interactions

### Hover States

- **Nodes**: 1.2× scale, border darkens to `borderDark`
- **Cards**: Background lightens
- **Transitions**: Bouncy easing (see `constants.md` Timing)

### Node Hover Stability

Node hover effects must use a **stable hitbox pattern** to prevent flickering:

- **Outer element (hitbox)**: Fixed `hitboxSize`, handles positioning/rotation, receives pointer events
- **Inner element (visual)**: `nodeSize`, performs visual transforms, has `pointer-events: none`

**Implementation requirements**:
- Hitbox element must not change dimensions on hover
- All visual transforms apply to inner element only
- `transform-origin: center` on visual element
- **SVG**: Use `transform-box: fill-box` so transform-origin references element's bounding box
- **SVG**: Set `pointer-events="all"` on hitbox rects with transparent fill
- **SVG**: Use `element.setAttribute('class', ...)` to reset classes (not `className`)

### Priority Ranking

When week has multiple events, node shows highest priority:
1. Major → 2. Big → 3. Medium → 4. Minor

### Current Week Indicator

**Visual treatment:**
- **Current week node**: 3px `textPrimary` border (regardless of fill state)
- **Past weeks**: 65% opacity
- **Future weeks**: 100% opacity

**Week calculation:**
- Monday-aligned, Week 1 contains January 1st (see `constants.md` Week Calculation)
- For 2026: Week 1 starts Dec 29, 2025
- Formula: `Math.floor(daysSinceWeek1Start / 7) + 1`
- Calculated client-side, updates on page load only

### Node Click/Tap Behavior

**Desktop (pointer: fine)**:
- Clicking a node opens event modal with that week pre-selected

**Touch devices (pointer: coarse)**:
- Tapping a node shows tooltip (week info, date range, event list)
- Tooltip anchored near tapped node
- Tap anywhere to dismiss
- Event creation via "Add Event" button only

**Implementation**: Event delegation on SVG element:
- `touchstart` → show tooltip, `preventDefault()` to block click
- `click` → open modal (only fires on non-touch)
- `touchstart` on document → dismiss tooltip if outside node

Use `{ passive: false }` for `preventDefault()` to work.

### Tooltips

- **Desktop**: Mouse-follow (12px offset), fade 150ms
- **Touch**: Anchored near node, persists until dismissed
- **Content**: Week N, Month, Date range, Event list

**SVG implementation**:
- Event delegation on SVG parent, not individual nodes
- Use `mouseover`/`mouseout` (which bubble)
- Use `element.closest('.node-hitbox')` to find hovered node
- Toggle visibility via CSS class

### Keyboard

- `Cmd+K` / `Ctrl+K`: Open event modal
- `Escape`: Close modal
- Shortcut badge shown on "Add Event" button hover

---

## 5. Components

Component props interfaces are defined in `manifest.md`.

```
Sidebar
├── Header
│   ├── Back Button (mobile only)
│   ├── Calendar Dropdown
│   │   ├── Current calendar name with chevron
│   │   ├── Dropdown menu:
│   │   │   ├── Calendar list (name + role badge)
│   │   │   ├── Divider
│   │   │   ├── Create Calendar (inline input)
│   │   │   └── Delete Calendar (owner only, confirmation)
│   │   └── Share button (opens ShareModal)
│   └── "Plan your 2026" subtitle (desktop only)
├── Add Event Button (+ keyboard shortcut badge)
├── Scheduled Events (collapsible, default: expanded)
│   └── Event cards sorted by week, then priority
├── ── [divider] ──
├── Backlog (collapsible, default: collapsed)
│   └── Unscheduled event cards
└── Priority Legend (desktop only)

Canvas
├── Month Divider Lines (SVG, z-index: 0)
├── Week Nodes (52 nodes across 12 spokes)
├── Month Labels (rotated text)
└── Center Hub

Floating Action Button (mobile only)
└── Opens events view from calendar view

Modal
├── Event Form (title, week select, priority, description, delete)
│   **Delete confirmation**: Browser `confirm()` dialog
│   **Mobile (≤1024px)**: Full-screen takeover (not centered floating dialog)
│   **Desktop (>1024px)**: Centered floating dialog with backdrop
└── Share Modal
    ├── View Link section (generate/copy/revoke)
    └── Invite Link section (generate/copy/revoke)

SharedCalendarView (public view via share token)
├── Banner: context-aware (see Join Flow States below)
├── RadialCalendar (read-only)
└── Event list (read-only)

### Share Link UX

**ShareModal behavior:**
- One-click generate + auto-copy (with toast feedback)
- Show link age: "Created 3 days ago"
- Revoke shows brief warning: "Anyone with this link will lose access"
- Persistent "link active" vs "no link" indicator
- Copy button shows "Copied!" for 2s, then reverts

**Clipboard handling:**
```typescript
async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    // Fallback: select input text, prompt manual copy
    inputRef.current?.select();
    return false;
  }
}
```
- On failure: select input text + show "Press Ctrl+C to copy"
- Never fail silently

### Join Flow States

SharedCalendarView must handle all user states:

| Auth State | Membership | UI |
|------------|------------|-----|
| Not authenticated | — | "Sign in to join" button |
| Authenticated | Not member | "Join Calendar" button |
| Authenticated | Already member | "You're already a member" + "Go to Calendar" link |
| Authenticated | Is owner | "This is your calendar" + "Go to Calendar" link |

**After successful join:**
- Redirect directly to that calendar (not home)
- Show calendar name in success state
- If user has multiple calendars, ensure correct one is selected

**Edge case: wrong account:**
- Show which account will join: "Join as {email}?"
- Provide "Switch account" option

### Real-time Revocation Handling

Since Convex queries are reactive, SharedCalendarView auto-updates when link is revoked:

```typescript
// Track previous state to detect revocation
const prevDataRef = useRef(data);

useEffect(() => {
  if (data === null && prevDataRef.current !== null) {
    // Link was just revoked while viewing
    // Show "Access has been revoked" (not "Invalid link")
  }
  prevDataRef.current = data;
}, [data]);
```

**User sees:**
- Valid → Revoked: "Access to this calendar has been revoked"
- Never valid: "This link is invalid or has expired"

### Token URL Privacy

After SharedCalendarView loads successfully, sanitize URL:

```typescript
useEffect(() => {
  if (data) {
    // Remove token from URL bar, history, bookmarks, screenshots
    history.replaceState(null, '', '#/shared');
  }
}, [data]);
```

**Why:**
- Prevents token appearing in browser history
- Prevents accidental sharing via screenshots
- Prevents bookmarking with token exposed
- Reference: [W3C Capability URLs](https://www.w3.org/2001/tag/doc/capability-urls/)

Tooltip
├── Desktop: floating, mouse-follow
└── Touch: anchored near node, tap to dismiss
```

### Collapsible Sections

- Click header to toggle; chevron rotates 180°
- Transition: `max-height` with collapse timing from `constants.md`
- Count badge: `borderLight` background, `textMuted` text, rounded-full
- State persisted in localStorage key `sidebarCollapseState`
- Sections collapse independently

### Responsive Layout

| Breakpoint | Layout |
|------------|--------|
| >1024px | 25% sidebar (280-360px) / 75% canvas |
| ≤1024px | Full-screen toggle views |

**Mobile layout (≤1024px)**:
- Two full-screen views via CSS classes on `#app`:
  - `mobile-view-calendar` (default): Full-screen radial calendar
  - `mobile-view-events`: Full-screen sidebar

**Mobile navigation**:
- **FAB** (calendar view): Bottom-right, 56×56px, opens events view
  - Safe area positioning: `bottom: max(1.5rem, env(safe-area-inset-bottom) + 1rem)`
  - **Idempotent**: tapping FAB while already in events view is a no-op (guard on current view state)
- **Back button** (events view): In header, returns to calendar

**Share Link URL format**:
- Hash-based routing: `#/share/{token}`
- Token: 22-char base62, CSPRNG (see `constants.md`)

**History API integration — state transition table**:

Each view transition creates exactly one history entry. Repeated actions are no-ops.

| Current View | Action | History Effect | New View |
|---|---|---|---|
| calendar | FAB tap | `pushState({ view: 'events' })` | events |
| events | FAB tap | no-op (FAB hidden, + idempotent guard) | events |
| events | Back button (header) | `history.back()` | calendar |
| events | Browser back | `popstate` fires, no additional history call | calendar |
| calendar | Browser back | default browser behavior | exit app/prev page |

**Invariants**:
- `showEvents` must guard: if already in events view, return early (prevents history stacking)
- `showCalendar` must distinguish "closed by UI" vs "closed by browser back":
  - UI close (header back button): calls `history.back()` to pop the entry
  - Browser back (`popstate`): entry already popped, only update React state
- Never call `history.back()` from within a `popstate` handler — the entry is already gone
- `popstate` listener sets view based on `event.state`, does not push/replace

**Mobile visual adjustments**:
- Hide priority legend
- Reduce header padding (`p-4` vs `p-6`)
- Hide subtitle
- Smaller section headers (`text-xs` vs `text-sm`)
- Larger month labels (14px vs 12px)
- Larger touch targets (36px hitbox)

**Safe area support**:
- Viewport meta: `viewport-fit=cover`
- FAB uses `env(safe-area-inset-*)` values
- SVG has `touch-action: manipulation`

---

## 6. Data Layer

Schema and types defined in `data-model.md`. This section covers frontend data flow.

### Convex Hooks

| Hook | Purpose |
|------|---------|
| `useQuery(api.events.getEvents)` | Fetch events for calendar |
| `useMutation(api.events.createEvent)` | Create event |
| `useMutation(api.events.updateEvent)` | Update event |
| `useMutation(api.events.deleteEvent)` | Delete event |
| `useQuery(api.calendars.getMyCalendars)` | Fetch user's calendars |
| `useQuery(api.calendars.getPrimaryCalendar)` | Fetch primary calendar |
| `useMutation(api.calendars.createCalendar)` | Create calendar |
| `useMutation(api.calendars.deleteCalendar)` | Delete calendar |
| `useQuery(api.shareLinks.getCalendarShareLinks)` | Fetch share links |
| `useQuery(api.shareLinks.getCalendarByToken)` | Fetch via share token |
| `useMutation(api.shareLinks.createShareLink)` | Generate link |
| `useMutation(api.shareLinks.revokeShareLink)` | Revoke link |
| `useMutation(api.shareLinks.joinViaInviteLink)` | Join via invite |

### Week Date Display

- Monday-aligned, Week 1 contains January 1st (see `constants.md` Week Calculation)
- 2026 Week 1: Dec 29, 2025 - Jan 4, 2026
- Format: `"Dec 29 - Jan 4"` (cross-month) or `"Jan 5-11"` (same month)

---

## 7. Loading & Performance

### Initialization Order

The page must feel instant. Render static UI before data:

1. **Immediate** (on initial render):
   - Empty calendar structure (nodes, labels, dividers, hub)
   - Sidebar with empty event lists
   - Restore collapse state from localStorage

2. **Async** (via Convex reactive queries):
   - Fetch events
   - Update node colors
   - Populate event lists

### React Component Structure

```
App (routing, auth state)
├── AuthScreen (Google sign-in)
├── SharedCalendarView (public share)
│   ├── Banner
│   ├── Sidebar (read-only)
│   └── RadialCalendar (read-only)
└── CalendarApp (authenticated)
    ├── Sidebar
    │   ├── CalendarDropdown
    │   └── EventCard[]
    ├── RadialCalendar
    │   ├── MonthDividers
    │   ├── WeekNode[]
    │   ├── MonthLabels
    │   └── CenterHub
    ├── Tooltip
    ├── EventModal
    └── ShareModal
```

### Error Handling

If Convex connection fails:
- Calendar visible with empty (white) nodes
- Sidebar shows empty event lists
- No blocking error modal
- Console logs error

---

## 8. Progressive Web App

### Manifest (`/manifest.json`)

```json
{
  "name": "Event Tracker 2026",
  "short_name": "Tracker",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#F9FAFB",
  "theme_color": "#111827",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

### Service Worker (`/sw.js`)

Minimal—enables PWA install, no caching:

```javascript
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', () => self.clients.claim());
```

### Icons

- `/icon-192.png` and `/icon-512.png`: Solid `textPrimary` color squares
- Generated by server or static files in `public/`

### HTML Head

```html
<meta name="theme-color" content="#111827">
<link rel="manifest" href="/manifest.json">
<link rel="apple-touch-icon" href="/icon-192.png">
```

### Registration

```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}
```

### Features

| Feature | Status |
|---------|--------|
| Add to Home Screen | Yes |
| Standalone display | Yes |
| Theme color | Yes |
| Offline support | No |
| Background sync | No |

---

## 9. CSS Implementation Details

### Node Hover Effect

The stable hitbox pattern requires this CSS rule to apply hover transforms:

```css
.node-hitbox:hover .node-visual {
  transform: scale(1.2);
  stroke: #374151 !important;  /* borderDark */
}
```

### Mobile View Toggle

CSS classes control which panel is visible on mobile:

```css
@media (max-width: 1024px) {
  .mobile-view-calendar .sidebar {
    display: none;
  }
  .mobile-view-events .canvas {
    display: none;
  }
  .mobile-view-events .sidebar {
    width: 100%;
    height: 100vh;
  }
}
```

### Mobile Modal (Full-Screen Takeover)

On mobile, EventModal fills the screen instead of floating centered:

```css
@media (max-width: 1024px) {
  .event-modal {
    /* Override centered dialog — fill screen */
    align-items: stretch !important;
    justify-content: stretch !important;
    padding: 0 !important;
    background: white !important;
    backdrop-filter: none !important;
  }
  .event-modal > div {
    max-width: 100% !important;
    min-height: 100dvh;
    border-radius: 0 !important;
    box-shadow: none !important;
    overflow-y: auto;
  }
}
```

Input focus scrolling (in component):
```typescript
onFocus={(e) => {
  setTimeout(() => {
    e.target.scrollIntoView({ block: "center", behavior: "smooth" });
  }, 300); // Wait for keyboard animation
}}
```

### Loading Spinner

Used for auth and data loading states:

```css
@keyframes spin {
  to { transform: rotate(360deg); }
}
.animate-spin {
  animation: spin 1s linear infinite;
}
```

### Scrollbar Styling

Subtle scrollbars for event lists:

```css
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #D1D5DB; border-radius: 3px; }
```
