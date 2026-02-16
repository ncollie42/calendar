Capture what we just learned into the spec: $ARGUMENTS

## Purpose

After fixing a bug, iterating on behavior, or discovering a gotcha — extract the lesson and add it to the spec as a behavioral invariant. This prevents the same issue from recurring on rebuild.

## Process

1. **Understand what changed** — Read the recent conversation, code changes, or git diff to identify what was fixed or learned
2. **Extract the invariant** — Ask: "What rule was violated that caused this bug?" The answer is what goes in the spec.
3. **Find the right file** — Match the invariant to a spec file's declared scope:

| If it's about... | It goes in... |
|---|---|
| What users should experience | `specs/requirements.md` |
| A design token value | `specs/constants.md` |
| Schema, access control, data rules | `specs/data-model.md` |
| UI behavior, interactions, states | `specs/frontend.md` |
| Server, deployment, infra gotchas | `specs/backend.md` |

4. **Draft the update** — Write it as behavioral prose
5. **Present for approval** — Show what's being added and where

## Translation Guide

Turn fixes into invariants:

| What you fixed | What goes in the spec |
|---|---|
| Added `pointer-events: none` to inner SVG rect | "Visual element must not intercept pointer events — hitbox only" |
| Wrapped state update in `useRef` check | "View transitions must distinguish UI-initiated vs browser-back to avoid double history entries" |
| Added `if (already) return` guard | "Repeated toggle actions must be no-ops — never stack history entries" |
| Changed `bunx tailwindcss` to explicit path | "Tailwind CLI must use explicit binary path — bunx fails silently" |

The pattern: **describe the constraint, not the implementation**.

## Quality Checks

Before applying:
- [ ] Written as an invariant or behavioral rule (not a code fix)
- [ ] No code blocks
- [ ] Placed in the correct spec file per scope
- [ ] Doesn't duplicate something already stated
- [ ] Future Claude could verify this by testing the app, not reading source

## Output

1. **The invariant** (one or two sentences)
2. **Which file** and **which section**
3. **The exact text to add** (ready to insert)
4. Ask for confirmation, then apply
