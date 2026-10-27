// [R13][R14][R20-R26] Property management and economic action sheets.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/game_state.dart';
import '../../core/data/properties_data.dart';
import '../../core/data/laws_data.dart';
import '../../core/data/chance_cards_data.dart';
import '../../core/rules/rent_calculator.dart';
import '../../core/rules/insurance_engine.dart';
import '../../core/rules/credit_system.dart';
import '../../core/rules/phase_engine.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/extensions.dart';
import '../../providers/game_provider.dart';
import '../../graphics/paper_city.dart';
import '../../graphics/card_dashboard.dart';
import '../widgets/components.dart';
import 'screens.dart';
import 'trade_sheet.dart';

class InfoSheet extends StatelessWidget {
  final String title, text;
  const InfoSheet({super.key, required this.title, required this.text});
  @override
  Widget build(BuildContext c) => ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      Text(text, style: const TextStyle(height: 2)),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.pop(c),
        child: const Text('بازگشت'),
      ),
    ],
  );
}

class EventSheet extends StatelessWidget {
  final GameState state;
  const EventSheet({super.key, required this.state});
  @override
  Widget build(BuildContext c) => ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'خبرهای شهر',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      for (final id in state.laws)
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: Text(LAWS.firstWhere((l) => l.id == id).title),
          subtitle: Text(LAWS.firstWhere((l) => l.id == id).description),
        ),
      if (state.lastChance != null)
        PaperCity(
          child: Text(
            CHANCE_CARDS
                .firstWhere((v) => v.id == state.lastChance)
                .description,
          ),
        ),
      for (final line in state.log.reversed)
        ListTile(
          dense: true,
          leading: const Icon(Icons.circle, size: 8, color: AppColors.gold),
          title: Text(line, style: const TextStyle(fontSize: 12)),
        ),
    ],
  );
}

