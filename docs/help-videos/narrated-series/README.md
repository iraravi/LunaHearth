# Nam Illam narrated help library

Actual v2 app screenshots, synthetic English narration (macOS Rishi), captions,
transcripts and a standalone web player. All household content is synthetic demo
data. No new app permissions, networking, data schema or dependencies are added.

## Content

- Connected kitchen: 2 minutes, Pantry → Shopping → receipt review → Expenses
  and explicit pantry selection; review matches to avoid duplicate stock.
- Nine 1-minute guides: create home, pantry, shopping, reminders, expenses,
  meals, calendar, family/backup and receipt-to-pantry.

The player explicitly labels these as v2 preview screens, which may differ from
the current App Store build. These are narrated screenshot walkthroughs with
vertical pans, not recordings of live taps. No autoplay, tracking or external
video hosting scripts. Native controls, keyboard-accessible chapters, burned-in
captions, optional WebVTT and text transcripts are included.

## Rebuild

Build-only tools: Python, Pillow, imageio-ffmpeg and macOS `say` with Rishi voice.

```
python build.py voice
python build.py
python library.py
```

`plan.py` is the narration/scene source. `assets/` contains actual app captures.
`publish/` is the only directory intended for web upload. Do not upload audio
intermediates, test result bundles or source files. Deploy additively under
`/help-videos/narrated/` without replacing the existing website.

## Verification

The current app capture test `testNarratedHelpScreens`, the receipt duplicate
stock test `testReceiptLinksBoughtItemWithoutRestocking`, and explicit inventory
choice/exact total test `testReceiptExplicitInventoryChoiceAndExactTotal` passed
on iPhone 18 Pro / iOS 27.2 simulator on 2026-11-06. The latter also captures the
expanded Quantity & matches controls. This is targeted UI validation, not a claim
that the complete app test suite ran during media production.

Published at https://neuralluna.com/help-videos/narrated/ on 2026-11-06.
All 41 public assets returned HTTP 200; all ten MP4 lengths match local files.
HTTP byte ranges are supported for seeking. Each local MP4 passed full audio/video
decoding. The public player and chapter navigation were checked in the browser.
