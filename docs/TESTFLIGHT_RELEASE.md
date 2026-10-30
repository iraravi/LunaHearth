# TestFlight beta 0.1.0 (1)

Uploaded September 12, 2026 using Xcode Organizer. App Store Connect app ID:
`6811447245`; bundle ID: `com.neuralluna.lunahearth`.

Apple's upload dashboard confirmed Processing after a successful upload.
Build 1 was subsequently cleared for internal testing and assigned to LunaHearth Beta. Ravi and Vasanthi were invited. No public App Store release was submitted.

Release preparation added an original geometric house app icon and an iPad-specific
orientation array supporting all four orientations for multitasking. This changes
bundle presentation only; no domain entities, persistence schema, permissions, or
data transmission behavior changed.

Validation: XcodeGen generation, signed Release archive, simulator build, and all
69 unit tests passed. The first upload was rejected for missing iPad upside-down
portrait support; the corrected archive uploaded successfully.

## CloudKit production prerequisite (resolved during build 3)

The CloudKit Console deployment preview still listed creation of `LHBackupEntity`,
`LHBackupManifest`, `LHHouseholdEntity`, and `cloudkit.share` in Production.
Production schema deployment must be completed before relying on iCloud backup or
household sharing in this beta. Schema review/export in Safari repeatedly lost its
page content, so no schema deployment was submitted during this upload.

Local workflows remain available offline. Live two-account sharing and restoration
from Production remain device validation tasks; unit tests do not establish them.


## Shopping redesign — 0.1.0 (2)

September 12: signed Release archive and Xcode Organizer upload succeeded. Includes
professional shopping layout, Now/Later summaries, persistent Add item, and new
fresh produce artwork replacing the blue basket. Encryption declaration is now
recorded in Info.plist, consistent with the Apple-system-only declaration for build 1.
The code was validated with a simulator build, 69 unit tests, and shopping UI flows
before archiving. No data model, permissions, or cloud behavior changed.

Build 2 completed Apple processing and was added to the existing LunaHearth Beta
internal group (2 testers). App Store Connect confirmed build 0.1.0 (2) as Testing.
At the time of build 2, the production CloudKit prerequisite remained outstanding. It was resolved during build 3 distribution (below).

### Unreleased shopping refinement

The sage shopping palette and offline US/India store picker are development
changes after build 2. They require a new TestFlight archive/upload.

Reusable private household stores (ADR-014) are also unreleased. All participating
clients must update before using the new store entity. Physical prior-build upgrade
and live two-account CloudKit delivery remain release verification tasks.


## Build 3 release preparation

Signed Release archive succeeded for 0.1.0 (3), including sage shopping surfaces,
offline store search, and reusable private household stores (ADR-014). Prior feature
validation: 81 distinct unit tests and two store/shopping UI flows passed; screenshots
were inspected. Archive: LunaHearth-PrivateStores-Build3.xcarchive.

CloudKit Console deployment succeeded during this release. It confirmed “The schema
is deployed to Production.” No household data was moved into the public database.
Live production two-account delivery and physical upgrade verification remain open.

Xcode Organizer confirmed “LunaHearth 0.1.0 (3) uploaded.” Apple processing and beta
group assignment are checked separately from upload success.

Build 3 completed Apple processing and was added to LunaHearth Beta. App Store
Connect confirmed 0.1.0 (3) as Testing, with 2 testers and 3 builds in the group.
Ravi's existing tester account was confirmed in that group (previously installed
build 2). No new tester access or public App Store release was created.

### Unreleased after build 3

ADR-015 guided shopping entry (inline store suggestions, duplicate warnings,
amount/unit controls, planned dates and compact buttons) is local development work,
not included in the currently distributed build 3.

### Pending next build: personal shopping

ADR-016 adds Today → For you, a device-local member selector, direct assigned-shopping completion, an on-device summary/fallback and opt-in background assignment alerts. Requires updated APNs provisioning. Physical two-account background delivery and real-device Foundation Models output remain unverified. This development change is not part of TestFlight build 3.

2026-09-13 development refinement: saved-store chips are visible before typing; inline selection persists/reuses the store immediately; general Quick Add groceries now also show autocomplete; Add uses a compact 44-point-minimum capsule. These changes still require a new TestFlight upload.

### Pending: home grocery inventory

ADR-017 adds name-first home grocery inventory, optional pack/store/date details, selected pantry starter ideas with on-device AI tailoring, and explicit bought-for-home versus bought-without-inventory shopping actions. Includes a new normalized InventoryItem kind; all devices sharing a home must update before inventory is used.

2026-09-13: Signed Release build succeeded and was installed directly on Ravi's iPhone, preserving the Production CloudKit configuration. No TestFlight upload was performed. Simulator validation: 102 unit tests and four distinct UI flows passed; inventory screenshots were inspected. Live two-account delivery and real Foundation Models generation remain unverified. See `visual-review/inventory-design.md` for evidence and artwork.

2026-09-13: ADR-018 ingredient alias/duplicate review update built in Release and installed directly on Ravi's iPhone. Simulator build, 107 unit tests and the duplicate warning/separate-pack/removal UI flow passed. No TestFlight upload. Foundation Models comparison quality on physical devices remains unverified.

2026-09-13: ADR-019 visual pantry shelves installed directly on Ravi's iPhone after successful signed Release build. Includes colorful offline icons, category filters, List switch and optional on-device categorization for unfamiliar names. 109 unit tests passed; targeted classification rerun and full visual-pantry UI flow passed. No TestFlight upload. Real AI output quality remains unverified.

2026-09-13: ADR-020 inventory attention and shopping shelves built in Release and installed directly on Ravi's iPhone. New optional low-stock flag joins the private/shared inventory payload; old payload compatibility and fake-server propagation tested. 112 unit tests and three UI flows passed, including dark-mode attention. New development-time shopping artwork is bundled. No TestFlight upload; live two-account delivery and real model quality remain unverified. Receipt/file cloud support remains a separate limitation noted in ADR-020.

2026-09-13: Shopping duplicate-comparison parity built in Release and installed directly on Ravi's iPhone. Add/Edit and household Quick Add support offline aliases/typos, optional on-device comparison, explicit separate purchases and review/removal of existing pending duplicates. All 113 unit tests and the complete shopping duplicate UI flow passed; screenshots inspected. No TestFlight upload. Live model quality remains unverified.

2026-09-13: Fixed automatic duplicate inventory creation from shopping completion. Existing ingredient matches now require keeping the existing entry or explicitly adding a separate pack; repeated stocked purchases do not recreate inventory. Signed Release build installed directly on Ravi's iPhone. 114 unit tests and the existing-Milk transfer UI flow passed; screenshot inspected. No TestFlight upload or destructive cleanup of existing packs.

2026-09-13: Multiple existing inventory matches now show one Use existing action, with a saved-pack picker and confirmed accidental-duplicate removal. All 114 unit tests and the final two-Milk cleanup UI flow passed; screenshots inspected. Signed Release build installed and launched directly on Ravi's iPhone. Existing user packs were not automatically deleted. No TestFlight upload.

2026-09-13: Corrected shared shopping/inventory icons for bananas, water and common produce plurals, with preparation-aware precedence. All 115 unit tests passed and signed Release build succeeded. Installed directly on Ravi's iPhone; no TestFlight upload. Icon rules were tested automatically; a fresh device screenshot was not captured for this correction.

2026-09-13: Unified shopping/inventory category chips, counts and AI/reset controls. Reset returns to All and cancels pending organization. All 115 unit tests and category-selection/reset UI checks passed; screenshots inspected with synthetic AI hints. Signed Release build installed and launched on Ravi's iPhone. No TestFlight upload, schema change or live AI quality verification.

