# HEY Calendar Library Specification

A self-contained Go package for programmatic access to HEY Calendar via their internal web API.

**Status**: Experimental - reverse-engineered API, not public, may break.

---

## 1. Overview

### Package Structure

```
calendar/
├── main.go              # imports "calendar/hey"
├── hey/
│   ├── client.go        # Client struct, NewClient, auth
│   ├── events.go        # CreateEvent, UpdateEvent, DeleteEvent, extractEventID
│   └── client_test.go   # Integration tests
```

### Package Declaration

```go
package hey

import (
    "fmt"
    "io"
    "net/http"
    "net/http/cookiejar"
    "net/url"
    "regexp"
    "strings"
    "sync"
    "time"
)
```

### Features
- Authentication with bot detection bypass
- Create, update, delete calendar events
- Extract event IDs from calendar pages
- Automatic session refresh on expiry

### Usage

```go
import "calendar/hey"

client, err := hey.NewClient(email, password, calendarID, timezone)
if err != nil {
    log.Fatal(err)
}

// Create event (spans Monday-Friday, with description and invite)
eventID, err := client.CreateEvent(CreateEventParams{
    Title:       "Meeting",
    StartDate:   time.Date(2026, 1, 19, 0, 0, 0, 0, time.UTC), // Monday
    EndDate:     time.Date(2026, 1, 23, 0, 0, 0, 0, time.UTC), // Friday
    Description: "Notes go here",
    InviteEmail: "leon9guada@gmail.com",  // Guadalupe - always invited
})

// Update event
err = client.UpdateEvent(eventID, UpdateEventParams{...})

// Delete event
err = client.DeleteEvent(eventID)
```

---

## 2. Authentication

### Overview

HEY uses session-based authentication with CSRF tokens. Bot detection requires browser fingerprint headers.

### Step 1: Get Sign-In Page

```
GET https://app.hey.com/sign_in
```

Extract `authenticity_token` from HTML:
```html
<input name="authenticity_token" value="TOKEN_HERE">
```

**Regex**:
```go
re := regexp.MustCompile(`name="authenticity_token"\s+value="([^"]+)"`)
```

### Step 2: Submit Login

```
POST https://app.hey.com/sign_in
Content-Type: application/x-www-form-urlencoded
```

**Required Headers** (ALL required for bot detection bypass):

| Header | Value |
|--------|-------|
| `User-Agent` | `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36` |
| `Accept` | `text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8` |
| `Accept-Language` | `en-US,en;q=0.9` |
| `Content-Type` | `application/x-www-form-urlencoded` |
| `Origin` | `https://app.hey.com` |
| `Referer` | `https://app.hey.com/sign_in` |
| `sec-ch-ua` | `"Google Chrome";v="120", "Chromium";v="120", "Not A(Brand";v="24"` |
| `sec-ch-ua-mobile` | `?0` |
| `sec-ch-ua-platform` | `"macOS"` |
| `sec-fetch-dest` | `document` |
| `sec-fetch-mode` | `navigate` |
| `sec-fetch-site` | `same-origin` |
| `sec-fetch-user` | `?1` |
| `upgrade-insecure-requests` | `1` |

**CRITICAL**: Without `sec-ch-ua` and `sec-fetch-*` headers, login returns HTTP 302 but NO `session_token` cookie.

**Form Data**:

| Field | Value |
|-------|-------|
| `authenticity_token` | Token from Step 1 |
| `email_address` | HEY email |
| `password` | HEY password |
| `commit` | `Sign in` |

**Success**: HTTP 302 with `session_token` in `Set-Cookie` header.

**Failure**:
- HTTP 302 but NO `session_token` → bot detection triggered
- HTTP 200 → invalid credentials (page re-rendered)

### Step 3: Get CSRF Token

Fetch `/calendar` and extract from meta tag:
```html
<meta name="csrf-token" content="TOKEN_HERE">
```

**Regex**:
```go
re := regexp.MustCompile(`name="csrf-token"\s+content="([^"]+)"`)
```

### Cookie Handling

When using `CheckRedirect: http.ErrUseLastResponse`, manually extract cookies:

```go
for _, cookie := range resp.Cookies() {
    client.Jar.SetCookies(url, []*http.Cookie{cookie})
}
```

### Redirect URL Handling

HEY returns **absolute URLs** in `Location` headers (e.g., `https://app.hey.com/calendar/weeks/2026-01-19`), not relative paths. When following redirects manually, check before prepending `baseURL`:

```go
location := resp.Header.Get("Location")
var redirectURL string
if strings.HasPrefix(location, "http") {
    redirectURL = location  // Already absolute
} else {
    redirectURL = baseURL + location  // Relative path
}
```

