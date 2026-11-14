# Deep release review — October 4, 2026

Status: code review and automated verification complete; public submission gates remain open. Remote `origin/main` was fetched successfully; local `main` at `daa0eba509c46496c70f748d42f76c8eb113b37c` is two commits ahead and zero behind. Public Apple submission is **not approved by this report**. The current working tree, including existing uncommitted Help, Today and demo changes, is the review target. No changes were discarded or pulled over them.

## Review scope and privacy

Reviewed local transaction/rollback boundaries, imported backup/shared record validation, cloud conflict handling and account boundaries, explicit Calendar/Reminders destinations, asynchronous refreshes, receipt reconciliation and quantity arithmetic, date handling, on-device AI input/cancellation bounds, URL parsing, permission strings, privacy manifest and release linkage. Changes affect event and meal import, repository reload publication, appointment delivery/alerts, Reminders list selection, Today accessibility and iPhone/iPad room navigation. No new network service, runtime dependency, schema migration, analytics, identity or household ownership change.

Normal tests use isolated fictional households and fake Apple adapters. Live Apple account data is not used. Screenshots and regression evidence are temporary local artifacts, not uploaded. Code review and pattern checks cannot certify that every bug or vulnerability is absent.

## Confirmed findings and fixes

| Finding | Effect | Fix and evidence |
|---|---|---|
| Invalid imported event range | A backup/shared event ending before its start could be inserted despite local entry validation | Validate finite, ordered dates and the title before graph insertion. Reproduced in `invalidImportedEventRangeCannotCreatePartialHome`; now passes and leaves the target empty on rejection. |
| Overlapping appointment alert refresh | An edit or notification opt-out during an earlier asynchronous replacement could leave stale alerts scheduled | Queue a follow-up refresh and re-read current state. Deterministic suspended-service regression failed before, passed after. |
| Calendar operational pause recorded as uncertain write | A brand-new export paused before EventKit access could never retry safely after resuming | Recognize the pre-write configuration pause, preserve prior uncertain-write protection and display the pause reason. Strict fake resolver regression failed before, passed after. |
| Reminder list row ignores taps in empty area | Tapping the center of a plain selection row failed to select it | Explicit rectangular hit area, stable identifier and selected accessibility trait. Full create/select/add/complete UI flow failed before and passed after on iPhone 18 Pro. The same iPad flow then exposed a separate completion-row hit area, fixed below. |
| Invalid imported meal civil day | A non-existent date key made the restored meal unreachable in valid day views | Reject invalid non-nil date keys before insertion. Regression failed with three assertions before the fix, then passed in the 276-test suite. |
| Partially published reload state | Calendar-link or purchase-history fetch failure could interrupt publication after some arrays had changed | Move both throwing fetches before any observable state assignment. Reviewed ordering; final unit suite passed. |
| Today layout overwrites child accessibility metadata | The For you link inherited the layout's ID and “Stacked” value | Remove container-only technical identifier/value; retain each control's own semantics. Confirmed by captured XCTest accessibility tree; assigned-task create/complete flow now passes in the updated broad UI run. |
| Compact room links do not open | A nested split view inside Home's navigation stack left iPhone users on the list after tapping a room | Use the existing stack for compact room destinations; keep regular-width split selection. Reproduced on two iPhone sizes; the full room/item/warranty/maintenance flow now passes on iPhone 18 Pro. The iPad flow also passes, including rotation and return to Home. |
| Reminder completion row ignores wide blank area | Tapping the center of a wide iPad reminder row did not toggle completion | Expand the label to the row width and add a rectangular content shape. iPad regression failed before; full select/create/add/complete flow now passes. |
| iPad item navigation stops at the room | Rooms were opened inside Home's existing navigation stack, causing nested split/detail navigation to stop before the asset page | Present the regular-width rooms workspace independently, with Done back to Home and compact navigation when resized. Reproduced with a selected Fridge row and missing warranty action. The corrected iPad flow passes through asset, warranty and maintenance detail, rotates and returns to Home. |

The initial three regression tests produced nine failed assertions before the fixes. The subsequent full unit run passed 275 tests in 51 suites plus the performance XCTest. The malformed-meal regression also failed before its fix; the next full unit run passed 276 tests in 51 suites. The subsequent final-source run also passed all 276 Swift tests plus the performance XCTest, including the reload publication fix.

## Validation evidence

Raw logs/results are under `/tmp/LunaDeepReviewOct03` (the directory was created before the client date changed). Keep portable summaries here; raw temporary files may not survive cleanup.

