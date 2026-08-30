/// The single place that decides sign-in vs onboarding vs Home.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_data.dart';
import '../services/onboarding_sync_service.dart';
import '../services/profile_service.dart';
import '../services/session_cache.dart';
import '../theme/aurora_tokens.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/aurora_buttons.dart';
import 'home_screen.dart';
import 'onboarding_flow_screen.dart';
import 'welcome_screen.dart';

/// Resolves where a signed-in patient belongs and renders it.
///
/// Every entry path funnels through here — Google sign-up, Google sign-in,
/// email OTP sign-up, email OTP sign-in, and cold relaunch. Auth handlers
/// used to each make their own routing decision and had drifted apart: one
/// checked `onboarding_completed_at`, one keyed off "was this a signup",
/// and one sent everybody to Home including callers with a null profile.
/// The rule is now stated once, here.
///
/// Deliberately has no "this is a fresh signup" input. Signup and sign-in are
/// the same question once a session exists, and the column being null is the
/// only signal needed to answer it.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

/// What the gate is currently able to say.
enum _GateStatus {
  /// The `profiles` fetch is in flight. Never routes anywhere — resolving to
  /// Home while this is unknown is the bug this state exists to prevent.
  loading,

  /// The fetch failed in a way that says nothing about the account, and this
  /// device has never seen the server vouch for the account either — so there
  /// is no last-known state to fall back on. Offers a retry.
  ///
  /// This is now the *rare* branch. A returning patient whose account has been
  /// confirmed before goes to [ready] on their remembered state instead; only
  /// someone whose very first resolve fails can land here.
  retry,

  /// No usable session. The reason travels with it.
  signedOut,

  ready,
}

class _AuthGateState extends State<AuthGate> {
  static const _fetchTimeout = Duration(seconds: 15);

  /// Silent retries before the gate shows the patient anything at all.
  ///
  /// A cold launch on a waking radio routinely fails its first call and
  /// succeeds a second later; that should look like a slightly slow start, not
  /// like an error — and certainly not like a sign-out.
  static const _retryBackoff = [
    Duration(milliseconds: 400),
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];

  /// The only errors allowed to end a session.
  ///
  /// Every one of these is the server explicitly saying the *refresh token* is
  /// finished — not that a request failed, not that a token was stale, not
  /// that a response was unexpected. Anything outside this set is treated as
  /// recoverable, however it looks.
  ///
  /// Deliberately excludes `bad_jwt` and a bare 401. Those describe the
  /// *access* token, which is exactly what a refresh exists to replace, and
  /// treating them as terminal is the bug this list was written to fix: a
  /// patient whose access token had merely gone stale was being signed out and
  /// having their still-valid refresh token deleted.
  static const _confirmedRejectionCodes = {
    // gotrue's own ErrorCode values for a dead session.
    'session_expired',
    'session_not_found',
    'user_not_found',
    'user_banned',
    // Raw codes the token endpoint can return that gotrue passes through
    // without an enum case. Matched as strings on purpose.
    'invalid_grant',
    'refresh_token_not_found',
    'refresh_token_already_used',
    'refresh_token_revoked',
  };

  final _sync = const OnboardingSyncService();
  final _cache = const SessionCache();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// The routing half of the answer: this person is done with onboarding, by
  /// either signal — the server said so, or they finished on this device.
  ///
  /// Monotonic for the life of a resolve. Once true it only goes false via a
  /// fresh [_resolve], never as a side effect of syncing. It used to be one
  /// flag with [_hasQueuedRecord] below, and the profile fetched at resolve
  /// time was kept around as the other half of the decision. A successful push
  /// cleared the flag, the decision fell back on that pre-write snapshot, and
  /// someone who had just finished was sent back into onboarding about one
  /// network round trip after reaching Home. The snapshot is gone with it —
  /// there is no cached profile left here to go stale.
  bool _onboardingComplete = false;

  /// The queue half: a local record still owed to the server. Purely about
  /// retries, never about where the person goes.
  bool _hasQueuedRecord = false;

  /// An onboarding run that was started and never finished, if this device
  /// remembers one for this user. Null means start from the top.
  OnboardingProgress? _progress;

  _GateStatus _status = _GateStatus.loading;

  /// Populated when [_status] is [_GateStatus.signedOut] and there is
  /// something worth explaining.
  String? _signedOutMessage;
  String? _unconfirmedEmail;

