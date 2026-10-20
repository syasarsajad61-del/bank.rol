import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/player_model.dart';
import '../painters/board_painter.dart';

/// The isometric 2.5D board.
///
/// The flat procedural board is painted into a square canvas and then
/// tilted with a [Matrix4] perspective so it reads as a physical table.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.game,
    required this.localPlayerId,
    this.onTileTap,
    this.tiltX = -0.40,
    this.tiltZ = -0.05,
    this.fit = 0.74,
  });

  final GameState game;
  final String? localPlayerId;
  final ValueChanged<int>? onTileTap;
  final double tiltX;
  final double tiltZ;

  /// Fraction of the available square the board occupies. Kept below 1 so
  /// the tilted projection still fits inside its box on every device.
  final double fit;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Map<int, BoardTileView> _buildTileViews(GameState game) {
    final Map<int, BoardTileView> views = <int, BoardTileView>{};
    final int? pendingIndex = game.pendingPurchase?.tileIndex;
    if (pendingIndex != null) {
      views[pendingIndex] = const BoardTileView(highlight: true);
    }
    final int? auctionIndex = game.auction?.tileIndex;
    if (auctionIndex != null) {
      views[auctionIndex] =
          const BoardTileView(highlight: true);
    }
    for (final PlayerModel player in game.players) {
      final Color color = Color(PlayerPalette.colorFor(player.colorIndex));
      player.properties.forEach((int index, OwnedProperty owned) {
        views[index] = BoardTileView(
          ownerColor: color,
          level: owned.level,
          mortgaged: owned.mortgaged,
          highlight: pendingIndex == index || auctionIndex == index,
        );
      });
    }
    return views;
  }

  List<PlayerMarker> _buildMarkers(GameState game) {
    final String? currentId = game.currentPlayerId;
    return game.players
        .map(
          (PlayerModel player) => PlayerMarker(
            position: player.position,
            color: Color(PlayerPalette.colorFor(player.colorIndex)),
            isCurrent: player.id == currentId,
            initial: player.name.isEmpty ? '' : player.name.substring(0, 1),
            connected: player.connected,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, BoardTileView> tileViews = _buildTileViews(widget.game);
    final List<PlayerMarker> markers = _buildMarkers(widget.game);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            math.min(constraints.maxWidth, constraints.maxHeight) * widget.fit;
        if (side <= 0) {
          return const SizedBox.shrink();
        }
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0009)
                ..rotateX(widget.tiltX)
                ..rotateZ(widget.tiltZ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (TapUpDetails details) {
                  if (widget.onTileTap == null) {
                    return;
                  }
                  final int? hit =
                      BoardGeometry(side).tileAt(details.localPosition);
                  if (hit != null) {
                    widget.onTileTap!(hit);
                  }
                },
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      size: Size(side, side),
                      painter: BoardPainter(
                        tileViews: tileViews,
                        markers: markers,
                        diceA: widget.game.diceA,
                        diceB: widget.game.diceB,
                        round: widget.game.round,
                        pulse: _pulse.value,
                        revision: widget.game.revision,
                        showDice: !widget.game.isLobby,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
