/// Onboarding step 2 — governorate. The one required answer in the flow.
library;

import 'package:flutter/material.dart';

import '../models/onboarding_data.dart';
import '../theme/aurora_tokens.dart';
import '../widgets/aurora_buttons.dart';
import '../widgets/aurora_select_field.dart';
import 'onboarding_city_picker_sheet.dart';
import 'onboarding_step_scaffold.dart';

class OnboardingStep2City extends StatelessWidget {
  const OnboardingStep2City({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onContinue,
  });

  final OnboardingData data;
  final ValueChanged<OnboardingData> onChanged;
  final VoidCallback onContinue;

  Future<void> _pickCity(BuildContext context) async {
    final city = await showOnboardingCityPicker(context, current: data.city);
    if (city != null) onChanged(data.copyWith(city: city));
  }

  @override
  Widget build(BuildContext context) {
    final hasCity = data.hasCity;

    return OnboardingStepScaffold(
      title: 'أين تقيم؟',
      subtitle: 'نستخدم هذه المعلومة لعرض الأطباء والعيادات الأقرب إليك.',
      // Required step: no skip, and the disabled button gets helper text so
      // the block is explained rather than just felt.
      footer: OnboardingStepFooter(
        primaryLabel: 'متابعة',
        onPrimary: hasCity ? onContinue : null,
        helperText: 'اختر محافظتك للمتابعة',
      ),
      children: [
        const AuroraSectionTitle(title: 'المحافظة'),
        const SizedBox(height: AuroraSpacing.lg),
        AuroraSelectField(
          icon: Icons.location_on_outlined,
          value: hasCity ? data.city : null,
          placeholder: 'اختر محافظتك',
          subtitle: 'اضغط للتغيير',
          onTap: () => _pickCity(context),
        ),
      ],
    );
  }
}
