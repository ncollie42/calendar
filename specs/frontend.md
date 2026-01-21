# Event Tracker 2026: Design Specification

## 1. Design Philosophy

**Geometric Minimalism**: Mathematical symmetry, high-utility data visualization, restrained monochromatic palette.

**Layout Zones**:
- **Sidebar (Input Zone)**: Event creation, list management, legend
- **Canvas (Visualization Zone)**: Radial week calendar

**Inspiration**: "4K Weeks" radial life calendar, "My Year Goal Countdown" poster

---

## 2. Visual Language

### Typography

- **Font**: Inter (Google Fonts)
- **Weights**: Bold (700) titles, Medium (500) labels, Regular (400) body
- **Loading**: Only load weights 400, 500, 700 with `display=swap`

### Color Palette

**Base**:

| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#FFFFFF` | Modals |
| Surface | `#F9FAFB` | Sidebar, canvas |
| Border Light | `#E5E7EB` | Cards, dividers, nodes |
| Border Medium | `#D1D5DB` | Inputs |
| Border Dark | `#374151` | Hover states |
| Text Primary | `#111827` | Headers |
| Text Secondary | `#374151` | Body |
| Text Muted | `#6B7280` | Captions |

**Priority Colors**:

| Priority | Hex | Description |
|----------|-----|-------------|
| Major | `#E1523D` | Vermilion red |
| Big | `#ED8B16` | Tangerine orange |
| Medium | `#C2BB00` | Golden yellow |
| Minor | `#005E54` | Deep teal |

### Effects

- **Modal overlay**: 40% white backdrop with `backdrop-blur(4px)`
- **Shadows**: `0 1px 3px rgba(0,0,0,0.04)` on nodes; `shadow-sm` cards; `shadow-xl` modals
- **Nodes**: Outlined rounded squares; solid priority fill when event exists

---

## 3. Radial Geometry

### Canvas

- SVG viewBox is fixed at 700×700, center at (350, 350)
- **Responsive sizing**: Container uses CSS to scale proportionally
  - Desktop (>1024px): `max-width: 700px`, centered in canvas area
  - Mobile (≤1024px): `width: min(100vw - 32px, 100vh - 32px)` to fit viewport with 16px padding on each side
  - Aspect ratio maintained via `aspect-ratio: 1` on container
  - SVG fills container with `width: 100%; height: 100%`

### Month Spokes

- 12 spokes at 30° intervals
- January at top (-90°), proceeding clockwise

### Week Nodes

```text
INNER_RADIUS: 120px    OUTER_RADIUS: 280px
Node size: 24×24px     Border radius: 8px
```

**Position calculation**:
```javascript
angleDeg = month * 30 - 90
radius = INNER_RADIUS + (weekInMonth / (weeksInMonth - 1)) * (OUTER_RADIUS - INNER_RADIUS)
x = 350 + radius * cos(angleDeg * PI/180)
y = 350 + radius * sin(angleDeg * PI/180)
nodeRotation = angleDeg + 90  // Align with spoke
```

**Week distribution** (54 total, capped at 52):
```
Jan:5 Feb:4 Mar:4 Apr:5 May:4 Jun:5 Jul:4 Aug:5 Sep:4 Oct:5 Nov:4 Dec:5
```

### Month Labels

- Position: `OUTER_RADIUS + 40px` from center
- Rotation: `angleDeg + 90`, add 180° if `angleDeg` between 0-180 (bottom half)
- Style: Uppercase, semi-bold (600 weight), `#6B7280`
- Mobile: 14px font size; Desktop: 12px font size

### Month Dividers

- 12 SVG lines at midpoint angles between spokes
- Span from hub edge (~56px) to past labels (~310px)
- Style: `#E5E7EB` at 50% opacity, 1px, lowest z-index

### Center Hub

- 112px diameter circle, centered at SVG origin (350, 350)
- **Positioning**: HTML overlay with `position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%)` inside a `position: relative` container
- Gradient: white to `#F9FAFB`
- Shadow: `inset 0 2px 8px rgba(0,0,0,0.06)`, ring `0 0 0 1px rgba(0,0,0,0.04)`
- Content:
  - Top line: "2026" (bold)
  - Bottom line: "Week X of 52" (current week progress)

---

## 4. Interactions

### Hover States

- **Nodes**: 1.2× scale, border darkens to `#374151`
- **Cards**: Background `#F3F4F6`
- **Transitions**: `cubic-bezier(0.34, 1.56, 0.64, 1)` for scale, 200-300ms

### Node Hover Stability

