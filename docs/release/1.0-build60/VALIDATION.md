# Build 60 — Liquid Glass controls

September 16, 2026. Presentation-only; no entities, schema, sync, permission or data changes. See ADR 048.

## Validation

- Simulator and signed Release builds passed with iOS 18 deployment target and guarded iOS 26 APIs.
- iPhone: main-screen screenshot flow and dark/large-text shopping form passed.
- iPad: calendar landscape and shopping/inventory large-text navigation passed.
- Screenshot review caught tool buttons stacking into three rows. Corrected to a horizontal scrolling control strip and removed redundant padding.
- Final iPhone compact shopping and shopping/inventory large-text tests passed after that correction. Final compact screenshot visually inspected; all three controls fit on one row and items remain visible.
- Calendar glass controls visually inspected. Native buttons preserve system semantics. No domain code changed; unit suite was not rerun for this presentation-only update.
- Reduce Transparency/Increase Contrast explicit fallback implemented; physical accessibility settings and older OS runtime not exercised. Only iOS 27 simulator runtime is available.

## Installation

Final signed build 1.0 (60) installed in place on Ravi's iPad and iPhone; no uninstall, fixture data or data reset.

## Evidence

Logs: /tmp/luna60-phone.log, /tmp/luna60-ipad.log, /tmp/luna60-final-ui.log, /tmp/luna60-device-final.log, /tmp/luna60-ipad-install.log, /tmp/luna60-iphone-install.log.

Screenshots: docs/visual-review/liquid-glass/. Store-03-Shopping is the initial capture before strip correction; 84-Compact-Shopping-iPhone.png is the corrected final layout.
