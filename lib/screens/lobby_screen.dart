import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../network/client_socket.dart';
import '../providers/game_provider.dart';
import '../theme.dart';
import '../widgets/glass_panel.dart';

/// Landing area: create a table, or join one by address / QR.
class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

enum _LobbyMode { host, join }

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final TextEditingController _name = TextEditingController(text: 'میزبان');
  final TextEditingController _address = TextEditingController(text: '');
  final TextEditingController _port =
      TextEditingController(text: '8080');
  _LobbyMode _mode = _LobbyMode.host;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _port.text = '${GameController.defaultPort}';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _port.dispose();
    super.dispose();
  }

  String get _invite {
    final SessionState session = ref.read(gameProvider);
    final String host = session.localIp ?? '127.0.0.1';
    final int port = session.port ?? GameController.defaultPort;
    return 'neonbankroll://join?host=$host&port=$port';
  }

  Future<void> _startHosting() async {
    setState(() => _submitting = true);
    await ref.read(gameProvider.notifier).hostGame(_name.text);
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  Future<void> _join({String? rawInvite}) async {
    String host = _address.text.trim();
    int port = int.tryParse(_port.text.trim()) ?? GameController.defaultPort;
    if (rawInvite != null) {
      final ({String host, int port})? parsed = parseInvite(rawInvite);
      if (parsed == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('کد QR معتبر نیست.')),
          );
        }
        return;
      }
      host = parsed.host;
      port = parsed.port;
      _address.text = host;
      _port.text = '$port';
    }
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('آدرس میزبان را وارد کنید.')),
      );
      return;
    }
    setState(() => _submitting = true);
    await ref.read(gameProvider.notifier).joinGame(
          playerName: _name.text,
          host: host,
          port: port,
        );
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  Future<void> _scan() async {
    final String? raw = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext context) => const QrScannerPage(),
      ),
    );
    if (raw != null && raw.isNotEmpty) {
      await _join(rawInvite: raw);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SessionState session = ref.watch(gameProvider);

    ref.listen<SessionState>(gameProvider, (SessionState? prev, SessionState next) {
      if (next.banner != null && next.bannerSeq != prev?.bannerSeq) {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(next.banner!)));
      }
    });

    return Scaffold(
      backgroundColor: NeonColors.bgDeep,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _LobbyBackdrop()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _LobbyTitle(),
                  const SizedBox(height: 18),
                  if (!session.inSession)
                    ..._chooser()
                  else
                    _waitingRoom(session),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _chooser() {
    return <Widget>[
      _ModeSwitcher(
        mode: _mode,
        onChanged: (_LobbyMode mode) => setState(() => _mode = mode),
      ),
      const SizedBox(height: 16),
      GlassPanel(
        accent: _mode == _LobbyMode.host ? NeonColors.cyan : NeonColors.magenta,
        blur: 22,
        glow: 0.22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              style: neonText(size: 14),
              decoration: const InputDecoration(
                labelText: 'نام شما',
                hintText: 'مثلاً آرش',
                prefixIcon: Icon(Icons.person_outline, size: 19),
              ),
            ),
            if (_mode == _LobbyMode.join) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                keyboardType: TextInputType.text,
                textDirection: TextDirection.ltr,
                style: neonText(size: 14),
                decoration: const InputDecoration(
                  labelText: 'آدرس میزبان',
                  hintText: '192.168.1.20',
                  prefixIcon: Icon(Icons.lan_outlined, size: 19),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                style: neonText(size: 14),
                decoration: const InputDecoration(
                  labelText: 'پورت',
                  prefixIcon: Icon(Icons.settings_ethernet, size: 19),
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (_mode == _LobbyMode.host)
              NeonButton(
                label: 'ساخت میز و میزبانی',
                icon: Icons.wifi_tethering,
                color: NeonColors.cyan,
                busy: _submitting,
                height: 52,
                onPressed: _submitting ? null : _startHosting,
              )
            else
              Column(
                children: <Widget>[
                  NeonButton(
                    label: 'اتصال به میز',
                    icon: Icons.login,
                    color: NeonColors.magenta,
                    busy: _submitting,
                    height: 52,
                    onPressed: _submitting ? null : _join,
                  ),
                  const SizedBox(height: 10),
                  NeonButton(
                    label: 'اسکن QR میزبان',
                    icon: Icons.qr_code_scanner,
                    color: NeonColors.violet,
                    filled: false,
                    height: 48,
                    onPressed: _submitting ? null : _scan,
                  ),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _RulesCard(),
    ];
  }

  Widget _waitingRoom(SessionState session) {
    final GameState game = session.game;
    final bool isHost = session.isHost;
    final bool canStart = isHost && game.players.length >= 2;
    final LinkStatus link = session.link;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GlassPanel(
          accent: isHost ? NeonColors.cyan : NeonColors.violet,
          blur: 24,
          glow: 0.26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    isHost ? Icons.wifi_tethering : Icons.link,
                    color: isHost ? NeonColors.cyan : NeonColors.violet,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHost ? 'میز شما آماده است' : 'اتصال به میز',
                      style: glowText(
                        size: 16,
                        color: isHost ? NeonColors.cyan : NeonColors.violet,
                      ),
                    ),
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: link == LinkStatus.connected
                          ? NeonColors.lime
                          : NeonColors.amber,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: (link == LinkStatus.connected
                                  ? NeonColors.lime
                                  : NeonColors.amber)
                              .withValues(alpha: 0.9),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    link.labelFa,
                    style: neonText(size: 10.5, color: NeonColors.textDim),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isHost) ...<Widget>[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: NeonColors.cyan.withValues(alpha: 0.35),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _invite,
                      size: 176,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(6),
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: SelectableText(
                    session.address ?? '-',
                    style: glowText(size: 20, color: NeonColors.lime),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'بازیکنان با اسکن این کد یا وارد کردن آدرس بالا وصل می‌شوند.',
                    textAlign: TextAlign.center,
                    style: neonText(size: 11, color: NeonColors.textDim),
                  ),
                ),
              ] else if (link != LinkStatus.connected) ...<Widget>[
                Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'در حال اتصال به ${session.joinHost ?? "-"}...',
                        style: neonText(
                            size: 12, color: NeonColors.textDim),
                      ),
                    ),
                  ],
                ),
              ] else ...<Widget>[
                Text(
                  'به میز متصل شدید. منتظر شروع بازی توسط میزبان باشید.',
                  style: neonText(size: 12, color: NeonColors.textDim),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Text(
                    'بازیکنان (${game.players.length}/${GameState.maxPlayers})',
                    style: neonText(size: 12.5, weight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (game.players.isEmpty)
                Text(
                  'هنوز کسی در میز نیست.',
                  style: neonText(size: 11.5, color: NeonColors.textDim),
                ),
              ...game.players.map((PlayerModel player) {
                final Color color =
                    Color(PlayerPalette.colorFor(player.colorIndex));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: PlayerChip(
                    name: player.name +
                        (player.id == session.localPlayerId ? ' (شما)' : ''),
                    color: color,
                    subtitle: player.isHost ? 'میزبان' : 'مهمان',
                    trailing: player.connected
                        ? const Icon(Icons.check_circle,
                            size: 15, color: NeonColors.lime)
                        : const Icon(Icons.wifi_off,
                            size: 15, color: NeonColors.danger),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (isHost)
          NeonButton(
            label: canStart
                ? 'شروع بازی با ${game.players.length} بازیکن'
                : 'برای شروع حداقل ۲ بازیکن لازم است',
            icon: Icons.play_circle_outline,
            color: NeonColors.lime,
            height: 54,
            onPressed: canStart ? () => ref.read(gameProvider.notifier).startMatch() : null,
          )
        else
          GlassPanel(
            accent: NeonColors.amber,
            child: Row(
              children: <Widget>[
                const Icon(Icons.hourglass_top,
                    color: NeonColors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'در انتظار میزبان برای شروع بازی...',
                    style: neonText(size: 12, color: NeonColors.textDim),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        NeonButton(
          label: 'انصراف و بازگشت',
          icon: Icons.arrow_back,
          color: NeonColors.danger,
          filled: false,
          height: 46,
          onPressed: () => ref.read(gameProvider.notifier).leaveSession(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------- title

class _LobbyTitle extends StatelessWidget {
  const _LobbyTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.bolt, color: NeonColors.magenta, size: 26),
            const SizedBox(width: 4),
            Text(
              'نئون بانکرول',
              style: glowText(size: 30, color: NeonColors.cyan, blur: 20),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.bolt, color: NeonColors.magenta, size: 26),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: -0.2, end: 0, duration: 600.ms),
        const SizedBox(height: 6),
        Text(
          'بازی تخته‌ای اقتصادی چندنفره — میزبانی محلی بدون اینترنت',
          textAlign: TextAlign.center,
          style: neonText(size: 11.5, color: NeonColors.textDim),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms),
      ],
    );
  }
}

// ------------------------------------------------------------- mode switcher

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.mode, required this.onChanged});

  final _LobbyMode mode;
  final ValueChanged<_LobbyMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _pill(
            label: 'میزبانی',
            icon: Icons.wifi_tethering,
            selected: mode == _LobbyMode.host,
            color: NeonColors.cyan,
            onTap: () => onChanged(_LobbyMode.host),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _pill(
            label: 'ورود به بازی',
            icon: Icons.login,
            selected: mode == _LobbyMode.join,
            color: NeonColors.magenta,
            onTap: () => onChanged(_LobbyMode.join),
          ),
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: selected ? 0.18 : 0.05),
          border: Border.all(
            color: color.withValues(alpha: selected ? 0.8 : 0.2),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: selected ? color : NeonColors.textDim),
            const SizedBox(width: 7),
            Text(
              label,
              style: neonText(
                size: 13,
                weight: FontWeight.w700,
                color: selected ? color : NeonColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ rules card

class _RulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const List<String> rules = <String>[
      '۴۰ خانه، ۲۲ شهر، ۴ ایستگاه حمل‌ونقل و ۲ خدمات شهری',
      'سرمایه اولیه ۵۰۰۰ دلار و ۵۰۰ دلار برای عبور از شروع',
      'اجاره با هر ارتقا به صورت تصاعدی زیاد می‌شود (تا ۳۰ برابر)',
      'رد کردن خرید، حراج عمومی را فعال می‌کند',
      'بازی با ۴۰ دور یا با حذف رقبا تمام می‌شود',
    ];
    return GlassPanel(
      accent: NeonColors.violet,
      blur: 18,
      glow: 0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.menu_book_outlined,
                  size: 17, color: NeonColors.violet),
              const SizedBox(width: 7),
              Text(
                'قوانین سریع',
                style: neonText(size: 13, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rules.map(
            (String rule) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 5, left: 6),
                    child: Icon(Icons.circle,
                        size: 5, color: NeonColors.violet),
                  ),
                  Expanded(
                    child: Text(
                      rule,
                      style: neonText(
                        size: 11,
                        color: NeonColors.textDim,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- backdrop

class _LobbyBackdrop extends StatelessWidget {
  const _LobbyBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.4, -0.8),
          radius: 1.6,
          colors: <Color>[
            Color(0xFF14204A),
            Color(0xFF080C1C),
            NeonColors.bgDeep,
          ],
          stops: <double>[0.0, 0.55, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

// ---------------------------------------------------------------- QR scanner

/// Full screen camera scanner that returns the raw QR payload.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('اسکن QR میزبان', style: neonText(size: 15)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: MobileScanner(
              fit: BoxFit.cover,
              onDetect: (BarcodeCapture capture) {
                if (_handled) {
                  return;
                }
                for (final Barcode barcode in capture.barcodes) {
                  final String? raw = barcode.rawValue;
                  if (raw != null && raw.trim().isNotEmpty) {
                    _handled = true;
                    Navigator.of(context).pop(raw);
                    return;
                  }
                }
              },
              errorBuilder: (
                BuildContext context,
                MobileScannerException error,
              ) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.no_photography_outlined,
                            color: NeonColors.danger, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          'دسترسی به دوربین ممکن نشد.',
                          style: neonText(size: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'می‌توانید آدرس و پورت میزبان را دستی وارد کنید.',
                          textAlign: TextAlign.center,
                          style:
                              neonText(size: 11.5, color: NeonColors.textDim),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ScanFramePainter()),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 42,
            child: Center(
              child: Text(
                'کد QR میزبان را داخل کادر قرار دهید',
                style: neonText(
                  size: 12,
                  color: NeonColors.text,
                  shadows: <Shadow>[
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double side = math.min(size.width, size.height) * 0.62;
    final Rect frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    );

    final Paint scrim = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final Path overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(frame, const Radius.circular(20)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, scrim);

    final Paint border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = const LinearGradient(
        colors: <Color>[
          NeonColors.cyan,
          NeonColors.magenta,
          NeonColors.violet,
        ],
      ).createShader(frame);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(20)),
      border,
    );

    final Paint corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = NeonColors.cyan;
    const double len = 26;
    final List<Offset> corners = <Offset>[
      frame.topLeft,
      frame.topRight,
      frame.bottomLeft,
      frame.bottomRight,
    ];
    for (int i = 0; i < corners.length; i++) {
      final Offset c = corners[i];
      final double sx = i.isEven ? 1 : -1;
      final double sy = i < 2 ? 1 : -1;
      canvas.drawLine(c, c + Offset(len * sx, 0), corner);
      canvas.drawLine(c, c + Offset(0, len * sy), corner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Parses every invite format the game can emit.
({String host, int port})? parseInvite(String raw) {
  final String text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  try {
    if (text.toLowerCase().startsWith('neonbankroll://')) {
      final Uri uri = Uri.parse(text);
      final String? host = uri.queryParameters['host'];
      final int? port = int.tryParse(uri.queryParameters['port'] ?? '');
      if (host != null && host.isNotEmpty) {
        return (host: host, port: port ?? GameController.defaultPort);
      }
    }
    if (text.startsWith('ws://') || text.startsWith('wss://')) {
      final Uri uri = Uri.parse(text);
      if (uri.host.isNotEmpty) {
        return (
          host: uri.host,
          port: uri.hasPort ? uri.port : GameController.defaultPort,
        );
      }
    }
    final RegExp ipOnly = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
    if (ipOnly.hasMatch(text)) {
      return (host: text, port: GameController.defaultPort);
    }
    final List<String> parts = text.split(':');
    if (parts.length == 2) {
      final int? port = int.tryParse(parts[1]);
      if (port != null && parts[0].trim().isNotEmpty) {
        return (host: parts[0].trim(), port: port);
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}

/// Small helper so money is formatted consistently in the lobby too.
String formatLobbyMoney(int value) => formatMoney(value);
