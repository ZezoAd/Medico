import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'otp_verification_screen.dart';

/// Sign-up screen matching the visual language of [SignInPage]: the same
/// aurora teal→blue gradient canvas, decorative soft circles, brand row, and
/// white card holding the form. Submitting creates the Supabase account and
/// hands off to [OtpVerificationScreen] to verify the email address.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _teal = Color(0xFF0D9488);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _faint = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _fieldFill = Color(0xFFF1F5F9);
  static const _danger = Color(0xFFDC2626);

  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Recognizers for the inline links in the footer rich-text runs.
  final _privacyPolicyTap = TapGestureRecognizer();
  final _signInTap = TapGestureRecognizer();

  bool _showPassword = false;
  bool _loading = false;
  bool _mounted = false;
  bool _agreedToPrivacy = false;

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  double get _screenHeight => MediaQuery.sizeOf(context).height;

  bool get _compact => _screenHeight < 700;

  double get _controlHeight => _screenHeight < 620
      ? 44
      : _compact
      ? 48
      : 54;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
    _signInTap.onTap = () => Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _privacyPolicyTap.dispose();
    _signInTap.dispose();
    super.dispose();
  }

  bool _validate() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _fullNameError = fullName.isEmpty ? 'الرجاء إدخال الاسم الكامل.' : null;
      _emailError = _emailPattern.hasMatch(email)
          ? null
          : 'أدخل بريدًا إلكترونيًا صحيحًا.';
      _passwordError = password.length < 8
          ? 'يجب أن تكون كلمة المرور 8 أحرف على الأقل.'
          : null;
    });

    return _fullNameError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _handleSubmit() async {
    setState(() => _formError = null);
    if (!_validate()) return;

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
      );
    } on AuthException catch (e) {
      setState(() => _formError = e.message);
    } catch (_) {
      setState(() => _formError = 'تعذر إنشاء الحساب. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Let the keyboard resize the body so the scroll view below can
        // bring a focused field above it instead of the keyboard covering it.
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
            SafeArea(child: _buildForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Gaps scale with the viewport instead of a fixed pixel value, so the
        // header block breathes on tall screens and tightens on short ones.
        final topGap = (constraints.maxHeight * 0.05).clamp(16.0, 44.0);
        final midGap = (constraints.maxHeight * 0.02).clamp(14.0, 20.0);
        final bottomGap = (constraints.maxHeight * 0.03).clamp(16.0, 24.0);
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              // Extra bottom padding lets the scroll view carry a focused
              // field above the keyboard instead of it hiding behind it.
              padding: EdgeInsets.fromLTRB(20, 0, 20, keyboardInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: topGap),
                  _buildBrand(),
                  SizedBox(height: midGap),
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
                  SizedBox(height: bottomGap),
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
            color: _ink.withValues(alpha: 0.08),
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
              color: _ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'أنشئ حسابك للبدء في استخدام Medico.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, color: _muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildFieldGroup(
            label: 'الاسم الكامل',
            controller: _fullNameController,
            hint: 'أدخل اسمك الكامل',
            icon: Icons.person_outline_rounded,
            error: _fullNameError,
          ),
          const SizedBox(height: 14),
          _buildFieldGroup(
            label: 'البريد الإلكتروني',
            controller: _emailController,
            hint: 'أدخل بريدك الإلكتروني',
            icon: Icons.mail_outline_rounded,
            error: _emailError,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildFieldGroup(
            label: 'كلمة المرور',
            controller: _passwordController,
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
                color: _faint,
              ),
            ),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: _danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          _buildPrivacyCheckbox(),
          const SizedBox(height: 18),
          _buildSubmitButton(),
          const SizedBox(height: 18),
          _buildSignInPrompt(),
        ],
      ),
    );
  }

  Widget _buildFieldGroup({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? error,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        _buildInput(
          controller: controller,
          hint: hint,
          icon: icon,
          hasError: error != null,
          obscure: obscure,
          suffix: suffix,
          keyboardType: keyboardType,
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(
              fontSize: 11.5,
              color: _danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
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

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool hasError,
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
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: (_) {
          if (_formError != null) setState(() => _formError = null);
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

  Widget _buildPrivacyCheckbox() {
    const linkStyle = TextStyle(
      fontSize: 12.5,
      color: _teal,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: _teal,
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
            activeColor: _teal,
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
            style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.4),
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

  Widget _buildSignInPrompt() {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'لديك حساب بالفعل؟'),
          const TextSpan(text: ' '),
          TextSpan(
            text: 'تسجيل الدخول',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _teal,
            ),
            recognizer: _signInTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, color: _muted),
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
