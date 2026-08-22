/// Onboarding step 1 — optional gender and birth year.
library;

import 'package:flutter/material.dart';

import '../models/onboarding_data.dart';
import '../theme/aurora_tokens.dart';
import '../widgets/aurora_buttons.dart';
import '../widgets/aurora_select_field.dart';
import 'onboarding_gender_control.dart';
import 'onboarding_step_scaffold.dart';
import 'onboarding_year_picker_sheet.dart';

class OnboardingStep1Basics extends StatelessWidget {
  const OnboardingStep1Basics({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onContinue,
    required this.onSkip,
  });

  final OnboardingData data;
  final ValueChanged<OnboardingData> onChanged;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  Future<void> _pickYear(BuildContext context) async {
    final year = await showOnboardingYearPicker(
      context,
      initial: data.birthYear,
    );
    if (year != null) onChanged(data.copyWith(birthYear: year));
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'لنتعرف عليك قليلاً',
      subtitle:
          'معلومات اختيارية تساعدنا على عرض أطباء أنسب لك. يمكنك تعديلها في أي وقت من الإعدادات.',
      // Exactly two ways off this step: answer both and continue, or skip.
      // A half-filled form is not a third path — "متابعة" stays disabled
      // until gender *and* birth year are set, so continuing always means a
      // complete answer and skipping always means a deliberate one. The
      // fields remain optional overall; "تخطي" is never gated.
      footer: OnboardingStepFooter(
        primaryLabel: 'متابعة',
        onPrimary: (data.gender != null && data.birthYear != null)
            ? onContinue
            : null,
        skipLabel: 'تخطي',
        onSkip: onSkip,
      ),
      children: [
        const AuroraSectionTitle(title: 'الجنس'),
        const SizedBox(height: AuroraSpacing.lg),
        OnboardingGenderControl(
          value: data.gender,
          // Tapping the current selection clears it — the field is optional,
          // and this is how you take an answer back without a third
          // "prefer not to say" pill.
          onChanged: (gender) => onChanged(
            data.gender == gender
                ? data.copyWith(clearGender: true)
                : data.copyWith(gender: gender),
          ),
        ),
        const SizedBox(height: AuroraSpacing.xxxl),
        const AuroraSectionTitle(title: 'سنة الميلاد'),
        const SizedBox(height: AuroraSpacing.lg),
        AuroraSelectField(
          icon: Icons.calendar_month_outlined,
          value: data.birthYear == null ? null : '${data.birthYear}',
          placeholder: 'اختر سنة الميلاد',
          onTap: () => _pickYear(context),
        ),
      ],
    );
  }
}
