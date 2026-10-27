// [G06][AS14] Generated sunny neighborhood behind the board.
import 'package:flutter/material.dart';

class NeighborhoodBackground extends StatelessWidget {
  const NeighborhoodBackground({super.key});
  @override
  Widget build(BuildContext c) => Image.asset(
    'assets/images/board_bg.png',
    fit: BoxFit.cover,
    opacity: const AlwaysStoppedAnimation(.32),
  );
}
