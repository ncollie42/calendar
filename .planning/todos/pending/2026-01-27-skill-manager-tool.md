---
created: 2026-01-27T21:48
title: Build skill manager tool
area: tooling
files: []
---

## Problem

Currently skills (Claude Code custom commands) are scattered across projects. To share them:
- Copy-paste manually between repos (tedious, no sync)
- Put in global `~/.claude/commands/` (loses project context, all-or-nothing)

Need a tool that:
1. Maintains a **central store** of skills (all available skills in one place)
2. Lets you **load/unload** skills into current project or global scope
3. **Tracks all Claude projects** so you can see where skills are used
4. Syncs updates — change a skill once, update everywhere it's loaded

## Solution

Build a standalone CLI tool (likely in the user's home directory or as a global install):

```
skill-manager
├── store/              # Central skill repository
│   ├── gsd-add-todo.md
│   ├── commit.md
│   └── ...
├── projects.json       # Registry of all Claude projects
└── skill-manager       # CLI binary
```

Commands:
- `skill load <name> [--global]` — Copy skill from store to `.claude/commands/` or `~/.claude/commands/`
- `skill unload <name> [--global]` — Remove skill from current project or global
- `skill list` — Show available skills in store
- `skill status` — Show what's loaded in current project vs global
- `skill sync` — Update loaded skills from store (if store version changed)
- `skill add <path>` — Add current project skill to central store
- `skill projects` — List all tracked Claude projects

TBD: Could also be a Claude skill itself (`/skill:load`, `/skill:unload`).
