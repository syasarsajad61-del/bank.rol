// [R23][A06] Only participants see their private agreements.
import '../models/game_state.dart';

class ContractEngine {
  static Contract sign(
    GameState s,
    Player p,
    String second,
    ContractKind kind,
  ) {
    if (second == p.id || s.player(second).eliminated) {
      throw StateError('طرف قرارداد معتبر نیست');
    }
    if (s.contracts.any(
      (c) =>
          c.accepted &&
          !c.broken &&
          c.expires > s.round &&
          c.includes(p.id) &&
          c.includes(second) &&
          c.kind == kind,
    )) {
      throw StateError('قرارداد فعال وجود دارد');
    }
    final c = Contract(
      id: 'contract_${s.revision}_${s.contracts.length}',
      first: p.id,
      second: second,
      kind: kind,
      expires: s.round + 5,
    );
    s.contracts.add(c);
    return c;
  }

  static void breakContract(GameState s, Player p, String id) {
    final c = s.contracts.firstWhere(
      (c) =>
          c.id == id &&
          c.includes(p.id) &&
          c.accepted &&
          !c.broken &&
          c.expires > s.round,
    );
    p.cash -= 400;
    s.bank += 400;
    p.credit = (p.credit - 15).clamp(0, 100);
    c.broken = true;
    s.record('${p.name} قرارداد را شکست');
  }

  static double adjustRent(
    GameState s,
    Player visitor,
    Player owner,
    double rent,
  ) {
    for (final c in s.contracts.where(
      (c) =>
          c.accepted &&
          !c.broken &&
          c.expires > s.round &&
          c.includes(visitor.id) &&
          c.includes(owner.id),
    )) {
      if (c.kind == ContractKind.nonAggression) return 0;
    }
    return rent;
  }

  static void share(GameState s, Player owner, double rent) {
    for (final c in s.contracts.where(
      (c) =>
          c.accepted &&
          !c.broken &&
          c.expires > s.round &&
          c.includes(owner.id) &&
          c.kind == ContractKind.rentShare,
    )) {
      final partner = s.player(c.other(owner.id));
      if (!partner.eliminated) {
        final part = rent * .25;
        owner.cash -= part;
        partner.cash += part;
      }
    }
  }
}
