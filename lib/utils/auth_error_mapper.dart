import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' show ClientException;
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

/// Shown for any connectivity failure — no route to Supabase at all, as
/// opposed to Supabase answering with a rejection.
const networkErrorMessage =
    'تعذر الاتصال بالإنترنت. تأكد من اتصالك بشبكة Wi‑Fi أو بيانات الهاتف وحاول مرة أخرى.';

/// The last resort for anything unrecognised. GoTrue's own text is English
/// and frequently internal ("Database error saving new user"), so it never
/// reaches the UI verbatim — the raw exception belongs in the logs via the
/// `debugPrint` calls at the catch sites.
const genericAuthErrorMessage = 'حدث خطأ غير متوقع. حاول مرة أخرى.';

/// Sign-in against an account whose email was never verified — the one auth
/// failure whose fix is "send a fresh code" rather than "try again". Doesn't
/// point back at the original signup email, which by the time someone hits
/// this is likely long expired.
const emailNotConfirmedMessage =
    'لم يتم تفعيل هذا الحساب بعد. يمكنك طلب رمز تحقق جديد لإكمال التفعيل.';

/// Signing up with an address that already has an account. Also shown by
/// [SignUpScreen] for the *silent* version of this case, which returns 200
/// with an empty `identities` list instead of raising at all.
const accountAlreadyExistsMessage =
    'هذا البريد الإلكتروني مسجل بالفعل. سجّل الدخول بدلاً من إنشاء حساب جديد.';

/// Google sign-in on the طبيب tab that landed on a non-doctor account.
///
/// Google is a *creating* flow: the first ID-token exchange registers the
/// auth user before any role is knowable, so by the time this is shown the
/// account genuinely exists and is signed in. The copy says so plainly —
/// implying nothing happened, or that it was undone, would be a lie the very
/// next launch contradicts, since the session is deliberately kept alive.
const doctorTabGoogleCreatedPatientMessage =
    'حسابات الأطباء تُنشأ داخل العيادة ولا يمكن تسجيلها من التطبيق. '
    'تم تسجيل دخولك بحساب مستخدم عادي، وهو جاهز للاستخدام الآن.';

/// Password sign-in on the طبيب tab that landed on a non-doctor account.
///
/// Unlike [doctorTabGoogleCreatedPatientMessage], `signInWithPassword` only
/// ever signs into an account that already existed — nothing was created
/// here, so this copy must not mention creation at all.
const doctorTabNotADoctorAccountMessage =
    'هذا الحساب ليس حساب طبيب. حسابات الأطباء تُنشأ داخل العيادة. '
    'يمكنك المتابعة كمستخدم عادي.';

const _rateLimitCodes = {
  'over_request_rate_limit',
  'over_email_send_rate_limit',
  'over_sms_send_rate_limit',
};

const _otpCodes = {'otp_expired'};

/// GoTrue `error_code` → Arabic copy, covering what the calls this app
/// actually makes can return: `signUp`, `signInWithPassword`,
/// `signInWithIdToken`, `resend`, `resetPasswordForEmail`, and `getUser`.
///
/// Deliberately absent: `user_not_found`. Answering it specifically would
/// confirm whether an address is registered, undoing the enumeration
/// protection the sign-in and forgot-password flows are built around — it
/// falls through to [genericAuthErrorMessage] instead.
const _codeMessages = <String, String>{
  // Not in gotrue's `ErrorCode` enum, but the live server sends it for a
  // wrong email/password pair; `AuthException.code` is the raw JSON string,
  // so it arrives regardless of what the Dart enum knows about.
  'invalid_credentials': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'email_not_confirmed': emailNotConfirmedMessage,
  'phone_not_confirmed': emailNotConfirmedMessage,
  'email_exists': accountAlreadyExistsMessage,
  'user_already_exists': accountAlreadyExistsMessage,
  'weak_password': 'كلمة المرور ضعيفة. اختر كلمة مرور أطول أو أصعب في التخمين.',
  'same_password': 'كلمة المرور الجديدة مطابقة للحالية. اختر كلمة مرور مختلفة.',
  'validation_failed': 'تحقق من البيانات المُدخلة وحاول مرة أخرى.',
  'bad_json': 'تحقق من البيانات المُدخلة وحاول مرة أخرى.',
  'signup_disabled': 'إنشاء الحسابات متوقف مؤقتًا. حاول لاحقًا.',
  'email_provider_disabled': 'تسجيل الدخول بالبريد الإلكتروني غير متاح حاليًا.',
  'provider_disabled': 'طريقة تسجيل الدخول هذه غير متاحة حاليًا.',
  'anonymous_provider_disabled': 'طريقة تسجيل الدخول هذه غير متاحة حاليًا.',
  'otp_disabled': 'تسجيل الدخول برمز التحقق غير متاح حاليًا.',
  'user_banned': 'تم إيقاف هذا الحساب. تواصل مع الدعم للمساعدة.',
  'captcha_failed': 'فشل التحقق الأمني. حاول مرة أخرى.',
  'session_not_found': sessionInvalidMessage,
  'session_expired': sessionInvalidMessage,
  'session_missing': sessionInvalidMessage,
  'bad_jwt': sessionInvalidMessage,
  'no_authorization': sessionInvalidMessage,
  'request_timeout': 'استغرق الاتصال وقتًا طويلاً. حاول مرة أخرى.',
  'unexpected_failure': genericAuthErrorMessage,
};

