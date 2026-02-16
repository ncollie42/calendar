---
created: 2026-02-16T10:40
title: Add Shared Planning Signals (Activity + Comments)
area: product
files:
  - specs/requirements.md
  - specs/frontend.md
  - specs/data-model.md
  - specs/backend.md
---

## Problem

Shared calendars support collaboration, but there is little visibility into what changed or why. Members can miss updates and lose planning context.

## Solution

Add lightweight shared-planning signals that improve awareness without turning the app into project management.

1. Activity feed for calendar changes
- Show recent high-signal actions (event created, moved week, priority changed, deleted)
- Include actor, event title, and relative time
- Keep scope short and readable (recent window, not full audit tooling)

2. Optional comments per event
- Allow short comments on an event for coordination context
- Show author + timestamp
- Keep comments optional and lightweight; no threads/reactions/mentions in first version

3. Product boundaries
- Preserve the app's high-level yearly planning focus
- Avoid task-assignment workflows, notifications complexity, and heavy collaboration mechanics

## Acceptance Criteria

- Members can see a clear recent-history view of meaningful calendar changes
- Members can add and read comments on events
- Shared planning context improves without increasing interaction complexity
- Non-members and view-only share links remain read-only for these collaboration features