2026-09-13: Corrected hidden AI controls: Organize/Reset remain visible with explanatory unavailable states in shopping and inventory. All 115 unit tests and both targeted UI flows passed. Signed Release installed and launched directly on Ravi's iPhone; no TestFlight upload.

2026-09-13: Shopping content-first layout installed and launched directly on Ravi's iPhone. Compact summary, Filters & AI sheet, visible category chips and single toolbar Add action replace the tall controls stack. Accessibility text stacks controls and is propagated into the scrollable sheet. 115 unit tests passed; simulator UI checks and screenshot reviews completed for iPhone and iPad at standard and accessibility text sizes. No TestFlight upload.

2026-09-13: Redesigned Filters & AI with themed cards, explicit filter labels and an actionable category status. Known-only items now provide Check categories feedback without a model call; AI applies to unfamiliar names; Reset appears when meaningful. 115 unit tests, automatic feedback, synthetic suggestion/reset and iPhone/iPad accessibility flows passed. Final signed Release installed and launched on Ravi's iPhone. No TestFlight upload; real Foundation Models output remains unverified.

2026-09-13: Inventory now matches shopping's compact summary, shared Filters & AI / Ideas / List-Shelves action bar and category chips. Inventory-specific filters/AI/duplicate review moved into its matching tools sheet; item expiry/low-stock badges remain. 115 unit tests and iPhone standard/large-text parity, synthetic AI reset and iPad large-text parity flows passed. Signed Release installed and launched directly on Ravi's iPhone. No TestFlight upload.

2026-09-13: Shared larger-artwork header replaces the 64-point thumbnail in shopping/inventory. 115 unit tests, standard/large-text iPhone and standard iPad UI flows passed. Signed Release build succeeded for generic iOS. Direct installation is pending because Ravi's iPhone is unavailable; no TestFlight upload.

2026-09-13: UI polish aligns card tops, spaces shared actions, blends header artwork edges and fixes shopping hero/AI button contrast in dark mode. iPhone dark and accessibility UI checks plus full-screen iPad landscape checks passed; screenshots inspected. Signed Release build succeeded. Direct installation remains pending because Ravi's iPhone is unavailable; no TestFlight upload.

## Shopping and inventory refinement — 0.1.0 (4)

September 13: XcodeGen generation and signed Release archive succeeded. Archive:
`~/Library/Developer/Xcode/Archives/2026-09-13/LunaHearth-CleanShopping-Build4.xcarchive`.
Xcode Organizer confirmed “LunaHearth 0.1.0 (4) uploaded.” Apple processing completed,
and build 4 was added to the existing LunaHearth Beta internal group. App Store
Connect confirmed 0.1.0 (4) as Testing, with 2 testers and 4 builds in the group.
Ravi's existing tester membership was verified. No new tester access or public App
Store release was created.

This build includes the post-build-3 work above: guided store/amount/date entry,
assigned shopping, grocery inventory, duplicate review and safer shopping-to-pantry
transfer, expiry/low-stock indicators, corrected food icons, and matching shopping
and inventory layouts with larger artwork and compact Filters & AI sheets.

Affected entities are household shopping items, private stores, members and inventory
packs. Local/offline storage remains primary; optional private/shared CloudKit uses
the existing Production schema. No public household database, new server, runtime
network AI, login or permission prompts were added for this release. All members of
a shared home must update before using the new inventory entity.

Validation carried into this archive: all 115 unit tests passed; targeted UI checks
and screenshot inspection covered iPhone, accessibility text, dark mode and iPad
landscape. Release archiving succeeded after the build-number increment. Real-device
Foundation Models quality, a physical upgrade from TestFlight build 3 and live
two-account Production CloudKit delivery remain unverified.

## Filters & AI redesign — 0.1.0 (5)

September 13: unified shopping and inventory tools with full-width cards, inline
native filter menus, compact category actions and colorful transparent artwork.
Similar-item review and optional category explanations have their own rows.
The sheet adapts to iPad, dark mode and accessibility text. No schema, CloudKit
transport, permissions or runtime network behavior changed.

XcodeGen generation, simulator build, all 115 unit tests and five UI flows passed.
Screenshots were inspected across the supported layouts. The accessibility flow
also passed after a final decorative icon correction. Signed Release archive:
`~/Library/Developer/Xcode/Archives/2026-09-13/LunaHearth-GroceryTools-Build5.xcarchive`.
Build 5 was installed and launched directly on Ravi's iPhone, retaining the
Production CloudKit entitlement. Xcode Organizer confirmed "LunaHearth 0.1.0 (5)
uploaded." Apple processing completed and the build was added to the existing
LunaHearth Beta group. App Store Connect confirmed 0.1.0 (5) as Testing, with
2 testers and 5 builds. No new tester access or public App Store release was added.

See `visual-review/grocery-tools-redesign.md` for artwork, behavior and validation
details. Model quality and live two-account synchronization were not tested by
these UI checks.

## Direct device update — 0.1.0 (6)

September 13: fixed repeated shopping shelf Edit/Delete actions and a row-context
menu that could target a neighboring card. Each shelf item now has one explicit
More menu; List rows retain swipe actions. Inventory's direct pack editor is
unchanged. No data, sync, schema or permission behavior changed.

All 115 unit tests passed. The final two UI regressions passed, verifying a single
menu, editing the selected Tomatoes card rather than its neighbor, no shelf swipe
actions and one set of List-row swipe actions. The menu screenshot was inspected.
Signed Release build 6 succeeded and was installed directly on Ravi's iPhone.
This correction has not been uploaded to TestFlight; build 5 remains distributed.

## Direct device update — 0.1.0 (7)

September 13: redesigned Today with sage home artwork, Buy / Use soon / Restock
priorities, duplicate-protected restock, and an optional aggregate-only on-device
daily brief with a deterministic offline fallback. The wide layout uses three
priority panels; accessibility text reflows the heading and omits decorative art.

120 unit tests passed, along with Today purchase, restock, pantry editor, empty
state, personal shopping, dark, large-text, and landscape iPad UI flows. Signed
Release build 7 succeeded and was installed on Ravi’s iPhone with the Production
CloudKit entitlement. Automated launch was blocked because the phone was locked;
open the installed app after unlocking. This build has not been uploaded to
TestFlight. Live two-account sharing and real on-device model output remain
unverified. See `visual-review/today-design.md`.

## TestFlight update — 0.1.0 (8)

September 13: Today redesign plus separately opted-in task/chores assignment
alerts in For you. Shopping alerts remain independently controlled. No shared
schema or record-type change. 122 unit tests passed, including alert opt-in,
historical baselines, completion/reopening and durable deduplication. Both the
new task completion UI flow and existing personal shopping completion flow
passed; the For you screenshot was inspected.

Archive: `~/Library/Developer/Xcode/Archives/2026-09-13/LunaHearth-TodayAssignments-Build8.xcarchive`.
Xcode Organizer confirmed 0.1.0 (8) uploaded. Apple processing completed, and the
build was added to LunaHearth Beta, where App Store Connect showed Testing.
The group now has three internal testers, including both requested iCloud
accounts; the iPad account is Invited. During this work the user changed the
App Store Connect session and added that account to the internal group.

A separate external group named Ravi Home was created with the requested tester
name Ravi Home. It has no build and is unnecessary for the now-available internal
route. Beta description saved; review-contact submission was interrupted when
the user changed the page. No external review was submitted, no public link
created, and no developer/admin role was granted by the agent.

