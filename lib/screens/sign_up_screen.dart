import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../theme/aurora_tokens.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_error_banner.dart';
import 'auth_gate.dart';
import 'auth_shell.dart';
import 'otp_verification_screen.dart';

/// Sign-up screen matching the visual language of [SignInPage]: the same
/// aurora teal→blue gradient canvas, decorative soft circles, brand row, and
/// white card holding the form. Submitting creates the Supabase account and
/// hands off to [OtpVerificationScreen] to verify the email address.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) => const AuthShell(initialTab: 1);
}

/// The sign-up form, without any surrounding chrome.
///
/// Mirror of [SignInForm]: [AuthShell] owns the gradient, brand, tab switcher
/// and banner slot, and hosts the two forms as the pages of one sliding
/// [PageView]. This renders only what moves during a tab switch.
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key, required this.banner});

  /// Where this form publishes its error banner for the shell to draw.
  final AuthBannerSlot banner;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm>
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

  // Recognizers for the inline links in the footer rich-text runs.
  final _privacyPolicyTap = TapGestureRecognizer();

  /// True while any field on this form holds focus, i.e. while the keyboard
  /// is up and competing for the vertical space the pitch line occupies.
  bool _fieldFocused = false;

  bool _showPassword = false;
  bool _loading = false;
  bool _mounted = false;
  bool _agreedToPrivacy = false;

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  AuthErrorInfo? _banner;

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

  /// Republishes the banner on every state change — see the twin override in
  /// [SignInForm] for why this hooks setState rather than each mutation site.
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
            onDismiss: () => setState(() => _banner = null),
          );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
    _fullNameFocusNode.addListener(_onFullNameFocusChange);
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    for (final node in [
      _fullNameFocusNode,
      _emailFocusNode,
      _passwordFocusNode,
    ]) {
      node.addListener(_onAnyFieldFocusChange);
    }
  }

  /// Collapses the pitch line the moment the keyboard claims the screen.
  ///
  /// Separate from the per-field blur listeners above: those fire validation
  /// and only rebuild when an error actually changes, so they cannot be used
  /// to observe focus itself.
  void _onAnyFieldFocusChange() {
    final focused =
        _fullNameFocusNode.hasFocus ||
        _emailFocusNode.hasFocus ||
        _passwordFocusNode.hasFocus;
    if (focused != _fieldFocused) setState(() => _fieldFocused = focused);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _privacyPolicyTap.dispose();
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
        MaterialPageRoute(
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

  // Mirrors [SignInPage]'s _handleGoogle: with Google there's no separate
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
      // while they were still choosing. See the same note in [SignInPage].
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

  /// Height the form needs before it can be shown without a scroll view.
  ///
  /// Compared against the **available** height — `constraints.maxHeight` —
  /// and never against the screen. `MediaQuery.sizeOf().height` reports the
  /// whole window, which does not shrink when the soft keyboard opens, so a
  /// check against it happily reported "tall screen, no scroll" while the
  /// real slot had collapsed to 591px behind the keyboard. That mismatch is
  /// what overflowed by 44px.
  ///
  /// 640 against a measured natural height of ~583 at default text size. The
  /// headroom is deliberate: the content is a column of fields whose height
  /// moves with locale, font fallback and inline validation errors, so the
  /// bar sits above the tallest state rather than the resting one.
  static const _minHeightForNonScrollable = 640.0;

  Widget _buildForm() {
    // Scrolling is opt-in by screen size: tall screens get a plain Column, so
    // there is no scrollable to drag at all, and short ones keep the "Holy
    // Grail" scroll view.
    //
    // The scrolling branch centres with MainAxisAlignment.center rather than a
    // pair of Spacers under an IntrinsicHeight. That earlier shape overflowed
    // for the duration of every inline-error animation: IntrinsicHeight pinned
    // the Column to the sum of its children's *target* intrinsic heights,
    // while the error row's AnimatedSize was still painting an in-flight
    // height on the way to that target. Dismissing the keyboard re-validates
    // on blur and collapses those errors, which left the Column laid out
    // shorter than what it was painting, with no Spacer slack left to absorb
    // it.
    //
    // minTopGap/minBottomGap are flat constants, never derived from
    // constraints or MediaQuery, so they can never shrink below 24px no
    // matter the screen size or content height.
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTopGap = 24.0;
        const minBottomGap = 24.0;

        // The bar rises with the system font setting, because the content
        // grows with it while the slot does not: measured natural height runs
        // ~583 at 1.0x but reaches ~680 at 1.3x on a narrow screen, which a
        // flat 640 would wave through into an overflow.
        //
        // Clamped at 1.3 so the bar tops out at 832. Unclamped it would keep
        // climbing past any phone slot and make the branch dead code; stopping
        // lower (1.15, i.e. 736) left a 915pt device overflowing by 53px at
        // the largest font settings, because its ~775 slot cleared the bar
        // while the content did not fit it. Costs nothing at default text
        // size, where the multiplier is 1.0 and the bar is a flat 640.
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final requiredHeight =
            _minHeightForNonScrollable * textScale.clamp(1.0, 1.3);
        final shouldEnableScroll = constraints.maxHeight < requiredHeight;

        final card = AnimatedSlide(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          offset: _mounted ? Offset.zero : const Offset(0, 0.05),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _mounted ? 1 : 0,
            child: _buildCard(),
          ),
        );

        if (!shouldEnableScroll) {
          // No scroll view in the tree at all — nothing to drag, and nothing
          // that can report a scroll extent.
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: minTopGap),
                card,
                const SizedBox(height: minBottomGap),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: minTopGap),
                card,
                const SizedBox(height: minBottomGap),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _compact ? 20 : 24,
        vertical: _screenHeight < 620
            ? 16
            : _compact
            ? 20
            : 28,
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
      // The outer page scrolls as a whole, so the card just sizes to its
      // content instead of scrolling internally — a nested scrollable here
      // was also what let the keyboard hide the password field, since focus
      // would try to scroll this inner, already content-sized viewport.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'إنشاء حساب جديد',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _compact ? 20 : 23,
              fontWeight: FontWeight.w700,
              color: AuroraColors.ink,
              height: 1.3,
            ),
          ),
          // The pitch line, and the gaps around it, fold away while a field
          // is focused. It is the one piece of copy here that nobody is
          // reading mid-typing, and reclaiming it gives the form ~55px back
          // exactly when the keyboard has taken the room. Animated rather
          // than switched so the fields glide up instead of jumping.
          AuthCollapsibleOnFocus(
            collapsed: _fieldFocused,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: _tightGap),
                // Moved verbatim from Sign In's card, where it sat under a
                // heading greeting someone who already has an account. The
                // pitch belongs in front of the person who has not signed up
                // yet.
                const Text(
                  'انتظار العيادة صار من الماضي — تابع دورك من أي مكان.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AuroraColors.secondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _innerGap),
          _buildFieldGroup(
            label: 'الاسم الكامل',
            controller: _fullNameController,
            focusNode: _fullNameFocusNode,
            hint: 'أدخل اسمك الكامل',
            icon: Icons.person_outline_rounded,
            error: _fullNameError,
          ),
          SizedBox(height: _innerGap),
          _buildFieldGroup(
            label: 'البريد الإلكتروني',
            controller: _emailController,
            focusNode: _emailFocusNode,
            hint: 'أدخل بريدك الإلكتروني',
            icon: Icons.mail_outline_rounded,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: _innerGap),
          _buildFieldGroup(
            label: 'كلمة المرور',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hint: 'أدخل كلمة المرور',
            icon: Icons.lock_outline_rounded,
            error: _passwordError,
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
          SizedBox(height: _innerGap),
          _buildPrivacyCheckbox(),
          SizedBox(height: _innerGap),
          _buildSubmitButton(),
          SizedBox(height: _innerGap),
          _buildDivider(),
          SizedBox(height: _innerGap),
          _buildGoogleButton(),
          // The "لديك حساب بالفعل؟ تسجيل الدخول" line lived here. The
          // تسجيل الدخول tab above now carries it, matching Sign In.
        ],
      ),
    );
  }

  Widget _buildFieldGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    String? error,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        SizedBox(height: _tightGap),
        _buildInput(
          controller: controller,
          focusNode: focusNode,
          hint: hint,
          icon: icon,
          hasError: error != null,
          obscure: obscure,
          suffix: suffix,
          keyboardType: keyboardType,
        ),
        AnimatedSize(
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
        ),
      ],
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
          if (_banner != null) setState(() => _banner = null);
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

  Widget _buildPrivacyCheckbox() {
    const linkStyle = TextStyle(
      fontSize: 12.5,
      color: AuroraColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AuroraColors.primary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _agreedToPrivacy,
            onChanged: (value) =>
                setState(() => _agreedToPrivacy = value ?? false),
            activeColor: AuroraColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'أوافق على '),
                TextSpan(
                  text: 'سياسة الخصوصية',
                  style: linkStyle,
                  recognizer: _privacyPolicyTap,
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 12.5,
              color: AuroraColors.secondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final enabled = _agreedToPrivacy && !_loading;
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
      child: Opacity(
        opacity: _agreedToPrivacy ? 1 : 0.5,
        child: SizedBox(
          height: _controlHeight,
          child: TextButton(
            onPressed: enabled ? _handleSubmit : null,
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
                    _loading ? 'جاري إنشاء الحساب…' : 'إنشاء حساب',
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
        onPressed: _loading ? null : _handleGoogleSignUp,
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
}
