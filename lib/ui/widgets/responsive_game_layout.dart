// [BL12] Landscape keeps the board beside a scrollable control rail.
import 'dart:math';
import 'package:flutter/material.dart';

class ResponsiveGameLayout extends StatelessWidget {
  final List<Widget> children;
  const ResponsiveGameLayout({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, b) {
      final boardIndex = children.indexWhere((w) => w is Expanded);
      if (b.maxWidth > b.maxHeight && b.maxWidth >= 640 && boardIndex >= 0) {
        final board = (children[boardIndex] as Expanded).child;
        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  children.first,
                  Expanded(child: board),
                ],
              ),
            ),
            SizedBox(
              width: 320,
              child: ListView(
                children: [
                  for (int i = 1; i < children.length; i++)
                    if (i != boardIndex) children[i],
                ],
              ),
            ),
          ],
        );
      }
      return SingleChildScrollView(
        child: SizedBox(
          height: max(b.maxHeight, 780),
          child: Column(children: children),
        ),
      );
    },
  );
}
