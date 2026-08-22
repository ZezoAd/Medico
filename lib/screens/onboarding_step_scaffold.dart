/// Shared layout rhythm and footer shape for the onboarding steps.
library;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../widgets/aurora_buttons.dart';

/// The fixed gap between the header's stepper and the first line of content.
/// The header deliberately has no bottom padding so this is the whole
/// distance, not one contribution to it.
const double _stepperToContent = 36;

/// One vertical rhythm for every step: a fixed gap under the stepper,
/// top-aligned content, then a single flexible gap before a bottom-pinned
/// footer.
///
/// Steps used to each build their own column, which is how they drifted into
/// having padding above *and* below the content — two dead zones fighting
/// each other for the same space. Centering is deliberately not offered here:
/// with a pinned footer it produces exactly that double gap.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.footer,
  });

  final String title;
  final String subtitle;

  /// Content below the subtitle.
  final List<Widget> children;

  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // Scrolls only when the content genuinely outgrows the viewport;
          // minHeight keeps it top-aligned with the slack pooled at the
          // bottom the rest of the time.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AuroraSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: _stepperToContent),
                    Text(
                      title,
                      style: AuroraText.display(
                        size: AuroraFontSize.h1,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: AuroraSpacing.md),
                    Text(
                      subtitle,
                      style: AuroraText.body(
                        size: AuroraFontSize.body,
                        color: AuroraColors.secondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: AuroraSpacing.xxxl),
                    ...children,
                    const SizedBox(height: AuroraSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          // No top padding: the flexible gap above is the separation.
          padding: const EdgeInsets.fromLTRB(
            AuroraSpacing.xxl,
            0,
            AuroraSpacing.xxl,
            AuroraSpacing.xxl,
          ),
          child: footer,
        ),
      ],
    );
  }
}

/// The one footer shape. A full-width primary always, then either a skip text
/// link (optional steps) or helper text explaining the disabled state
/// (required steps) — never both, and never a second competing button.
class OnboardingStepFooter extends StatelessWidget {
  const OnboardingStepFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.skipLabel,
    this.onSkip,
    this.helperText,
  }) : assert(
         skipLabel == null || onSkip != null,
         'a skip link needs a handler',
       );

  final String primaryLabel;

  /// Null renders the primary disabled — pair it with [helperText] so the
  /// reason is visible rather than left to be guessed at.
  final VoidCallback? onPrimary;

  final IconData? primaryIcon;

  final String? skipLabel;
  final VoidCallback? onSkip;

  /// Shown under a disabled primary on required steps.
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final showHelper = helperText != null && onPrimary == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraPrimaryButton(
          label: primaryLabel,
          icon: primaryIcon,
          onTap: onPrimary,
        ),
        if (skipLabel != null)
          AuroraSecondaryButton(label: skipLabel!, onTap: onSkip!)
        else if (showHelper) ...[
          const SizedBox(height: AuroraSpacing.md),
          Text(
            helperText!,
            style: AuroraText.body(
              size: AuroraFontSize.caption,
              color: AuroraColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
