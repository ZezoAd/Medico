import 'package:flutter/material.dart';

import 'auth_gate.dart';

/// The app's first route.
///
/// The session check and the sign-in/onboarding/Home decision it used to make
/// itself now live in [AuthGate], so that every entry path — cold launch,
/// Google, and email OTP — resolves through the same code. This stays as the
/// named entry point `main.dart` boots into; [AuthGate] renders the launch
/// spinner while it works, so there is still no flash of the sign-in form for
/// a returning user.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthGate();
}
