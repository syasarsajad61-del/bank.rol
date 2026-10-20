import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../models/tile_model.dart';
import '../providers/game_provider.dart';
import '../theme.dart';
import 'glass_panel.dart';

/// Shared shell for the bottom sheets used inside a match.
class SheetShell extends StatelessWidget {
  const SheetShell({
    super.key,
    required this.title,
    required this.child,
    this.icon = Icons.dashboard_customize_outlined,
    this.accent = NeonColors.cyan,
  });

  final String title;
  final Widget child;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.82;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: GlassPanel(
        radius: 26,
        accent: accent,
        blur: 28,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: glowText(size: 16, color: accent),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, size: 20),
                  color: NeonColors.textDim,
                ),
              ],
            ),
            const NeonDivider(),
            const SizedBox(height: 8),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

Future<void> showPropertySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (BuildContext context) => const PropertySheet(),
  );
}

class PropertySheet extends ConsumerWidget {
  const PropertySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(gameProvider);
    final GameState game = session.game;
    final PlayerModel? me = session.localPlayer;

    if (me == null) {
      return const SheetShell(
        title: 'املاک',
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('در این بازی بازیکن نیستید.'),
        ),
      );
    }

    final List<OwnedProperty> mine = me.properties.values.toList()
      ..sort((OwnedProperty a, OwnedProperty b) =>
          a.tileIndex.compareTo(b.tileIndex));

    final List<PlayerModel> others = game.players
        .where((PlayerModel p) => p.id != me.id && p.properties.isNotEmpty)
        .toList(growable: false);

    return SheetShell(
      title: 'املاک و مدیریت دارایی',
      icon: Icons.account_balance_outlined,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Row(
            children: <Widget>[
              _stat('نقدینگی', formatMoney(me.cash), NeonColors.lime),
              _stat('ارزش خالص', formatMoney(me.netWorth()), NeonColors.cyan),
              _stat('تعداد ملک', '${me.propertyCount}', NeonColors.violet),
            ],
          ),
          const SizedBox(height: 12),
          if (mine.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'هنوز ملکی ندارید. با خرید زمین شروع کنید.',
                style: neonText(size: 12, color: NeonColors.textDim),
              ),
            ),
          ...mine.map(
            (OwnedProperty owned) => _OwnedTileCard(
              owned: owned,
              game: game,
              player: me,
              isMyTurn: session.isMyTurn,
              onUpgrade: () => ref
                  .read(gameProvider.notifier)
                  .upgrade(owned.tileIndex),
              onMortgage: () => ref
                  .read(gameProvider.notifier)
                  .mortgage(owned.tileIndex),
              onUnmortgage: () => ref
                  .read(gameProvider.notifier)
                  .unmortgage(owned.tileIndex),
            ),
          ),
          if (others.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text('املاک رقبا', style: neonText(size: 13, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...others.expand(
              (PlayerModel player) => player.properties.values.map(
                (OwnedProperty owned) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(
                            PlayerPalette.colorFor(player.colorIndex),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '${owned.tile.name} — ${player.name}',
                          style: neonText(size: 11.5),
                        ),
                      ),
                      Text(
                        TileModel.levelNamesFa[owned.level],
                        style: neonText(
                          size: 11,
                          color: NeonColors.textDim,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _rentLabel(game, owned),
                        style: neonText(
                          size: 11,
                          color: NeonColors.lime,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: neonText(size: 10, color: NeonColors.textDim)),
          Text(
            value,
            style: neonText(size: 13.5, weight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  static String _rentLabel(GameState game, OwnedProperty owned) {
    if (owned.mortgaged) {
      return 'در رهن';
    }
    final TileModel tile = owned.tile;
    if (tile.type == TileType.city) {
      final String ownerId = game.ownerIdOf(owned.tileIndex) ?? '';
      return formatMoney(
        tile.cityRent(
          owned.level,
          ownsGroup: game.ownsWholeGroup(ownerId, tile.groupId),
        ),
      );
    }
    return formatMoney(tile.baseRent);
  }
}

class _OwnedTileCard extends StatelessWidget {
  const _OwnedTileCard({
    required this.owned,
    required this.game,
    required this.player,
    required this.isMyTurn,
    required this.onUpgrade,
    required this.onMortgage,
    required this.onUnmortgage,
  });

  final OwnedProperty owned;
  final GameState game;
  final PlayerModel player;
  final bool isMyTurn;
  final VoidCallback onUpgrade;
  final VoidCallback onMortgage;
  final VoidCallback onUnmortgage;

  @override
  Widget build(BuildContext context) {
    final TileModel tile = owned.tile;
    final bool ownsGroup = game.ownsWholeGroup(player.id, tile.groupId);
    final int cost =
        tile.type.isCity && owned.level < 5 ? tile.upgradeCostFrom(owned.level) : 0;
    final bool canUpgrade = isMyTurn &&
        !owned.mortgaged &&
        tile.type.isCity &&
        owned.level < 5 &&
        player.cash >= cost;
    final bool canMortgage = !owned.mortgaged && (isMyTurn || player.cash < 0);
    final bool canUnmortgage =
        owned.mortgaged && player.cash >= tile.unmortgageCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: NeonColors.panel.withValues(alpha: 0.55),
        border: Border.all(
          color: (owned.mortgaged ? NeonColors.danger : tile.color)
              .withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tile.color,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: tile.color.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tile.name,
                  style: neonText(size: 13, weight: FontWeight.w800),
                ),
              ),
              if (ownsGroup)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: NeonColors.amber.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'گروه کامل',
                    style: neonText(
                      size: 9,
                      color: NeonColors.amber,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                owned.mortgaged
                    ? 'در رهن'
                    : TileModel.levelNamesFa[owned.level],
                style: neonText(
                  size: 11,
                  color: owned.mortgaged
                      ? NeonColors.danger
                      : NeonColors.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                'اجاره فعلی: ',
                style: neonText(size: 10.5, color: NeonColors.textDim),
              ),
              Text(
                PropertySheet._rentLabel(game, owned),
                style: neonText(
                  size: 11.5,
                  weight: FontWeight.w800,
                  color: NeonColors.lime,
                ),
              ),
              const Spacer(),
              if (tile.type.isCity && owned.level < 5)
                Text(
                  'ارتقا: ${formatMoney(cost)}',
                  style: neonText(
                    size: 10.5,
                    color: canUpgrade ? NeonColors.amber : NeonColors.textDim,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (tile.type.isCity && owned.level < 5)
                _chip(
                  canUpgrade
                      ? 'ارتقا به ${TileModel.levelNamesFa[owned.level + 1]}'
                      : 'ارتقا (نوبت/موجودی)',
                  Icons.arrow_upward,
                  NeonColors.amber,
                  canUpgrade ? onUpgrade : null,
                ),
              if (canMortgage)
                _chip(
                  'رهن (${formatMoney(tile.mortgageValue)})',
                  Icons.lock_outline,
                  NeonColors.magenta,
                  onMortgage,
                ),
              if (canUnmortgage)
                _chip(
                  'آزادسازی (${formatMoney(tile.unmortgageCost)})',
                  Icons.lock_open,
                  NeonColors.cyan,
                  onUnmortgage,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.04)
              : color.withValues(alpha: 0.14),
          border: Border.all(
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.10)
                : color.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 13,
              color: onTap == null ? NeonColors.textDim : color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: neonText(
                size: 10.5,
                weight: FontWeight.w700,
                color: onTap == null ? NeonColors.textDim : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
