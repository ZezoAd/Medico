/// The shared Aurora control set.
///
/// The auth screens each grew their own private copies of these; that is the
/// pattern this file exists to stop. Anything new builds on these rather than
/// pasting another `_GradientButton` into a screen file.
library;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';

/// Wraps a child in the shared press feedback: a short scale-down on touch,
/// released on lift or cancel. Every interactive surface in the design gets
/// this — it is the whole reason taps feel acknowledged before the
/// navigation animation starts.
class AuroraPressable extends StatefulWidget {
  const AuroraPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
  });

  final Widget child;

  /// A null callback disables both the tap and the press feedback.
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<AuroraPressable> createState() => _AuroraPressableState();
}

class _AuroraPressableState extends State<AuroraPressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: AuroraMotion.press,
        curve: AuroraMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 56px gradient pill-ish primary action. Falls back to a flat disabled fill
/// — and drops its glow — when [onTap] is null.
class AuroraPrimaryButton extends StatelessWidget {
  const AuroraPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return AuroraPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        // Explicit, because the Stack below sizes to its largest child rather
        // than filling the way the Row it replaced did — without this the
        // button shrinks to the width of its label.
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: enabled ? AuroraGradients.aurora : null,
          color: enabled ? null : AuroraColors.divider,
          borderRadius: BorderRadius.circular(AuroraRadius.md),
          boxShadow: enabled ? AuroraShadows.lift : null,
        ),
        // The icon is pinned to the leading edge rather than riding beside
        // the label, so the label stays optically centred in the button
        // instead of being pushed off-centre by the glyph's width.
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              label,
              style: AuroraText.body(
                size: AuroraFontSize.bodyLg,
                weight: FontWeight.w700,
                color: enabled ? Colors.white : AuroraColors.disabledInk,
              ),
            ),
            if (icon != null)
              PositionedDirectional(
                start: AuroraSpacing.xl,
                top: 0,
                bottom: 0,
                child: Icon(
                  icon,
                  size: 18,
                  color: enabled ? Colors.white : AuroraColors.disabledInk,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Text-only tertiary action — no fill, no border. This is the skip
/// treatment on every optional step; the outlined variant that used to sit
/// beside the primary button competed with it for the same decision.
class AuroraSecondaryButton extends StatelessWidget {
  const AuroraSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AuroraPressable(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Center(
          child: Text(
            label,
            style: AuroraText.body(
              size: AuroraFontSize.body,
              weight: FontWeight.w700,
              color: AuroraColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 40px tonal circle holding a single glyph — the back affordance.
class AuroraIconButton extends StatelessWidget {
  const AuroraIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: AuroraPressable(
        onTap: onTap,
        pressedScale: 0.92,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AuroraColors.tonal,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AuroraColors.ink),
        ),
      ),
    );
  }
}

/// One consistent heading treatment for a labelled block within a step.
class AuroraSectionTitle extends StatelessWidget {
  const AuroraSectionTitle({super.key, required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AuroraText.display(size: AuroraFontSize.h3),
          textAlign: TextAlign.start,
        ),
        if (hint != null) ...[
          const SizedBox(height: AuroraSpacing.xs),
          Text(
            hint!,
            style: AuroraText.body(
              size: AuroraFontSize.caption,
              color: AuroraColors.muted,
              height: 1.55,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ],
    );
  }
}
