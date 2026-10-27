from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'lib/ui/screens/screens.dart';s=p.read_text(encoding='utf-8').replace("import '../widgets/components.dart';", "import '../widgets/components.dart';\nimport '../widgets/responsive_game_layout.dart';");p.write_text(s,encoding='utf-8')
p=root/'lib/ui/widgets/components.dart';s=p.read_text(encoding='utf-8');start=s.index('class PlayerProfileCard');end=s.index('class BottomDock');s=s[:start]+s[start:end].replace('EdgeInsets.all(12)','EdgeInsets.all(8)')+s[end:];p.write_text(s,encoding='utf-8')
p=root/'lib/core/theme/colors.dart';s=p.read_text(encoding='utf-8').replace('muted = Color(0xFF6B7280),','muted = Color(0xFF6B7280),\n      mutedOnCream = Color(0xFF68717D),');p.write_text(s,encoding='utf-8')
for p in (root/'lib').rglob('*.dart'):
    if p.name!='colors.dart':p.write_text(p.read_text(encoding='utf-8').replace('AppColors.muted','AppColors.mutedOnCream'),encoding='utf-8')
p=root/'test/theme_test.dart';s=p.read_text(encoding='utf-8').replace('AppColors.muted,AppColors.background','AppColors.mutedOnCream,AppColors.background');p.write_text(s,encoding='utf-8')
# Restore the three locked source files after formatting.
import re
spec=(root/'docs/MASTER_SPEC.txt').read_text(encoding='utf-8')
for m in re.finditer(r'===BEGIN-FILE ([^=]+)===\n(.*?)\n===END-FILE===',spec,re.S):
    (root/m[1]).write_text(m[2]+'\n',encoding='utf-8')
