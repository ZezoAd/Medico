import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';

enum _OtpStatus { empty, filling, loading, success, failure }

/// Six-digit email OTP verification screen matching [SignInPage]'s visual
/// language. Sends the code via Supabase's `signInWithOtp` email flow on
/// entry, then verifies whatever the user types with `verifyOTP`.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

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
  static const _digitCount = 6;

  final _digitControllers = List.generate(
    _digitCount,
    (_) => TextEditingController(),
  );
  final _digitFocusNodes = List.generate(_digitCount, (_) => FocusNode());

  _OtpStatus _status = _OtpStatus.empty;
  String? _errorMessage;
  bool _resending = false;
  bool _sendFailed = false;
  bool _mounted = false;

  String get _code => _digitControllers.map((c) => c.text).join();

  bool get _isComplete => _code.length == _digitCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
    _sendCode();
  }

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _sendFailed = false);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: widget.email,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _sendFailed = true;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sendFailed = true;
        _errorMessage = 'تعذر إرسال الرمز. تحقق من اتصالك وحاول مرة أخرى.';
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _status = _OtpStatus.empty;
      _errorMessage = null;
    });
    for (final c in _digitControllers) {
      c.clear();
    }
    await _sendCode();
    if (!mounted) return;
    setState(() => _resending = false);
    if (!_sendFailed) {
      _digitFocusNodes.first.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رمز جديد إلى بريدك الإلكتروني.'),
        ),
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _digitCount - 1) {
      _digitFocusNodes[index + 1].requestFocus();
    }
    setState(() {
      _errorMessage = null;
      _status = _code.isEmpty ? _OtpStatus.empty : _OtpStatus.filling;
    });
    if (_isComplete) _verify();
  }

  void _onDigitBackspace(int index) {
    if (_digitControllers[index].text.isEmpty && index > 0) {
      _digitFocusNodes[index - 1].requestFocus();
      _digitControllers[index - 1].clear();
    }
  }

  Future<void> _verify() async {
    if (!_isComplete || _status == _OtpStatus.loading) return;
    setState(() {
      _status = _OtpStatus.loading;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _code,
        type: OtpType.email,
      );
      if (!mounted) return;
      setState(() => _status = _OtpStatus.success);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      _handleFailure(e.message);
    } catch (_) {
      _handleFailure('تعذر التحقق من الرمز. حاول مرة أخرى.');
    }
  }

  void _handleFailure(String message) {
    if (!mounted) return;
    setState(() {
      _status = _OtpStatus.failure;
      _errorMessage = message;
    });
    for (final c in _digitControllers) {
      c.clear();
    }
    _digitFocusNodes.first.requestFocus();
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_status == _OtpStatus.success)
              _buildSuccess()
            else
              _buildForm(),
          ],
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
        if (_sendFailed) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(
            _errorMessage ?? 'تعذر إرسال الرمز.',
            onRetry: _sendCode,
          ),
        ],
        const SizedBox(height: 24),
        _buildDigitRow(disabled: disabled, hasError: hasError),
        if (hasError && _errorMessage != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: _danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
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
        const SizedBox(height: 24),
        _buildVerifyButton(),
        const SizedBox(height: 18),
        _buildResendRow(),
      ],
    );
  }

  Widget _buildErrorBanner(String message, {required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: _danger),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: _danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitRow({required bool disabled, required bool hasError}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_digitCount, (i) {
        return SizedBox(
          width: 44,
          height: 52,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                _onDigitBackspace(i);
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _digitControllers[i],
              focusNode: _digitFocusNodes[i],
              enabled: !disabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: _fieldFill,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? _danger : _border,
                    width: 1.5,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? _danger : _border,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? _danger : _teal,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? _danger : _border,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) => _onDigitChanged(i, value),
            ),
          ),
        );
      }),
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
    final showResend = _status == _OtpStatus.failure || _sendFailed;
    if (!showResend) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'لم يصلك الرمز؟',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _resending ? null : _resend,
          child: Text(
            _resending ? 'جاري الإرسال…' : 'إعادة إرسال الرمز',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _teal.withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.check_rounded, size: 32, color: _teal),
        ),
        const SizedBox(height: 18),
        const Text(
          'تم التحقق بنجاح',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'جاري تحويلك…',
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
