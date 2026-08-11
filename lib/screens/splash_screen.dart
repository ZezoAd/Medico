import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

/// The app's first route: decides between [SignInScreen] and [HomeScreen]
/// based on the persisted Supabase session, so a returning user never sees a
/// flash of the sign-in form before being bounced past it.
///
/// Supabase restores the session from local storage during
/// `Supabase.initialize`, so `currentSession` is already populated by the time
/// this builds — the only real wait here is the profile fetch.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap(context));

    return const Scaffold(
      backgroundColor: Color(0xFF1D9E75),
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _bootstrap(BuildContext context) async {
    final navigator = Navigator.of(context);
    // Once we've replaced ourselves this is no longer the current route, so a
    // second post-frame callback (from a rebuild) can't navigate again.
    final route = ModalRoute.of(context);

    Widget destination;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        destination = const SignInScreen();
      } else {
        // Fetched here rather than on HomeScreen so the role-based routing
        // that replaces this line later has what it needs at the decision
        // point. For now every role lands on the same screen.
        await const ProfileService().fetchCurrentProfile();
        destination = const HomeScreen();
      }
    } catch (_) {
      // Supabase not initialized, or the profile read failed — the sign-in
      // screen is the safe landing spot either way.
      destination = const SignInScreen();
    }

    if (!navigator.mounted || route?.isCurrent == false) return;
    await navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}