- Baseline: 272 Swift tests in 51 suites plus the performance XCTest passed.
- Initial full UI run was interrupted to split the remaining work. It is not a passing full-suite result; retained failures drove the Reminders and Today fixes.
- Updated UI suite: all 114 cases allocated across three explicit 38-case shards. Shards 1 and 3 finished; shard 2 was stopped after 36 completed cases when stale scrolling/orientation assumptions were identified. Focused reruns preserve the intended assertions. Passing evidence covers all 114 distinct phone UI cases across broad runs and targeted reruns after fixes (see `2026-10-04-deep-review/ui-coverage.json` in the dated evidence folder). This is aggregate evidence, not a single all-green full-suite run on one exact binary. The final two-case rerun passed with zero failures.
- Latest full unit verification: 276 Swift tests in 51 suites plus the performance XCTest passed. Final phone and iPad Home flows passed through room, item, warranty and maintenance, including rotation; iPad also returned to Home. Reminders selection, creation, addition and completion passed on both device classes.
- Unsigned Release iPhone/iPad build and Xcode Analyze action passed with no reported compiler/analyzer warnings. This action is not a comprehensive Swift vulnerability analysis or distribution signing validation. Final-source rebuild and Analyze action passed; see release-binary-final.json.
- Binary check: iOS 18 minimum, iPhone/iPad device families, iPhoneOS 27.1 SDK, privacy manifest present, tracking false, no non-system linked dynamic libraries. No third-party runtime packages are declared.
- `scripts/security-audit.py`: offline heuristic checks for common credential literals/files, forced try/cast, unsafe concurrency overrides, disallowed imports, ATS exceptions, required permission text and relevant project/privacy settings. The latest scan of 196 production Swift files returned no matching findings. It does not query CVEs or prove absence of secrets/vulnerabilities.

## UI harness maintenance

The broad run also exposed stale tests after earlier product changes. Preserve the intended assertions while following the current UI: “Getting started” title, pantry/shopping tools sheets, current on-device AI test message and iPad navigation controls. Scroll targets into the actual visible viewport; SwiftUI reports a scroll frame extending behind fixed footers, so use its indicator bounds. Reset orientation before each case so a failed landscape case cannot contaminate later tests. Prefer the visible matching control when SwiftUI also exposes a presenting screen behind a modal, and derive geometry from one snapshot to avoid redundant accessibility queries. Landscape shelf visibility now checks the item after scrolling to it; the separate compact-portrait above-the-fold assertions remain unchanged. The final shopping rerun removed redundant swipes that timed out in simulator event synthesis. The compact action test now asserts a hittable target at least 44 points tall and narrower than half the screen; its obsolete 48-point maximum rejected the current native glass control at 58 points. Permission/cloud behavior and business outcomes are still asserted.

## Sonar status

No Sonar scanner, project URL or credentials were configured at the start. `sonar-project.properties` now scopes production and test sources and waits for the server quality gate. It contains no token, guessed project key or server address. **No Sonar scan or quality gate has run; no source has been uploaded.** Supply the existing project/server URL and authenticate through the scanner's normal secure environment. Do not paste credentials into chat or commit them. SonarQube Server Swift analysis requires an edition with Swift support; its official documentation currently lists Developer Edition or above and Swift 3–6.3 support.

## Open Apple release gates

- Final legal publisher/contact/pricing decisions, hosted support/privacy URLs, and replacing the in-app draft privacy policy remain unresolved.
- A changed production binary needs a new build number and verification before upload. Build 66 remains the existing TestFlight reference.
- India-only availability is confirmed by the user but has not been applied/verified in App Store Connect during this review.
- Production two-account CloudKit, real EventKit permission allow/deny and account delivery, remote notifications, spoken Siri, on-device model quality, VoiceOver and execution on the minimum iOS 18 remain separate physical acceptance checks.
- Simulator tests, static checks and a successful Release build do not establish Apple approval. No Submit for Review or Release action has been taken.

Sources checked: [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/), [Sonar Swift support](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/languages/swift).

## Runtime observations to retain

Some simulator runs report a SwiftUI “Invalid frame dimension (negative or non-finite)” warning when the setup keyboard opens. The result bundle supplies no source location or stack, and the affected setup flow still completes. This is not counted as a compiler warning or silently dismissed as resolved; it needs separate SDK/device investigation. Xcode also emits toolchain OS-build parsing and remote accessibility-server diagnostics. The final successful run also reported a simulator diagnostic-collection failure because its child process could not locate simctl; test execution itself passed. Preserve these alongside the functional results.

Interrupted attempts are retained as non-passing evidence. Five simultaneous simulators caused heavy host swapping; later runs use fewer simulators. A runner that failed to start after restart was stopped and is not counted as an app test result.
