# ADR 031 — Connected receipt demo and expiry review

User requested a sample receipt and a slow graphical demonstration of receipt → expenses/shopping → pantry → meal ideas.

Home exposes a connected demo backed by its own in-memory SwiftData repository. It creates no sync configuration and never invokes real household notification scheduling. A locally rendered synthetic receipt can be loaded directly through Vision or shared as an image. The real reviewed receipt transaction writes only to the injected demo repository. Rescanning remains idempotent. Sample pantry contains low-stock curd, and the sample shopping list is matched on import. The animation highlights stages five seconds apart with a moving document symbol, supports pause/replay/manual stepping, cancels on disappearance, and uses manual steps with Reduce Motion.

Meal cards are explicitly curated examples matched to available sample inventory. Missing items can be added to the demo shopping list with duplicate checks. The 5 PM check-in is a manual preview, not a scheduled notification or background AI job. Production pantry meal generation and opt-in daily reminders remain future work; existing Meals remains the manual planner.

Receipt review also gains an optional expiry date for the selected pack, validated before the atomic transaction. A reviewed date applies to a new pack or explicitly selected existing pack; omitted dates preserve existing expiry. No shelf life is inferred. Existing InventoryItem expiry fields already sync, so no schema changes.

Shopping's delivered aggregate notice is cleared after completed/removed assignments are observed, preventing a stale count even while other shopping items remain. In-app lists already exclude bought items; cross-device delivery still depends on receiving sync.

Build 30 replaces the stage highlight with a continuous vector animation and shortens the demo header. The animation is independent of actual sample transactions and owns no repository. Temporary-store creation and all receipt writes remain unchanged; the user's main household database and iCloud are untouched by the demo.

October 1, 2026 presentation update: the original Canvas diagram is replaced by a five-chapter photographic walkthrough, animated sample record cards, direct chapter selection and native playback controls. Five-second structured task sleeps replace per-frame drawing; leaving the screen cancels playback. Reduce Motion retains manual navigation and all review actions. The underlying in-memory demo and review-confirmation boundary remain unchanged.
