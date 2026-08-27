import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../theme/aurora_tokens.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_surface.dart';
import 'auth_gate.dart';

enum _OtpStatus { empty, filling, loading, success, failure }

/// Which GoTrue channel this screen sends and verifies codes on.
///
/// The split exists because GoTrue's signup-confirmation endpoints are gated
/// on *its own* `email_confirmed_at`, which is not the same question the app
/// asks. See [OtpPurpose.reVerification] for the case where the two diverge.
enum OtpPurpose {
  /// A brand-new account that GoTrue still considers unconfirmed.
  ///
  /// `resend(type: OtpType.signup)` / `verifyOTP(type: OtpType.signup)` — the
  /// original, working flow. Do not route anything else through it.
  signupConfirmation,

  /// An account GoTrue already considers confirmed, but that never finished
  /// the app's own signup step (`profiles.signup_verified` is still false).
  ///
  /// This is what an abandoned-signup-then-password-recovery account looks
  /// like: verifying the recovery link calls `user.Confirm(tx)` server-side
  /// as a side effect, so `email_confirmed_at` gets stamped without the OTP
  /// screen ever being completed.
  ///
  /// The signup channel is unusable here. GoTrue's resend handler starts with
  ///
  ///     case mail.SignupVerification:
  ///         if user.IsConfirmed() {
  ///             return sendJSON(w, http.StatusOK, map[string]string{})
  ///         }
  ///
  /// so `resend(type: OtpType.signup)` returns 200 with an empty body and
  /// sends nothing — no exception to catch, no email, no way for the client
  /// to tell it apart from a successful send.
  ///
  /// `signInWithOtp(shouldCreateUser: false)` does not consult confirmation
  /// state at all, so it delivers a code regardless; the matching verify type
  /// is [OtpType.email], not [OtpType.signup].
  ///
  /// Requires `{{ .Token }}` in the project's **Magic Link** email template —
  /// that template is what this channel sends, and without the token it
  /// carries only a link, so no typeable code ever reaches the person.
  reVerification,
}

