# Frontend Specification

UI behavior, interactions, and component structure for Event Tracker 2026.

**Scope**: Observable behavior only. No CSS blocks, no framework code, no implementation details. Describe what the user sees and how the app responds — Claude derives the implementation.

**Related specs:**
- `constants.md` — All design tokens (colors, geometry, timing)
- `data-model.md` — Database schema and types

---

## 1. Design Philosophy

**Warm Geometric Minimalism**: Mathematical symmetry meets human warmth. The radial visualization is the hero — surrounding UI serves it with a warm, personality-driven aesthetic. Neutral surfaces use warm grays (cream/linen family), shadows use warm brown tints. The interface should feel handcrafted, not clinical.

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
- **Warm undertone philosophy**: All neutral surfaces use warm grays instead of cool grays. Shadows use warm brown tints (`rgba(120,100,80,...)`) instead of pure black. See `constants.md` for exact values.

### Effects

- **Modal overlay**: Desktop: 40% white backdrop with `backdrop-blur(4px)`. Mobile: full-screen takeover (see `constants.md` Modal Overlay)
- **Nodes**: Outlined rounded squares; solid priority fill when event exists
- **Shadows**: Applied per `constants.md` Effects section

---

## 3. Radial Geometry

Geometry values (radii, sizes, offsets) are defined in `constants.md`. This section covers layout behavior.

### Canvas Sizing

- SVG viewBox is fixed at 700×700, center at (350, 350)
- **Responsive sizing**: Container uses CSS to scale proportionally
  - Desktop (>1024px): `width: min(calc(100vh - 64px), 700px)`, centered in canvas area. Height is the primary size driver since desktop screens are landscape (32px effective margin top/bottom).
  - Mobile (≤1024px): `width: min(100vw - 16px, 100vh - 16px)` to fit viewport (8px margin each side — SVG has internal padding so outer margin can be tight)
  - Aspect ratio maintained via `aspect-ratio: 1` on container
  - SVG fills container with `width: 100%; height: 100%`

### Month Spokes

- 12 spokes at 30° intervals
- January at top (-90°), proceeding clockwise

### Week Node Position Algorithm

Each month's spoke is at `month * 30 - 90` degrees (January at top). Nodes are distributed linearly along the spoke from `innerRadius` to `outerRadius` based on their position within the month's week count. Each node rotates to align with its spoke (angle + 90°). Week distribution per month defined in `constants.md` (54 total nodes, capped at 52 unique weeks).

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

**Hover-aware crossfade (desktop only):**
- When user hovers any week node, the hub's "Week X of 52" text crossfades to show the hovered week number instead
- Transition: `hubCrossfade` duration (200ms ease)
- On mouse-out, crossfades back to actual current week
- Mobile: no crossfade, hub stays static
- Implementation: Hub receives optional `hoveredWeek` prop

---

## 4. Interactions

### Hover States

- **Nodes**: 1.2× scale, border darkens to `borderDark`
- **Cards**: Lift effect — `translateY(-1px)` + shadow increase (`shadow-sm` → `shadow-md`). Duration: `cardLiftDuration`.
- **Transitions**: Bouncy easing (see `constants.md` Timing)

### Animation Performance Constraints

To preserve native-feel responsiveness, interaction-path animations must stay compositor-friendly:

- Allowed in hot paths: `transform`, `opacity`
- Avoid in hot paths: layout-affecting properties (`top`, `left`, `width`, `height`, `margin`, `padding`, `max-height`)
- Avoid driving per-frame interactivity by repeatedly mutating expensive paint/layout properties
- Hover, tooltip-follow, and node emphasis interactions should favor transform/opacity transitions

### Node Hover Stability

Node hover effects must use a **stable hitbox pattern** to prevent flickering:

- **Outer element (hitbox)**: Fixed `hitboxSize`, handles positioning/rotation, receives pointer events
- **Inner element (visual)**: `nodeSize`, performs visual transforms, has `pointer-events: none`

