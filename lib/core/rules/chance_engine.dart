// [R16] All sixteen chance cards execute against the authoritative state.
import '../models/game_state.dart';
import '../data/chance_cards_data.dart';
import '../data/properties_data.dart';
import 'insurance_engine.dart';
import 'jail_engine.dart';
import 'phase_engine.dart';

class ChanceEngine {
  static void draw(GameState s, Player p) {
    final card = CHANCE_CARDS[s.nextRandom(CHANCE_CARDS.length)];
    apply(s, p, card);
  }

  static void apply(GameState s, Player p, ChanceCardData c) {
    s.lastChance = c.id;
    s.record('${p.name}: ${c.title}');
    final factor = !c.positive && InsuranceEngine.covered(s, p.id) ? 0.5 : 1.0;
    final amount = (c.amount ?? 0) * factor;
    final others = s.alive.where((o) => o.id != p.id).toList();
    switch (c.effect) {
      case ChanceEffect.moneyFromBank:
        p.cash += amount;
      case ChanceEffect.moneyFromPlayers:
        for (final o in others) {
          o.cash -= amount;
          p.cash += amount;
        }
      case ChanceEffect.discountNextProperty:
        p.discount = true;
      case ChanceEffect.moneyFromBankPool:
        final paid = s.bank.clamp(0, amount);
        s.bank -= paid;
        p.cash += paid;
      case ChanceEffect.moveToStart:
        p.position = 0;
        p.cash += s.laws.contains('law_03') ? 250 : PhaseEngine.salary(s.phase);
      case ChanceEffect.payBankPool:
        p.cash -= amount;
        s.bank += amount;
      case ChanceEffect.payPlayers:
        for (final o in others) {
          o.cash += amount;
          p.cash -= amount;
        }
      case ChanceEffect.loseBuilding:
        final built = s.properties
            .where((q) => q.owner == p.id && q.buildings > 0)
            .toList();
        if (built.isNotEmpty && !(factor == .5 && s.nextRandom(2) == 0)) {
          built[s.nextRandom(built.length)].buildings--;
        }
      case ChanceEffect.goToJail:
        if (!(factor == .5 && s.nextRandom(2) == 0)) JailEngine.send(s, p);
      case ChanceEffect.loseCredit:
        p.credit = (p.credit - amount.round()).clamp(0, 100);
      case ChanceEffect.moveToAnywhere:
        s.pendingMove = p.id;
      case ChanceEffect.moveToNextChance:
        for (int i = 1; i <= 32; i++) {
          final next = (p.position + i) % 32;
          if (BOARD[next].type == BoardSpaceType.chance) {
            if (next < p.position) p.cash += PhaseEngine.salary(s.phase);
            p.position = next;
            break;
          }
        }
      case ChanceEffect.moveToLastBought:
        if (s.lastBought != null) {
          p.position = BOARD
              .firstWhere((b) => b.propertyId == s.lastBought)
              .index;
        }
      case ChanceEffect.gainUnownedProperty:
        final free = s.properties.where((q) => q.owner == null).toList();
        if (free.isNotEmpty) {
          final q = free[s.nextRandom(free.length)];
          q.owner = p.id;
          s.lastBought = q.id;
        }
      case ChanceEffect.swapPosition:
        if (others.isNotEmpty) {
          final other = others[s.nextRandom(others.length)], old = p.position;
          p.position = other.position;
          other.position = old;
        }
    }
  }
}
