# Nam Illam 1.0 (68)

Final renamed candidate, uploaded to Apple on 30 October 2026 and selected for version 1.0. Publication/submission state: see ../nam-illam-app-store/STATUS.md.

Includes the complete published offline privacy policy and public policy link. Display and permission text use Nam Illam; bundle, data and CloudKit identifiers remain stable.

Build/archive successful; 287 Swift Testing cases in 52 suites plus performance test passed. Seven primary UI regressions passed, covering dark mode, large text, receipt review/import, stock preservation and offline policy. Two additional Apple-list creation/completion UI tests passed. Screenshot test was corrected to explicitly select shelf view instead of depending on a prior user preference; final capture rerun recorded separately. No real household data used.

Security audit is an offline heuristic check, not Sonar or a vulnerability database scan. Physical-device iOS 18, two-account production iCloud sharing, real camera/permissions, notification delivery and VoiceOver acceptance are not established by these tests.

Screenshot package: six iPhone (1320 × 2868), six iPad (2064 × 2752), and six Duo (1398 × 2034) native captures. Duo screenshot walkthrough passed on iOS 27.1; all six images visually inspected. iPad upload verified; iPhone and Duo uploads remain pending.
