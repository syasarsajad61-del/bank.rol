// [R25] Two-party property offers with visible taxation.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../widgets/components.dart';

class TradeSheet extends StatefulWidget {
  final String propertyId;
  const TradeSheet({super.key, required this.propertyId});
  @override
  State<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<TradeSheet> {
  String? buyer, requested;
  final price = TextEditingController(text: '0');
  @override
  void dispose() {
    price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final g = c.watch<GameProvider>(),
        s = g.state!,
        q = s.property(widget.propertyId);
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(c).bottom,
      ),
      children: [
        Text(
          'معاملهٔ ${q.name}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'خریدار'),
          items: [
            for (final p in s.alive.where((p) => p.id != g.localId))
              DropdownMenuItem(value: p.id, child: Text(p.name)),
          ],
          onChanged: (v) => setState(() {
            buyer = v;
            requested = null;
          }),
        ),
        const SizedBox(height: 16),
        if (buyer != null)
          DropdownButtonFormField<String>(
            key: ValueKey(buyer),
            decoration: const InputDecoration(
              labelText: 'ملک درخواستی برای معاوضه',
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('بدون ملک جایگزین'),
              ),
              for (final p in s.properties.where(
                (p) => p.owner == buyer && p.buildings == 0,
              ))
                DropdownMenuItem(value: p.id, child: Text(p.name)),
            ],
            onChanged: (v) => setState(() => requested = v == '' ? null : v),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: price,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'مبلغ دریافتی از خریدار',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.laws.contains('law_08')
              ? 'خریدار ۵٪ مجموع ارزش املاک و وجه معامله را به بانک می‌پردازد.'
              : 'مالیات معاوضه در این راند فعال نیست.',
        ),
        const SizedBox(height: 24),
        ActionButton(
          label: 'فرستادن پیشنهاد',
          icon: Icons.swap_horiz,
          onPressed: buyer != null && g.myTurn
              ? () {
                  final amount = double.tryParse(price.text);
                  if (amount != null) {
                    g.command('trade', {
                      'buyer': buyer,
                      'property': q.id,
                      'requested': requested,
                      'price': amount,
                    });
                    Navigator.pop(c);
                  }
                }
              : null,
        ),
      ],
    );
  }
}
