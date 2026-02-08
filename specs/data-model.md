# Data Model

Single source of truth for database schema. Implementation: `convex/schema.ts`

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

**Schema evolution note**: Existing deployments may have additional fields (e.g., `parentRefreshTokenId` in `authRefreshTokens`) not present in current `@convex-dev/auth` version. Extend `authTables` if schema validation fails:
```typescript
const extendedAuthTables = {
  ...authTables,
  authRefreshTokens: defineTable({
    // ... include extra fields from existing deployment
  }),
};
```

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
| `participants` | `Id<"users">[]` | no | Future: assigned users |
| `createdBy` | `Id<"users">` | yes | Creator reference |
| `createdAt` | `number` | yes | Unix timestamp (ms) |

**Priority enum:**
```typescript
type Priority = "major" | "big" | "medium" | "minor"
```

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
```typescript
// MUST use crypto.getRandomValues(), NEVER Math.random()
function generateSecureToken(): string {
  const chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  let result = "";
  while (result.length < 22) {
    const array = new Uint8Array(32); // over-request to handle rejections
    crypto.getRandomValues(array);
    for (const b of array) {
      if (result.length >= 22) break;
      if (b < 248) result += chars[b % 62]; // reject 248-255 to eliminate modulo bias
    }
  }
  return result;
}
```

**Why rejection sampling:** `256 % 62 = 8`, so naive `b % 62` makes chars 0-7 slightly more likely than chars 8-61. Rejecting bytes 248-255 (where `248 = 62 * 4`) ensures uniform distribution. At this entropy level the bias is not exploitable, but the fix is trivial so we do it correctly.

**Why 22 characters:**
- OWASP requires 128+ bits for security tokens
- Base62 provides ~5.95 bits per character
- 22 × 5.95 = ~131 bits (exceeds minimum)
- Math.random() is predictable and MUST NOT be used

---

## Convex Schema

Reference implementation for `convex/schema.ts`:

```typescript
import { defineSchema, defineTable } from "convex/server";
import { authTables } from "@convex-dev/auth/server";
import { v } from "convex/values";

export default defineSchema({
  ...authTables,

  calendars: defineTable({
    name: v.string(),
    createdBy: v.id("users"),
    createdAt: v.number(),
  }).index("by_createdBy", ["createdBy"]),

  memberships: defineTable({
    calendarId: v.id("calendars"),
    userId: v.id("users"),
    role: v.union(v.literal("owner"), v.literal("member")),
    joinedAt: v.number(),
  })
    .index("by_userId", ["userId"])
    .index("by_calendarId", ["calendarId"])
    .index("by_userId_calendarId", ["userId", "calendarId"]),

  events: defineTable({
    calendarId: v.id("calendars"),
    title: v.string(),
    week: v.union(v.number(), v.null()),
    priority: v.union(
      v.literal("major"),
      v.literal("big"),
      v.literal("medium"),
      v.literal("minor")
    ),
    description: v.optional(v.string()),
    participants: v.optional(v.array(v.id("users"))),
    createdBy: v.id("users"),
    createdAt: v.number(),
  }).index("by_calendarId", ["calendarId"]),

  // Token: 22-char base62, generated via crypto.getRandomValues()
  // See "Token Generation" section for implementation
  shareLinks: defineTable({
    calendarId: v.id("calendars"),
    token: v.string(),  // 22 chars, CSPRNG-generated
    permission: v.union(v.literal("view"), v.literal("invite")),
    createdBy: v.id("users"),
    createdAt: v.number(),
    revokedAt: v.optional(v.number()),
  })
    .index("by_token", ["token"])
    .index("by_calendarId", ["calendarId"]),
});
```

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

---

## TypeScript Types

Frontend type definitions derived from schema:

```typescript
import { Id } from "convex/_generated/dataModel";

export type Priority = "major" | "big" | "medium" | "minor";
export type Role = "owner" | "member";
export type SharePermission = "view" | "invite";

export interface Event {
  _id: Id<"events">;
  calendarId: Id<"calendars">;
  title: string;
  week: number | null;
  priority: Priority;
  description?: string;
  participants?: Id<"users">[];
  createdBy: Id<"users">;
  createdAt: number;
}

export interface Calendar {
  _id: Id<"calendars">;
  name: string;
  createdBy: Id<"users">;
  createdAt: number;
}

export interface Membership {
  _id: Id<"memberships">;
  calendarId: Id<"calendars">;
  userId: Id<"users">;
  role: Role;
  joinedAt: number;
}

export interface ShareLink {
  _id: Id<"shareLinks">;
  calendarId: Id<"calendars">;
  token: string;
  permission: SharePermission;
  createdBy: Id<"users">;
  createdAt: number;
  revokedAt?: number;
}

// Result from joinViaInviteLink mutation
export interface JoinResult {
  membershipId: Id<"memberships">;
  calendarId: Id<"calendars">;
  calendarName: string;
  alreadyMember?: boolean;  // User was already a member
  isOwner?: boolean;        // User is the calendar owner
}
```