Both physical devices were detected and unlocked, but Device Hub control timed
out repeatedly. Live invitation acceptance and cross-account APNs were not
verified. Permanent data deletion scope remains awaiting user confirmation;
no local or CloudKit household data was deleted. See `TWO_DEVICE_TEST.md` for the
fresh-home test procedure and explicit limitations.

## Direct device update — 0.1.0 (9)

Per user preference, future updates install directly on iPad and iPhone unless
otherwise requested. Build 9 adds cold/warm invitation callback handling,
invitation-first root presentation, visible errors before home creation, and
Join an existing home with validated iCloud-link lookup and already-joined-home
discovery. This responds to the real build 8 report of an invitation opening
Get Started. The exact physical callback failure remains unverified.

125 unit tests passed, including joining a fresh local store through a fake
shared server. Invitation precedence/fallback and empty Today UI flows passed;
screenshots 103/104 were inspected. Signed Release build 9 installed on both
Ravi’s iPad and Ravi’s iPhone using the Production CloudKit entitlement.
No local or cloud data was erased. TestFlight remains build 8. Retry the existing
household invitation on the phone to verify the real iCloud flow.

## Direct device update — 0.1.0 (10)

Adds automatic invitation routing for web-browsing activities and scene URL
contexts, including cold launch and resumed-app paths, alongside the existing
CloudKit metadata flow. Only validated iCloud share links reach metadata lookup;
no automatic clipboard access or new sharing boundary. The user confirmed
joining through build 9's manual link fallback, but direct Mail/Messages handoff
still requires a physical retry.

127 unit tests and the invitation-priority UI flow passed. Signed Release build
10 succeeded. Installation confirmed on both Ravi’s iPad and iPhone; no data
reset or TestFlight upload. TestFlight remains build 8.

## Direct device build 11 — named family invitations

Installed directly on Ravi’s iPad and iPhone, without deleting local/cloud data.
Owner sets names and recipient iCloud email in More → iCloud & sharing → Invite
family; recipient profile automatically selected after sync. No TestFlight upload.
Simulator build + 130 unit tests + iPhone named invitation UI test passed. Signed
Release build passed (Production CloudKit, development APNs). iPad automation
reached the form but stalled entering email; physical iPad was locked at launch.
Real two-account lookup/linking and notification delivery remain user test steps.

## Direct device build 12 — More redesign

More now groups family/sharing, Apple connections, storage/preferences and the tour
into compact cards on a subtle teal canvas with home photography. Wide layouts
use two columns; accessibility sizes use one column without decorative hero art.
Privacy explanations and warranty preferences moved into focused detail screens.
Existing routes and identifiers remain available; family route tests use its ID.
No household data/schema, cloud sharing or permission changes.

Simulator build and 130 unit tests passed, plus navigation checks on iPhone and
iPad and a dark/large-text check on iPhone. Screenshots inspected and saved in
visual-review/More-Redesign-*.png. The fixture intentionally has unavailable iCloud
and therefore shows the existing sync status banner. Signed Release build passed.
Build 12 installation succeeded directly on both Ravi’s iPad and Ravi’s iPhone.
No TestFlight upload and no local or cloud data deletion was performed.

## Direct device build 13 — clear Family flows

Family now shows a family roster, device-linked You marker, and an owner invitation
entry that opens the existing named invitation flow. The separate Add someone
without a device sheet preserves offline profiles without presenting a manual form
as the primary path. Local, participant, paused, read-only and recovery states have
appropriate direction. Soft avatar graphics and a wide two-column layout match More.

Visual QA also found a large-text icon overlap and the root iCloud warning obscuring
navigation; both were corrected. The warning now takes its own space above the
navigation container. No model/schema, CloudKit operations or permission changes.

Simulator build and 130 unit tests passed. UI tests passed for owner invitation,
offline profile creation, large/dark text and invitation-first onboarding. Final
phone screenshots were inspected and saved in visual-review/Family-Redesign-*.png.
Signed Release build passed; build 13 installed directly on Ravi’s iPad and iPhone.
No TestFlight upload or household data deletion. Physical cloud invite delivery
remains a separate user test; these checks validate UI and local behavior.
Final iPad owner-invitation navigation test also passed; its screenshot was inspected
and saved as Family-Redesign-iPad.png. Both the iPad tab bar and Family back control
are visible with the iCloud warning displayed.

## Direct device build 14 — send invitations explicitly

The prior named flow prepared a CKShare but did not send an email. Continue to send
now opens a pre-addressed Apple Mail composer when configured, or the system share
sheet for Messages/other apps. Sending remains an explicit user action. Status
copy distinguishes ready, cancelled, copied and handing off to another app; it
never claims actual arrival or acceptance. Ready links remain available for retry.

Family's Invitations & access opens Apple sharing directly, without the intermediate
settings page. Local enablement uses an explicit private-upload confirmation;
connection repair still routes to settings only for paused/recovery homes.

131 unit tests passed, including paused-sharing preparation rejection. iPhone UI
checks passed for the unavailable form, prepared/not-sent display, native share
sheet cancellation and retry. iPad checks also passed for Family → named invitation
and native share sheet cancellation. No test email was sent; Mail composer sending,
actual message arrival and recipient acceptance need the user's physical check.
Final header copy clarifies the prepare-versus-send stage. See ADR-025.
Signed Release build 14 succeeded and installation was confirmed on both Ravi’s
iPad and iPhone. No TestFlight upload, actual outbound message, or data reset.

## Direct device build 15 — one Family entry (2026-09-13)

Installed and verified version 0.1.0 (15) on the owner iPad and Ravi iPhone. Production CloudKit Release configuration retained; no data reset or TestFlight upload. More → Family is the single invitation destination. Removed competing invitation controls from the technical iCloud sync & data page. Background sync no longer disables invitation form editing; named preparation waits up to 30 seconds for busy work, revalidates destination/access, and surfaces errors in an alert.

Read-only owner iPad diagnostics before installation showed one home, enabled owner sync, no recovery/read-only flag, no recorded conflicts and zero members. This is saved-state evidence only, not proof of live CloudKit service availability. Temporary diagnostic copies were deleted. No outbound invitation was sent and recipient delivery/acceptance remains a live-device test.

Signed device build passed. iPhone simulator: 131 existing unit tests and three UI tests passed (single navigation, error/retry, native send cancellation). Screenshot review confirmed the single Family entry and readable name/email invitation form.

## Direct device build 17 — Apple invitations and automatic profiles (2026-09-13)

Supersedes builds 15/16. Release build 17 installed directly on both physical devices, preserving Production CloudKit and all local data. Both launch attempts were blocked by device lock; live invitation delivery and profile synchronization remain to verify after unlocking. No message was sent by the agent.

The user confirmed Apple's email/Messages sharing works for the intended recipient, while the custom lookup rejects it. Family → Invite someone now opens the native Apple sharing panel without email discovery. Verified writable sync/import automatically creates/reuses the device account's household-scoped profile. Owner can set the shared display name with the pencil in Family; renaming keeps assignment IDs stable. A profile is created after joining, not proof that an invitation was delivered. Existing named profiles are preserved.

Validation: signed Release build succeeded; 134 unit tests in 23 suites passed, including native joining, admin naming sync, same-account devices, stable task assignments, no email discovery, and busy-sync invitation handling. Three iPhone UI tests passed: native-share failure/retry, profile renaming, and More navigation. iPhone screenshot inspected. No TestFlight upload or destructive migration.

Build 17 iPad simulator: large Dynamic Type/dark Family flow and owner profile renaming both passed; large-text screenshot inspected.

## Direct device build 18 — pantry idea clarity (2026-09-13)

