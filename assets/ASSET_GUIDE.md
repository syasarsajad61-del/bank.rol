# راهنمای دارایی‌ها

تولید: ابزار داخلی image_gen، ۲۷ اکتبر ۲۰۲۶. سبک: تصویرسازی تخت مدرن با سایهٔ نرم سه‌بعدی، کرم/سرمه‌ای/طلایی، نور از بالا-چپ.

منابع اصلی در tools/generated_sources نگهداری شده‌اند. تصاویر پس از تولید به اندازهٔ هدف تبدیل شدند. تصاویر رابط با خروجی شفاف یا حذف پس‌زمینهٔ یکدست پردازش شدند. صدای WAV به صورت محلی ساخته شده و حق استفادهٔ پروژه را دارد. انیمیشن‌های JSON محلی و کنترل‌گرهای PNG هر دو موجودند.

| فایل | ابعاد | سهم پیکسل غیرشفاف | گوشه شفاف |
|---|---|---|---|
| assets/images/card_back.png | 512×768 | 0.785 | True |
| assets/images/paper_texture.png | 1024×1024 | 1.0 | False |
| assets/images/coin.png | 256×256 | 0.515 | True |
| assets/images/bank_pool.png | 512×512 | 0.458 | True |
| assets/images/splash_bg.png | 1080×1920 | 1.0 | False |
| assets/images/menu_bg.png | 1080×1920 | 1.0 | False |
| assets/images/app_icon.png | 512×512 | 1.0 | False |
| assets/images/board_bg.png | 2048×2048 | 1.0 | False |
| assets/images/property_card_frame.png | 512×768 | 0.278 | True |
| assets/images/dice_rolling_strip.png | 1536×256 | 0.314 | True |
| assets/images/coin_fly_strip.png | 1024×256 | 0.357 | True |
| assets/images/contract_seal.png | 256×256 | 0.36 | True |
| assets/images/dice_1.png | 256×256 | 0.297 | True |
| assets/images/icons/identity_1.png | 128×128 | 0.661 | True |
| assets/images/dice_2.png | 256×256 | 0.398 | True |
| assets/images/icons/identity_2.png | 128×128 | 0.611 | True |
| assets/images/dice_3.png | 256×256 | 0.396 | True |
| assets/images/icons/identity_3.png | 128×128 | 0.586 | True |
| assets/images/dice_4.png | 256×256 | 0.406 | True |
| assets/images/icons/identity_4.png | 128×128 | 0.657 | True |
| assets/images/dice_5.png | 256×256 | 0.49 | True |
| assets/images/icons/identity_5.png | 128×128 | 0.612 | True |
| assets/images/dice_6.png | 256×256 | 0.439 | True |
| assets/images/icons/identity_6.png | 128×128 | 0.643 | True |
| assets/images/building_l1.png | 512×512 | 0.556 | True |
| assets/images/building_l2.png | 512×512 | 0.702 | True |
| assets/images/building_l3.png | 512×512 | 0.505 | True |
| assets/images/avatar_normal.png | 256×256 | 0.51 | True |
| assets/images/avatar_rich.png | 256×256 | 0.529 | True |
| assets/images/avatar_broke.png | 256×256 | 0.26 | True |
| assets/images/avatar_jailed.png | 256×256 | 0.492 | True |
| assets/images/avatar_happy.png | 256×256 | 0.391 | True |
| assets/images/phase_bull.png | 256×256 | 0.44 | True |
| assets/images/phase_bear.png | 256×256 | 0.448 | True |
| assets/images/phase_stable.png | 256×256 | 0.276 | True |
| assets/images/ticker_arrow_up.png | 64×64 | 0.238 | True |
| assets/images/ticker_arrow_down.png | 64×64 | 0.351 | True |

## پرامپت‌های مرجع

 ASSET GENERATION (تولید تصویر — ۲۰ asset)
═══════════════════════════════════════════════════════════════════════

🎨 تو قابلیت تولید تصویر داری. برای همه ۲۰ asset بصری از این قابلیت
استفاده کن. هیچ asset با placeholder یا CustomPaint ساده جایگزین نشود.

📐 STYLE BIBLE (اجباری — همه تصاویر با این مشخصات)
────────────────────────────────────────────────────

[ART-01] سبک کلی: «modern flat illustration + soft 3D shading»
         تصویرسازی تخت مدرن با سایه‌های ملایم. حس: دوستانه، زنده،
         قابل اعتماد، ایرانی-مدرن. نور روشن و شاد.

