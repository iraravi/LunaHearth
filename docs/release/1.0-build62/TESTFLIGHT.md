# TestFlight 1.0 (62) — September 24, 2026

Requested upload of the current workspace, including the publisher-only public configuration implementation.

## What to test

- Manual shopping, pantry entry and existing household records remain available.
- Help & guides and contextual help work on iPhone and iPad.
- AI-only controls respect actual device capability and published settings.
- No user-facing App Status/feature-flag management screen is present.
- Publisher notices and help text are read-only. Missing or expired public configuration uses app defaults.

## Validation carried forward

Full unit suite and public-settings UI flow passed on iPhone/iPad simulators. After removing the App Status screen, configuration tests and updated UI flow passed again on both sizes. Logs: `/tmp/luna-config-final.log`, `/tmp/luna-publisher-only.log`.

## Distribution

Release archive succeeded at `/Users/ira/Library/Developer/Xcode/Archives/2026-09-24/LunaHearth 1.0 (62).xcarchive` using Xcode 27.1; log `/tmp/luna62-archive.log`.

Xcode Organizer confirmed “App upload complete” and “LunaHearth 1.0 (62) uploaded”. Safari App Store Connect subsequently confirmed processing completed. Build 62 was added to the existing LunaHearth Beta internal group (three testers) and its status is Testing. Both Ravi test accounts belong to that group. Builds 61 and 62 previously had no groups assigned, explaining why only build 60 appeared.

Build 62 was also added to the existing Ravi Home external group with What to Test notes and automatic tester notification enabled. After submission, App Store Connect showed Testing for build 62 in that group as well; no pending review was shown.

No public App Store release is requested. Device installation of build 62 has not been verified.

## Public configuration

CloudKit Console schema/permissions and production `ios-current` publication remain unverified and are separate from binary upload. See `docs/PUBLIC_APP_CONFIGURATION.md`. Scheduled activation dates are not implemented. No household records are made public.
