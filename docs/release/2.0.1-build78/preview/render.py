"""Natural-speed App Store export. Run using Python with imageio-ffmpeg installed."""
import json
from pathlib import Path
import subprocess
import imageio_ffmpeg

root = Path(__file__).resolve().parent
edit = json.loads((root / "timeline.json").read_text())
duration = edit["source_out_seconds"] - edit["source_in_seconds"]
assert 15 <= duration <= 30 and edit["playback_speed"] == 1
ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
output = root / "Nam-Illam-Home-and-Fridge.mp4"
command = [
    ffmpeg, "-n", "-i", str(root / edit["source"]),
    "-f", "lavfi", "-i", f"anullsrc=channel_layout=stereo:sample_rate=48000:d={duration}",
    "-filter_complex", f"[0:v]fps=30,trim=start={edit['source_in_seconds']}:end={edit['source_out_seconds']},setpts=PTS-STARTPTS,colorspace=all=bt709,"
    "scale=-2:1920:flags=lanczos,pad=886:1920:(ow-iw)/2:0,setsar=1,fps=30[v]",
    "-map", "[v]", "-map", "1:a", "-c:v", "libx264", "-preset", "slow",
    "-profile:v", "high", "-level:v", "4.0", "-b:v", "10M", "-maxrate", "12M", "-bufsize", "20M",
    "-pix_fmt", "yuv420p", "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709",
    "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-movflags", "+faststart", str(output),
]
with (root / "render.log").open("w") as log:
    subprocess.run(command, stdout=log, stderr=log, check=True)
subprocess.run([ffmpeg, "-v", "error", "-i", str(output), "-f", "null", "-"], check=True)
subprocess.run([ffmpeg, "-n", "-ss", "5", "-i", str(output), "-frames:v", "1", str(root / "poster.png")],
               check=True, capture_output=True)
print(output)