Installed and verified build 18 on owner iPad and Ravi iPhone. The user separately confirmed assignment syncing works between owner and participant. This update is confined to pantry suggestions, explicit on-device AI outcomes, tests and copy. No data reset, schema change, or sharing/assignment change.

The previous What's already at home heading described suggestions, not saved inventory. It now says Starter suggestions / AI suggestions, with an independent saved-ingredient count. AI unavailability and failures no longer silently return an unchanged starter list without a meaningful reason. Typed requests are bounded; changing cooking style cancels/discards stale responses; household switching dismisses the scoped sheet.

Signed Release build and 135 unit tests passed. iPhone UI checks verified empty pantry ownership copy, explicit non-AI fallback status, duplicate exclusion and selected-only additions. Screenshot inspected. The first UI attempt exposed an outdated test setup helper that skipped the now-required home name; it was corrected and both flows passed. Actual Foundation Models generation on the physical iPad is not claimed verified; UI tests intentionally exercise the deterministic unavailable-model fallback.

## Direct device build 19 — visible pantry AI feedback (2026-09-13)

Supersedes build 18, installed on both physical devices. The build 18 iPad UI check caught a real presentation issue: the fallback explanation existed below the visible sheet and was not discoverable without scrolling. ScrollViewReader now brings the result section into view when generation finishes. The iPad empty-pantry/AI feedback check passed on build 19. Release build succeeded; underlying pantry rules/service unit validation remains the 135-test build 18 run. Live Foundation Models inference is not claimed verified.

Build 19 iPad result screenshot inspected: the result and starter suggestions are visible after Tailor. The additional saved-Rice iPad test was interrupted after repeated minute-long simulator idle/remote accessibility waits; it is inconclusive on iPad. That selected-addition flow passed on iPhone in build 18. Do not report the entire build 19 iPad suite as passed.

## Direct device build 20 — kitchen templates and unified canvas (2026-09-13)

Installed build 20 directly on owner iPad and Ravi iPhone. No data reset or TestFlight upload. South Indian, North Indian and American basics templates each offer 100+ ingredients; Everyday basics offers 60. Search, select-all/category selection, review and remove-before-confirm replace repetitive individual entry. Saving no longer truncates at 24 names; the validated maximum is 150. Existing active aliases are skipped and no quantity/date/store is invented. Optional on-device AI supports up to 100 proposed names; live inference quality remains unverified.

Home sidebar and detail now share the active pantry peach or shopping green canvas. A per-tab presentation coordinator restores the previous color on Back. Inspected iPad screenshots show pantry → shopping → pantry colors matching across both panes.

Final signed Release build succeeded. Final 136 unit tests passed; full-size template insertion, replay deduplication and name-only metadata checks included. Bulk select/review/remove/add UI flow passed on iPhone and iPad. iPad forward/back palette transition passed and screenshots were inspected. No assignment or sharing protocol changed.

## Direct device build 21 — Home organization (2026-09-13)

Reorganized Home into Groceries, Rooms (including Floor plan), expandable Belongings and Home care. Removed duplicate root room/item setup prompts; floor management lives in Home settings. Existing offline persistence and optional private sharing are unchanged.

Validation: xcodegen; simulator build; 136 unit tests; room creation/navigation on iPhone and iPad; iPad pantry/shopping/back canvas regression. Results: `/tmp/LunaHome21.xcresult`, `/tmp/LunaHome21Pad.xcresult`. Both test runs succeeded. Reviewed exported Home overview screenshots on both sizes and saved under `docs/visual-review/Home-Organized-*`. Release device build succeeded (`/tmp/luna-home21-device.log`), and direct installation succeeded on both the owner iPad and Ravi iPhone. No household data reset. Live CloudKit and physical-device interaction were not repeated for this presentation-only change.

## Direct device build 22 — shopping restocks low inventory (2026-09-13)

Restock existing now clears the selected inventory entry's Low stock flag atomically with shopping completion. Amount and dates remain explicit; no duplicate entry is created. Repeated purchases preserve a later low-stock flag, and finishing for someone else does not change stock. The existing inventory disposition is retained after reopening as evidence the purchase already stocked inventory.

Validation: xcodegen and simulator build; 139 unit tests passed (`/tmp/LunaRestock22.xcresult`), existing-item purchase UI passed (`/tmp/LunaRestock22UI.xcresult`); screenshot inspected. Release device build passed. Installed and verified version 22 on both owner iPad and Ravi iPhone. No data reset. Live cross-device sync delivery was not repeated; this uses the existing inventory backup/sync field and its modified timestamp.

## Direct device build 23 — reviewed receipt photo import (2026-09-13)

Shopping and Pantry now expose Scan receipt. PhotosPicker and Apple's document camera feed on-device Vision OCR, followed by editable selection, shopping matching and inventory destination review. Confirm creates/updates bought shopping rows and adds new inventory or clears existing low stock atomically. Existing amounts/expiry are preserved. Optional GroceryItem.receiptImportKey is included in backup/sync for repeat-import detection; update household devices together. No receipt photo/text is retained or uploaded, and no data reset was performed.

Validation: xcodegen; simulator and Release device builds; 147 unit tests passed in `/tmp/LunaReceipt23Pad.xcresult`, including actual Vision recognition of a rendered receipt, atomic imports, exclusions, duplicate/replay protection, backup round-trip and read-only rejection. Final UI checks passed on iPhone with normal/large text (`/tmp/LunaReceipt23FinalPhone.xcresult`) and iPad (`/tmp/LunaReceipt23FinalPad.xcresult`). Exported review screenshots were inspected and saved under `docs/visual-review/Receipt-Review-*`. Final Release log: `/tmp/luna-receipt23-devicefinal.log`. Direct install succeeded and installed build 23 was verified on owner iPad and Ravi iPhone. Actual retailer photos, hardware camera permission and live cross-device sync delivery remain real-device checks; UI fixtures are not evidence for those.

## Direct device build 24 — Home Expenses and monthly reports (2026-09-13)

Home → Expenses now provides a lavender monthly dashboard: gross spending, refunds/net, currency-separated totals, six-month chart, category breakdown, searchable/editable purchase history and a complete-month CSV export. Manual expenses/refunds stay independent of inventory. Receipt imports optionally save a reviewed expense in the same local transaction as shopping/inventory updates. Existing totals are never inferred from old shopping history. Saved expenses return to the recorded month/currency and clear history filters so the result is visible.

New HouseholdExpense entity participates in local persistence, normalized backup, explicit private/shared sync, conflict handling, global ID protection and tombstones. This adds the model without destructive migration; older clients cannot interpret the new kind, so all household devices must upgrade. ADR-029 records the user-approved financial tracking scope and privacy behavior.

Validation: xcodegen; simulator build; 155 tests in 25 suites passed (`/tmp/LunaExpense24Pad.xcresult`), including decimal money, monthly currency separation, refunds, receipt atomicity/replay, backup, CSV safety and fake-server household expense update/delete propagation. Final phone UI tests passed at normal and large/dark text sizes (`/tmp/LunaExpense24FinalPhone.xcresult`); final iPad dashboard and integrated receipt UI tests passed (`/tmp/LunaExpense24FinalPad.xcresult`). Exported phone/tablet/dashboard screenshots were inspected; an initial color-asset encoding error was corrected before final verification. Screenshot evidence is saved as `Expenses-Monthly-iPhone.png`, `Expenses-Monthly-iPad.png`, `Expenses-Large-Dark-iPhone.png` under `docs/visual-review`.