/// Six-digit email verification screen, in the auth surface's gradient-hero
/// over white-sheet shape. The caller sends the first code immediately before
/// pushing this screen, so screen entry starts the resend cooldown rather
/// than a send.
///
/// Which channel is used for both sending and verifying is decided entirely
/// by [purpose] — see [OtpPurpose] for why one flow is not enough.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.purpose = OtpPurpose.signupConfirmation,
    this.passwordUnchanged = false,
  });

  final String email;

  /// The GoTrue channel to send and verify on. Defaults to the fresh-signup
  /// flow; callers reached through the `signup_verified` gate must pass
  /// [OtpPurpose.reVerification] instead.
  final OtpPurpose purpose;

  /// Set when this screen was reached by re-signing-up an address that
  /// already had an unverified account. GoTrue resent the code but kept the
  /// original password, so the one just typed on the signup form is not the
  /// one on the account — worth saying plainly here rather than letting it
  /// surface later as an unexplained "wrong email or password".
  final bool passwordUnchanged;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _digitCount = 6;
  static const _resendCooldown = Duration(seconds: 60);

  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _profileService = const ProfileService();

  _OtpStatus _status = _OtpStatus.empty;
  String? _errorMessage;
  bool _resending = false;
  bool _sendFailed = false;

  /// When the code being verified was sent — the only thing that separates a
  /// mistyped code from an expired one, since Supabase reports both the same
  /// way (see [mapOtpVerifyError]). `signUp` sends the email immediately
  /// before this screen is pushed, so screen entry is the send time; [_resend]
  /// re-stamps it.
  late DateTime _codeSentAt;

  /// Seconds left before "إعادة إرسال الرمز" becomes tappable again; 0 means
  /// no cooldown is running. Driven by [_cooldownTimer].
  int _resendSeconds = 0;
  Timer? _cooldownTimer;

  String get _code => _pinController.text;

  bool get _isComplete => _code.length == _digitCount;

  bool get _coolingDown => _resendSeconds > 0;

  @override
  void initState() {
    super.initState();
    _codeSentAt = DateTime.now();
    // `signUp` already sent the first code just before this screen was
    // pushed, so the cooldown starts on entry, not on the first resend.
    _startResendCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    _resendSeconds = _resendCooldown.inSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) {
        timer.cancel();
        _cooldownTimer = null;
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() => _sendFailed = false);
    try {
      final auth = Supabase.instance.client.auth;
      switch (widget.purpose) {
        case OtpPurpose.signupConfirmation:
          await auth.resend(type: OtpType.signup, email: widget.email);
        case OtpPurpose.reVerification:
          // Never `resend` here: GoTrue short-circuits the signup channel for
          // an already-confirmed address and reports success without sending.
          // `shouldCreateUser: false` keeps this from quietly registering a
          // new account if the address somehow isn't on file.
          await auth.signInWithOtp(
            email: widget.email,
            shouldCreateUser: false,
          );
      }
      _codeSentAt = DateTime.now();
      // Only a code that actually went out starts the clock — a failed send
      // must leave the link tappable so the user can retry immediately.
      if (mounted) setState(_startResendCooldown);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendFailed = true;
        _errorMessage = mapAuthError(e).message;
      });
    }
  }

  Future<void> _resend() async {
    // The link is already untappable while a send is in flight or the
    // cooldown is running; this guard just makes a stray call harmless.
    if (_resending || _coolingDown) return;
    setState(() {
      _resending = true;
      _status = _OtpStatus.empty;
      _errorMessage = null;
    });
    _pinController.clear();
    await _sendCode();
    if (!mounted) return;
    setState(() => _resending = false);
    if (!_sendFailed) {
      _pinFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رمز جديد إلى بريدك الإلكتروني.'),
        ),
      );
    }
  }

  void _onPinChanged(String value) {
    setState(() {
      _errorMessage = null;
      _status = value.isEmpty ? _OtpStatus.empty : _OtpStatus.filling;
    });
  }

  Future<void> _verify() async {
    if (!_isComplete || _status == _OtpStatus.loading) return;
    setState(() {
      _status = _OtpStatus.loading;
      _errorMessage = null;
    });

    try {
      // Must match the channel [_sendCode] used: a magic-link code is not
      // accepted as OtpType.signup, and vice versa.
      final verifyType = switch (widget.purpose) {
        OtpPurpose.signupConfirmation => OtpType.signup,
        OtpPurpose.reVerification => OtpType.email,
      };
      await Supabase.instance.client.auth
          .verifyOTP(email: widget.email, token: _code, type: verifyType)
          .timeout(const Duration(seconds: 15));
      // This screen is the *only* place the signup flag is ever set — it is
      // what later tells a real signup apart from an account that merely
      // looks confirmed because it went through password recovery. Both
      // purposes run it: the re-verification path exists precisely to set
      // this flag on an account where it was never stamped.
      //
      // Best-effort on purpose: the code was accepted and the session is
      // live, so a failure here must not strand someone on the OTP screen
      // with nothing left to verify. If it does fail, the next sign-in sees
      // signup_verified = false and offers the resend path, which lands
      // right back here — recoverable, unlike a dead end.
      try {
        await _profileService.markSignupVerified();
      } catch (e) {
        debugPrint('markSignupVerified failed after signup OTP: $e');
      }
      if (!mounted) return;
      setState(() => _status = _OtpStatus.success);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      // No signup-vs-reverification branch here any more: once the session
      // exists both cases ask the same question, and AuthGate answers it from
      // `onboarding_completed_at` alone.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      _handleFailure(
        mapOtpVerifyError(
          e,
          sinceCodeSent: DateTime.now().difference(_codeSentAt),
        ).message,
      );
    }
  }

  void _handleFailure(String message) {
    if (!mounted) return;
    // Pinput's controller fires onChanged on programmatic clears too, so
    // clearing first (while onChanged still resets to the empty/idle state)
    // and setting the failure state after keeps it from immediately
    // clobbering the banner and error theme this method is trying to show.
    _pinController.clear();
    setState(() {
      _status = _OtpStatus.failure;
      _errorMessage = message;
    });
    _pinFocusNode.requestFocus();
  }

  bool get _showBanner =>
      _errorMessage != null && (_sendFailed || _status == _OtpStatus.failure);

  // On a verify failure, _handleFailure already clears the field and
  // refocuses it — a retry action here would do nothing visible. Only a
  // send failure has something real to retry.
  VoidCallback? get _bannerRetry => _sendFailed ? _sendCode : null;

  @override
  Widget build(BuildContext context) {
    return AuthSheetScaffold(
      hero: _buildHero(),
      sheetPadding: const EdgeInsets.fromLTRB(26, 30, 26, 20),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: KeyedSubtree(
          key: ValueKey(_status == _OtpStatus.success),
          child: _status == _OtpStatus.success ? _buildSuccess() : _buildForm(),
        ),
      ),
      // Hidden once the code is accepted: the success state owns the sheet
      // for its 1200ms, and a spam-folder tip under a green checkmark is
      // advice about a problem that no longer exists.
      footer: _status == _OtpStatus.success ? null : _buildSpamHint(),
    );
  }

  /// Back chevron, heading, and the address the code actually went to.
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pops rather than pushing anything: this screen is always reached
          // by a push — from Sign Up after `signUp`, or from Sign In's
          // resend-a-code banner action — so back is whichever of those sent
          // the person here.
          AuthBackButton(onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 16),
          Text(
            'تأكيد البريد',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.display(
              size: 26,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                // Western digits, per the app-wide numerals default — the
                // source file reads "٦ أرقام".
                const TextSpan(text: 'أرسلنا رمزًا من 6 أرقام إلى\n'),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  // The address is Latin text inside an Arabic sentence, so
                  // it is force-wrapped LTR — otherwise the RTL run reorders
                  // its dots and @ and shows the person an address that is
                  // not the one the mail went to.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      widget.email,
                      style: AuroraText.body(
                        size: 14,
                        weight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            style: AuroraText.body(
              size: 14,
              weight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final disabled = _status == _OtpStatus.loading;
    final hasError = _status == _OtpStatus.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inline at the top of the sheet, the same placement Sign In and Sign
        // Up use — it no longer floats over the hero, where it covered the
        // heading and the address.
        if (_showBanner) ...[
          AuthErrorBanner(
            message: _errorMessage!,
            onRetry: _bannerRetry,
            onDismiss: () => setState(() {
              _errorMessage = null;
              _sendFailed = false;
            }),
          ),
          const SizedBox(height: 20),
        ],
        _buildPinInput(disabled: disabled, hasError: hasError),
        if (widget.passwordUnchanged) ...[
          const SizedBox(height: 18),
          _buildPasswordUnchangedNote(),
        ],
        const SizedBox(height: 26),
        AuthPrimaryButton(
          label: _status == _OtpStatus.loading ? 'جاري التحقق…' : 'تأكيد الرمز',
          loading: _status == _OtpStatus.loading,
          enabled: _isComplete,
          onPressed: (_isComplete && _status != _OtpStatus.loading)
              ? _verify
              : null,
        ),
        const SizedBox(height: 20),
        _buildResendBlock(),
      ],
    );
  }

  /// The typed sequence must assemble in true left-to-right numeric order
  /// regardless of the surrounding screen's RTL direction, or digits land in
  /// the wrong box and the wrong code gets sent to verifyOTP — so the pin
  /// field is force-wrapped LTR here, independent of the app's Arabic
  /// Directionality above it.
  Widget _buildPinInput({required bool disabled, required bool hasError}) {
    final defaultTheme = PinTheme(
      width: 44,
      height: 56,
      textStyle: AuroraText.body(
        size: 22,
        weight: FontWeight.w600,
        color: AuthColors.ink,
      ),
      decoration: BoxDecoration(
        color: AuthColors.fieldFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasError ? AuthColors.danger : AuthColors.fieldBorder,
          width: 1.5,
        ),
      ),
    );
    // Focus flips the fill to white as well as the border, matching every
    // other field on the surface.
    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasError ? AuthColors.danger : AuthColors.green,
          width: 1.5,
        ),
      ),
    );

    return Center(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Pinput(
          length: _digitCount,
          controller: _pinController,
          focusNode: _pinFocusNode,
          enabled: !disabled,
          autofocus: true,
          keyboardType: TextInputType.number,
          separatorBuilder: (_) => const SizedBox(width: 9),
          defaultPinTheme: defaultTheme,
          focusedPinTheme: focusedTheme,
          submittedPinTheme: defaultTheme,
          errorPinTheme: defaultTheme,
          forceErrorState: hasError,
          showCursor: true,
          onChanged: _onPinChanged,
          onCompleted: (_) => _verify(),
        ),
      ),
    );
  }

  /// Amber note for the re-signup case: the account already existed, so the
  /// password on it is still the original one.
  Widget _buildPasswordUnchangedNote() {
    const amber = AuroraColors.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'هذا الحساب مسجل بالفعل وبانتظار التفعيل، وأرسلنا لك رمزًا جديدًا. '
              'كلمة المرور لم تتغير — كلمة المرور الأصلية هي السارية.',
              style: AuroraText.body(
                size: 12.5,
                weight: FontWeight.w500,
                color: AuthColors.ink,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The timer line, and — only once it has run out — the resend button
  /// under it.
  ///
  /// Two stacked elements rather than one sentence with a tappable tail, as
  /// drawn: while the cooldown runs there is nothing to tap, so a link styled
  /// to look tappable would be a lie for its first 60 seconds.
  Widget _buildResendBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _resending
              ? 'جاري الإرسال…'
              : _coolingDown
              ? 'يمكنك إعادة الإرسال بعد $_resendSeconds ثانية'
              : 'لم يصلك الرمز؟',
          textAlign: TextAlign.center,
          style: AuroraText.body(
            size: 13,
            weight: FontWeight.w300,
            color: AuthColors.secondary,
          ),
        ),
        if (!_coolingDown && !_resending) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _resend,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.all(6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'إعادة إرسال الرمز',
                style: AuroraText.body(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: AuthColors.link,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpamHint() {
    return Text(
      'تحقّق من مجلد الرسائل غير المرغوب فيها\nإن لم يصلك الرمز',
      textAlign: TextAlign.center,
      style: AuroraText.body(
        size: 12.5,
        weight: FontWeight.w300,
        color: AuthColors.muted,
        height: 1.7,
      ),
    );
  }

  // Copy considered: "تم التحقق، أهلاً بيك" (this one) vs. the flatter
  // "تم التحقق بنجاح" and the more playful "اتأكد الرمز، يلا بينا" — this
  // reads warmest without tipping into filler, matching the surface's
  // calm-not-corporate tone.
  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AuroraColors.success,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'تم التحقق، أهلاً بيك',
            style: AuroraText.display(
              size: 18,
              weight: FontWeight.w700,
              color: AuthColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'بنجهز كل حاجة… لحظات وتوصل.',
            style: AuroraText.body(size: 13.5, color: AuthColors.secondary),
          ),
        ],
      ),
    );
  }
}
