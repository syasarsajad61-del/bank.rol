import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../engine/game_engine.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../models/tile_model.dart';
import '../theme.dart';
import 'glass_panel.dart';

/// Full screen translucent backdrop with a centred glass card.
class ModalShell extends StatelessWidget {
  const ModalShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.accent = NeonColors.cyan,
    this.icon,
    this.maxWidth = 430,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Color accent;
  final IconData? icon;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.62),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: GlassPanel(
                accent: accent,
                blur: 26,
                glow: 0.30,
                radius: 24,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Icon(icon, color: accent, size: 22),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: glowText(
                              size: 18,
                              color: accent,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: neonText(
                          size: 12,
                          color: NeonColors.textDim,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const NeonDivider(),
                    const SizedBox(height: 14),
                    child,
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms)
                .scaleXY(begin: 0.94, end: 1.0, duration: 260.ms),
          ),
        ),
      ),
    );
  }
}

/// Rent ladder shared by the purchase prompt and the property sheet.
class RentLadder extends StatelessWidget {
  const RentLadder({super.key, required this.tile, this.ownsGroup = false});

  final TileModel tile;
  final bool ownsGroup;

  @override
  Widget build(BuildContext context) {
    final List<int> rents = <int>[
      for (int level = 1; level <= 5; level++)
        tile.cityRent(level, ownsGroup: ownsGroup),
    ];
    return Column(
      children: <Widget>[
        for (int level = 1; level <= 5; level++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: <Widget>[
                _LevelDots(level: level, color: tile.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    TileModel.levelNamesFa[level],
                    style: neonText(
                      size: 11.5,
                      color: level == 5
                          ? NeonColors.amber
                          : NeonColors.textDim,
                      weight: level == 5 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  formatMoney(rents[level - 1]),
                  style: neonText(
                    size: 12,
                    weight: FontWeight.w700,
                    color: NeonColors.lime,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LevelDots extends StatelessWidget {
  const _LevelDots({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= level ? color : Colors.white24,
              boxShadow: i <= level
                  ? <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: 0.8),
                        blurRadius: 5,
                      ),
                    ]
                  : null,
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ urchase

/// Shown when the local player landed on an unowned property.
class PurchasePrompt extends StatelessWidget {
  const PurchasePrompt({
    super.key,
    required this.game,
    required this.tile,
    required this.player,
    required this.onBuy,
    required this.onDecline,
  });

  final GameState game;
  final TileModel tile;
  final PlayerModel player;
  final VoidCallback onBuy;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final bool affordable = player.cash >= tile.price;
    final bool ownsGroup = game.ownsWholeGroup(player.id, tile.groupId);
    return ModalShell(
      title: 'فرصت خرید ملک',
      subtitle: 'شما به «${tile.name}» رسیدید.',
      accent: tile.color,
      icon: Icons.sell_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _kv('قیمت', formatMoney(tile.price),
                    NeonColors.amber),
              ),
              Expanded(
                child: _kv('موجودی شما', formatMoney(player.cash),
                    affordable ? NeonColors.lime : NeonColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tile.type == TileType.city) ...<Widget>[
            Text('نردبان اجاره', style: neonText(size: 12, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            RentLadder(tile: tile, ownsGroup: ownsGroup),
          ] else
            Text(
              tile.description,
              style: neonText(size: 12, color: NeonColors.textDim),
            ),
          if (tile.type == TileType.transport) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'اجاره هر ایستگاه: ${formatMoney(tile.baseRent)} × تعداد ایستگاه‌های مالک',
              style: neonText(size: 11, color: NeonColors.textDim),
            ),
          ],
          if (tile.type == TileType.utility) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'اجاره: مجموع تاس × ۴ (یا × ۱۰ اگر هر دو خدمات را داشته باشید)',
              style: neonText(size: 11, color: NeonColors.textDim),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: NeonButton(
                  label: 'خرید به ${formatMoney(tile.price)}',
                  icon: Icons.shopping_cart_checkout,
                  color: NeonColors.lime,
                  onPressed: affordable ? onBuy : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NeonButton(
                  label: 'انصراف و حراج',
                  icon: Icons.gavel,
                  color: NeonColors.magenta,
                  filled: false,
                  onPressed: onDecline,
                ),
              ),
            ],
          ),
          if (!affordable) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'موجودی شما برای خرید این ملک کافی نیست؛ با انصراف، حراج آغاز می‌شود.',
              style: neonText(size: 11, color: NeonColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String key, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(key, style: neonText(size: 10.5, color: NeonColors.textDim)),
        Text(
          value,
          style: neonText(size: 15, weight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ auction

/// Live auction panel. Only the player whose turn it is can bid.
class AuctionOverlay extends StatefulWidget {
  const AuctionOverlay({
    super.key,
    required this.game,
    required this.localPlayerId,
    required this.onBid,
    required this.onPass,
  });

  final GameState game;
  final String? localPlayerId;
  final ValueChanged<int> onBid;
  final VoidCallback onPass;

  @override
  State<AuctionOverlay> createState() => _AuctionOverlayState();
}

class _AuctionOverlayState extends State<AuctionOverlay> {
  late double _bid;

  @override
  void initState() {
    super.initState();
    _bid = 0;
  }

  @override
  Widget build(BuildContext context) {
    final AuctionState auction = widget.game.auction!;
    final TileModel tile = auction.tile;
    final PlayerModel? me = widget.game.playerById(widget.localPlayerId);
    final bool myTurn = auction.currentBidderId == widget.localPlayerId;
    final int maxBid = me?.cash ?? 0;
    final int minBid = auction.nextMinBid;
    final int sliderMax = maxBid < minBid ? minBid : maxBid;
    final double bid = _bid.clamp(minBid.toDouble(), sliderMax.toDouble());
    final PlayerModel? leader = widget.game.playerById(auction.leaderId);

    return ModalShell(
      title: 'حراج «${tile.name}»',
      subtitle: auction.leaderId == null
          ? 'هنوز پیشنهادی ثبت نشده است.'
          : 'بالاترین پیشنهاد: ${formatMoney(auction.currentBid)} از «${leader?.name ?? "-"}»',
      accent: NeonColors.amber,
      icon: Icons.gavel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _stat('ارزش ملک', formatMoney(tile.price),
                    NeonColors.cyan),
              ),
              Expanded(
                child: _stat('حداقل پیشنهاد', formatMoney(minBid),
                    NeonColors.amber),
              ),
              Expanded(
                child: _stat('نوبت', myTurn ? 'شما' : 'دیگران',
                    myTurn ? NeonColors.lime : NeonColors.textDim),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (myTurn) ...<Widget>[
            Row(
              children: <Widget>[
                Text('پیشنهاد شما', style: neonText(size: 12)),
                const Spacer(),
                Text(
                  formatMoney(bid.round()),
                  style: neonText(
                    size: 17,
                    weight: FontWeight.w900,
                    color: NeonColors.lime,
                  ),
                ),
              ],
            ),
            Slider(
              value: bid,
              min: minBid.toDouble(),
              max: sliderMax.toDouble(),
              divisions: sliderMax <= minBid
                  ? null
                  : ((sliderMax - minBid) / 50).round().clamp(1, 400),
              label: formatMoney(bid.round()),
              onChanged: (double value) => setState(() => _bid = value),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: NeonButton(
                    label: 'پیشنهاد ${formatMoney(bid.round())}',
                    icon: Icons.trending_up,
                    color: NeonColors.lime,
                    height: 46,
                    onPressed: bid.round() >= minBid && bid.round() <= maxBid
                        ? () => widget.onBid(bid.round())
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeonButton(
                    label: 'رد کردن',
                    icon: Icons.close,
                    color: NeonColors.danger,
                    filled: false,
                    height: 46,
                    onPressed: widget.onPass,
                  ),
                ),
              ],
            ),
            if (maxBid < minBid) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'موجودی شما برای ادامه حراج کافی نیست؛ فقط می‌توانید رد کنید.',
                style: neonText(size: 11, color: NeonColors.danger),
              ),
            ],
          ] else ...<Widget>[
            Text(
              'در انتظار پیشنهاد بازیکن بعدی...',
              style: neonText(size: 12.5, color: NeonColors.textDim),
            ),
            const SizedBox(height: 10),
            _participants(auction),
          ],
          const SizedBox(height: 10),
          _participants(auction),
        ],
      ),
    );
  }

  Widget _participants(AuctionState auction) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: auction.activeIds.map((String id) {
        final PlayerModel? player = widget.game.playerById(id);
        final bool isLeader = auction.leaderId == id;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isLeader
                ? NeonColors.lime.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isLeader
                  ? NeonColors.lime.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            '${player?.name ?? "-"}${isLeader ? " ★" : ""}',
            style: neonText(
              size: 10.5,
              color: isLeader ? NeonColors.lime : NeonColors.textDim,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: neonText(size: 10, color: NeonColors.textDim)),
        Text(
          value,
          style: neonText(size: 13, weight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- card reveal

class CardRevealOverlay extends StatelessWidget {
  const CardRevealOverlay({
    super.key,
    required this.reveal,
    required this.playerName,
    required this.onAcknowledge,
  });

  final CardReveal reveal;
  final String playerName;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final GameCard? card = reveal.card;
    final Color accent = reveal.deck == CardDeck.chance
        ? NeonColors.amber
        : NeonColors.cyan;
    return ModalShell(
      title: reveal.deck.labelFa,
      subtitle: 'برای «$playerName»',
      accent: accent,
      icon: reveal.deck == CardDeck.chance
          ? Icons.casino_outlined
          : Icons.volunteer_activism_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            card?.title ?? 'کارت ناشناس',
            style: glowText(size: 20, color: accent, weight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            card?.description ?? '',
            style: neonText(size: 13, height: 1.7),
          ),
          const SizedBox(height: 18),
          NeonButton(
            label: 'تایید و ادامه',
            icon: Icons.check_circle_outline,
            color: accent,
            onPressed: onAcknowledge,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- trade dialog

class TradeResponseOverlay extends StatelessWidget {
  const TradeResponseOverlay({
    super.key,
    required this.game,
    required this.offer,
    required this.onAccept,
    required this.onReject,
  });

  final GameState game;
  final TradeOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final PlayerModel? from = game.playerById(offer.fromId);
    return ModalShell(
      title: 'پیشنهاد معامله',
      subtitle: 'از طرف «${from?.name ?? "-"}»',
      accent: NeonColors.violet,
      icon: Icons.swap_horiz,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _block(
            'آن‌ها به شما می‌دهند',
            offer.offeredTiles,
            offer.offeredCash,
            NeonColors.cyan,
          ),
          const SizedBox(height: 10),
          _block(
            'شما به آن‌ها می‌دهید',
            offer.requestedTiles,
            offer.requestedCash,
            NeonColors.magenta,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: NeonButton(
                  label: 'قبول معامله',
                  icon: Icons.check,
                  color: NeonColors.lime,
                  onPressed: onAccept,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NeonButton(
                  label: 'رد کردن',
                  icon: Icons.close,
                  color: NeonColors.danger,
                  filled: false,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _block(String title, List<int> tiles, int cash, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: neonText(
                  size: 11, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          if (cash > 0)
            Text('نقدینگی: ${formatMoney(cash)}',
                style: neonText(size: 12, color: NeonColors.lime)),
          if (tiles.isEmpty && cash == 0)
            Text('بدون مورد', style: neonText(size: 11, color: NeonColors.textDim)),
          ...tiles.map(
            (int index) => Text(
              '• ${TileModel.byIndex(index).name}',
              style: neonText(size: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- game over

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.game,
    required this.isHost,
    required this.onRematch,
    required this.onLeave,
  });

  final GameState game;
  final bool isHost;
  final VoidCallback onRematch;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final List<PlayerModel> ranking = game.ranking;
    final PlayerModel? winner = game.winner ?? (ranking.isEmpty ? null : ranking.first);
    return ModalShell(
      title: 'پایان بازی',
      subtitle: winner == null
          ? 'برنده‌ای مشخص نشد.'
          : '«${winner.name}» با دارایی ${formatMoney(winner.netWorth())} برنده شد.',
      accent: NeonColors.amber,
      icon: Icons.emoji_events_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ...ranking.asMap().entries.map((MapEntry<int, PlayerModel> entry) {
            final PlayerModel player = entry.value;
            final Color color =
                Color(PlayerPalette.colorFor(player.colorIndex));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${entry.key + 1}',
                      style: neonText(
                        size: 13,
                        weight: FontWeight.w900,
                        color: entry.key == 0
                            ? NeonColors.amber
                            : NeonColors.textDim,
                      ),
                    ),
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            color: color.withValues(alpha: 0.8), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.name,
                      style: neonText(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: player.bankrupt
                            ? NeonColors.textDim
                            : NeonColors.text,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(player.netWorth()),
                    style: neonText(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: NeonColors.lime,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              if (isHost)
                Expanded(
                  child: NeonButton(
                    label: 'بازی مجدد',
                    icon: Icons.replay,
                    color: NeonColors.lime,
                    onPressed: onRematch,
                  ),
                ),
              if (isHost) const SizedBox(width: 10),
              Expanded(
                child: NeonButton(
                  label: 'خروج',
                  icon: Icons.logout,
                  color: NeonColors.danger,
                  filled: false,
                  onPressed: onLeave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
