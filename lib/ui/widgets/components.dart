// [BL04-BL10][G08][TH15] Shared, accessible game controls.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_state.dart';
import '../../core/data/properties_data.dart';
import '../../core/rules/rent_calculator.dart';
import '../../core/rules/phase_engine.dart';
import '../../core/rules/inflation.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/extensions.dart';
import '../../graphics/living_avatar.dart';
import '../../graphics/paper_city.dart';
import '../../graphics/live_ticker.dart';
import '../../providers/game_provider.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext c) => outlined
      ? OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
        )
      : FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
        );
}

class PhaseIndicator extends StatelessWidget {
  final EconomicPhase phase;
  const PhaseIndicator({super.key, required this.phase});
  @override
  Widget build(BuildContext c) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/images/phase_${phase.name}.png',
        width: 32,
        height: 32,
      ),
      const SizedBox(width: 8),
      Text(
        PhaseEngine.label(phase),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class InflationMeter extends StatelessWidget {
  final GameState state;
  const InflationMeter({super.key, required this.state});
  @override
  Widget build(BuildContext c) => Text(
    'تورم ${(Inflation.of(state) * 100).fa}٪',
    style: const TextStyle(fontSize: 12, color: AppColors.mutedOnCream),
  );
}

class CommonBankPool extends StatelessWidget {
  final double amount;
  const CommonBankPool({super.key, required this.amount});
  @override
  Widget build(BuildContext c) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: .9, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (c, t, w) => Transform.scale(scale: t, child: w),
        child: Image.asset(
          'assets/images/bank_pool.png',
          width: 48,
          height: 48,
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'بانک مشترک',
            style: TextStyle(fontSize: 10, color: AppColors.mutedOnCream),
          ),
          Text(
            amount.money,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ],
  );
}

class TopTickerBar extends StatelessWidget {
  final GameState state;
  const TopTickerBar({super.key, required this.state});
  @override
  Widget build(BuildContext c) => LiveTicker(state: state);
}