**Invariants**:
- Hitbox element must not change dimensions on hover
- All visual transforms apply to inner element only
- Transform origin must be center of the visual element
- In SVG: hitbox needs explicit pointer-events with transparent fill; visual element has pointer-events disabled

### Priority Ranking

When week has multiple events, node shows highest priority:
1. Major → 2. Big → 3. Medium → 4. Minor

### Current Week Indicator

**Visual treatment:**
- **Current week node**: 3px `textPrimary` border (regardless of fill state) + animated glow ring
- **Glow ring**: SVG blur filter creating a soft halo that pulses (opacity 0.15→0.4 over `currentWeekPulse` duration). See `constants.md` Current Week Glow.
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
- Tapping a node shows tooltip anchored near the node
- Tooltip persists until user taps outside any node
- Tapping the same node again does NOT dismiss (not a toggle)
- Tapping a different node moves the tooltip to that node
- Event creation via "Add Event" button only (node taps never open modal on touch)
- Tooltip is read-only context for that week's schedule, not an event creation entry point
- Touch-node interactions must never trigger create/edit modal open states

**Touch vs click discrimination**: On touch devices, tapping a node must show tooltip without opening the modal. Use a touch-active flag: touch sets it, click checks it — if set from touch, suppress the modal. Tapping anywhere outside week nodes dismisses the tooltip (including areas outside the SVG canvas).

### Tooltips

- **Desktop**: Mouse-follow (12px offset), fade in/out 150ms
- **Touch**: Anchored near node, persists until tap outside node dismisses it
- **Content**: Week N, Date range, Event list (with priority dots)

**Desktop dismiss behavior:**
- Tooltip hides when mouse leaves the node hitbox
- 100ms grace period before starting fade-out (cancel if mouse enters another node)
- This prevents flicker when sliding between adjacent nodes
- Moving mouse within the same node (between child SVG elements) must NOT trigger hide

**SVG tooltip delegation**: Use event delegation on the SVG parent (not individual nodes) with pointer events. When the pointer moves between child elements within the same node, the tooltip must NOT flicker — check that the pointer is actually leaving the node's hitbox, not just moving between its children. Track cursor position for desktop tooltip follow.

**Single tooltip overlay invariant**:
- Render exactly one tooltip overlay instance for the radial calendar
- Reuse that single instance for all hovered/tapped weeks
- Do not mount one tooltip per node

**Pointer move update budget (desktop follow tooltip)**:
- Pointer tracking must be `requestAnimationFrame`-throttled (max one visual update per frame)
- Coalesce multiple raw pointer events into the next animation frame update
- Do not trigger React state updates on every raw `pointermove` event

### Keyboard

- `Cmd+K` / `Ctrl+K`: Open event modal
- `Escape`: Close modal
- Shortcut badge shown on "Add Event" button hover

---

## 5. Components

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
├── Priority Legend (desktop only, scrolls with content)
└── Account Bar (sticky bottom)
    ├── Google avatar (32px circle, fallback: first letter of email on surface background)
    ├── Email address (truncated with ellipsis if overflow)
    └── "Sign out" text button (textMuted, right-aligned)

Canvas
├── Calendar Name Pill (mobile only, fixed top, frosted glass)
│     Centered floating pill matching bottom bar aesthetic
│     Fixed position with safe-area-inset-top respect
│     Font: text-base (16px), font-medium, text-secondary
├── Month Divider Lines (SVG, z-index: 0)
├── Week Nodes (52 nodes across 12 spokes)
├── Month Labels (rotated text)
└── Center Hub

Bottom Bar (mobile only)
├── Translucent pill anchored to bottom center
├── Frosted glass: backdrop-blur(12px), rgba(250,249,247,0.85) background
├── Rounded-full with subtle borderLight border, shadow-lg
├── Content (left to right):
│   ├── "Add Event" button (primary action → opens event modal)
│   └── View toggle icon (list ↔ calendar, tap toggles mobile view in both directions)
└── Safe area: bottom: max(1rem, env(safe-area-inset-bottom) + 0.5rem)

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

