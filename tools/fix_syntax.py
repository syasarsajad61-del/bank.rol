from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'lib/ui/widgets/components.dart';s=p.read_text(encoding='utf-8').replace('height:64);})));}\n}', 'height:64);})));\n}');p.write_text(s,encoding='utf-8')
p=root/'lib/ui/screens/screens.dart';s=p.read_text(encoding='utf-8').replace('const SizedBox(height:32)]))]));','const SizedBox(height:32)])))]));');p.write_text(s,encoding='utf-8')
p=root/'lib/graphics/live_ticker.dart'
s=p.read_text(encoding='utf-8').replace('fontWeight:FontWeight.w500)))))),Padding','fontWeight:FontWeight.w500))))))),Padding');p.write_text(s,encoding='utf-8')
