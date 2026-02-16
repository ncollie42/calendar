---
created: 2026-01-27T13:05
title: Add Deploy Pipeline - Local to Fly and Convex
area: tooling
files: []
---

## Problem

Currently no automated deployment pipeline exists. Need a way to deploy from local development machine that:
1. Syncs/pushes changes to a PC (possibly for backup or secondary deployment)
2. Deploys frontend to Fly.io
3. Deploys backend/functions to Convex

Manual deployment is error-prone and tedious.

## Solution

TBD - Create a deploy script (possibly `scripts/deploy.sh` or `bun run deploy`) that orchestrates:
- Git push or rsync to PC
- `fly deploy` for frontend
- `bunx convex deploy` for Convex functions
