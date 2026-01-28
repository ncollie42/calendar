# Backend Specification

Server, deployment, and infrastructure for Event Tracker 2026.

**Related specs:**
- `data-model.md` — Database schema, types, access control
- `manifest.md` — Complete file list and build order
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

**Note**: CSS requires Tailwind compilation at runtime:
```typescript
const result = await $`bunx tailwindcss -i ./src/styles.css -o /dev/stdout`.text();
```
Raw CSS with `@tailwind` directives won't work—must compile before serving.

### Dynamic Icon Generation

PWA icons generated at runtime using raw PNG construction:

1. PNG signature: `[137, 80, 78, 71, 13, 10, 26, 10]`
2. IHDR chunk: width/height as 32-bit big-endian, bit depth 8, color type 2 (RGB)
3. IDAT chunk: `Bun.deflateSync()` to compress raw pixel data
4. CRC32 checksum for each chunk

Alternative: Static PNG files in `public/`.

### Development Hot Reload

```typescript
if (!isProd && import.meta.main) {
  const fs = await import("fs");
  const watcher = fs.watch("./src", { recursive: true }, () => {
    cachedBundle = null;
    cachedCss = null;  // Also invalidate CSS cache
  });
  process.on("exit", () => watcher.close());
}
```

Basic cache invalidation, not HMR. Browser refresh required.

---

## 2. Data Model

**See `data-model.md` for complete schema, types, and access control rules.**

Summary:
- `users` — Auth-managed user records
- `calendars` — Named calendars with owner
- `memberships` — User-calendar links with role (owner/member)
- `events` — Calendar events with week, priority, description
- `shareLinks` — View/invite tokens for sharing

---

## 3. Convex Functions

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

## 4. Share Link Security

### Token Generation (CRITICAL)

**MUST use CSPRNG, NEVER Math.random():**

```typescript
function generateSecureToken(): string {
  const chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  const array = new Uint8Array(22);
  crypto.getRandomValues(array);
  return Array.from(array, b => chars[b % 62]).join('');
}
```

**Why this matters:**
- `Math.random()` uses a PRNG that can be predicted
- OWASP classifies this as "Insecure Randomness" vulnerability
- Attackers observing outputs can predict future tokens
- `crypto.getRandomValues()` is cryptographically secure

### Rate Limiting

Protect `getCalendarByToken` from enumeration attacks:

```typescript
import { RateLimiter } from "convex-helpers/server/rateLimit";

const rateLimiter = new RateLimiter(ctx, {
  tokenLookup: { kind: "fixed window", rate: 10, period: "minute" },
});

// In getCalendarByToken:
const { ok } = await rateLimiter.check("tokenLookup", clientIP);
if (!ok) throw new Error("Rate limited");
```

**Limits:**
- Token lookup: 10 requests/minute per IP
- Prevents brute-force enumeration of tokens

### Join Flow Edge Cases

`joinViaInviteLink` must handle:

| Scenario | Behavior |
|----------|----------|
| Valid invite token | Create membership, return `{ membershipId, calendarId }` |
| Already a member | Return existing `{ membershipId, calendarId, alreadyMember: true }` |
| User is owner | Return `{ membershipId, calendarId, isOwner: true }` |
| Revoked token | Throw "Invalid or expired invite link" |
| View-only token | Throw "This link does not allow joining" |

**Return shape for frontend routing:**
```typescript
interface JoinResult {
  membershipId: Id<"memberships">;
  calendarId: Id<"calendars">;
  calendarName: string;
  alreadyMember?: boolean;
  isOwner?: boolean;
}
```

### Security References

