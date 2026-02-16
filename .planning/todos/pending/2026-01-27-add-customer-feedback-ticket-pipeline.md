---
created: 2026-01-27T13:06
title: Add Customer Feedback Ticket Pipeline
area: general
files: []
---

## Problem

No system exists for collecting and managing customer feedback. Need a way for users to submit feedback, bug reports, or feature requests. Should be agnostic (not tied to a specific ticketing system) so it can integrate with different backends (GitHub Issues, Linear, Notion, email, etc.).

## Solution

TBD - Design an agnostic feedback interface that:
- Provides in-app feedback submission UI
- Abstracts the ticket destination behind an adapter pattern
- Supports multiple backends without code changes