**Clipboard handling:** Try `navigator.clipboard.writeText()` first. On failure, fall back to selecting input text and showing "Press Ctrl+C to copy". Never fail silently.

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

Since Convex queries are reactive, SharedCalendarView auto-updates when a link is revoked. The view must distinguish between "was valid, now revoked" vs "was never valid":
- Valid → Revoked: "Access to this calendar has been revoked"
- Never valid: "This link is invalid or has expired"

Track previous data state to detect the transition.

### Token URL Privacy

After SharedCalendarView loads successfully, replace the URL to remove the token (e.g. `history.replaceState` to `#/shared`). This prevents token exposure in browser history, bookmarks, and screenshots.

### EventCard Visual Treatment

- **Left border accent**: 3px left border in the event's priority color, always visible
- **Hover lift**: Card lifts `translateY(-1px)`, shadow increases to `shadow-md`, border accent at full opacity. Duration: `cardLiftDuration`.
- **"Now" divider**: In the Scheduled section, a subtle horizontal divider "— Now —" between past-week events and current/future-week events. `textMuted` color, `text-xs`, centered. Only shown when there are both past and future events in the list.

### Collapsible Sections

- Click header to toggle; chevron rotates 180°
- Transition: `max-height` with collapse timing from `constants.md`
- Count badge: `borderLight` background, `textMuted` text, rounded-full
- State persisted in localStorage key `sidebarCollapseState`
- Sections collapse independently

### Account Bar

Sticky bar pinned to the bottom of the sidebar, always visible regardless of scroll position. Separated from scrollable content by a `borderLight` top border.

**Content (left to right):**
- Google avatar: 32px circle. If no image URL or image fails to load, show first letter of email on a `borderLight` background circle with `textMuted` color.
- Email: `text-xs`, `textSecondary`, truncated with ellipsis. Takes remaining horizontal space.
- "Sign out": `text-xs`, `textMuted`, right-aligned. No confirmation dialog — sign out is low-stakes and reversible (sign back in).

**After sign-out:**
- If on main app: redirect to auth screen.
- If on shared calendar view (view-only): stay on shared view (no auth required). Remove any stale membership UI.

**Mobile:** Same layout. Account bar visible in events view (sidebar). Not visible in calendar view (canvas only).

### Empty State Personality

Empty states use warm, encouraging copy:

| Location | Copy |
|----------|------|
| Scheduled section (0 events) | "Your year is wide open" |
| Backlog section (0 events) | "Nothing waiting — add ideas as they come" |
| First-time user (0 events total) | "Start with one event — what's the first thing you're looking forward to?" |

**Micro-celebration on first event:**
When user creates their very first event (0→1), the filled node plays an emphasized entrance: `scale(0) → scale(1.3) → scale(1)` with priority color flooding in. Duration 500ms, easing: `hoverEasing` (bouncy). Subsequent creates have no special animation.

### Responsive Layout

| Breakpoint | Layout |
|------------|--------|
| >1024px | 25% sidebar (280-360px) / 75% canvas |
| ≤1024px | Full-screen toggle views |

**Desktop layout (>1024px)**:
- Root container: `height: 100vh` (viewport-locked, NOT `min-height`)
- Sidebar: `height: 100vh`, `overflow-y: auto` (scrolls independently)
- Canvas: `height: 100vh`, `overflow: hidden` (calendar centered, never scrolls)
- This prevents the sidebar's content length from expanding the page and pushing the calendar down

**Mobile layout (≤1024px)**:
- Two full-screen views via CSS classes on `#app`:
  - `mobile-view-calendar` (default): Full-screen radial calendar
  - `mobile-view-events`: Full-screen sidebar

**Mobile navigation**:
- **Bottom bar** (both views): Translucent pill at bottom center with frosted glass effect
  - Always visible on mobile (calendar view AND events view)
  - Contains: "Add Event" + view toggle icon
  - View toggle is a **bidirectional toggle**: calendar → events, events → calendar
  - `showEvents` guards: if already in events view, return early (prevents history stacking)
  - `showCalendar` guards: if already in calendar view, return early
  - Safe area: `bottom: max(1rem, env(safe-area-inset-bottom) + 0.5rem)`
