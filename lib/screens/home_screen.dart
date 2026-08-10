import 'package:flutter/material.dart';

/// Placeholder landing screen shown once a user is fully signed in and
/// verified. Real content lives elsewhere; this just gives the auth flow
/// (sign-up → OTP verification) somewhere concrete to land.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    size: 32,
                    color: Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'مرحبًا بك في Medico',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
