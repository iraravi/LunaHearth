"""Real-screen guided transitions, continuous approved Janet audio, provider timings.
No speech generation here. Rebuild the two authorized guides without consuming quota.
"""
from pathlib import Path
import json,math,re,textwrap,subprocess,sys
from PIL import Image,ImageDraw,ImageFont
import imageio_ffmpeg
from plan import GUIDES
P=Path(__file__).parent; OUT=P/'publish'; SOURCE=P/'voice-janet'; CACHE=P/'audio'/'janet';CACHE.mkdir(parents=True,exist_ok=True)
FF=imageio_ffmpeg.get_ffmpeg_exe();W,H,FPS=1280,720,24
FONT='/System/Library/Fonts/Supplemental/Arial.ttf';BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
fonts={}
def font(n,b=False):
 k=(n,b)
 if k not in fonts:fonts[k]=ImageFont.truetype(BOLD if b else FONT,n)
 return fonts[k]
def text(d,xy,s,n=24,color='#f3f5f8',bold=False):d.multiline_text(xy,s,font=font(n,bold),fill=color,spacing=7)
def ease(t):t=max(0,min(1,t));return t*t*(3-2*t)
def rounded(d,b,fill,r=18,outline=None,width=1):d.rounded_rectangle(b,r,fill=fill,outline=outline,width=width)
def ts(t):return f'{int(t//3600):02d}:{int(t//60)%60:02d}:{t%60:06.3f}'
def norm(s):return re.sub('[^a-z0-9]','',s.lower())

def timeline(slug):
 title,_,scenes=GUIDES[slug];data=json.loads((SOURCE/f'{slug}.json').read_text())
 words=[x for x in data['word_timestamps'] if not x['word'].startswith('<')]
 assert [norm(x) for x in data['request']['text'].split()]==[norm(w['word']) for w in words]
 assert all(0<=w['start']<=w['end']<=data['duration'] for w in words)
 at=0;beats=[]
 for i,s in enumerate(scenes):
  count=len(s['narration'].split());sw=words[at:at+count];at+=count
  beats.append(dict(s,start=0 if i==0 else sw[0]['start'],spoken_start=sw[0]['start'],words=sw))
 for i,b in enumerate(beats):b['end']=beats[i+1]['start'] if i+1<len(beats) else data['duration']
 cues=[];group=[]
 for i,w in enumerate(words):
  group.append(w);line=' '.join(x['word'] for x in group)
  sentence=w['word'].endswith(('.', '?','!'))
  if len(line)>=60 or (sentence and len(line)>=24) or i==len(words)-1:
   end=min(data['duration'],words[i+1]['start'] if i+1<len(words) else data['duration'])
   cues.append(dict(start=group[0]['start'],end=end,text=line));group=[]
 assert ' '.join(c['text'] for c in cues)== ' '.join(w['word'] for w in words)
 (OUT/f'{slug}-janet.vtt').write_text('WEBVTT\n\n'+'\n\n'.join(f"{ts(c['start'])} --> {ts(c['end'])}\n{c['text']}" for c in cues)+'\n')
 result={'title':title,'duration':data['duration'],'voice':'Janet - Warm & Approachable','engine':data['engine'],'speed':1,'listening_review':'not_performed','timing_source':'HeyGen word timestamps, token-by-token checked against submitted script','scenes':[{k:v for k,v in b.items() if k!='words'} for b in beats],'captions':cues}
 (SOURCE/f'{slug}-timeline.json').write_text(json.dumps(result,indent=2)+'\n')
 return data,beats,cues

class Screens:
 def __init__(self):self.imgs={};self.scaled={}
 def raw(self,key):
  if key not in self.imgs:self.imgs[key]=Image.open(P/'assets'/f'{key}.png').convert('RGB')
  return self.imgs[key]
 def viewport(self,key,offset=0):
  if key not in self.scaled:
   a=self.raw(key);crop=a.crop((0,180,a.width,a.height-120));self.scaled[key]=crop.resize((486,round(crop.height*486/a.width)),Image.Resampling.LANCZOS)
  a=self.scaled[key];off=max(0,min(a.height-510,int(offset)));return a.crop((0,off,486,off+510))