/// The same conditions keyed on the English message text, for responses that
/// carry no `error_code` at all — older GoTrue versions, and errors raised
/// before the structured code is attached. Checked in order, so the more
/// specific phrases must come first.
const _messageFragments = <String, String>{
  'email not confirmed': emailNotConfirmedMessage,
  'invalid login credentials': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'user already registered': accountAlreadyExistsMessage,
  'already registered': accountAlreadyExistsMessage,
  'password should be': 'كلمة المرور ضعيفة. اختر كلمة مرور أطول أو أصعب في التخمين.',
  'signups not allowed': 'إنشاء الحسابات متوقف مؤقتًا. حاول لاحقًا.',
  'unable to validate email address': 'الرجاء إدخال بريد إلكتروني صحيح.',
};

/// Conditions the person can act on themselves read as a caution, not a
/// hard failure — same reasoning as the rate-limit branch.
const _warningCodes = {
  'email_not_confirmed',
  'phone_not_confirmed',
  'email_exists',
  'user_already_exists',
};

/// How long a signup OTP stays valid. Must mirror the project's
/// Auth → Providers → Email → "Email OTP Expiration" setting in the Supabase
/// dashboard, currently 300s; [mapOtpVerifyError] has no other way to know the
/// window, so if that setting changes, change this too.
const otpValidityWindow = Duration(minutes: 5);

/// Shown when the entered code is past [otpValidityWindow].
const otpExpiredMessage = 'انتهت صلاحية الرمز، يرجى طلب رمز جديد';

/// Shown when the entered code was rejected while still inside the window,
/// i.e. it was almost certainly mistyped.
const otpIncorrectMessage = 'الرمز الذي أدخلته غير صحيح، يرجى المحاولة مرة أخرى';

/// True when [error] is GoTrue rejecting the submitted code itself, as opposed
/// to a network drop, a rate limit, or any other auth failure.
bool _isOtpCodeRejected(Object error) {
  if (error is! AuthException) return false;

  final code = error.code;
  // A 429 during verification is a rate limit, not a verdict on the code.
  if (error.statusCode == '429' ||
      (code != null && _rateLimitCodes.contains(code))) {
    return false;
  }

  final message = error.message.toLowerCase();
  return (code != null && _otpCodes.contains(code)) ||
      message.contains('otp') ||
      (message.contains('token') &&
          (message.contains('expired') || message.contains('invalid')));
}

/// Message fragments that show up in a network-level failure's text — for
/// exceptions that carry no dedicated type, e.g. a raw `ClientException` or
/// an `AuthRetryableFetchException` wrapping one, whose message is just
/// `error.toString()` of whatever the underlying HTTP client threw.
const _networkMessageFragments = {
  'failed host lookup',
  'connection closed',
  'connection refused',
  'network is unreachable',
};

/// True when [error] means the request never reached Supabase at all, as
/// opposed to Supabase answering with a rejection.
bool _isNetworkFailure(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is AuthRetryableFetchException ||
      error is ClientException) {
    return true;
  }
  final text = (error is AuthException ? error.message : error.toString())
      .toLowerCase();
  return _networkMessageFragments.any(text.contains);
}

