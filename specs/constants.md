# Constants

Single source of truth for all design tokens and magic values.

**Scope**: Values only. No behavior, no implementation. Behavior that uses these tokens lives in `frontend.md`.

### Tailwind v4 CSS Variable Mapping

Tokens are exposed as CSS custom properties via Tailwind v4's `@theme` directive in `src/styles.css`. The CSS variable names follow the pattern `--color-{token}` for colors, `--font-{token}` for fonts, `--shadow-{token}` for shadows:

| Token | CSS Variable |
|-------|-------------|
| `surface` | `--color-surface` |
| `borderLight` | `--color-border-light` |
| `borderMedium` | `--color-border-medium` |
| `borderDark` | `--color-border-dark` |
| `textPrimary` | `--color-text-primary` |
| `textSecondary` | `--color-text-secondary` |
| `textMuted` | `--color-text-muted` |
| `priorityMajor` | `--color-priority-major` |
| `priorityBig` | `--color-priority-big` |
| `priorityMedium` | `--color-priority-medium` |
| `priorityMinor` | `--color-priority-minor` |
| Font family | `--font-sans` = `"Inter", system-ui, sans-serif` |
| Node shadow | `--shadow-node` |
| Hub inset shadow | `--shadow-hub-inset` |
| Hub ring shadow | `--shadow-hub-ring` |

This enables Tailwind utilities like `bg-surface`, `text-text-primary`, `border-border-light`, etc.

---

## Colors

### Base Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#FFFFFF` | Modals, pure white surfaces |
| `surface` | `#FAF9F7` | Sidebar, canvas, cards (warm linen) |
| `borderLight` | `#E8E6E3` | Cards, dividers, empty nodes (warm border) |
| `borderMedium` | `#D4D1CC` | Input borders (warm input border) |
| `borderDark` | `#374151` | Hover states, emphasis |
| `textPrimary` | `#111827` | Headers, important text |
| `textSecondary` | `#374151` | Body text |
| `textMuted` | `#8B8579` | Captions, labels (warm muted) |

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
| `progressArcWidth` | `3` | Stroke width for year progress arc (SVG units) |

### Quarter Markers

| Token | Value | Notes |
|-------|-------|-------|
| `quarterWeeks` | `[13, 26, 39]` | Week indices marking Q1/Q2/Q3 boundaries |
| `quarterTickLength` | `12` | Tick mark length (SVG units) |
| `quarterTickWidth` | `1.5` | Stroke width (SVG units) |
| `quarterTickOffset` | `8` | Distance past `outerRadius` to center the tick |

---

## Timing

### Transitions

| Token | Value | Usage |
|-------|-------|-------|
| `hoverTransition` | `200ms` | Node hover scale/border |
| `hoverEasing` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Bouncy scale effect |
| `collapseTransition` | `300ms ease-out` | Section expand/collapse |
| `tooltipFade` | `150ms` | Tooltip show/hide |
| `nodeStaggerDelay` | `8ms` | Per-node entrance delay |
| `nodeEntranceDuration` | `400ms` | Node scale-in animation |
| `nodeEntranceEasing` | `cubic-bezier(0.16, 1, 0.3, 1)` | Expo-out for entrance |
| `currentWeekPulse` | `3s ease-in-out infinite` | Breathing glow cycle |
| `hubCrossfade` | `200ms ease` | Hub text transition on hover |
| `cardLiftDuration` | `150ms ease` | Event card hover lift |

---

## Typography

### Font

- **Family:** Inter (self-hosted)
- **Weights:** 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)
- **Loading:** `@font-face` in `src/styles.css`, preload weight 400 in HTML
- **Source:** [Inter releases](https://github.com/rsms/inter/releases)

#### Font Files

| Weight | File | Size |
|--------|------|------|
| 400 | `public/fonts/inter-400.woff2` | ~95KB |
| 500 | `public/fonts/inter-500.woff2` | ~97KB |
| 600 | `public/fonts/inter-600.woff2` | ~97KB |
| 700 | `public/fonts/inter-700.woff2` | ~97KB |

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

Bottom bar offset: `1.5rem` minimum, or `env(safe-area-inset-bottom) + 1rem` on devices with a home indicator.

---

## Calendar Data

### Weeks Per Month (2026)

```
Jan: 5, Feb: 4, Mar: 4, Apr: 5, May: 4, Jun: 5
Jul: 4, Aug: 5, Sep: 4, Oct: 5, Nov: 4, Dec: 5
```

Total: 54 nodes distributed across months. Since a year has 52 weeks, months with boundary weeks share nodes with adjacent months. When computing week numbers, weeks that span month boundaries are assigned to the month containing Thursday (majority of days). Any month slot beyond week 52 is not rendered.

### Week Calculation

- Monday-aligned, Week 1 contains January 1st (note: this differs from ISO 8601 where Week 1 contains the first Thursday)
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
| Nodes | `0 1px 3px rgba(120,100,80,0.06)` |
| Cards | `shadow-sm` (Tailwind) |
| Modals | `shadow-xl` (Tailwind) |
| Hub (inset) | `inset 0 2px 8px rgba(120,100,80,0.07)` |
| Hub (ring) | `0 0 0 1px rgba(120,100,80,0.05)` |

### Modal Overlay

- **Desktop (>1024px)**: Centered dialog
  - Backdrop: 40% white with `backdrop-blur(4px)`
- **Mobile (≤1024px)**: Full-screen takeover
  - No backdrop (form fills screen)
  - Height: `min-height: 100dvh` (accounts for virtual keyboard)
  - `overflow-y: auto` for scrollable form content
  - On input focus: `scrollIntoView({ block: "center", behavior: "smooth" })` after 300ms delay

### Opacity

| State | Opacity |
|-------|---------|
| Past weeks | 65% |
| Future weeks | 100% |
| Current week | 100% + 3px border |

### Current Week Glow

Soft animated ring behind the current week node:
- SVG filter: `feGaussianBlur` with `stdDeviation="3"` on a textPrimary-colored circle
- Animation: opacity pulses 0.15 → 0.4 over `currentWeekPulse` duration
- Renders behind the node visual (lower z-order within the `<g>`)
- Only the single current-week node, not a class on all nodes

