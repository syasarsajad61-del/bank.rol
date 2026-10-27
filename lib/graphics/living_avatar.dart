// [G05][G09] Five generated moods and six patterned identities.
import 'package:flutter/material.dart';
import '../core/models/game_state.dart';
import '../core/theme/colors.dart';

class LivingAvatar extends StatelessWidget {
  final Player player;
  final double size;
  final bool active;
  const LivingAvatar({
    super.key,
    required this.player,
    this.size = 48,
    this.active = false,
  });
  @override
  Widget build(BuildContext context) {
    final mood = player.eliminated
        ? 'broke'
        : player.jailTurns > 0
        ? 'jailed'
        : player.cash > 2500
        ? 'rich'
        : active
        ? 'happy'
        : 'normal';
    return Semantics(
      label:
          '${player.name}، ${player.jailTurns > 0
              ? 'زندانی'
              : player.eliminated
              ? 'حذف شده'
              : 'فعال'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: active
                ? AppColors.gold
                : AppColors.identities[player.identity % 6],
            width: active ? 3 : 2,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/avatar_$mood.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: Image.asset(
                'assets/images/icons/identity_${player.identity % 6 + 1}.png',
                width: size * .4,
                height: size * .4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
