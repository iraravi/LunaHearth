# Receipt recovery and dark-mode controls

## Scope and evidence
User reports receipt scanning fails or does not finish, plus hard-to-see dark-mode buttons. The exact customer receipt and physical-device failure were not available. Source review found no timeout/cancel for photo loading + OCR, unguarded completion state across retries, retained photo selection preventing straightforward retry of the same image, and prominent labels without an explicit inverse foreground on pastel dark-mode accents.

## Changes
- ReceiptScanSession bounds photo loading and OCR to 60 seconds, exposes immediate cancellation and rejects stale completions/errors. A timeout does not wait for uncooperative provider work.
- Each attempt creates a scanner so an earlier busy scanner actor cannot queue later attempts.
- Prior review survives failure/cancellation. Photo selection resets for retry. Save remains disabled before text is available.
- Receipt failures now use receipt-specific explanations and a neutral attention alert instead of misleading save-failure messages.
- Shared prominent controls and remaining onboarding/meal/sharing prominent controls pair accent fills with adaptive canvas-coloured labels.
- No receipt parser, amount calculation, record schema, permission, network or persistence changes. All writes still require review and confirmation.

## Validation
- Simulator build passed on available iPhone 18 Pro / iOS 27.
- 280 Swift Testing tests in 52 suites passed, including four session regressions and actual Vision OCR of a synthetic receipt image.
- Session tests cover success/error, cancellation of uncooperative work, timeout without waiting for the provider, and stale results during retry.
- Current asset foreground/fill contrast: at least 5.70:1 light, 10.27:1 dark. These ratios do not substitute for screenshots of glass/disabled controls.
- Both light/dark receipt review-to-save UI tests passed. Inspected captured review screens: toolbar actions and receipt controls are readable in both appearances. This is targeted visual coverage, not a whole-app accessibility audit.
- Focused receipt/session tests passed again after the final error-message changes. Full run evidence: /tmp/LunaReceiptFixTests2.xcresult; final focused log: /tmp/luna-receipt-final-test.log.
- The simulator emitted frame-dimension and platform diagnostic warnings during the broader run; this validation does not establish a warning-free app.
- Physical-device camera capture, iCloud-photo download and the customer's failing receipt remain unverified. No TestFlight upload in this change.

## Deeper follow-up
- Found camera JPEG conversion on the main actor before the bounded session. Moved conversion to ReceiptCameraEncoder and into the timed operation; output is capped at 2600 pixels and orientation is rendered upright.
- Photo imports now recognize one page before loading the next, avoiding retention of four encoded page payloads.
- Successful sessions invalidate their generation as well as cancelling the watchdog. An immediately cancelled session checks cancellation before invoking its provider.
- Late AI-decoding errors now require the current generation and household before changing presentation state.
- Reviewed repository preflight validation, duplicate import protection and atomic save behavior; existing regression tests cover these paths. No parser, record schema or network changes were made.
- Added image-encoding/OCR, malformed/oversized image, completed-timeout, immediate-cancellation and stale-error regressions.

Follow-up validation: simulator build passed; the final full unit run passed 285 Swift Testing tests in 52 suites plus the grocery performance XCTest. Dark-mode/large-text and landscape receipt review/save UI flows both passed (/tmp/LunaDeepReceiptTests.xcresult). Inspected the dark/large-text screenshot: primary controls remain readable and reachable; the navigation title truncates at this extreme text size. The landscape XCTest screenshot contains a black/cropped capture, so passing interactions do not establish landscape visual quality; device visual review remains outstanding. Saved the dark/large-text evidence alongside this report. Final unit log: /tmp/luna-deep-final.log. Existing physical-camera/iCloud-photo and whole-app accessibility limitations remain.

## Missing-item follow-up
Confirmed parser gaps for explicit whole-rupee prices and currency labels; corrected Rs./INR/symbol handling while retaining refund/payment exclusion and rejecting ambiguous bare whole numbers. Moved manual missed-item recovery before the proposed rows. Simulator build, 287 unit tests and dark-mode receipt review/save UI check passed. Evidence: /tmp/luna-missing-build.log and /tmp/luna-missing-test.log. No customer receipt supplied, so this does not establish that their particular missing item is resolved.
