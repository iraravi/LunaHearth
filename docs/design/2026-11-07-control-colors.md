# Stronger control and illustration colors

User preference: reduce light green; favor dark blue, orange, pink and red.

Enabled native switches use ControlBlue (#2249B5 light / #315BCB dark) and retain visible On/Off words and native accessibility semantics. Disabled controls keep system behavior. Shared legacy sage accents now resolve to blue. Illustration blue, orange, coral and purple tokens use blue, orange, red and pink respectively, with brighter dark-appearance variants for legibility. Existing original-color artwork and semantic warning/success colors are preserved.

No domain entities, persistence, networking, permissions or offline behavior changes. No new dependencies.

Computed sRGB contrast against white in light appearance and #202020 in dark appearance: decorative text accents 5.67:1 or higher; white switch thumb against enabled blue 6.02:1 or higher. This is a palette check, not a claim of whole-app accessibility certification.

Validation: XcodeGen generation and simulator build succeeded. Existing light/dark Home UI test and dark receipt-image opt-in/save/view/remove UI test passed on iPhone 18 Pro iOS 27.2. Log: `/tmp/namillam-colors.log`. No business logic changed, so no new unit tests added. Not uploaded or released.
