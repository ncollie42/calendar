Analyze the spec files for dead documentation, self-containment, and verbosity issues.

## Core Philosophy: Claude-to-Claude Communication

The spec is read by future Claude during implementation. Optimize for:
- **Density**: Maximum information per token (context is precious)
- **Punchiness**: Crisp, direct statements - Claude doesn't need hand-holding
- **Signal over noise**: Only include what changes behavior
- **Precision over verbosity**: Unambiguous > lengthy explanations

Claude understands programming. Don't explain HOW to code - explain WHAT behavior to produce and WHEN something is non-obvious.

Example transformation:
```
BEFORE (verbose):
"The token generation function must use a cryptographically secure
random number generator. This is important because Math.random()
uses a pseudo-random number generator that can be predicted..."

AFTER (punchy):
"Token: 22-char base62 via CSPRNG (never Math.random - predictable)"
```

## Functional Equivalence Rule

**Before ANY removal, ask:**
> "If Claude implements from the trimmed spec, will it produce the same behavior?"

If uncertain, default to keeping. Removing functionality is worse than verbosity.

## Specs to Analyze

- `specs/frontend.md` - Frontend design specification
- `specs/backend.md` - Backend server specification
- `specs/requirements.md` - User stories and acceptance criteria
- `specs/constants.md` - Design tokens
- `specs/data-model.md` - Database schema
- `specs/manifest.md` - File structure and build order

## Audit Checks

### Dead Documentation
- Files/artifacts mentioned but never used
- Embedded code that duplicates actual implementation files
- Stale status/checklist sections ("Implementation Status", TODO lists)
- "Lessons Learned" debugging history

### Duplication
- Same content across multiple specs
- Could be replaced with cross-reference

### Over-Specification
- Code blocks where prose would suffice
- Obvious implementation details any developer knows
- Verbose explanations that could be 2 lines

### Self-Containment Gaps
- Missing context needed to implement
- Unclear API contracts
- Missing cross-references

---

## Output Format: Categorized by Confidence

Present findings in these categories:

### Safe Removals (high confidence)
Issues that can definitely be removed:
- Implementation debugging history
- Stale status/checklist sections
- Duplicate content that exists verbatim elsewhere

### Code → Prose Candidates (review carefully)
Code blocks that could become prose. For each:
- Show the current code block
- Show proposed prose replacement
- Highlight any gotchas that must be preserved

### Potential Duplication (needs cross-ref)
Content duplicated across specs:
- Note both locations
- Suggest which file should be canonical
- Propose cross-reference text

### Keep (precision required)
Explicitly call out what should NOT be touched:
- Exact values (magic numbers, signatures, patterns)
- Mathematical formulas
- Security-critical specifications where prose is risky
- Regex patterns, API formats, tricky algorithms

### Gotcha Decisions Needed
Code blocks encoding non-obvious behavior. For each, present options:
- **Inline callout**: Add `**Note:**` with the gotcha in prose
- **Dedicated section**: Gotcha complex enough for its own heading
- **Keep code**: The gotcha is best expressed in code form
- **Create skill**: Complex enough to warrant a skill file

---

## Clean Bill of Health

When specs are genuinely in good shape, say so. This is a valid outcome, not a cop-out.

**Criteria for clean bill:**
- No dead documentation (stale status, debugging history)
- No obvious duplication across specs
- Code blocks serve a purpose (exact values, gotchas, complex algorithms)
- Prose is already punchy and dense

**Clean bill format:**
```
## Audit Result: Clean Bill of Health

Specs are in good shape. No actionable cleanup found.

**What I checked:**
- [Brief list of what was scanned]

**Why no issues:** [1-2 sentences on why specs pass muster]
```

Don't invent issues to seem thorough. If it's clean, it's clean.

---

## Top 3 Recommendations

When findings exist, lead with the highest-impact issues before the full categorized list.

**Prioritize by:**
1. Functional risk (could cause incorrect implementation)
2. Context waste (tokens spent on noise)
3. Maintenance burden (likely to become stale)

**Format:**
```
## Top 3 Recommendations

1. **[Category]**: [Specific issue] — [Why it matters most]
2. **[Category]**: [Specific issue] — [Impact]
3. **[Category]**: [Specific issue] — [Impact]

---
[Full categorized findings below]
```

---

## Interaction Model

### When Specs Are Clean
Present clean bill of health and stop. No need to prompt for actions.

### When Findings Exist
Lead with Top 3 Recommendations, then full categorized list:

```
---
Pick a number to address (1-N), or:
- 'skip' to move on without changes
- 'verify' to test regeneration capability of a section
```

### When User Picks a Number

1. Show the current content in full
2. Show the proposed change (removal, prose replacement, or cross-ref)
3. For gotchas: present handling options and ask user to choose
4. Ask for confirmation before applying
5. Apply the change if confirmed
6. Re-run audit to show remaining issues

### Gotcha Handling Decision

When a code block contains gotchas, ask:
> "This code embeds important gotchas. How should we preserve them?"
> 1. Inline callout (add **Note:** in prose)
> 2. Keep code as-is (gotcha best expressed in code)
> 3. Create skill (complex enough for dedicated skill file)
> 4. Dedicated section (deserves its own heading)

---

## Punchiness Checklist

For each piece of content, ask:
- Does this add info Claude wouldn't already know?
- Can this be said in fewer words without losing precision?
- Is this explaining HOW to code (cut) or WHAT behavior (keep)?

---

## Rules

1. **Present findings first** - Never auto-fix
2. **One issue at a time** - User picks, we address, loop
3. **Preserve gotchas** - Non-obvious behavior must survive cleanup
4. **Confirm before applying** - Show before/after, get explicit approval
5. **Re-audit after changes** - Show updated issue list
