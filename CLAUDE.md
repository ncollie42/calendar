# Claude Code Instructions

## Spec-Driven Development

This repository treats **specs as source code** and **implementation as a compiled artifact**.

### The Philosophy

The specs in `specs/` are the source of truth—not the code. Code can be deleted and regenerated from specs. If the spec is complete and unambiguous, Claude should be able to rebuild the entire codebase from scratch.

This inverts the typical relationship:
- **Traditional**: Code is source, docs describe code
- **This repo**: Specs are source, code implements specs

### Why This Matters

1. **Specs must be complete** — If Claude can't rebuild a feature, the spec is incomplete
2. **Code is disposable** — Don't preserve code for its own sake; preserve knowledge in specs
3. **Iterate on specs** — When exploring a feature, code first, then extract learnings back to spec
4. **Determinism** — Precise specs produce consistent implementations across rebuilds

### Workflow

**Adding a new feature:**
1. `/workshop <feature>` — explore ambiguity, draft spec update
2. Apply the spec update
3. `/implement` — build from specs

**Fixed a bug or learned something:**
1. `/spec_update <what changed>` — extract invariant, add to spec

**Iterating on existing features:**
1. Make changes in code to explore/prototype
2. `/spec_update` — extract learnings back to spec
3. Spec becomes the permanent record

**Periodic maintenance:**
1. `/spec_cleanup` — audit specs for drift, redundancy, code blocks

**Full rebuild:**
1. Delete implementation code (keep specs)
2. `/implement` — regenerate from specs
3. Verify behavior matches expectations
4. If gaps found, `/spec_update` to fix specs

### Spec Files

| File | Purpose | Scope boundary |
|------|---------|----------------|
| `specs/requirements.md` | User stories, acceptance criteria, NFRs | What and why — never how |
| `specs/constants.md` | Design tokens (colors, geometry, timing) | Values only — no behavior, no code |
| `specs/data-model.md` | Schema, access control, security invariants | Data shape and rules — no implementation |
| `specs/frontend.md` | UI behavior, interactions, layout, states | Observable behavior — no CSS/framework code |
| `specs/backend.md` | Server, deployment, testing, infra | Architecture and gotchas — no inline code |

**Hierarchy:**
- `requirements.md` defines **what** and **why**
- `constants.md` and `data-model.md` define **shared foundations**
- `frontend.md` and `backend.md` define **how** (behavior)

### Implementation Files

| Path | Purpose |
|------|---------|
| `src/` | React TypeScript source |
| `src/components/` | React components |
| `src/hooks/` | Custom hooks |
| `src/lib/` | Utilities (constants, geometry, weeks) |
| `public/` | Static files (index.html, manifest.json, sw.js) |
| `convex/` | Convex schema and functions |
| `server.ts` | Bun.serve() dev/prod server |
| `build.ts` | Production build script |

### When Implementing

- **Use token names from `constants.md`** — Not hardcoded values
- **Match `data-model.md` exactly** — Schema is authoritative
- **Reference `frontend.md` for behavior** — Not just what it looks like, but how it works
- **Derive file structure from specs** — Don't ask for a file list; read the behavior and decide what files make sense

### What Belongs in a Spec

Specs contain two kinds of knowledge. Implementation details belong in neither.

| Tier | Verifiable by | Lives in |
|------|--------------|----------|
| **Observable behavior** | Using the app | `requirements.md`, domain specs |
| **Design constraints** | Understanding the architecture | `frontend.md`, `backend.md` |
| **Implementation details** | Reading source code | Nowhere — derives from the above |

**Observable behavior**: What a user can see or do. "Past weeks render at reduced opacity." "Tooltip appears on hover." If the app worked differently, a user would notice.

**Design constraints**: Architectural decisions that aren't visible to users but constrain implementation in important ways. "One tooltip overlay instance serves all week nodes." "Static radial geometry never re-renders on data updates." Removing these would cause Claude to make a different (valid but wrong) architectural choice.

**Implementation details**: Names specific code constructs — CSS properties, React APIs, library calls. "Use `transform` and `opacity`." "Pass `hoveredWeek` as a prop." These derive naturally from the above two tiers and don't need to be specified.

**Three tests for any spec line:**
1. **App test** — Can you verify this by using the app? If yes, it's observable behavior. Keep it.
2. **Info test** — Would removing this cause Claude to make a different architectural choice? If yes, it's a design constraint. Keep it in the right file.
3. **Home test** — Is this in the right file? Design constraints belong in `frontend.md`/`backend.md`, not `requirements.md`. The right answer is sometimes "move it", not "cut it."

If a line fails all three tests, cut it.

### Spec Update Rules

When updating specs after bug fixes or iteration:

1. **Add invariants, not fixes** — "Hitbox dimensions must not change during hover" not the CSS that fixes it
2. **No code blocks** — Describe algorithms and patterns in prose. Claude derives the implementation.
3. **Each fact once** — If it's about data, it's in data-model.md. Don't repeat across files.
4. **Verifiable from behavior** — Every spec line should be testable by using the app, not reading source
5. **Use `/spec_cleanup` periodically** — Catches drift, redundancy, and implementation leaking into specs

---

## Local Development

```bash
bun install      # Install dependencies
bunx convex dev  # Terminal 1 (Convex backend)
bun run dev      # Terminal 2 (Bun dev server)
# Open http://localhost:3000
```

### Environment

- `.env.local` — Convex deployment config (auto-generated by `bunx convex dev`)

---

## Coding Practices

### Defensive Programming

Assert aggressively. If an assumption could be wrong, assert it—inputs non-nil, values in range, invariants hold.

The goal: if your mental model is wrong, crash immediately at the violation, not later with corrupted state. When something crashes, add assertions that would have caught it earlier. The assertions are the spec.

