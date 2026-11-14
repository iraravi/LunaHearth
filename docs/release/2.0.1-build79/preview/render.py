"""Render three truthful natural-speed beats from actual app recordings."""
from pathlib import Path
import subprocess,json,re,datetime,sys
import imageio_ffmpeg
root=Path(__file__).resolve().parent
name=sys.argv[1];ff=imageio_ffmpeg.get_ffmpeg_exe()
source=root/'source'/(name+'-walkthrough.mov')
probe=subprocess.run([ff,'-i',str(source)],capture_output=True,text=True).stderr
(root/'source'/(name+'-metadata.txt')).write_text(probe)
created=datetime.datetime.fromisoformat(re.search(r'creation_time\s*:\s*(\S+)',probe)[1].replace('Z','+00:00')).timestamp()
attachments=json.loads((Path('/tmp')/('NamIllam79-'+name+'-attachments')/'manifest.json').read_text())
marks={a['suggestedHumanReadableName'].split('_')[0]:a['timestamp']-created for t in attachments for a in t['attachments'] if a.get('suggestedHumanReadableName','').startswith('Preview-')}
e,h,f,p=[marks['Preview-'+key] for key in ['01-Entrance','02-WholeHome','03-Fridge','04-Pantry']]
segments=[(e+1,h+1),(f-7,f+1),(p-5,p-1)]
segments=[(round(a*30)/30,round(b*30)/30) for a,b in segments]
duration=sum(b-a for a,b in segments)
assert 15<=duration<=30,(duration,segments)
w,height=(1200,1600) if name=='ipad' else (886,1920)
filters=['[0:v]fps=30,split=3[v0][v1][v2]']
for i,(a,b) in enumerate(segments):filters.append(f'[v{i}]trim=start={a}:end={b},setpts=PTS-STARTPTS[s{i}]')
filters.append('[s0][s1][s2]concat=n=3:v=1:a=0,colorspace=all=bt709,'+f'scale={w}:{height}:force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos,pad={w}:{height}:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30[v]')
output=root/(name+'-app-preview.mp4')
(root/(name+'-timeline.json')).write_text(json.dumps(dict(source=str(source.relative_to(root)),segments=segments,duration=duration,playback_speed=1,width=w,height=height,fps=30,audio='intentional silence',provenance='Native app recording with fictional in-memory Maple House data'),indent=2))
cmd=[ff,'-n','-i',str(source),'-f','lavfi','-i',f'anullsrc=channel_layout=stereo:sample_rate=48000:d={duration}','-filter_complex',';'.join(filters),'-map','[v]','-map','1:a','-c:v','libx264','-preset','medium','-profile:v','high','-level:v','4.0','-b:v','10M','-maxrate','12M','-bufsize','20M','-r','30','-pix_fmt','yuv420p','-c:a','aac','-b:a','256k','-movflags','+faststart',str(output)]
with (root/(name+'-render.log')).open('w') as log:subprocess.run(cmd,stdout=log,stderr=log,check=True)
subprocess.run([ff,'-v','error','-i',str(output),'-f','null','-'],check=True)
subprocess.run([ff,'-n','-i',str(output),'-vf','fps=1,scale=150:-1,tile=8x4','-frames:v','1',str(root.parent/'validation'/(name+'-final-contact.png'))],check=True,capture_output=True)
print(output,duration)