/// Maps a failure from `verifyOTP` — the one call site that can tell a
/// mistyped code from a stale one.
///
/// GoTrue answers both cases *identically*: HTTP 403, `error_code`
/// `otp_expired`, `msg` "Token has expired or is invalid" — verified against
/// the live project by submitting a code that was never issued, which still
/// comes back as `otp_expired`. That collapse is deliberate on Supabase's
/// side; splitting them server-side would let the endpoint confirm that a
/// guessed code was real and merely late. `otp_expired` is therefore the
/// generic OTP-failure code, not an expiry signal, and no response field
/// distinguishes the two.
///
/// So the split is made here instead, on [sinceCodeSent] — how long ago we
/// sent the code the person is answering. It is a heuristic, not ground
/// truth: a wrong code typed after the window will be reported as expired.
/// That errs toward the action that actually unblocks them (request a new
/// code), which is why it leans this way rather than the other.
AuthErrorInfo mapOtpVerifyError(
  Object error, {
  required Duration sinceCodeSent,
}) {
  if (_isOtpCodeRejected(error)) {
    return AuthErrorInfo(
      sinceCodeSent >= otpValidityWindow ? otpExpiredMessage : otpIncorrectMessage,
    );
  }
  return mapAuthError(error);
}

/// Turns a caught exception from a Supabase auth call, Google sign-in, or a
/// plain network failure into a message the person on screen can act on.
/// Raw Supabase/Google error text stays in the logs (see the `debugPrint`
/// calls at each Google catch site) rather than reaching the UI verbatim.
///
/// Callers are expected to have already handled
/// `GoogleSignInExceptionCode.canceled` themselves — backing out of the
/// account picker isn't an error and should never reach this mapper.
AuthErrorInfo mapAuthError(Object error) {
  // Checked before the AuthException branch below: AuthRetryableFetchException
  // is itself an AuthException (GoTrue's wrapper around any non-HTTP-response
  // failure, e.g. a SocketException from airplane mode), so without this
  // early check it would fall through to the generic fallback instead of
  // being reported as what it actually is — no connection.
  if (_isNetworkFailure(error)) {
    return const AuthErrorInfo(networkErrorMessage);
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

    // Callers that can't date the code they're verifying (anything other than
    // the OTP screen) keep the combined wording; see [mapOtpVerifyError] for
    // why the two cases can't be told apart from the response alone.
    if (_isOtpCodeRejected(error)) {
      return const AuthErrorInfo('الرمز غير صحيح أو منتهي الصلاحية. حاول مرة أخرى.');
    }

    if (code != null) {
      final mapped = _codeMessages[code];
      if (mapped != null) {
        return AuthErrorInfo(
          mapped,
          severity: _warningCodes.contains(code)
              ? AuthErrorSeverity.warning
              : AuthErrorSeverity.error,
        );
      }
    }

    for (final entry in _messageFragments.entries) {
      if (message.contains(entry.key)) return AuthErrorInfo(entry.value);
    }

    // Anything still unrecognised stops here rather than being echoed: raw
    // GoTrue text is English, and some of it is internal detail the person
    // on screen can neither read nor act on.
    return const AuthErrorInfo(genericAuthErrorMessage);
  }

  return const AuthErrorInfo(genericAuthErrorMessage);
}

/// True when [error] is Supabase rejecting a wrong email/password pair on
/// sign-in — the one case [SignInPage] marks on both fields inline instead
/// of showing as a banner, since Supabase deliberately won't say which of
/// the two was wrong.
bool isInvalidCredentialsError(Object error) {
  if (error is! AuthException) return false;
  if (error.code == 'invalid_credentials') return true;
  return error.message.toLowerCase().contains('invalid login credentials');
}

/// True when [error] is Supabase refusing sign-in because the account's
/// email was never confirmed — the case [SignInPage] offers a "resend code"
/// action for, instead of leaving the person at a dead end.
bool isEmailNotConfirmedError(Object error) {
  if (error is! AuthException) return false;
  if (error.code == 'email_not_confirmed') return true;
  return error.message.toLowerCase().contains('email not confirmed');
}
