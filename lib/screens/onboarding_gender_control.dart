/// The gender segmented control on step 1.
library;

import 'package:flutter/material.dart';

import '../models/onboarding_data.dart';
import '../theme/aurora_tokens.dart';

/// A two-option sliding segmented control. أنثى sits on the right and ذكر on
/// the left — the natural RTL reading order, produced by the ambient
/// [Directionality] rather than by reversing the children by hand.
///
/// Male/female only, and no "prefer not to say": the field is optional, so
/// skipping it already serves that purpose without a third pill.
class OnboardingGenderControl extends StatefulWidget {
  const OnboardingGenderControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Gender? value;

  /// Fires with the tapped option. Deselection is the caller's decision —
  /// tapping the current selection again is what clears it.
  final ValueChanged<Gender> onChanged;

  @override
  State<OnboardingGenderControl> createState() =>
      _OnboardingGenderControlState();
}

class _OnboardingGenderControlState extends State<OnboardingGenderControl> {
  /// The indicator must *appear in place* on the very first pick and only
  /// slide on later switches — otherwise the first selection looks like it
  /// flew in from an option the user never chose. So sliding stays off until
  /// one frame after the first non-null value has painted.
  bool _canSlide = false;

  static const List<Gender> _options = [Gender.female, Gender.male];

  @override
  void initState() {
    super.initState();
    _syncSlide();
  }

  @override
  void didUpdateWidget(covariant OnboardingGenderControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncSlide();
  }

  void _syncSlide() {
    if (widget.value == null) {
      if (_canSlide) setState(() => _canSlide = false);
      return;
    }
    if (_canSlide) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.value != null) setState(() => _canSlide = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final selectedIndex = value == Gender.female ? 0 : 1;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AuroraColors.tonal,
        borderRadius: BorderRadius.circular(AuroraRadius.lg),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;

          return SizedBox(
            height: 52,
            child: Stack(
              children: [
                // Sliding selection pill. Only its position is gated by
                // _canSlide; the fade-in always runs.
                AnimatedPositionedDirectional(
                  duration: _canSlide
                      ? AuroraMotion.genderSlideDuration
                      : Duration.zero,
                  curve: AuroraMotion.genderSlide,
                  start: selectedIndex == 0 ? 0 : halfWidth,
                  top: 0,
                  bottom: 0,
                  width: halfWidth,
                  child: AnimatedOpacity(
                    opacity: value == null ? 0 : 1,
                    duration: Duration(milliseconds: _canSlide ? 200 : 160),
                    // White pill on the tonal track, same as the sign-in role
                    // tabs. The lifted white reads as a physical switch, where
                    // a gradient fill made the control look like a pair of
                    // buttons one of which happened to be primary.
                    child: Container(
                      decoration: BoxDecoration(
                        color: AuroraColors.surface,
                        borderRadius: BorderRadius.circular(AuroraRadius.md),
                        boxShadow: AuroraShadows.pill,
                      ),
                    ),
                  ),
                ),
                // The seam between the two options at rest. It uses
                // AuroraColors.secondary, not the divider token: divider on
                // this tonal track measures ~1.07:1 and is invisible, which
                // was a real bug. It fades once a pill edge sits flush
                // against it so the two edges don't read as a doubled line.
                PositionedDirectional(
                  start: halfWidth - 1,
                  top: 12,
                  child: AnimatedOpacity(
                    opacity: value == null ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 2,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AuroraColors.secondary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final option in _options)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onChanged(option),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AuroraMotion.standard,
                              curve: AuroraMotion.easeOut,
                              style: AuroraText.body(
                                size: AuroraFontSize.bodyLg,
                                weight: FontWeight.w700,
                                color: value == option
                                    ? AuroraColors.primary
                                    : AuroraColors.secondary,
                              ),
                              child: Text(option.arabicLabel),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
