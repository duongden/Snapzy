# Manual QA Session Worksheet (Sandbox)

**Date:** 2026-02-19  
**Session ID:** 260219-0027  
**Build:** `Snapzy` (sandbox enabled)

## Preconditions

1. Build app in Debug at least once (`xcodebuild ... Debug ... CODE_SIGNING_ALLOWED=NO`).
2. Start with clean onboarding state.
3. Open Console.app and filter process: `Snapzy`.
4. Capture sandbox deny lines while running scenarios.

### Reset commands (clean-state rerun)

```bash
defaults write Snapzy onboardingCompleted -bool false
defaults delete Snapzy "exportLocation.bookmark" >/dev/null 2>&1 || true
defaults delete Snapzy "wallpaper.directoryBookmark" >/dev/null 2>&1 || true
defaults write Snapzy exportLocation -string "$HOME/Desktop/Snapzy"
tccutil reset ScreenCapture Snapzy
tccutil reset Microphone Snapzy
tccutil reset Accessibility Snapzy
pkill -x Snapzy >/dev/null 2>&1 || true
```

## Result legend

- `PASS`: behavior correct, no blocking deny log.
- `PASS-WARN`: behavior correct, non-blocking warning.
- `FAIL`: behavior broken or blocking deny log.
- `N/A`: not tested.

## Test matrix (fill during run)

| ID  | Scenario                                             | Expected                                                     | Result | Evidence / Notes |
| --- | ---------------------------------------------------- | ------------------------------------------------------------ | ------ | ---------------- |
| Q1  | Onboarding permission flow                           | asks Screen Recording + Save Folder (default Desktop/Snapzy) | N/A    |                  |
| Q2  | Screenshot full capture                              | saves into selected export folder without repeated prompt    | N/A    |                  |
| Q3  | Screenshot area capture                              | saves into selected export folder without repeated prompt    | N/A    |                  |
| Q4  | Recording start/stop (no mic)                        | video file saved and quick access works                      | N/A    |                  |
| Q5  | Recording start/stop (with mic)                      | video file saved with mic audio                              | N/A    |                  |
| Q6  | Annotate: Save to original (granted file)            | save succeeds, window behavior correct                       | N/A    |                  |
| Q7  | Annotate: Save to original (revoked/not granted)     | failure alert shown, no silent close/loss                    | N/A    |                  |
| Q8  | Video editor: Replace Original (granted file)        | replace succeeds                                             | N/A    |                  |
| Q9  | Video editor: Replace Original (revoked/not granted) | permission error path offers Save as Copy                    | N/A    |                  |
| Q10 | Wallpaper fallback folder grant                      | selected folder bookmark restores on relaunch                | N/A    |                  |
| Q11 | License activate/validate/deactivate (online)        | all actions succeed, fingerprint stable after relaunch       | N/A    |                  |
| Q12 | License behavior (offline)                           | expected failure handling, no crash/churn                    | N/A    |                  |
| Q13 | Sparkle check for updates                            | check call succeeds under sandbox                            | N/A    |                  |
| Q14 | Diagnostics log read/write/open folder               | operations succeed                                           | N/A    |                  |
| Q15 | Runtime first-time permissions outside onboarding    | none except explicit recovery prompt                         | N/A    |                  |

## Deny-log checklist

1. Any persistent deny in core flows? `YES/NO`
2. If yes, paste exact deny lines and scenario ID.
3. Mark severity:
   - `P0`: blocks capture/record/save/license/update.
   - `P1`: major UX degradation with workaround.
   - `P2`: minor issue.

## Session summary

- Overall status: `PENDING`
- Blockers:

1.
2.

- Ready for rollout gate (`Debug -> internal Release -> public Release`): `NO`

## Unresolved questions

1. Distribution target policy still undecided (MAS-first vs Developer ID-first).
2. Need decision on dedicated beta cycle before production rollout.
3. Need backend confirmation that device-label format shift is accepted.
