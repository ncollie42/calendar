Audit spec files against their declared scope and the spec update rules in CLAUDE.md.

## Core Philosophy

Specs describe **observable behavior and invariants**. Implementation is derived by Claude at build time. If a spec line can only be verified by reading source code (not by using the app), it's implementation detail and should be removed.

## Specs to Audit

Each file declares its scope in a preamble. Content must match:

| File | Scope |
|------|-------|
| `specs/requirements.md` | What and why — never how |
| `specs/constants.md` | Values only — no behavior, no code |
| `specs/data-model.md` | Data shape and rules — no implementation |
| `specs/frontend.md` | Observable behavior — no CSS/framework code |
| `specs/backend.md` | Architecture and gotchas — no inline code |

## Audit Checks

### 1. Code Block Violations (highest priority)
Specs must not contain code blocks. For each one found:
- Extract the behavioral invariant or gotcha it encodes
- Propose a prose replacement
- Flag any non-obvious knowledge that must survive

### 2. Scope Violations
Content that belongs in a different spec file:
- Data concerns in frontend.md → should be in data-model.md
- Visual behavior in constants.md → should be in frontend.md
- Schema details in backend.md → should be in data-model.md

### 3. Duplication
Same fact stated in multiple files. For each:
- Identify the canonical location (using the scope table above)
- Flag the duplicate for removal

### 4. Implementation Leakage
Signs that bug fixes were captured as code rather than invariants:
- CSS snippets
- Framework-specific patterns (React hooks, memo, etc.)
- Specific API calls or library usage

### 5. Self-Containment Gaps
Missing information that would cause Claude to guess during rebuild:
- Undefined behavior for edge cases
- Ambiguous state transitions
- Missing invariants for tricky interactions

## Functional Equivalence Rule

**Before ANY removal, ask:**
> "If Claude implements from the trimmed spec, will it produce the same behavior?"

If uncertain, keep it. Removing functionality is worse than verbosity.

---

## Output Format

### Top 3 Issues

Lead with the highest-impact findings:

1. **[Check type]**: [Specific issue] — [Why it matters]
2. **[Check type]**: [Specific issue] — [Impact]
3. **[Check type]**: [Specific issue] — [Impact]

### Full Findings

Group by check type. For each finding:
- **Location**: file + line range
- **Problem**: what violates the rules
- **Proposed fix**: the replacement (or removal)

### Clean Bill of Health

When specs pass all checks, say so. Don't invent issues.

---

## Interaction Model

1. Present findings (never auto-fix)
2. User picks a number to address
3. Show current content → proposed change
4. Confirm before applying
5. Re-audit after changes

---

## Punchiness Checklist

For each piece of content:
- Does this add info Claude wouldn't already know?
- Can this be said in fewer words without losing precision?
- Is this describing WHAT behavior to produce (keep) or HOW to code it (cut)?
- Is this verifiable from using the app (keep) or only from reading source (cut)?
