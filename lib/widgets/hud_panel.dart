import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../network/client_socket.dart';
import '../providers/game_provider.dart';
import '../theme.dart';
import 'glass_panel.dart';

/// Compact status strip: round, phase, link health.
class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.game,
    required this.link,
    required this.role,
  });

  final GameState game;
  final LinkStatus link;
  final PlayerRole role;

  Color get _linkColor {
    switch (link) {
      case LinkStatus.connected:
        return NeonColors.lime;
      case LinkStatus.connecting:
      case LinkStatus.reconnecting:
        return NeonColors.amber;
      case LinkStatus.failed:
      case LinkStatus.closed:
        return NeonColors.danger;
      case LinkStatus.idle:
        return NeonColors.textDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      radius: 16,
      glow: 0.10,
      accent: NeonColors.violet,
      child: Row(
        children: <Widget>[
          _badge('دور ${game.round}', NeonColors.violet),
          const SizedBox(width: 8),
          _badge(role.labelFa, NeonColors.cyan),
          const SizedBox(width: 8),
          _badge(game.phase.labelFa, NeonColors.magenta),
          const Spacer(),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _linkColor,
              boxShadow: <BoxShadow>[
                BoxShadow(color: _linkColor.withValues(alpha: 0.9), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            link.labelFa,
            style: neonText(size: 10.5, color: NeonColors.textDim),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: neonText(size: 10.5, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Horizontally scrollable roster of every player at the table.
class PlayerRail extends StatelessWidget {
  const PlayerRail({
    super.key,
    required this.game,
    required this.localPlayerId,
  });

  final GameState game;
  final String? localPlayerId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: game.players.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final PlayerModel player = game.players[index];
          final bool isCurrent = game.currentPlayerId == player.id;
          final Color color = Color(PlayerPalette.colorFor(player.colorIndex));
          return SizedBox(
            width: 178,
            child: PlayerChip(
              name: player.name +
                  (player.id == localPlayerId ? ' (شما)' : ''),
              color: color,
              active: isCurrent,
              dimmed: player.bankrupt,
              subtitle: player.bankrupt
                  ? 'ورشکسته'
                  : 'نقد ${formatMoney(player.cash)} • ارزش ${formatMoney(player.netWorth())}',
              trailing: player.bankrupt
                  ? const Icon(Icons.block, size: 14, color: NeonColors.danger)
                  : (player.connected
                      ? null
                      : const Icon(Icons.wifi_off,
                          size: 14, color: NeonColors.danger)),
            ),
          );
        },
      ),
    );
  }
}

/// Live log ticker.
class LogTicker extends StatelessWidget {
  const LogTicker({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final List<String> tail =
        lines.length <= 2 ? lines : lines.sublist(lines.length - 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tail
          .map(
            (String line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: neonText(
                  size: 11,
                  color: NeonColors.textDim,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
