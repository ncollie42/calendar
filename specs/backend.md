# Backend Specification

Go server for the 2026 Planning Calendar with optional HEY Calendar sync.

---

## 1. Architecture

### Project Structure

```
calendar/
├── main.go              # Server, imports "calendar/hey"
├── index.html           # Embedded frontend
├── hey/
│   ├── client.go        # HEY client (see hey-library.md)
│   ├── events.go        # Create/Update/Delete
│   └── client_test.go   # Integration tests
```

### Go Server (`main.go`)

Single binary with embedded `index.html`. Stores all state in Redis. Imports HEY client from `hey/` subfolder.

### Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Serve `index.html` |
| `/api/state` | GET | Return full state `{"events2026": [...]}` |
| `/api/state` | POST | Save full state (replaces all events, syncs to HEY) |

### Data Model

```go
type Event struct {
    ID          string  `json:"id"`                      // "evt_1704067200000"
    Title       string  `json:"title"`
    Week        *int    `json:"week"`                    // null = backlog
    Priority    string  `json:"priority"`                // major|big|medium|minor
    Description string  `json:"description,omitempty"`
    HeyEventID  string  `json:"heyEventId,omitempty"`    // HEY's internal event ID (server-side only)
}
```

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | `8080` | HTTP server port |
| `REDIS_URL` | Yes (production) | `localhost:6379` | Redis connection. App fails to start if unavailable. |
| `HEY_SYNC_ENABLED` | No | `false` | Set to `true` to enable HEY sync |
| `HEY_EMAIL` | If sync enabled | - | HEY account email |
| `HEY_PASSWORD` | If sync enabled | - | HEY account password |
| `HEY_CALENDAR_ID` | If sync enabled | - | Target calendar ID (e.g., `486638`) |
| `HEY_TIMEZONE` | No | `Pacific Time (US & Canada)` | Timezone for events |
| `HEY_INVITE_EMAIL` | No | - | Email to send calendar invites to. When set, all created/updated HEY events will invite this address. |

**Note**: For production use, `HEY_INVITE_EMAIL` should be configured to ensure calendar invites are sent.

### Startup Requirements

The server performs these checks at startup and **exits immediately** if any fail:

1. **Redis connection** - Must successfully ping Redis. Fail with `log.Fatal()` if unreachable.
2. **HEY client** (if `HEY_SYNC_ENABLED=true`) - Must successfully authenticate. Log warning and continue without sync if auth fails.

### Fly.io Deployment

Fly.io provides `REDIS_URL` automatically when Upstash Redis is attached to the app. No manual configuration needed.

```bash
# Attach Redis (one-time setup)
fly redis create
fly redis attach <redis-name>

# Redis URL is automatically injected as REDIS_URL
```

---

## 2. HEY Calendar Sync

### Overview

When `HEY_SYNC_ENABLED=true`, the backend automatically syncs scheduled events to HEY Calendar:

| Action | Result |
|--------|--------|
| Event scheduled (week assigned) | Create HEY calendar event |
| Event unscheduled (moved to backlog) | Delete HEY calendar event |
| Event deleted | Delete HEY calendar event (if was scheduled) |
| Week changed | Delete old, create new |

**Status**: Experimental - uses HEY's internal API (see `hey-library.md`).

### Sync Strategy

On each `POST /api/state`:

1. Load previous state from Redis (contains `heyEventId` values)
2. Compare with new state from frontend (does NOT contain `heyEventId`)
3. For each event:
   - **Newly scheduled** → Create HEY event, store `heyEventId`
   - **Unscheduled** → Delete HEY event using stored `heyEventId`
   - **Deleted** → Delete HEY event if `heyEventId` exists
   - **Week changed** → Delete old HEY event, create new one
   - **Unchanged** → Preserve `heyEventId` from old state
4. Save updated state (with `heyEventId` values) to Redis

**Important**: The frontend does NOT track `heyEventId`. It's managed entirely server-side.

### Sync Algorithm

