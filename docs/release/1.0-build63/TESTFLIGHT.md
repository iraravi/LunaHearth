# TestFlight 1.0 (63)

## Changes

- Shopping ideas filter against stocked pantry ingredients and open shopping items before presentation and saving. Low-stock, used-up and past-expiry packs remain eligible for restocking. Ingredient varieties are not merged automatically.
- First-time setup explains create, join and restore paths; naming is the sole required step. Follow-up activities are explicitly optional.
- Local fresh-start action requires typed confirmation and refuses deletion whenever any iCloud sync configuration exists. Shared-home deletion remains CloudKit-owner-only; delegated deletion is not implemented.
- Includes the previously uploaded build 61/62 help, capability checks, performance work and publisher-managed public settings.
- Main navigation and visual design remain unchanged. The rejected HTML navigation concept is not part of this release commit.

## Validation

- Release archive succeeded with Xcode 27.1. Archive log: `/tmp/luna63-archive.log`.
- 255 Swift Testing tests in 48 suites passed; the 1,000-ingredient search performance test also passed. Initial log: `/tmp/luna63-check.log`.
- All eight release UI scenarios passed on the Duo simulator across the initial run and targeted reruns. Final calendar and receipt results: `/tmp/LunaHearthRelease63/DuoRelease.xcresult`, `/tmp/luna63-duo-release.log`.
- The initial UI failures exposed test gestures outside adaptive sheets and transient accessibility identities during navigation. The helper now snapshots the hierarchy, resolves only the foreground scroll container for its gesture, and preserves the outcome assertions. Only test code changed after archiving.
- iPad and additional iPhone help/capability UI checks are being completed separately; their results will be appended.
- No physical installation or live household sharing test is claimed by this release check. Fixtures use local synthetic data and mocked Calendar delivery.

## Distribution

Archive: `/Users/ira/Library/Developer/Xcode/Archives/2026-09-26/LunaHearth 1.0 (63).xcarchive`.

Xcode Organizer confirmed upload completion. App Store Connect confirmed processing complete. Build 63 was assigned to the existing **LunaHearth Beta** internal group (four testers); its group build table shows **Testing**.

External **Ravi Home** distribution is not yet complete: build 63 was selected, but the Mac locked at the What to Test form before submission. User unlock is required to finish that UI step. No public App Store submission was requested or made.

A request for a new tester name/email remains unanswered; no additional tester identity was inferred or created. Existing group membership was retained.
