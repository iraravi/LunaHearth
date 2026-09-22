# ADR-016: Personal shopping and assignment alerts

Status: Accepted for implementation; physical cross-account push validation pending.

## Decision and affected entities

GroceryItem remains the single to-do record. Its existing assignedMemberID, completion, store, quantity and civil plannedDay drive Today → For you. No duplicate HouseholdTask or Apple Reminder is created. HouseholdMember is a household profile, not an authenticated identity. Each device explicitly selects its member for each household; this selection and notification deduplication IDs stay in local preferences and are excluded from household backups/sync. No shared schema migration is required.

The current active home gets a personal card, open-item count, Needed now / Later sections and direct completion. A dated Later item becomes Needed now on its local civil day. Undated legacy Later items remain Later. Counts mean list entries, not summed quantities. Shared changes continue through the existing merge/conflict and recovery policy.

## Alerts and privacy review

After explicit opt-in, request system alert/sound permission. Install CKDatabaseSubscription in the existing owner's private or participant's shared database. No public database, custom server, third-party push provider, account login or new sharing boundary is introduced. The silent push carries a CloudKit change hint; the app reuses validated account-bound sync to obtain content. APNs development/production entitlement and remote-notification background mode are added. This supersedes ADR-012's foreground-only delivery statement.

After sync, compare active assignment UUIDs for the selected member against a durable device-local set. Batch newly observed assignments into one generic alert; quantity/name edits do not repeat it, completed or reassigned-away items leave the set, and reopened items can alert again. Enabling alerts or choosing a person establishes a baseline, avoiding a flood for historical items. Turning off alerts/clearing a person removes the app's delivered alert for this home. Alert text contains counts only, without member names, household names, stores or item content. Tapping opens For you. The member selector is a filter, never access control; share participants can read the whole shared home.

CloudKit/APNs background delivery is best effort. It may be delayed, coalesced or suppressed, including after force quit. The current active home is refreshed; inactive homes are not enumerated in the background. Foreground polling/manual sharing refresh remains the fallback and Today is the durable actionable view. No timed due-date notification or iOS widget is implemented by this change. Live two-device APNs delivery and release provisioning must be verified before claiming it works on Ravi/Kira's phones.

## Summary

ShoppingBriefService has a deterministic offline fallback and a Foundation Models adapter gated to supported iOS 26+ devices. User-triggered generation receives at most 40 assigned open items, with bounded labels, quantity, store and timing only. UUIDs, member identities and other household data are omitted. Labels are untrusted prompt data. Generated prose is read-only, marked as an on-device summary and never drives counts, completion, scheduling or writes. The exact deterministic totals remain visible; changing the list invalidates the brief. No network AI or Private Cloud Compute is used.

## Validation

Unit coverage: member filtering, shared-record completion without task duplication, ten-item alert batching, durable deduplication, reopening, opt-out, denied permission, historical assignment baseline, and civil-day summary rules. UI coverage: choose Kira, see assigned Milk, generate fallback summary, complete Milk and see the empty state. Simulator checks do not prove physical APNs or Foundation Models generation.

Apple references:
- https://developer.apple.com/documentation/cloudkit/ckdatabasesubscription
- https://developer.apple.com/documentation/usernotifications/implementing-background-push-notifications
- https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications

Validated locally on 2026-09-12: Xcode simulator build succeeded; all 91 unit tests passed (`/tmp/LunaPersonalShoppingFinal20260912.xcresult`), with both light and accessibility-large dark UI flows passing. After moving background callback setup to app initialization and adding minute-based civil-day refresh, all four assignment tests and the light end-to-end flow passed again (`/tmp/LunaPersonalShoppingLifecycle2_20260912.xcresult`). Screenshots were visually inspected and are linked from `docs/visual-review/personal-shopping.html`. These checks do not validate APNs delivery or actual model generation on a physical device.
