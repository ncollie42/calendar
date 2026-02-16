# Requirements

User stories and acceptance criteria for Event Tracker 2026.

---

## Product Vision

A radial year-view calendar for planning significant life events across 52 weeks. Inspired by "4K Weeks" life calendars and year-goal posters. The visualization creates urgency and perspective by showing the entire year at once—making empty weeks visible and motivating action.

### Target Users

**Individuals** planning their year with major milestones (career moves, travel, personal goals) who want a bird's-eye view rather than day-by-day detail.

**Couples** sharing a calendar to visualize their year together—trips, anniversaries, goals they're tackling as a pair. The shared view keeps both partners aligned on what's coming.

**Friend groups & families** coordinating at a high level—reunions, group trips, holidays. The radial view makes it fun to see the year fill up and spot empty stretches that need planning.

### Core Value

The calendar answers: "What are we doing with our year?" Not daily logistics, but the meaningful stuff. Seeing 52 weeks at once creates gentle pressure to make them count—and makes shared planning feel tangible.

**Not for:** Daily scheduling, recurring events, detailed time-blocking, or work project management.

---

## User Stories

### Authentication

**US-1: Sign in with Google**
> As a user, I want to sign in with my Google account so I don't need to create another password.

Acceptance criteria:
- [ ] Single "Sign in with Google" button on auth screen
- [ ] Successful auth creates user record and primary calendar
- [ ] Failed auth shows error, allows retry
- [ ] Session persists across browser refreshes

**US-1b: See account and sign out**
> As a user, I want to see which Google account I'm signed in with and be able to sign out.

Acceptance criteria:
- [ ] Signed-in email and Google avatar visible in sidebar
- [ ] Sign out button next to account info
- [ ] Sign out returns to auth screen
- [ ] Sign out from shared calendar view returns to auth screen but preserves the share URL so the user can still view (if view-only)

---

### Calendar Management

**US-2: Multiple calendars**
> As a user, I want to create multiple calendars so I can separate different contexts (personal, couple, family, friends).

Acceptance criteria:
- [ ] Dropdown in sidebar shows all my calendars
- [ ] Can create new calendar with custom name
- [ ] Can delete calendars I own (with confirmation)
- [ ] Deleting calendar removes all its events

**US-3: Share calendar (view-only)**
> As a user, I want to share a read-only link so others can see our plans without needing an account.

Acceptance criteria:
- [ ] Generate shareable URL from share modal
- [ ] Anyone with link sees calendar and events (no auth required)
- [ ] Shared view clearly indicates read-only status
- [ ] Can revoke link to disable access

**US-4: Share calendar (collaborative)**
> As a couple or group, we want to invite others to edit our shared calendar so we can plan together.

Acceptance criteria:
- [ ] Generate invite link from share modal
- [ ] Clicking invite link prompts sign-in, then adds user as member
- [ ] Members can create, edit, delete events
- [ ] Only owner can delete calendar or manage share links

---

### Event Management

**US-5: Create event**
> As a user, I want to add events to specific weeks so we can plan when things will happen.

Acceptance criteria:
- [ ] Click node or "Add Event" button opens modal
- [ ] Required: title, priority
- [ ] Optional: week (null = backlog), description
- [ ] Event appears on calendar immediately after save

**US-6: Edit event**
> As a user, I want to modify events so we can adjust plans as things change.

Acceptance criteria:
- [ ] Click event card opens modal with current values
- [ ] Can change any field
- [ ] Can move event to different week or backlog
- [ ] Changes reflect immediately

**US-7: Delete event**
> As a user, I want to remove events so we can clean up cancelled plans.

Acceptance criteria:
- [ ] Delete button in edit modal
- [ ] Confirmation dialog before deletion
- [ ] Event removed from calendar and sidebar immediately

**US-8: Backlog**
> As a user, I want a backlog for unscheduled events so we can capture ideas without committing to dates.

Acceptance criteria:
- [ ] Events with week=null appear in backlog section
- [ ] Can move events between backlog and scheduled
- [ ] Backlog section collapsible, default collapsed

**US-9: Priority levels**
> As a user, I want to assign priority to events so we can distinguish major milestones from smaller plans.

Acceptance criteria:
- [ ] Four priority levels: Major, Big, Medium, Minor
- [ ] Each has distinct color visible on calendar nodes
- [ ] When week has multiple events, node shows highest priority color
- [ ] Events sorted by priority in sidebar lists

---

### Visualization

**US-10: Radial year view**
> As a user, I want to see our entire year at a glance so we can understand the big picture and spot empty weeks.

Acceptance criteria:
- [ ] 52 week nodes arranged radially by month
- [ ] 12 month spokes with labels
- [ ] Empty weeks shown as outlined squares (visible gaps = motivation)
- [ ] Weeks with events filled with priority color

**US-11: Current week indicator**
> As a user, I want to see which week is "now" so we can orient ourselves in time.

Acceptance criteria:
- [ ] Current week node has thicker border
- [ ] Past weeks at reduced opacity
- [ ] Center hub shows "Week X of 52"

**US-12: Week details on hover**
> As a user, I want to see week details without clicking so I can quickly scan the calendar.

Acceptance criteria:
- [ ] Hover shows tooltip with: week number, date range, event list
- [ ] Desktop: tooltip follows cursor
- [ ] Touch: tap shows anchored tooltip, tap elsewhere dismisses

---

### Mobile Experience

**US-13: Mobile-friendly layout**
> As a user, I want to use this on my phone so I can check plans on the go or show friends.

Acceptance criteria:
- [ ] Two-view toggle: calendar view and events view
- [ ] FAB on calendar view opens events
- [ ] Back button on events view returns to calendar
- [ ] Touch targets minimum 36px
- [ ] Safe area insets respected

**US-14: Installable PWA**
> As a user, I want to install this as an app so I can access it quickly from my home screen.

Acceptance criteria:
- [ ] "Add to Home Screen" prompt available
- [ ] Launches in standalone mode (no browser chrome)
- [ ] App icon appears on home screen
- [ ] Works online only (no offline requirement)

---

## Non-Functional Requirements

**NFR-1: Performance**
- Initial render under 500ms (empty calendar structure)
- Data population under 1s on typical connection

**NFR-2: Accessibility**
- Keyboard navigation for event creation (Cmd/Ctrl+K)
- Escape closes modals
- Color is not the only indicator (shapes + color for priority)

**NFR-3: Data integrity**
- All mutations require authentication
- Users can only access calendars they own or are members of
- Share tokens are 22-char base62, unguessable (see constants.md)
