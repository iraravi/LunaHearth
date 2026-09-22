#!/usr/bin/env python3
"""Package unretouched XCUI screenshots, validate sizes, and build a local gallery."""
import argparse, hashlib, html, json, os, pathlib, shutil, subprocess, tempfile
p = argparse.ArgumentParser()
p.add_argument('--phone', required=True); p.add_argument('--ipad', required=True)
p.add_argument('--output', default='docs/release/1.0-build54')
a = p.parse_args(); root = pathlib.Path(a.output)
env = dict(os.environ, DEVELOPER_DIR='/Applications/Xcode.app/Contents/Developer')
records=[]
for result, folder, expected in [(a.phone,'iphone-6.9',(1320,2868)), (a.ipad,'ipad-13',(2064,2752))]:
    with tempfile.TemporaryDirectory() as temporary:
        subprocess.run(['xcrun','xcresulttool','export','attachments','--path',result,'--output-path',temporary],env=env,check=True,capture_output=True)
        manifest=json.loads((pathlib.Path(temporary)/'manifest.json').read_text())
        captures=[item for test in manifest if test['testIdentifier']=='VisualFlowTests/testAppStoreScreenshots()' for item in test['attachments'] if item.get('suggestedHumanReadableName','').startswith('Store-') and item['exportedFileName'].endswith('.png')]
        assert len(captures)==6, f'{folder}: expected six captures, found {len(captures)}'
        for item in captures:
            name=item['suggestedHumanReadableName'].split('_')[0]
            source=pathlib.Path(temporary)/item['exportedFileName']
            output=root/'screenshots'/folder/(name+'.png'); output.parent.mkdir(parents=True,exist_ok=True)
            # Preserve the exact simulator capture; no cropping, resizing or invented UI.
            shutil.copyfile(source, output)
            alpha=subprocess.check_output(['sips','-g','hasAlpha',str(output)],text=True)
            assert 'hasAlpha: no' in alpha, 'Screenshot must be opaque'
            info=subprocess.check_output(['sips','-g','pixelWidth','-g','pixelHeight',str(output)],text=True)
            dimensions=tuple(int(line.split(':')[1]) for line in info.splitlines() if 'pixelWidth:' in line or 'pixelHeight:' in line)
            assert dimensions==expected, (str(output),dimensions,expected)
            records.append({'file':str(output.relative_to(root)),'pixels':dimensions,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'source_result':result,'sample_data':True})
records.sort(key=lambda r:r['file'])
(root/'validation/screenshots.json').write_text(json.dumps(records,indent=2)+'\n')
style='body{font:17px/1.5 system-ui;background:#f5f7f5;color:#20372d;max-width:1450px;margin:auto;padding:32px}h1{font-size:42px}section{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:22px}figure{margin:0;background:white;padding:14px;border-radius:20px}img{width:100%;border-radius:12px}figcaption{margin:12px 0}a{color:#245f46}.note{background:#fff0d7;padding:20px;border-radius:16px}'
parts=['<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>LunaHearth release gallery</title><style>'+style+'</style><h1>LunaHearth · 1.0 (54)</h1><p>Actual app captures · Fictional Maple House household</p><p class="note">Candidate assets. Public launch still requires the checks in <a href="README.md">README</a>. No upload has been performed.</p>']
for folder,title in [('iphone-6.9','iPhone · 6.9-inch'),('ipad-13','iPad · 13-inch')]:
    parts.append('<h2>'+title+'</h2><section>')
    for record in records:
        if folder not in record['file']: continue
        path=html.escape(record['file']); title=pathlib.Path(record['file']).stem.replace('Store-','').replace('-',' · ')
        parts.append(f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(title)}"></a><figcaption>{html.escape(title)}</figcaption></figure>')
    parts.append('</section>')
(root/'index.html').write_text(''.join(parts)+'</html>')
print(f'Validated {len(records)} screenshots and wrote {root}/index.html')
