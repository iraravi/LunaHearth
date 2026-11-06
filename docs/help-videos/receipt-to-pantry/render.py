"""Reproducible 60-second captioned guide. Pillow + imageio-ffmpeg, build-time only."""
from PIL import Image, ImageDraw, ImageFont
import math, subprocess, pathlib, imageio_ffmpeg
P=pathlib.Path(__file__).parent; OUT=P/'hostinger'; OUT.mkdir(exist_ok=True)
W,H,FPS=1280,720,24
FONT='/System/Library/Fonts/Supplemental/Arial.ttf'; BOLD='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
def font(n,b=False): return ImageFont.truetype(BOLD if b else FONT,n)
BG=(12,15,20); FG=(246,247,249); MUT=(170,180,193); Y=(255,211,66); GREEN=(102,222,173)
scenes=[(0,7,'RECEIPTS, MADE SIMPLE','From receipt\nto pantry.','Scan. Check. Choose. Save.','A one-minute guide using sample data.'),
(7,17,'01 / SCAN','Start with\na clear receipt.','Open Home → Expenses → Scan receipt.','Photograph the full receipt or choose a photo.'),
(17,29,'02 / REVIEW','Check the total.\nThen the details.','Compare the amount and currency with your receipt.','Edit names, prices and quantities before saving.'),
(29,42,'03 / CHOOSE','Your pantry.\nYour choice.','Use Add all, or tap individual item cards.','Choose food kept at home. Leave meals out unselected.'),
(42,53,'04 / CONFIRM','Review once.\nSave with confidence.','Choose Save & update pantry for selected items.','Or save the expense without adding inventory.'),
(53,60,'READY FOR NEXT TIME','Spending recorded.\nPantry in order.','Scan → review → choose → save.','Always check scanned details against the original.')]
imgs={}
for k in ['overview','selection','confirmation']:
 f=P/'assets'/f'{k}.png'
 if f.exists(): imgs[k]=Image.open(f).convert('RGB')
