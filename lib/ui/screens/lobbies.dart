// [M02-M06] Local network hosting and room discovery.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/extensions.dart';
import '../../graphics/paper_city.dart';
import '../widgets/components.dart';
import 'screens.dart';

class HostLobbyScreen extends StatefulWidget {
  const HostLobbyScreen({super.key});
  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  int bots = 0, port = 7823;
  bool loading = false;
  String? hotspotInfo;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => create());
  }

  Future<void> create() async {
    setState(() => loading = true);
    try {
      final s = context.read<SettingsProvider>();
      await context.read<NetworkProvider>().create(
        s.id,
        s.name,
        selectedPort: port,
      );
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) {
    final n = c.watch<NetworkProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('اتاق دوستان')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'همه در یک محله',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'به یک وای‌فای یا هات‌اسپات وصل شوید و کد را به دوستانتان بدهید.',
                style: TextStyle(height: 1.8, color: AppColors.mutedOnCream),
              ),
              const SizedBox(height: 24),
              if (loading) const LinearProgressIndicator(),
              if (n.isHost)
                PaperCity(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'کد خصوصی اتاق',
                        style: TextStyle(color: AppColors.mutedOnCream),
                      ),
                      SelectableText(
                        n.pin,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                      SelectableText(
                        '${n.address}:${n.port}',
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: 8),
                      Text(n.status),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final result = await n.startHotspot();
                    if (mounted) {
                      setState(
                        () => hotspotInfo =
                            'نام شبکه: ${result['ssid']}\nگذرواژه: ${result['passphrase']}',
                      );
                    }
                  } catch (e) {
                    if (c.mounted) showFailure(c, e);
                  }
                },
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('ساخت هات‌اسپات محلی'),
              ),
              if (hotspotInfo != null) SelectableText(hotspotInfo!),
              const SizedBox(height: 16),
              for (final p in n.roster)
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(p['name']),
                  trailing: Text(
                    p['id'] == n.id
                        ? 'میزبان'
                        : p['connected']
                        ? 'متصل'
                        : 'قطع شده',
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: bots,
                decoration: const InputDecoration(labelText: 'ربات‌های تکمیلی'),
                items: List.generate(
                  6,
                  (i) => DropdownMenuItem(value: i, child: Text(i.fa)),
                ),
                onChanged: (v) => setState(() => bots = v!),
              ),
              const SizedBox(height: 24),
              ActionButton(
                label: 'شروع بازی',
                icon: Icons.play_arrow_rounded,
                onPressed: loading
                    ? null
                    : () async {
                        try {
                          await n.begin(bots: bots);
                          if (c.mounted) {
                            Navigator.pushReplacement(
                              c,
                              MaterialPageRoute(
                                builder: (_) => const GameBoardScreen(),
                              ),
                            );
                          }
                        } catch (e) {
                          if (c.mounted) showFailure(c, e);
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '7823',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'پورت اتاق'),
                onChanged: (v) => port = int.tryParse(v) ?? 7823,
              ),
              TextButton(
                onPressed: loading ? null : create,
                child: const Text('بازسازی اتاق با پورت جدید'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JoinLobbyScreen extends StatefulWidget {
  const JoinLobbyScreen({super.key});
  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  final address = TextEditingController(),
      pin = TextEditingController(),
      port = TextEditingController(text: '7823');
  bool loading = false, opened = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<NetworkProvider>().search();
      } catch (e) {
        if (mounted) showFailure(context, e);
      }
    });
  }

  @override
  void dispose() {
    address.dispose();
    pin.dispose();
    port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final n = c.watch<NetworkProvider>(), g = c.watch<GameProvider>();
    if (n.connected && g.state != null && !opened) {
      opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            c,
            MaterialPageRoute(builder: (_) => const GameBoardScreen()),
          );
        }
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('پیوستن به دوستان')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'اتاق دوستانتان کجاست؟',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              for (final room in n.rooms)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.wifi_outlined),
                    title: Text(room.name),
                    subtitle: Text(
                      '${room.address}:${room.port}',
                      textDirection: TextDirection.ltr,
                    ),
                    trailing: Text('${room.players.fa}/۶'),
                    onTap: () {
                      address.text = room.address;
                      port.text = room.port.toString();
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: address,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'نشانی میزبان',
                  hintText: '192.168.1.10',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'پورت'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'کد خصوصی اتاق'),
              ),
              const SizedBox(height: 24),
              ActionButton(
                label: loading ? 'در حال اتصال' : 'وصل شو',
                icon: Icons.login_rounded,
                onPressed: loading || n.connected
                    ? null
                    : () async {
                        setState(() => loading = true);
                        try {
                          final s = c.read<SettingsProvider>();
                          await n.join(
                            s.id,
                            s.name,
                            address.text.trim(),
                            pin.text.trim(),
                            selectedPort: int.tryParse(port.text) ?? 7823,
                          );
                        } catch (e) {
                          if (c.mounted) showFailure(c, e);
                        }
                        if (mounted) setState(() => loading = false);
                      },
              ),
              const SizedBox(height: 16),
              Text(n.status),
              if (n.connected)
                const Text(
                  'منتظر شروع بازی توسط میزبان باشید.',
                  style: TextStyle(height: 2),
                ),
              TextButton(
                onPressed: () =>
                    n.search(selectedPort: int.tryParse(port.text) ?? 7823),
                child: const Text('جست‌وجوی دوبارهٔ شبکه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