**CRITICAL**: Blindly concatenating `baseURL + location` produces malformed URLs like `https://app.hey.comhttps://app.hey.com/...`.

---

## 3. Create Event

```
POST https://app.hey.com/calendar/events
Content-Type: application/x-www-form-urlencoded
```

### Required Headers

| Header | Value |
|--------|-------|
| `Accept` | `text/vnd.turbo-stream.html, text/html, application/xhtml+xml` |
| `Accept-Language` | `en-US,en;q=0.9` |
| `Content-Type` | `application/x-www-form-urlencoded` |
| `Origin` | `https://app.hey.com` |
| `Referer` | `https://app.hey.com/calendar/weeks/{date}` |
| `x-csrf-token` | CSRF token |
| `x-turbo-request-id` | Unique ID (timestamp) |
| `sec-fetch-dest` | `empty` |
| `sec-fetch-mode` | `cors` |
| `sec-fetch-site` | `same-origin` |

**CRITICAL**: The `sec-fetch-*` and `x-turbo-request-id` headers are required. Without them, you get full HTML instead of success, and the event may not be created.

### Form Data

| Field | Example | Notes |
|-------|---------|-------|
| `calendar_event[calendar_id]` | `486638` | |
| `calendar_event[summary]` | `My Event` | Event title |
| `calendar_event[starts_at]` | `2026-01-19` | Start date (Monday) |
| `calendar_event[starts_at_time]` | `0:00:00` | Use `0:00:00` for all-day |
| `calendar_event[starts_at_time_zone_name]` | `Pacific Time (US & Canada)` | |
| `calendar_event[ends_at]` | `2026-01-23` | End date (Friday for week span) |
| `calendar_event[ends_at_time]` | `0:00:00` | Use `0:00:00` for all-day |
| `calendar_event[ends_at_time_zone_name]` | `Pacific Time (US & Canada)` | |
| `calendar_event[all_day]` | `1` | `1` for all-day events |
| `calendar_event[description]` | `<div>Notes here</div>` | HTML content for notes |
| `calendar_event[attendance_email_addresses][]` | `user@example.com` | Configured via `HEY_INVITE_EMAIL` |
| `commit` | `Add this event` | |

**Invite Recipient**: Configured via `HEY_INVITE_EMAIL` env var. When set, all events will send calendar invites to this address.

**Single-day vs Multi-day Events**:

| Type | starts_at | ends_at | Extraction |
|------|-----------|---------|------------|
| Single-day | `2026-01-19` | `2026-01-19` (same) | More reliable |
| Multi-day | `2026-01-19` (Mon) | `2026-01-23` (Fri) | May have different HTML structure |

**Recommendation**: Use **single-day events** for more reliable ID extraction. Multi-day events may render differently in the calendar HTML, causing extraction strategies to fail.

```go
// Single-day (recommended for reliable extraction)
formData.Set("calendar_event[starts_at]", "2026-01-19")
formData.Set("calendar_event[starts_at_time]", "9:00:00")
formData.Set("calendar_event[ends_at]", "2026-01-19")      // Same date
formData.Set("calendar_event[ends_at_time]", "10:00:00")

// Multi-day (may cause extraction issues)
formData.Set("calendar_event[starts_at]", "2026-01-19")    // Monday
formData.Set("calendar_event[starts_at_time]", "0:00:00")
formData.Set("calendar_event[ends_at]", "2026-01-23")      // Friday
formData.Set("calendar_event[ends_at_time]", "0:00:00")
```

**Invites**: The `attendance_email_addresses[]` field sends a calendar invite to the specified email. Can include multiple by repeating the field.

### Response

**Success**: HTTP 302 redirect to `/calendar/weeks/{date}`

**Failure**:
- HTTP 302 to `/sign_in` → session expired
- HTTP 422 → validation error

### Event ID

The create endpoint does NOT return the event ID. You must extract it afterward (see Section 6).

---

## 4. Update Event

```
POST https://app.hey.com/calendar/events/{event_id}
Content-Type: application/x-www-form-urlencoded;charset=UTF-8
```

Uses Rails method override (`_method=patch`).

### Headers

Same as Create (including `sec-fetch-*` and `x-turbo-request-id`).

### Form Data

Same as Create, plus:

| Field | Value |
|-------|-------|
| `_method` | `patch` |
| `commit` | `Update` |

### Response

**Success**: HTTP 302 redirect to calendar page, or HTTP 200.

**Failure**: HTTP 302 to `/sign_in`, HTTP 404.

---

## 5. Delete Event

```
POST https://app.hey.com/calendar/events/{event_id}?_method=delete
Content-Type: application/x-www-form-urlencoded;charset=UTF-8
```