class PlayerProfileCard extends StatelessWidget {
  final Player player;
  final GameState state;
  final bool active;
  const PlayerProfileCard({
    super.key,
    required this.player,
    required this.state,
    this.active = false,
  });
  @override
  Widget build(BuildContext c) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: 180,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: active ? AppColors.gold : AppColors.border,
        width: active ? 2 : 1,
      ),
    ),
    child: Row(
      children: [
        LivingAvatar(player: player, active: active, size: 40),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(player.cash.money, style: const TextStyle(fontSize: 12)),
              Text(
                'دارایی ${state.netWorth(player.id).money}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedOnCream,
                ),
              ),
              Text(
                'اعتبار ${player.credit.fa}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.mutedOnCream,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class BottomDock extends StatelessWidget {
  final GameState state;
  const BottomDock({super.key, required this.state});
  @override
  Widget build(BuildContext c) => Container(
    height: 120,
    color: AppColors.background,
    child: ListView.separated(
      padding: const EdgeInsets.all(8),
      scrollDirection: Axis.horizontal,
      itemCount: state.players.length,
      separatorBuilder: (c, i) => const SizedBox(width: 8),
      itemBuilder: (c, i) => Opacity(
        opacity: state.players[i].eliminated ? 0.4 : 1,
        child: PlayerProfileCard(
          player: state.players[i],
          state: state,
          active: i == state.turn,
        ),
      ),
    ),
  );
}

class PathProgressBar extends StatelessWidget {
  final GameState state;
  const PathProgressBar({super.key, required this.state});
  @override
  Widget build(BuildContext c) => SizedBox(
    height: 12,
    child: LayoutBuilder(
      builder: (c, b) => Stack(
        children: [
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Container(height: 4, color: AppColors.border),
          ),
          for (final p in state.alive)
            Positioned(
              left: (b.maxWidth - 8) * p.position / 31,
              top: 0,
              child: Semantics(
                label: '${p.name} خانه ${p.position.fa}',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.identities[p.identity % 6],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: p.id == state.active.id
                          ? AppColors.gold
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class DiceWidget extends StatefulWidget {
  final int value;
  final int revision;
  final bool reducedMotion;
  const DiceWidget({
    super.key,
    required this.value,
    required this.revision,
    this.reducedMotion = false,
  });
  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  @override
  void didUpdateWidget(covariant DiceWidget old) {
    super.didUpdateWidget(old);
    if (old.revision != widget.revision &&
        old.value != widget.value &&
        !widget.reducedMotion) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Semantics(
    label: 'تاس ${widget.value.fa}',
    child: SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: controller,
        builder: (c, w) {
          if (controller.isAnimating) {
            final frame = (controller.value * 20).floor() % 6;
            return ClipRect(
              child: OverflowBox(
                maxWidth: 384,
                minWidth: 384,
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(-frame * 64.0, 0),
                  child: Image.asset(
                    'assets/images/dice_rolling_strip.png',
                    width: 384,
                    height: 64,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            );
          }
          return Image.asset(
            'assets/images/dice_${widget.value.clamp(1, 6)}.png',
            width: 64,
            height: 64,
          );
        },
      ),
    ),
  );
}

class CenterHud extends StatelessWidget {
  final GameState state;
  final bool enabled;
  final bool reducedMotion;
  const CenterHud({
    super.key,
    required this.state,
    required this.enabled,
    this.reducedMotion = false,
  });
  @override
  Widget build(BuildContext c) {
    final game = c.read<GameProvider>();
    return PaperCity(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          DiceWidget(
            value: state.lastDice,
            revision: state.revision,
            reducedMotion: reducedMotion,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? 'نوبت شماست' : 'نوبت ${state.active.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  state.extraRoll
                      ? 'شش! یک بار دیگر تاس بریزید'
                      : 'خانه ${state.active.position.fa} • راند ${state.round.fa}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedOnCream,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed:
                enabled &&
                    state.auction == null &&
                    state.vote == null &&
                    state.pendingMove == null
                ? () => game.command(state.rolled ? 'end' : 'roll')
                : null,
            child: Text(
              !state.rolled
                  ? 'تاس بریز'
                  : state.extraRoll
                  ? 'دوباره!'
                  : 'پایان نوبت',
            ),
          ),
        ],
      ),
    );
  }
}

class TimerWidget extends StatefulWidget {
  final int deadline;
  const TimerWidget({super.key, required this.deadline});
  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final seconds =
        ((widget.deadline - DateTime.now().millisecondsSinceEpoch) / 1000)
            .ceil()
            .clamp(0, 999);
    return Chip(
      avatar: const Icon(Icons.timer_outlined, size: 18),
      label: Text('${seconds.fa} ثانیه'),
    );
  }
}

class BidInput extends StatelessWidget {
  final TextEditingController controller;
  final double max;
  const BidInput({super.key, required this.controller, required this.max});
  @override
  Widget build(BuildContext c) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: 'پیشنهاد مخفی (دلار)',
      helperText: 'حداکثر ${max.money}',
      prefixIcon: const Icon(Icons.local_offer_outlined),
    ),
  );
}

class PropertyCard extends StatelessWidget {
  final Property property;
  final GameState state;
  final VoidCallback? onTap;
  const PropertyCard({
    super.key,
    required this.property,
    required this.state,
    this.onTap,
  });
  @override
  Widget build(BuildContext c) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 132,
      child: PaperCity(
        propertyFrame: true,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: property.isPublic
                    ? AppColors.navy
                    : AppColors.blocks[property.block!.index],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Image.asset(
              'assets/images/building_l${property.buildings.clamp(1, 3)}.png',
              height: 48,
            ),
            Text(
              property.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              RentCalculator.value(state, property).money,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${property.buildings.fa} ساختمان',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.mutedOnCream,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SpaceWidget extends StatelessWidget {
  final BoardSpace space;
  final GameState state;
  final VoidCallback onTap;
  const SpaceWidget({
    super.key,
    required this.space,
    required this.state,
    required this.onTap,
  });
  static String label(BoardSpaceType t) => switch (t) {
    BoardSpaceType.start => 'آغاز',
    BoardSpaceType.chance => 'شانس',
    BoardSpaceType.tax => 'مالیات',
    BoardSpaceType.auction => 'حراج',
    BoardSpaceType.jail => 'زندان',
    BoardSpaceType.goToJail => 'به زندان',
    BoardSpaceType.freeParking => 'پارک شهر',
    BoardSpaceType.bankPool => 'بانک مشترک',
    _ => 'ملک',
  };
  static IconData icon(BoardSpaceType t) => switch (t) {
    BoardSpaceType.start => Icons.flag_outlined,
    BoardSpaceType.chance => Icons.auto_awesome_outlined,
    BoardSpaceType.tax => Icons.receipt_long_outlined,
    BoardSpaceType.auction => Icons.gavel_outlined,
    BoardSpaceType.jail => Icons.local_police_outlined,
    BoardSpaceType.goToJail => Icons.arrow_circle_left_outlined,
    BoardSpaceType.freeParking => Icons.park_outlined,
    BoardSpaceType.bankPool => Icons.account_balance_outlined,
    BoardSpaceType.publicProperty => Icons.flight_outlined,
    _ => Icons.home_outlined,
  };
  static String? landmark(BoardSpaceType t) => switch (t) {
    BoardSpaceType.start => 'start',
    BoardSpaceType.jail => 'jail',
    BoardSpaceType.freeParking => 'park',
    BoardSpaceType.goToJail => 'goToJail',
    BoardSpaceType.bankPool => 'bankPool',
    _ => null,
  };
  @override
  Widget build(BuildContext c) {
    final q = space.propertyId == null
        ? null
        : state.property(space.propertyId!);
    final owner = q?.owner == null ? null : state.player(q!.owner!);
    final occupants = state.alive
        .where((p) => p.position == space.index)
        .toList();
    final active = state.active.position == space.index;
    final color = q?.block == null
        ? AppColors.border
        : AppColors.blocks[q!.block!.index];
    return Semantics(
      button: true,
      label:
          'خانه ${space.index.fa}، ${q?.name ?? label(space.type)}${owner == null ? '' : ', مالک ${owner.name}'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Color.alphaBlend(color.withValues(alpha: .1), Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: owner != null
                  ? AppColors.identities[owner.identity % 6]
                  : active
                  ? AppColors.gold
                  : AppColors.border,
              width: owner != null || active ? 3 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: .22),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 8,
                right: 8,
                top: 4,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                child: Column(
                  children: [
                    if (q != null)
                      Image.asset(
                        'assets/images/building_l${q.buildings.clamp(1, 3)}.png',
                        height: 32,
                      )
                    else if (landmark(space.type) != null)
                      Image.asset(
                        'assets/images/landmark_${landmark(space.type)}.png',
                        height: 32,
                      )
                    else
                      Icon(icon(space.type), size: 32, color: AppColors.navy),
                    const SizedBox(height: 4),
                    Text(
                      q?.name ?? label(space.type),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    if (q != null)
                      Text(
                        RentCalculator.value(state, q).money,
                        style: const TextStyle(fontSize: 10),
                      ),
                    if (space.taxAmount != null)
                      Text(
                        space.taxAmount!.money,
                        style: const TextStyle(fontSize: 10),
                      ),
                    Text(
                      space.index.fa,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.mutedOnCream,
                      ),
                    ),
                  ],
                ),
              ),
              if (occupants.isNotEmpty)
                Positioned(
                  bottom: 4,
                  right: 4,
                  left: 4,
                  child: Wrap(
                    spacing: 0,
                    children: [
                      for (final p in occupants)
                        LivingAvatar(
                          player: p,
                          size: 24,
                          active: p.id == state.active.id,
                        ),
                    ],
                  ),
                ),
              if (q != null && q.buildings > 0)
                Positioned(
                  top: 12,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.white,
                    child: Text(
                      '★' * q.buildings,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