```go
func syncHeyCalendar(heyClient *HeyClient, oldEvents, newEvents []Event, inviteEmail string) []Event {
    // Build lookup maps
    oldByID := make(map[string]Event)
    for _, e := range oldEvents {
        oldByID[e.ID] = e
    }

    newByID := make(map[string]Event)
    for _, e := range newEvents {
        newByID[e.ID] = e
    }

    // Process deletions: events in old but not in new
    for _, old := range oldEvents {
        if _, exists := newByID[old.ID]; !exists {
            if old.HeyEventID != "" {
                heyClient.DeleteEvent(old.HeyEventID)
            }
        }
    }

    // Process each new event
    result := make([]Event, len(newEvents))
    for i, new := range newEvents {
        result[i] = new
        old, existed := oldByID[new.ID]

        wasScheduled := existed && old.Week != nil
        isScheduled := new.Week != nil
        weekChanged := wasScheduled && isScheduled && *old.Week != *new.Week

        if weekChanged {
            // Week changed: delete old, create new
            if old.HeyEventID != "" {
                heyClient.DeleteEvent(old.HeyEventID)
            }
            if isScheduled {
                monday := weekToMonday(*new.Week)
                friday := weekToFriday(*new.Week)
                heyEventID, _ := heyClient.CreateEvent(CreateEventParams{
                    Title:       new.Title,
                    StartDate:   monday,
                    EndDate:     friday,
                    Description: new.Description,
                    InviteEmail: inviteEmail,
                })
                result[i].HeyEventID = heyEventID
            }
        } else if !wasScheduled && isScheduled {
            // Newly scheduled: create HEY event
            monday := weekToMonday(*new.Week)
            friday := weekToFriday(*new.Week)
            heyEventID, _ := heyClient.CreateEvent(CreateEventParams{
                Title:       new.Title,
                StartDate:   monday,
                EndDate:     friday,
                Description: new.Description,
                InviteEmail: inviteEmail,
            })
            result[i].HeyEventID = heyEventID
        } else if wasScheduled && !isScheduled {
            // Unscheduled: delete HEY event
            if old.HeyEventID != "" {
                heyClient.DeleteEvent(old.HeyEventID)
            }
            result[i].HeyEventID = ""
        } else if wasScheduled && isScheduled {
            // Still scheduled, same week: preserve heyEventId
            result[i].HeyEventID = old.HeyEventID
        }
    }

    return result
}
```

### Week → Date Mapping

Events are created as all-day events spanning **Monday to Friday** of the assigned week.

```go
func weekToMonday(week int) time.Time {
    // Jan 1, 2026 is Thursday
    jan1 := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
    weekday := int(jan1.Weekday())
    if weekday == 0 { weekday = 7 } // Sunday = 7
    daysToMonday := weekday - 1
    week1Monday := jan1.AddDate(0, 0, -daysToMonday)
    return week1Monday.AddDate(0, 0, (week-1)*7)
}

func weekToFriday(week int) time.Time {
    return weekToMonday(week).AddDate(0, 0, 4) // Monday + 4 days = Friday
}
```

### Event Fields

When syncing to HEY Calendar:
- **Title**: Event title from frontend
- **Start Date**: Monday of assigned week
- **End Date**: Friday of assigned week (event spans full work week)
- **Description**: Event description wrapped in `<div>` tags
- **Invite Email**: Configurable via `HEY_INVITE_EMAIL` env var (optional)

### HEY Client

Import from subfolder (see `hey-library.md` for full implementation):

```go
import "calendar/hey"

// In main.go
var heyClient *hey.Client

func initHeyClient() {
    if os.Getenv("HEY_SYNC_ENABLED") == "true" {
        client, err := hey.NewClient(
            os.Getenv("HEY_EMAIL"),
            os.Getenv("HEY_PASSWORD"),
            os.Getenv("HEY_CALENDAR_ID"),
            os.Getenv("HEY_TIMEZONE"),
        )
        if err != nil {
            log.Printf("HEY client init failed: %v", err)
            return
        }
        heyClient = client
    }
}
```

Key types and methods from `hey` package:

```go
hey.Client
hey.CreateEventParams{Title, StartDate, EndDate, Description, InviteEmail}
hey.NewClient(email, password, calendarID, timezone) (*Client, error)
client.CreateEvent(params) (eventID string, err error)
client.UpdateEvent(eventID, params) error
client.DeleteEvent(eventID) error
```

---

## 3. Testing

### Local Development

```bash
# Without HEY sync
go run main.go

# With HEY sync
export HEY_EMAIL=you@hey.com
export HEY_PASSWORD=yourpass
export HEY_CALENDAR_ID=486638
export HEY_SYNC_ENABLED=true
export HEY_INVITE_EMAIL=collaborator@example.com  # optional
go run main.go
```

### API Testing

```bash
# Get current state
curl http://localhost:8080/api/state

# Save state (triggers HEY sync if enabled)
curl -X POST http://localhost:8080/api/state \
  -H "Content-Type: application/json" \
  -d '{"events2026":[{"id":"test1","title":"Test Event","week":3,"priority":"major"}]}'
```

### HEY Integration Tests

Tests are in `hey/` subfolder. See `hey-library.md` for details.

```bash
cd hey
HEY_EMAIL=you@hey.com \
HEY_PASSWORD=yourpass \
HEY_CALENDAR_ID=486638 \
go test -v
```

### Production (Fly.io)

```bash
fly secrets set HEY_EMAIL=you@hey.com
fly secrets set HEY_PASSWORD=yourpass
fly secrets set HEY_CALENDAR_ID=486638
fly secrets set HEY_SYNC_ENABLED=true
fly secrets set HEY_INVITE_EMAIL=collaborator@example.com  # optional
```

---

## 4. Implementation Status

### Completed

- [x] REST API endpoints (GET/POST `/api/state`)
- [x] Redis state persistence
- [x] Embedded `index.html` serving
- [x] HEY Calendar sync on state changes
- [x] Week → Monday date mapping
- [x] HeyEventID tracking (server-side)
- [x] Go integration tests

### Future

- [ ] Retry logic for failed syncs
- [ ] Queue failed operations for retry
- [ ] Health check endpoint
