import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A blurred glassmorphism surface with a neon rim.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.blur = 18,
    this.radius = 20,
    this.accent = NeonColors.cyan,
    this.tint = NeonColors.glassTint,
    this.borderOpacity = 0.28,
    this.onTap,
    this.width,
    this.height,
    this.glow = 0.18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blur;
  final double radius;
  final Color accent;
  final Color tint;
  final double borderOpacity;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(tint, NeonColors.panel.withValues(alpha: 0.55)),
            NeonColors.panel.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: borderOpacity),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: glow),
            blurRadius: 26,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: onTap == null
              ? content
              : GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: content,
                ),
        ),
      ),
    );
  }
}

/// Glowing neon button with a gradient fill and press animation.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = NeonColors.cyan,
    this.expanded = true,
    this.height = 50,
    this.busy = false,
    this.fontSize = 15,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool expanded;
  final double height;
  final bool busy;
  final double fontSize;
  final bool filled;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.busy;
    final Color color = enabled ? widget.color : NeonColors.textDim;
    final Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.busy)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 19, color: color),
        if (widget.busy || widget.icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: neonText(
              size: widget.fontSize,
              weight: FontWeight.w800,
              color: enabled ? color : NeonColors.textDim,
            ),
          ),
        ),
      ],
    );

    final Widget body = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: widget.filled && enabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  color.withValues(alpha: _down ? 0.34 : 0.22),
                  color.withValues(alpha: _down ? 0.18 : 0.08),
                ],
              )
            : null,
        border: Border.all(
          color: color.withValues(alpha: enabled ? 0.75 : 0.25),
          width: 1.4,
        ),
        boxShadow: enabled
            ? <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: _down ? 0.45 : 0.28),
                  blurRadius: _down ? 22 : 14,
                  spreadRadius: _down ? 3 : 0,
                ),
              ]
            : null,
      ),
      child: label,
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed?.call();
            }
          : null,
      child: widget.expanded
          ? SizedBox(width: double.infinity, child: body)
          : body,
    );
  }
}

/// Small colour chip used for a player identity.
class PlayerChip extends StatelessWidget {
  const PlayerChip({
    super.key,
    required this.name,
    required this.color,
    this.subtitle,
    this.active = false,
    this.dimmed = false,
    this.trailing,
  });

  final String name;
  final Color color;
  final String? subtitle;
  final bool active;
  final bool dimmed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final double opacity = dimmed ? 0.42 : 1.0;
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: NeonColors.panel.withValues(alpha: 0.62),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.9)
                : color.withValues(alpha: 0.28),
            width: active ? 1.8 : 1.0,
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.85),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: neonText(size: 13, weight: FontWeight.w700),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: neonText(size: 10.5, color: NeonColors.textDim),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Animated scan-line divider that sells the "cyberpunk terminal" look.
class NeonDivider extends StatelessWidget {
  const NeonDivider({super.key, this.color = NeonColors.cyan, this.height = 1});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.7),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
