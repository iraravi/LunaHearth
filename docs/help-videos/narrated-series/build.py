"""Narrated, actual-screen help library. Build-only dependencies; no app networking."""
from pathlib import Path
import sys,subprocess,json,math,textwrap,wave,shutil
from PIL import Image,ImageDraw,ImageFont
import imageio_ffmpeg
from plan import GUIDES
P=Path(__file__).parent; OUT=P/'publish'; AUDIO=P/'audio'; AUDIO.mkdir(exist_ok=True); OUT.mkdir(exist_ok=True)
FF=imageio_ffmpeg.get_ffmpeg_exe(); FPS=24; W,H=1280,720
F='/System/Library/Fonts/Supplemental/Arial.ttf'; B='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
fonts={}
def ft(n,b=False):
 key=(n,b)
 if key not in fonts:fonts[key]=ImageFont.truetype(B if b else F,n)
 return fonts[key]
def tx(d,pos,t,n=22,c='#f5f6fa',b=False):d.multiline_text(pos,t,font=ft(n,b),fill=c,spacing=8)
def rr(d,box,c,r=20):d.rounded_rectangle(box,r,fill=c)
def run(cmd):subprocess.run(cmd,check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
def stamp(t):return f'{int(t//60):02d}:{t%60:06.3f}'
def voice(slug,scenes,duration):
 folder=AUDIO/slug;folder.mkdir(exist_ok=True);slot=duration/len(scenes);cues=[];rawdur=[]
 for i,s in enumerate(scenes):
  a=folder/f'{i}.aiff';w=folder/f'{i}.wav'
  run(['say','-v','Rishi','-r','155','-o',str(a),s['narration']])
  pcm=folder/f'{i}-raw.wav'
  run([FF,'-y','-i',str(a),'-ar','44100','-ac','1','-c:a','pcm_s16le',str(pcm)])
  with wave.open(str(pcm),'rb') as f: dur=f.getnframes()/f.getframerate()
  speed=max(1,dur/(slot-1));actual=dur/speed;rawdur.append(actual)
  run([FF,'-y','-i',str(a),'-af',f'atempo={speed},adelay=400,apad','-t',str(slot),'-ar','44100','-ac','1','-c:a','pcm_s16le',str(w)])
  chunks=textwrap.wrap(s['narration'],85,break_long_words=False);count=sum(len(c) for c in chunks);start=i*slot+.4
  for c in chunks:
   end=start+actual*len(c)/count;cues.append((start,end,c));start=end
 with wave.open(str(folder/'narration.wav'),'wb') as output:
  output.setnchannels(1);output.setsampwidth(2);output.setframerate(44100)
  for i in range(len(scenes)):
   with wave.open(str(folder/f'{i}.wav'),'rb') as f:output.writeframes(f.readframes(f.getnframes()))
 (OUT/f'{slug}.vtt').write_text('WEBVTT\n\n'+'\n\n'.join(f'{stamp(a)} --> {stamp(b)}\n{c}' for a,b,c in cues)+'\n')
 (OUT/f'{slug}.txt').write_text('\n\n'.join(s['title'].replace('\n',' ')+'\n'+s['narration'] for s in scenes))
 (folder/'cues.json').write_text(json.dumps(cues));return cues

def render(slug,title,duration,scenes,cues):
 imgs={}
 for s in scenes:
  path=P/'assets'/(s['image']+'.png');src=Image.open(path).convert('RGB')
  shot=src.crop((0,180,src.width,max(181,src.height-120)))
  imgs[s['image']]=shot.resize((470,int(shot.height*470/shot.width)),Image.Resampling.LANCZOS)
 slot=duration/len(scenes)
 def frame(t):
  ix=min(len(scenes)-1,int(t/slot));s=scenes[ix];local=t-ix*slot;q=local/slot
  im=Image.new('RGB',(W,H),'#0c0f14');d=ImageDraw.Draw(im)
  tx(d,(52,30),'NAM ILLAM',19,b=True);tx(d,(917,33),'VOICE GUIDE  /  DEMO DATA',13,c='#b2bac8',b=True)
  d.line((52,72,1228,72),fill='#323947')
  tx(d,(54,119),f'{ix+1:02d} / {len(scenes):02d}   '+('CONNECTED KITCHEN' if slug=='connected-kitchen' else title.upper()),14,c='#ffd342',b=True)
  tx(d,(50,170),s['title'],46,b=True)
  rr(d,(54,327,676,411),'#1c232e',16)
  route=textwrap.fill(s['route'],48)
  tx(d,(76,346),route,22,b=True)
  tx(d,(54,443),'FOLLOW THE SAME BUTTONS IN YOUR APP',12,c='#aeb7c6',b=True)
  for j,label in enumerate(['PANTRY','SHOPPING','EXPENSES']):
   x=55+j*204;rr(d,(x,483,x+185,527),'#282f3a',12);tx(d,(x+20,497),label,14,b=True)
   if j<2:tx(d,(x+188,493),'›',22,c='#ffd342',b=True)
  tx(d,(54,552),'Pause or replay any step.',19,c='#aeb7c6')
  shot=imgs[s['image']];rw,rh=shot.size;vh=516
  # All UI pixels are actual screenshots. Slow pan reveals the screen.
  progress=max(0,min(1,(q-.15)/.7));progress=progress*progress*(3-2*progress)
  y=int(max(0,rh-vh)*progress);shot=shot.crop((0,y,rw,y+vh))
  mask=Image.new('L',(rw,vh));ImageDraw.Draw(mask).rounded_rectangle((0,0,rw,vh),20,fill=255)
  rr(d,(714,94,1208,634),'#343d4c',26);im.paste(shot,(726,106),mask);d=ImageDraw.Draw(im)
  tx(d,(744,607),'ACTUAL NAM ILLAM SCREEN',11,c='#cbd2db',b=True)
  rr(d,(0,647,W,H),'#171d26',0)
  caption=next((c for a,b,c in cues if a<=t<b),'')
  if caption:tx(d,(52,660),textwrap.fill(caption,93),20)
  d.rectangle((0,716,int(W*t/duration),720),fill='#ffd342')
  fade=min(1,local/.22,(slot-local)/.22)
  if fade<1:im=Image.blend(Image.new('RGB',(W,H),'#0c0f14'),im,max(0,fade))
  return im
 silent=AUDIO/slug/'silent.mp4';log=open(AUDIO/slug/'encode.log','w')
 proc=subprocess.Popen([FF,'-y','-f','rawvideo','-pix_fmt','rgb24','-s','1280x720','-r',str(FPS),'-i','-','-an','-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p',str(silent)],stdin=subprocess.PIPE,stderr=log)
 for n in range(int(duration*FPS)):proc.stdin.write(frame(n/FPS).tobytes())
 proc.stdin.close();assert proc.wait()==0;log.close()
 run([FF,'-y','-i',str(silent),'-i',str(AUDIO/slug/'narration.wav'),'-map','0:v','-map','1:a','-c:v','copy','-af','loudnorm=I=-16:TP=-1.5:LRA=11','-c:a','aac','-b:a','128k','-t',str(duration),'-movflags','+faststart',str(OUT/f'{slug}.mp4')])
 frame(3).save(OUT/f'{slug}.jpg',quality=90)
 frame(slot+5).save(P/f'qa-{slug}.jpg',quality=90)
 print('Finished',slug,flush=True)
if __name__=='__main__':
 mode=sys.argv[1] if len(sys.argv)>1 else 'all'
 for slug,(title,duration,scenes) in GUIDES.items():
  if mode=='voice':voice(slug,scenes,duration);print('Narrated',slug,flush=True)
  else:
   cues=json.loads((AUDIO/slug/'cues.json').read_text()) if (AUDIO/slug/'cues.json').exists() else voice(slug,scenes,duration)
   render(slug,title,duration,scenes,cues)
