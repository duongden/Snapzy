# Phase 03: Testing & Validation

## Context

- **Parent Plan:** [plan.md](plan.md)
- **Dependencies:** Phase 01, Phase 02

## Overview

| Field | Value |
|-------|-------|
| Date | 2026-01-29 |
| Description | Comprehensive testing of window focus fixes |
| Priority | High |
| Implementation Status | Pending |
| Review Status | Pending |

## Test Scenarios

### Scenario 1: Basic Focus Preservation

**Steps:**
1. Open 3 different windows (e.g., Safari, VSCode, Terminal)
2. Focus on window 2 (e.g., VSCode)
3. Trigger screen recording (hotkey or menu bar)
4. Draw selection rectangle

**Expected:**
- VSCode remains the active/focused window throughout
- Area selection overlay appears on top
- After selection, toolbar appears but VSCode still focused

### Scenario 2: Multi-Monitor Focus

**Steps:**
1. Connect external monitor
2. Have windows on both monitors
3. Focus window on monitor 2
4. Start recording, select area on monitor 1

**Expected:**
- Window on monitor 2 remains focused
- Selection works correctly across monitors

### Scenario 3: Recording Flow Complete

**Steps:**
1. Focus on a specific window
2. Start recording
3. Select region
4. Click Record button
5. Wait 5 seconds
6. Click Stop

**Expected:**
- Focus preserved throughout entire flow
- Recording completes successfully
- Video saved correctly

### Scenario 4: Cancel Flow

**Steps:**
1. Focus on window
2. Start recording
3. Press Escape

**Expected:**
- Selection cancelled
- Focus unchanged

### Scenario 5: Region Adjustment

**Steps:**
1. Start recording
2. Select region
3. Drag region to new position
4. Resize region using handles
5. Start recording

**Expected:**
- Focus preserved during drag/resize
- Region updates correctly

## Todo List

- [ ] Test Scenario 1: Basic Focus Preservation
- [ ] Test Scenario 2: Multi-Monitor Focus
- [ ] Test Scenario 3: Recording Flow Complete
- [ ] Test Scenario 4: Cancel Flow
- [ ] Test Scenario 5: Region Adjustment
- [ ] Document any issues found
- [ ] Fix any regressions

## Success Criteria

All 5 scenarios pass without focus stealing.

## Regression Checklist

- [ ] Area selection mouse events work
- [ ] Crosshair rendering works
- [ ] Selection rectangle rendering works
- [ ] Escape key cancels
- [ ] Recording toolbar appears correctly
- [ ] Recording starts/stops
- [ ] Video is saved correctly
- [ ] Multi-monitor works

## Next Steps

If all tests pass, close this plan as completed.
If issues found, create additional fix phases.