Final Release build succeeded (`/tmp/luna-expense24-deviceverified.log`). Build 24 installed successfully and version was verified on owner iPad and Ravi iPhone. No household reset. Simulator workflows use test records; physical camera, real retailer accuracy, actual file destination export and live two-account CloudKit delivery were not repeated here.

## Direct device build 25 — shopping stores in Expenses (2026-09-13)

Expense entry and receipt review now show saved household shopping-store suggestions, plus the existing Browse shopping stores picker. Canonical store spelling is reused at save time, including branch labels. Arbitrary payees remain valid without being inserted into ShoppingStore. No schema or cloud change.

Validation: xcodegen and simulator build; 156 unit tests passed (`/tmp/LunaExpenseStores25.xcresult`). Saved-store selection and expense save passed on iPhone and iPad (`/tmp/LunaExpenseStores25Pad.xcresult`). The iPhone screenshot was inspected and saved as `docs/visual-review/Expense-Shopping-Store.png`. Release device build succeeded (`/tmp/luna-expense-stores25-device.log`). Direct installation succeeded on owner iPad and Ravi iPhone; no data reset. Live cross-device delivery was not repeated for this reuse of the existing store directory.

## Direct device build 26 — receipt name AI
- Added optional on-device generative decoding of abbreviated receipt item names, with individual review/acceptance, cancellation and manual fallback. No schema change; no network LLM.
- Validation: 158 unit tests in 26 suites passed, plus iPhone receipt review/import. iPad normal and large-text UI tests exercised Decode names with AI, explicit test-unavailable feedback, and successful receipt import. Simulator screenshots inspected; deterministic UI tests do not run the real model.
- Release build succeeded; installed directly and verified version 0.1.0 (26) on owner iPad and Ravi iPhone. No TestFlight upload in this task.
- Real Costco receipt decoding accuracy and device Apple Intelligence readiness remain to be checked by the user. No claim of live AI, camera or CloudKit revalidation.

## Direct device build 27 — linked purchase history
- Home → Purchase history groups purchased items, expense links, shopping status and inventory/restock destinations. Expense and inventory editors expose history; receipt completion opens the linked purchase directly.
- Receipt import writes history atomically. Optional reviewed item totals use integer minor units. Shopping purchases can receive a linked expense later without repeating stock actions; deterministic expense IDs protect the same group's offline creation. Historical snapshots survive deletion of linked records.
- Final 162 unit tests in 27 suites passed, including fake-server sharing and backup/restore. Receipt → purchase → expense UI tests passed on iPhone and iPad simulators, including iPad large text. Final compact header inspected on iPhone. Release build succeeded and build 27 installed directly on owner iPad and Ravi iPhone.
- Physical devices were locked; user was asked to unlock for a live UI test. Physical UI and live CloudKit verification remain pending. No TestFlight upload or user-data reset.
- Limits: history starts with new purchases; optional line prices require review/manual entry; free-text stock quantities are not added arithmetically. Restocks clear Low stock and record purchased quantities while retaining pack amount/expiry.

## Direct device build 28 — purchase UI and accessibility polish
- Purchase history cards show item previews, dates and totals. Details use illustrated item cards, a compact receipt summary, progressive disclosure and a side-by-side layout at sufficiently wide window sizes. Expense charts/amounts adapt to accessibility text; receipt introductions are shorter.
- Native text scales without a cap, important actions have explicit labels and 44-point targets, decorative graphics are hidden from accessibility, and Increase Contrast strengthens card borders. Test-only Dynamic Type overrides now reach presented sheets and their adaptive layout environment.
- UI tests passed for iPhone standard receipt flow, actual accessibility-sized receipt/purchase sheets, and large-text/dark expense dashboard; iPad landscape navigation through purchase history and large-text flow also passed. iPhone standard and enlarged-text screenshots inspected. The iPad landscape screenshot export had rotated/cropped framing, so landscape navigation success is not a complete visual audit.
- Release build succeeded. Version 0.1.0 (28) installed directly on owner iPad and Ravi iPhone. No data-model or sync changes. Physical devices remained locked during testing; live VoiceOver, keyboard/Switch Control and device UI checks remain pending. No undocumented Duo API or device compatibility claim is introduced.

## Direct device build 29 — connected demo
- Home → Try the connected demo uses an isolated in-memory home with shopping items and low-stock curd. Load a synthetic receipt through real Vision OCR, review/save, inspect linked expenses/pantry and manually preview tomorrow's pantry-matched sample meal cards. Missing ingredients can be added to demo shopping. A five-second-per-stage animated document marker has pause/replay/manual controls and a Reduce Motion fallback.
- Receipt review now supports optional explicit pack expiry, including selected restocks. Existing dates stay unchanged unless reviewed. Stale shopping aggregate notifications are cleared when completed/removed items are observed.
- 165 unit tests in 28 suites passed, including sample-image OCR → expense/shopping/inventory links, expiry validation/preservation/update and partial shopping completion notification clearing. End-to-end demo UI tests passed on iPhone and iPad simulators. Inspected sample receipt and iPhone flow screenshots. Final playback label shortened to Replay for clearer spacing.
- Demo meal ideas are curated examples, not generated recipes. The 5 PM preview does not schedule real notifications or run background AI. Household data and CloudKit are not touched by the demo. Saving the sample image outside the demo and confirming an import can create real records.
- Release build and direct-device install use version 0.1.0 (29). Physical UI testing remains pending because both devices are locked. No TestFlight upload.

## Direct device build 30 — continuous connected-demo animation
- Replaced highlighted step cards with a continuous 25-second vector animation: receipt scanning, branching amounts/items, shopping completion, pantry jars and meal ingredients. Playback starts immediately; Pause and Next scene remain available. Reduce Motion provides manual still scenes with scalable explanatory text.
- The illustration has no database access. The working receipt demo retains its separate in-memory repository, with no main-household or CloudKit writes. Sample animation values are explicitly illustrative. No model or sync changes.
- iPhone end-to-end receipt demo and automatic/manual animation tests passed (`/tmp/LunaAnimation30.xcresult`); iPad automatic/manual animation test passed (`/tmp/LunaAnimation30Pad.xcresult`). Exported iPhone and final iPad screenshots were inspected; final iPad evidence is `docs/visual-review/Animated-Demo-iPad.png`. Simulator and Release builds succeeded; diff whitespace checks passed.
- Direct installation succeeded and version 0.1.0 (30) was verified on owner iPad and Ravi iPhone. No TestFlight upload or household data reset. Physical UI, VoiceOver and live sync were not revalidated; devices were last observed locked.

## Direct device build 31 — real pantry meal planning
- Lists → Meal ideas, Home → Groceries → Meal ideas and Today → Plan meals open the real household screen. Get suggestions now uses eligible pantry names, optional on-device structured generation and labelled built-in fallback. Review & plan saves through the existing meal editor/repository; saved plans open on the selected day. Demo remains separate.
- Optional device-local 5 PM repeating notification opens Meal ideas. Enabling asks for notification permission; disabling clears the reminder. This prompts foreground generation, not background AI. No schema, cloud transport or stock mutation changes.
- 170 unit tests in 29 suites passed, including pantry ranking, expiry/used-up filtering, proposal bounds, civil-time DST calculation and real repository meal persistence. Final suggestion/review/save UI tests passed on iPhone and iPad. Inspected screenshots; final iPad evidence is Meal-Ideas-iPad.png. Release build succeeded.
- Physical on-device model quality, notification delivery/tap routing and VoiceOver were not exercised. No claim of live CloudKit revalidation. No TestFlight upload or household data reset.
- Final build 31 installed directly on Ravi iPhone and owner iPad (iPad connection allocation error cleared on retry). Home entry sits under Groceries. iPhone installed version verified as 0.1.0 (31).

