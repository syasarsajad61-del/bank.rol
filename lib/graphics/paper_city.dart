// [G02][TH02] Textured cards unfold on entry.
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/shadows.dart';

class PaperCity extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final bool fold;
  final bool propertyFrame;
  const PaperCity({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.fold = true,
    this.propertyFrame = false,
  });
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: fold ? 0.92 : 1, end: 1),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
    builder: (c, t, w) => Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, .001)
        ..rotateX((1 - t) * 1.5),
      alignment: Alignment.topCenter,
      child: Opacity(opacity: t, child: w),
    ),
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppShadows.small],
        image: DecorationImage(
          image: AssetImage(
            propertyFrame
                ? 'assets/images/property_card_frame.png'
                : 'assets/images/paper_texture.png',
          ),
          opacity: propertyFrame ? .45 : .08,
          fit: propertyFrame ? BoxFit.fill : BoxFit.cover,
        ),
      ),
      child: child,
    ),
  );
}
