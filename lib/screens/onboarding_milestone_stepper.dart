/// The three-node progress path in the onboarding header.
library;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';

const List<String> _stepLabels = ['معلومات أساسية', 'مدينتك', 'الإشعارات'];

const List<IconData> _stepIcons = [
  Icons.person_outline,
  Icons.location_on_outlined,
  Icons.notifications_none,
];

/// One continuous track with three nodes sitting on it — not three separate
/// segments. The gradient fill grows along that single track as steps
/// complete, which is what makes the progress read as one journey.
///
/// Everything here is driven by [step] alone, on the same duration and curve
/// as the page slide, so the bar and the pages move as a single motion. It
/// deliberately does *not* follow the `PageController` offset continuously —
/// that couples the bar to scroll physics it should not care about.
class OnboardingMilestoneStepper extends StatelessWidget {
  const OnboardingMilestoneStepper({super.key, required this.step});

  /// 0-based index of the current step, clamped to 0..2 by the caller.
  final int step;

  /// Column width each node is centred inside.
  static const double _column = 76;

  /// Half a column — the distance from the container edge to the centre of
  /// the first node, i.e. where the track has to start and stop so it runs
  /// node-centre to node-centre.
  static const double _half = _column / 2;

  /// Vertical centre of the 40px node, minus half the 3px track.
  static const double _trackTop = 18.5;

  static const double _nodeSize = 40;

  /// Clears the active node's 8px outer ring before the label starts. At the
  /// old 8px the ring sat right on the text the moment a step became active.
  static const double _labelGap = AuroraSpacing.lg;

  static const double _labelHeight = 16;

  /// Published so the header can size itself from the stepper rather than
  /// carrying a duplicated magic number that silently drifts.
  static const double height = _nodeSize + _labelGap + _labelHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackLength = constraints.maxWidth - _column;
        final fillWidth = trackLength * (step / 2);

        return Stack(
          children: [
            // The full-length track, behind every node.
            PositionedDirectional(
              top: _trackTop,
              start: _half,
              end: _half,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AuroraColors.divider,
                  borderRadius: BorderRadius.circular(AuroraRadius.pill),
                ),
              ),
            ),
            // The completed portion, growing along that same track.
            PositionedDirectional(
              top: _trackTop,
              start: _half,
              child: AnimatedContainer(
                duration: AuroraMotion.page,
                curve: AuroraMotion.easeOut,
                width: fillWidth.clamp(0, double.infinity),
                height: 3,
                decoration: BoxDecoration(
                  gradient: AuroraGradients.aurora,
                  borderRadius: BorderRadius.circular(AuroraRadius.pill),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 3; i++)
                  _MilestoneNode(
                    index: i,
                    isDone: step > i,
                    isActive: step == i,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MilestoneNode extends StatelessWidget {
  const _MilestoneNode({
    required this.index,
    required this.isDone,
    required this.isActive,
  });

  final int index;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final filled = isDone || isActive;

    // Pending steps use secondary at 70% rather than the muted token: muted
    // on this background measures ~2.5:1 and reads as disabled rather than
    // merely not-yet-reached. Held back from full strength so the active step
    // still wins the row.
    final pendingInk = AuroraColors.secondary.withValues(alpha: 0.7);

    final labelColor = isActive
        ? AuroraColors.primary
        : isDone
        ? AuroraColors.secondary
        : pendingInk;

    return SizedBox(
      width: OnboardingMilestoneStepper._column,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isActive ? 1 : 0.86,
            duration: AuroraMotion.standard,
            curve: AuroraMotion.easeOut,
            child: AnimatedContainer(
              duration: AuroraMotion.standard,
              curve: AuroraMotion.easeOut,
              width: OnboardingMilestoneStepper._nodeSize,
              height: OnboardingMilestoneStepper._nodeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: filled ? AuroraGradients.aurora : null,
                color: filled ? null : AuroraColors.tonal,
                // Painted back-to-front: the soft green halo first, then a
                // solid ring in the page colour on top of it. The opaque ring
                // is what makes the track read as passing *behind* the node
                // instead of colliding with its edge.
                boxShadow: [
                  if (isActive)
                    const BoxShadow(
                      color: Color(0x291D9E75), // rgba(29,158,117,0.16)
                      spreadRadius: 8,
                    ),
                  const BoxShadow(
                    color: AuroraColors.background,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                isDone ? Icons.check : _stepIcons[index],
                size: isDone ? 18 : 16,
                color: filled ? Colors.white : pendingInk,
              ),
            ),
          ),
          const SizedBox(height: OnboardingMilestoneStepper._labelGap),
          // Each label sits under its own node rather than being centred
          // beneath the bar as a whole. Scaled down rather than wrapped so
          // the header's fixed height holds for every label length.
          SizedBox(
            height: OnboardingMilestoneStepper._labelHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: AuroraMotion.standard,
                curve: AuroraMotion.easeOut,
                style: AuroraText.body(
                  size: AuroraFontSize.micro,
                  weight: FontWeight.w700,
                  color: labelColor,
                  height: 1.3,
                ),
                child: Text(
                  _stepLabels[index],
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
