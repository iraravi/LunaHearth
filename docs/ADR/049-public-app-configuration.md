# ADR 049 — Public operational configuration

Accepted September 23, 2026. User explicitly approved public CloudKit status/content and feature switches, including AI, receipts, shopping and Notes. New product features remain frozen.

## Boundary and privacy review

Introduce a separate, read-only `LHAppConfiguration` record in the existing container's PUBLIC database, default zone, fixed record name `ios-current`. This does not move or expose any household entity, receipt, image, expense, note, identity, or sync metadata. No SwiftData migration, automatic mirroring, ownership change, telemetry, targeting, new login, SDK, or cloud inference. CloudKit requests necessarily reach Apple; bundled privacy text discloses this independently of optional household sync.

The client fetches one known record, never queries/users/identities, subscribes, or writes publicly. Only publisher staff with CloudKit Console access publish. Configure World read; remove app-user Create/Write from Authenticated and Creator roles for this record type. Confirm permissions before production publication. Never ship management credentials. Public means nonconfidential, not secure secret storage.

## Untrusted content / abuse controls

Only a typed JSON payload, schema version 1, <=32 KiB, positive monotonically increasing revision, expiry within 31 days, <=100 feature keys, 300-character per-feature messages, 500-character announcement and 4,000-character help text. Unknown flags cannot enable code absent from the binary. Plain SwiftUI text only: no HTML, scripts, links, arbitrary media downloads, model prompts, or commands. No remotely configurable household identifiers, endpoints, entitlements, prices or permission grants. No automatic actions or data deletion. Cloud permissions mitigate unauthorized writes; stolen publisher credentials could still publish misleading text or temporarily pause actions. Restrict console access and review messages before publishing. This first version deliberately excludes remote images.

## Reliability

Bundled defaults retain all previously shipped workflows. Last validated configuration is cached in device UserDefaults. Missing/invalid/expired data falls back to defaults. Unsupported schema, malformed JSON, excessive size, expired payload, and lower revisions do not replace a valid active cache. Fixed fetch on foreground, minimum 15 minutes between attempts, persisted across launches. No startup wait, background polling, push guarantee or immediate global kill switch. Expiry intentionally releases operational pauses; do not rely on it as a security/food-safety mechanism. Future safety-critical policy would require a separate design.

## Enforcement

Master AI gates all nine Foundation Models services; individual gates retain deterministic fallbacks. Views hide relevant AI controls and keep actual hardware checks. Service/data entry points recheck cached policy for receipt OCR/import/expense/pantry updates, kitchen photos, shopping-to-pantry, new buyer assignment, templates, shopping proposals, weekly saves, calendar export, new Reminders connection/list/entry, and meal reminder enablement. Calendar deletion and reminder disable/completion remain possible. Notes switch gates the transient share composer. Existing records, manual pantry/shopping/expense entry, sync, backups, deletion/export/recovery remain available. New receipt drafts are blocked if their requested disabled destination is selected, rather than silently saving only part of the transaction. Existing scheduled meal reminders remain until users turn them off; the remote flag prevents new scheduling, not remote notification cancellation.

UI gates are convenience, not authorization. A running inference or external share sheet may finish after a refresh; switches control subsequent operations, not an immediate distributed cancellation protocol. Offline clients can differ. Do not present flags as a security control.

## App review / rollout

Only control existing disclosed functionality. No review-specific settings or remotely downloaded code. Deploy schema/security in Development first, then Production; production content is published separately. TestFlight uses Production. Existing build 61 does not contain this feature and cannot receive switches. A new binary is necessary.

See `docs/PUBLIC_APP_CONFIGURATION.md` for setup. Live console permissions, production fetch, and a new signed-device distribution remain release acceptance steps; unit tests do not establish them.

## Publisher-only management clarification
The publisher requested removal of the user-facing App Status screen. It is removed, including its refresh action and flag inventory. Management is exclusively through developer CloudKit Console; there has never been an in-app write API. Published help is shown in Help & guides, notices in the app banner, and pause explanations at the affected action. Only nonconfidential, non-PII editorial configuration belongs in the public record; absence of PII alone does not make secrets or proprietary information suitable for public storage.