- **Back button** (events view): In header, also returns to calendar (alternative to toggle)

**Share Link URL format**:
- Hash-based routing: `#/share/{token}`
- Token: 22-char base62, CSPRNG (see `constants.md`)

**History API integration — state transition table**:

Each view transition creates exactly one history entry. Repeated actions are no-ops.

| Current View | Action | History Effect | New View |
|---|---|---|---|
| calendar | Bottom bar toggle tap | `pushState({ view: 'events' })` | events |
| events | Bottom bar toggle tap | `history.back()` (pops the events entry) | calendar |
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
- Bottom bar uses `env(safe-area-inset-*)` values
- SVG has `touch-action: manipulation`

---

## 6. Data Layer

Schema, types, and Convex functions are defined in `data-model.md` and `backend.md`. The frontend uses Convex's reactive queries and mutations — data updates in real-time without manual refetching.

### Week Date Display

- Monday-aligned, Week 1 contains January 1st (see `constants.md` Week Calculation)
- 2026 Week 1: Dec 29, 2025 - Jan 4, 2026
- Format: `"Dec 29 - Jan 4"` (cross-month) or `"Jan 5-11"` (same month)

---

## 7. Loading & Performance

### Performance Budget

| Metric | Target |
|--------|--------|
| First Paint | <300ms |
| Time to Interactive | <800ms |
| Node hover response | <16ms (60fps) |
| Bundle size (gzipped) | <400KB |

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

### Node Entrance Animation

On initial render, week nodes stagger-animate in with a bloom effect:
- Each node starts at `scale(0)` and animates to `scale(1)`
- Stagger: `nodeStaggerDelay` per node (8ms × 52 ≈ 416ms total spread)
- Order: inner nodes first (week 1), outward to week 52
- Duration: `nodeEntranceDuration` (400ms per node)
- Easing: `nodeEntranceEasing` (expo-out)
- Plays once on mount only, not on re-render or data updates
- Implementation: CSS `animation-delay` computed from week index

### Render Performance

Only nodes affected by a data change should re-render — not all 52. Static elements (month dividers, month labels) never re-render after initial mount. Cache the events-by-week mapping so it only recomputes when the events array changes.

**Static radial layer invariant**:
- Radial geometry (month dividers, month labels, node positions/rotations) is precomputed and rendered once on mount
- Data updates must not rebuild static geometry
- Event changes should only update dynamic node visuals (fill, opacity, border emphasis) for affected weeks

### Font Loading

Self-host Inter (woff2, weights 400/500/600/700) from `public/fonts/`. Preload weight 400 in HTML. No external font CDN requests.

### Critical CSS

Inline minimal CSS in `<head>`: body background color, font-family, text color, and the node entrance keyframe. Prevents flash of unstyled content on load.

### Component Hierarchy

The app has three top-level routes: auth screen, shared calendar view (public), and the main calendar app (authenticated). The main app splits into sidebar (event list, calendar switcher) and canvas (radial calendar with tooltip). Modals (event, share) overlay both.

### Error Handling

If Convex connection fails:
- Calendar visible with empty (white) nodes
- Sidebar shows empty event lists
- No blocking error modal
- Console logs error

---

## 8. Progressive Web App

Installable PWA with standalone display. App name "Event Tracker 2026", theme color `textPrimary`, background color `surface`.

### Service Worker Strategy

Speed-focused, not offline-first:

| Resource | Strategy |
|----------|----------|
| Fonts | Cache-first (immutable) |
| App shell (HTML, JS, CSS) | Stale-while-revalidate |
| Convex API / WebSocket | Pass-through (never cache) |

On install: pre-cache static files, skip waiting. On activate: delete old caches, claim clients. No offline support, no background sync.

### Icons

192px and 512px solid `textPrimary` color squares. Can be server-generated or static files.
