// [R01][R04][M10][A07] Serializable authoritative game state.
import '../data/properties_data.dart';
import '../rules/rent_calculator.dart';

enum EconomicPhase { stable, bull, bear }

enum ContractKind { nonAggression, rentShare, informant }

enum BankChoice { loan, split, save }

enum Difficulty { easy, medium, hard }

enum Personality { conservative, aggressive, balanced }

class Player {
  final String id;
  final String name;
  final int identity;
  final bool bot;
  final Difficulty difficulty;
  final Personality personality;
  double cash;
  int position, credit, jailTurns, inactiveTurns, sixes;
  bool eliminated, discount;
  Player({
    required this.id,
    required this.name,
    required this.identity,
    this.bot = false,
    this.difficulty = Difficulty.medium,
    this.personality = Personality.balanced,
    this.cash = 1500,
    this.position = 0,
    this.credit = 70,
    this.jailTurns = 0,
    this.inactiveTurns = 0,
    this.sixes = 0,
    this.eliminated = false,
    this.discount = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'identity': identity,
    'bot': bot,
    'difficulty': difficulty.index,
    'personality': personality.index,
    'cash': cash,
    'position': position,
    'credit': credit,
    'jailTurns': jailTurns,
    'inactiveTurns': inactiveTurns,
    'sixes': sixes,
    'eliminated': eliminated,
    'discount': discount,
  };
  factory Player.fromJson(Map<String, dynamic> j) => Player(
    id: j['id'],
    name: j['name'],
    identity: j['identity'],
    bot: j['bot'],
    difficulty: Difficulty.values[j['difficulty']],
    personality: Personality.values[j['personality']],
    cash: (j['cash'] as num).toDouble(),
    position: j['position'],
    credit: j['credit'],
    jailTurns: j['jailTurns'],
    inactiveTurns: j['inactiveTurns'],
    sixes: j['sixes'],
    eliminated: j['eliminated'],
    discount: j['discount'],
  );
}

class Property {
  final String id, name;
  final int price, baseRent, buildingCost;
  final PropertyColor? block;
  String? owner;
  int buildings;
  Property({
    required this.id,
    required this.name,
    required this.price,
    required this.baseRent,
    this.buildingCost = 0,
    this.block,
    this.owner,
    this.buildings = 0,
  });
  bool get isPublic => block == null;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'baseRent': baseRent,
    'buildingCost': buildingCost,
    'block': block?.index,
    'owner': owner,
    'buildings': buildings,
  };
  factory Property.fromJson(Map<String, dynamic> j) => Property(
    id: j['id'],
    name: j['name'],
    price: j['price'],
    baseRent: j['baseRent'],
    buildingCost: j['buildingCost'],
    block: j['block'] == null ? null : PropertyColor.values[j['block']],
    owner: j['owner'],
    buildings: j['buildings'],
  );
}

class Contract {
  final String id, first, second;
  final ContractKind kind;
  final int expires;
  bool broken, accepted;
  Contract({
    required this.id,
    required this.first,
    required this.second,
    required this.kind,
    required this.expires,
    this.broken = false,
    this.accepted = false,
  });
  bool includes(String id) => first == id || second == id;
  String other(String id) => first == id ? second : first;
  Map<String, dynamic> toJson() => {
    'id': id,
    'first': first,
    'second': second,
    'kind': kind.index,
    'expires': expires,
    'broken': broken,
    'accepted': accepted,
  };
  factory Contract.fromJson(Map<String, dynamic> j) => Contract(
    id: j['id'],
    first: j['first'],
    second: j['second'],
    kind: ContractKind.values[j['kind']],
    expires: j['expires'],
    broken: j['broken'],
    accepted: j['accepted'] ?? false,
  );
}

class Loan {
  final String id, borrower;
  final double principal, due;
  final int dueRound;
  final String? guarantor, collateral;
  bool settled, defaulted, pending;
  Loan({
    required this.id,
    required this.borrower,
    required this.principal,
    required this.due,
    required this.dueRound,
    this.guarantor,
    this.collateral,
    this.settled = false,
    this.defaulted = false,
    this.pending = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'borrower': borrower,
    'principal': principal,
    'due': due,
    'dueRound': dueRound,
    'guarantor': guarantor,
    'collateral': collateral,
    'settled': settled,
    'defaulted': defaulted,
    'pending': pending,
  };
  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
    id: j['id'],
    borrower: j['borrower'],
    principal: (j['principal'] as num).toDouble(),
    due: (j['due'] as num).toDouble(),
    dueRound: j['dueRound'],
    guarantor: j['guarantor'],
    collateral: j['collateral'],
    settled: j['settled'],
    defaulted: j['defaulted'],
    pending: j['pending'] ?? false,
  );
}

