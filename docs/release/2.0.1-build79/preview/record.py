"""Record the real iPhone UI-test walkthrough; preserve its unedited source footage."""
import os
import sys
from pathlib import Path
import signal
import subprocess

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[3]
NAME, DEVICE = sys.argv[1:3]
ENV = dict(os.environ, DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer")
SOURCE = ROOT / "source" / (NAME + "-walkthrough.mov")
SOURCE.parent.mkdir(exist_ok=True)
if SOURCE.exists():
    raise SystemExit("Preserve the existing recording; choose a new source filename.")
with (ROOT / "source" / (NAME + "-record.log")).open("w") as record_log:
    recorder = subprocess.Popen(
        ["xcrun", "simctl", "io", DEVICE, "recordVideo", "--codec=h264", "--mask=ignored", str(SOURCE)],
        env=ENV, stdout=record_log, stderr=record_log,
    )
    try:
        with (ROOT / "source" / (NAME + "-walkthrough.log")).open("w") as test_log:
            result = subprocess.run(
                ["xcodebuild", "-project", "LunaHearth.xcodeproj", "-scheme", "LunaHearth",
                 "-destination", f"platform=iOS Simulator,id={DEVICE}",
                 "-derivedDataPath", "/tmp/NamIllamFix",
                 "-resultBundlePath", "/tmp/NamIllam79-" + NAME + ".xcresult",
                 "-only-testing:LunaHearthUITests/VisualFlowTests/testAppStoreHomePreview",
                 "test"], cwd=REPO, env=ENV, stdout=test_log, stderr=test_log,
            )
    finally:
        recorder.send_signal(signal.SIGINT)
        recorder.wait(timeout=60)
    if result.returncode:
        raise SystemExit("Walkthrough failed; inspect source/walkthrough.log before editing.")
print(SOURCE)
