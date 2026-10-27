from pathlib import Path
from PIL import Image
import subprocess, sys, re, json
ROOT=Path(__file__).resolve().parents[1]
helper=Path(r'C:\Users\amin\.gapcode\skills\.system\imagegen\scripts\remove_chroma_key.py')
sizes={'card_back':(512,768),'paper_texture':(1024,1024),'coin':(256,256),'bank_pool':(512,512),'splash_bg':(1080,1920),'menu_bg':(1080,1920),'app_icon':(512,512),'board_bg':(2048,2048),'property_card_frame':(512,768),'dice_rolling_strip':(1536,256),'coin_fly_strip':(1024,256),'contract_seal':(256,256)}
for i in range(1,7):sizes[f'dice_{i}']=(256,256);sizes[f'icons/identity_{i}']=(128,128)
for i in range(1,4):sizes[f'building_l{i}']=(512,512)
for mood in ['normal','rich','broke','jailed','happy']:sizes['avatar_'+mood]=(256,256)
for phase in ['bull','bear','stable']:sizes['phase_'+phase]=(256,256)
for direction in ['up','down']:sizes['ticker_arrow_'+direction]=(64,64)
backgrounds={'paper_texture','splash_bg','menu_bg','app_icon','board_bg'}
raw_dir=ROOT/'tools/generated_sources';raw_dir.mkdir(exist_ok=True)
records=[]
for name,size in sizes.items():
    path=ROOT/f'assets/images/{name}.png'
    if not path.exists():raise FileNotFoundError(path)
    raw=raw_dir/(name.replace('/','_')+'.png')
    if not raw.exists():raw.write_bytes(path.read_bytes())
    image=Image.open(raw).convert('RGBA')
    if name not in backgrounds:
        # Keep tool-produced native alpha; otherwise remove the requested uniform key.
        if image.getextrema()[3][0]==255:
            subprocess.run([sys.executable,str(helper),'--input',str(raw),'--out',str(path),'--auto-key','border','--soft-matte','--transparent-threshold','12','--opaque-threshold','220','--despill'],check=True,capture_output=True)
            image=Image.open(path).convert('RGBA')
    image=image.resize(size,Image.Resampling.LANCZOS)
    image.save(path,optimize=True)
    alpha=image.getchannel('A');coverage=sum(1 for x in alpha.getdata() if x>128)/(size[0]*size[1])
    records.append({'name':name,'file':f'assets/images/{name}.png','size':list(size),'generated_with':'built-in image_gen','date':'2026-10-27','alpha_coverage':round(coverage,3),'transparent_corner':alpha.getpixel((0,0))==0})
    print(name,size,'coverage',round(coverage,3),flush=True)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    path=ROOT/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png';path.parent.mkdir(parents=True,exist_ok=True);Image.open(ROOT/'assets/images/app_icon.png').resize((size,size),Image.Resampling.LANCZOS).save(path)
(ROOT/'docs/asset_manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
spec=(ROOT/'docs/MASTER_SPEC.txt').read_text(encoding='utf-8')
asset_section=spec.split('SECTION 13 —')[1].split('SECTION 14 —')[0]
guide='# راهنمای دارایی‌ها\n\nتولید: ابزار داخلی image_gen، ۲۷ اکتبر ۲۰۲۶. سبک: تصویرسازی تخت مدرن با سایهٔ نرم سه‌بعدی، کرم/سرمه‌ای/طلایی، نور از بالا-چپ.\n\nمنابع اصلی در tools/generated_sources نگهداری شده‌اند. تصاویر پس از تولید به اندازهٔ هدف تبدیل شدند. تصاویر رابط با خروجی شفاف یا حذف پس‌زمینهٔ یکدست پردازش شدند. صدای WAV به صورت محلی ساخته شده و حق استفادهٔ پروژه را دارد. انیمیشن‌های JSON محلی و کنترل‌گرهای PNG هر دو موجودند.\n\n'
guide+='| فایل | ابعاد | سهم پیکسل غیرشفاف | گوشه شفاف |\n|---|---|---|---|\n'
for r in records:guide+=f"| {r['file']} | {r['size'][0]}×{r['size'][1]} | {r['alpha_coverage']} | {r['transparent_corner']} |\n"
guide+='\n## پرامپت‌های مرجع\n\n'+asset_section+'\n## راهبرد تولید\n\nبرای هر تصویر یک درخواست جداگانه ارسال شد. همهٔ درخواست‌ها قید سبک روشن، بدون متن، نور بالا-چپ، بدون نماد سیاسی/مذهبی داشتند. برای تصاویر رابط، پس‌زمینهٔ یکنواخت FF00FF و padding درخواست شد. تصاویر پس‌زمینه full bleed بودند.\n'
(ROOT/'assets/ASSET_GUIDE.md').write_text(guide,encoding='utf-8')