class Insurance {
  final String owner;
  final int expires;
  final String? propertyId;
  Insurance(this.owner, this.expires, {this.propertyId});
  Map<String, dynamic> toJson() => {
    'owner': owner,
    'expires': expires,
    'propertyId': propertyId,
  };
  factory Insurance.fromJson(Map<String, dynamic> j) =>
      Insurance(j['owner'], j['expires'], propertyId: j['propertyId']);
}

class Auction {
  final String propertyId, trigger;
  final int deadline;
  final Map<String, double> bids;
  Auction(
    this.propertyId,
    this.trigger,
    this.deadline, {
    Map<String, double>? bids,
  }) : bids = bids ?? {};
  Map<String, dynamic> toJson({bool private = true}) => {
    'propertyId': propertyId,
    'trigger': trigger,
    'deadline': deadline,
    if (private) 'bids': bids,
  };
  factory Auction.fromJson(Map<String, dynamic> j) => Auction(
    j['propertyId'],
    j['trigger'],
    j['deadline'],
    bids: (j['bids'] as Map? ?? {}).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    ),
  );
}

class Vote {
  final List<String> candidates;
  final Map<String, String> elimination, ballots, bankBallots;
  int stage, deadline;
  Vote(
    this.candidates,
    this.deadline, {
    this.stage = 0,
    Map<String, String>? elimination,
    Map<String, String>? ballots,
    Map<String, String>? bankBallots,
  }) : elimination = elimination ?? {},
       ballots = ballots ?? {},
       bankBallots = bankBallots ?? {};
  Map<String, dynamic> toJson() => {
    'candidates': candidates,
    'deadline': deadline,
    'stage': stage,
    'elimination': elimination,
    'ballots': ballots,
    'bankBallots': bankBallots,
  };
  factory Vote.fromJson(Map<String, dynamic> j) => Vote(
    List<String>.from(j['candidates']),
    j['deadline'],
    stage: j['stage'],
    elimination: Map<String, String>.from(j['elimination']),
    ballots: Map<String, String>.from(j['ballots']),
    bankBallots: Map<String, String>.from(j['bankBallots']),
  );
}

class GameState {
  List<Player> players;
  List<Property> properties;
  List<Contract> contracts;
  List<Loan> loans;
  List<Insurance> policies;
  List<String> laws, log;
  List<Map<String, dynamic>> trades = [];
  int turn, round, target, roundLimit, rng, revision, lastDice;
  double bank, initialMoney;
  EconomicPhase phase;
  bool rolled, extraRoll, ended;
  String? winner, lastBought, pendingMove, lastChance;
  Auction? auction;
  Vote? vote;
  GameState({
    required this.players,
    required this.properties,
    this.turn = 0,
    this.round = 1,
    this.target = 5000,
    this.roundLimit = 30,
    this.rng = 42,
    this.revision = 0,
    this.lastDice = 1,
    this.bank = 300,
    this.initialMoney = 300,
    this.phase = EconomicPhase.stable,
    this.rolled = false,
    this.extraRoll = false,
    this.ended = false,
    this.winner,
    this.lastBought,
    this.pendingMove,
    this.lastChance,
    this.auction,
    this.vote,
    List<Contract>? contracts,
    List<Loan>? loans,
    List<Insurance>? policies,
    List<String>? laws,
    List<String>? log,
  }) : contracts = contracts ?? [],
       loans = loans ?? [],
       policies = policies ?? [],
       laws = laws ?? [],
       log = log ?? [];
  Player get active => players[turn];
  List<Player> get alive => players.where((p) => !p.eliminated).toList();
  Player player(String id) => players.firstWhere((p) => p.id == id);
  Property property(String id) => properties.firstWhere((p) => p.id == id);
  int nextRandom(int max) {
    rng = (1664525 * rng + 1013904223) & 0xffffffff;
    return (rng >> 8) % max;
  }