Uses Rails method override (`_method=delete`).

### Headers

Same as Create (including `sec-fetch-*` and `x-turbo-request-id`).

### Form Data

| Field | Value |
|-------|-------|
| `_method` | `delete` |

### Response

**Success**: HTTP 302 redirect to calendar page, or HTTP 200.

**Failure**: HTTP 302 to `/sign_in`, HTTP 404.

---

## 6. Extract Event ID

After creating an event, fetch the calendar page to get the HEY event ID.

```
GET https://app.hey.com/calendar/weeks/{date}
```

**Date format**: Use `YYYY-MM-DD` (e.g., `2026-01-19`). HEY will show the week containing that date.

**Note**: Use `/calendar/weeks/{date}` not `/calendar/days`.

### Redirect-Following Client

The calendar page may redirect. Use a **separate HTTP client** that follows redirects (unlike the main client which blocks redirects for cookie capture):

```go
client := &http.Client{
    Jar:     hc.client.Jar,  // Share cookies with main client
    Timeout: 30 * time.Second,
    // No CheckRedirect - allows following redirects
}
```

### HTML Structure

```html
<a data-identifier="141217979" href="/calendar/events/141217979/edit">
   <span class="event__title">Event Title</span>
</a>
```

**Note**: Title is in `<span class="event__title">`, NOT `event__summary`.

### Extraction Strategies

Use multiple fallback strategies since HTML structure may vary:

```go
// Strategy 1: Position matching (primary)
// Find all data-identifier values and event titles, match by position
reIdentifier := regexp.MustCompile(`data-identifier="(\d+)"`)
identifiers := reIdentifier.FindAllStringSubmatch(html, -1)

reTitles := regexp.MustCompile(`class="[^"]*event__title[^"]*"[^>]*>\s*([^<]+?)\s*<`)
titles := reTitles.FindAllStringSubmatch(html, -1)

for i, t := range titles {
    if strings.TrimSpace(t[1]) == targetTitle && i < len(identifiers) {
        return identifiers[i][1], nil
    }
}

// Strategy 2: Anchor tag content matching
// Find <a> tags with data-identifier that contain our title
reEventBlock := regexp.MustCompile(`<a[^>]*data-identifier="(\d+)"[^>]*>([\s\S]*?)</a>`)
eventBlocks := reEventBlock.FindAllStringSubmatch(html, -1)

for _, block := range eventBlocks {
    eventID := block[1]
    blockContent := block[2]
    if strings.Contains(blockContent, targetTitle) {
        return eventID, nil
    }
}

// Strategy 3: Proximity search (last resort)
// Find title anywhere, search backwards for nearest data-identifier
titleIndex := strings.Index(html, targetTitle)
if titleIndex > 0 {
    before := html[:titleIndex]
    matches := reIdentifier.FindAllStringSubmatch(before, -1)
    if len(matches) > 0 {
        return matches[len(matches)-1][1], nil  // Return nearest
    }
}

return "", fmt.Errorf("could not find event with title %q", targetTitle)
```

### Graceful Failure

ID extraction may fail even when the event was created successfully. Treat this as **non-fatal**:

```go
eventID, err := hc.extractEventID(dateStr, title)
if err != nil {
    log.Printf("Warning: event created but could not extract ID: %v", err)
    return "", nil  // Return empty ID, not an error
}
```

**Rationale**: The event exists in HEY Calendar; we just couldn't get its ID. The caller can still function without it (e.g., won't be able to update/delete, but sync continues).

---

## 7. Implementation

### Client Structure

```go
type Client struct {
    email      string
    password   string
    calendarID string
    timezone   string
    client     *http.Client  // with cookie jar
    csrfToken  string
    mu         sync.Mutex    // protect concurrent access
}

const userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

type CreateEventParams struct {
    Title       string
    StartDate   time.Time   // Monday of the week
    EndDate     time.Time   // Friday of the week (for week-spanning events)
    Description string      // HTML content, wrapped in <div>
    InviteEmail string      // Email address to send invite to
}
```

### Constructor

```go
func NewClient(email, password, calendarID, timezone string) (*Client, error) {
    jar, _ := cookiejar.New(nil)

    httpClient := &http.Client{
        Jar:     jar,
        Timeout: 30 * time.Second,
        CheckRedirect: func(req *http.Request, via []*http.Request) error {
            return http.ErrUseLastResponse  // Don't follow redirects
        },
    }

    c := &Client{
        email:      email,
        password:   password,
        calendarID: calendarID,
        timezone:   timezone,
        client:     httpClient,
    }

    if err := c.authenticate(); err != nil {
        return nil, err
    }

    return c, nil
}
```

