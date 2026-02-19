# Backend Specification

Server, deployment, and infrastructure for Event Tracker 2026.

**Scope**: Architecture, deployment, testing, and infrastructure gotchas. No inline code — describe patterns and rules in prose.

**Related specs:**
- `data-model.md` — Database schema, types, access control
- `constants.md` — Design tokens used in icon generation

---

## 1. Architecture

### Stack

- **Server**: Bun.serve() for static files + bundling
- **Database**: Convex (real-time, serverless)
- **Auth**: Google OAuth via @convex-dev/auth
- **Deployment**: Fly.io (server) + Convex Cloud (data)

### Bun Server (`server.ts`)

Development mode bundles TypeScript/React on the fly. Production serves pre-built files from `dist/`.

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Serve `index.html` |
| `/src/main.tsx` | GET | Bundle and serve React app (dev) |
| `/main.js` | GET | Serve bundled JS (prod) |
| `/styles.css` | GET | Serve CSS |
| `/manifest.json` | GET | PWA manifest |
| `/sw.js` | GET | Service worker |
| `/icon-192.png` | GET | PWA icon (192×192) |
| `/icon-512.png` | GET | PWA icon (512×512) |

**Note**: CSS requires Tailwind v4 compilation at runtime.

**Tailwind v4 Gotchas:**
- Install both `tailwindcss` and `@tailwindcss/cli` as dev dependencies
- Must use explicit binary path `./node_modules/.bin/tailwindcss` — `bunx tailwindcss` fails silently
- Dev server (macOS): can pipe to `/dev/stdout`. Docker builds: must write to file directly (`/dev/stdout` unavailable)
- CSS file must include `@source` directives for class detection (paths relative to CSS file)
- Raw CSS with `@import "tailwindcss"` won't work — must compile before serving

### HTTP Cache Headers

| Resource | Cache-Control | Why |
|----------|---------------|-----|
| HTML (`/`) | `no-cache` | Always check for updates |
| JS (`/main.[hash].js`) | `public, max-age=31536000, immutable` | Hash changes on rebuild |
| CSS (`/styles.css`) | `public, max-age=300` | Short cache (no hash yet) |
| Fonts (`/fonts/*`) | `public, max-age=31536000, immutable` | Never changes |
| Icons, manifest | `public, max-age=86400` | Stable, 24h cache |
| `sw.js` | `no-cache` | Must always check for updates |

### Asset Hashing

Build script uses content hashing for JS bundles (e.g. `main.a1b2c3.js`). After build, inject the generated filename into `dist/index.html`. Content hashing + `immutable` cache header = browser never re-downloads unchanged JS.

### Font Serving

