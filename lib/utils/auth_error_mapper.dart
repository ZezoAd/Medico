import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/auth_error_banner.dart';

/// The message + tone [mapAuthError] resolves a caught exception to, ready
/// to hand straight to [AuthErrorBanner].
class AuthErrorInfo {
  const AuthErrorInfo(
    this.message, {
    this.severity = AuthErrorSeverity.error,
  });

  final String message;
  final AuthErrorSeverity severity;
}

/// Shown after a stored session turns out to no longer correspond to a real,
/// signed-in account (token revoked, or the `profiles` row is gone) — always
/// paired with a forced `signOut()` so the stale session can't keep coming
/// back silently.
const sessionInvalidMessage = 'جلستك لم تعد صالحة. الرجاء تسجيل الدخول مرة أخرى.';

const _rateLimitCodes = {
  'over_request_rate_limit',
  'over_email_send_rate_limit',
  'over_sms_send_rate_limit',
};

const _otpCodes = {'otp_expired'};

/// Turns a caught exception from a Supabase auth call, Google sign-in, or a
/// plain network failure into a message the person on screen can act on.
/// Raw Supabase/Google error text stays in the logs (see the `debugPrint`
/// calls at each Google catch site) rather than reaching the UI verbatim.
///
/// Callers are expected to have already handled
/// `GoogleSignInExceptionCode.canceled` themselves — backing out of the
/// account picker isn't an error and should never reach this mapper.
AuthErrorInfo mapAuthError(Object error) {
  if (error is SocketException || error is TimeoutException) {
    return const AuthErrorInfo('لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.');
  }

  if (error is GoogleSignInException) {
    return const AuthErrorInfo('تعذر تسجيل الدخول عبر Google. حاول مرة أخرى.');
  }

  if (error is AuthException) {
    final code = error.code;
    final message = error.message.toLowerCase();

    if (error.statusCode == '429' ||
        (code != null && _rateLimitCodes.contains(code))) {
      return const AuthErrorInfo(
        'محاولات كثيرة جدًا. انتظر قليلاً ثم حاول مرة أخرى.',
        severity: AuthErrorSeverity.warning,
      );
    }

    if ((code != null && _otpCodes.contains(code)) ||
        message.contains('otp') ||
        (message.contains('token') &&
            (message.contains('expired') || message.contains('invalid')))) {
      return const AuthErrorInfo('الرمز غير صحيح أو منتهي الصلاحية. حاول مرة أخرى.');
    }

    if (message.contains('invalid login credentials')) {
      return const AuthErrorInfo('البريد الإلكتروني أو كلمة المرور غير صحيحة.');
    }

    return AuthErrorInfo(
      error.message.isNotEmpty ? error.message : 'حدث خطأ غير متوقع. حاول مرة أخرى.',
    );
  }

  return const AuthErrorInfo('حدث خطأ غير متوقع. حاول مرة أخرى.');
}
