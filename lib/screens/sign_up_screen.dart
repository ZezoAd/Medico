import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../theme/aurora_tokens.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_surface.dart';
import 'auth_gate.dart';
import 'otp_verification_screen.dart';
import 'sign_in_screen.dart';

/// Sign Up, as a full screen of its own — the mirror of [SignInScreen].
///
/// Submitting creates the Supabase account and hands off to
/// [OtpVerificationScreen] to verify the address. That hand-off, and every
/// piece of reasoning around what `signUp` returns, is untouched from the
/// tab-shell version; only the chrome around it changed.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.cameFromSignIn = false});

  /// True when [SignInScreen] pushed this route, i.e. Sign In is sitting
  /// directly underneath it.
  ///
  /// It decides what the footer's تسجيل الدخول does. Popping is right when
  /// Sign In is already below — it reuses the live route and keeps the stack
  /// flat. When this screen was pushed from Welcome instead, there is nothing
  /// to pop back to but Welcome, so the footer replaces this route with a
  /// fresh Sign In. Either way the person ends up on Sign In with Welcome
  /// one step below, and the stack never grows by bouncing between the two.
  final bool cameFromSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static const _networkTimeout = Duration(seconds: 15);

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _showPassword = false;
  bool _loading = false;
  bool _agreedToTerms = false;

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  AuthErrorInfo? _banner;

  @override
  void initState() {
    super.initState();
    _fullNameFocusNode.addListener(_onFullNameFocusChange);
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateFullName(String value) {
    return value.isEmpty ? 'الرجاء إدخال الاسم الكامل.' : null;
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

  /// Length only. There is deliberately no character-composition rule: any
  /// eight characters pass, letters-only and digits-only included.
  ///
  /// This inline error is also the *only* feedback a password gets. The
  /// design's three-segment strength meter was built and then removed, so
  /// nothing else on this screen rates or comments on what was typed.
  String? _validatePassword(String value) {
    if (value.isEmpty) return 'الرجاء إدخال كلمة المرور';
    return value.length >= 8
        ? null
        : 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
  }

  void _onFullNameFocusChange() {
    if (_fullNameFocusNode.hasFocus) return;
    final error = _validateFullName(_fullNameController.text.trim());
    if (error != _fullNameError) setState(() => _fullNameError = error);
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

  bool _validate() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _fullNameError = _validateFullName(fullName);
      _emailError = _validateEmail(email);
      _passwordError = _validatePassword(password);
    });

    return _fullNameError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  /// True when `signUp` quietly did nothing because the address already
  /// belongs to a confirmed account.
  ///
  /// With Supabase's email-enumeration protection enabled, that case is not
  /// an error: the call returns 200 with an obfuscated user — fabricated id,
  /// no session, and, the one reliable tell, an **empty** `identities` list —
  /// and no email is sent. A real new signup comes back with exactly one
  /// identity. Navigating to [OtpVerificationScreen] here would park the
  /// person in front of a code that is never going to arrive.
  ///
  /// A null `identities` means the field was absent rather than empty, which
  /// is not the same signal, so it deliberately does not count.
  bool _isAlreadyRegistered(AuthResponse response) {
    final identities = response.user?.identities;
    return identities != null && identities.isEmpty;
  }

  /// True when `signUp` resent a confirmation for an account that already
  /// existed *unverified*, rather than creating a new one.
  ///
  /// GoTrue deliberately does not overwrite an existing unconfirmed user's
  /// password ("do not update the user because we can't be sure of their
  /// claimed identity"), and it resends the code instead. Unlike the
  /// already-*confirmed* case above, the user it returns is the real row —
  /// real id, one real identity — so [_isAlreadyRegistered] cannot see it
  /// and the flow continues to [OtpVerificationScreen] as if nothing were
  /// unusual.
  ///
  /// That matters because the password just typed is *not* the one now on
  /// the account. The original still is. Signing in with the new one comes
  /// back as `invalid_credentials`, because GoTrue checks the password
  /// before it ever checks confirmation state — indistinguishable from a
  /// plain typo, and the reason this case looked like a mis-mapped error.
  ///
  /// The tell is the gap between when the row was created and when this
  /// code was sent. Both timestamps come from the server, so unlike a
  /// comparison against the device clock this cannot be thrown off by a
  /// phone with a wrong time — which matters, because a false positive here
  /// tells someone their password did not take when it did.
  ///
  /// A genuinely new account has the two within the same request (~2s).
  /// A resend can only be more than a minute later regardless, because
  /// GoTrue rejects a repeat send to the same address inside its own
  /// per-address cooldown with a 429, so a *successful* resend is always
  /// well past this threshold.
  bool _isPreexistingUnverified(AuthResponse response) {
    final user = response.user;
    final createdAt = DateTime.tryParse(user?.createdAt ?? '');
    final sentAt = DateTime.tryParse(user?.confirmationSentAt ?? '');
    if (createdAt == null || sentAt == null) return false;
    return sentAt.toUtc().difference(createdAt.toUtc()) >
        const Duration(seconds: 30);
  }

  Future<void> _handleSubmit() async {
    setState(() => _banner = null);
    if (!_validate()) return;

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth
          .signUp(
            email: email,
            password: password,
            data: {'full_name': fullName},
          )
          .timeout(_networkTimeout);
      if (!mounted) return;
      if (_isAlreadyRegistered(response)) {
        setState(
          () => _banner = const AuthErrorInfo(
            accountAlreadyExistsMessage,
            severity: AuthErrorSeverity.warning,
          ),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(
            email: email,
            passwordUnchanged: _isPreexistingUnverified(response),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _banner = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Mirrors [SignInScreen]'s _handleGoogle: with Google there's no separate
  // sign-up step — the first successful token exchange creates the account,
  // so both buttons run the same flow and land in the same place.
  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _banner = null;
      _loading = true;
    });

    try {
      // Not wrapped in [_networkTimeout]: this waits on a person reading the
      // native account picker, which has no bounded duration and is not a
      // network call. Timing it out surfaced a false "no internet" banner
      // while they were still choosing. See the same note in [SignInScreen].
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
      await const ProfileService().markSignupVerified();
      if (!mounted) return;
      // Routing is AuthGate's call, not this screen's — Google and email
      // signups must not answer the same question two different ways.
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

  void _goSignIn() {
    if (widget.cameFromSignIn) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    );
  }

  void _onFieldChanged() {
    if (_banner != null) setState(() => _banner = null);
  }

  @override
  Widget build(BuildContext context) {
    return AuthSheetScaffold(
      hero: const AuthHero(
        heading: 'إنشاء حساب',
        subheading: 'خطوة واحدة وتبدأ الحجز',
        headingSize: 26,
        subheadingSize: 13.5,
        padding: EdgeInsets.fromLTRB(28, 30, 28, 22),
      ),
      sheetPadding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBanner(),
          const AuthFieldLabel('الاسم الكامل'),
          const SizedBox(height: 7),
          AuthTextField(
            controller: _fullNameController,
            focusNode: _fullNameFocusNode,
            hint: 'مثال: سارة العامري',
            height: 46,
            radius: 15,
            textInputAction: TextInputAction.next,
            hasError: _fullNameError != null,
            onChanged: (_) => _onFieldChanged(),
            onSubmitted: (_) => _emailFocusNode.requestFocus(),
          ),
          AuthInlineError(_fullNameError),
          const SizedBox(height: 11),
          const AuthFieldLabel('البريد الإلكتروني'),
          const SizedBox(height: 7),
          AuthTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hint: 'أدخل بريدك الإلكتروني',
            height: 46,
            radius: 15,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            hasError: _emailError != null,
            onChanged: (_) => _onFieldChanged(),
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          AuthInlineError(_emailError),
          const SizedBox(height: 11),
          const AuthFieldLabel('كلمة المرور'),
          const SizedBox(height: 7),
          AuthTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            // Western digits, per the app-wide numerals default — the source
            // file's "٨ أحرف على الأقل" is Arabic-Indic.
            hint: '8 أحرف على الأقل',
            height: 46,
            radius: 15,
            obscure: !_showPassword,
            textInputAction: TextInputAction.done,
            hasError: _passwordError != null,
            onChanged: (_) => _onFieldChanged(),
            onSubmitted: (_) {
              if (_agreedToTerms && !_loading) _handleSubmit();
            },
            suffix: AuthPasswordToggle(
              visible: _showPassword,
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          AuthInlineError(_passwordError),
          const SizedBox(height: 11),
          _buildTermsRow(),
          const SizedBox(height: 11),
          AuthPrimaryButton(
            label: _loading ? 'جاري إنشاء الحساب…' : 'إنشاء الحساب',
            loading: _loading,
            height: 52,
            enabled: _agreedToTerms,
            onPressed: (_agreedToTerms && !_loading) ? _handleSubmit : null,
          ),
          const SizedBox(height: 11),
          const AuthOrDivider(),
          const SizedBox(height: 9),
          AuthGoogleButton(
            label: 'إنشاء حساب باستخدام Google',
            height: 48,
            onPressed: _loading ? null : _handleGoogleSignUp,
          ),
          const SizedBox(height: 12),
        ],
      ),
      footer: AuthFooterPrompt(
        prompt: 'لديك حساب بالفعل؟',
        actionLabel: 'تسجيل الدخول',
        fontSize: 13,
        onPressed: _goSignIn,
      ),
    );
  }

  /// See [SignInScreen]'s twin: inline at the top of the sheet, not floating
  /// over the hero.
  Widget _buildBanner() {
    final banner = _banner;
    if (banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AuthErrorBanner(
        message: banner.message,
        severity: banner.severity,
        onDismiss: () => setState(() => _banner = null),
      ),
    );
  }

  /// The whole row is the tap target, not just the 20pt box — a checkbox
  /// that size is a hard thing to hit, and the copy beside it is the part
  /// people actually aim at.
  Widget _buildTermsRow() {
    final linkStyle = AuroraText.body(
      size: 12,
      weight: FontWeight.w500,
      color: AuthColors.link,
      height: 1.6,
    );

    return InkWell(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (value) =>
                    setState(() => _agreedToTerms = value ?? false),
                activeColor: AuthColors.green,
                side: const BorderSide(
                  color: AuthColors.checkboxBorder,
                  width: 1.5,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'أوافق على '),
                    TextSpan(text: 'شروط الاستخدام', style: linkStyle),
                    const TextSpan(text: ' و'),
                    TextSpan(text: 'سياسة الخصوصية', style: linkStyle),
                  ],
                ),
                style: AuroraText.body(
                  size: 12,
                  weight: FontWeight.w300,
                  color: AuthColors.secondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
