"""Export unretouched app screenshots and contact sheets from native simulator captures."""
import os,sys,json,subprocess,shutil,hashlib
from pathlib import Path
from PIL import Image,ImageDraw
import imageio_ffmpeg
root=Path(__file__).resolve().parent.parent
env=dict(os.environ,DEVELOPER_DIR='/Applications/Xcode.app/Contents/Developer')
name=sys.argv[1]
attachments=Path('/tmp')/('NamIllam79-'+name+'-attachments')
attachments.mkdir(exist_ok=True)
if not (attachments/'manifest.json').exists(): subprocess.run(['xcrun','xcresulttool','export','attachments','--path','/tmp/NamIllam79-'+name+'.xcresult','--output-path',str(attachments)],env=env,check=True,capture_output=True)
output=root/'screenshots'/name;output.mkdir(parents=True,exist_ok=True)
records=[]
for test in json.loads((attachments/'manifest.json').read_text()):
    for a in test['attachments']:
        human=a.get('suggestedHumanReadableName','')
        if not human.startswith('Preview-') or not a['exportedFileName'].endswith('.png'):continue
        target=output/(human.split('_')[0]+'.png')
        shutil.copyfile(attachments/a['exportedFileName'],target)
        im=Image.open(target)
        assert im.mode=='RGB' or ('A' in im.getbands() and im.getextrema()[-1]==(255,255))
        records.append(dict(file=str(target.relative_to(root)),width=im.width,height=im.height,sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
(root/'validation').mkdir(exist_ok=True)
(root/'validation'/(name+'.json')).write_text(json.dumps(records,indent=2))
video=root/'preview'/'source'/(name+'-walkthrough.mov')
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-i',str(video),'-vf','fps=1/5,scale=150:-1,tile=8x4','-frames:v','1',str(root/'validation'/(name+'-contact.png'))],check=True,capture_output=True)
print(name,len(records),'screenshots exported')
