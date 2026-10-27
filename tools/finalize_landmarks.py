from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import sys, subprocess, json
root=Path(__file__).resolve().parents[1]
helper=Path(r'C:\Users\amin\.gapcode\skills\.system\imagegen\scripts\remove_chroma_key.py')
manifest=json.loads((root/'docs/asset_manifest.json').read_text(encoding='utf-8'))
for path in sorted((root/'assets/images').glob('landmark_*.png')):
    raw=root/'tools/generated_sources'/path.name
    if not raw.exists():raw.write_bytes(path.read_bytes())
    im=Image.open(raw).convert('RGBA')
    if im.getextrema()[3][0]==255:
        subprocess.run([sys.executable,str(helper),'--input',str(raw),'--out',str(path),'--auto-key','border','--soft-matte','--transparent-threshold','12','--opaque-threshold','220','--despill'],check=True,capture_output=True)
        im=Image.open(path).convert('RGBA')
    im.resize((512,512),Image.Resampling.LANCZOS).save(path,optimize=True)
    manifest=[r for r in manifest if r['name']!=path.stem]
    manifest.append({'name':path.stem,'file':str(path.relative_to(root)).replace('\\','/'),'size':[512,512],'generated_with':'built-in image_gen','date':'2026-10-27','prompt':'Modern flat illustration, soft 3D shading, cream/navy/gold, upper-left light, secular friendly city landmark '+path.stem+', no text, transparent background, padding.'})
(root/'docs/asset_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
files=sorted((root/'assets/images').rglob('*.png'))
sheet=Image.new('RGB',(1000,((len(files)+5)//6)*155),'#FAF6EE');d=ImageDraw.Draw(sheet)
for i,path in enumerate(files):
    im=Image.open(path).convert('RGBA');im.thumbnail((150,120))
    x=(i%6)*166+(166-im.width)//2;y=(i//6)*155
    sheet.paste(im,(x,y),im);d.text(((i%6)*166+4,y+125),path.stem[:23],fill='#1E3A5F')
sheet.save(root/'docs/asset_contact_sheet.jpg')
guide=root/'assets/ASSET_GUIDE.md'
with guide.open('a',encoding='utf-8') as f:
    f.write('\n## Five additional landmarks (2026-10-27)\nBuilt-in image_gen; one image per request. Common prompt: modern flat illustration + soft 3D shading, cream/navy/gold, upper-left light, secular friendly city, no text, transparency and padding. Subjects: start square with abstract coin statue and gate; police station with bars; leafy city park and bench; arrow sign with police badge; civic bank with dome. PNG 512×512, connected in SpaceWidget.\n')
print('42 image files prepared; contact sheet ready')
