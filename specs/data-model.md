# Data Model

Single source of truth for database schema, access control, and security invariants.

**Scope**: Data shape and rules only. No TypeScript code, no implementation. Claude derives `convex/schema.ts` and TypeScript types from these tables.

---

## Overview

```
users (auth)
    │
    ├──< memberships >── calendars
    │        │
    │        └── role: owner | member
    │
    ├──< events (createdBy)
    │
    └──< shareLinks (createdBy)
```

- Users authenticate via Google OAuth
- Users access calendars through memberships
- Events belong to calendars, track creator
- Share links enable public/invite access

---

## Tables

### users

Managed by `@convex-dev/auth`. Contains auth provider data.

| Field | Type | Notes |
|-------|------|-------|
| `_id` | `Id<"users">` | Auto-generated |
| (auth fields) | — | Managed by auth library |

**Schema evolution note**: Existing deployments may have additional fields (e.g., `parentRefreshTokenId` in `authRefreshTokens`) not present in current `@convex-dev/auth` version. If schema validation fails, extend `authTables` to include extra fields from the existing deployment.

### calendars

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `_id` | `Id<"calendars">` | auto | — |
| `name` | `string` | yes | Display name |
| `createdBy` | `Id<"users">` | yes | Owner reference |
| `createdAt` | `number` | yes | Unix timestamp (ms) |

**Indexes:**
- `by_createdBy`: `[createdBy]`

### memberships

Links users to calendars with role.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `_id` | `Id<"memberships">` | auto | — |
| `calendarId` | `Id<"calendars">` | yes | — |
| `userId` | `Id<"users">` | yes | — |
| `role` | `"owner" \| "member"` | yes | Permission level |
| `joinedAt` | `number` | yes | Unix timestamp (ms) |

**Indexes:**
- `by_userId`: `[userId]` — get all calendars for a user
- `by_calendarId`: `[calendarId]` — get all members of a calendar
- `by_userId_calendarId`: `[userId, calendarId]` — check specific membership

**Invariants:**
- Each calendar has exactly one `owner` membership
- Owner membership created atomically with calendar
- Deleting calendar cascades to all memberships

### events

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `_id` | `Id<"events">` | auto | — |
| `calendarId` | `Id<"calendars">` | yes | Parent calendar |
| `title` | `string` | yes | Event name |
| `week` | `number \| null` | yes | 1-52 = scheduled, null = backlog |
| `priority` | `Priority` | yes | See below |
| `description` | `string` | no | Optional details |
| `createdBy` | `Id<"users">` | yes | Creator reference |
| `createdAt` | `number` | yes | Unix timestamp (ms) |

**Priority values:** `"major" | "big" | "medium" | "minor"`

**Indexes:**
- `by_calendarId`: `[calendarId]` — get all events for a calendar

**Invariants:**
- `week` must be 1-52 or null
- Deleting calendar cascades to all events

### shareLinks

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `_id` | `Id<"shareLinks">` | auto | — |
| `calendarId` | `Id<"calendars">` | yes | Target calendar |
| `token` | `string` | yes | 22-char base62, unique, CSPRNG |
| `permission` | `"view" \| "invite"` | yes | Access level |
| `createdBy` | `Id<"users">` | yes | Who generated |
| `createdAt` | `number` | yes | Unix timestamp (ms) |
| `revokedAt` | `number` | no | Soft delete timestamp |

**Indexes:**
- `by_token`: `[token]` — lookup by share token
- `by_calendarId`: `[calendarId]` — get all links for a calendar

**Permissions:**
- `view`: Read-only access, no auth required
- `invite`: Clicking link + signing in = member role

**Invariants:**
- Token is unique across all shareLinks
- Revoked links (revokedAt set) return 404, not forbidden
- Only calendar owner can create/revoke links

**Token Generation (SECURITY CRITICAL):**

22-char base62 string via `crypto.getRandomValues()` with rejection sampling. Never `Math.random()`.

- Charset: `[0-9A-Za-z]` (62 chars, ~5.95 bits each)
- Length: 22 chars = ~131 bits entropy (exceeds OWASP 128-bit minimum)
- Rejection sampling: discard random bytes ≥248 to eliminate modulo bias (`256 % 62 = 8` makes first 8 chars slightly more likely without rejection; `248 = 62 * 4` is the clean cutoff)
- Over-request bytes (e.g. 32 at a time) to minimize calls to `getRandomValues()`

---

## Access Control

### Query permissions

| Query | Auth required | Access rule |
|-------|---------------|-------------|
| `getMyCalendars` | yes | Returns calendars where user has membership |
| `getEvents` | no* | Membership OR valid share token |
| `getCalendarByToken` | no | Valid, non-revoked share token (rate limited) |
| `getCalendarShareLinks` | yes | Membership in calendar |

### Mutation permissions

| Mutation | Auth required | Access rule |
|----------|---------------|-------------|
| `createCalendar` | yes | Any authenticated user |
| `deleteCalendar` | yes | Owner only |
| `createEvent` | yes | Membership in calendar |
| `updateEvent` | yes | Membership in calendar |
| `deleteEvent` | yes | Membership in calendar |
| `createShareLink` | yes | Owner only |
| `revokeShareLink` | yes | Owner only |
| `joinViaInviteLink` | yes | Valid invite token (returns rich result) |

