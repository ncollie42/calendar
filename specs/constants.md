# Constants

Single source of truth for all design tokens and magic values. Code should import from `src/lib/constants.ts` which implements these values.

### Tailwind v4 Integration

Design tokens are defined in `src/styles.css` using Tailwind v4's `@theme` directive:

```css
@import "tailwindcss";

@theme {
  --color-surface: #F9FAFB;
  --color-border-light: #E5E7EB;
  --color-border-medium: #D1D5DB;
  --color-border-dark: #374151;
  --color-text-primary: #111827;
  --color-text-secondary: #374151;
  --color-text-muted: #6B7280;
  --color-priority-major: #E1523D;
  --color-priority-big: #ED8B16;
  --color-priority-medium: #C2BB00;
  --color-priority-minor: #005E54;
  --font-sans: "Inter", system-ui, sans-serif;
  --shadow-node: 0 1px 3px rgba(0,0,0,0.04);
  --shadow-hub-inset: inset 0 2px 8px rgba(0,0,0,0.06);
  --shadow-hub-ring: 0 0 0 1px rgba(0,0,0,0.04);
}
```

No separate config files needed—Tailwind v4 uses CSS-native configuration.

---

## Colors

### Base Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#FFFFFF` | Modals, pure white surfaces |
| `surface` | `#F9FAFB` | Sidebar, canvas, cards |
| `borderLight` | `#E5E7EB` | Cards, dividers, empty nodes |
| `borderMedium` | `#D1D5DB` | Input borders |
| `borderDark` | `#374151` | Hover states, emphasis |
| `textPrimary` | `#111827` | Headers, important text |
| `textSecondary` | `#374151` | Body text |
| `textMuted` | `#6B7280` | Captions, labels |

### Priority Colors

| Priority | Token | Hex | Description |
|----------|-------|-----|-------------|
| Major | `priorityMajor` | `#E1523D` | Vermilion red |
| Big | `priorityBig` | `#ED8B16` | Tangerine orange |
| Medium | `priorityMedium` | `#C2BB00` | Golden yellow |
| Minor | `priorityMinor` | `#005E54` | Deep teal |

### Priority Order (highest to lowest)

```
major → big → medium → minor
```

When a week has multiple events, the node displays the highest priority color.

---

## Geometry

### SVG Canvas

| Token | Value | Notes |
|-------|-------|-------|
| `viewBox` | `700` | Fixed 700×700 SVG |
| `center` | `350` | Center point (350, 350) |

### Radial Layout

| Token | Value | Notes |
|-------|-------|-------|
| `innerRadius` | `120` | Start of node placement |
| `outerRadius` | `280` | End of node placement |
| `labelOffset` | `40` | Distance past outerRadius for month labels |
| `dividerInner` | `56` | Divider line start (at hub edge) |
| `dividerOuter` | `310` | Divider line end (past labels) |

### Nodes

| Token | Value | Notes |
|-------|-------|-------|
| `nodeSize` | `24` | Visual node dimensions (24×24px) |
| `hitboxSize` | `36` | Touch target dimensions (36×36px) |
| `nodeBorderRadius` | `8` | Rounded square corners |

### Center Hub

| Token | Value | Notes |
|-------|-------|-------|
| `hubRadius` | `56` | Hub is 112px diameter (56px radius) |

---

## Timing

### Transitions

| Token | Value | Usage |
|-------|-------|-------|
| `hoverTransition` | `200ms` | Node hover scale/border |
| `hoverEasing` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Bouncy scale effect |
| `collapseTransition` | `300ms ease-out` | Section expand/collapse |
| `tooltipFade` | `150ms` | Tooltip show/hide |

---

## Typography

### Font

- **Family:** Inter (Google Fonts)
- **Weights:** 400 (Regular), 500 (Medium), 700 (Bold)
- **Loading:** `display=swap`

### Scale

| Usage | Weight | Size |
|-------|--------|------|
| Titles | 700 | — |
| Labels | 500 | — |
| Body | 400 | — |
| Month labels (desktop) | 600 | 12px |
| Month labels (mobile) | 600 | 14px |

---

## Layout

### Breakpoints

| Name | Value | Layout |
|------|-------|--------|
| Desktop | `>1024px` | 25% sidebar / 75% canvas |
| Mobile | `≤1024px` | Full-screen view toggle |

### Sidebar Width (Desktop)

- Min: 280px
- Max: 360px
- Relative: 25% of viewport

### Mobile Safe Areas

```css
bottom: max(1.5rem, env(safe-area-inset-bottom) + 1rem)
```

---

## Calendar Data

### Weeks Per Month (2026)

```
Jan: 5, Feb: 4, Mar: 4, Apr: 5, May: 4, Jun: 5
Jul: 4, Aug: 5, Sep: 4, Oct: 5, Nov: 4, Dec: 5
```

Total: 54 nodes distributed, capped at 52 unique weeks.

### Week Calculation

- ISO-style: Monday-aligned, Week 1 contains January 1st
- 2026 Week 1: Dec 29, 2025 – Jan 4, 2026
- Formula: `Math.floor(daysSinceWeek1Start / 7) + 1`

### Month Names

```
January, February, March, April, May, June,
July, August, September, October, November, December
```

### Month Abbreviations

```
Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec
```

---

## Effects

### Shadows

| Usage | Value |
|-------|-------|
| Nodes | `0 1px 3px rgba(0,0,0,0.04)` |
| Cards | `shadow-sm` (Tailwind) |
| Modals | `shadow-xl` (Tailwind) |
| Hub (inset) | `inset 0 2px 8px rgba(0,0,0,0.06)` |
| Hub (ring) | `0 0 0 1px rgba(0,0,0,0.04)` |

### Modal Overlay

- Backdrop: 40% white
- Blur: `backdrop-blur(4px)`

### Opacity

| State | Opacity |
|-------|---------|
| Past weeks | 65% |
| Future weeks | 100% |
| Current week | 100% + 3px border |

---

## Share Links

| Property | Value | Notes |
|----------|-------|-------|
| Token length | 22 characters | 128+ bits entropy (OWASP minimum) |
| Token charset | Base62 (`[a-zA-Z0-9]`) | ~5.95 bits per character |
| URL format | `#/share/{token}` | Hash-based for SPA routing |
| Generation | `crypto.getRandomValues()` | CSPRNG required, never Math.random() |

### Token Security Requirements

- **Entropy**: 22 chars × 5.95 bits = ~131 bits (exceeds OWASP 128-bit minimum)
- **Generation**: Must use cryptographically secure random number generator
- **Uniqueness**: Collision probability negligible at this entropy level
- **Reference**: [W3C Capability URLs](https://www.w3.org/2001/tag/doc/capability-urls/)
