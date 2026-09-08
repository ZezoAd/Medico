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

/// A brand-gradient surface that both ripples and scales under a finger.
///
/// **The press half of this was missing everywhere on Home.** The doctor
/// card's "احجز الآن", the visited row's "احجز" and the visited card's footer
/// CTA were each a hand-rolled `DecoratedBox → Material → InkWell` with the
/// same gradient and the same ripple — and no scale, so a tap was acknowledged
/// only by a ripple that the gradient largely swallows. This is that stack
/// written once, with [AuroraPressable]'s press feedback folded in.
///
/// Not a replacement for [AuroraPrimaryButton], which is the 56pt full-width
/// action with its own glow and disabled state. This is the smaller in-card
/// CTA: the caller owns the size, the padding and the label.
///
/// A null [onTap] renders the surface fully styled but inert — the honest
/// state while a flow does not exist yet — and takes the press feedback with
/// it, so a dead control does not pretend to respond.
class AuroraGradientTap extends StatefulWidget {
  const AuroraGradientTap({
    super.key,
    required this.child,
    required this.onTap,
    required this.borderRadius,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  /// Slightly deeper than [AuroraPressable]'s 0.97: these controls are small,
  /// and the same ratio reads as nothing at this size.
  final double pressedScale;

  @override
  State<AuroraGradientTap> createState() => _AuroraGradientTapState();
}

class _AuroraGradientTapState extends State<AuroraGradientTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: AuroraMotion.timed(context, AuroraMotion.press),
      curve: AuroraMotion.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // The in-app two-stop brand ramp. Emphatically not
          // AuroraGradients.authButton — that four-stop ramp belongs to the
          // auth surface, and the two systems are kept apart on purpose.
          gradient: AuroraGradients.aurora,
          borderRadius: widget.borderRadius,
        ),
        // Transparent Material so the ripple clips to the shape and paints
        // over the gradient rather than under it.
        child: Material(
          color: Colors.transparent,
          borderRadius: widget.borderRadius,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius,
            // Tracks the *highlight*, not raw pointer events, so the scale
            // follows the same press/cancel rules the ripple already does —
            // dragging a finger off the control releases both together.
            onHighlightChanged: _setPressed,
            child: widget.child,
          ),
        ),
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
