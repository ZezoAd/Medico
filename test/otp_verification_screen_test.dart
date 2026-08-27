import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/otp_verification_screen.dart';
import 'package:medico/theme/aurora_tokens.dart';
import 'package:medico/widgets/auth_surface.dart';
import 'package:pinput/pinput.dart';

import 'auth_test_support.dart';

const _email = 'patient@example.com';

/// Never settles this screen: the autofocused `Pinput`'s caret blinks on a
/// repeating timer and the resend countdown ticks once a second, so
/// `pumpAndSettle` would wait for a quiescence that never arrives.
///
/// The 60-second cooldown is also why every test here tears the tree down
/// inside its own body — see [unmount].
Future<void> pumpOtp(
  WidgetTester tester, {
  Size size = phone,
  double keyboardInset = 0,
  bool passwordUnchanged = false,
}) {
  return pumpAt(
    tester,
    OtpVerificationScreen(email: _email, passwordUnchanged: passwordUnchanged),
    size,
    keyboardInset: keyboardInset,
    settle: false,
  );
}

void main() {
  group('lays out without overflow', () {
    for (final size in const [
      shortPhone,
      Size(360, 640),
      Size(393, 873),
      Size(430, 932),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpOtp(tester, size: size);

        expect(find.text('تأكيد البريد'), findsOneWidget);
        expect(find.byType(Pinput), findsOneWidget);
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }

    testWidgets('an open keyboard scrolls rather than overflowing', (
      tester,
    ) async {
      // The number pad is up for this entire screen's useful life, so this is
      // the resting state rather than an edge case.
      await pumpOtp(tester, size: const Size(393, 873), keyboardInset: 340);

      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  });

  testWidgets('is the reskinned hero-over-sheet shape', (tester) async {
    await pumpOtp(tester);

    expect(heroGradientOf(tester), AuroraGradients.authHero);
    expect(find.byType(AuthSheetScaffold), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('shows the real address the code went to', (tester) async {
    await pumpOtp(tester);

    // Not a placeholder and not the design's `name@email.com`: the whole
    // point of the line is telling someone which inbox to open.
    expect(find.text(_email), findsOneWidget);
    expect(
      visibleText(tester).any((t) => t.contains('أرسلنا رمزًا من 6 أرقام')),
      isTrue,
    );
    await unmount(tester);
  });

  testWidgets('numerals are Western, never Arabic-Indic', (tester) async {
    await pumpOtp(tester);

    // The design reads "٦ أرقام".
    expectNoArabicIndicDigits(tester);
    await unmount(tester);
  });

  testWidgets('six cells, assembled left to right under an RTL screen', (
    tester,
  ) async {
    await pumpOtp(tester);

    final pin = tester.widget<Pinput>(find.byType(Pinput));
    expect(pin.length, 6);

    // Force-wrapped LTR: if the boxes filled right to left the digits would
    // reach verifyOTP reversed, and every correct code would be rejected.
    final direction = tester
        .widget<Directionality>(
          find
              .ancestor(
                of: find.byType(Pinput),
                matching: find.byType(Directionality),
              )
              .first,
        )
        .textDirection;
    expect(direction, TextDirection.ltr);
    await unmount(tester);
  });

  group('resend', () {
    testWidgets('opens on a cooldown, with nothing tappable yet', (
      tester,
    ) async {
      await pumpOtp(tester);

      // The first code was sent by the caller immediately before this screen
      // was pushed, so entry starts the clock rather than a send.
      expect(
        visibleText(tester).any((t) => t.contains('يمكنك إعادة الإرسال بعد')),
        isTrue,
      );
      expect(find.text('إعادة إرسال الرمز'), findsNothing);
      await unmount(tester);
    });

    testWidgets('the timer counts down in Western digits', (tester) async {
      await pumpOtp(tester);

      await tester.pump(const Duration(seconds: 1));
      expect(
        visibleText(tester).any((t) => t.contains('59')),
        isTrue,
        reason: 'the countdown should be visible and Western',
      );
      await unmount(tester);
    });

    testWidgets('the button appears once the cooldown runs out', (
      tester,
    ) async {
      await pumpOtp(tester);

      await tester.pump(const Duration(seconds: 61));
      await tester.pump();

      // A link styled to look tappable while nothing can be tapped would be a
      // lie for its first 60 seconds, so it is absent rather than disabled.
      expect(find.text('إعادة إرسال الرمز'), findsOneWidget);
      expect(find.text('لم يصلك الرمز؟'), findsOneWidget);
      await unmount(tester);
    });
  });

  testWidgets('the verify button is gated on a complete code', (tester) async {
    await pumpOtp(tester);

    final button = tester.widget<AuthPrimaryButton>(
      find.byType(AuthPrimaryButton),
    );
    expect(button.enabled, isFalse);
    expect(button.onPressed, isNull);
    expect(find.text('تأكيد الرمز'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the back chevron pops to whoever pushed this screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = phone * 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OtpVerificationScreen(email: _email),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    // Fixed pumps rather than pumpAndSettle: once the OTP screen is up, its
    // blinking caret means nothing ever settles. The generous windows cover
    // the route transition plus the tap's own ink splash, since a single
    // elapsed pump has to clear both before the popped route leaves the tree.
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(OtpVerificationScreen), findsOneWidget);

    await tester.tap(find.byType(AuthBackButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(OtpVerificationScreen), findsNothing);
    expect(find.text('go'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the re-signup password note still has a home', (tester) async {
    await pumpOtp(tester, passwordUnchanged: true);

    // The design has no slot for this, but the case is real: GoTrue kept the
    // original password on a resend, so the one just typed is not the live
    // one. Dropping the note in a reskin would have turned that into an
    // unexplained "wrong email or password" later.
    expect(
      visibleText(tester).any((t) => t.contains('كلمة المرور لم تتغير')),
      isTrue,
    );
    await unmount(tester);
  });
}
