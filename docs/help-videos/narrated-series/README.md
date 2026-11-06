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

## Janet motion revision — 2026-11-06

The user approved Janet's sample and then requested animated Home → Pantry and
Home → Shopping navigation. Two continuous narrations were generated with the
approved voice ID `4270665fc47f44aa989c093bb3dc2b99`, returning engine `orca`.
HeyGen stopped the third request for insufficient credit. The user explicitly
chose to keep only the two completed Janet guides; no retry or further synthesis
was made. The other eight guides retain their original narration.

Rebuild without new speech calls:

```
python animate.py
python library.py
```

`voice-janet/` preserves original MP3s, exact submitted text, provider word timing,
request IDs, scene/caption timelines and technical validation. No API credentials
or expiring media URLs are committed. `animate.py` uses immutable screenshot
assets and an absolute, deterministic narration clock. Speech stays at 1.0x:
connected-kitchen is 84.297 seconds; create-home is 37.564 seconds. No dialogue is
cut to force the old 120/60-second runtimes.

The visual direction retains black/white/yellow, one teaching headline, and real
app screenshots. Guided tap rings identify actual Home cards and toolbar controls;
push transitions illustrate opening those screens. These are animated screenshot
walkthroughs, not live interaction recordings. Captions follow provider word
intervals checked token-by-token against each submitted script, rather than
estimated character durations. Chapter buttons use the actual scene starts.

New `*-janet.mp4`, `.jpg` and `.vtt` files retain the old exports for rollback.
The player labels Janet versus original narration explicitly. Validation includes
full decoding, 48 kHz AAC/H.264 checks, encoded loudness/peak measurements,
caption coverage and representative transition frames. No new app code changed,
so the app build/test suite was not rerun for this media revision. Full subjective
audio listening review was not performed; the user approved the voice sample.

Deployment status: prepared; final upload awaits an unlocked Mac.