  double debt(String id) => loans
      .where((l) => l.borrower == id && !l.settled && !l.pending)
      .fold(0, (v, l) => v + l.due);
  double netWorth(String id) =>
      player(id).cash +
      properties
          .where((p) => p.owner == id)
          .fold<double>(
            0,
            (v, p) =>
                v +
                RentCalculator.value(this, p) +
                p.buildings * RentCalculator.buildingPrice(this, p),
          ) -
      debt(id);
  void record(String text) {
    log.add(text);
    if (log.length > 160) log.removeAt(0);
  }

  Map<String, dynamic> toJson({String? viewer, bool migration = false}) => {
    'players': players.map((p) => p.toJson()).toList(),
    'properties': properties.map((p) => p.toJson()).toList(),
    'contracts': contracts
        .where((c) => viewer == null || migration || c.includes(viewer))
        .map((c) => c.toJson())
        .toList(),
    'loans': loans.map((l) => l.toJson()).toList(),
    'policies': policies.map((p) => p.toJson()).toList(),
    'laws': laws,
    'trades': trades,
    'log': log,
    'turn': turn,
    'round': round,
    'target': target,
    'roundLimit': roundLimit,
    'rng': rng,
    'revision': revision,
    'lastDice': lastDice,
    'bank': bank,
    'initialMoney': initialMoney,
    'phase': phase.index,
    'rolled': rolled,
    'extraRoll': extraRoll,
    'ended': ended,
    'winner': winner,
    'lastBought': lastBought,
    'pendingMove': pendingMove,
    'lastChance': lastChance,
    'auction': auction == null
        ? null
        : {
            ...auction!.toJson(private: viewer == null || migration),
            if (viewer != null && !migration)
              'bids': {
                for (final id in visibleBidders(viewer))
                  if (auction!.bids.containsKey(id)) id: auction!.bids[id],
              },
          },
    'vote': vote?.toJson(),
  };
  Set<String> visibleBidders(String viewer) => {
    viewer,
    for (final c in contracts.where(
      (c) =>
          c.accepted &&
          !c.broken &&
          c.expires > round &&
          c.includes(viewer) &&
          c.kind == ContractKind.informant,
    ))
      c.other(viewer),
  };
  factory GameState.fromJson(Map<String, dynamic> j) =>
      GameState(
          players: (j['players'] as List)
              .map((p) => Player.fromJson(Map<String, dynamic>.from(p)))
              .toList(),
          properties: (j['properties'] as List)
              .map((p) => Property.fromJson(Map<String, dynamic>.from(p)))
              .toList(),
          contracts: (j['contracts'] as List)
              .map((p) => Contract.fromJson(Map<String, dynamic>.from(p)))
              .toList(),
          loans: (j['loans'] as List)
              .map((p) => Loan.fromJson(Map<String, dynamic>.from(p)))
              .toList(),
          policies: (j['policies'] as List)
              .map((p) => Insurance.fromJson(Map<String, dynamic>.from(p)))
              .toList(),
          laws: List<String>.from(j['laws']),
          log: List<String>.from(j['log']),
          turn: j['turn'],
          round: j['round'],
          target: j['target'],
          roundLimit: j['roundLimit'],
          rng: j['rng'],
          revision: j['revision'],
          lastDice: j['lastDice'],
          bank: (j['bank'] as num).toDouble(),
          initialMoney: (j['initialMoney'] as num).toDouble(),
          phase: EconomicPhase.values[j['phase']],
          rolled: j['rolled'],
          extraRoll: j['extraRoll'],
          ended: j['ended'],
          winner: j['winner'],
          lastBought: j['lastBought'],
          pendingMove: j['pendingMove'],
          lastChance: j['lastChance'],
          auction: j['auction'] == null
              ? null
              : Auction.fromJson(Map<String, dynamic>.from(j['auction'])),
          vote: j['vote'] == null
              ? null
              : Vote.fromJson(Map<String, dynamic>.from(j['vote'])),
        )
        ..trades = (j['trades'] as List? ?? [])
            .map((t) => Map<String, dynamic>.from(t))
            .toList();
}