### Gotchas & Key Learnings

1. **Bot detection**: Login returns 302 but NO `session_token` cookie without the full `sec-ch-ua` and `sec-fetch-*` headers
2. **Cookie extraction**: When using `CheckRedirect: http.ErrUseLastResponse`, you must manually call `jar.SetCookies()` with `resp.Cookies()`
3. **Turbo headers required**: Create/Update/Delete fail silently without `x-turbo-request-id` and `sec-fetch-dest: empty`
4. **Event ID not returned**: Create endpoint doesn't return ID - must extract from `/calendar/weeks/{date}` HTML afterward
5. **Wrong endpoint**: Use `/calendar/weeks/{date}` NOT `/calendar/days/{date}` for event extraction
6. **Wrong CSS class**: Event titles are in `event__title` NOT `event__summary`
7. **Success = 302**: Both 200 and 302 can mean success; check if 302 Location contains `sign_in` (failure) vs calendar path (success)
8. **Time format**: Use `0:00:00` (not `00:00:00`) for all-day events
9. **Absolute redirect URLs**: `Location` headers contain full URLs (e.g., `https://app.hey.com/...`), not relative paths - check before prepending `baseURL`
10. **Single-day events more reliable**: Multi-day events (Mon-Fri spans) may render differently in calendar HTML, causing ID extraction to fail. Use single-day events for reliable extraction.
11. **Redirect-following for calendar fetch**: Use a separate `http.Client` without `CheckRedirect` override when fetching calendar pages, to properly follow redirects while preserving cookies.
12. **ID extraction is non-fatal**: Treat extraction failures as warnings, not errors. The event exists; we just can't track its ID for updates/deletes.

### Session Management

- Authenticate on startup
- Re-authenticate automatically on 401/403 or redirect to `/sign_in`
- Never log credentials or session tokens
- Use mutex for thread safety

### Error Handling

Check redirect location to distinguish success from auth failure:

```go
if resp.StatusCode == 302 {
    location := resp.Header.Get("Location")
    if strings.Contains(location, "sign_in") {
        // Session expired - re-authenticate and retry
        c.authenticate()
        return c.RetryOperation()
    }
    // 302 to calendar page = success
    return nil
}
```

---

## 8. Testing

### Test File (`hey/client_test.go`)

```go
package hey

import (
    "fmt"
    "os"
    "testing"
    "time"
)

func TestHeyAPI(t *testing.T) {
    email := os.Getenv("HEY_EMAIL")
    password := os.Getenv("HEY_PASSWORD")
    calendarID := os.Getenv("HEY_CALENDAR_ID")

    if email == "" || password == "" || calendarID == "" {
        t.Skip("HEY credentials not set")
    }

    var client *Client
    var eventID string
    testTitle := fmt.Sprintf("Test_%d", time.Now().Unix())
    testDate := time.Now().AddDate(0, 0, 7)

    t.Run("1_Login", func(t *testing.T) {
        var err error
        client, err = NewClient(email, password, calendarID, "Pacific Time (US & Canada)")
        if err != nil {
            t.Fatalf("Login failed: %v", err)
        }
    })

    t.Run("2_CreateEvent", func(t *testing.T) {
        var err error
        eventID, err = client.CreateEvent(CreateEventParams{
            Title:     testTitle,
            StartDate: testDate,
            EndDate:   testDate.AddDate(0, 0, 4), // Mon-Fri
        })
        if err != nil {
            t.Fatalf("CreateEvent failed: %v", err)
        }
    })

    t.Run("3_UpdateEvent", func(t *testing.T) {
        err := client.UpdateEvent(eventID, CreateEventParams{
            Title:     testTitle + "_Updated",
            StartDate: testDate,
            EndDate:   testDate.AddDate(0, 0, 4),
        })
        if err != nil {
            t.Fatalf("UpdateEvent failed: %v", err)
        }
    })

    t.Run("4_DeleteEvent", func(t *testing.T) {
        err := client.DeleteEvent(eventID)
        if err != nil {
            t.Fatalf("DeleteEvent failed: %v", err)
        }
    })
}
```

### Run Tests

```bash
cd hey
HEY_EMAIL=you@hey.com \
HEY_PASSWORD=yourpass \
HEY_CALENDAR_ID=486638 \
go test -v
```

---

## 9. Risks & Limitations

| Risk | Mitigation |
|------|------------|
| HEY changes API | Monitor for failures, update as needed |
| Session expires | Re-authenticate on 401/403 |
| Rate limiting | Add delays between requests |
| 2FA added | Would break this approach |
| ToS violation | Use at your own risk |
