# Spec-Driven Workflow

Quick reference for the development loop.

## Full Rebuild

```bash
bash scripts/reset-workspace.sh    # wipe code, keep specs + configs + fonts
/implement                         # specs → code → install → codegen → build → test
```

## Development Loop

```
┌─────────────────────────────────────────────────┐
│  BUILD                                          │
│  /implement                                     │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  USE THE APP — find bugs, want changes          │
└──────────┬───────────────────────┬──────────────┘
           │                       │
     bug / gotcha            new feature
           │                       │
           ▼                       ▼
┌──────────────────┐   ┌─────────────────────────┐
│  fix the code    │   │  /workshop <feature>     │
│  then:           │   │  (explores, asks Qs,     │
│                  │   │   drafts spec update)    │
│  /spec_update    │   │                          │
│  <what broke>    │   │  apply the spec update   │
│                  │   │  then fix code or:       │
│                  │   │  /implement              │
└──────────┬───────┘   └────────────┬─────────────┘
           │                        │
           └───────────┬────────────┘
                       │
                       ▼
                    repeat
```

## Commands

| When | Command | What it does |
|---|---|---|
| Build from specs | `/implement` | Reads all specs, writes code, installs, builds, tests |
| Fixed a bug | `/spec_update <description>` | Extracts the invariant, adds to right spec file |
| New feature | `/workshop <feature>` | Explores ambiguity, asks questions, drafts spec text |
| Periodic hygiene | `/spec_cleanup` | Audits specs for drift, code blocks, duplication |
| Stress-test an idea | `/askHard <topic>` | Challenges your thinking before you commit |
| Explore a problem | `/unknown <problem>` | Expert-level research on unknown unknowns |

## When to Rebuild vs Fix

- **Targeted fix**: Most of the time. Fix code → `/spec_update` → move on.
- **Full rebuild**: When specs have drifted far, or to verify spec completeness.

## Spec Files

| File | What belongs |
|------|-------------|
| `requirements.md` | What and why — user stories, acceptance criteria |
| `constants.md` | Values only — colors, geometry, timing, CSS variable mapping |
| `data-model.md` | Data shape — schema, access control, security invariants |
| `frontend.md` | Observable behavior — interactions, states, layout rules |
| `backend.md` | Architecture — server, deployment, testing, gotchas |

## Rules

1. **Invariants, not fixes** — spec says "hitbox must not resize on hover", not the CSS
2. **No code blocks in specs** — prose only, Claude derives the implementation
3. **Each fact once** — canonical location per scope, no duplication
4. **Verifiable from behavior** — testable by using the app, not reading source