def ring(im,point,t):
 if not 0<=t<=.75:return im
 d=ImageDraw.Draw(im);x,y=point;r=15+22*ease(t/.75)
 d.ellipse((x-r,y-r,x+r,y+r),outline='#ffda48',width=4)
 d.ellipse((x-6,y-6,x+6,y+6),fill='#ffda48');return im

def push(a,b,t):
 f=ease(t/.42);off=round(486*f);im=Image.new('RGB',(486,510),'#101216')
 im.paste(a,(-off,0));im.paste(b,(486-off,0));return im

def screen_for(screens,slug,ix,beat,local):
 key=beat['image'];span=beat['end']-beat['start']
 # Teaching transitions use exact app screenshots. Tap rings are explanatory overlays.
 if slug=='connected-kitchen' and ix==0:
  a=screens.viewport('Home',260*ease(local/.55));b=screens.viewport('Pantry')
  if local<1.25:
   ring(a,(130,300),local-.5);return a,'Home → tap Pantry'
  if local<1.67:return push(a,b,local-1.25),'Opening Pantry'
 if slug=='connected-kitchen' and ix==1:
  home=screens.viewport('Home',260);shopping=screens.viewport('Shopping');add=screens.viewport('Shopping-Add')
  if local<1.0: return ring(home,(352,300),local-.3),'Home → tap Shopping'
  if local<1.42:return push(home,shopping,local-1),'Opening Shopping'
  if local<2.5:return ring(shopping,(438,28),local-1.8),'Shopping → tap +'
  if local<2.92:return push(shopping,add,local-2.5),'Add an item'
 if slug=='connected-kitchen' and ix==2:
  expense=screens.viewport('Expenses');receipt=screens.viewport('overview')
  if local<2.0:return ring(expense,(293,28),local-1.25),'Expenses → tap Scan receipt'
  if local<2.42:return push(expense,receipt,local-2),'Review the scanned receipt'
 if slug=='create-home' and ix==1:
  welcome=screens.viewport('Welcome',390);form=screens.viewport('CreateHome')
  if local<.7:return ring(welcome,(243,345),local),'Tap Create a new home'
  if local<1.12:return push(welcome,form,local-.7),'Name your home'
 # Scroll the real screen only after its heading and primary controls have held.
 if key not in screens.scaled:screens.viewport(key)
 maxoff=max(0,screens.scaled[key].height-510)
 offset=maxoff*ease((local/span-.32)/.55)
 shot=screens.viewport(key,offset)
 return shot,beat['route']

