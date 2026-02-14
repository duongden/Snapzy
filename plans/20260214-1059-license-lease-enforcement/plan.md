# License Lease Enforcement — Plan Overview

**Date**: 2026-02-14
**Status**: 🟡 In Review
**Priority**: High — Security-critical feature

## Problem

Disabled/revoked Polar license keys are not detected after initial activation. App continues working indefinitely from stale cache.

## Solution

Short-lived lease architecture with hybrid offline-first validation, background sync, and grace period anti-cheating.

## Research

- [Researcher 01 — Polar API](research/researcher-01-report.md)
- [Researcher 02 — macOS Lease Patterns](research/researcher-02-report.md)

## Implementation Phases

| Phase | Name                                                         | Status | Files                     |
| ----- | ------------------------------------------------------------ | ------ | ------------------------- |
| 01    | [Lease Model & Cache](phase-01-lease-model-and-cache.md)     | ⬜     | 2 files (1 new, 1 modify) |
| 02    | [Lease Lifecycle Engine](phase-02-lease-lifecycle-engine.md) | ⬜     | 1 file (modify)           |
| 03    | [App Integration & Enforcement](phase-03-app-integration.md) | ⬜     | 1 file (modify)           |
| 04    | [Verification](phase-04-verification.md)                     | ⬜     | 0 files (testing only)    |

## Key Constants

```
Lease Duration:       1 hour
Background Sync:      15 minutes
Grace Period:         2 days, max 3 uses
Time Drift Threshold: 5 minutes
```

## Risk Assessment

- **Low**: Rate limits — 4 req/hour << 3 req/sec limit
- **Low**: False positives — generous grace period + uptime-based anti-cheat
- **Medium**: Clock manipulation — mitigated by server time anchor + system uptime
