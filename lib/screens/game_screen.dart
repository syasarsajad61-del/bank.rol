import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../models/tile_model.dart';
import '../painters/dice_painter.dart';
import '../providers/game_provider.dart';
import '../theme.dart';
import '../widgets/board_view.dart';
import '../widgets/glass_panel.dart';
import '../widgets/hud_panel.dart';
import '../widgets/modals.dart';
import '../widgets/property_sheet.dart';
import '../widgets/trade_sheet.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;
  bool _diceRolling = false;
  int _lastRollCount = 0;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  void _maybeAnimateDice(GameState game) {
    if (game.rollCount != _lastRollCount) {
      _lastRollCount = game.rollCount;
      setState(() => _diceRolling = true);
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() => _diceRolling = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionState session = ref.watch(gameProvider);
    final GameState game = session.game;

    _maybeAnimateDice(game);

    ref.listen<SessionState>(gameProvider, (SessionState? prev, SessionState next) {
      if (next.banner != null && next.bannerSeq != prev?.bannerSeq) {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(next.banner!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: NeonColors.bg,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _Backdrop(animation: _ambient)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatusStrip(
                          game: game,
                          link: session.link,
                          role: session.role,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RoundIconButton(
                        icon: Icons.logout,
                        color: NeonColors.danger,
                        onTap: _confirmLeave,
                        tooltip: 'خروج از بازی',
                      ),
                      if (session.isHost) ...<Widget>[
                        const SizedBox(width: 6),
                        _RoundIconButton(
                          icon: Icons.qr_code_2,
                          color: NeonColors.cyan,
                          onTap: () => _showInvite(context, session),
                          tooltip: 'دعوت بازیکن',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  PlayerRail(
                    game: game,
                    localPlayerId: session.localPlayerId,
                  ),
                  Expanded(
                    child: BoardView(
                      game: game,
                      localPlayerId: session.localPlayerId,
                      onTileTap: (int index) =>
                          _showTileInfo(context, game, index),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ActionBar(
                    session: session,
                    diceRolling: _diceRolling,
                    onRoll: _roll,
                    onEndTurn: _endTurn,
                    onProperties: () => showPropertySheet(context),
                    onTrade: () => showTradeSheet(context),
                    onBankrupt: _confirmBankrupt,
                  ),
                  const SizedBox(height: 4),
                  LogTicker(lines: game.log),
                ],
              ),
            ),
          ),
          ..._overlays(session),
        ],
      ),
    );
  }

  List<Widget> _overlays(SessionState session) {
    final GameState game = session.game;
    final List<Widget> layers = <Widget>[];

    if (game.phase == GamePhase.gameOver) {
      layers.add(
        GameOverOverlay(
          game: game,
          isHost: session.isHost,
          onRematch: () => ref.read(gameProvider.notifier).rematch(),
          onLeave: () => ref.read(gameProvider.notifier).leaveSession(),
        ),
      );
      return layers;
    }

    if (game.cardReveal != null) {
      final String name = game.playerById(game.cardReveal!.playerId)?.name ??
          'بازیکن';
      layers.add(
        CardRevealOverlay(
          reveal: game.cardReveal!,
          playerName: name,
          onAcknowledge: () =>
              ref.read(gameProvider.notifier).acknowledgeCard(),
        ),
      );
      return layers;
    }

    if (game.auction != null) {
      layers.add(
        AuctionOverlay(
          game: game,
          localPlayerId: session.localPlayerId,
          onBid: (int amount) =>
              ref.read(gameProvider.notifier).placeBid(amount),
          onPass: () => ref.read(gameProvider.notifier).passBid(),
        ),
      );
      return layers;
    }

    final TradeOffer? offer = game.tradeOffer;
    if (offer != null && offer.isPending && offer.toId == session.localPlayerId) {
      layers.add(
        TradeResponseOverlay(
          game: game,
          offer: offer,
          onAccept: () =>
              ref.read(gameProvider.notifier).respondTrade(true),
          onReject: () =>
              ref.read(gameProvider.notifier).respondTrade(false),
        ),
      );
      return layers;
    }

    final PendingPurchase? pending = game.pendingPurchase;
    if (pending != null && pending.playerId == session.localPlayerId) {
      final PlayerModel? me = session.localPlayer;
      if (me != null) {
        layers.add(
          PurchasePrompt(
            game: game,
            tile: pending.tile,
            player: me,
            onBuy: () => ref.read(gameProvider.notifier).buyPending(),
            onDecline: () => ref.read(gameProvider.notifier).declinePending(),
          ),
        );
        return layers;
      }
    }

    if (game.phase == GamePhase.paused) {
      final String name =
          game.playerById(game.pausedForId)?.name ?? 'یکی از بازیکنان';
      layers.add(
        ModalShell(
          title: 'بازی متوقف است',
          subtitle: 'وضعیت بازی ذخیره شده و پس از اتصال مجدد ادامه می‌یابد.',
          accent: NeonColors.amber,
          icon: Icons.pause_circle_outline,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 4),
              const CircularProgressIndicator(strokeWidth: 2.4),
              const SizedBox(height: 14),
              Text(
                'در انتظار بازگشت «$name»...',
                textAlign: TextAlign.center,
                style: neonText(size: 13, color: NeonColors.textDim),
              ),
            ],
          ),
        ),
      );
    }

    return layers;
  }

  void _roll() {
    ref.read(gameProvider.notifier).rollDice();
  }

  void _endTurn() {
    ref.read(gameProvider.notifier).endTurn();
  }

  Future<void> _confirmLeave() async {
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('خروج از میز', style: glowText(size: 18)),
        content: Text(
          'با خروج، اتصال شما قطع می‌شود و بازی برای سایرین متوقف خواهد شد.',
          style: neonText(size: 13),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('انصراف', style: neonText(size: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'خروج',
              style: neonText(size: 13, color: NeonColors.danger),
            ),
          ),
        ],
      ),
    );
    if (leave ?? false) {
      await ref.read(gameProvider.notifier).leaveSession();
    }
  }

  Future<void> _confirmBankrupt() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('اعلام ورشکستگی', style: glowText(size: 18)),
        content: Text(
          'با اعلام ورشکستگی از بازی خارج می‌شوید و تمام املاک شما به بانک بازمی‌گردد.',
          style: neonText(size: 13),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('انصراف', style: neonText(size: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'اعلام ورشکستگی',
              style: neonText(size: 13, color: NeonColors.danger),
            ),
          ),
        ],
      ),
    );
    if (result ?? false) {
      ref.read(gameProvider.notifier).declareBankrupt();
    }
  }

  Future<void> _showInvite(BuildContext context, SessionState session) async {
    final String? address = session.address;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('دعوت بازیکن', style: glowText(size: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'بازیکنان باید به همان شبکه وای‌فای متصل باشند و این آدرس را وارد کنند:',
              style: neonText(size: 12.5, color: NeonColors.textDim),
            ),
            const SizedBox(height: 12),
            SelectableText(
              address ?? '-',
              style: glowText(size: 22, color: NeonColors.lime),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('بستن', style: neonText(size: 13)),
          ),
        ],
      ),
    );
  }

  void _showTileInfo(BuildContext context, GameState game, int index) {
    final TileModel tile = TileModel.byIndex(index);
    final PlayerModel? owner = game.ownerOf(index);
    final OwnedProperty? owned = game.propertyOf(index);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => Container(
        margin: const EdgeInsets.all(12),
        child: GlassPanel(
          accent: tile.color,
          radius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tile.color,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: tile.color.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tile.name,
                      style: glowText(size: 18, color: tile.color),
                    ),
                  ),
                  Text(
                    tile.type.labelFa,
                    style: neonText(size: 11, color: NeonColors.textDim),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tile.description,
                style: neonText(size: 12, color: NeonColors.textDim, height: 1.6),
              ),
              const SizedBox(height: 10),
              if (tile.isPurchasable) ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'قیمت: ${formatMoney(tile.price)}',
                        style: neonText(size: 12, weight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      owner == null
                          ? 'بدون مالک'
                          : 'مالک: ${owner.name}',
                      style: neonText(
                        size: 12,
                        color: owner == null
                            ? NeonColors.textDim
                            : Color(
                                PlayerPalette.colorFor(owner.colorIndex),
                              ),
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tile.type == TileType.city)
                  RentLadder(
                    tile: tile,
                    ownsGroup: owner != null &&
                        owned != null &&
                        game.ownsWholeGroup(owner.id, tile.groupId),
                  )
                else
                  Text(
                    'اجاره پایه: ${formatMoney(tile.baseRent)}',
                    style: neonText(size: 12, color: NeonColors.lime),
                  ),
                if (owned != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'سطح: ${TileModel.levelNamesFa[owned.level]}'
                    '${owned.mortgaged ? " (در رهن)" : ""}',
                    style: neonText(
                      size: 12,
                      color: owned.mortgaged
                          ? NeonColors.danger
                          : NeonColors.amber,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ action bar

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.session,
    required this.diceRolling,
    required this.onRoll,
    required this.onEndTurn,
    required this.onProperties,
    required this.onTrade,
    required this.onBankrupt,
  });

  final SessionState session;
  final bool diceRolling;
  final VoidCallback onRoll;
  final VoidCallback onEndTurn;
  final VoidCallback onProperties;
  final VoidCallback onTrade;
  final VoidCallback onBankrupt;

  @override
  Widget build(BuildContext context) {
    final GameState game = session.game;
    final PlayerModel? me = session.localPlayer;
    final bool myTurn = session.isMyTurn;
    final bool blocked = game.hasPendingModal ||
        game.cardReveal != null ||
        game.phase != GamePhase.playing;
    final bool inDebt = (me?.cash ?? 0) < 0;

    String hint;
    if (game.phase == GamePhase.paused) {
      hint = 'بازی متوقف شده است.';
    } else if (inDebt) {
      hint = 'بدهکار هستید: ملک رهن کنید یا ورشکستگی اعلام کنید.';
    } else if (myTurn) {
      hint = game.hasRolled
          ? 'حرکت را انجام دادید؛ نوبت را پایان دهید.'
          : 'نوبت شماست؛ تاس بریزید.';
    } else {
      hint = 'در انتظار «${game.currentPlayer?.name ?? "-"}»...';
    }

    final bool canRoll = myTurn && !game.hasRolled && !blocked && !inDebt;
    final bool canEnd = myTurn &&
        game.hasRolled &&
        !blocked &&
        !inDebt &&
        game.currentPlayer?.cash != null &&
        (game.currentPlayer?.cash ?? 0) >= 0;

    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      radius: 18,
      glow: 0.12,
      accent: myTurn ? NeonColors.lime : NeonColors.violet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      hint,
                      maxLines: 2,
                      style: neonText(
                        size: 11.5,
                        color: inDebt
                            ? NeonColors.danger
                            : (myTurn ? NeonColors.lime : NeonColors.textDim),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'نقد شما: ${formatMoney(me?.cash ?? 0)}',
                      style: neonText(
                        size: 11,
                        color: NeonColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DiceTray(
                diceA: game.diceA,
                diceB: game.diceB,
                rolling: diceRolling,
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: canRoll
                    ? NeonButton(
                        label: 'تاس بریز',
                        icon: Icons.casino,
                        color: NeonColors.cyan,
                        height: 44,
                        onPressed: onRoll,
                      )
                    : NeonButton(
                        label: 'پایان نوبت',
                        icon: Icons.skip_next,
                        color: NeonColors.lime,
                        height: 44,
                        onPressed: canEnd ? onEndTurn : null,
                      ),
              ),
              const SizedBox(width: 6),
              _RoundIconButton(
                icon: Icons.home_work_outlined,
                color: NeonColors.amber,
                onTap: onProperties,
                tooltip: 'املاک من',
              ),
              const SizedBox(width: 6),
              _RoundIconButton(
                icon: Icons.swap_horiz,
                color: NeonColors.violet,
                onTap: onTrade,
                tooltip: 'معامله',
              ),
              if (inDebt && myTurn) ...<Widget>[
                const SizedBox(width: 6),
                _RoundIconButton(
                  icon: Icons.gavel,
                  color: NeonColors.danger,
                  onTap: onBankrupt,
                  tooltip: 'اعلام ورشکستگی',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.55)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- backdrop

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: <Color>[
                Color(0xFF101B3A),
                NeonColors.bgDeep,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _GridPainter(phase: animation.value),
            child: child,
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint line = Paint()
      ..color = NeonColors.cyan.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const double gap = 42;
    final double offset = phase * gap;
    for (double x = -gap + offset; x < size.width + gap; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = -gap + offset; y < size.height + gap; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          NeonColors.magenta.withValues(alpha: 0.10 + 0.04 * math.sin(phase * math.pi * 2)),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.78, size.height * 0.18),
          radius: size.width * 0.7,
        ),
      );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
