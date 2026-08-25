import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../theme/aurora_tokens.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/forgot_password_sheet.dart';
import 'auth_gate.dart';
import 'auth_shell.dart';
import 'otp_verification_screen.dart';

/// Sign-in screen ported from the "Medico Login - Glass" design.
///
/// The design is RTL Arabic: a teal→blue gradient canvas with two soft
/// decorative circles, a تسجيل الدخول / إنشاء حساب switcher, and a white card
/// holding the credential form.
///
/// That switcher used to be a مستخدم / طبيب role toggle. Doctors sign in
/// through a separate Flutter app entirely, so the toggle was picking heading
/// copy and nothing else — the account's real role has always lived in
/// `profiles.role`. The control was kept and repointed at Sign In vs Sign Up,
/// which gives sign-up equal footing instead of one small link at the bottom
/// of the card.
class SignInPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AuthShell(
      initialTab: 0,
      initialErrorMessage: initialErrorMessage,
      initialUnconfirmedEmail: initialUnconfirmedEmail,
    );
  }
}

/// The sign-in credential form, without any surrounding chrome.
///
/// Everything outside the white card — gradient, brand, tab switcher, banner
/// slot — belongs to [AuthShell], which hosts this and [SignUpForm] as the two
/// pages of one sliding [PageView]. This widget renders only what actually
/// moves during a tab switch.
class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
    required this.banner,
    this.initialErrorMessage,
    this.initialUnconfirmedEmail,
  });

  /// Where this form publishes its error banner for the shell to draw.
  final AuthBannerSlot banner;

  final String? initialErrorMessage;
  final String? initialUnconfirmedEmail;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm>
    with AutomaticKeepAliveClientMixin {
  /// Keeps this form mounted while the *other* tab is showing.
  ///
  /// A `PageView` builds pages lazily and drops them once they leave the
  /// viewport, which for a form means its `TextEditingController`s go with it:
  /// type an email, glance at the other tab, come back, and the field is
  /// empty. Keeping both alive is also what lets the slide show two real forms
  /// moving as one track instead of one form and a blank page.
  @override
  bool get wantKeepAlive => true;

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
  final _termsTap = TapGestureRecognizer();
  final _privacyTap = TapGestureRecognizer();

  bool _showPassword = false;
  bool _loading = false;
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

  /// Which OTP channel [_resendConfirmation] should use for
  /// [_pendingUnconfirmedEmail]. Set together with that field at every site
  /// that populates it, because the two cases need different GoTrue calls and
  /// are indistinguishable once the banner is on screen — see [OtpPurpose].
  OtpPurpose _pendingOtpPurpose = OtpPurpose.signupConfirmation;
  bool _resendingConfirmation = false;

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

  /// Republishes the banner on every state change.
  ///
  /// Overriding [setState] rather than calling a publish helper at each of the
  /// ~10 sites that touch [_banner]: every one of them already goes through
  /// setState, so this cannot be forgotten at a new one, and it always reads
  /// [_bannerAction]/[_bannerActionLabel] *after* the mutation rather than
  /// capturing a value that a later line in the same block invalidates.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _publishBanner();
  }

  void _publishBanner() {
    final banner = _banner;
    widget.banner.value = banner == null
        ? null
        : AuthBannerData(
            info: banner,
            action: _bannerAction,
            actionLabel: _bannerActionLabel,
            onDismiss: () => setState(_clearBanner),
          );
  }

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
      // [SplashScreen] is the only caller that sets this, and it only does so
      // off the `signup_verified` gate — reached with a live session, which
      // GoTrue only issues for an address it already considers confirmed. So
      // the signup channel is guaranteed to be a no-op here.
      _pendingOtpPurpose = OtpPurpose.reVerification;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
    // initState sets _banner directly, ahead of any setState, so the opening
    // banner needs one explicit publish. Deferred because the shell's slot is
    // read during its build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishBanner();
    });
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
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
    return value.length >= 8
        ? null
        : 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
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
      // Fetched for the signup-verified check below. The account's role is
      // not consulted here at all — `profiles.role` is the only authority on
      // that, and this screen no longer asks the person to declare one.
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
          // Reaching this line means signInWithPassword just succeeded, which
          // GoTrue only allows for a confirmed address — so this account is
          // confirmed on its side and unverified on ours, the one combination
          // the signup resend channel silently refuses to serve.
          _pendingOtpPurpose = OtpPurpose.reVerification;
        });
        return;
      }
      if (!mounted) return;
      await Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
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
          // GoTrue itself says the address is unconfirmed, so there really is
          // a pending signup confirmation to resend — the original flow, which
          // works and is deliberately left alone.
          _pendingOtpPurpose = OtpPurpose.signupConfirmation;
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
    _pendingOtpPurpose = OtpPurpose.signupConfirmation;
  }

  /// The banner's action. Only one case still carries one: an account that
  /// signed in correctly but never finished signup verification, which gets a
  /// "resend a code" way forward instead of a dead-end message.
  VoidCallback? get _bannerAction {
    if (_pendingUnconfirmedEmail != null) return _resendConfirmation;
    return null;
  }

  String? get _bannerActionLabel {
    if (_pendingUnconfirmedEmail != null) return 'إرسال رمز تحقق جديد';
    return null;
  }

  /// The sign-in banner's action for an account that still needs to verify
  /// its email — sends a fresh code and hands the person straight to the OTP
  /// screen to enter it, instead of leaving them stuck on a dead banner.
  ///
  /// The channel depends on [_pendingOtpPurpose]: an account GoTrue already
  /// considers confirmed cannot be served by the signup resend, which returns
  /// 200 having sent nothing. [OtpPurpose] has the details.
  Future<void> _resendConfirmation() async {
    final email = _pendingUnconfirmedEmail;
    if (email == null || _resendingConfirmation) return;
    final purpose = _pendingOtpPurpose;
    setState(() => _resendingConfirmation = true);
    try {
      final auth = Supabase.instance.client.auth;
      switch (purpose) {
        case OtpPurpose.signupConfirmation:
          await auth
              .resend(type: OtpType.signup, email: email)
              .timeout(_networkTimeout);
        case OtpPurpose.reVerification:
          await auth
              .signInWithOtp(email: email, shouldCreateUser: false)
              .timeout(_networkTimeout);
      }
      if (!mounted) return;
      setState(_clearBanner);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: email, purpose: purpose),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _banner = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _resendingConfirmation = false);
    }
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
      //
      // Deliberately not wrapped in [_networkTimeout], unlike every other call
      // in this file. This one blocks on a human reading a native account
      // picker, not on the network, and someone may sit on that screen for as
      // long as they like. Timing it out reported "no internet" to a person
      // who was merely still choosing. The timeout below covers the part that
      // is actually a network round-trip.
      final googleUser = await GoogleSignIn.instance.authenticate();
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
      // No profile read here any more: it existed only to answer the
      // doctor-tab question. AuthGate fetches the row itself on the very next
      // frame, so doing it here too was a duplicate round trip.
      if (!mounted) return;
      // Clears the auth stack: there's nothing to come back to once signed in.
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
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

  @override
  Widget build(BuildContext context) {
    // Required by AutomaticKeepAliveClientMixin.
    super.build(context);
    return _buildForm();
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
        const minTopGap = 24.0;
        const minBottomGap = 24.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: minTopGap),
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
        );
      },
    );
  }

  Widget _buildCard() {
    const heading = 'أهلاً بعودتك';
    // The old pitch line ("انتظار العيادة صار من الماضي…") moved to Sign Up,
    // where a first-time visitor is the one who needs convincing. Someone
    // already returning to sign in does not.
    const subheading = 'سجّل دخولك وتابع دورك وحجوزاتك من مكان واحد.';

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
            color: AuroraColors.ink.withValues(alpha: 0.08),
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
              color: AuroraColors.ink,
              height: 1.3,
            ),
          ),
          SizedBox(height: _tightGap),
          Text(
            subheading,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: AuroraColors.secondary,
              height: 1.5,
            ),
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
                color: AuroraColors.muted,
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
                    color: AuroraColors.primary,
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
          // No "مستخدم جديد؟ إنشاء حساب" line here any more — the إنشاء حساب
          // tab above goes to the same place, and two routes to one screen on
          // one card is just clutter.
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
        color: AuroraColors.secondary,
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
                  const Icon(
                    Icons.error_outline,
                    size: 13,
                    color: AuroraColors.danger,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AuroraColors.danger,
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
    final baseBorder = hasError ? AuroraColors.danger : AuroraColors.divider;

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
          // Typing clears a stale failure.
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
          color: AuroraColors.ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AuroraColors.muted,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AuroraColors.tonal,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Icon(icon, size: 18, color: AuroraColors.muted),
          prefixIconConstraints: BoxConstraints(
            minWidth: 40,
            minHeight: _controlHeight,
          ),
          suffixIcon: suffix,
          enabledBorder: border(baseBorder, 1.5),
          border: border(baseBorder, 1.5),
          focusedBorder: border(
            hasError ? AuroraColors.danger : AuroraColors.primary,
            2,
          ),
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
        Expanded(child: Divider(height: 1, color: AuroraColors.divider)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'أو',
            style: TextStyle(
              fontSize: 11.5,
              color: AuroraColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(height: 1, color: AuroraColors.divider)),
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
                  color: AuroraColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The design pins this to a single line (white-space:nowrap). Rather than
  // truncating with an ellipsis when it doesn't fit (e.g. at a larger system
  // font scale), it's scaled down as a whole so the full sentence stays
  // legible instead of being cut off.
  Widget _buildLegalNote() {
    const linkStyle = TextStyle(
      fontSize: 11.5,
      color: AuroraColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AuroraColors.primary,
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
        style: const TextStyle(fontSize: 11.5, color: AuroraColors.muted),
      ),
    );
  }
}
