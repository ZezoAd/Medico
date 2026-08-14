import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/forgot_password_sheet.dart';
import 'home_screen.dart';
import 'otp_verification_screen.dart';
import 'sign_up_screen.dart';

/// Sign-in screen ported from the "Medico Login - Glass" design.
///
/// The design is RTL Arabic: a teal→blue gradient canvas with two soft
/// decorative circles, a role switcher (مستخدم / طبيب), and a white card
/// holding the credential form. Submitting swaps the whole screen for a
/// success state.
class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    this.initialErrorMessage,
    this.initialUnconfirmedEmail,
  });

  /// Shown as a dismissible banner as soon as this screen builds — used by
  /// [SplashScreen] to explain a forced sign-out instead of silently
  /// bouncing here with no context.
  final String? initialErrorMessage;

  /// Set alongside [initialErrorMessage] when the sign-out that landed here
  /// was caused by an account that never finished signup verification — it
  /// gives that opening banner the same tappable "resend a code" action a
  /// failed sign-in would have, instead of a message with no way forward.
  final String? initialUnconfirmedEmail;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

enum _Role { patient, doctor }

class _SignInPageState extends State<SignInPage> {
  static const _teal = Color(0xFF0D9488);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _faint = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _fieldFill = Color(0xFFF1F5F9);
  static const _danger = Color(0xFFDC2626);

  static const _networkTimeout = Duration(seconds: 15);

  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  final _profileService = const ProfileService();

  // Recognizers for the inline links in the footer rich-text runs.
  final _signupTap = TapGestureRecognizer();
  final _termsTap = TapGestureRecognizer();
  final _privacyTap = TapGestureRecognizer();

  _Role _role = _Role.patient;
  bool _showPassword = false;
  bool _loading = false;
  bool _success = false;
  bool _mounted = false;
  String? _emailError;
  String? _passwordError;
  AuthErrorInfo? _banner;

  /// Set instead of [_banner] when Supabase rejects the email/password pair
  /// — shown as a shared inline message under the password field, with both
  /// fields marked red, since Supabase won't say which one was wrong.
  String? _credentialsError;

  /// The email that just failed sign-in with "email not confirmed" — set
  /// alongside [_banner] so its retry action knows which address to resend
  /// a code to. Cleared whenever the banner is cleared.
  String? _pendingUnconfirmedEmail;
  bool _resendingConfirmation = false;

  bool get _isDoctor => _role == _Role.doctor;

  double get _screenHeight => MediaQuery.sizeOf(context).height;

  /// Short phones (iPhone SE and friends) get tighter controls so the
  /// column still fits once the spacers between groups have collapsed.
  bool get _compact => _screenHeight < 700;

  /// Continuous interpolation between the 44dp accessibility-minimum tap
  /// target and the 54dp comfortable size, instead of rigid if/else tiers -
  /// clamped at both ends so it never drops below 44dp on any phone.
  double get _controlHeight {
    final t = ((_screenHeight - 560) / (760 - 560)).clamp(0.0, 1.0);
    return 44.0 + (54.0 - 44.0) * t;
  }

  /// Tight typographic gaps (heading → subheading, label → field) - scales
  /// gently with viewport height instead of a flat magic number.
  double get _tightGap => (_screenHeight * 0.008).clamp(6.0, 10.0);

  /// Structural gaps between fields, buttons, and dividers inside the card,
  /// so it "breathes" proportionally instead of using one fixed pixel value
  /// that's cramped on small phones and stingy on large ones.
  double get _innerGap => (_screenHeight * 0.015).clamp(12.0, 24.0);

