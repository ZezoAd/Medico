import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../theme/aurora_tokens.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_surface.dart';
import '../widgets/forgot_password_sheet.dart';
import 'auth_gate.dart';
import 'otp_verification_screen.dart';
import 'sign_up_screen.dart';

/// Sign In, as a full screen of its own.
///
/// It used to be one page of a `PageView` behind a tab pill, sharing a
/// gradient, a brand row and a banner slot with Sign Up. That shell is gone:
/// the two are separate routes now, each with its own gradient hero over its
/// own white sheet, reached by `Navigator.push` from [WelcomeScreen] or from
/// the other's footer.
///
/// Reached two ways, and both matter:
/// * تسجيل الدخول on Welcome — the ordinary path, no arguments.
/// * Forwarded from Welcome with [initialErrorMessage] set, when [AuthGate]
///   bounced someone here after a forced sign-out. That path is the reason
///   this screen still takes those two fields at all.
///
/// None of the Supabase calls, error mapping or OTP hand-offs below changed
/// when the shell did — only where they are drawn.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    this.initialErrorMessage,
    this.initialUnconfirmedEmail,
  });

  /// Shown as a banner at the top of the sheet as soon as this screen builds
  /// — used to explain a forced sign-out instead of silently bouncing here
  /// with no context.
  final String? initialErrorMessage;

  /// Set alongside [initialErrorMessage] when the sign-out that landed here
  /// was caused by an account that never finished signup verification — it
  /// gives that opening banner the same tappable "resend a code" action a
  /// failed sign-in would have, instead of a message with no way forward.
  final String? initialUnconfirmedEmail;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const _networkTimeout = Duration(seconds: 15);

  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  final _profileService = const ProfileService();

  bool _showPassword = false;
  bool _loading = false;
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
      // [AuthGate] is the only caller that sets this, and it only does so off
      // the `signup_verified` gate — reached with a live session, which
      // GoTrue only issues for an address it already considers confirmed. So
      // the signup channel is guaranteed to be a no-op here.
      _pendingOtpPurpose = OtpPurpose.reVerification;
    }
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    // No third "is any field focused" listener here any more. The footer's
    // collapse used to hang off one, and focus turned out to be the wrong
    // question: Android's back gesture hides the keyboard without unfocusing
    // anything, so the answer stayed `true` and the footer never came back.
    // [AuthSheetScaffold] watches the keyboard inset instead.
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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

  /// Only emptiness. Sign In deliberately does not hold a *typed* password to
  /// Sign Up's 8-character bar: an account created before that rule existed
  /// would be locked out of its own app by a client-side check, and the
  /// server is the authority on whether a password is right regardless.
  String? _validatePassword(String value) {
    return value.isEmpty ? 'الرجاء إدخال كلمة المرور' : null;
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

  void _clearBanner() {
    _banner = null;
    _pendingUnconfirmedEmail = null;
    _pendingOtpPurpose = OtpPurpose.signupConfirmation;
  }

  /// Clears a stale failure the moment the person starts fixing it.
  void _onFieldChanged() {
    if (_banner == null && _credentialsError == null) return;
    setState(() {
      _clearBanner();
      _credentialsError = null;
    });
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
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
        (route) => false,
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

  /// The banner's action. Only one case still carries one: an account that
  /// signed in correctly but never finished signup verification, which gets a
  /// "resend a code" way forward instead of a dead-end message.
  VoidCallback? get _bannerAction =>
      _pendingUnconfirmedEmail != null ? _resendConfirmation : null;

  String? get _bannerActionLabel =>
      _pendingUnconfirmedEmail != null ? 'إرسال رمز تحقق جديد' : null;

  /// Sends a fresh code and hands the person straight to the OTP screen to
  /// enter it, instead of leaving them stuck on a dead banner.
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
        MaterialPageRoute<void>(
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
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
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

  void _goSignUp() {
    // cameFromSignIn: this route is directly underneath, so Sign Up's footer
    // can pop back to it rather than pushing a second copy.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SignUpScreen(cameFromSignIn: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthSheetScaffold(
      hero: const AuthHero(
        heading: 'أهلاً بعودتك',
        subheading: 'سجّل دخولك لمتابعة مواعيدك',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBanner(),
          const AuthFieldLabel('البريد الإلكتروني'),
          const SizedBox(height: 7),
          AuthTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hint: 'أدخل بريدك الإلكتروني',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            hasError: _emailError != null || _credentialsError != null,
            onChanged: (_) => _onFieldChanged(),
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          AuthInlineError(_emailError),
          const SizedBox(height: 13),
          const AuthFieldLabel('كلمة المرور'),
          const SizedBox(height: 7),
          AuthTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hint: 'أدخل كلمة المرور',
            obscure: !_showPassword,
            textInputAction: TextInputAction.done,
            hasError: _passwordError != null || _credentialsError != null,
            onChanged: (_) => _onFieldChanged(),
            onSubmitted: (_) => _handleSubmit(),
            suffix: AuthPasswordToggle(
              visible: _showPassword,
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          AuthInlineError(_passwordError ?? _credentialsError),
          const SizedBox(height: 11),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              // Unchanged: the same modal sheet as before, which sends a
              // Supabase reset mail whose link opens the external reset page
              // at reset.medico.dpdns.org. Nothing about that flow is this
              // screen's business beyond opening the sheet.
              onPressed: () => showForgotPasswordSheet(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: AlignmentDirectional.centerStart,
              ),
              child: Text(
                'نسيت كلمة المرور؟',
                style: AuroraText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AuthColors.link,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthPrimaryButton(
            label: _loading ? 'جاري تسجيل الدخول…' : 'تسجيل الدخول',
            loading: _loading,
            onPressed: _loading ? null : _handleSubmit,
          ),
          const SizedBox(height: 14),
          const AuthOrDivider(),
          const SizedBox(height: 12),
          AuthGoogleButton(
            label: 'تسجيل الدخول باستخدام Google',
            onPressed: _loading ? null : _handleGoogle,
          ),
          const SizedBox(height: 12),
        ],
      ),
      // Folded away while the keyboard is up. The footer is anchored to the
      // sheet's bottom edge, and `resizeToAvoidBottomInset` moves that edge —
      // so left alone it climbs the screen behind the keyboard instead of
      // holding still. Nobody is reading "ليس لديك حساب؟" mid-typing, so it
      // steps out and the form gets the space.
      collapseFooterWithKeyboard: true,
      footer: AuthFooterPrompt(
        prompt: 'ليس لديك حساب؟',
        actionLabel: 'أنشئ حسابًا',
        onPressed: _goSignUp,
      ),
    );
  }

  /// The banner sits at the top of the sheet, in the scroll, rather than
  /// floating over the hero the way it did under the old shell.
  ///
  /// It is the design's placement and it is also the better one: over the
  /// hero it covered the heading, and it had to be published up to a parent
  /// through a `ValueNotifier` slot because the widget that owned the error
  /// was not the widget that drew it. Here the screen that has the error
  /// draws it, and the whole slot mechanism is gone.
  Widget _buildBanner() {
    final banner = _banner;
    if (banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AuthErrorBanner(
        message: banner.message,
        severity: banner.severity,
        onRetry: _bannerAction,
        retryLabel: _bannerActionLabel,
        onDismiss: () => setState(_clearBanner),
      ),
    );
  }
}
