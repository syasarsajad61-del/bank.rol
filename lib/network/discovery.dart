// [M03][M05] UDP discovery on configurable port plus one.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

class LanRoom {
  final String name, address, session;
  final int port, players;
  LanRoom(this.name, this.address, this.port, this.players, this.session);
}

class Discovery {
  RawDatagramSocket? socket;
  Timer? timer;
  final controller = StreamController<LanRoom>.broadcast();
  Future<void> advertise(
    String name,
    int port,
    String session,
    int Function() players,
  ) async {
    socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port + 1,
      reuseAddress: true,
    );
    socket!.broadcastEnabled = true;
    socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final d = socket!.receive();
        if (d != null &&
            utf8.decode(d.data, allowMalformed: true) == 'BANKROLL_DISCOVER') {
          socket!.send(
            utf8.encode(
              jsonEncode({
                'app': 'bankroll',
                'name': name,
                'port': port,
                'players': players(),
                'session': session,
              }),
            ),
            d.address,
            d.port,
          );
        }
      }
    });
  }

  Future<void> search({int port = 7823}) async {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket!.broadcastEnabled = true;
    socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final d = socket!.receive();
      if (d == null) return;
      try {
        final j = jsonDecode(utf8.decode(d.data));
        if (j['app'] == 'bankroll') {
          controller.add(
            LanRoom(
              j['name'],
              d.address.address,
              j['port'],
              j['players'],
              j['session'],
            ),
          );
        }
      } catch (_) {}
    });
    void send() {
      socket?.send(
        utf8.encode('BANKROLL_DISCOVER'),
        InternetAddress('255.255.255.255'),
        port + 1,
      );
    }

    send();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => send());
  }

  void dispose() {
    timer?.cancel();
    socket?.close();
    controller.close();
  }
}
