#!/bin/bash

# Workspace Reset Script
# Wipes implementation code while preserving specs, configs, and planning files.
# Use this for full rebuilds from specs.

set -e

cd "$(dirname "$0")/.."

echo "=== Workspace Reset ==="
echo ""
echo "This will DELETE the following implementation files:"
echo "  - src/           (React components, hooks, lib)"
echo "  - convex/        (backend schema and functions)"
echo "  - public/        (static files)"
echo "  - tests/         (server tests)"
echo "  - server.ts      (dev server entry)"
echo "  - build.ts       (build script)"
echo "  - node_modules/  (dependencies)"
echo "  - bun.lock       (lockfile)"
echo ""
echo "The following will be PRESERVED:"
echo "  - specs/         (source of truth)"
echo "  - .claude/       (workflow settings)"
echo "  - .planning/     (todos)"
echo "  - scripts/       (utility scripts)"
echo "  - Config files   (package.json, tsconfig.json, etc.)"
echo ""

read -p "Are you sure you want to reset the workspace? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Deleting implementation files..."

deleted=()

# Directories
for dir in src convex public tests node_modules; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        deleted+=("$dir/")
    fi
done

# Files
for file in server.ts build.ts bun.lock; do
    if [ -f "$file" ]; then
        rm -f "$file"
        deleted+=("$file")
    fi
done

echo ""
echo "=== Summary ==="

if [ ${#deleted[@]} -eq 0 ]; then
    echo "Nothing to delete (workspace was already clean)."
else
    echo "Deleted:"
    for item in "${deleted[@]}"; do
        echo "  - $item"
    done
fi

echo ""
echo "Preserved:"
for item in specs .claude .planning scripts package.json tsconfig.json vitest.config.ts .gitignore .dockerignore Dockerfile fly.toml CLAUDE.md; do
    if [ -e "$item" ]; then
        echo "  - $item"
    fi
done

echo ""
echo "=== Next Steps ==="
echo "1. Run 'bun install' to restore dependencies"
echo "2. Regenerate implementation from specs"
echo ""
