// [G08] A gently fanned hand of owned property cards.
import 'package:flutter/material.dart';
import '../core/models/game_state.dart';
import '../ui/widgets/components.dart';

class CardDashboard extends StatelessWidget {
  final GameState state;
  final String owner;
  final void Function(Property) onProperty;
  const CardDashboard({
    super.key,
    required this.state,
    required this.owner,
    required this.onProperty,
  });
  @override
  Widget build(BuildContext c) {
    final cards = state.properties.where((q) => q.owner == owner).toList();
    if (cards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'با خرید اولین ملک، مجموعهٔ محله‌های شما اینجا شکل می‌گیرد.',
          style: TextStyle(fontSize: 12),
        ),
      );
    }
    return SizedBox(
      height: 152,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: cards.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (c, i) => Transform.rotate(
          angle: (i % 3 - 1) * .025,
          child: PropertyCard(
            property: cards[i],
            state: state,
            onTap: () => onProperty(cards[i]),
          ),
        ),
      ),
    );
  }
}
