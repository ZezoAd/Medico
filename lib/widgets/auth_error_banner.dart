import 'dart:async';

import 'package:flutter/material.dart';

/// How urgently [AuthErrorBanner] should read — a hard failure (red) versus
/// a soft caution like rate limiting (amber).
enum AuthErrorSeverity { error, warning }

/// Dismissible message strip for the auth screens (Sign In, Sign Up, OTP,
/// Google) — meant to sit pinned to the top of the screen so a failure is
/// always visible, never just a silent reroute or a swallowed exception.
///
/// Auto-dismisses 5 seconds after it appears, fading out first. Showing a
/// new message while already visible restarts the 5-second countdown.
class AuthErrorBanner extends StatefulWidget {
  const AuthErrorBanner({
    super.key,
    required this.message,
    this.severity = AuthErrorSeverity.error,
    this.onRetry,
    this.retryLabel,
    this.onDismiss,
  });

  final String message;
  final AuthErrorSeverity severity;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final VoidCallback? onDismiss;

  @override
  State<AuthErrorBanner> createState() => _AuthErrorBannerState();
}

class _AuthErrorBannerState extends State<AuthErrorBanner> {
  static const _autoDismissDelay = Duration(seconds: 5);
  static const _fadeDuration = Duration(milliseconds: 300);

  static const _red = Color(0xFFDC2626);
  static const _amber = Color(0xFFD97706);

  Timer? _autoDismissTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant AuthErrorBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message ||
        widget.severity != oldWidget.severity) {
      if (!_visible) {
        setState(() => _visible = true);
      }
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(_autoDismissDelay, _handleAutoDismiss);
  }

  void _handleAutoDismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
    Future.delayed(_fadeDuration, () {
      if (mounted) widget.onDismiss?.call();
    });
  }

  void _handleManualDismiss() {
    _autoDismissTimer?.cancel();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.severity == AuthErrorSeverity.warning ? _amber : _red;

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: _fadeDuration,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.severity == AuthErrorSeverity.warning
                    ? Icons.warning_amber_rounded
                    : Icons.error_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              if (widget.onRetry != null)
                TextButton(
                  onPressed: widget.onRetry,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    widget.retryLabel ?? 'حاول مرة أخرى',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),
              if (widget.onDismiss != null)
                IconButton(
                  onPressed: _handleManualDismiss,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