## Direct device build 32 — meal cuisine and preferences
- Meal ideas asks for a cuisine in a clean native dropdown with 18 choices. Selected style is remembered locally on the device and filters built-in suggestions as well as guiding on-device AI. An optional bordered multiline field accepts up to 400 characters of cooking context, with character count and keyboard Done.
- Inputs invalidate old results. Results scroll into view after generation. Fallback explicitly states extra notes were not applied. No schema, cloud synchronization or notification changes.
- Seven meal-domain tests passed, covering cuisine filtering and context bounds alongside pantry/date/persistence rules. iPhone style → context → suggestions → review → saved meal UI flow passed after fixing result visibility; screenshot inspected. Real model quality remains a physical-device check.
- Final iPad cuisine/context/review/save UI test passed; preferences screenshot inspected and saved as Meal-Preferences-iPad.png. Release build 32 installed directly on owner iPad and Ravi iPhone. No TestFlight upload or main-data reset. Physical AI/notification/VoiceOver verification was not repeated.

## Direct device build 33 — cook a meal and review pantry use
- Saved meals open Cook this meal: ingredients, existing pack amounts/editing, selected missing ingredients to Shopping, preparation tasks and editable recipe steps. Today links to cooking and shows the next open prep task. Review/save includes servings and ingredient/step fields; on-device ideas can propose steps.
- Measured pantry entry supports g/kg/oz/lb, ml/l and pieces using decimal arithmetic. Finish defaults packs to unchanged and previews measured remainders; optional low-stock/used-up actions remain available. Local completion atomically saves selected pack changes, cooked status and preparation-task completion. Repeated completion and stale reviews are rejected.
- Optional timed preparation alerts are device-local, permission-gated and open the linked meal. Tasks persist/share as normal household records. Observed completion/deletion clears previously scheduled alerts; remote offline changes require sync before they can cancel an alert.
- Additive optional MealPlanEntry recipe/servings/cooked fields and HouseholdTask.mealID map through existing backup/custom CloudKit payloads. Upgrade household devices together; older clients do not preserve new fields. No household reset. Simultaneous offline pack edits still follow existing record conflict handling, not a distributed stock ledger.
- 177 unit tests in 30 suites passed, including decimal conversions, incompatible/excess use, stale snapshots, local completion idempotency, duplicate shopping and backup round-trip of cooked meals/prep/stock. Complete iPhone and iPad simulator workflows passed. The iPhone stock-review screenshot was inspected. Physical notification delivery, model quality and VoiceOver remain separate checks.
- Final compact stock review passed on iPhone; final pantry-colored cooking cards/stock review passed on iPad. Final iPad screenshot inspected and saved as Cooking-iPad.png. Release build 33 installed directly on owner iPad and Ravi iPhone. No TestFlight upload. Live shared-device conflicts, actual timed notification delivery and on-disk upgrade UI were not independently exercised.

## Direct device build 34 — Home dashboard, shopping status and category cleanup
- Home is a visual dashboard with illustrated Pantry / What you have and Shopping / What to buy cards, Meals, a separate rooms workspace and spending/care tiles. Rooms retain adaptive split navigation; the Home landing no longer has an empty detail/sidebar arrangement.
- Meal ingredients and idea cards show Already in shopping using current pending items and alias matching. Already-listed ingredients are excluded from add selection; adding updates the visible status and offers View shopping list.
- More → Danger Zone offers independent pantry, shopping, meals, expenses and task cleanup. Counts, household scope, linked preparation tasks, sync/backup implications and typed CLEAR precede deletion. Local snapshots prevent clearing new records added during review. Existing read-only restrictions apply. Purchase history and unrelated areas remain; tests use isolated synthetic data only.
- 180 unit tests in 31 suites passed. iPhone and iPad UI tests passed for dashboard, room navigation (iPad), cancelled/confirmed cleanup, and the complete meal/shopping/cooking flow with live Already in shopping status. Home and cleanup screenshots inspected. No schema change or real household cleanup. Cross-device deletion delivery and physical accessibility were not revalidated.
- Final iPhone dashboard/room navigation/cleanup test passed after constraining food artwork to each card width; final screenshot inspected. Cleanup counts use packs, items or meal plans. Release build 34 installed successfully on owner iPad and Ravi iPhone. No TestFlight upload.

## Direct device build 35 — Meals card tap fix
- Home Meals now responds across its entire card, including empty space. Rooms & belongings receives the same explicit touch boundary. No data or permission changes.
- Reproduced a failed coordinate tap in blank card space on iPad before the fix; the same test passed after the fix on iPad and iPhone. Release build succeeded. Business logic is unchanged; the full unit suite was not repeated.
- Build 35 installed successfully on owner iPad and Ravi iPhone. No TestFlight upload or data reset. Physical-device tapping remains for user verification.

## Direct device build 36 — clearer Lists cards
- Replaced the tall Lists hero and grouped rows with compact illustrated cards for Reminders, Shopping and Meal ideas, each with explicit full-card touch bounds. Counts read the existing local repository; no domain, storage, sync or permission change.
- The reported original Lists tap failure did not reproduce in the initial iPad coordinate test. Final redesigned Meals card opens from blank-space taps in iPhone and iPad UI tests; both screenshots inspected. Full unit suite and physical VoiceOver were not repeated for this UI-only change.
- Release build succeeded and build 36 installed on owner iPad and Ravi iPhone. No data reset or TestFlight upload.

## Direct device build 37 — meal plans, ingredients and preparation clarity
- Saved plans now use day-based cards with meal type, servings, ingredient counts and cooked state. Ingredient status and editable matched-pack amounts share a card instead of duplicated lists. Whole-card navigation uses explicit touch regions.
- Preparation is now labelled Prep reminders, with an explanation when no advance tasks exist. Cooking steps separately explains older recipes without instructions and offers Add recipe steps. Every built-in starter now includes editable instructions for new review/save proposals; existing meals remain unchanged. No schema, sync, permissions or network changes.
- Seven meal unit tests passed, including complete built-in step coverage and validation. The iPhone meal-to-shopping-to-cooking UI flow passed and screenshots were inspected. Full unit suite and physical VoiceOver/model behavior were not repeated.
- iPad complete cooking flow also passed; ingredient/prep/steps screenshot inspected. Release build 37 installed successfully on owner iPad and Ravi iPhone. No data reset or TestFlight upload.

## Direct device build 38 — quantities, weekly meals and combined shopping
- Added optional per-serving recipe amounts, stored with the meal and carried through backup/private/shared payloads. Ingredient cards scale the need by servings. Old meals keep unknown quantities; shared devices should upgrade together.
- Weekly meals provides seven civil days with breakfast/lunch/dinner slots, editable plans and a reviewable on-device/built-in draft. Existing slots are preserved. Users can swap, change servings and deselect proposals before one local atomic save. Limited candidate sets may repeat dishes; amounts are not generated.
- Separate shopping review aggregates ingredient aliases, allocates measured pantry amounts once across planned meals, excludes expired packs by meal day, and flags unknown/incompatible quantities. Pending shopping entries are shown and skipped; quantities on those existing entries still need user review. Selected shortages add shopping records only; no stock is consumed or reserved. Stale previews are rejected.
- Today links the weekly planner and shows open prep tasks for tomorrow's meals. No added notification permission or background-generation behavior.
- 188 unit tests in 32 suites passed, including DST, measured units, expiry, unknown stock, aliases, backup round-trip, atomic slot save and stale shopping review. Weekly suggestion/save/shopping/deduplication UI flows passed on iPhone and iPad; screenshots inspected. No real household cleanup. Full physical AI/VoiceOver/live shared-conflict validation and on-disk upgrade UI remain unverified.
- Final direct per-serving quantity UI tests passed on iPhone and iPad, including keyboard Done, save and 100 g × 2 servings = 200 g display. A broader iPad cooking run was interrupted while the simulator stalled typing in the existing preferences screen; the focused quantity and weekly flows passed separately. Final Release build 38 installed successfully on owner iPad and Ravi iPhone. No TestFlight upload or data reset.

