/// The persistent onboarding shell header.
library;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import 'onboarding_milestone_stepper.dart';

/// Sits above the page area and never travels with the page transition —
/// only the stepper fill animates while the steps slide underneath. On the
/// way to the completion screen it collapses its height to zero rather than
/// merely hiding, so the final screen gets the whole viewport.
///
/// There is no back affordance: navigation is forward-only, so the header
/// carries the brand mark and progress, nothing else.
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.step,
    required this.visible,
  });

  final int step;
  final bool visible;

  static const double _topPadding = AuroraSpacing.xxl;
  static const double _markHeight = 30;
  static const double _markGap = 18;

  /// No bottom padding: the steps own the gap below the stepper so that
  /// "36dp from stepper to content" means exactly that, rather than 36 plus
  /// whatever the header happened to add.
  static const double _height =
      _topPadding + _markHeight + _markGap + OnboardingMilestoneStepper.height;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      // heightFactor rather than an animated height: the content keeps its
      // full layout the whole way down, so collapsing it never produces a
      // transient overflow.
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: visible ? 1 : 0,
        duration: AuroraMotion.page,
        curve: AuroraMotion.easeOut,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 320),
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AuroraSpacing.xxl,
                _topPadding,
                AuroraSpacing.xxl,
                0,
              ),
              child: Column(
                children: [
                  const SizedBox(height: _markHeight, child: _MedicoMark()),
                  const SizedBox(height: _markGap),
                  OnboardingMilestoneStepper(step: step),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Medico lockup, matching the one on the auth screens — same glyph and
/// wordmark, recoloured for a light background instead of the gradient.
class _MedicoMark extends StatelessWidget {
  const _MedicoMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: AuroraGradients.aurora,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.monitor_heart_outlined,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'Medico',
          style: AuroraText.body(
            size: AuroraFontSize.h3,
            weight: FontWeight.w700,
          ).copyWith(letterSpacing: -0.2),
        ),
      ],
    );
  }
}
