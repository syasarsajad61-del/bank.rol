// [R01][M01][TH15] Persian navigation and game setup.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_state.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/extensions.dart';
import '../../providers/game_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/settings_provider.dart';
import '../../graphics/paper_city.dart';
import '../../graphics/living_avatar.dart';
import '../../graphics/dual_theme.dart';
import '../../graphics/coin_particles.dart';
import '../../graphics/serpentine_board.dart';
import '../widgets/components.dart';
import '../widgets/responsive_game_layout.dart';
import 'game_sheets.dart';
import 'lobbies.dart';
export 'game_sheets.dart';
export 'lobbies.dart';

void openPage(BuildContext c, Widget page) =>
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => page));
Future<void> showGameSheet(BuildContext c, Widget page) =>
    showModalBottomSheet<void>(
      context: c,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (c) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(c).height * .88,
        ),
        child: page,
      ),
    );
void showFailure(BuildContext c, Object e) {
  if (c.mounted) {
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(e is StateError ? e.message.toString() : e.toString()),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? failure;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  Future<void> initialize() async {
    try {
      final settings = context.read<SettingsProvider>(),
          game = context.read<GameProvider>();
      await settings.load();
      await game.initialize();
      game.localId = settings.id;
      game.sound = settings.play;
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      }
    } catch (e) {
      if (mounted) setState(() => failure = e.toString());
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x11FAF6EE), Color(0xFFFAF6EE)],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  'assets/images/app_icon.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'بانک‌رول پلاتو+',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('یک شهر، هزار فرصت'),
                const SizedBox(height: 32),
                if (failure == null)
                  const LinearProgressIndicator()
                else
                  Text(failure!),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final settings = c.watch<SettingsProvider>(),
        game = c.watch<GameProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: LayoutBuilder(
              builder: (c, b) {
                final wide = b.maxWidth > 720;
                final art = ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/menu_bg.png',
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xBBFAF6EE), Color(0x00FAF6EE)],
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 24,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'شهر برای همه جا دارد.',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text('محله‌ات را بساز. فرصتت را پیدا کن.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                final controls = SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/app_icon.png',
                            width: 44,
                            height: 44,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'تنظیمات',
                            onPressed: () =>
                                showGameSheet(c, const SettingsSheet()),
                            icon: const Icon(Icons.tune_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'به زاهدان\nخوش آمدید.',
                        style: TextStyle(
                          fontSize: 36,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'بانک‌رول پلاتو+',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8C701A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ملک بخرید، محله بسازید و در بازار پرماجرای شهر با دوستانتان رقابت کنید.',
                        style: TextStyle(
                          height: 1.9,
                          color: AppColors.mutedOnCream,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ActionButton(
                          label: 'بازی تازه',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => openPage(c, const GameSetupScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (game.hasSaved)
                        SizedBox(
                          width: double.infinity,
                          child: ActionButton(
                            label: 'ادامهٔ بازی',
                            icon: Icons.history_rounded,
                            outlined: true,
                            onPressed: () async {
                              try {
                                await c.read<NetworkProvider>().leave();
                                await game.resume();
                                game.localId = settings.id;
                                if (c.mounted) {
                                  openPage(c, const GameBoardScreen());
                                }
                              } catch (e) {
                                if (c.mounted) showFailure(c, e);
                              }
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              label: 'ساخت اتاق',
                              icon: Icons.wifi_tethering,
                              outlined: true,
                              onPressed: kIsWeb
                                  ? null
                                  : () => openPage(c, const HostLobbyScreen()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ActionButton(
                              label: 'پیوستن',
                              icon: Icons.group_add_outlined,
                              outlined: true,
                              onPressed: kIsWeb
                                  ? null
                                  : () => openPage(c, const JoinLobbyScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 16,
                            color: AppColors.mutedOnCream,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'کاملاً آفلاین • ۲ تا ۶ بازیکن',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedOnCream,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => showGameSheet(c, const RulesSheet()),
                        child: const Text('راهنمای بازی و قوانین'),
                      ),
                    ],
                  ),
                );
                return wide
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(child: controls),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: art,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: b.maxHeight * .25,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: art,
                            ),
                          ),
                          Expanded(child: controls),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});
  @override
  Widget build(BuildContext c) {
    final s = c.watch<SettingsProvider>();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'به سلیقهٔ شما',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        TextFormField(
          initialValue: s.name,
          maxLength: 24,
          decoration: const InputDecoration(labelText: 'نام شما'),
          onChanged: (v) {
            if (v.trim().isNotEmpty) s.save(newName: v.trim());
          },
        ),
        SwitchListTile(
          title: const Text('صدای بازی'),
          value: s.sound,
          onChanged: (v) => s.save(audioEnabled: v),
        ),
        SwitchListTile(
          title: const Text('کاهش حرکت و زوم'),
          value: s.reducedMotion,
          onChanged: (v) => s.save(motion: v),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('ذخیره و بازگشت'),
        ),
      ],
    );
  }
}

class RulesSheet extends StatelessWidget {
  const RulesSheet({super.key});
  @override
  Widget build(BuildContext c) => ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'از اولین ملک تا یک محله',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      const Text(
        'در نوبت خود تاس بریزید. روی ملک بی‌صاحب می‌توانید خرید کنید یا آن را به حراج بگذارید. روی ملک دیگران اجاره می‌پردازید. با کامل کردن بلوک رنگی، اجاره دو برابر می‌شود و می‌توانید تا سه ساختمان بسازید.\n\nشش نوبت اضافه دارد؛ شش سوم شما را به زندان می‌فرستد. زندان سه نوبت است یا با ۱۵۰ دلار آزاد می‌شوید.\n\nهر چهار راند اقتصاد تغییر می‌کند و دربارهٔ قانون و بانک مشترک رأی می‌دهید. حراج ده ثانیه است و پیشنهادها مخفی‌اند.\n\nوام پنج راند مهلت دارد. نکول ۲۰ اعتبار کم می‌کند. بیمه سه راند اعتبار دارد و خسارت و اجارهٔ پرداختی را نصف می‌کند.\n\nقرارداد فقط برای دو طرف دیده می‌شود و باید پذیرفته شود. شکستن قرارداد ۴۰۰ دلار و ۱۵ اعتبار هزینه دارد.\n\nرسیدن به هدف دارایی، باقی ماندن یک بازیکن یا تمام شدن راندها بازی را تمام می‌کند. برنده بیشترین دارایی خالص را دارد.',
        style: TextStyle(height: 2),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.pop(c),
        child: const Text('متوجه شدم'),
      ),
    ],
  );
}

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});
  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int bots = 3, target = 5000, rounds = 30;
  Difficulty difficulty = Difficulty.medium;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('یک بازی تازه')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'شهر را با چه کسانی می‌سازید؟',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'شما به همراه ربات‌های شهر بازی می‌کنید.',
              style: TextStyle(color: AppColors.mutedOnCream),
            ),
            const SizedBox(height: 32),
            PaperCity(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعداد ربات‌ها: ${bots.fa}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: bots.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: bots.fa,
                    onChanged: (v) => setState(() => bots = v.round()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Difficulty>(
                    initialValue: difficulty,
                    decoration: const InputDecoration(
                      labelText: 'مهارت ربات‌ها',
                    ),
                    items: Difficulty.values
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(['آسان', 'متوسط', 'سخت'][d.index]),
                          ),
                        )
                        .toList(),
                    onChanged: (d) => setState(() => difficulty = d!),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    initialValue: target,
                    decoration: const InputDecoration(
                      labelText: 'هدف دارایی خالص',
                    ),
                    items: [3000, 5000, 7000]
                        .map(
                          (n) =>
                              DropdownMenuItem(value: n, child: Text(n.money)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => target = v!),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    initialValue: rounds,
                    decoration: const InputDecoration(labelText: 'سقف راند'),
                    items: [30, 50, 0]
                        .map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text(n == 0 ? 'نامحدود' : n.fa),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => rounds = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ActionButton(
              label: 'بریم توی شهر',
              icon: Icons.arrow_forward_rounded,
              onPressed: () async {
                final settings = c.read<SettingsProvider>(),
                    game = c.read<GameProvider>();
                await c.read<NetworkProvider>().leave();
                game.localId = settings.id;
                game.start(
                  [
                    Player(id: settings.id, name: settings.name, identity: 0),
                    for (int i = 0; i < bots; i++)
                      Player(
                        id: 'bot_$i',
                        name: ['آرمان', 'رها', 'نیما', 'سارا', 'پارسا'][i],
                        identity: i + 1,
                        bot: true,
                        difficulty: difficulty,
                        personality: Personality.values[i % 3],
                      ),
                  ],
                  target: target,
                  rounds: rounds,
                );
                if (c.mounted) {
                  Navigator.pushReplacement(
                    c,
                    MaterialPageRoute(builder: (_) => const GameBoardScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});
  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  bool ended = false;
  String? shownError;
  @override
  Widget build(BuildContext c) {
    final game = c.watch<GameProvider>(),
        settings = c.watch<SettingsProvider>(),
        network = c.watch<NetworkProvider>(),
        s = game.state;
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (s.ended && !ended) {
      ended = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            c,
            MaterialPageRoute(builder: (_) => const EndGameScreen()),
          );
        }
      });
    }
    if (game.error != null && shownError != game.error) {
      shownError = game.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showFailure(c, StateError(game.error!));
      });
    } else if (game.error == null) {
      shownError = null;
    }
    final me = game.me;
    final canAct = game.myTurn && s.auction == null && s.vote == null;
    final own = s.properties.where((q) => q.owner == game.localId).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'محله‌های زاهدان',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'رویدادهای شهر',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => showGameSheet(c, EventSheet(state: s)),
          ),
          IconButton(
            tooltip: 'راهنما',
            icon: const Icon(Icons.help_outline),
            onPressed: () => showGameSheet(c, const RulesSheet()),
          ),
          IconButton(
            tooltip: 'ذخیره و خروج',
            icon: const Icon(Icons.home_outlined),
            onPressed: () async {
              await game.save();
              if (c.mounted) Navigator.pop(c);
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: DualTheme(
          phase: s.phase,
          child: ResponsiveGameLayout(
            children: [
              TopTickerBar(state: s),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    PhaseIndicator(phase: s.phase),
                    const SizedBox(width: 12),
                    Expanded(child: InflationMeter(state: s)),
                    CommonBankPool(amount: s.bank),
                  ],
                ),
              ),
              if (network.reconnecting)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(network.status),
                ),
              Expanded(
                child: CoinParticles(
                  revision: s.revision,
                  child: SerpentineBoard(
                    state: s,
                    viewer: game.localId,
                    reducedMotion: settings.reducedMotion,
                    onSpace: (space) {
                      if (s.pendingMove == game.localId) {
                        game.command('move', {'index': space.index});
                        return;
                      }
                      if (space.propertyId != null) {
                        showGameSheet(
                          c,
                          PropertySheet(propertyId: space.propertyId!),
                        );
                      } else {
                        showGameSheet(
                          c,
                          InfoSheet(
                            title: SpaceWidget.label(space.type),
                            text:
                                'خانه ${space.index.fa}${space.taxAmount == null ? '' : '\nمالیات ${space.taxAmount!.money}'}',
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              if (s.auction != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ActionButton(
                    label: 'حراج ${s.property(s.auction!.propertyId).name}',
                    icon: Icons.gavel_rounded,
                    onPressed: () => showGameSheet(c, const AuctionScreen()),
                  ),
                ),
              if (s.vote != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ActionButton(
                    label: 'شورای شهر • رأی بدهید',
                    icon: Icons.how_to_vote_outlined,
                    onPressed: () => showGameSheet(c, const VoteScreen()),
                  ),
                ),
              if (s.pendingMove == game.localId)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('یک خانهٔ دلخواه روی نقشه انتخاب کنید.'),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: CenterHud(
                  state: s,
                  enabled: game.myTurn,
                  reducedMotion: settings.reducedMotion,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _action(
                      'وام',
                      Icons.account_balance_outlined,
                      () => showGameSheet(c, const LoanScreen()),
                    ),
                    _action(
                      'قراردادها',
                      Icons.handshake_outlined,
                      () => showGameSheet(c, const ContractScreen()),
                    ),
                    _action(
                      'املاک من (${own.fa})',
                      Icons.home_work_outlined,
                      () => showGameSheet(c, AssetsSheet(owner: game.localId)),
                    ),
                    _action(
                      'بیمه',
                      Icons.shield_outlined,
                      canAct && me != null
                          ? () => showGameSheet(c, InsuranceSheet(owner: me.id))
                          : null,
                    ),
                    if (me != null && me.jailTurns > 0)
                      _action(
                        'آزادی ۱۵۰ دلار',
                        Icons.lock_open_outlined,
                        canAct ? () => game.command('bail') : null,
                      ),
                  ],
                ),
              ),
              PathProgressBar(state: s),
              BottomDock(state: s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback? tap) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: TextButton.icon(
      onPressed: tap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    ),
  );
}

class EndGameScreen extends StatelessWidget {
  const EndGameScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final s = c.watch<GameProvider>().state!;
    final ranked = s.players.toList()
      ..sort((a, b) => s.netWorth(b.id).compareTo(s.netWorth(a.id)));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                const SizedBox(height: 32),
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 80,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 24),
                Text(
                  s.winner == null
                      ? 'شهر به استراحت نیاز دارد'
                      : '${s.player(s.winner!).name}، شهر از آن شماست!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.round.fa} راند رقابت در زاهدان',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedOnCream),
                ),
                const SizedBox(height: 32),
                for (int i = 0; i < ranked.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PaperCity(
                      child: Row(
                        children: [
                          Text(
                            (i + 1).fa,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          LivingAvatar(player: ranked[i], active: i == 0),
                          const SizedBox(width: 16),
                          Expanded(child: Text(ranked[i].name)),
                          Text(
                            s.netWorth(ranked[i].id).money,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                ActionButton(
                  label: 'بازگشت به خانه',
                  icon: Icons.home_outlined,
                  onPressed: () async {
                    await c.read<NetworkProvider>().leave();
                    if (c.mounted) Navigator.of(c).popUntil((r) => r.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