## Direct device build 39 — Today imagery and aligned cards
- Reworked Today with a household-photo hero, consistent illustrated card headers, spacing and aligned action links. A measured SwiftUI Layout equalizes priority/card heights while supporting larger content; wide screens show columns and accessibility layouts use one column. Decorative art hides for accessibility text sizes. Wrapped action text aligns left.
- iPhone attention interaction and large-text tests passed; iPad dark and landscape attention tests passed. Inspected iPhone standard/large screenshots and the visible aligned iPad landscape cards; the landscape capture was offset/cropped, so full landscape visual verification is limited. Existing stock/task/meal/brief rules, privacy and synchronization are unchanged; no domain tests were added or full unit suite repeated for this UI-only change. Physical VoiceOver remains unverified.
- Final Release build 39 succeeded and installed directly on owner iPad and Ravi iPhone. No TestFlight upload or household data reset.

## Direct-device build 40 — household calendar
- Replaced the calendar form with illustrated heading, compact week navigation, real-member filters, and appointment cards. Wide layouts show month and agenda side by side.
- Existing FamilyEvent and HouseholdMember data, offline persistence, optional Apple Calendar connection/export, and CloudKit behavior remain unchanged. No household records were seeded or removed on physical devices.
- Validation: 188 unit tests across 32 suites passed; household calendar filtering/detail flow passed on iPhone and iPad simulators; iPad landscape flow passed. iPhone large-text flow passed and decorative card icons were subsequently suppressed at accessibility sizes to give appointment text more room.
- Reviewed iPhone and iPad portrait screenshots. Landscape XCTest capture has the existing offset/black-region issue, so full landscape visual verification remains limited. Physical VoiceOver and live event sharing were not re-tested.
- Final accessibility refinement re-tested successfully on iPhone; Release build succeeded. Build 40 direct installations target the owner iPad and Ravi iPhone.

## Direct-device build 41 — person-first calendar board
- Reworked Calendar around the supplied visual reference: profile initials, pastel member panels, day navigation, and time-of-day appointment illustrations. Members remain real household records; no demo data is added to production stores.
- Adds deterministic, calendar/time-zone-aware morning/afternoon/evening grouping, including appointments continuing from a previous day. Per-member + preselects that member in the existing event editor. Storage, permissions, and CloudKit mapping are unchanged.
- 190 tests in 33 unit suites passed. Calendar member filtering and detail navigation passed on iPhone and iPad; iPhone large text and iPad landscape flows passed. Reviewed iPhone standard/large-text and iPad portrait screenshots. Physical VoiceOver and live CloudKit event sharing were not re-tested.
- Release build succeeded; build number 41 verified in the app bundle. Direct installation succeeded on the owner iPad and Ravi iPhone. Existing household data was preserved.

## Direct-device build 42 — appointments and Siri
- Dedicated appointment editor with user-selected icons, bounded custom day/week/month repeats (up to 52 independent appointments), shared reminder timing, and explicit overlap confirmation. Calendar member + now passes an identifiable draft, fixing a UI-discovered loss of the selected member.
- Device-local alert opt-in and recipient selector live in Calendar settings. Alert content is generic; timing/member changes reconcile after sync. Siri/Shortcuts register two authenticated App Intents: review an appointment draft and open the family calendar. Siri never directly writes the store.
- Full unit suite: 196 tests in 34 suites passed. After the selected-member fix, the six appointment tests passed again. Complete editor/type/repeat/reminder/save/detail flow passed on iPhone and iPad simulators. App-link UI test passed, verifying Siri-style title and Kira preselection and cancellation. Release App Intent metadata includes both actions.
- Reviewed editor screenshots on iPhone and iPad. Live spoken Siri, physical-device notification delivery, VoiceOver, and two-device CloudKit sync of new optional fields were not verified.
- Release build succeeded and app bundle version 42 verified. Direct installation succeeded on Ravi iPhone. Owner iPad installation is pending: device was locked, preventing developer disk image mounting. No production household records were created or deleted.
- Follow-up: after the user unlocked the owner iPad, direct installation of the verified build 42 bundle succeeded. Build 42 is now installed on both devices.

## Direct-device build 43 — linked Apple Calendar
- Appointment editor adds explicit Apple Calendar opt-in and writable-calendar selection. Subsequent title/time/notes edits target the existing linked copy through a device-local durable outbox. Shared devices do not inherit export opt-in.
- Retry/pause/remove/forget controls appear in Calendar settings → Linked events & sync status. Linked appointment deletion distinguishes retaining the Apple copy from explicitly removing both. Identifier/marker validation and uncertain-write recovery prevent blind recreation and unrelated-event changes.
- New local CalendarDeliveryLink table is excluded from BackupCodec/CloudKit. Core saves are independent of EventKit availability. Full-access permission copy now includes linked updates.
- Full unit suite: 203 tests across 35 suites passed. The seven calendar-delivery tests passed again after final error-status handling. Checkbox/create/edit/status UI flow passed on iPhone and iPad with an isolated in-memory calendar provider; reviewed screenshots saved under docs/visual-review/Apple-Calendar43-*.
- Live EventKit permission, writable calendar enumeration, real event creation/update/deletion, Apple-account server sync, and physical-device VoiceOver were not verified. No real calendar events were created/deleted by these automated tests.
- Final Release build succeeded, bundle version 43 verified, and direct installation succeeded on both the owner iPad and Ravi iPhone. Existing household data was preserved.

## Build 44 — Family week (2026-09-14)
Installed directly on Ravi’s iPad (00008132-000218E61103001C) and Ravi’s iPhone (00008140-0004343A1E44801C), replacing build 43 in place. Release artifact CFBundleVersion confirmed 44. This was not a TestFlight upload.

Open Calendar → Family week, or Today → Family week. Existing appointments, due tasks and meals open their original screens. Plan our week provides reviewed pantry-based dinners, quicker options on busy evenings and optional linked prep tasks. Ingredient review reuses measured pantry and existing shopping matching. See ADR 038 for offline behavior, bounded scheduling and privacy.

Validation: simulator build and signed device Release build succeeded; 208 unit tests across 36 suites passed in `/tmp/Luna44PadFinal.xcresult`. Family-week navigation, person filtering, dinner/prep save and shopping review passed on iPhone and iPad. Large-text navigation passed on both. Final iPhone UI result `/tmp/Luna44PhoneFinal.xcresult`; initial iPad large-text result `/tmp/Luna44Pad.xcresult`. Screenshots were inspected for standard phone, portrait iPad columns and large text. Visual evidence is under docs/visual-review/Family-Week44*.png. No real household data was created/deleted during tests; live on-device generative model output, cross-device sync of this new flow, and notification delivery were not interactively verified.
Both installs succeeded. Automatic launch was denied because both physical devices were locked; unlock and open LunaHearth to use build 44. Installation success is not a claim of interactive physical-device validation.

