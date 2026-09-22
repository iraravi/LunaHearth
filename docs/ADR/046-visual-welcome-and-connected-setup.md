# ADR 046: Visual welcome and connected setup

Accepted September 16, 2026 following the request for instructions after installation, graphics explaining connected workflows and step-by-step setup. Video is deferred.

## Experience

An offline five-chapter walkthrough introduces the home, receipts/expenses, shopping, pantry and meals. It uses bundled illustrations and a gently animated, tappable workflow. Continue, Back and Skip are explicit controls; completing or skipping saves a device-local reviewed flag. Existing installations see it once when updating to this feature. More → How it works replays it without changing setup progress or household data.

The introduction comes after successful local loading. Invitations and invitation lookup take precedence, and store recovery remains visible on failure. Creating, joining or restoring a home stays in the existing onboarding flow. No permissions are requested by the tour.

The existing per-home setup guide adds receipts/expenses and meals, taking the guide to seven steps including home creation. Old completion and skip values are preserved. Real expense and meal records satisfy the new milestones; steps can be left for later. Finishing the instructional tour does not mark setup actions complete.

## Data and privacy

The walkthrough writes only one device-local preference. Setup progress uses existing device-local, household-scoped preferences. No new entity, schema, sync behavior, networking, AI inference or permission is introduced. Household records (expenses, purchases, groceries, inventory and meals) are read by the existing setup milestone checks only. The flow is illustrative, does not seed demo data and does not silently update the pantry or shopping list.

Copy explains review before saving, optional on-device AI and fallback, optional iCloud sharing, and the meal-ideas-only boundary. A 5 PM reminder does not imply scheduled background AI generation. Saved dates are not food-safety verification.

## Accessibility and layout

Scrollable content, native controls, 44-point minimum control heights, Dynamic Type, named chapter buttons, progress semantics and heading focus. iPad uses an adaptive two-column illustration/explanation layout; accessibility text returns to one column. Reduce Motion disables automatic workflow highlighting. No autoplay video or audio.

## Validation

Simulator build and 240 unit tests passed. First-run completion, persisted dismissal after relaunch, and More replay with large text passed on iPhone and iPad. The seven-step setup progress/skip regression passed on iPhone. Final receipt illustration and adaptive screenshots were inspected on iPad and large-text iPhone; captures are in `docs/visual-review/welcome-guide`. Physical-device VoiceOver and Reduce Motion interaction have not been manually audited. See build 57 validation for direct installation. No App Store or TestFlight upload is part of this feature.

### September 16 visual refinement
The first visual treatment was rejected as too crowded and bright. The revised journey uses two bundled editorial photographs, adaptive ivory/charcoal colors, serif headings and underlined chapter navigation. The looping workflow highlight and diagram cards were removed. Only the selected chapter underline animates; text changes immediately, and Reduce Motion disables the underline animation. New-household creation, setup progress and the More photograph follow the same visual direction. No data, permissions, persistence keys or AI behavior changed; the existing once-per-device reviewed flag is preserved. Image assets and prompts are recorded in `docs/visual-review/premium-welcome/ART_DIRECTION.md`.
