// [G07][AS03][AS17] Transaction coins fly along curved trajectories.
import 'dart:math' as math;
import 'package:flutter/material.dart';

class CoinParticles extends StatefulWidget {
  final int revision;
  final Widget child;
  const CoinParticles({super.key, required this.revision, required this.child});
  @override
  State<CoinParticles> createState() => _CoinParticlesState();
}

class _CoinParticlesState extends State<CoinParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  @override
  void didUpdateWidget(covariant CoinParticles old) {
    super.didUpdateWidget(old);
    if (widget.revision != old.revision) controller.forward(from: 0);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (c, b) => AnimatedBuilder(
              animation: controller,
              builder: (c, w) {
                final t = Curves.easeOutQuad.transform(controller.value);
                return Stack(
                  children: controller.isAnimating
                      ? List.generate(
                          9,
                          (i) => Positioned(
                            left: b.maxWidth * .5 + math.sin(i * 2.4) * t * 120,
                            top:
                                b.maxHeight * .55 -
                                t * 180 +
                                math.sin(t * math.pi) * -60 +
                                i * 4,
                            child: Opacity(
                              opacity: (1 - t).clamp(0, 1),
                              child: Transform.rotate(
                                angle: t * 6 + i.toDouble(),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      alignment: Alignment.centerLeft,
                                      minWidth: 80,
                                      maxWidth: 80,
                                      child: Transform.translate(
                                        offset: Offset(
                                          -((controller.value * 12 + i)
                                                      .floor() %
                                                  4) *
                                              20.0,
                                          0,
                                        ),
                                        child: Image.asset(
                                          'assets/images/coin_fly_strip.png',
                                          width: 80,
                                          height: 20,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : [],
                );
              },
            ),
          ),
        ),
      ),
    ],
  );
}
