// [G01][BL07] Continuous ticker with rolling numeric transitions.
import 'package:flutter/material.dart';
import '../core/models/game_state.dart';
import '../core/rules/inflation.dart';
import '../core/rules/phase_engine.dart';
import '../core/theme/colors.dart';
import '../core/utils/extensions.dart';

class LiveTicker extends StatefulWidget {
  final GameState state;
  const LiveTicker({super.key, required this.state});
  @override
  State<LiveTicker> createState() => _LiveTickerState();
}

class _LiveTickerState extends State<LiveTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final inflation = Inflation.of(s);
    final rising = s.phase != EconomicPhase.bear;
    final color = rising ? const Color(0xFF17623B) : const Color(0xFF9C4920);
    final text =
        '   بازار زاهدان   •   ${PhaseEngine.label(s.phase)}   •   تورم ${(inflation * 100).fa}٪   •   ضریب اجاره ${PhaseEngine.rent(s.phase)}   •   بانک ${s.bank.money}   •   راند ${s.round.fa}   ';
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/ticker_arrow_${rising ? 'up' : 'down'}.png',
              width: 20,
            ),
          ),
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: controller,
                builder: (c, w) => OverflowBox(
                  maxWidth: 1800,
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(-controller.value * 600, 0),
                    child: Text(
                      text * 3,
                      maxLines: 1,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => SlideTransition(
                position: Tween(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(a),
                child: c,
              ),
              child: Text(
                s.bank.money,
                key: ValueKey(s.bank.round()),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
