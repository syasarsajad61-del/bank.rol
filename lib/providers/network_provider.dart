// [M02-M13] LAN lobby, reconnect window and designated snapshot successor.
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/models/game_state.dart';
import '../network/host_server.dart';
import '../network/client_connection.dart';
import '../network/discovery.dart';
import '../network/protocol.dart';
import '../network/snapshot.dart';
import 'game_provider.dart';

class NetworkProvider extends ChangeNotifier {
  static const hotspot = MethodChannel('ir.zahedan.bankroll/hotspot');
  final GameProvider game;
  HostServer? host;
  ClientConnection? client;
  Discovery? discovery;
  final List<LanRoom> rooms = [];
  List<Map<String, dynamic>> roster = [];
  Map<String, dynamic>? backup;
  String id = '',
      name = '',
      pin = '',
      address = '',
      status = 'آماده',
      session = '',
      hostId = '';
  String? successor;
  int port = 7823;
  bool connected = false, reconnecting = false, leaving = false;
  NetworkProvider(this.game);
  bool get isHost => host != null;
  Future<void> create(
    String playerId,
    String playerName, {
    int selectedPort = 7823,
  }) async {
    if (kIsWeb) throw StateError('شبکهٔ محلی در نسخهٔ اندروید در دسترس است');
    await leave();
    game.state = null;
    leaving = false;
    id = playerId;
    name = playerName;
    port = selectedPort;
    pin = SecureProtocol.pin();
    hostId = id;
    await _host();
    connected = true;
    final addresses = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    address = addresses
        .expand((i) => i.addresses)
        .where((a) => !a.isLoopback)
        .map((a) => a.address)
        .join(' / ');
    status = 'اتاق ساخته شد';
    notifyListeners();
  }

  Future<void> _host() async {
    host = HostServer(
      hostId: id,
      hostName: name,
      pin: pin,
      port: port,
      session: session.isEmpty ? null : session,
      state: () => game.state,
      onRoster: () {
        roster = host!.roster;
        notifyListeners();
      },
      onAction: (id, type, data, now) => game.execute(id, type, data, now),
    );
    await host!.start();
    session = host!.session;
    game.authority = true;
    game.broadcast = () => host!.broadcast();
    roster = host!.roster;
    discovery = Discovery();
    await discovery!.advertise(
      'محلهٔ $name',
      port,
      session,
      () => roster.length,
    );
  }

  Future<Map<String, dynamic>> startHotspot() async {
    final value = await hotspot.invokeMapMethod<String, dynamic>('start');
    return value ?? {};
  }

  Future<void> search({int selectedPort = 7823}) async {
    if (kIsWeb) return;
    discovery?.dispose();
    rooms.clear();
    discovery = Discovery();
    discovery!.controller.stream.listen((room) {
      rooms.removeWhere(
        (r) => r.address == room.address && r.port == room.port,
      );
      rooms.add(room);
      notifyListeners();
    });
    await discovery!.search(port: selectedPort);
  }

  Future<void> join(
    String playerId,
    String playerName,
    String ip,
    String code, {
    int selectedPort = 7823,
  }) async {
    await leave();
    leaving = false;
    id = playerId;
    name = playerName;
    address = ip;
    pin = code;
    port = selectedPort;
    game.authority = false;
    game.localId = id;
    game.state = null;
    status = 'در حال اتصال';
    notifyListeners();
    await _connect(ip);
    connected = true;
    status = 'متصل به اتاق';
    notifyListeners();
  }

  Future<void> _connect(String ip) async {
    client = ClientConnection(
      id: id,
      name: name,
      pin: pin,
      onDisconnected: () {
        if (!leaving && !reconnecting) _recover();
      },
      onMessage: (j) {
        switch (j['type']) {
          case 'welcome':
            hostId = j['hostId'];
            session = client?.codec?.session ?? session;
          case 'roster':
            roster = (j['players'] as List)
                .map((p) => Map<String, dynamic>.from(p))
                .toList();
            successor = j['successor'];
            notifyListeners();
          case 'snapshot':
            game.receive(
              Snapshot.decode(Map<String, dynamic>.from(j['snapshot'])),
            );
          case 'backup':
            backup = Map<String, dynamic>.from(j['snapshot']);
          case 'error':
            game.error = j['message'];
            game.notifyListeners();
        }
      },
    );
    await client!.connect(ip, port);
    game.send = (type, data, revision) => client!.send(type, data, revision);
  }

  Future<void> _recover() async {
    reconnecting = true;
    connected = false;
    status = 'اتصال قطع شد؛ تلاش مجدد تا ۶۰ ثانیه';
    notifyListeners();
    final start = DateTime.now();
    while (!leaving && DateTime.now().difference(start).inSeconds < 60) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (leaving) break;
      try {
        await client?.dispose();
        await _connect(address);
        connected = true;
        break;
      } catch (_) {}
      if (DateTime.now().difference(start).inSeconds >= 6 &&
          successor != null) {
        try {
          if (successor == id && backup != null) {
            game.state = Snapshot.decode(backup!);
            await _host();
            game.deadline = DateTime.now().millisecondsSinceEpoch + 90000;
            connected = true;
            status = 'میزبانی با آخرین ذخیره منتقل شد';
            break;
          }
          final candidate = roster
              .where((p) => p['id'] == successor)
              .firstOrNull;
          if (candidate != null) {
            await client?.dispose();
            await _connect(candidate['address']);
            address = candidate['address'];
            connected = true;
            break;
          }
        } catch (_) {}
      }
    }
    reconnecting = false;
    if (!connected) {
      status = 'مهلت اتصال مجدد تمام شد';
    } else if (!isHost) {
      status = 'اتصال بازیابی شد';
    }
    notifyListeners();
  }

  Future<void> begin({
    int bots = 0,
    int target = 5000,
    int rounds = 30,
    Difficulty difficulty = Difficulty.medium,
  }) async {
    if (host == null) throw StateError('فقط میزبان می‌تواند بازی را آغاز کند');
    if (roster.length + bots < 2 || roster.length + bots > 6) {
      throw StateError('۲ تا ۶ بازیکن لازم است');
    }
    game.localId = id;
    game.start(
      [
        for (int i = 0; i < roster.length; i++)
          Player(id: roster[i]['id'], name: roster[i]['name'], identity: i),
        for (int i = 0; i < bots; i++)
          Player(
            id: 'bot_$i',
            name: ['آرمان', 'رها', 'نیما', 'سارا', 'پارسا'][i],
            identity: roster.length + i,
            bot: true,
            difficulty: difficulty,
            personality: Personality.values[i % 3],
          ),
      ],
      target: target,
      rounds: rounds,
    );
    await host!.broadcast();
  }

  Future<void> leave() async {
    leaving = true;
    connected = false;
    game.broadcast = null;
    game.send = null;
    await client?.dispose();
    await host?.dispose();
    discovery?.dispose();
    host = null;
    client = null;
    discovery = null;
    roster = [];
    backup = null;
    session = '';
    successor = null;
    notifyListeners();
  }

  @override
  void dispose() {
    leaving = true;
    client?.dispose();
    host?.dispose();
    discovery?.dispose();
    super.dispose();
  }
}
