from pathlib import Path
import re, shutil, json

ROOT = Path(__file__).resolve().parents[1]
def write(name, body):
    p = ROOT / name
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(body, encoding='utf-8')

source = Path(r'C:\Users\amin\.gapcode\attachments\dca1e1c1-c5d5-4e76-af14-d657ae3c217b\pasted-text.txt').read_text(encoding='utf-8')
write('docs/MASTER_SPEC.txt', source)
for m in re.finditer(r'===BEGIN-FILE ([^=]+)===\r?\n(.*?)\r?\n===END-FILE===', source, re.S):
    write(m[1], m[2] + '\n')
write('pubspec.yaml', '''# [T01][T03][F02] Offline game application
name: bankroll_plato
description: A Persian offline economic board game set in Zahedan.
publish_to: none
version: 1.0.0+1
environment:
  sdk: '>=3.10.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  provider: ^6.1.5
  web_socket_channel: ^3.0.3
  rive: ^0.13.20
  lottie: ^3.3.1
  shared_preferences: ^2.3.0
  sqflite: ^2.4.0
  uuid: ^4.5.3
  crypto: ^3.0.7
  cryptography: ^2.7.0
  path: ^1.9.1
  path_provider: ^2.1.5
  audioplayers: ^6.1.0
  collection: ^1.19.1
  google_fonts: ^6.3.3
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/images/icons/
    - assets/animations/
    - assets/sounds/
    - assets/fonts/
  fonts:
    - family: Vazirmatn
      fonts:
        - asset: assets/fonts/Vazirmatn-Regular.ttf
''')
write('analysis_options.yaml', '''include: package:flutter_lints/flutter.yaml
analyzer:
  errors:
    unused_import: ignore
    constant_identifier_names: ignore
linter:
  rules:
    constant_identifier_names: false
    prefer_single_quotes: true
''')
for directory in ['assets/images/icons', 'assets/animations', 'assets/sounds', 'assets/fonts', 'docs', 'test']:
    (ROOT / directory).mkdir(parents=True, exist_ok=True)
write('android/local.properties', 'sdk.dir=C:\\\\android_sdk\nflutter.sdk=C:\\\\flutter_sdk\\\\flutter\n')
print('Reference data extracted verbatim; project dependencies configured.')