  @override
  void initState() {
    super.initState();
    _resolve();

    // Retry trigger #2. Paired with the launch-triggered attempt in
    // [_resolve], this is the whole retry policy — no polling loop.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) _drainPendingOnboarding();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Pushes the queued onboarding record, if any. Silent by design: it can
  /// run while the person is already using Home and must never interrupt.
  ///
  /// Only ever touches [_hasQueuedRecord]. Where the person is standing is
  /// [_onboardingComplete]'s business, and a sync result — success, failure or
  /// "nothing was queued" — is not evidence about that either way.
  Future<void> _drainPendingOnboarding() async {
    if (!_hasQueuedRecord) return;
    final synced = await _sync.syncPending();
    if (synced && mounted) setState(() => _hasQueuedRecord = false);
  }

  /// Whether [error] is the server unambiguously ending this session.
  ///
  /// The default answer is no. Only a code in [_confirmedRejectionCodes]
  /// counts; a network failure, a timeout, a stale access token, an
  /// unrecognised response and anything else this app has not explicitly
  /// classified are all treated as "we could not tell", which never signs
  /// anybody out.
  static bool _isConfirmedRejection(Object error) {
    if (error is! AuthException) return false;
    final code = error.code;
    return code != null && _confirmedRejectionCodes.contains(code);
  }

  Future<void> _resolve() async {
    if (_status != _GateStatus.loading) {
      setState(() => _status = _GateStatus.loading);
    }

    for (var attempt = 0; ; attempt++) {
      try {
        await _attemptResolve();
        return;
      } catch (error) {
        // The one exit that ends a session. Checked before the retry loop so
        // a genuinely dead refresh token is not pointlessly retried four
        // times — the answer will not change.
        if (_isConfirmedRejection(error)) {
          await _signOutForReal(sessionInvalidMessage);
          return;
        }

        if (attempt < _retryBackoff.length) {
          await Future<void>.delayed(_retryBackoff[attempt]);
          if (!mounted) return;
          continue;
        }

        // Retries exhausted and still no clear answer. Fall back on what the
        // server last confirmed rather than making the patient sign in again.
        await _failOpen();
        return;
      }
    }
  }

  /// One full resolve. Throws on any failure; the caller decides what that
  /// means.
  Future<void> _attemptResolve() async {
    final client = Supabase.instance.client;

    // Awaited, unlike the `currentSession` getter this replaces. That getter
    // hands back whatever is in memory *including an already-expired session*,
    // which on a cold start is exactly what it is: `Supabase.initialize` only
    // awaits `setInitialSession`, and fires the refresh off unawaited. The
    // gate used to read that stale session, send its dead access token to
    // `getUser`, take the 401 as a rejection and sign the patient out.
    //
    // `getSession` resolves only once the token is actually good — refreshing
    // an expired one itself and joining an in-flight refresh rather than
    // racing it.
    final session = await client.auth.getSession().timeout(_fetchTimeout);

    if (session == null) {
      // Genuinely nobody signed in — not a failure, just a signed-out device.
      if (!mounted) return;
      setState(() {
        _status = _GateStatus.signedOut;
        _signedOutMessage = null;
      });
      return;
    }

    // A round trip, unlike `currentUser` — catches a token revoked
    // server-side while the local copy still looks live.
    final userResponse = await client.auth.getUser().timeout(_fetchTimeout);
    final user = userResponse.user;
    if (user == null) throw const AuthException('Session user not found');

    final profile = await const ProfileService()
        .fetchCurrentProfile()
        .timeout(_fetchTimeout);
    if (profile == null) throw const AuthException('Profile not found');

    if (!mounted) return;

    // Catches a session established without ever passing the signup check —
    // most realistically the one handed out by a completed password
    // recovery, which is the route around the OTP that `signup_verified`
    // exists to close.
    //
    // Untouched by the leniency above, deliberately. That leniency is about
    // *reaching* an answer; this is about what to do with the answer once the
    // server has actually given it. A confirmed `signup_verified == false`
    // still signs out on the spot, exactly as before.
    if (!profile.signupVerified) {
      await _signOutForReal(emailNotConfirmedMessage, email: user.email);
      return;
    }

    // A local record counts as completed: the person finished on this
    // device, the server just has not heard yet. Retry trigger #1 fires
    // here, on every launch that still has something queued.
    final pending = profile.hasCompletedOnboarding
        ? false
        : await _sync.hasPending(user.id);

    // Only worth reading when onboarding is actually about to show. When it
    // isn't, any record still sitting there is a leftover from a run that
    // finished by some other path — bin it rather than leave a stale
    // breadcrumb that a later incomplete run could resume from.
    final resumable = profile.hasCompletedOnboarding || pending;
    final progress = resumable ? null : await _sync.loadProgress(user.id);
    if (resumable) unawaited(_sync.clearProgress(user.id));

    final onboardingComplete = profile.hasCompletedOnboarding || pending;

    // Only written on the path where the server actually answered, and only
    // ever with `signupVerified: true` — an unverified account returned above
    // without leaving a record behind.
    unawaited(
      _cache.remember(
        userId: user.id,
        signupVerified: true,
        onboardingComplete: onboardingComplete,
      ),
    );

    if (!mounted) return;

    setState(() {
      _progress = progress;
      _hasQueuedRecord = pending;
      // Both signals collapse into the routing answer here, once, against a
      // profile that was just read from the server this instant.
      _onboardingComplete = onboardingComplete;
      _status = _GateStatus.ready;
    });

    if (pending) unawaited(_drainPendingOnboarding());
  }

  /// Ends the session and says why. The only path to [GoTrueClient.signOut] in
  /// this file.
  Future<void> _signOutForReal(String message, {String? email}) async {
    final userId = Supabase.instance.client.auth.currentSession?.user.id;
    if (userId != null) await _cache.forget(userId);

    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    setState(() {
      _status = _GateStatus.signedOut;
      _signedOutMessage = message;
      _unconfirmedEmail = email;
    });
  }

  /// Could not reach a verdict. Let the patient in on what the server last
  /// confirmed, rather than making a network problem look like a sign-out.
  ///
  /// The session is left completely alone — not signed out, not cleared. The
  /// refresh token stays on disk, the auto-refresh ticker keeps trying, and
  /// the next successful call quietly repairs everything.
  Future<void> _failOpen() async {
    // The stale session is still in memory even when the refresh failed, so
    // this identifies the patient without having reached the server.
    final userId = Supabase.instance.client.auth.currentSession?.user.id;
    final known = userId == null ? null : await _cache.read(userId);

    if (!mounted) return;

    // Nothing remembered — this device has never once seen the server vouch
    // for this account, so there is no confirmed state to fall open to and
    // guessing one would be inventing permission. Offer a retry instead. Note
    // this still does not sign anyone out.
    if (known == null || !known.signupVerified) {
      setState(() => _status = _GateStatus.retry);
      return;
    }

    setState(() {
      _onboardingComplete = known.onboardingComplete;
      _progress = null;
      _status = _GateStatus.ready;
    });
  }

  /// Onboarding just finished: the record is already staged locally, so the
  /// gate can resolve straight to Home without waiting on the server.
  void _onOnboardingFinished() {
    setState(() {
      _onboardingComplete = true;
      _hasQueuedRecord = true;
    });
    unawaited(_drainPendingOnboarding());
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _GateStatus.loading:
        return const _GateLoading();

      case _GateStatus.retry:
        return _GateRetry(onRetry: _resolve);

      case _GateStatus.signedOut:
        // Welcome, not Sign In, is the signed-out root now — the auth
        // screens are separate routes and something has to sit under them.
        //
        // A forced sign-out still has to land on Sign In, which is the only
        // screen that can act on the message: Welcome forwards itself to Sign
        // In on its first frame whenever these are set, so the banner and its
        // "resend a code" action arrive exactly where they did before, with
        // Welcome underneath rather than an empty navigator.
        return WelcomeScreen(
          initialErrorMessage: _signedOutMessage,
          initialUnconfirmedEmail: _unconfirmedEmail,
        );

      case _GateStatus.ready:
        // The whole decision, already computed. Deliberately not re-derived
        // from `_profile` here: that object is a snapshot from resolve time
        // and goes stale the moment onboarding finishes underneath it.
        return _onboardingComplete
            // The Profile tab's sign-out row hands control back here rather
            // than navigating itself — this widget is the root, so there is
            // no route for it to pop.
            ? HomeScreen(onSignedOut: _resolve)
            // Staying mounted matters: this state owns the connectivity
            // listener, so onboarding hands control back rather than
            // replacing the route.
            : OnboardingFlowScreen(
                onFinished: _onOnboardingFinished,
                initialStep: _progress?.step ?? 0,
                initialData: _progress?.data ?? const OnboardingData(),
              );
    }
  }
}

/// The launch visual, reused as the gate's in-flight state so a cold start
/// and a post-auth resolve look identical.
class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
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
}

class _GateRetry extends StatelessWidget {
  const _GateRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AuroraColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AuroraColors.tonal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 32,
                    color: AuroraColors.secondary,
                  ),
                ),
                const SizedBox(height: AuroraSpacing.xl),
                Text(
                  'تعذّر الاتصال',
                  style: AuroraText.display(size: AuroraFontSize.h2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AuroraSpacing.md),
                Text(
                  'تحقق من اتصالك بالإنترنت ثم أعد المحاولة.',
                  style: AuroraText.body(
                    size: AuroraFontSize.body,
                    color: AuroraColors.secondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AuroraSpacing.xxl),
                AuroraPrimaryButton(
                  label: 'إعادة المحاولة',
                  icon: Icons.refresh_rounded,
                  onTap: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
