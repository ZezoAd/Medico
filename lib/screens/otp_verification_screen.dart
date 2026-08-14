import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_error_banner.dart';
import 'home_screen.dart';

enum _OtpStatus { empty, filling, loading, success, failure }

/// Six-digit signup confirmation screen matching [SignInPage]'s visual
/// language. `signUp` (called before this screen is pushed) already sends
/// the "Confirm signup" email, so this screen only verifies what the user
/// types via `verifyOTP(type: OtpType.signup)`; resending re-sends that same
/// signup-confirmation email via `resend(type: OtpType.signup)`.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.passwordUnchanged = false,
  });

  final String email;

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
  static const _teal = Color(0xFF0D9488);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _fieldFill = Color(0xFFF1F5F9);
  static const _danger = Color(0xFFDC2626);
  static const _successGreen = Color(0xFF16A34A);
  static const _digitCount = 6;
  static const _resendCooldown = Duration(seconds: 60);

  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _profileService = const ProfileService();

  _OtpStatus _status = _OtpStatus.empty;
  String? _errorMessage;
  bool _resending = false;
  bool _sendFailed = false;
  bool _mounted = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
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
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
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
      await Supabase.instance.client.auth
          .verifyOTP(email: widget.email, token: _code, type: OtpType.signup)
          .timeout(const Duration(seconds: 15));
      // This screen is the *only* place the signup flag is ever set — it is
      // what later tells a real signup apart from an account that merely
      // looks confirmed because it went through password recovery.
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  bool get _showBanner => _errorMessage != null && (_sendFailed || _status == _OtpStatus.failure);

  // On a verify failure, _handleFailure already clears the field and
  // refocuses it — a retry action here would do nothing visible. Only a
  // send failure has something real to retry.
  VoidCallback? get _bannerRetry => _sendFailed ? _sendCode : null;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const Positioned.fill(child: _GradientBackdrop()),
            Positioned(
              top: -120,
              left: -100,
              child: _SoftCircle(size: 280, opacity: 0.06),
            ),
            Positioned(
              bottom: -80,
              right: -70,
              child: _SoftCircle(size: 220, opacity: 0.05),
            ),
            SafeArea(child: _buildBody()),
            if (_showBanner)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: AuthErrorBanner(
                      message: _errorMessage!,
                      onRetry: _bannerRetry,
                      onDismiss: () => setState(() {
                        _errorMessage = null;
                        _sendFailed = false;
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 44),
          _buildBrand(),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              offset: _mounted ? Offset.zero : const Offset(0, 0.05),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: _mounted ? 1 : 0,
                child: _buildCard(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Icons.monitor_heart_outlined,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'Medico',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: AnimatedSwitcher(
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
      ),
    );
  }

  Widget _buildForm() {
    final disabled = _status == _OtpStatus.loading;
    final hasError = _status == _OtpStatus.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تحقق من بريدك الإلكتروني',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _ink,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13.5, color: _muted, height: 1.5),
            children: [
              const TextSpan(text: 'أدخلنا رمزًا مكونًا من 6 أرقام إلى '),
              TextSpan(
                text: widget.email,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
        if (widget.passwordUnchanged) ...[
          const SizedBox(height: 14),
          _buildPasswordUnchangedNote(),
        ],
        const SizedBox(height: 24),
        _buildPinInput(disabled: disabled, hasError: hasError),
        const SizedBox(height: 24),
        _buildVerifyButton(),
        const SizedBox(height: 18),
        _buildResendRow(),
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
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? _danger : _border,
          width: 1.5,
        ),
      ),
    );
    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasError ? _danger : _teal, width: 2),
      ),
    );
    final submittedTheme = defaultTheme;

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
          separatorBuilder: (_) => const SizedBox(width: 8),
          defaultPinTheme: defaultTheme,
          focusedPinTheme: focusedTheme,
          submittedPinTheme: submittedTheme,
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
    const amber = Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.28)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'هذا الحساب مسجل بالفعل وبانتظار التفعيل، وأرسلنا لك رمزًا جديدًا. '
              'كلمة المرور لم تتغير — كلمة المرور الأصلية هي السارية.',
              style: TextStyle(
                fontSize: 12.5,
                color: _ink,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    final enabled = _isComplete && _status != _OtpStatus.loading;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF17B47F), Color(0xFF1E8FCB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: enabled ? 0.2 : 0.0),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        child: TextButton(
          onPressed: enabled ? _verify : null,
          style: TextButton.styleFrom(
            disabledBackgroundColor: _border,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_status == _OtpStatus.loading) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 9),
              ],
              Text(
                _status == _OtpStatus.loading ? 'جاري التحقق…' : 'تحقق',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.white : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'لم يصلك الرمز؟',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: (_resending || _coolingDown) ? null : _resend,
          child: Text(
            _resending
                ? 'جاري الإرسال…'
                : _coolingDown
                    ? 'إعادة الإرسال خلال $_resendSeconds'
                    : 'إعادة إرسال الرمز',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _coolingDown ? _muted : _teal,
            ),
          ),
        ),
      ],
    );
  }

  // Copy considered: "تم التحقق، أهلاً بيك" (this one) vs. the flatter
  // "تم التحقق بنجاح" and the more playful "اتأكد الرمز، يلا بينا" — this
  // reads warmest without tipping into filler, matching the Aurora sheet's
  // calm-not-corporate tone.
  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _successGreen,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 34,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'تم التحقق، أهلاً بيك',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'بنجهز كل حاجة… لحظات وتوصل.',
          style: TextStyle(fontSize: 13.5, color: _muted),
        ),
      ],
    );
  }
}

/// The 165° teal→blue canvas the whole screen sits on — mirrors
/// [SignInPage]'s backdrop so both screens read as one continuous surface.
class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.35, -1),
          end: Alignment(0.35, 1),
          colors: [Color(0xFF1D9E75), Color(0xFF227FAF), Color(0xFF2A93C9)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// Translucent decorative circle bleeding off the screen edges.
class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