class AssetsSheet extends StatelessWidget {
  final String owner;
  const AssetsSheet({super.key, required this.owner});
  @override
  Widget build(BuildContext c) {
    final s = c.watch<GameProvider>().state!;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'یک تکه از شهر برای شما',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        CardDashboard(
          state: s,
          owner: owner,
          onProperty: (q) => showGameSheet(c, PropertySheet(propertyId: q.id)),
        ),
        const SizedBox(height: 24),
        Text('دارایی خالص: ${s.netWorth(owner).money}'),
        for (final offer in s.trades.where((t) => t['buyer'] == owner))
          PaperCity(
            child: Column(
              children: [
                Text(
                  'پیشنهاد ${s.player(offer['seller']).name}: ${s.property(offer['property']).name} به مبلغ ${(offer['price'] as num).money}',
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => c.read<GameProvider>().command(
                        'acceptTrade',
                        {'trade': offer['id']},
                      ),
                      child: const Text('پذیرش معامله'),
                    ),
                    TextButton(
                      onPressed: () => c.read<GameProvider>().command(
                        'rejectTrade',
                        {'trade': offer['id']},
                      ),
                      child: const Text('رد کردن'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'بلوک کامل، اجاره را دو برابر می‌کند. برای ساخت‌وساز یک کارت را انتخاب کنید.',
          style: TextStyle(height: 1.8, color: AppColors.mutedOnCream),
        ),
      ],
    );
  }
}

class PropertySheet extends StatelessWidget {
  final String propertyId;
  const PropertySheet({super.key, required this.propertyId});
  @override
  Widget build(BuildContext c) {
    final g = c.watch<GameProvider>(),
        s = g.state!,
        q = s.property(propertyId),
        me = g.me;
    final owned = q.owner == g.localId,
        can = g.myTurn && s.auction == null && s.vote == null;
    final here = BOARD[s.active.position].propertyId == q.id && s.rolled;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Image.asset(
            'assets/images/building_l${q.buildings.clamp(1, 3)}.png',
            height: 120,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          q.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          q.owner == null
              ? 'هنوز صاحب ندارد'
              : 'مالک: ${s.player(q.owner!).name}',
          style: const TextStyle(color: AppColors.mutedOnCream),
        ),
        const SizedBox(height: 24),
        PaperCity(
          child: Column(
            children: [
              _value('ارزش روز', RentCalculator.value(s, q).money),
              _value(
                'اجاره',
                me == null ? '—' : RentCalculator.of(s, q, me).money,
              ),
              _value('ساختمان', q.buildings.fa),
              if (!q.isPublic)
                _value('هزینهٔ ساخت', RentCalculator.buildingPrice(s, q).money),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (q.owner == null && here)
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'خرید ملک',
                  icon: Icons.add_home_outlined,
                  onPressed: can ? () => g.command('buy') : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionButton(
                  label: 'حراج',
                  icon: Icons.gavel_outlined,
                  outlined: true,
                  onPressed: can
                      ? () {
                          g.command('auction');
                          Navigator.pop(c);
                          showGameSheet(c, const AuctionScreen());
                        }
                      : null,
                ),
              ),
            ],
          ),
        if (owned)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionButton(
                label: 'ساخت‌وساز',
                icon: Icons.construction_outlined,
                onPressed:
                    can &&
                        RentCalculator.fullBlock(s, q) &&
                        q.buildings < (s.laws.contains('law_07') ? 2 : 3)
                    ? () => g.command('build', {'property': q.id})
                    : null,
              ),
              ActionButton(
                label: 'فروش ساختمان',
                icon: Icons.remove_circle_outline,
                outlined: true,
                onPressed: can && q.buildings > 0
                    ? () => g.command('sellBuilding', {'property': q.id})
                    : null,
              ),
              ActionButton(
                label: 'فروش ملک',
                icon: Icons.sell_outlined,
                outlined: true,
                onPressed: can
                    ? () => g.command('sell', {'property': q.id})
                    : null,
              ),
              ActionButton(
                label: 'پیشنهاد معامله',
                icon: Icons.swap_horiz_outlined,
                outlined: true,
                onPressed: can && q.buildings == 0
                    ? () => showGameSheet(c, TradeSheet(propertyId: q.id))
                    : null,
              ),
            ],
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('بازگشت'),
        ),
      ],
    );
  }

  Widget _value(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(a, style: const TextStyle(color: AppColors.mutedOnCream)),
        const Spacer(),
        Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});
  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  final amount = TextEditingController();
  bool sent = false;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final g = c.watch<GameProvider>(), s = g.state!, a = s.auction, me = g.me;
    if (a == null) {
      return const InfoSheet(
        title: 'حراج پایان یافت',
        text: 'نتیجه در رویدادهای شهر ثبت شده است.',
      );
    }
    final q = s.property(a.propertyId);
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(c).bottom,
      ),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'یک پیشنهاد، یک فرصت',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            TimerWidget(deadline: a.deadline),
          ],
        ),
        const SizedBox(height: 16),
        Center(child: Image.asset('assets/images/card_back.png', height: 96)),
        Text(
          q.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'ارزش روز ${RentCalculator.value(s, q).money} • پیشنهادها تا پایان مخفی می‌مانند.',
          style: const TextStyle(color: AppColors.mutedOnCream, height: 1.8),
        ),
        const SizedBox(height: 24),
        BidInput(controller: amount, max: me?.cash ?? 0),
        for (final entry in a.bids.entries.where(
          (e) =>
              e.key != g.localId && s.visibleBidders(g.localId).contains(e.key),
        ))
          Text(
            'خبرچین: پیشنهاد ${s.player(entry.key).name} برابر ${entry.value.money} است',
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(height: 16),
        ActionButton(
          label: sent ? 'پیشنهاد تازه بفرست' : 'ارسال پیشنهاد مخفی',
          icon: Icons.lock_outline,
          onPressed: me == null || me.eliminated
              ? null
              : () {
                  final bid = double.tryParse(amount.text);
                  if (bid == null) {
                    showFailure(c, StateError('یک مبلغ معتبر وارد کنید'));
                    return;
                  }
                  g.command('bid', {'amount': bid});
                  setState(() => sent = true);
                },
        ),
        if (sent)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'پیشنهاد ارسال شد؛ منتظر پایان حراج باشید.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        const Text(
          '۱۰٪ مبلغ برنده به بانک و ۵٪ به آغازکنندهٔ حراج می‌رسد.',
          style: TextStyle(fontSize: 12, color: AppColors.mutedOnCream),
        ),
      ],
    );
  }
}

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final g = c.watch<GameProvider>(), v = g.state!.vote;
    if (v == null) {
      return const InfoSheet(
        title: 'شورا پایان یافت',
        text: 'نتیجه در رویدادهای شهر ثبت شده است.',
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                v.stage == 0
                    ? 'کدام پیشنهاد حذف شود؟'
                    : 'کدام قانون تصویب شود؟',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TimerWidget(deadline: v.deadline),
          ],
        ),
        const SizedBox(height: 16),
        for (final id in v.candidates)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaperCity(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LAWS.firstWhere((l) => l.id == id).title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(LAWS.firstWhere((l) => l.id == id).description),
                  const SizedBox(height: 12),
                  if (v.stage == 0)
                    OutlinedButton(
                      onPressed: () => g.command('vote', {'law': id}),
                      child: Text(
                        v.elimination[g.localId] == id
                            ? 'رأی شما: حذف'
                            : 'حذف این پیشنهاد',
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final bank in BankChoice.values)
                          OutlinedButton(
                            onPressed: () => g.command('vote', {
                              'law': id,
                              'bank': bank.name,
                            }),
                            child: Text(
                              '${['وام گروهی', 'تقسیم بانک', 'ذخیره'][bank.index]}${v.ballots[g.localId] == id && v.bankBallots[g.localId] == bank.name ? ' ✓' : ''}',
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        const Text(
          'قانون با رأی بیش از نصف بازیکنان تصویب می‌شود. تساوی بی‌اثر است.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedOnCream,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});
  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final amount = TextEditingController(text: '200');
  String? collateral, guarantor;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final g = c.watch<GameProvider>(), s = g.state!, p = g.me;
    if (p == null) return const SizedBox.shrink();
    final own = s.properties.where((q) => q.owner == p.id).toList();
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(c).bottom,
      ),
      children: [
        const Text(
          'یک فرصت برای رشد',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        PaperCity(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اعتبار شما ${p.credit.fa} از ۱۰۰',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: p.credit / 100),
              const SizedBox(height: 16),
              Text('سقف وام: ${CreditSystem.limit(p.credit).money}'),
              Text(
                'بهرهٔ این فاز: ${(PhaseEngine.interest(s.phase) * 100).fa}٪ • سررسید: ۵ راند',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (final l in s.loans.where((l) => l.borrower == p.id && !l.settled))
          ListTile(
            title: Text('بدهی ${l.due.money}'),
            subtitle: Text('سررسید راند ${l.dueRound.fa}'),
            trailing: TextButton(
              onPressed: g.myTurn && !l.pending
                  ? () => g.command('repay', {'loan': l.id})
                  : null,
              child: const Text('تسویه'),
            ),
          ),
        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'مبلغ وام'),
        ),
        for (final l in s.loans.where(
          (l) => l.pending && !l.settled && l.guarantor == p.id,
        ))
          PaperCity(
            child: Column(
              children: [
                Text(
                  'ضمانت وام ${s.player(l.borrower).name} به مبلغ ${l.due.money} را می‌پذیرید؟',
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          g.command('acceptGuarantee', {'loan': l.id}),
                      child: const Text('پذیرش ضمانت'),
                    ),
                    TextButton(
                      onPressed: () =>
                          g.command('rejectGuarantee', {'loan': l.id}),
                      child: const Text('رد درخواست'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'ضامن اختیاری (با پذیرش او)',
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('بدون ضامن')),
            for (final other in s.alive.where((o) => o.id != p.id))
              DropdownMenuItem(value: other.id, child: Text(other.name)),
          ],
          onChanged: (v) => setState(() => guarantor = v == '' ? null : v),
        ),
        if (own.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'وثیقه (برای اعتبار زیر ۵۰)',
              ),
              items: own
                  .map(
                    (q) => DropdownMenuItem(value: q.id, child: Text(q.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => collateral = v),
            ),
          ),
        const SizedBox(height: 24),
        ActionButton(
          label: 'دریافت وام',
          icon: Icons.account_balance_outlined,
          onPressed: g.myTurn
              ? () {
                  final value = double.tryParse(amount.text);
                  if (value != null) {
                    g.command('loan', {
                      'amount': value,
                      'collateral': collateral,
                      'guarantor': guarantor,
                    });
                  }
                }
              : null,
        ),
        const SizedBox(height: 16),
        const Text(
          'تسویه به‌موقع: ۲ اعتبار بیشتر. نکول: ۲۰ اعتبار کمتر و ضبط وثیقه.',
          style: TextStyle(
            color: AppColors.mutedOnCream,
            fontSize: 12,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

class ContractScreen extends StatefulWidget {
  const ContractScreen({super.key});
  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  String? second;
  ContractKind kind = ContractKind.nonAggression;
  static const kinds = ['عدم تعرض', 'تقسیم اجاره', 'خبرچین'];
  @override
  Widget build(BuildContext c) {
    final g = c.watch<GameProvider>(), s = g.state!, p = g.me;
    if (p == null) return const SizedBox.shrink();
    final contracts = s.contracts
        .where((x) => x.includes(p.id) && x.expires > s.round && !x.broken)
        .toList();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'بین خودمان بماند',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            Image.asset('assets/images/contract_seal.png', width: 48),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'قرارداد فقط برای دو طرف و میزبان قابل مشاهده است.',
          style: TextStyle(color: AppColors.mutedOnCream, fontSize: 12),
        ),
        const SizedBox(height: 24),
        for (final x in contracts)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaperCity(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${kinds[x.kind.index]} با ${s.player(x.other(p.id)).name}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'تا راند ${x.expires.fa} • ${x.accepted ? 'فعال' : 'منتظر پذیرش'}',
                  ),
                  if (!x.accepted && x.second == p.id)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () =>
                              g.command('acceptContract', {'contract': x.id}),
                          child: const Text('پذیرش'),
                        ),
                        TextButton(
                          onPressed: () =>
                              g.command('rejectContract', {'contract': x.id}),
                          child: const Text('رد کردن'),
                        ),
                      ],
                    ),
                  if (x.accepted)
                    TextButton(
                      onPressed: g.myTurn
                          ? () => g.command('breakContract', {'contract': x.id})
                          : null,
                      child: const Text('شکستن: ۴۰۰ دلار + ۱۵ اعتبار'),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'طرف قرارداد'),
          items: s.alive
              .where((o) => o.id != p.id)
              .map((o) => DropdownMenuItem(value: o.id, child: Text(o.name)))
              .toList(),
          onChanged: (v) => setState(() => second = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ContractKind>(
          initialValue: kind,
          decoration: const InputDecoration(labelText: 'نوع قرارداد'),
          items: ContractKind.values
              .map(
                (v) => DropdownMenuItem(value: v, child: Text(kinds[v.index])),
              )
              .toList(),
          onChanged: (v) => setState(() => kind = v!),
        ),
        const SizedBox(height: 24),
        ActionButton(
          label: 'پیشنهاد محرمانه',
          icon: Icons.handshake_outlined,
          onPressed: g.myTurn && second != null
              ? () =>
                    g.command('contract', {'second': second, 'kind': kind.name})
              : null,
        ),
        const SizedBox(height: 16),
        const Text(
          'عدم تعرض: اجاره بین دو طرف صفر. تقسیم اجاره: ۲۵٪ اجاره‌های دریافتی شریک می‌شود. خبرچین: پیشنهاد حراج شریک را می‌بینید.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedOnCream,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

class InsuranceSheet extends StatelessWidget {
  final String owner;
  const InsuranceSheet({super.key, required this.owner});
  @override
  Widget build(BuildContext c) {
    final g = c.watch<GameProvider>(), s = g.state!, p = s.player(owner);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.shield_outlined, size: 64, color: AppColors.navy),
        const SizedBox(height: 16),
        const Text(
          'خیالتان کمی آسوده‌تر',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Text(
          'حق بیمه ${InsuranceEngine.premium(s, p).money}\nسه راند اعتبار • کاهش ۵۰٪ اجاره و خسارت\nحداکثر دو بیمه؛ تخفیف‌ها روی هم جمع نمی‌شوند.',
          style: const TextStyle(height: 2),
        ),
        for (final i in s.policies.where(
          (i) => i.owner == p.id && i.expires > s.round,
        ))
          ListTile(title: Text('بیمهٔ فعال تا راند ${i.expires.fa}')),
        const SizedBox(height: 24),
        ActionButton(
          label: 'خرید بیمه',
          icon: Icons.verified_user_outlined,
          onPressed: g.myTurn ? () => g.command('insurance') : null,
        ),
      ],
    );
  }
}
