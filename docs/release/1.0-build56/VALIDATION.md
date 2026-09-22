# Build 56 — direct device installation

September 16, 2026. Version 1.0 (56) includes the simplified Meals experience described in ADR 045: meal ideas, ingredients, planning and shopping without recipe instructions. Existing records are retained; no schema or privacy transport changes.

- XcodeGen generation and signed Release build succeeded. Product Info.plist confirms build 56. Build log: `/tmp/luna56-device.log`.
- Preceding source validation passed: 239 unit tests in 44 suites and the full meal workflow UI test, including absence of recipe controls (`/tmp/luna-simple-meals.log`). Final simulator build passed after the navigation wording change (`/tmp/luna-simple-meals-finalbuild.log`).
- Installed directly on Ravi’s iPad and Ravi’s iPhone with devicectl. No uninstall, reset or data deletion was performed.
- iPad app launch succeeded. iPhone installation succeeded, but launch was denied because the device was locked; unlock and open manually.
- Physical-device visual/interaction QA was not performed. This build was not uploaded to TestFlight.
