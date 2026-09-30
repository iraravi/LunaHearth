# TestFlight 1.0 (64)

## Changes
- AI reliability fixes across nine on-device adapters; private last-result diagnostics in More → AI Status.
- Typed shopping requests no longer fall back to unrelated purchase history.
- Smaller classification/comparison batches and bounded prompt text.
- Improved ingredient validation, cancellation and stale-result handling.
- Today and assigned-shopping AI controls respect capability and publisher settings.

## Validation
Release archive passed: `/tmp/luna64-archive.log`.
Audit: `docs/validation/2026-09-28-ai-audit.md`.
266 unit tests plus the grocery performance XCTest passed. Six selected iPhone/iPad UI checks passed, including large text and unavailable/paused AI workflows. Physical model accuracy was not verified.
Archive: `/Users/ira/Library/Developer/Xcode/Archives/2026-09-28/LunaHearth 1.0 (64).xcarchive`.

## Distribution
Command-line export could not access the App Store Connect account. Retried through the signed-in Xcode Organizer; it confirmed “LunaHearth 1.0 (64) uploaded”. App Store Connect browser sign-in is restored. Processing and tester-group availability are not yet verified; the browser is being used concurrently.
