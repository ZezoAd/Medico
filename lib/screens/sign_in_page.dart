import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Sign-in screen ported from the "Medico Login - Glass" design.
///
/// The design is RTL Arabic: a teal→blue gradient canvas with two soft
/// decorative circles, a role switcher (مستخدم / طبيب), and a white card
/// holding the credential form. Submitting swaps the whole screen for a
/// success state.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Recognizers for the inline links in the footer rich-text runs.
  final _signupTap = TapGestureRecognizer();
  final _termsTap = TapGestureRecognizer();
  final _privacyTap = TapGestureRecognizer();

  _Role _role = _Role.patient;
  bool _showPassword = false;
  bool _loading = false;
  bool _success = false;
  bool _mounted = false;
  String _error = '';

  bool get _isDoctor => _role == _Role.doctor;

  double get _screenHeight => MediaQuery.sizeOf(context).height;

  /// Short phones (iPhone SE and friends) get tighter controls so the fixed
  /// column still fits once the spacers between groups have collapsed.
  bool get _compact => _screenHeight < 700;

  /// Height of the inputs and the two buttons. The third tier is below any
  /// shipping phone, and only exists so the layout degrades instead of breaking.
  double get _controlHeight => _screenHeight < 620
      ? 44
      : _compact
          ? 48
          : 54;

  /// Scales one of the design's fixed spacings to the viewport height, so the
  /// header block shrinks on short phones instead of squeezing the card.
  /// 874 is the height of the design's reference canvas.
  double _gap(double design) {
    final scale = (MediaQuery.sizeOf(context).height / 874).clamp(0.55, 1.0);
    return design * scale;
  }

  // The card fades and slides in shortly after the first frame.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signupTap.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _setRole(_Role role) {
    setState(() {
      _role = role;
      _error = '';
    });
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'أدخل بريدًا إلكترونيًا صحيحًا.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'يجب أن تكون كلمة المرور 6 أحرف على الأقل.');
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _error = '';
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });
  }

  void _reset() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _success = false;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // The column is fixed-height by design, so let the keyboard overlay it
        // rather than shrinking the body into an overflow.
        resizeToAvoidBottomInset: false,
        body: Stack(
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
            SafeArea(
              child: _success ? _buildSuccess() : _buildForm(),
            ),
          ],
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
              child: const Icon(Icons.check_rounded, size: 34, color: Colors.white),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Header block: a fixed height near the top. Nothing here flexes, so
          // the card below gets every remaining pixel rather than competing
          // with spacers for the same free space.
          SizedBox(height: _gap(44)),
          _buildBrand(),
          SizedBox(height: _gap(14)),
          _buildRoleTabs(),
          SizedBox(height: _gap(14)),
          // The card fills whatever is left.
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
          SizedBox(height: _gap(24)),
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
          child: const Icon(Icons.monitor_heart_outlined, size: 18, color: Colors.white),
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
    final heading = _isDoctor ? 'مرحبًا دكتور' : 'أهلًا بعودتك';
    final subheading = _isDoctor
        ? 'تابع مواعيد عيادتك وطابور مرضاك من مكان واحد.'
        : 'انتظار العيادة صار من الماضي — تابع دورك من أي مكان.';

    // The design highlights whichever field failed validation.
    final emailError = _error.isNotEmpty && !_emailController.text.contains('@');
    final passwordError = _error.isNotEmpty && _passwordController.text.length < 6;

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
      // The separations between groups are Spacers weighted by the design's
      // own spacing values, so the rhythm is preserved at any card height and
      // every gap collapses toward zero as the card gets shorter. Only the
      // label→field pairs keep a fixed gap, since those must not close up.
      child: Column(
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
          const SizedBox(height: 8),
          Text(
            subheading,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: _muted, height: 1.5),
          ),
          const Spacer(flex: 24),
          _fieldLabel('البريد الإلكتروني'),
          const SizedBox(height: 8),
          _buildInput(
            controller: _emailController,
            hint: 'أدخل بريدك الإلكتروني',
            icon: Icons.mail_outline_rounded,
            hasError: emailError,
            keyboardType: TextInputType.emailAddress,
          ),
          const Spacer(flex: 18),
          _fieldLabel('كلمة المرور'),
          const SizedBox(height: 8),
          _buildInput(
            controller: _passwordController,
            hint: 'أدخل كلمة المرور',
            icon: Icons.lock_outline_rounded,
            hasError: passwordError,
            obscure: !_showPassword,
            suffix: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              tooltip: _showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
              icon: Icon(
                _showPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 22,
                color: _faint,
              ),
            ),
          ),
          const Spacer(flex: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GestureDetector(
              onTap: () {},
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
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: _danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error,
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
          const Spacer(flex: 24),
          _buildSubmitButton(),
          const Spacer(flex: 18),
          _buildDivider(),
          const Spacer(flex: 18),
          _buildGoogleButton(),
          const Spacer(flex: 26),
          _buildSignupPrompt(),
          const Spacer(flex: 14),
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
          if (_error.isNotEmpty) setState(() => _error = '');
        },
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _faint, fontWeight: FontWeight.w400),
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
            blurRadius: 26,
            offset: const Offset(0, 12),
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
          side: const BorderSide(color: Color(0xFFDADCE0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleGlyph(size: 20),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'الاستمرار بحساب Google',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupPrompt() {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: _isDoctor ? 'دكتور جديد؟' : 'مستخدم جديد؟'),
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

  // The design pins this to a single line (white-space:nowrap), so it is one
  // rich-text run rather than a Wrap that could grow to two or three lines.
  Widget _buildLegalNote() {
    const linkStyle = TextStyle(
      fontSize: 11.5,
      color: _teal,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: _teal,
    );

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'بالمتابعة، أنت توافق على '),
          TextSpan(
            text: 'الشروط',
            style: linkStyle,
            recognizer: _termsTap,
          ),
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
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11.5, color: _faint),
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

/// Google "G" mark, painted so no asset or extra dependency is needed.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  // Paths lifted from the design's 48×48 viewBox and scaled to the widget.
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  static const _paths = <(Color, String)>[
    (_blue, 'M45.1 24.5c0-1.6-.1-3.1-.4-4.6H24v9h11.9c-.5 2.8-2.1 5.1-4.4 6.7v5.6h7.1c4.2-3.8 6.5-9.5 6.5-16.7z'),
    (_green, 'M24 46c5.9 0 10.9-2 14.6-5.3l-7.1-5.6c-2 1.4-4.6 2.2-7.5 2.2-5.8 0-10.7-3.9-12.5-9.1H4.2v5.7C7.9 41.1 15.3 46 24 46z'),
    (_yellow, 'M11.5 28.2c-.5-1.4-.7-2.9-.7-4.2s.3-2.9.7-4.2v-5.7H4.2C2.8 17 2 20.4 2 24s.8 7 2.2 9.9l7.3-5.7z'),
    (_red, 'M24 10.7c3.2 0 6 1.1 8.3 3.2l6.3-6.3C34.9 4 29.9 2 24 2 15.3 2 7.9 6.9 4.2 14.1l7.3 5.7c1.8-5.2 6.7-9.1 12.5-9.1z'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    for (final (color, data) in _paths) {
      canvas.drawPath(_parse(data), Paint()..color = color);
    }
    canvas.restore();
  }

  /// Minimal SVG path parser covering the commands used by the Google mark
  /// (M, m, L, l, H, h, V, v, C, c, Z).
  static Path _parse(String data) {
    final path = Path();
    final tokens = RegExp(r'[A-Za-z]|-?\d*\.?\d+').allMatches(data).map((m) => m[0]!);
    final it = tokens.iterator;
    var cx = 0.0, cy = 0.0, sx = 0.0, sy = 0.0;
    String? cmd;
    String? pending;

    double num_() {
      if (pending != null) {
        final v = double.parse(pending!);
        pending = null;
        return v;
      }
      it.moveNext();
      return double.parse(it.current);
    }

    while (true) {
      if (pending == null) {
        if (!it.moveNext()) break;
        final t = it.current;
        if (RegExp(r'^[A-Za-z]$').hasMatch(t)) {
          cmd = t;
        } else {
          pending = t; // repeated coordinate set for the previous command
        }
      }
      if (cmd == null) break;

      switch (cmd) {
        case 'M' || 'm':
          final rel = cmd == 'm';
          final x = num_(), y = num_();
          cx = rel ? cx + x : x;
          cy = rel ? cy + y : y;
          sx = cx;
          sy = cy;
          path.moveTo(cx, cy);
          cmd = rel ? 'l' : 'L';
        case 'L' || 'l':
          final rel = cmd == 'l';
          final x = num_(), y = num_();
          cx = rel ? cx + x : x;
          cy = rel ? cy + y : y;
          path.lineTo(cx, cy);
        case 'H' || 'h':
          final x = num_();
          cx = cmd == 'h' ? cx + x : x;
          path.lineTo(cx, cy);
        case 'V' || 'v':
          final y = num_();
          cy = cmd == 'v' ? cy + y : y;
          path.lineTo(cx, cy);
        case 'C' || 'c':
          final rel = cmd == 'c';
          final dx = rel ? cx : 0.0;
          final dy = rel ? cy : 0.0;
          final x1 = dx + num_(), y1 = dy + num_();
          final x2 = dx + num_(), y2 = dy + num_();
          final x = dx + num_(), y = dy + num_();
          path.cubicTo(x1, y1, x2, y2, x, y);
          cx = x;
          cy = y;
        case 'Z' || 'z':
          path.close();
          cx = sx;
          cy = sy;
        default:
          return path; // unsupported command — stop rather than misdraw
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
