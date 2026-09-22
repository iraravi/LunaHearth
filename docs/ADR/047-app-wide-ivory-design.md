# ADR 047: App-wide ivory design

Accepted September 16, 2026. The user explicitly requested extending the accepted ivory/premium welcome direction to the entire app, rather than updating only one image.

## Design scope

Shared adaptive ivory canvas, near-white cards, charcoal text and restrained semantic accents: sage shopping, clay pantry, slate calendar, plum spending. All existing main feature theme color sets use the same canvas/surface/ink system. Existing warning/danger colors remain unchanged. Member colors stay distinct and labels are retained. More, family, privacy, Apple connections, receipt/photo import, editors, home spaces and floor-plan backgrounds follow the same system through shared components and view-level backgrounds.

Display headings use a regular serif; body text, controls and record values retain native readable typography. Today and Home use a shared editorial header. Home separates kitchen destinations, reminders, spaces and spending/home care with consistent surface treatment. Grocery shelf heroes/cards use quieter colors and reduced decorative icon sizes. Cards have restrained corners. Expenses keep prominent tabular spending numbers. Calendar keeps people, dates and appointments as the primary content. No root-tab or workflow changes.

Photography is a coordinated bundled set: WelcomeResidence, WelcomeTable, EditorialPantry and EditorialPlanning. Replaced references to the older cartoon planning image, blue living room, old shopping basket/hero and bright pantry photos throughout Features. Item-specific food icons remain to aid recognition. Decorative photos remain hidden from VoiceOver and yield at accessibility text sizes.

## Domain and privacy

Presentation only. No entity, repository, receipt matching, inventory quantity, expense accounting, household sharing or AI inference changes. No schemas, permissions, remote services or user-data migration. Photos were generated as development assets with generic prompts, not household content, and are bundled for offline use. Existing user progress and records remain untouched.

## Validation

Build, domain regression and phone/iPad navigation/visual checks are recorded with build 59. Asset sources/prompts and screenshots are in `docs/visual-review/ivory-app/`.
