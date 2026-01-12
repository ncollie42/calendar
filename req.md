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

```css
:root {
  --color-priority-major: #E1523D;
  --color-priority-big: #ED8B16;
  --color-priority-medium: #C2BB00;
  --color-priority-minor: #005E54;
}
```

### Effects

- **Modal overlay**: 40% white backdrop with `backdrop-blur(4px)`
- **Shadows**: `0 1px 3px rgba(0,0,0,0.04)` on nodes; `shadow-sm` cards; `shadow-xl` modals
- **Nodes**: Outlined rounded squares; solid priority fill when event exists

---

## 3. Radial Geometry

### Canvas

- Fixed 700×700px grid, center at (350, 350)
- Scales via CSS `transform: scale(min(1, (containerSize - 40) / 700))`

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
- Style: Uppercase, 500 weight, `#9CA3AF`

### Month Dividers

- 12 SVG lines at midpoint angles between spokes
- Span from hub edge (~56px) to past labels (~310px)
- Style: `#E5E7EB` at 50% opacity, 1px, lowest z-index

### Center Hub

- 112px diameter circle
- Gradient: white to `#F9FAFB`
- Shadow: `inset 0 2px 8px rgba(0,0,0,0.06)`, ring `0 0 0 1px rgba(0,0,0,0.04)`
- Content: "2026" bold, "52 WEEKS" or event count below

---

## 4. Interactions

### Hover States

- **Nodes**: 1.2× scale, border darkens to `#374151`
- **Cards**: Background `#F3F4F6`
- **Transitions**: `cubic-bezier(0.34, 1.56, 0.64, 1)` for scale, 200-300ms

### Node Hover Stability

Node hover effects must use a **stable hitbox pattern** to prevent flickering caused by boundary shifts during scaling:

- **Outer element (hitbox)**: Fixed 24×24px, handles positioning, rotation, and receives pointer events
- **Inner element (visual)**: Performs visual transforms (scale, border color), has `pointer-events: none`

```html
<div class="node-hitbox">        <!-- stable 24×24, receives hover -->
  <div class="node-visual">      <!-- scales 1.2×, no pointer events -->
  </div>
</div>
```

**Implementation requirements**:
- The hitbox element must not change dimensions on hover
- All visual transforms (scale, shadow, border) apply to the inner element only
- `transform-origin: center` on the visual element ensures centered scaling
- **SVG note**: Use `transform-box: fill-box` on the visual element so `transform-origin` references the element's bounding box, not the SVG canvas origin
- **SVG note**: Set `pointer-events="all"` on hitbox rects with transparent fill to ensure cross-browser pointer event capture
- Optional: Hitbox may extend 2-4px beyond visual bounds for easier targeting in dense node areas

### Priority Ranking

When week has multiple events, node shows highest priority:
1. Major → 2. Big → 3. Medium → 4. Minor

### Tooltips

- Mouse-follow (12px offset right/below cursor)
- Content: Week N, Month, Date range, Event list
- Fade: 150ms

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
├── Header ("Event Tracker" / "Plan your 2026")
├── Add Event Button (+ keyboard shortcut badge)
├── Scheduled Events (collapsible, default: expanded)
│   └── Event cards sorted by week, then priority
├── ── [divider] ──
├── Backlog (collapsible, default: collapsed)
│   └── Unscheduled event cards
└── Priority Legend

Canvas
├── Month Divider Lines (SVG, z-index: 0)
├── Week Nodes (52 nodes across 12 spokes)
├── Month Labels (rotated text)
└── Center Hub

Modal
└── Event Form (title, week select, priority, description, delete)

Tooltip (floating, mouse-follow)
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
| ≤1024px | 35vh top panel / 65vh canvas (vertical stack) |

**Mobile optimizations (≤1024px)**:
- Hide priority legend (colors visible on calendar nodes)
- Reduce header padding (`p-4` instead of `p-6`)
- Hide "Plan your 2026" subtitle
- Smaller section header text (`text-xs` instead of `text-sm`)

---

## 6. Data

### Schema

Redis key `event_tracker_2026`:
```json
{
  "events2026": [
    {
      "id": "evt_1704067200000",
      "title": "Event Title",
      "week": 12,
      "priority": "major",
      "description": "Optional"
    }
  ]
}
```

- `week: null` = backlog item
- `priority`: major | big | medium | minor

### Week Dates

- Weeks start Monday; Week 1 contains Jan 1, 2026
- Format: `"Feb 2-8"` or `"Jan 27 - Feb 2"` (cross-month)

---

## 7. API

| Endpoint | Method | Response |
|----------|--------|----------|
| `/` | GET | `index.html` |
| `/api/state` | GET | `{"events2026": [...]}` or `{"error": "..."}` |
| `/api/state` | POST | `{"ok": true}` or `{"error": "..."}` |

**Errors**: 400 invalid JSON, 400 body >1MB, 500 Redis unavailable

---

## 8. Stack & Deployment

### Files

| File | Purpose |
|------|---------|
| `main.go` | Go server with embedded static files |
| `index.html` | Frontend (Tailwind CDN, FontAwesome CDN) |
| `TESTING.md` | Validation procedures |

### Environment

| Variable | Default | Notes |
|----------|---------|-------|
| `PORT` | `8080` | HTTP port |
| `REDIS_URL` | `localhost:6379` | Without `redis://` prefix (code prepends it) |

### Deploy to Fly.io

```bash
fly redis create                    # Note the URL
fly secrets set REDIS_URL="default:pass@fly-xxx.upstash.io:6379"
fly deploy
```

### Local Development

```bash
redis-server                        # Terminal 1
go run main.go                      # Terminal 2
# http://localhost:8080
```

See `TESTING.md` for validation procedures.