def rr(d,box,fill,r=20,outline=None,width=1): d.rounded_rectangle(box,r,fill=fill,outline=outline,width=width)
def text(d,xy,t,n=24,fill=FG,b=False,spacing=10): d.multiline_text(xy,t,font=font(n,b),fill=fill,spacing=spacing)
def ease(x): x=max(0,min(1,x)); return 1-(1-x)**3
def draw(t):
 idx=next(i for i,s in enumerate(scenes) if s[0]<=t<s[1]); a,b,k,title,line,sub=scenes[idx]; q=(t-a)/(b-a)
 im=Image.new('RGB',(W,H),BG); d=ImageDraw.Draw(im)
 # restrained radial glow and a fine architectural grid
 for x in range(700,1280,60): d.line((x,85,x,600),fill=(19,25,31))
 for y in range(85,601,60): d.line((700,y,1240,y),fill=(19,25,31))
 text(d,(56,34),'NAM ILLAM',19,FG,True); text(d,(1000,36),'QUICK GUIDE  /  01',13,MUT,True)
 d.line((56,75,1224,75),fill=(42,48,58))
 offset=int(22*(1-ease((t-a)/.65)))
 text(d,(56,125+offset),k,15,Y,True)
 text(d,(52,171+offset),title,49,FG,True,12)
 # concise instruction card
 rr(d,(56,346,650,478),(24,29,36),18)
 text(d,(78,368),line,20,FG,True)
 # wrap caption to fit readable area
 import textwrap
 text(d,(78,408),'\n'.join(textwrap.wrap(sub,48)),19,MUT,False,6)
 for j,label in enumerate(['SCAN','REVIEW','CHOOSE','SAVE']):
  x=58+j*150; active=(idx==j+1 or idx==5)
  rr(d,(x,521,x+128,558),Y if active else (27,33,41),10)
  text(d,(x+15,532),label,13,BG if active else MUT,True)
 if idx in [2,3,4]:
  key=['overview','selection','confirmation'][idx-2]; src=imgs[key]
  # Screenshot is a real app capture; pan within it to magnify the relevant section.
  if idx==2: crop=(0,350,src.width,min(src.height,1750))
  elif idx==3: crop=(0,min(1100,src.height//3),src.width,min(src.height,2600))
  else: crop=(0,int(src.height*.45),src.width,src.height)
  region=src.crop(crop); sw=472; sh=int(region.height*sw/region.width)
  region=region.resize((sw,sh),Image.Resampling.LANCZOS)
  # fixed viewport with gentle content pan
  vh=480; ypan=int(max(0,sh-vh)*ease(q)); region=region.crop((0,ypan,sw,ypan+vh))
  rr(d,(704,101,1200,613),(38,45,54),30)
  mask=Image.new('L',(sw,vh),0); ImageDraw.Draw(mask).rounded_rectangle((0,0,sw,vh),22,fill=255)
  im.paste(region,(716,113),mask); d=ImageDraw.Draw(im)
  text(d,(732,590),'ACTUAL APP SCREENS · SAMPLE DATA',11,MUT,True)
  # animated focus ring, not a simulated user selection
  px,py=(945,270) if idx==2 else ((840,400) if idx==3 else (953,400))
  pulse=(t-a)%2.5
  if pulse<1.3:
   r=14+int(pulse*22); d.ellipse((px-r,py-r,px+r,py+r),outline=Y,width=3)
 elif idx==1:
  rr(d,(792,112,1135,574),(242,241,234),16)
  text(d,(825,151),'FRESH MARKET',24,BG,True)
  text(d,(825,201),'SAMPLE RECEIPT',12,(90,98,105))
  for n,(name,cost) in enumerate([('Curd','$3.99'),('Bananas','$2.49')]):
   y=266+n*56;text(d,(825,y),name,20,BG);text(d,(1030,y),cost,20,BG)
  d.line((824,396,1104,396),fill=(180,182,179),width=2)
  text(d,(825,422),'TOTAL',20,BG,True);text(d,(1002,416),'$6.48',30,BG,True)
  scanY=230+int(245*((t-a)%3)/3);d.line((766,scanY,1160,scanY),fill=Y,width=4)
  text(d,(824,539),'ILLUSTRATED SCAN',12,(90,98,105),True)
 else:
  for j,(lab,detail,col) in enumerate([('01','Receipt checked',Y),('02','Items selected',(112,202,255)),('03','Ready to save',GREEN)]):
   y=150+j*142+int(12*math.sin(t*.65+j)); x=728+int(6*math.sin(t*.5+j))
   rr(d,(x,y,x+464,y+112),(28,34,43),22,outline=(48,57,69))
   rr(d,(x+20,y+25,x+80,y+85),col,16);text(d,(x+34,y+44),lab,20,BG,True)
   text(d,(x+104,y+43),detail,25,FG,True)
 # burned-in captions, progress, and explicit sound-independent playback
 d.rectangle((0,642,W,H),fill=(18,22,28))
 text(d,(56,662),sub,21,FG)
 text(d,(1105,666),f'{int(t):02d} / 60',15,MUT)
 d.rectangle((0,714,int(W*t/60),720),fill=Y)
 # short fades at chapter boundaries, no flashing
 fade=min(1,(t-a)/.28,(b-t)/.28)
 if fade<1: im=Image.blend(Image.new('RGB',(W,H),BG),im,max(0,fade))
 return im
if __name__=='__main__':
 if len(imgs)!=3: raise SystemExit('Provide reviewed app captures in assets first.')
 ff=imageio_ffmpeg.get_ffmpeg_exe()
 proc=subprocess.Popen([ff,'-y','-f','rawvideo','-vcodec','rawvideo','-pix_fmt','rgb24','-s',f'{W}x{H}','-r',str(FPS),'-i','-','-an','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(OUT/'receipt-to-pantry.mp4')],stdin=subprocess.PIPE,stderr=open('/tmp/namillam-video-encode.log','w'))
 for frame in range(60*FPS):
  pic=draw(frame/FPS);proc.stdin.write(pic.tobytes())
  if frame in [72,240,528,840,1128,1368]:pic.save(OUT/f'preview-{frame//FPS:02d}.jpg',quality=90)
 proc.stdin.close();assert proc.wait()==0
 draw(3).save(OUT/'poster.jpg',quality=92)
 print(OUT/'receipt-to-pantry.mp4')