  // The card fades and slides in shortly after the first frame.
  @override
  void initState() {
    super.initState();
    if (widget.initialErrorMessage != null) {
      _banner = AuthErrorInfo(
        widget.initialErrorMessage!,
        severity: widget.initialUnconfirmedEmail != null
            ? AuthErrorSeverity.warning
            : AuthErrorSeverity.error,
      );
      _pendingUnconfirmedEmail = widget.initialUnconfirmedEmail;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
    _signupTap.onTap = () {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
    };
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _signupTap.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _setRole(_Role role) {
    setState(() => _role = role);
  }

  /// Empty → required copy, non-empty-but-malformed → format copy. Runs on
  /// blur and on submit, never on every keystroke.
  String? _validateEmail(String value) {
    if (value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    if (!_emailPattern.hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  /// Mirrors Sign Up's strength rule so a password is held to the same bar
  /// everywhere it's typed.
  String? _validatePassword(String value) {
    if (value.isEmpty) return 'الرجاء إدخال كلمة المرور';
    return value.length >= 8 ? null : 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
  }

  void _onEmailFocusChange() {
    if (_emailFocusNode.hasFocus) return;
    final error = _validateEmail(_emailController.text.trim());
    if (error != _emailError) setState(() => _emailError = error);
  }

  void _onPasswordFocusChange() {
    if (_passwordFocusNode.hasFocus) return;
    final error = _validatePassword(_passwordController.text);
    if (error != _passwordError) setState(() => _passwordError = error);
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);
    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() {
      _clearBanner();
      _credentialsError = null;
      _loading = true;
    });

    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password)
          .timeout(_networkTimeout);
      // The طبيب/مستخدم tab above only picks the heading copy — the account's
      // real role lives in `profiles.role`, so signing in under the wrong tab
      // still succeeds and still lands wherever the database says it should.
      final profile = await _profileService.fetchCurrentProfile();
      // The password was right, but that is not the same as having finished
      // signup. Someone who abandoned the OTP screen and used forgot-password
      // instead looks fully confirmed to Supabase, so the app's own flag is
      // what stops them here — signed out again before they ever reach Home.
      if (profile != null && !profile.signupVerified) {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        setState(() {
          _banner = const AuthErrorInfo(
            emailNotConfirmedMessage,
            severity: AuthErrorSeverity.warning,
          );
          _pendingUnconfirmedEmail = email;
        });
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _destination(profile)),
      );
    } catch (e) {
      if (!mounted) return;
      // Supabase deliberately won't say which of the two was wrong (email
      // enumeration protection), so this goes inline on both fields rather
      // than guessing; email-not-confirmed gets a "resend code" action
      // instead of a dead-end banner; everything else stays a top banner.
      if (isInvalidCredentialsError(e)) {
        setState(() => _credentialsError = mapAuthError(e).message);
      } else if (isEmailNotConfirmedError(e)) {
        setState(() {
          _banner = mapAuthError(e);
          _pendingUnconfirmedEmail = email;
        });
      } else {
        setState(() => _banner = mapAuthError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearBanner() {
    _banner = null;
    _pendingUnconfirmedEmail = null;
  }

  /// The sign-in banner's action for an unconfirmed account — resends the
  /// signup confirmation code and hands the person straight to the OTP
  /// screen to enter it, instead of leaving them stuck on a dead banner.
  Future<void> _resendConfirmation() async {
    final email = _pendingUnconfirmedEmail;
    if (email == null || _resendingConfirmation) return;
    setState(() => _resendingConfirmation = true);
    try {
      await Supabase.instance.client.auth
          .resend(type: OtpType.signup, email: email)
          .timeout(_networkTimeout);
      if (!mounted) return;
      setState(_clearBanner);
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _banner = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _resendingConfirmation = false);
    }
  }

  /// Both roles land on [HomeScreen] for now — the doctor-side dashboard
  /// doesn't exist yet. The branch stays here so adding it is a one-line
  /// change, and so the destination is visibly driven by [UserProfile.role]
  /// rather than by the tab the user happened to be on.
  Widget _destination(UserProfile? profile) {
    return switch (profile?.role) {
      UserRole.doctor => const HomeScreen(),
      UserRole.patient || null => const HomeScreen(),
    };
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _clearBanner();
      _credentialsError = null;
      _loading = true;
    });

    try {
      // Native Google sign-in hands back an ID token, which Supabase exchanges
      // for a session directly — no browser round-trip, no redirect URL.
      final googleUser = await GoogleSignIn.instance.authenticate().timeout(
        _networkTimeout,
      );
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw Exception('لم يتم استلام رمز الدخول من Google.');
      }
      await Supabase.instance.client.auth
          .signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)
          .timeout(_networkTimeout);
      // Google already proved ownership of the address, so there is no OTP
      // step to complete. The trigger in 004_signup_verified.sql stamps this
      // at row-creation time; this repeats it client-side because a false
      // negative there would lock a legitimate Google user out of the app
      // entirely, and the call is idempotent and cheap.
      await _profileService.markSignupVerified();
      final profile = await _profileService.fetchCurrentProfile();
      if (!mounted) return;
      // Clears the auth stack: there's nothing to come back to once signed in.
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => _destination(profile)),
        (route) => false,
      );
    } on GoogleSignInException catch (e) {
      // Backing out of the account picker isn't an error worth reporting.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      debugPrint('Google sign-in error: $e');
      if (!mounted) return;
      setState(() => _banner = mapAuthError(e));
    } catch (e, stackTrace) {
      debugPrint('Google sign-in error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() => _banner = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _success = false;
      _emailError = null;
      _passwordError = null;
      _credentialsError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Let the keyboard resize the body so the scroll view below can
        // bring a focused field above it instead of the keyboard covering it.
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              const Positioned.fill(child: _GradientBackdrop()),
              // Top-left circle (RTL: visually the trailing side of the header).
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
              SafeArea(child: _success ? _buildSuccess() : _buildForm()),
              if (_banner != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: AuthErrorBanner(
                        message: _banner!.message,
                        severity: _banner!.severity,
                        onRetry: _pendingUnconfirmedEmail != null
                            ? _resendConfirmation
                            : null,
                        retryLabel: _pendingUnconfirmedEmail != null
                            ? 'إرسال رمز تحقق جديد'
                            : null,
                        onDismiss: () => setState(_clearBanner),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── success state ─────────────────────────────

  Widget _buildSuccess() {
    final note = _isDoctor
        ? 'جاري تحويلك إلى لوحة تحكم عيادتك.'
        : 'جاري تحويلك إلى مواعيدك وحالة الطابور المباشرة.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'تم تسجيل الدخول بنجاح',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                note,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 26),
            TextButton(
              onPressed: _reset,
              child: const Text(
                'الرجوع لتسجيل الدخول',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────── form state ───────────────────────────────

  Widget _buildForm() {
    // "Holy Grail" responsive pattern: LayoutBuilder feeds the viewport
    // height to a ConstrainedBox(minHeight:) inside a SingleChildScrollView,
    // so the content centres on tall screens and scrolls on short ones.
    //
    // Centring is done with MainAxisAlignment.center rather than a pair of
    // Spacers under an IntrinsicHeight. That earlier shape overflowed for the
    // duration of every inline-error animation: IntrinsicHeight pinned the
    // Column to the sum of its children's *target* intrinsic heights, while
    // the error row's AnimatedSize was still painting an in-flight height on
    // the way to that target. Collapsing errors therefore left the Column
    // laid out shorter than what it was actually painting, and the Spacers
    // had no slack left to absorb the difference on a full screen.
    //
    // With no flex children the Column simply takes max(content, viewport)
    // from the ConstrainedBox, so a mid-animation residual is free space
    // rather than an overflow, and nothing queries intrinsics at all.
    //
    // minTopGap/minBottomGap are flat constants, never derived from
    // constraints or MediaQuery, so they can never shrink below 24px no
    // matter the screen size or content height.
    return LayoutBuilder(
      builder: (context, constraints) {
        final brandToTabs = (constraints.maxHeight * 0.015).clamp(10.0, 16.0);
        final tabsToCard = (constraints.maxHeight * 0.025).clamp(16.0, 24.0);
        const minTopGap = 24.0;
        const minBottomGap = 24.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: minTopGap),
                  _buildBrand(),
                  SizedBox(height: brandToTabs),
                  _buildRoleTabs(),
                  SizedBox(height: tabsToCard),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    offset: _mounted ? Offset.zero : const Offset(0, 0.05),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _mounted ? 1 : 0,
                      child: _buildCard(),
                    ),
                  ),
                  const SizedBox(height: minBottomGap),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _buildRoleTabs() {
    // Fixed outer height (38 tab + 4+4 padding). Nothing queries intrinsics
    // any more now that _buildForm centres without IntrinsicHeight, but the
    // tab strip is a fixed-height control regardless, so it stays pinned
    // here rather than being re-derived from the slider's inner layout.
    return SizedBox(height: 46, child: _roleTabsContent());
  }

  Widget _roleTabsContent() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return SizedBox(
            height: 38,
            child: Stack(
              children: [
                // Sliding white pill behind the active tab.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  right: _isDoctor ? tabWidth : 0,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _roleTab('مستخدم', _Role.patient),
                    _roleTab('طبيب', _Role.doctor),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _roleTab(String label, _Role role) {
    final active = _role == role;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setRole(role),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active
                  ? const Color(0xFF12664C)
                  : Colors.white.withValues(alpha: 0.8),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    final heading = _isDoctor ? 'أهلاً دكتور' : 'أهلاً بيك';
    final subheading = _isDoctor
        ? 'تابع مواعيد عيادتك وطابور مرضاك من مكان واحد.'
        : 'انتظار العيادة صار من الماضي — تابع دورك من أي مكان.';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _compact ? 20 : 24,
        vertical: _compact ? 20 : 28,
      ),
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
      // The outer page scrolls as a whole now, so the card just sizes to its
      // content instead of scrolling internally.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            heading,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _compact ? 20 : 23,
              fontWeight: FontWeight.w700,
              color: _ink,
              height: 1.3,
            ),
          ),
          SizedBox(height: _tightGap),
          Text(
            subheading,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: _muted, height: 1.5),
          ),
          SizedBox(height: _innerGap),
          _fieldLabel('البريد الإلكتروني'),
          SizedBox(height: _tightGap),
          _buildInput(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hint: 'أدخل بريدك الإلكتروني',
            icon: Icons.mail_outline_rounded,
            hasError: _emailError != null || _credentialsError != null,
            keyboardType: TextInputType.emailAddress,
          ),
          _buildFieldError(_emailError),
          SizedBox(height: _innerGap),
          _fieldLabel('كلمة المرور'),
          SizedBox(height: _tightGap),
          _buildInput(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hint: 'أدخل كلمة المرور',
            icon: Icons.lock_outline_rounded,
            hasError: _passwordError != null || _credentialsError != null,
            obscure: !_showPassword,
            suffix: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              tooltip: _showPassword
                  ? 'إخفاء كلمة المرور'
                  : 'إظهار كلمة المرور',
              icon: Icon(
                _showPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 22,
                color: _faint,
              ),
            ),
          ),
          _buildFieldError(_passwordError ?? _credentialsError),
          SizedBox(height: _innerGap * 0.5),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: () => showForgotPasswordSheet(context),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _teal,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: _innerGap),
          _buildSubmitButton(),
          SizedBox(height: _innerGap),
          _buildDivider(),
          SizedBox(height: _innerGap),
          _buildGoogleButton(),
          // Doctors are onboarded manually via the separate mini-app — no
          // self-serve signup, so this only appears on the patient tab.
          if (!_isDoctor) ...[
            SizedBox(height: _innerGap),
            _buildSignupPrompt(),
          ],
          SizedBox(height: _tightGap),
          _buildLegalNote(),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _muted,
        letterSpacing: 0.1,
      ),
    );
  }

  /// The error line under a field - collapses to zero height when there's
  /// nothing to show instead of popping in/out instantly, so the controls
  /// below (e.g. "نسيت كلمة المرور؟", the submit button) shift smoothly.
  Widget _buildFieldError(String? error) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      curve: Curves.easeOut,
      child: error == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 13, color: _danger),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool hasError,
    FocusNode? focusNode,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    final baseBorder = hasError ? _danger : _border;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );

    return SizedBox(
      height: _controlHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: (_) {
          if (_banner != null || _credentialsError != null) {
            setState(() {
              _clearBanner();
              _credentialsError = null;
            });
          }
        },
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: _faint,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: _fieldFill,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Icon(icon, size: 18, color: _faint),
          prefixIconConstraints: BoxConstraints(
            minWidth: 40,
            minHeight: _controlHeight,
          ),
          suffixIcon: suffix,
          enabledBorder: border(baseBorder, 1.5),
          border: border(baseBorder, 1.5),
          focusedBorder: border(hasError ? _danger : _teal, 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: _controlHeight,
        child: TextButton(
          onPressed: _loading ? null : _handleSubmit,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loading) ...[
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
              Flexible(
                child: Text(
                  _loading ? 'جاري تسجيل الدخول…' : 'تسجيل الدخول',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(height: 1, color: _border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'أو',
            style: TextStyle(
              fontSize: 11.5,
              color: _faint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(height: 1, color: _border)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: _controlHeight,
      child: OutlinedButton(
        onPressed: _loading ? null : _handleGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF747775)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: SvgPicture.asset('assets/icons/google_logo.svg'),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'الاستمرار باستخدام Google',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Only reached from the patient tab — doctors are onboarded manually via
  // the separate mini-app and never see a signup prompt here.
  Widget _buildSignupPrompt() {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'مستخدم جديد؟'),
          const TextSpan(text: ' '),
          TextSpan(
            text: 'إنشاء حساب',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _teal,
            ),
            recognizer: _signupTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, color: _muted),
    );
  }

  // The design pins this to a single line (white-space:nowrap). Rather than
  // truncating with an ellipsis when it doesn't fit (e.g. at a larger system
  // font scale), it's scaled down as a whole so the full sentence stays
  // legible instead of being cut off.
  Widget _buildLegalNote() {
    const linkStyle = TextStyle(
      fontSize: 11.5,
      color: _teal,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: _teal,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'بالمتابعة، أنت توافق على '),
            TextSpan(text: 'الشروط', style: linkStyle, recognizer: _termsTap),
            const TextSpan(text: 'و'),
            TextSpan(
              text: 'سياسة الخصوصية',
              style: linkStyle,
              recognizer: _privacyTap,
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(fontSize: 11.5, color: _faint),
      ),
    );
  }
}

/// The 165° teal→blue canvas the whole screen sits on.
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
