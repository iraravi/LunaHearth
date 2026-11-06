"""Original locally composed instrumental; preserve Janet speech at 1x."""
from pathlib import Path
import math,json,wave,subprocess
import numpy as np
from PIL import Image,ImageDraw,ImageFont
import imageio_ffmpeg
P=Path(__file__).parent;OUT=P/'publish';TMP=P/'audio'/'music';TMP.mkdir(parents=True,exist_ok=True)
FF=imageio_ffmpeg.get_ffmpeg_exe();RATE=48000;INTRO=2.5;END=1.5
font='/System/Library/Fonts/Supplemental/Arial.ttf';bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def card(path,title,subtitle):
 im=Image.new('RGB',(1280,720),'#0b0e13');d=ImageDraw.Draw(im)
 for txt,y,size,color,face in [('NAM ILLAM',200,18,'#ffda48',bold),(title,280,54,'#f5f7fb',bold),(subtitle,365,24,'#b8c2d1',font)]:
  f=ImageFont.truetype(face,size);w=d.textlength(txt,font=f);d.text(((1280-w)/2,y),txt,font=f,fill=color)
 d.rounded_rectangle((604,440,676,445),2,fill='#ffda48');im.save(path)
def music(path,duration,speech_end):
 n=math.ceil(duration*RATE);out=np.zeros(n,dtype=np.float32)
 # Original repeating harmonic progression with gently staggered tones, no samples.
 chords=[[57,60,64],[53,57,60],[48,52,55],[55,59,62]]
 for bar,start in enumerate(np.arange(0,duration,3.2)):
  for j,note in enumerate(chords[bar%4]):
   at=start+j*.22;length=min(4.0,duration-at)
   if length<=0:continue
   t=np.arange(int(length*RATE))/RATE;freq=440*2**((note-69)/12)
   env=(1-np.exp(-t/0.12))*np.exp(-t/1.4)*np.minimum(1,(length-t)/.25)
   tone=(np.sin(2*np.pi*freq*t)+.2*np.sin(2*np.pi*freq*2*t))*env*.12
   pos=int(at*RATE);end=min(n,pos+len(tone));out[pos:end]+=tone[:end-pos]
 t=np.arange(n)/RATE
 # Quiet under narration, slightly fuller during the opening and closing cards.
 level=np.where(t<INTRO,.42,.11)
 level=np.where(t>speech_end,.25,level)
 fade=np.minimum(1,t/.65)*np.minimum(1,(duration-t)/1.2)
 out*=level*fade
 with wave.open(str(path),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes((np.clip(out,-1,1)*32767).astype('<i2').tobytes())
for slug,subtitle in [('connected-kitchen','Your pantry, shopping and expenses—connected.'),('create-home','A simple start for your household.')]:
 duration=json.loads((P/'voice-janet'/f'{slug}-timeline.json').read_text())['duration'];base=math.ceil(duration*24)/24;total=INTRO+base+END
 intro=TMP/f'{slug}-intro.png';outro=TMP/f'{slug}-outro.png';audio=TMP/f'{slug}-music.wav'
 card(intro,'Welcome to Nam Illam',subtitle);card(outro,'A little more together.','Pause, replay, and try it in your own home.');music(audio,total,INTRO+base)
 graph=f'[0:v]fps=24,format=yuv420p,setsar=1,fade=t=in:st=0:d=0.4[v0];[1:v]setpts=PTS-STARTPTS,setsar=1[v1];[2:v]fps=24,format=yuv420p,setsar=1,fade=t=out:st=0.8:d=0.7[v2];[v0][v1][v2]concat=n=3:v=1:a=0[v];[1:a]adelay=2500:all=1,apad[a];[a][3:a]amix=inputs=2:duration=longest:normalize=0[aout]'
 cmd=[FF,'-y','-loop','1','-t',str(INTRO),'-i',str(intro),'-i',str(OUT/f'{slug}-janet.mp4'),'-loop','1','-t',str(END),'-i',str(outro),'-i',str(audio),'-filter_complex',graph,'-map','[v]','-map','[aout]','-t',str(total),'-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-ar','48000','-movflags','+faststart',str(OUT/f'{slug}-janet-music.mp4')]
 with (TMP/f'{slug}.log').open('w') as log:subprocess.run(cmd,check=True,stderr=log,stdout=subprocess.DEVNULL)
 # Preserve reliable caption intervals with a single explicit intro offset.
 def stamp(v):return f'{int(v//3600):02}:{int(v//60)%60:02}:{v%60:06.3f}'
 info=json.loads((P/'voice-janet'/f'{slug}-timeline.json').read_text())
 (OUT/f'{slug}-janet-music.vtt').write_text('WEBVTT\n\n'+'\n\n'.join(f"{stamp(c['start']+INTRO)} --> {stamp(c['end']+INTRO)}\n{c['text']}" for c in info['captions'])+'\n')
 Image.open(intro).save(OUT/f'{slug}-janet-music.jpg',quality=90)
 print(slug,round(total,2),'seconds',flush=True)