Node hover effects must use a **stable hitbox pattern** to prevent flickering caused by boundary shifts during scaling:

- **Outer element (hitbox)**: Fixed 36×36px, handles positioning/rotation, receives pointer events
- **Inner element (visual)**: 24×24px, performs visual transforms, has `pointer-events: none`

**Implementation requirements**:
- The hitbox element must not change dimensions on hover
- All visual transforms (scale, shadow, border) apply to the inner element only
- `transform-origin: center` on the visual element ensures centered scaling
- **SVG note**: Use `transform-box: fill-box` on the visual element so `transform-origin` references the element's bounding box, not the SVG canvas origin
- **SVG note**: Set `pointer-events="all"` on hitbox rects with transparent fill to ensure cross-browser pointer event capture
- **SVG note**: Use `element.setAttribute('class', ...)` to reset classes on SVG elements. `element.className = ...` silently fails because SVG `className` is a read-only `SVGAnimatedString`
- **Touch optimization**: Hitbox is 36×36px (12px larger than visual) for easier touch targeting

### Priority Ranking

When week has multiple events, node shows highest priority:
1. Major → 2. Big → 3. Medium → 4. Minor

### Current Week Indicator

**Visual treatment:**
- **Current week node**: Thicker border (3px) in `#111827` (text-primary black)
  - Applies regardless of whether node has event fill or is empty
  - Border color remains constant, does not change with priority color
- **Past weeks**: Rendered at 65% opacity (both empty and filled nodes)
- **Future weeks**: Full opacity (100%)

**Week calculation:**
- Uses same week numbering as events: Week 1 contains Jan 1, weeks start Monday
- Calculated client-side from `new Date()`
- Updates on page load (not real-time at midnight)

**Center hub integration:**
- Bottom line displays "Week X of 52" where X is current week number
- Replaces previous "52 WEEKS" / event count display

### Node Click/Tap Behavior

**Desktop (pointer: fine)**:
- Clicking a node opens the event creation modal with that week pre-selected

**Touch devices (pointer: coarse)**:
- Tapping a node shows the tooltip (same content as hover: week info, date range, event list)
- Tooltip anchored near the tapped node (not mouse-follow)
- Tap anywhere to dismiss (including tapping the same node again)
- Event creation on touch devices is via the "Add Event" button only

**Implementation**: Use event delegation on the SVG element with separate listeners for touch and mouse:
- `touchstart` on SVG → if target is node, show tooltip and call `preventDefault()` to block click
- `click` on SVG → if target is node, open modal (only fires on non-touch since touch prevents it)
- `touchstart` on document → dismiss tooltip if tap is outside a node

Using `touchstart` (not `touchend`) is more reliable for SVG elements. The `{ passive: false }` option is required for `preventDefault()` to work.

### Tooltips

- **Desktop**: Mouse-follow (12px offset right/below cursor), fade 150ms
- **Touch**: Anchored near tapped node (centered above or below based on screen position), persists until dismissed
- Content: Week N, Month, Date range, Event list

**SVG implementation notes**:
- Use event delegation on the SVG parent element, not individual node listeners
- Use `mouseover`/`mouseout` (which bubble) instead of `mouseenter`/`mouseleave`
- Use `element.closest('.node-hitbox')` to find the hovered node
- Toggle visibility via CSS class (`.visible`), not inline styles

### Keyboard

- `Cmd+K` / `Ctrl+K`: Open event modal
- `Escape`: Close modal
- Shortcut badge shown on "Add Event" button hover

---

## 5. Components

```
Sidebar
├── Header
│   ├── Back Button (mobile only, hidden on desktop)
│   ├── "Event Tracker" title
│   └── "Plan your 2026" subtitle (desktop only)
├── Add Event Button (+ keyboard shortcut badge on desktop)
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
└── Event Form (title, week select, priority, description, delete)

Tooltip
├── Desktop: floating, mouse-follow
└── Touch: anchored near node, tap to dismiss
```

### Collapsible Sections

- Click header to toggle; chevron rotates 180°
- Transition: `max-height` 300ms ease-out
- Count badge: `#E5E7EB` background, `#6B7280` text, `rounded-full`
- State persisted in localStorage key `sidebarCollapseState`
- Sections are siblings (independent collapse)

### Responsive

| Breakpoint | Layout |
|------------|--------|
| >1024px | 25% sidebar / 75% canvas (sidebar: 280-360px) |
| ≤1024px | Full-screen toggle views (calendar or events) |