[ART-02] پالت اصلی (تم روشن):
         - Background base: #FAF6EE (کرم روشن)
         - Card surface: #FFFFFF
         - Primary: #1E3A5F (سرمه‌ای — متن و آیکون)
         - Secondary: #D4AF37 (طلایی سکه)
         - Accent-1: #27AE60 (سبز رونق)
         - Accent-2: #E74C3C (قرمز رکود/هشدار)
         - Accent-3: #F39C12 (نارنجی — گاهی)
         - Neutral-warm: #F5F0E8
         - Neutral-cool: #E8EEF2

[ART-03] پالت بلوک‌های محله:
         turquoise: #1ABC9C — pink: #E91E63 — orange: #FF9800
         red: #C0392B — yellow: #F1C40F — green: #27AE60

[ART-04] نورپردازی: منبع نور بالا-چپ، سایه‌های نرم ۱۰٪ شفافیت رنگی
         (رنگ سایه = rgba(30,58,95,0.08) نه سیاه). هیچ سایه تیره.

[ART-05] ابعاد: توان ۲ (۲۵۶، ۵۱۲، ۱۰۲۴). فرمت PNG شفاف برای UI، JPG
         برای پس‌زمینه‌ها.

[ART-06] هیچ متنی در تصویر ننویس. استثنا: dots تاس و monogram مهر.

[ART-07] هیچ المان مذهبی/سیاسی/توهین‌آمیز. تم شهری، اقتصادی، دوستانه.

[ART-08] ثبات سبک: اگر یک تصویر تخت است، همه تخت. مخلوط سبک ممنوع.

[ART-09] همه تصاویر در ASSET_GUIDE.md با prompt و تاریخ ثبت شوند.

[ART-10] تناسب با تم روشن: هیچ پس‌زمینه تیره، سیاه یا moody. همه شاد
         و روشن.

═══════════════════════════════════════════════════════════════════════
📦 لیست کامل assets با prompt تولید تصویر
═══════════════════════════════════════════════════════════════════════

