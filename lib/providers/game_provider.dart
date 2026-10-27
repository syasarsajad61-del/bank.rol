// [T05][M01][M10][M13][B10] State ownership, serial saves and authoritative timers.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as paths;
import '../core/models/game_state.dart';
import '../core/rules/turn_manager.dart';
import '../core/rules/phase_engine.dart';
import '../core/utils/logger.dart';
import '../ai/bot_controller.dart';
import '../network/snapshot.dart';

class GameProvider extends ChangeNotifier {
  GameState? state;
  String localId = '';
  bool authority = true, busy = false, hasSaved = false;
  String? error;
  Timer? ticker;
  int deadline = 0, _botAt = 0;
  Database? db;
  Future<void> _saving = Future.value();
  Future<void> Function()? broadcast;
  void Function(String, Map<String, dynamic>, int)? send;
  void Function(String)? sound;
  Future<void> initialize() async {
    final p = await SharedPreferences.getInstance();
    hasSaved = p.containsKey('gameSnapshot');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      db = await openDatabase(
        paths.join(await getDatabasesPath(), 'bankroll.db'),
        version: 1,
        onCreate: (db, v) async {
          await db.execute(
            'CREATE TABLE snapshots (id INTEGER PRIMARY KEY, revision INTEGER, payload TEXT NOT NULL)',
          );
        },
      );
    }
    ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
    notifyListeners();
  }

  void start(
    List<Player> players, {
    int target = 5000,
    int rounds = 30,
    bool isHost = true,
  }) {
    authority = isHost;
    state = TurnManager.create(
      players,
      target: target,
      rounds: rounds,
      seed: Random.secure().nextInt(0x7fffffff),
    );
    deadline = DateTime.now().millisecondsSinceEpoch + 90000;
    error = null;
    _changed();
  }

  Future<void> resume() async {
    final p = await SharedPreferences.getInstance();
    String? raw = p.getString('gameSnapshot');
    if (db != null) {
      final rows = await db!.query(
        'snapshots',
        where: 'id = ?',
        whereArgs: [1],
      );
      if (rows.isNotEmpty) raw = rows.first['payload'] as String;
    }
    if (raw == null) throw StateError('بازی ذخیره‌شده‌ای وجود ندارد');
    state = Snapshot.decode(Map<String, dynamic>.from(jsonDecode(raw)));
    authority = true;
    deadline = DateTime.now().millisecondsSinceEpoch + 90000;
    notifyListeners();
  }

  bool get myTurn =>
      state != null && state!.active.id == localId && !state!.ended;
  Player? get me => state?.players.where((p) => p.id == localId).firstOrNull;
  void command(String type, [Map<String, dynamic> data = const {}]) {
    if (state == null) return;
    if (!authority) {
      send?.call(type, data, state!.revision);
      return;
    }
    execute(localId, type, data, DateTime.now().millisecondsSinceEpoch);
  }

  void execute(String id, String type, Map<String, dynamic> data, int now) {
    final s = state;
    if (s == null) return;
    try {
      final draft = GameState.fromJson(s.toJson());
      TurnManager.apply(draft, id, type, data, now);
      state = draft;
      error = null;
      if (draft.active.id != s.active.id || draft.round != s.round) {
        deadline = now + 90000;
      }
      sound?.call(
        type == 'roll'
            ? 'dice_roll'
            : type == 'breakContract'
            ? 'contract_seal'
            : type == 'buy' || type == 'bid'
            ? 'coin_collect'
            : 'phase_change',
      );
      _changed();
    } catch (e) {
      error = e is StateError ? e.message.toString() : 'فرمان نامعتبر است';
      notifyListeners();
      if (id != localId) rethrow;
    }
  }

  void receive(GameState s) {
    if (state != null && s.revision < state!.revision) return;
    state = s;
    error = null;
    notifyListeners();
  }

  void _changed() {
    notifyListeners();
    if (authority) {
      save();
      broadcast?.call();
    }
  }

  Future<void> save() {
    final s = state;
    if (s == null || !authority) return Future.value();
    final raw = jsonEncode(Snapshot.encode(s));
    hasSaved = true;
    _saving = _saving
        .then((_) async {
          final p = await SharedPreferences.getInstance();
          await p.setString('gameSnapshot', raw);
          if (db != null) {
            await db!.insert('snapshots', {
              'id': 1,
              'revision': s.revision,
              'payload': raw,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        })
        .catchError((Object e) {
          GameLogger.event('save_failed');
        });
    return _saving;
  }

  void tick() {
    final s = state;
    if (s == null || !authority || s.ended) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final before = s.revision;
    TurnManager.tick(s, now);
    if (s.revision != before) _changed();
    if (s.auction == null && s.vote == null && now > deadline) {
      TurnManager.timeout(s, now);
      deadline = now + 90000;
      _changed();
    }
    if (now < _botAt) return;
    _botAt = now + 800;
    final responsive = s.alive.where((p) => p.bot).toList();
    for (final p in responsive) {
      final a = BotController.decide(s, p);
      if (a != null) {
        try {
          execute(p.id, a.type, a.data, now);
        } catch (e) {
          GameLogger.event('bot_action_rejected', fields: {'type': a.type});
        }
        break;
      }
    }
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    ticker?.cancel();
    db?.close();
    super.dispose();
  }
}