`/fonts/*` route serves woff2 files from `public/fonts/` with immutable cache headers (`public, max-age=31536000, immutable`). Add to the endpoint table:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/fonts/*` | GET | Self-hosted Inter font files (woff2) |

### Icon Generation

PWA icons at 192×192 and 512×512, solid `textPrimary` fill. Serve as static files from `public/` or generate at request time.

### Development Hot Reload

In dev mode, watch `./src` recursively and invalidate cached bundle + CSS on any change. Basic cache invalidation, not HMR — browser refresh required. Only run watcher when `import.meta.main` is true (not during tests).

---

## 2. Convex Functions

### Queries

| Function | Args | Returns | Purpose |
|----------|------|---------|---------|
| `events.getEvents` | `calendarId, shareToken?` | `Event[]` | Events for calendar |
| `calendars.getMyCalendars` | — | `Calendar[]` | User's calendars with role |
| `calendars.getPrimaryCalendar` | — | `Calendar \| null` | Primary owned calendar |
| `shareLinks.getCalendarShareLinks` | `calendarId` | `ShareLink[]` | Calendar's share links |
| `shareLinks.getCalendarByToken` | `token` | `{calendar, events}` | Public calendar access |

### Mutations

| Function | Args | Returns | Purpose |
|----------|------|---------|---------|
| `events.createEvent` | `calendarId, title, week, priority, description?` | `eventId` | Create event |
| `events.updateEvent` | `eventId, updates` | — | Update event |
| `events.deleteEvent` | `eventId` | — | Delete event |
| `calendars.createCalendar` | `name` | `calendarId` | Create calendar + membership |
| `calendars.deleteCalendar` | `calendarId` | — | Delete (owner only, cascades) |
| `shareLinks.createShareLink` | `calendarId, permission` | `linkId` | Generate share link |
| `shareLinks.revokeShareLink` | `linkId` | — | Soft-delete link |
| `shareLinks.joinViaInviteLink` | `token` | `membershipId` | Join via invite |

---

## 3. Share Link Security

Token generation and security invariants are canonical in `data-model.md`. This section covers server-side protections.

### Rate Limiting

`getCalendarByToken` must be rate-limited: 10 requests/minute per IP. Use `convex-helpers/server/rateLimit` with fixed window strategy.

### Join Flow Edge Cases

`joinViaInviteLink` must handle all cases and return a result the frontend can route on:

| Scenario | Behavior |
|----------|----------|
| Valid invite token | Create membership, return membershipId + calendarId + calendarName |
| Already a member | Return existing membership with `alreadyMember: true` |
| User is owner | Return existing membership with `isOwner: true` |
| Revoked token | Throw "Invalid or expired invite link" |
| View-only token | Throw "This link does not allow joining" |

---

## 4. Environment Variables

**Bun server:**
- `PORT` — Default: 3000
- `NODE_ENV` — `development` or `production`

**Convex (`.env.local`, auto-generated by `bunx convex dev`):**
- `CONVEX_DEPLOYMENT` — Dev deployment name
- `CONVEX_URL` — Dev deployment URL

**Convex production (set via CLI):**
- `SITE_URL` — `https://<deployment>.convex.site`
- `AUTH_GOOGLE_ID` — Google OAuth client ID
- `AUTH_GOOGLE_SECRET` — Google OAuth client secret

---

## 5. Deployment

### Convex URLs

| Pattern | Example | Purpose |
|---------|---------|---------|
| `*.convex.cloud` | `https://zealous-hyena-667.convex.cloud` | API (queries, mutations) |
| `*.convex.site` | `https://zealous-hyena-667.convex.site` | HTTP actions (OAuth) |

### Initial Setup

```bash
# 1. Install dependencies
bun install

# 2. Deploy Convex to production
bunx convex deploy

# 3. Set Convex environment variables
bunx convex env set SITE_URL https://<deployment>.convex.site --prod
bunx convex env set AUTH_GOOGLE_ID <client-id> --prod
bunx convex env set AUTH_GOOGLE_SECRET <client-secret> --prod

# 4. Configure Google OAuth (Google Cloud Console)
#    Redirect URI: https://<deployment>.convex.site/api/auth/callback/google

# 5. Deploy to Fly.io
fly deploy
```

### Subsequent Deploys

```bash
bunx convex deploy    # Convex functions
fly deploy            # Frontend/server
```

### Build Process

1. Bundle `src/main.tsx` → `dist/main.[hash].js` (minified, CONVEX_URL injected via `define`)
2. Generate `dist/index.html` (rewrite script src to hashed filename)
3. Compile `src/styles.css` → `dist/styles.css` via Tailwind CLI (write to file, not stdout — see Tailwind v4 Gotchas above)

Production server serves from `dist/`.

### Fly.io Config

`fly.toml` passes `CONVEX_URL` as a build arg.

### Docker Build Gotchas

- `convex/_generated/` must be available during Docker builds — commit these files to git
- Do NOT add `convex/_generated/` to `.dockerignore` or `.gitignore`
- These files are generated by `bunx convex dev` or `bunx convex codegen`

---

## 6. Testing

### Test Architecture

Two test runners due to runtime requirements:

| Runner | Environment | Tests | Why |
|--------|-------------|-------|-----|
| `bun test` | Bun runtime | Server | Requires `Bun.serve()`, `Bun.build()` |
| `vitest` | edge-runtime | Convex | Required by `convex-test` |

### Server Testability

Server must export a `createServer(port)` function. Production startup is guarded by `import.meta.main` so importing in tests doesn't start a server. Use port 0 for OS-assigned ports in tests.

### Vitest Configuration

- Environment: `edge-runtime`
- Inline deps: `convex-test`
- Include: `convex/**/*.test.ts`
- Requires a `convex/test.setup.ts` that exports module glob for convex-test

### Test Coverage

**Server tests**: All endpoints return expected status/content-type, PNG icons have valid signatures, unknown paths return 404.

**Convex event tests**: CRUD operations, access control enforced.

**Share link tests**: Token length (22 chars), full charset, revoked tokens return null, all join edge cases (already member, is owner, view-only token, non-owner restrictions).

---

## 7. Implementation Gotchas

- `convex/_generated/` doesn't exist until `bunx convex dev` or `bunx convex codegen` — CI must run codegen before type checking
- Bun Response body may need `as unknown as BodyInit` cast
- CONVEX_URL is injected at bundle time via `define` in `Bun.build()`, accessed as `process.env.CONVEX_URL` in client code
- Auth uses `@convex-dev/auth` with Google provider. On first user creation, `afterUserCreatedOrUpdated` callback schedules primary calendar creation via `ctx.scheduler.runAfter`
- Auth config points to `CONVEX_SITE_URL` domain with applicationID "convex"
- HTTP router must register auth routes via `auth.addHttpRoutes(http)`
