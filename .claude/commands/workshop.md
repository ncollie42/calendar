Let's workshop this spec addition: $ARGUMENTS

## Your Job

Help me think through this feature/change before it goes into the spec. Spot ambiguity, missing edge cases, and unclear behavior — then draft a spec update that's tight enough for Claude to implement without follow-up questions.

## Process

1. **Read the relevant spec(s)** to understand existing patterns and conventions
2. **Ask clarifying questions** about the unclear areas you've identified — use AskUserQuestion
3. **Point out** ambiguities, missing edge cases, conflicting behavior with existing features
4. **Draft the spec update** once we've discussed

## Available Specs

- `specs/requirements.md` — User stories, acceptance criteria (what/why)
- `specs/constants.md` — Design tokens: colors, geometry, timing (values only)
- `specs/data-model.md` — Schema, access control, security invariants (data shape)
- `specs/frontend.md` — UI behavior, interactions, layout, states (observable behavior)
- `specs/backend.md` — Server, deployment, testing, infra (architecture/gotchas)

## Spec Update Rules (from CLAUDE.md)

When drafting the update, enforce these:

1. **Invariants, not fixes** — Describe what must be true, not how to make it true
2. **No code blocks** — Algorithms and patterns in prose. Claude derives the implementation.
3. **Each fact once** — Put it in the right file per scope. Don't duplicate across specs.
4. **Verifiable from behavior** — Every line should be testable by using the app, not reading source
5. **Match the file's scope** — Each spec has a scope preamble declaring what belongs

## Quality Checks for the Draft

Before presenting the final update, verify:
- [ ] No code blocks (CSS, TypeScript, HTML, etc.)
- [ ] Placed in the correct spec file per scope boundaries
- [ ] Doesn't duplicate information already in another spec
- [ ] Describes observable behavior or invariants, not implementation
- [ ] Edge cases are covered (what happens when X fails? when Y is empty?)
- [ ] Consistent with existing spec conventions (table format, section structure)

## Output

Present the draft update as:
1. **Which file** and **which section** it goes in
2. **The update** (ready to paste)
3. **What it replaces** (if modifying existing content) or **where it inserts** (if new)