[AS01] assets/images/card_back.png — 512×768 PNG شفاف
  prompt: "A luxurious playing card back, cream (#FAF6EE) background,
  ornate golden (#D4AF37) geometric pattern inspired by Persian
  tilework, a central red wax seal with monogram 'B', flat modern
  illustration, soft 3D shading, top-left light source, bright
  cheerful palette, no text, transparent outside card rectangle,
  premium board game aesthetic"
  استفاده: پشت کارت قرارداد + حراج

[AS02] assets/images/paper_texture.png — 1024×1024 JPG
  prompt: "Seamless cream paper texture (#FAF6EE), subtle fiber
  details, very soft warm shadows like thick watercolor paper,
  vintage warm parchment feel, photorealistic surface, top-left
  soft light, no dark areas, bright and airy"
  استفاده: پس‌زمینهٔ تخته + کارت‌ها

[AS03] assets/images/coin.png — 256×256 PNG شفاف
  prompt: "A single gold coin, front view slightly tilted, embossed
  Persian dome silhouette in center, metallic gold gradient
  (#D4AF37 to #F1C40F), soft highlight top-left, cast shadow
  bottom-right, flat modern illustration with 3D shading, bright
  cheerful, transparent background, board game icon style"
  استفاده: انیمیشن سکه + آیکون پول

[AS04] assets/images/dice_1.png تا dice_6.png — 256×256 × ۶ فایل
  prompt برای dice_1: "A white ceramic die, front face showing 1 red
  dot, isometric 3D view slightly tilted, soft warm shadow, flat
  modern illustration, top-left light, clean white surface, rounded
  corners, bright cheerful, transparent background"
  prompt برای 2..6: همان با تعداد dots متفاوت
  استفاده: انیمیشن تاس

[AS05] assets/images/building_l1.png, building_l2.png, building_l3.png
  — 512×512 × ۳ فایل
  prompt l1 (خانه): "A small modern Persian house, cream walls,
  flat roof with small parapet, turquoise wooden door, one window,
  isometric 3D view, flat illustration, soft shading, warm sunlight,
  bright cheerful palette, transparent background, cute miniature
  building"
  prompt l2 (آپارتمان): ۳ طبقه با بالکن، پنجره‌های بیشتر
  prompt l3 (برج): ۷ طبقه شیشه‌ای مدرن، لوکس، نمای شهری
  استفاده: ساختمان‌های محله

[AS06] assets/images/avatar_normal.png, _rich.png, _broke.png,
       _jailed.png, _happy.png — 256×256 × ۵ فایل
  prompt normal: "Friendly stylized character avatar, neutral face,
  simple flat illustration, gender-neutral, business casual,
  warm skin tone, minimal features, top-left light, circular crop,
  bright warm palette, transparent background"
  rich: با کلاه، عینک آفتابی طلایی، سکه‌های شناور
  broke: چهره غمگین، کیف پول خالی
  jailed: پشت میله‌های نازک، ناراضی
  happy: لبخند بزرگ، ستاره‌های کوچک
  استفاده: مهره‌های زنده

[AS07] assets/images/bank_pool.png — 512×512 PNG شفاف
  prompt: "A golden pool or basin shaped like a Persian bowl,
  overflowing with gold coins, sparkle particles, soft glow,
  flat modern illustration, warm bright golden light, isometric
  view, transparent background, board game centerpiece"
  استفاده: بانک مشترک

[AS08] assets/images/icons/identity_1.png تا identity_6.png
  — 128×128 × ۶ فایل
  prompt identity_1: "Circular badge, diagonal stripes pattern,
  deep blue (#1E3A5F), flat illustration, thick white border,
  minimal, bright cheerful, transparent background"
  identity_2: قرمز #E74C3C + نقطه‌چین
  identity_3: سبز #27AE60 + خط‌دار
  identity_4: بنفش #8E44AD + شطرنجی
  identity_5: نارنجی #F39C12 + موج
  identity_6: صورتی #E91E63 + ستاره
  استفاده: هویت رنگی بازیکن‌ها

[AS09] assets/animations/ — Rive یا Lottie
  - coin_spin.json: چرخش سکه، ۳۰ فریم loop
  - dice_roll.json: پرتاب تاس، ۲۰ فریم
  - contract_break.json: شکستن مهر، ۱۵ فریم
  - phase_change.json: تغییر فاز، ۲۴ فریم
  اگر Rive/Lottie محدود بود، AnimationController + فریم PNG

[AS10] assets/sounds/ (اختیاری)
  - dice_roll.mp3، coin_collect.mp3، contract_seal.mp3،
  - phase_change.mp3، error_buzz.mp3

[AS11] assets/images/splash_bg.png — 1080×1920 JPG
  prompt: "Aerial isometric view of a modern Iranian city at golden
  hour, cream buildings with turquoise domes and colorful flat roofs,
  streets forming a board game path, warm golden light, soft
  painterly style, flat illustration with 3D depth, no text, no
  people, bright cheerful, premium game splash screen"
  استفاده: SplashScreen

[AS12] assets/images/menu_bg.png — 1080×1920 JPG
  prompt: "Cozy indoor scene of a board game on a wooden table,
  overhead isometric view, cream and warm palette, cards and gold
  coins scattered, soft candlelight, warm bright atmosphere, flat
  illustration, no people, no text, premium game menu background"
  استفاده: MainMenuScreen

[AS13] assets/images/app_icon.png — 512×512 PNG
  prompt: "App icon, square with rounded corners, cream (#FAF6EE)
  background, centered gold coin with Persian dome silhouette,
  small turquoise crescent accent top-right, flat modern icon,
  bold readable at small sizes, no text, bright cheerful"
  استفاده: Launcher icon (۵ ابعاد 48,72,96,144,192)

[AS14] assets/images/board_bg.png — 2048×2048 JPG
  prompt: "Top-down isometric view of an Iranian neighborhood,
  cream and warm tones, subtle grass patches, small trees, colorful
  rooftops (turquoise, pink, orange, red, yellow, green), streets
  with clear path lines, no people, no text, flat illustration with
  3D depth, bright sunny daylight, cheerful"
  استفاده: game_board پس‌زمینه (SECTION 19)

[AS15] assets/images/property_card_frame.png — 512×768 PNG شفاف
  prompt: "Empty playing card frame, white inner area, navy outer
  border (#1E3A5F), ornate golden corners with Persian motifs,
  small ribbon at top center, flat modern illustration, no text,
  no color fill inside, transparent center, bright"
  استفاده: قالب کارت ملک

[AS16] assets/images/dice_rolling_strip.png — 1536×256 PNG شفاف
  prompt: "6-frame animation strip of a white ceramic die rolling,
  frames showing die at different rotation angles, consistent
  bright lighting, flat 3D illustration, transparent background"
  استفاده: dice_widget

[AS17] assets/images/coin_fly_strip.png — 1024×256 PNG شفاف
  prompt: "4-frame animation strip of a gold coin spinning in air,
  frames at 0, 90, 180, 270 degrees, soft motion blur, transparent
  background, flat illustration, bright"
  استفاده: coin_particles

[AS18] assets/images/phase_bull.png, phase_bear.png, phase_stable.png
  — 256×256 × ۳ فایل
  prompt bull: "Stylized golden bull head icon, upward arrow motif,
  green accent (#27AE60), flat modern icon, bright, transparent"
  bear: "Stylized grey bear head icon, downward arrow motif, red
  accent (#E74C3C), flat modern icon, bright, transparent"
  stable: "Balanced scale icon, golden and grey, subtle green
  accent, flat modern icon, bright, transparent"
  استفاده: phase_indicator

[AS19] assets/images/ticker_arrow_up.png, ticker_arrow_down.png
  — 64×64 × ۲ فایل
  prompt up: "Simple flat upward arrow, green (#27AE60), bold,
  transparent, 2px white border, bright"
  down: همان ولی قرمز (#E74C3C)
  استفاده: live_ticker

[AS20] assets/images/contract_seal.png — 256×256 PNG شفاف
  prompt: "A red wax seal, circular, embossed with Persian geometric
  star pattern, cracked in half, flat illustration, bright warm,
  transparent background, dramatic"
  استفاده: secret_contract_layer

═══════════════════════════════════════════════════════════════════════
✅ چک‌لیست ASSET (۲۰ مورد — همه باید تولید شوند)
═══════════════════════════════════════════════════════════════════════

| شناسه | نام فایل | ابعاد | وضعیت |
|-------|----------|-------|-------|
| AS01  | card_back.png | 512×768 | ✅/❌ |
| AS02  | paper_texture.png | 1024×1024 | ✅/❌ |
| AS03  | coin.png | 256×256 | ✅/❌ |
| AS04  | dice_1..6.png | 256×256×6 | ✅/❌ |
| AS05  | building_l1..3.png | 512×512×3 | ✅/❌ |
| AS06  | avatar_*.png | 256×256×5 | ✅/❌ |
| AS07  | bank_pool.png | 512×512 | ✅/❌ |
| AS08  | identity_*.png | 128×128×6 | ✅/❌ |
| AS09  | animations/ | json/riv | ✅/❌ |
| AS10  | sounds/ | mp3 | ✅/❌ |
| AS11  | splash_bg.png | 1080×1920 | ✅/❌ |
| AS12  | menu_bg.png | 1080×1920 | ✅/❌ |
| AS13  | app_icon.png | 512×512+mipmaps | ✅/❌ |
| AS14  | board_bg.png | 2048×2048 | ✅/❌ |
| AS15  | property_card_frame.png | 512×768 | ✅/❌ |
| AS16  | dice_rolling_strip.png | 1536×256 | ✅/❌ |
| AS17  | coin_fly_strip.png | 1024×256 | ✅/❌ |
| AS18  | phase_*.png | 256×256×3 | ✅/❌ |
| AS19  | ticker_*.png | 64×64×2 | ✅/❌ |
| AS20  | contract_seal.png | 256×256 | ✅/❌ |

اگر یکی ❌ بود، کار تمام نیست. اگر ابزار تولید تصویر نبود، در
ASSET_GUIDE.md ذکر کن + CustomPaint جایگزین بساز.

═══════════════════════════════════════════════════════════════════════

## راهبرد تولید

برای هر تصویر یک درخواست جداگانه ارسال شد. همهٔ درخواست‌ها قید سبک روشن، بدون متن، نور بالا-چپ، بدون نماد سیاسی/مذهبی داشتند. برای تصاویر رابط، پس‌زمینهٔ یکنواخت FF00FF و padding درخواست شد. تصاویر پس‌زمینه full bleed بودند.

## Five additional landmarks (2026-10-27)
Built-in image_gen; one image per request. Common prompt: modern flat illustration + soft 3D shading, cream/navy/gold, upper-left light, secular friendly city, no text, transparency and padding. Subjects: start square with abstract coin statue and gate; police station with bars; leafy city park and bench; arrow sign with police badge; civic bank with dome. PNG 512×512, connected in SpaceWidget.
