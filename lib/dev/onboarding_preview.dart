// Standalone preview for OnboardingFlowScreen — not wired into the real app.
// Run with:
//   flutter run -t lib/dev/onboarding_preview.dart
//
// Supabase and Firebase are deliberately NOT initialised here, so the save
// and device-token writes fail into their own catch blocks. That is the
// point: it exercises the UI, the step machine and the animations without
// needing a signed-in account. The permission prompt is still the real one.
import 'package:flutter/material.dart';

import '../screens/onboarding_flow_screen.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingFlowScreen(),
    );
  }
}
