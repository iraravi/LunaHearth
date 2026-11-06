# Nam Illam welcome story — review cut

22.5-second portrait welcome film with Janet narration at original speed, generated animated scenes, real app confirmation panel, original quiet instrumental and provider-timed captions.

The requested fully animated receipt-scanning scene remains unfinished: the generated shot showed the phone facing the wrong way, and its replacement returned HTTP 402 (free video allowance exhausted). The rejected shot is excluded. This cut substitutes the real app's confirmation panel, explicitly labeled as an example. It is shorter than the approximate 30–35-second plan, following the accepted narration without stretching speech or padding footage. The script is preserved verbatim.

This is an illustrative welcome story, not a screen recording or a completed first-launch app integration. It is not deployed to Hostinger. No application code, user data, backend or permissions changed.

## Rebuild

Python 3 with Pillow, NumPy and imageio-ffmpeg. On this Mac:

`/tmp/namillam-video-venv/bin/python docs/help-videos/welcome-story/render.py`

The renderer uses project-relative media and the existing real app capture in the sibling narrated-series directory. Fonts use macOS Arial. Output is in `publish/`. Originals, script/timings, source IDs, edit decisions and music source are retained. Source footage is 768×1344 despite requesting 1080p; delivery is 720×1280 with a small aspect-ratio crop.

Validation: complete media decode, 1-second source/final frame sampling, subtitle coverage and loudness checks. Listening review was not performed. Review on a phone before shipping. No app build/tests run for this media-only change.
