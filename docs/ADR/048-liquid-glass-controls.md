# ADR 048: Liquid Glass control layer

Accepted September 16, 2026 following the user's request to add Apple's Liquid Glass direction to the ivory redesign.

## Scope

Native tab/navigation bars use their system appearance on iOS 26 and later; remove the custom ivory bar-background override on those releases. iOS 18/older supported releases retain the ivory override. No custom tab bar or navigation hierarchy change.

Shared availability-guarded glass button styles cover pantry/shopping tools, calendar date controls and the shopping form's primary action. Adjacent custom controls use GlassEffectContainer. Content cards, forms, photographs, expense charts and grocery records remain opaque ivory surfaces; no glass over glass or custom animation is introduced.

Reduce Transparency and Increase Contrast select bordered/solid controls. Native button styles retain disabled semantics, focus, touch feedback and system motion behavior. Existing labels, accessibility identifiers and minimum targets remain. Native bar accessibility behavior is system managed. Requires no minimum-OS increase.

## Domain and privacy

Presentation only. No record changes, migration, networking, permissions, sync or AI changes. Offline behavior unchanged.

## Reference

https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views

## Validation

Build 60 validation and device installation recorded in docs/release/1.0-build60/VALIDATION.md. Physical VoiceOver and Reduce Transparency checks remain manual verification boundaries.
