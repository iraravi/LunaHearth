# Receipt to pantry: 60-second help video

Silent, captioned 1280×720 H.264 MP4, 24fps, fast-start streaming.
Original motion graphics and actual current app screenshots, all synthetic UI-test
household/receipt data. The scan illustration is explicitly labelled. No voice,
music, tracking, new app permission or runtime dependency.

Source captures: testReceiptExplicitInventoryChoiceAndExactTotal on iPhone 18 Pro,
iOS 27.2, November 6, 2026. Test passed including saved expense amount $6.48.
Result bundle: /tmp/namillam-receipt-help.xcresult.

Build: create a Python venv with pillow, imageio-ffmpeg, numpy; run render.py.
macOS Arial fonts are used. Do not deploy source/assets: deploy only index.html,
receipt-to-pantry.mp4, poster.jpg and captions.vtt from hostinger into a new
/help-videos/receipt-to-pantry/ directory. Keep the existing site intact.
The player supports native controls, chapter buttons, replay, a text transcript,
caption track and downloads. No autoplay.

This task creates and hosts the guide. Adding an in-app Watch how link is a
separate app change and would require a new app build and applicable privacy review.
