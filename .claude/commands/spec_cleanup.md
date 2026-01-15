Analyze the spec files for dead documentation, self-containment, and verbosity issues.

## Spec philosophy

Specs should **convey meaning**, not dictate implementation verbatim.

- **Prefer intent over code** - Describe what something should do, not line-by-line how
- **Code only when precision matters** - Regex patterns, exact API formats, tricky algorithms
- **Trust the implementer** - They know how to write a for-loop; tell them what to iterate over
- **Sharp instructions for sharp edges** - Be explicit only where ambiguity would cause bugs

A good spec is a **well-defined PRD** that's precise and complete, but not bloated. Every section should earn its place.

## Functional equivalence rule

**Refactoring must preserve all functionality.** When condensing or cleaning up a spec:

- Every behavior described in the original must remain in the refactored version
- If removing verbose code, the prose replacement must capture the same edge cases
- If a gotcha/pitfall was documented, it stays documented (perhaps more concisely)
- When in doubt, keep it - removing functionality is worse than verbosity

Ask: "If someone implements from the new spec, will they produce the same behavior as the old spec?"

## Specs to analyze
- `specs/frontend.md` - Frontend design specification
- `specs/backend.md` - Backend server specification
- `specs/hey-library.md` - HEY Calendar library specification

## Check for dead documentation

Scan each spec for:
1. **Files/artifacts mentioned but not needed** - Like TESTING.md that gets created but never used
2. **Embedded code that duplicates implementation** - Full code blocks that will drift from actual files
3. **Stale status/checklist sections** - Implementation status, TODO lists that aren't maintained
4. **Duplicate information across specs** - Same content copy-pasted in multiple places without purpose

## Check for over-specification

Flag sections that are too verbose:
1. **Excessive code blocks** - Could the intent be conveyed in prose instead?
2. **Obvious implementation details** - Standard patterns that don't need spelling out
3. **Verbose where concise would do** - 10 lines explaining what 2 lines could

Ask: "Does this code block teach something non-obvious, or is it just showing how to do something any developer would know?"

## Check for self-containment

Each spec must be independently implementable. Verify each spec has:
1. **Enough context to implement** - Can someone implement from just this spec?
2. **Clear API contracts** - If it consumes/provides APIs, are they documented?
3. **Cross-references where needed** - "See X for details" instead of duplication

## Report format

For each issue found:
- **Location**: Which spec, which section
- **Issue type**: Dead doc / Duplication / Missing context / Over-specified
- **Recommendation**: Remove / Add cross-reference / Condense to prose / Keep (if precision needed)

## Before making changes

1. Present findings to me first
2. Ask clarifying questions if intent is unclear
3. Get approval before editing specs

Do NOT automatically fix issues - this is an audit tool. Present findings and wait for direction.
