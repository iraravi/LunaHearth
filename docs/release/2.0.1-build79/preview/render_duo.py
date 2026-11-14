"""Actual Duo front/interior captures; inactive screen intervals excluded."""
from pathlib import Path
import json,subprocess
import imageio_ffmpeg
root=Path(__file__).resolve().parent;ff=imageio_ffmpeg.get_ffmpeg_exe()
segments=[dict(source='source/duo-entrance.mov',start=1,end=4),dict(source='source/duo-interior.mov',start=19.7,end=26.7),dict(source='source/duo-interior.mov',start=63.9,end=71.9),dict(source='source/duo-interior.mov',start=109.3,end=116.3)]
w,h=1920,886;duration=25
filters=[]
inputs=[]
for i,s in enumerate(segments):
 inputs+=['-i',str(root/s['source'])]
 filters.append(f'[{i}:v]fps=30,trim=start={s["start"]}:end={s["end"]},setpts=PTS-STARTPTS,colorspace=all=bt709,scale={w}:{h}:force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos,pad={w}:{h}:(ow-iw)/2:(oh-ih)/2,setsar=1[v{i}]')
filters.append('[v0][v1][v2][v3]concat=n=4:v=1:a=0,fps=30[v]')
output=root/'iphone-duo-app-preview.mp4'
cmd=[ff,'-n']+inputs+['-f','lavfi','-i',f'anullsrc=channel_layout=stereo:sample_rate=48000:d={duration}','-filter_complex',';'.join(filters),'-map','[v]','-map','4:a','-c:v','libx264','-preset','medium','-profile:v','high','-level:v','4.0','-r','30','-b:v','10M','-maxrate','12M','-bufsize','20M','-pix_fmt','yuv420p','-c:a','aac','-b:a','256k','-movflags','+faststart',str(output)]
with (root/'duo-render.log').open('w') as log:subprocess.run(cmd,stdout=log,stderr=log,check=True)
subprocess.run([ff,'-v','error','-i',str(output),'-f','null','-'],check=True)
subprocess.run([ff,'-n','-i',str(output),'-vf','fps=1,scale=300:-1,tile=5x5','-frames:v','1',str(root.parent/'validation'/'duo-final-contact.png')],check=True,capture_output=True)
(root/'iphone-duo-timeline.json').write_text(json.dumps(dict(segments=segments,duration=duration,playback_speed=1,width=w,height=h,fps=30,fit='Contain with neutral black margins to preserve whole app UI',note='Duo changes active display on folding. Real front and interior footage joined with cuts; inactive black intervals excluded.'),indent=2))
print(output)
