# Connected demo redesign

The user's “deop screen” was interpreted as the connection demo after requesting clarification. The change preserves the existing in-memory demo store and receipt confirmation flow; no household data, AI, CloudKit, notifications or permission behavior changes.

Five selectable scenes replace the Canvas diagram. Existing bundled photography sits behind opaque sample-record cards; titles and explanatory content use Dynamic Type. Chapter controls, pause/play and manual stepping remain available. A cancellable structured task advances scenes every five seconds, with a short dissolve/lift transition and no per-frame drawing loop. Reduce Motion disables automatic playback and animated transitions. Accessibility text sizes omit decorative photography/cards while preserving explanations and actions. Backgrounding pauses playback.

Validation evidence:
- XcodeGen and simulator build passed.
- 272 unit tests in 51 suites passed, plus grocery search performance coverage: `/tmp/luna-demo-modern.log`.
- Animated playback, pause and next scene passed on iPad and iPhone Duo simulators (`/tmp/luna-demo-modern.log`, `/tmp/luna-demo-phone.log`).
- The initial Reduce Motion test exposed that the existing debug launch flag was only used by purchase/assignment feedback. The demo now reuses that shared helper; production still follows the system setting.
- Reviewed the iPad Spending scene screenshot: `docs/visual-review/connected-demo-2026/iPad-spending.png`.
- Physical-device animation smoothness and VoiceOver remain manual checks. This change is not deployed to TestFlight.
- Final Reduce Motion + accessibility text test passed on both iPhone Duo and iPad, including manual next-scene selection, disabled automatic playback and loading the sample receipt review: `/tmp/luna-demo-accessibility.log`.
- `git diff --check` passed.
