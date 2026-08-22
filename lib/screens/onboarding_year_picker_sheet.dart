/// Birth-year field and its wheel-picker bottom sheet.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../widgets/aurora_buttons.dart';

const int _firstYear = 1935;

/// Mirrors the `profiles_birth_year_check` constraint in
/// `005_onboarding_fields.sql`, which requires
/// `birth_year <= EXTRACT(YEAR FROM now()) - 16`.
///
/// The wheel used to run up to the current year, which meant its own default
/// landing position was a value the database would reject. Because gender,
/// city and the completion timestamp all travel in the same `UPDATE`, that
/// rejection discarded the entire answer set and left
/// `onboarding_completed_at` null — so the patient saw the success screen,
/// lost everything, and was routed back into onboarding on next launch.
/// Capping the range here makes that state unreachable rather than merely
/// unlikely.
///
/// Derived from the clock, not hardcoded, for the same reason the SQL uses
/// `now()`: a literal cutoff silently drifts out of sync every January.
const int _minimumAge = 16;

const double _itemExtent = 46;
const double _viewportHeight = 184;

/// The tappable field that opens the wheel. Shows the placeholder in muted
/// regular weight and the chosen year in ink bold, so a filled field is
/// legible at a glance without an extra checkmark.
class OnboardingYearField extends StatelessWidget {
  const OnboardingYearField({
    super.key,
    required this.value,
    required this.onTap,
  });

  final int? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return AuroraPressable(
      onTap: onTap,
      pressedScale: 0.985,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
        decoration: BoxDecoration(
          color: AuroraColors.tonal,
          borderRadius: BorderRadius.circular(AuroraRadius.md),
        ),
        child: Row(
          children: [
            Text(
              // Western digits, deliberately. The app-wide numeral toggle
              // does not exist yet; this follows the default rather than
              // inventing per-widget numeral handling ahead of it.
              hasValue ? '$value' : 'اختر سنة الميلاد',
              style: AuroraText.body(
                size: AuroraFontSize.bodyLg,
                weight: hasValue ? FontWeight.w700 : FontWeight.w400,
                color: hasValue ? AuroraColors.ink : AuroraColors.muted,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AuroraColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the year wheel. Resolves to the confirmed year, or null if the sheet
/// was dismissed without confirming.
Future<int?> showOnboardingYearPicker(BuildContext context, {int? initial}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AuroraColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AuroraRadius.xl),
      ),
    ),
    // A modal route sits outside this flow's subtree, so it does not inherit
    // the flow's Directionality — same reason forgot_password_sheet.dart
    // re-declares it.
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _YearPickerSheet(initial: initial),
    ),
  );
}

class _YearPickerSheet extends StatefulWidget {
  const _YearPickerSheet({required this.initial});

  final int? initial;

  @override
  State<_YearPickerSheet> createState() => _YearPickerSheetState();
}

class _YearPickerSheetState extends State<_YearPickerSheet> {
  late final List<int> _years;
  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();
    // The newest birth year that satisfies the server-side minimum-age rule.
    final latestYear = DateTime.now().year - _minimumAge;
    _years = [for (var y = _firstYear; y <= latestYear; y++) y];

    // Opens on the newest selectable year, so the default landing position is
    // always a value the database will accept.
    final initialIndex = _years.indexOf(widget.initial ?? latestYear);
    final index = initialIndex >= 0 ? initialIndex : _years.length - 1;

    _selected = _years[index];
    _controller = FixedExtentScrollController(initialItem: index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AuroraSpacing.xxl,
          0,
          AuroraSpacing.xxl,
          AuroraSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: AuroraSpacing.sm),
            Text(
              'سنة الميلاد',
              style: AuroraText.display(size: AuroraFontSize.h3),
            ),
            const SizedBox(height: AuroraSpacing.xl),
            SizedBox(
              height: _viewportHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Painted behind the wheel rather than passed as
                  // CupertinoPicker's `selectionOverlay`: that overlay renders
                  // on top of the items, so an opaque fill there hides the
                  // very value it is meant to highlight.
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    height: _itemExtent,
                    decoration: BoxDecoration(
                      color: AuroraColors.tonal,
                      borderRadius: BorderRadius.circular(AuroraRadius.sm),
                    ),
                  ),
                  ShaderMask(
                    // Fades the wheel out toward both edges so the list reads as
                    // a physical drum rather than a clipped list.
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xFF000000),
                        Color(0xFF000000),
                        Color(0x00000000),
                      ],
                      stops: [0.0, 0.34, 0.66, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: CupertinoPicker(
                      scrollController: _controller,
                      itemExtent: _itemExtent,
                      onSelectedItemChanged: (i) =>
                          setState(() => _selected = _years[i]),
                      // The band is drawn behind this picker instead; the default
                      // overlay would stack a second highlight on top of it.
                      selectionOverlay: null,
                      children: [
                        for (final year in _years)
                          Center(
                            child: Text(
                              '$year',
                              style: year == _selected
                                  ? AuroraText.display(
                                      size: AuroraFontSize.h2,
                                      color: AuroraColors.primary,
                                    )
                                  : AuroraText.body(
                                      size: AuroraFontSize.bodyLg,
                                      color: AuroraColors.muted,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuroraSpacing.xl),
            AuroraPrimaryButton(
              label: 'تأكيد',
              onTap: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}

/// The grab handle shared by both onboarding sheets.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: AuroraSpacing.md,
        bottom: AuroraSpacing.sm,
      ),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AuroraColors.divider,
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
      ),
    );
  }
}
