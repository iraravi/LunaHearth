# Publishing app status and feature settings

Implementation: ADR 049. Settings never contain household data. Read-only clients use offline defaults when no valid published record exists. Only the publisher manages flags in CloudKit Console. There is no user-facing flag/status management screen. Users see published announcements, contextual pause messages, and help text in Help & guides.

## CloudKit Console setup

1. Open the existing `iCloud.com.neuralluna.lunahearth` container in CloudKit Console. Start in Development.
2. Create record type `LHAppConfiguration`, field `payload` of type String.
3. Configure public record permissions: World may Read; ordinary Authenticated/Creator roles must not Create or Write. Publish only using trusted CloudKit Console developer access. Verify with an ordinary app account that writes fail.
4. In the PUBLIC database/default zone, create record ID `ios-current` of that type. Paste the JSON below into `payload`. Use a future ISO8601 expiry within 31 days.
5. Test enabled/paused/offline/expired settings. Deploy the schema and permissions to Production, then create the same record in Production (development records are not copied).
6. Increment revision for every edit, including rollback. Restore earlier content under a newer revision. Never publish secrets or personal information.
7. Install a new app build containing this implementation. Build 61 predates it. Verify production fetching on a signed device/TestFlight before calling remote controls live.

```json
{
  "schemaVersion": 1,
  "revision": 1,
  "expiresAt": "2026-09-30T23:59:59Z",
  "features": {
    "ai": { "enabled": true },
    "aiReceiptNames": { "enabled": false, "message": "Receipt name suggestions are being improved. You can edit names manually." },
    "receipts": { "enabled": true },
    "shoppingToPantry": { "enabled": true }
  },
  "announcement": "Help & guides is now available under More.",
  "helpText": "Review receipt names, amounts and destinations before saving. Manual entry remains available."
}
```

Omitted known flags default to enabled. Unknown keys are ignored. Empty announcement/help text removes that content. No remote images, URLs or executable content are supported. AI enabled also needs real device/model availability; it cannot activate Apple Intelligence on unsupported hardware.

## Supported keys

| Keys | Scope |
|---|---|
| `ai` | Master generation switch |
| `aiMeals`, `aiShopping`, `aiPantry` | Individual suggestion models; built-in fallbacks remain |
| `aiCategories`, `aiDuplicates`, `aiReceiptNames`, `aiPhoto`, `aiBriefs` | Individual model operations |
| `receipts` | Receipt scanner and new receipt screen |
| `receiptImport`, `receiptExpenses`, `receiptPantry` | Confirmation and individual requested destinations; a paused destination blocks the whole save until review changes |
| `pantryPhoto`, `pantryTemplates` | Kitchen-photo scan, starter-list creation |
| `shoppingIdeas`, `shoppingAssignments`, `shoppingToPantry` | Suggestions, new/reassigned buyers, purchase stocking |
| `mealIdeas`, `weeklyMeals`, `mealReminder` | Proposal screen/service, weekly planning/save, new 5 PM scheduling |
| `notesSharing` | Share-to-Notes composer, not a Notes library connection |
| `calendarExport` | Calendar permission request for export and nondeleting delivery |
| `reminders` | New connection/list/entry; existing reminder reads/completion stay available |

Checks occur on foreground, no more than once every 15 minutes. A failed fetch retains a valid cache; expired settings revert to app defaults. Changes are not guaranteed immediately and do not cancel already-running work. Notices are publisher-authored messages, not automatic measurement of Apple's service health. No public writes occur in the app. Disable a feature by publishing `enabled: false`, not deleting user data or modifying household records.

## Verification status

Source and automated validation are recorded with this change. CloudKit Console schema, permissions, production record publication and signed-device fetching have NOT been verified. Do not claim switches are live until these steps pass. Update the externally hosted privacy policy to match the bundled public-settings disclosure before release.

### Automated validation — September 23, 2026

- Simulator build succeeded (`/tmp/luna-config-build.log`).
- Initial full unit run passed 252 Swift Testing tests in 48 suites, plus the grocery performance XCTest (`/tmp/luna-config-tests.log`).
- Final full unit suite and `testPublicSettingsPreserveManualShopping` passed on both iPhone 18 Pro and iPad Pro 13-inch simulators (`/tmp/luna-config-final.log`). The UI case uses an isolated DEBUG-only configuration fixture and makes no public CloudKit request.
- Verified AI controls are hidden despite a ready-capability fixture, manual shopping remains accessible, paused receipt scanning explains the pause and has no Save action, and App status opens. Screenshot review corrected duplicate dismissal controls. Evidence: `docs/visual-review/public-settings/`.
- Live CloudKit permissions/publication, physical devices, VoiceOver and TestFlight deployment remain unverified for this change. Earlier build 61 is unchanged and does not contain these switches.

### Publisher-only UI correction
The user-facing App status screen and manual configuration refresh were removed at the publisher’s request. No feature flag controls are exposed to household owners or participants. Existing App Status screenshots above document the earlier iteration, not the current UI. Published plain-text guidance appears in Help & guides; public records remain restricted to nonconfidential, non-personal publisher content. CloudKit production permissions still require verification.

Publisher-only correction validation: configuration unit tests and the updated public-settings UI flow passed on both iPhone and iPad simulators (`/tmp/luna-publisher-only.log`). The UI test asserts absence of the App Status/refresh controls, continues to verify the paused receipt behavior and manual shopping, and opens publisher guidance through Help & guides. No production publication or device deployment was performed.

### Production publication — September 26, 2026

Verified in CloudKit Console: created the `recordName` queryable index, removed ordinary `_icloud` create and `_creator` write permissions for `LHAppConfiguration`, retained `_world` read, and deployed the schema to Production. The reviewed schema diff only introduced this configuration type. Production public/default-zone query succeeded and initially returned no records. Published `ios-current` with revision 1, expiry `2026-10-20T23:59:59Z`, master AI enabled and `aiReceiptNames` disabled with the publisher's maintenance message. Read back the saved payload in Console. Physical-device fetching and ordinary-account write-rejection testing are still not verified. The index supports Console browsing; the app fetches by fixed record ID without a query.