## Build 45 — All-day weekly meal selection (2026-09-14)
Plan our week defaults to Breakfast, Lunch and Dinner, with individual toggles before generation. Review supports up to 21 meals and preserves existing slots. Changing meal selection clears the prior draft. Busy-evening ranking and optional prep tasks are dinner-only. Existing candidate/fallback variety and manual swap behavior remain unchanged; no schema, network or permission changes.

209 unit tests passed (`/tmp/Luna45Phone.xcresult`), including a 21-meal/7-dinner-prep atomic save. Family-week UI review/save/shopping flow passed on iPhone and iPad (`/tmp/Luna45Pad.xcresult`). Signed Release build passed; CFBundleVersion 45 verified. Build 45 installed successfully in place on both Ravi devices, with no test data written to their household. This was a direct installation, not TestFlight. On-device generative output and live sharing were not retested for this selection change.

## Build 46 — Connected functionality audit (2026-09-14)
Fixed compatible pantry restock quantity addition (including matching package counts), protection against merging fresh purchases into expired stock, and 32-bit truncation in large expense amount formatting. Purchase/receipt reviews explain quantity effects. Receipt details link to purchase history for expenses on already-recorded purchases. Pantry copy explains reviewed consumption/restocking. No schema or new network/permission change; existing quantities were not reconstructed or reset.

Full suite: 213 tests / 37 suites passed in `/tmp/Luna46Pad.xcresult`; final targeted Inventory/ConnectedPurchaseAudit rerun passed 20 tests in `/tmp/Luna46PhoneVerified.xcresult`. A real temporary on-disk SwiftData test exercised shopping restock, a separate receipt purchase, one linked expense, exact receipt replay, ingredient-shopping dedupe, measured cooking use, disk reopen, and backup restore. Compatible counts and unit conversion, unknown/incompatible amounts, expired packs, atomic rejection, read-only behavior and large money formatting were checked.

UI: monthly expense navigation, receipt-to-purchase/expense links, and measured restock passed on iPad. On iPhone, expense/receipt/weekly-shopping flows passed in `/tmp/Luna46Phone.xcresult`; the new amount test initially failed because it did not expand the editor's Details disclosure. That test was corrected, and measured restock plus existing-item duplicate protection passed in `/tmp/Luna46PhoneVerified.xcresult`. Screenshots were inspected; restock evidence saved under docs/visual-review/Restock46*.png. This is not a claim of exhaustive UI/accessibility or physical-device workflow testing.

Build 46 Release built and installed in place on both Ravi’s iPad and Ravi’s iPhone. No TestFlight upload or real-household data reset. Component test plan and remaining limits are in `docs/FUNCTIONAL_AUDIT.md`: live cross-device sync/notification delivery, concurrent offline arithmetic conflicts, and automatic reconciliation of a separately completed purchase with a later receipt are not validated/implemented by these tests.

## Build 47 — release hardening

September 14: receipt-to-purchase reconciliation, durable history replay keys, safer storage-open recovery, task-notification summary clearing, richer pantry/expense conflict review, required-reason privacy manifest and large-text pantry/receipt refinements. See ADR 040 and RELEASE_READINESS.md. No new network service, no household reset and no TestFlight or public App Store submission.

Validation:
- `/tmp/Luna47ReleaseChecks/iPhone.xcresult`: 222 domain/persistence/sync tests in 39 suites passed, plus all eight selected UI flows. Tests include actual on-disk migration from the frozen build-46 PurchaseEntry layout, receipt replay after shopping deletion, legacy payloads, offline purchase/receipt transport and simultaneous stock conflict review with two simulated repositories.
- `/tmp/Luna47ReleaseChecks/iPad.xcresult`: seven selected UI flows passed; the large-text receipt flow exposed Scan receipt being moved to native toolbar overflow. An icon-only adjustment alone did not resolve it. Scan/Add now appear within pantry content at accessibility sizes, with normal toolbar icons otherwise.
- `/tmp/Luna47PadAccessible.xcresult`: the corrected iPad accessibility receipt → existing purchase → unchanged pantry flow passed; screenshots inspected. `/tmp/Luna47PhoneFinal.xcresult` records the final iPhone receipt runs and the three rechecked migration/demo tests.
- `/tmp/Luna47AppleFramework.xcresult`: actual EventKit create/update/delete in a temporary local simulator calendar passed, including one-event identity and calendar cleanup. This used pre-granted simulator Calendar permission and is not real-account sync or permission-prompt verification.
- `/tmp/Luna47PadFinal.xcresult`: actual revoked-permission adapter/outbox test passed, retaining the local appointment and retry state. That run's earlier toolbar UI failure is superseded by PadAccessible above. The allowed-calendar test is intentionally skipped in this denied-permission run; the successful allowed run is AppleFramework above.
- Final signed Release build `/tmp/luna47-accessible-device.log` succeeded; CFBundleVersion 47 and bundled PrivacyInfo.xcprivacy checked. Final app installed directly on both owner iPad and Ravi iPhone. Launch attempts were denied because both physical devices were locked. Installation is not evidence of successful physical startup or live service checks.

Remaining release gates are explicit in RELEASE_READINESS.md: unlocked two-account CloudKit/APNs checks, Siri voice, actual permission prompts, VoiceOver and iOS 18 runtime, and current App Store Connect submission metadata/privacy review. App Store readiness is not asserted by this entry.

## TestFlight build 48 — September 15, 2026

Archived the current 0.1.0 (48) release, including four-tab navigation, the More/settings redesign and receipt/pantry hardening. Archive `/tmp/LunaHearth-Build48.xcarchive`; `/tmp/luna48-archive.log` confirms ARCHIVE SUCCEEDED. Bundled privacy manifest passed plist validation. Feature validation remains recorded in MORE_NAVIGATION.md and the build-47 entry above; no additional live household tests were claimed during upload.

Command-line export failed to use the stored App Store account. Xcode Organizer's App Store Connect distribution subsequently succeeded and explicitly confirmed “LunaHearth 0.1.0 (48) uploaded.” Processing and tester availability are separate checks recorded below when confirmed. This upload does not submit the app for public App Store release.

App Store Connect confirmed upload processing Complete for 0.1.0 (48). Saved testing notes and assigned the existing LunaHearth Beta internal group (3 testers) and Ravi Home external group (1 tester). External beta review submission succeeded; status is Waiting for Review, with automatic tester notification selected. This is beta review, not public App Store submission. Both Ravi device accounts were observed in the existing internal group, which now reports seven builds. Final per-build internal Testing status was not verified because the user was actively using Safari; no claim of external approval or completed device download is made. Build detail: https://appstoreconnect.apple.com/teams/278f79ef-d215-47fc-82e0-b88d1239f11b/apps/6811447245/testflight/ios/3a96c6e5-cfc7-4c2d-8cd1-067434318ee8


## TestFlight 1.0 (66) — October 1, 2026

Uploaded the current Help/FAQ, adaptive Today and animated demo updates successfully at 11:29 CDT. Xcode reports the uploaded package is processing. The simulator build, 272 Swift tests, performance XCTest and three targeted UI flows passed; signed Release archive succeeded. See `release/1.0-build66/TESTFLIGHT.md`.

Assignment to existing LunaHearth Beta and Ravi Home groups is requested but pending: Safari App Store Connect is signed out. User sign-in is needed to confirm Apple processing completion and assign/check group availability. No completed tester assignment or public App Store submission is claimed.

October 1 follow-up: user restored App Store Connect sign-in. Build 66 completed processing and was assigned to LunaHearth Beta (4 internal testers) and Ravi Home (1 external tester). Saved testing notes and completed external beta-review submission with automatic tester notification selected. Both group build tables now show 1.0 (66) as Testing. No new testers or public App Store submission.
