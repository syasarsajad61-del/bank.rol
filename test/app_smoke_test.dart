import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neon_bankroll/main.dart';

void main() {
  testWidgets('app boots into the Persian lobby', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NeonBankrollApp()));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('نئون بانکرول'), findsWidgets);
    expect(find.text('ساخت میز و میزبانی'), findsOneWidget);
    expect(find.text('میزبانی'), findsWidgets);
    expect(find.text('ورود به بازی'), findsWidgets);
  });
}
