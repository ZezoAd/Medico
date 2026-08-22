import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../theme/aurora_tokens.dart';
import '../utils/auth_error_mapper.dart';
import 'home_screen.dart';
import 'onboarding_flow_screen.dart';
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
      backgroundColor: AuroraColors.primary,
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
      destination = session == null
          ? const SignInScreen()
          : await _destinationForSession();
    } catch (_) {
      // Supabase not initialized, or a plain network/timeout hiccup while
      // checking the session — the sign-in screen is the safe landing spot
      // either way, and the session (if any) is left untouched so a normal
      // retry on next launch can still walk straight past it.
      destination = const SignInScreen();
    }

    if (!navigator.mounted || route?.isCurrent == false) return;
    await navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  /// Resolves where a *present* session should land. Network-shaped failures
  /// (no connectivity, a timeout, gotrue's own retryable-fetch error) are
  /// rethrown untouched so the caller's catch-all handles them without
  /// touching the stored session — only a genuine rejection (revoked token,
  /// or the `profiles` row gone) is treated as the session actually being
  /// invalid.
  Future<Widget> _destinationForSession() async {
    try {
      // A round-trip, unlike `currentUser` — catches a token that was
      // revoked server-side even though the local copy still looks live.
      final userResponse = await Supabase.instance.client.auth.getUser();
      if (userResponse.user == null) {
        throw const AuthException('Session user not found');
      }
      // Fetched here rather than on HomeScreen so the role-based routing
      // that replaces this line later has what it needs at the decision
      // point. For now every role lands on the same screen. A null profile
      // means the `profiles` row is gone (e.g. deleted directly in the
      // database) even though the auth session itself is still valid.
      final profile = await const ProfileService().fetchCurrentProfile();
      if (profile == null) {
        throw const AuthException('Profile not found');
      }
      // Catches a session that was established without ever passing the sign-in
      // screen's own check — most realistically the one handed out by a
      // completed password recovery, which is exactly the route around the
      // signup OTP that `signup_verified` exists to close. Handled here rather
      // than left to the sign-in screen, because this path never visits it.
      if (!profile.signupVerified) {
        await Supabase.instance.client.auth.signOut();
        return SignInScreen(
          initialErrorMessage: emailNotConfirmedMessage,
          initialUnconfirmedEmail: userResponse.user!.email,
        );
      }
      // Additive to the session check above, not part of it: the session is
      // already confirmed valid by this point: this only picks the landing
      // screen. Anyone who never finished onboarding — including accounts
      // that predate it — gets sent through it before Home.
      if (!profile.hasCompletedOnboarding) {
        return const OnboardingFlowScreen();
      }
      return const HomeScreen();
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } on AuthRetryableFetchException {
      rethrow;
    } catch (_) {
      // The stored session no longer corresponds to a real, usable account —
      // sign out for real so the stale token can't silently keep coming
      // back, and say so instead of bouncing to Sign In with no explanation.
      await Supabase.instance.client.auth.signOut();
      return const SignInScreen(initialErrorMessage: sessionInvalidMessage);
    }
  }
}