**Mobile layout (≤1024px)**:
- **Two full-screen views** that toggle (CSS classes `mobile-view-calendar`, `mobile-view-events` on `#app`):
  - **Calendar view** (default): Full-screen radial calendar
  - **Events view**: Full-screen sidebar (Add Event, Scheduled, Backlog)

**Mobile navigation elements**:
- **Floating action button** (calendar view): Fixed position bottom-right, 56×56px dark rounded button with list icon, opens events view
  - Positioned with safe area insets: `bottom: max(1.5rem, env(safe-area-inset-bottom) + 1rem)`
- **Back button** (events view): In sidebar header, arrow-left icon, returns to calendar view

**History API integration** (for back gesture/button support):
- Opening events view pushes state to history: `history.pushState({ view: 'events' }, '', '#events')`
- Back button in header calls `history.back()` instead of directly switching views
- `popstate` event listener returns to calendar view when back is triggered
- On page load, if URL hash is `#events`, show events view
- This prevents the PWA from closing when user presses back in events view—it returns to calendar first

**Mobile visual adjustments**:
- Hide priority legend (colors visible on calendar nodes)
- Reduce header padding (`p-4` instead of `p-6`)
- Hide "Plan your 2026" subtitle
- Smaller section header text (`text-xs` instead of `text-sm`)
- Larger month labels (14px vs 12px on desktop)
- Larger touch targets on nodes (36px hitbox vs 24px visual)

**Safe area support**:
- Viewport meta: `viewport-fit=cover`
- Floating button uses `env(safe-area-inset-bottom)` and `env(safe-area-inset-right)`
- SVG has `touch-action: manipulation` for reliable touch events

---

## 6. API Contract

The frontend consumes these endpoints. See `backend.md` for server implementation details.

### Endpoints

| Endpoint | Method | Request | Response |
|----------|--------|---------|----------|
| `/api/state` | GET | - | `{"events2026": [...]}` |
| `/api/state` | POST | `{"events2026": [...]}` | `{"ok": true}` |

### Event Schema

```json
{
  "id": "evt_1704067200000",
  "title": "Event Title",
  "week": 12,
  "priority": "major",
  "description": "Optional notes"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Generated client-side: `evt_{timestamp}` |
| `title` | string | Required |
| `week` | number \| null | `1-52` = scheduled, `null` = backlog |
| `priority` | string | `major` \| `big` \| `medium` \| `minor` |
| `description` | string | Optional |

### Week Dates

- Weeks start Monday; Week 1 contains Jan 1, 2026
- Display format: `"Feb 2-8"` or `"Jan 27 - Feb 2"` (cross-month)

---

## 7. Loading & Performance

### Initialization Order

The page must feel instant. Render the static UI before fetching data:

1. **Immediate** (on DOMContentLoaded, no await):
   - Render empty calendar structure (nodes, labels, dividers, hub)
   - Populate week select dropdown
   - Setup event listeners
   - Restore collapse state from localStorage

2. **Async** (after calendar is visible):
   - Fetch `/api/state`
   - Update node colors based on events
   - Render event lists in sidebar

### Static HTML Structure

The SVG element with empty `<g>` groups for dividers, nodes, and labels must exist in HTML markup. Center hub can be SVG or HTML overlay.

### Calendar Rendering

The `buildCalendar()` / `renderCalendar()` function must:
1. Run synchronously (no awaits)
2. Complete before any API calls
3. Display a fully-formed but empty calendar

Node colors and event data are applied separately via `updateNodes()` after the API responds.

### Error Handling

If `/api/state` fails or times out:
- Calendar remains visible with empty (white) nodes
- Sidebar shows empty event lists
- No error modal or blocking UI
- Console logs the error for debugging

---

## 8. Progressive Web App (PWA)

The app is installable as a PWA for a native app-like experience on mobile and desktop.

### Manifest

File: `/manifest.json`

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

### Service Worker

File: `/sw.js`

Minimal service worker that registers but does not cache. Required for PWA install prompt.

```javascript
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', () => self.clients.claim());
```

### Icons

- `/icon-192.png` and `/icon-512.png`: Solid `#111827` (theme color) squares
- Generated dynamically by the server (no static files needed)

### HTML Head Tags

```html
<meta name="theme-color" content="#111827">
<link rel="manifest" href="/manifest.json">
<link rel="apple-touch-icon" href="/icon-192.png">
```

### Service Worker Registration

```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}
```

### PWA Features Enabled

| Feature | Status |
|---------|--------|
| Add to Home Screen | Yes |
| Standalone display (no browser chrome) | Yes |
| Theme color in status bar | Yes |
| Offline support | No (online-only) |
| Background sync | No |