def render(slug,preview=False):
 data,beats,cues=timeline(slug);duration=data['duration'];screens=Screens()
 # Cache all actual-screen assets; graphical layers do not alter app pixels.
 for key in {b['image'] for b in beats}|{'Home','Shopping','Welcome','CreateHome','Pantry','Shopping-Add'}:screens.viewport(key)
 mask=Image.new('L',(486,510));ImageDraw.Draw(mask).rounded_rectangle((0,0,485,509),20,fill=255)
 def frame(t):
  ix=max(i for i,b in enumerate(beats) if b['start']<=t);b=beats[ix];local=t-b['start'];span=b['end']-b['start']
  im=Image.new('RGB',(W,H),'#0b0e13');d=ImageDraw.Draw(im)
  text(d,(48,30),'NAM ILLAM',19,bold=True);text(d,(970,32),'GUIDED APP WALKTHROUGH',12,color='#bac3d0')
  d.line((48,72,1232,72),fill='#2a3442',width=1)
  # One strong teaching headline and a quiet chapter marker.
  text(d,(48,112),f'STEP {ix+1:02d} / {len(beats):02d}',14,color='#ffda48',bold=True)
  text(d,(48,160),b['title'],44,bold=True)
  route=b['route'];route_lines=textwrap.fill(route,40)
  rounded(d,(48,306,656,395),'#19222d',16)
  text(d,(68,326),route_lines,22,bold=True)
  shot,active=screen_for(screens,slug,ix,b,local)
  # Speech-led process graphics: build only the current teaching state.
  if slug=='connected-kitchen':
   labels=['PANTRY','SHOPPING','EXPENSES'];sub=['What you have','What you buy','What you spend'];active_ix=0 if ix in (0,4) else 1 if ix in (1,5,6) else 2
  else:labels=['CHOOSE','NAME','BEGIN'];sub=['A new home','Make it yours','Start your day'];active_ix=min(ix,2)
  text(d,(48,432),'YOUR CONNECTED HOME' if slug=='connected-kitchen' else 'A SIMPLE START',12,color='#aeb9c8',bold=True)
  for j,label in enumerate(labels):
   x=48+j*211;is_active=j==active_ix
   rounded(d,(x,471,x+185,550),'#ffda48' if is_active else '#19222d',16)
   text(d,(x+17,484),label,16,color='#0b0e13' if is_active else '#d4dce7',bold=True)
   text(d,(x+17,514),sub[j],13,color='#343020' if is_active else '#aeb9c8')
   if j<2:
    y=507;d.line((x+190,y,x+204,y),fill='#8995a7',width=3);d.polygon([(x+204,y),(x+198,y-5),(x+198,y+5)],fill='#8995a7')
  # A brief underline draws attention once on entry, then remains still.
  x=48+active_ix*211;d.line((x+18,559,x+18+round(147*ease(local/.6)),559),fill='#ffda48',width=4)
  text(d,(48,591),'Real app screens · animated guidance · sample data',14,color='#9daabb')
  rounded(d,(704,90,1222,632),'#273342',26);im.paste(shot,(720,106),mask);d=ImageDraw.Draw(im)
  # Separate route label below screenshot, never covering the app controls.
  rounded(d,(720,584,1206,616),'#121a24',9);text(d,(734,591),textwrap.shorten(active,width=59,placeholder='…'),13,color='#ffda48',bold=True)
  rounded(d,(0,647,W,H),'#151e29',0)
  c=next((c for c in cues if c['start']<=t<c['end']),None)
  if c:
   lines=textwrap.wrap(c['text'],83);text(d,(48,657),'\n'.join(lines),23)
   for line in lines:assert d.textlength(line,font=font(23))<=1184
  d.rectangle((0,716,round(W*t/duration),719),fill='#ffda48')
  return im
 for j,t in enumerate([.9,1.5,3.2,beats[1]['start']+.6,beats[1]['start']+2,beats[-1]['start']+1]):frame(t).save(CACHE/f'{slug}-qa-{j}.jpg',quality=90)
 if preview:return
 silent=CACHE/f'{slug}-silent.mp4';log=(CACHE/f'{slug}-encode.log').open('w')
 proc=subprocess.Popen([FF,'-y','-f','rawvideo','-pix_fmt','rgb24','-s','1280x720','-r',str(FPS),'-i','-','-an','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p',str(silent)],stdin=subprocess.PIPE,stderr=log)
 for n in range(math.ceil(duration*FPS)):proc.stdin.write(frame(n/FPS).tobytes())
 proc.stdin.close();assert proc.wait()==0;log.close()
 # Preserve speech at 1x. Resampling and loudness normalization never change duration.
 subprocess.run([FF,'-y','-i',str(silent),'-i',str(SOURCE/f'{slug}.mp3'),'-map','0:v:0','-map','1:a:0','-c:v','copy','-af','loudnorm=I=-16:TP=-1.5:LRA=11','-ar','48000','-c:a','aac','-b:a','160k','-movflags','+faststart',str(OUT/f'{slug}-janet.mp4')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 frame(3.2).save(OUT/f'{slug}-janet.jpg',quality=90)
 print('Rendered',slug,round(duration,2),'seconds',flush=True)
if __name__=='__main__':
 for slug in ['connected-kitchen','create-home']:render(slug,'--preview' in sys.argv)
