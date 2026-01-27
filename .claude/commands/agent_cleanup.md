I want you to refactor my AGENTS.md file to follow progressive disclosure principles.

Target file: `$ARGUMENTS` (defaults to `CLAUDE.md` if not specified)

Follow these steps in order:

## Step 1: Find Contradictions

Scan the entire file for instructions that conflict with each other. For each contradiction found:
- Quote both conflicting instructions
- Explain the conflict
- Ask me which version I want to keep

Do NOT proceed until all contradictions are resolved.

## Step 2: Identify the Essentials

Extract only what truly belongs in the root AGENTS.md. These are instructions relevant to **every single task**:
- One-sentence project description
- Package manager (only if not npm)
- Non-standard build/test/typecheck commands
- Critical invariants that apply universally

Be ruthless. If it only applies to some tasks, it goes in a category file.

## Step 3: Group the Rest

Organize remaining instructions into logical categories. Common groupings:
- `typescript.md` - TS conventions, type patterns
- `testing.md` - Test patterns, coverage requirements
- `api.md` - API design, endpoint conventions
- `git.md` - Commit messages, branching, PR workflow
- `architecture.md` - Module structure, dependency rules
- `errors.md` - Error handling patterns

Create groups based on what's actually in the file, not these examples.

## Step 4: Flag for Deletion

Identify instructions that should be removed entirely:

**Redundant** (agent already knows):
- "Use meaningful variable names"
- "Handle errors appropriately"
- "Write tests for your code"

**Too vague** (not actionable):
- "Write clean code"
- "Follow best practices"
- "Be consistent"

**Overly obvious**:
- "Import before using"
- "Don't commit broken code"

For each flagged item, explain why it should be deleted.

## Step 5: Present the Plan

Before making any changes, show me:

1. **Proposed root file** - The minimal AGENTS.md content
2. **Category files** - List of files with their contents
3. **Deletions** - What's being removed and why
4. **Folder structure** - Suggested `.claude/docs/` layout

Example structure:
```
CLAUDE.md (or AGENTS.md)
.claude/
  docs/
    typescript.md
    testing.md
    git.md
```

## Step 6: Execute

Only after I approve the plan:
1. Create the category files in `.claude/docs/`
2. Update the root file with links to each category
3. Remove flagged items

## Link Format

In the root file, link to category files like this:
```markdown
## Detailed Instructions

See context-specific instructions:
- [TypeScript conventions](.claude/docs/typescript.md)
- [Testing patterns](.claude/docs/testing.md)
```

Do NOT proceed past Step 1 without resolving contradictions. Do NOT create files without my approval on the plan.
