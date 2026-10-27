// [G10][BL09] Smooth event focus with manual pan and zoom.
import 'package:flutter/material.dart';
import 'dart:math' as math;

class DirectorCamera extends StatefulWidget {
  final Widget child;
  final Offset focus;
  final Object event;
  final bool reducedMotion;
  final Object? overviewEvent;
  const DirectorCamera({
    super.key,
    required this.child,
    required this.focus,
    required this.event,
    this.reducedMotion = false,
    this.overviewEvent,
  });
  @override
  State<DirectorCamera> createState() => _DirectorCameraState();
}

class _DirectorCameraState extends State<DirectorCamera>
    with SingleTickerProviderStateMixin {
  final TransformationController transform = TransformationController();
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  Animation<Matrix4>? tween;
  Size viewport = Size.zero;
  @override
  void initState() {
    super.initState();
    motion.addListener(() {
      if (tween != null) transform.value = tween!.value;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) focus(overview: true); });
  }

  void focus({bool overview = false}) {
    if (viewport == Size.zero) return;
    final canvas = widget.child is SizedBox ? widget.child as SizedBox : null;
    final canvasWidth = canvas?.width ?? viewport.width;
    final canvasHeight = canvas?.height ?? viewport.height;
    final scale = overview
        ? math.min(viewport.width / canvasWidth, viewport.height / canvasHeight) * .94
        : widget.reducedMotion ? 1.0 : 1.5;
    final target = overview ? Offset(canvasWidth / 2, canvasHeight / 2) : widget.focus;
    final matrix = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - target.dx * scale,
        viewport.height / 2 - target.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    if (widget.reducedMotion) {
      transform.value = matrix;
      return;
    }
    tween = Matrix4Tween(
      begin: transform.value,
      end: matrix,
    ).animate(CurvedAnimation(parent: motion, curve: Curves.easeInOutCubic));
    motion.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant DirectorCamera old) {
    super.didUpdateWidget(old);
    if (old.overviewEvent != widget.overviewEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) focus(overview: true); });
    } else if (old.event != widget.event) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) focus(); });
    }
  }

  @override
  void dispose() {
    transform.dispose();
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => LayoutBuilder(
    builder: (c, b) {
      viewport = Size(b.maxWidth, b.maxHeight);
      return Stack(children: [Positioned.fill(child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(480),
        minScale: .1,
        maxScale: 2.5,
        transformationController: transform,
        onInteractionStart: (_) => motion.stop(),
        child: widget.child,
      )), Positioned(top: 8, left: 8, child: Material(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(tooltip: 'نمای کامل مسیر', onPressed: () => focus(overview: true), icon: const Icon(Icons.fit_screen_outlined)),
          IconButton(tooltip: 'بازیکن فعال', onPressed: () => focus(), icon: const Icon(Icons.my_location_outlined)),
        ]),
      ))]);
    },
  );
}