- [OWASP: Insecure Randomness](https://owasp.org/www-community/vulnerabilities/Insecure_Randomness)
- [OWASP: Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [W3C: Capability URLs](https://www.w3.org/2001/tag/doc/capability-urls/)

---

## 5. Environment Variables

**Bun server:**
- `PORT` — Default: 3000
- `NODE_ENV` — `development` or `production`

**Convex (`.env.local`, auto-generated):**
```
CONVEX_DEPLOYMENT=dev:opulent-lynx-809
CONVEX_URL=https://opulent-lynx-809.convex.cloud
```

**Convex production (set via CLI):**
- `SITE_URL` — `https://<deployment>.convex.site`
- `AUTH_GOOGLE_ID` — Google OAuth client ID
- `AUTH_GOOGLE_SECRET` — Google OAuth client secret

---

## 6. Deployment

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

### Build Process (`build.ts`)

1. Bundle `src/main.tsx` → `dist/main.js` (minified, CONVEX_URL injected)
2. Generate `dist/index.html` (rewrite script src)
3. Copy `src/styles.css` → `dist/styles.css`

Production `server.ts` serves from `dist/`.

### Fly.io Config (`fly.toml`)

```toml
[build.args]
  CONVEX_URL = "https://zealous-hyena-667.convex.cloud"
```

### Docker Build Requirements

**Critical**: `convex/_generated/` must be available during Docker builds.

Convex generates TypeScript types in `convex/_generated/` when you run `bunx convex dev` or `bunx convex codegen`. These files are required for the build but are typically gitignored.

**Solution**: Do NOT exclude `convex/_generated/` from `.dockerignore`. Commit these files to git so they're available in the Docker build context.

```bash
# .dockerignore - do NOT include this line:
# convex/_generated/   <- WRONG, breaks Docker builds

# .gitignore - remove or comment out:
# convex/_generated/   <- Must be committed for Docker builds
```

**Verify locally before deploying**:
```bash
docker build --build-arg CONVEX_URL=https://your-deployment.convex.cloud .
```

---

## 7. Local Development

```bash
# Terminal 1: Convex dev server
bunx convex dev

# Terminal 2: Bun dev server
bun run dev

# Open http://localhost:3000
```

---

## 8. Testing

### Test Architecture

Two test runners due to runtime requirements:

| Runner | Environment | Tests | Why |
|--------|-------------|-------|-----|
| `bun test` | Bun runtime | Server | Requires `Bun.serve()`, `Bun.build()` |
| `vitest` | edge-runtime | Convex | Required by `convex-test` |

### Running Tests

```bash
bun run test          # All tests
bun run test:convex   # Convex only (vitest)
bun run test:server   # Server only (bun test)
bun run test:watch    # Watch mode
```

### Configuration

**vitest.config.ts:**
```typescript
export default defineConfig({
  test: {
    environment: "edge-runtime",
    server: { deps: { inline: ["convex-test"] } },
    include: ["convex/**/*.test.ts"],
  },
});
```

**convex/test.setup.ts:**
```typescript
// @ts-ignore - Vite/Vitest specific
export const modules = import.meta.glob("./**/!(*.*.*)*.*s") as Record<
  string,
  () => Promise<unknown>
>;
```

### Server Testability Pattern

```typescript
export function createServer(port: number = PORT) {
  const server = Bun.serve({ port, fetch(req) { ... } });
  return server;
}

if (import.meta.main) {
  const server = createServer();
  console.log(`Server running at http://localhost:${server.port}`);
}
```

- `import.meta.main` guards against import side effects
- Port 0 for OS-assigned ports in tests
- Server object has `.port` and `.stop()`

### Test Coverage

**Server tests** (`tests/server.test.ts`):
- All endpoints return expected status and content-type
- PNG icons have valid signature bytes
- Unknown paths return 404

**Convex tests** (`convex/events.test.ts`):
- CRUD operations return correct data
- Access control enforced

**Share link tests** (`convex/shareLinks.test.ts`):
- Token is 22 characters (security requirement)
- Token uses full base62 charset (not predictable)
- Revoked tokens return null
- Already-member join returns `alreadyMember: true`
- Owner join returns `isOwner: true`
- Non-owner cannot create/revoke links
- View token cannot be used to join
- Rate limiting blocks enumeration (if implemented)

### Lessons Learned

**convex-test + @convex-dev/auth:**
- Standard `identity` option doesn't work with `getAuthUserId()`
- Workaround: Test database operations via `t.run()`:
```typescript
await t.run(async (ctx) => {
  return await ctx.db.insert("events", {...});
});
```

**Two test runners required:**
- `convex-test` needs edge-runtime
- Server tests need Bun APIs
- Solution: Separate runners, combined `test` script

**CONVEX_URL undefined in tests:**
- `Bun.build({ define: { "process.env.CONVEX_URL": JSON.stringify(undefined) } })` throws
- Solution: Conditionally add define

**Import side effects:**
- Server started on import, breaking tests
- Solution: `import.meta.main` guard

**Port conflicts:**
- Solution: Port 0 for dynamic assignment

**`import.meta.glob` TypeScript error:**
- Solution: `@ts-ignore` + explicit type annotation

---

## 9. Implementation Notes

### TypeScript Quirks

- `convex/_generated/` doesn't exist until `bunx convex dev`
- Run `bunx convex codegen` for types without dev server
- Bun Response body may need `as unknown as BodyInit` cast

### Priority Type Alignment

```typescript
const priority = event.priority as Priority;
```

### Convex URL Injection

**server.ts:**
```typescript
const result = await Bun.build({
  entrypoints: ["./src/main.tsx"],
  define: {
    "process.env.CONVEX_URL": JSON.stringify(process.env.CONVEX_URL),
  },
});
```

**src/main.tsx:**
```typescript
const convex = new ConvexReactClient(process.env.CONVEX_URL!);
```

### Build Order Dependency

1. `bunx convex codegen` (or `convex dev`)
2. `bunx tsc --noEmit`
3. `convex/_generated/` is gitignored but required

CI must run codegen before type checking.

### Authentication

**convex/auth.ts:**
```typescript
import Google from "@auth/core/providers/google";
import { convexAuth } from "@convex-dev/auth/server";

export const { auth, signIn, signOut, store } = convexAuth({
  providers: [Google],
  callbacks: {
    async afterUserCreatedOrUpdated(ctx, { userId, existingUserId }) {
      if (!existingUserId) {
        await ctx.scheduler.runAfter(0, internal.users.createPrimaryCalendar, { userId });
      }
    },
  },
});
```

**convex/auth.config.ts:**
```typescript
export default {
  providers: [{
    domain: process.env.CONVEX_SITE_URL,
    applicationID: "convex",
  }],
};
```

**convex/http.ts:**
```typescript
import { httpRouter } from "convex/server";
import { auth } from "./auth";

const http = httpRouter();
auth.addHttpRoutes(http);
export default http;
```
