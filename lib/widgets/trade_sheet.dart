import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../models/tile_model.dart';
import '../providers/game_provider.dart';
import '../theme.dart';
import 'glass_panel.dart';
import 'property_sheet.dart';

Future<void> showTradeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (BuildContext context) => const TradeSheet(),
  );
}

/// Builder for a property-for-cash swap proposal.
class TradeSheet extends ConsumerStatefulWidget {
  const TradeSheet({super.key});

  @override
  ConsumerState<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends ConsumerState<TradeSheet> {
  String? _partnerId;
  final Set<int> _myTiles = <int>{};
  final Set<int> _theirTiles = <int>{};
  double _myCash = 0;
  double _theirCash = 0;

  @override
  Widget build(BuildContext context) {
    final SessionState session = ref.watch(gameProvider);
    final GameState game = session.game;
    final PlayerModel? me = session.localPlayer;

    if (me == null) {
      return const SheetShell(
        title: 'معامله',
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('در این بازی بازیکن نیستید.'),
        ),
      );
    }

    final List<PlayerModel> partners = game.players
        .where((PlayerModel p) => p.id != me.id && !p.bankrupt)
        .toList(growable: false);

    if (partners.isEmpty) {
      return const SheetShell(
        title: 'معامله',
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('رقیبی برای معامله وجود ندارد.'),
        ),
      );
    }

    final PlayerModel? partner =
        game.playerById(_partnerId ?? partners.first.id);

    if (_partnerId != partner?.id) {
      _partnerId = partner?.id;
    }

    final List<OwnedProperty> myProperties = me.properties.values.toList()
      ..sort((OwnedProperty a, OwnedProperty b) =>
          a.tileIndex.compareTo(b.tileIndex));
    final List<OwnedProperty> partnerProperties =
        (partner?.properties.values.toList() ?? <OwnedProperty>[])
          ..sort((OwnedProperty a, OwnedProperty b) =>
              a.tileIndex.compareTo(b.tileIndex));

    final int myMaxCash = me.cash;
    final int partnerMaxCash = partner?.cash ?? 0;
    final int myCashValue = _myCash.round().clamp(0, myMaxCash);
    final int theirCashValue = _theirCash.round().clamp(0, partnerMaxCash);

    return SheetShell(
      title: 'پیشنهاد معامله',
      icon: Icons.swap_horiz,
      accent: NeonColors.violet,
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Text('طرف معامله', style: neonText(size: 12, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: partners.map((PlayerModel p) {
              final bool selected = p.id == partner?.id;
              final Color color =
                  Color(PlayerPalette.colorFor(p.colorIndex));
              return GestureDetector(
                onTap: () => setState(() {
                  _partnerId = p.id;
                  _theirTiles.clear();
                  _theirCash = 0;
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color.withValues(alpha: selected ? 0.22 : 0.06),
                    border: Border.all(
                      color: color.withValues(alpha: selected ? 0.8 : 0.25),
                    ),
                  ),
                  child: Text(
                    p.name,
                    style: neonText(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: selected ? color : NeonColors.textDim,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 14),
          _sectionHeader(
            'شما می‌دهید',
            NeonColors.magenta,
            '${_myTiles.length} ملک • ${formatMoney(myCashValue)}',
          ),
          const SizedBox(height: 6),
          _tilePicker(
            properties: myProperties,
            selected: _myTiles,
            accent: NeonColors.magenta,
            onToggle: (int index) => setState(() {
              if (!_myTiles.remove(index)) {
                _myTiles.add(index);
              }
            }),
            emptyLabel: 'ملکی برای پیشنهاد ندارید.',
          ),
          _cashSlider(
            label: 'نقدینگی پیشنهادی',
            value: myCashValue.toDouble(),
            max: myMaxCash.toDouble(),
            accent: NeonColors.magenta,
            onChanged: (double value) => setState(() => _myCash = value),
          ),
          const SizedBox(height: 12),
          _sectionHeader(
            'شما می‌گیرید',
            NeonColors.cyan,
            '${_theirTiles.length} ملک • ${formatMoney(theirCashValue)}',
          ),
          const SizedBox(height: 6),
          _tilePicker(
            properties: partnerProperties,
            selected: _theirTiles,
            accent: NeonColors.cyan,
            onToggle: (int index) => setState(() {
              if (!_theirTiles.remove(index)) {
                _theirTiles.add(index);
              }
            }),
            emptyLabel: 'طرف مقابل ملکی ندارد.',
          ),
          _cashSlider(
            label: 'نقدینگی درخواستی',
            value: theirCashValue.toDouble(),
            max: partnerMaxCash.toDouble(),
            accent: NeonColors.cyan,
            onChanged: (double value) => setState(() => _theirCash = value),
          ),
          const SizedBox(height: 18),
          NeonButton(
            label: 'ارسال پیشنهاد به ${partner?.name ?? "-"}',
            icon: Icons.send,
            color: NeonColors.lime,
            onPressed: () {
              ref.read(gameProvider.notifier).proposeTrade(
                    toId: partner!.id,
                    offeredTiles: _myTiles.toList(growable: false),
                    requestedTiles: _theirTiles.toList(growable: false),
                    offeredCash: myCashValue,
                    requestedCash: theirCashValue,
                  );
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(height: 8),
          Text(
            'معامله فقط با ملک‌های آزاد (غیرمرهونه) و نقدینگی موجود امکان‌پذیر است.',
            style: neonText(size: 10.5, color: NeonColors.textDim),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color, String trailing) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: neonText(size: 12.5, weight: FontWeight.w800, color: color),
        ),
        const Spacer(),
        Text(
          trailing,
          style: neonText(size: 10.5, color: NeonColors.textDim),
        ),
      ],
    );
  }

  Widget _tilePicker({
    required List<OwnedProperty> properties,
    required Set<int> selected,
    required Color accent,
    required ValueChanged<int> onToggle,
    required String emptyLabel,
  }) {
    if (properties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          emptyLabel,
          style: neonText(size: 11, color: NeonColors.textDim),
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: properties.map((OwnedProperty owned) {
        final bool isSelected = selected.contains(owned.tileIndex);
        final TileModel tile = owned.tile;
        final bool disabled = owned.mortgaged;
        return GestureDetector(
          onTap: disabled ? null : () => onToggle(owned.tileIndex),
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: isSelected
                    ? accent.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: isSelected
                      ? accent.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                tile.name,
                style: neonText(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: isSelected ? accent : NeonColors.text,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _cashSlider({
    required String label,
    required double value,
    required double max,
    required Color accent,
    required ValueChanged<double> onChanged,
  }) {
    final double safeMax = max <= 0 ? 1 : max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Text(label, style: neonText(size: 10.5, color: NeonColors.textDim)),
            const Spacer(),
            Text(
              formatMoney(value.round()),
              style: neonText(
                size: 11.5,
                weight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value.clamp(0, safeMax),
            max: safeMax,
            divisions: safeMax <= 0 ? null : (safeMax / 50).round().clamp(1, 200),
            onChanged: max <= 0 ? null : onChanged,
          ),
        ),
      ],
    );
  }
}
