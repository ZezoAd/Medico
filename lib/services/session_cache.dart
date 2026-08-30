/// Remembers what the server last *confirmed* about a signed-in patient, so a
/// launch that cannot reach the server can still let them back in.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// The last server-confirmed answer to "where does this user belong".
///
/// Written only after a resolve that actually succeeded — never guessed, never
/// written from a cached or partial read. That is what makes it safe to trust
/// when the network is gone: every value in it was true the last time the
/// server was actually asked.
///
/// Keyed by user id so switching accounts on one device cannot inherit the
/// previous person's answer.
class SessionCache {
  const SessionCache();

  static const _verifiedPrefix = 'session_verified_';
  static const _onboardedPrefix = 'session_onboarded_';

  /// Records a confirmed resolve.
  ///
  /// [signupVerified] is only ever passed `true` by the caller — an
  /// unverified signup is signed out on the spot and must not leave a
  /// breadcrumb that a later offline launch could read as permission.
  Future<void> remember({
    required String userId,
    required bool signupVerified,
    required bool onboardingComplete,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_verifiedPrefix$userId', signupVerified);
    await prefs.setBool('$_onboardedPrefix$userId', onboardingComplete);
  }

  /// The last confirmed state for [userId], or null if this device has never
  /// completed a resolve for them.
  ///
  /// Null is the important case: it means we have never once seen the server
  /// vouch for this account, so there is nothing to fail open *to*.
  Future<({bool signupVerified, bool onboardingComplete})?> read(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final verified = prefs.getBool('$_verifiedPrefix$userId');
    if (verified == null) return null;
    return (
      signupVerified: verified,
      onboardingComplete: prefs.getBool('$_onboardedPrefix$userId') ?? false,
    );
  }

  /// Drops the record — called on a real sign-out so the next person on this
  /// device starts from nothing.
  Future<void> forget(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_verifiedPrefix$userId');
    await prefs.remove('$_onboardedPrefix$userId');
  }
}
