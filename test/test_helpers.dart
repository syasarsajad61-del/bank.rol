import 'package:bankroll_plato/core/models/game_state.dart';
import 'package:bankroll_plato/core/rules/turn_manager.dart';

GameState fixture({int count = 3}) => TurnManager.create(
  List.generate(
    count,
    (i) => Player(id: 'p$i', name: 'بازیکن $i', identity: i),
  ),
  seed: 19,
  target: 7000,
  rounds: 30,
);
