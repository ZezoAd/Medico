import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/auth_error_mapper.dart';
import 'auth_error_banner.dart';

const _resetPasswordRedirect = 'https://reset.medico.dpdns.org';

/// Same neutral copy whether the address is registered or not — Supabase's
/// API already avoids leaking that, so the UI must not undo it by branching
/// on "email not found".
const _neutralSentMessage =
    'إذا كان هذا البريد مسجلاً لدينا، ستصلك رسالة لإعادة تعيين كلمة المرور.';

/// Opens the forgot-password bottom sheet over [context], matching the
/// Aurora sheet's white-card look instead of pushing a full route.
Future<void> showForgotPasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const Directionality(
      textDirection: TextDirection.rtl,
      child: ForgotPasswordSheet(),
    ),
  );
}

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  static const _teal = Color(0xFF0D9488);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _faint = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _fieldFill = Color(0xFFF1F5F9);
  static const _danger = Color(0xFFDC2626);

  static const _networkTimeout = Duration(seconds: 15);
  static const _cooldownSeconds = 60;

  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  String? _emailError;
  AuthErrorInfo? _banner;
  bool _loading = false;
  bool _sent = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    if (!_emailPattern.hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final error = _validateEmail(email);
    if (error != null) {
      setState(() => _emailError = error);
      return;
    }

    setState(() {
      _emailError = null;
      _banner = null;
      _loading = true;
    });

    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email, redirectTo: _resetPasswordRedirect)
          .timeout(_networkTimeout);
      if (!mounted) return;
      setState(() => _sent = true);
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      // Mirrors otp_verification_screen's _sendCode: only a send that
      // actually went out starts the cooldown, so a failure of any kind
      // leaves the button immediately tappable again.
      setState(() => _banner = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSubmit = !_loading && _cooldown == 0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_banner != null) ...[
                AuthErrorBanner(
                  message: _banner!.message,
                  severity: _banner!.severity,
                  onDismiss: () => setState(() => _banner = null),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'استعادة كلمة المرور',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.',
                style: TextStyle(fontSize: 13.5, color: _muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              Text(
                'البريد الإلكتروني',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: TextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_sent,
                  onChanged: (_) {
                    if (_banner != null) setState(() => _banner = null);
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أدخل بريدك الإلكتروني',
                    hintStyle: const TextStyle(
                      color: _faint,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: _fieldFill,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: _faint,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 50,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _emailError != null ? _danger : _border,
                        width: 1.5,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _emailError != null ? _danger : _border,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _emailError != null ? _danger : _teal,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              if (_emailError != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 13, color: _danger),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _emailError!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_sent) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: _teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _neutralSentMessage,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _ink,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: canSubmit
                        ? const [Color(0xFF17B47F), Color(0xFF1E8FCB)]
                        : [
                            const Color(0xFF17B47F).withValues(alpha: 0.5),
                            const Color(0xFF1E8FCB).withValues(alpha: 0.5),
                          ],
                  ),
                ),
                child: SizedBox(
                  height: 50,
                  child: TextButton(
                    onPressed: canSubmit ? _handleSubmit : null,
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
                        Text(
                          _cooldown > 0
                              ? 'إعادة الإرسال خلال ${_cooldown}s'
                              : 'إرسال',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
}
