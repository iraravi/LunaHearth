"""Render a welcome-film review cut. Original speech stays at 1x."""
from pathlib import Path
import json,subprocess,math,wave
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageOps
import imageio_ffmpeg
P=Path(__file__).parent; A=P/'assets'; O=P/'publish'; O.mkdir(exist_ok=True)
FF=imageio_ffmpeg.get_ffmpeg_exe(); W,H,FPS=720,1280,24; TOTAL=22.5; OFFSET=.5
font='/System/Library/Fonts/Supplemental/Arial.ttf'; bold='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def text(d,s,y,size=34,color='white',face=bold):
 f=ImageFont.truetype(face,size);d.text(((W-d.textlength(s,font=f))/2,y),s,font=f,fill=color)
meta=json.loads((P/'narration.json').read_text()); words=[w for w in meta['word_timestamps'] if not w['word'].startswith('<')]
# Exact provider word timing; short grammatical caption phrases.
groups=[4,6,4,5,5,4,6,4,3,4,4,2,2,4,4,3]
# Segment at punctuation or at six words, preserving every token.
cues=[]; current=[]
for w in words:
 current.append(w)
 if w['word'][-1] in '.,' or len(current)>=6:
  cues.append({'start':current[0]['start']+OFFSET,'end':current[-1]['end']+OFFSET,'text':' '.join(x['word'] for x in current)});current=[]
if current:cues.append({'start':current[0]['start']+OFFSET,'end':current[-1]['end']+OFFSET,'text':' '.join(x['word'] for x in current)})
def stamp(v):return f'{int(v//3600):02}:{int(v//60)%60:02}:{v%60:06.3f}'
(O/'welcome.vtt').write_text('WEBVTT\n\n'+'\n\n'.join(f"{stamp(c['start'])} --> {stamp(c['end'])}\n{c['text']}" for c in cues)+'\n')
(P/'timeline.json').write_text(json.dumps({'duration':TOTAL,'voice_offset':OFFSET,'voice_speed':1,'captions':cues,'shots':[{'asset':'scene-1','in':0,'out':3.5,'start':0},{'asset':'scene-1','in':4,'out':8.5,'start':3.5},{'asset':'scene-2','in':1,'out':3,'start':8},{'asset':'real-app-review','start':10,'end':15},{'asset':'scene-3','in':5,'out':10,'start':15},{'asset':'end-graphic','start':20,'end':22.5}]},indent=2))
# Decode retained footage only. No speed changes, repeated frames or loops.
segments=[(0,3.5,1,0),(3.5,8,1,4),(8,10,2,1),(15,20,3,5)]
readers={}
for st,en,num,si in segments:
 readers[st]=subprocess.Popen([FF,'-v','error','-ss',str(si),'-i',str(A/f'scene-{num}.mp4'),'-t',str(en-st),'-vf',f'scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},fps={FPS}','-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
review=Image.open(P.parent/'narrated-series/assets/confirmation.png').convert('RGB')
# Use the actual confirmation panel only; no invented app UI or milk amount.
review=review.crop((25,1270,1180,2300));review.thumbnail((652,650))
log=(P/'render.log').open('w')
enc=subprocess.Popen([FF,'-y','-f','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','-','-an','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p',str(O/'picture.mp4')],stdin=subprocess.PIPE,stderr=log)
for n in range(int(TOTAL*FPS)):
 t=n/FPS; segment=next((s for s in segments if s[0]<=t<s[1]),None)
 if segment:
  raw=readers[segment[0]].stdout.read(W*H*3)
  if len(raw)!=W*H*3:raise RuntimeError('Missing source frame')
  im=Image.frombytes('RGB',(W,H),raw)
 else:im=Image.new('RGB',(W,H),'#102b2d')
 d=ImageDraw.Draw(im)
 if 10<=t<15:
  text(d,'Review. Then confirm.',170,40)
  text(d,'Example from Nam Illam',230,24,'#b8d4ce',font)
  slide=round(22*max(0,1-(t-10)/.35)**2)
  im.paste(review,((W-review.width)//2,340+slide));d=ImageDraw.Draw(im)
 elif t>=20:
  text(d,'NAM ILLAM',320,24,'#ffdc69');text(d,'A little more',455,52);text(d,'together.',520,52)
  d.rounded_rectangle((205,700,515,780),40,fill='#ffdc69');text(d,'Get started',721,30,'#102b2d')
 else:
  # Single concise status overlay, synthetic illustration, never masquerading as app UI.
  label='A new day at home' if t<3.5 else ('Today · Check your tasks' if t<5.3 else ('Pantry → Shopping' if t<8 else ('Pick up what’s missing' if t<10 else 'Back home. Stock updated.')))
  d.rounded_rectangle((45,65,675,138),26,fill='#102b2d');text(d,label,86,27,'#fff3c8')
 cue=next((c for c in cues if c['start']<=t<c['end']+.035),None)
 if cue:
  lines=[];line='';f=ImageFont.truetype(bold,34)
  for word in cue['text'].split():
   test=(line+' '+word).strip()
   if d.textlength(test,font=f)>590:lines.append(line);line=word
   else:line=test
  lines.append(line); y=1070
  d.rounded_rectangle((35,y-20,685,y+len(lines)*45+18),22,fill='#102023')
  for j,line in enumerate(lines):text(d,line,y+j*45,34)
 enc.stdin.write(im.tobytes())
 if n==24:im.save(O/'welcome.jpg',quality=92)
enc.stdin.close();assert enc.wait()==0
for r in readers.values():r.stdout.close();r.wait()
# Original instrumental synthesis, no external samples. Quiet under unchanged narration.
R=48000; N=int(TOTAL*R); bed=np.zeros(N,dtype=np.float32)
for b,at in enumerate(np.arange(0,TOTAL,3.2)):
 for j,note in enumerate([[57,60,64],[53,57,60],[48,52,55],[55,59,62]][b%4]):
  start=at+j*.22;length=min(3.5,TOTAL-start)
  if length<=0:continue
  tt=np.arange(int(length*R))/R;env=(1-np.exp(-tt/.1))*np.exp(-tt/1.3)*np.minimum(1,(length-tt)/.3)
  tone=np.sin(2*np.pi*(440*2**((note-69)/12))*tt)*env*.025
  pos=int(start*R);end=min(N,pos+len(tone));bed[pos:end]+=tone[:end-pos]
tt=np.arange(N)/R;bed*=np.minimum(1,tt/.4)*np.minimum(1,(TOTAL-tt)/1.3)
with wave.open(str(A/'music.wav'),'wb') as f:f.setparams((1,2,R,0,'NONE','not compressed'));f.writeframes((bed*32767).astype('<i2').tobytes())
subprocess.run([FF,'-y','-i',str(O/'picture.mp4'),'-i',str(A/'janet.mp3'),'-i',str(A/'music.wav'),'-filter_complex',f'[1:a]adelay=500:all=1,apad=whole_dur={TOTAL}[v];[v][2:a]amix=inputs=2:duration=longest:normalize=0,loudnorm=I=-16:TP=-1.5:LRA=11[a]','-map','0:v','-map','[a]','-c:v','copy','-c:a','aac','-ar','48000','-b:a','192k','-movflags','+faststart',str(O/'nam-illam-welcome.mp4')],check=True,stdout=subprocess.DEVNULL,stderr=log)
print('Rendered',TOTAL,'seconds')
