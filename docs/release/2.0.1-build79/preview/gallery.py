from pathlib import Path
import json,html
root=Path(__file__).resolve().parent.parent
parts=['''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Nam Illam · Publishing media</title><style>body{font:16px -apple-system,BlinkMacSystemFont,sans-serif;background:#f5f5f7;color:#171719;margin:0;padding:clamp(20px,4vw,64px);max-width:1500px;margin:auto}h1{font-size:clamp(32px,5vw,64px);letter-spacing:-.05em;margin-bottom:12px}h2{margin-top:56px}p{line-height:1.6;color:#555}section{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px}figure{background:white;margin:0;padding:14px;border-radius:18px}img,video{width:100%;max-height:620px;object-fit:contain;border-radius:10px;background:#171719}figcaption{padding:14px 2px 4px}a{color:inherit}aside{padding:16px;background:#fff1d3;border-radius:12px}</style><h1>Your home, brought to life.</h1><p>Nam Illam 2.0.1 · Candidate build 79<br>Real app captures. Fictional Maple House household. No personal records.</p><aside>Review package — not uploaded or submitted. All four device-layout captures are complete. Final encodes were frame-reviewed and fully decoded; continuous normal-speed playback review and upload remain pending. Build 78 remains the current TestFlight build.</aside>''']
for name,title in [('iphone-max','iPhone Pro Max'),('iphone-pro','iPhone Pro'),('ipad','iPad Pro'),('iphone-duo','iPhone Duo')]:
 parts.append('<h2>'+title+'</h2><section>')
 video='preview/'+name+'-app-preview.mp4'
 edit=json.loads((root/'preview'/(name+'-timeline.json')).read_text())
 parts.append(f'<figure><video controls preload="metadata" src="{video}"></video><figcaption><a href="{video}">App preview · {edit["duration"]:.1f} seconds</a></figcaption></figure>')
 for p in sorted((root/'screenshots'/name).glob('*.png')):
  rel=p.relative_to(root).as_posix();label=p.stem.split('-',2)[-1]
  parts.append(f'<figure><a href="{rel}"><img loading="lazy" src="{rel}" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)}</figcaption></figure>')
 parts.append('</section>')
parts.append('</html>');(root/'index.html').write_text('\n'.join(parts))
