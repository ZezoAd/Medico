import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_in_screen.dart';
import 'package:medico/screens/sign_up_screen.dart';
import 'package:medico/screens/welcome_screen.dart';
import 'package:medico/theme/aurora_tokens.dart';

import 'auth_test_support.dart';

void main() {
  group('lays out without overflow', () {
    for (final size in const [
      Size(320, 568), // below anything shipping, to prove the panel shrinks
      Size(360, 640),
      Size(375, 667),
      Size(393, 873), // Tecno Camon 20 Pro, the primary real-world target
      Size(430, 932),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpAt(tester, const WelcomeScreen(), size);

        expect(find.text('Medico'), findsOneWidget);
        expect(find.text('رفيقك في كل موعد طبي'), findsOneWidget);
        expect(find.text('إنشاء حساب جديد'), findsOneWidget);
        expect(find.text('تسجيل الدخول'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('the trust row makes no claim it cannot back', (tester) async {
    await pumpAt(tester, const WelcomeScreen(), phone);

    expect(find.text('تتبّع مباشر للدور'), findsOneWidget);
    expect(find.text('حجز فوري'), findsOneWidget);
    expect(find.text('بيانات مشفّرة'), findsOneWidget);

    // The design's first item was a doctor count. There is no real number to
    // put there before launch, and inventing one on the first screen anybody
    // sees is the wrong thing to be approximate about.
    expect(find.textContaining('طبيب'), findsNothing);
    expect(find.textContaining('2400'), findsNothing);
  });

  testWidgets('numerals are Western, never Arabic-Indic', (tester) async {
    await pumpAt(tester, const WelcomeScreen(), phone);
    expectNoArabicIndicDigits(tester);
  });

  testWidgets('paints the auth gradient, not the in-app one', (tester) async {
    await pumpAt(tester, const WelcomeScreen(), phone);

    // The two-gradient split is deliberate: this surface must never pick up
    // the token the Home queue card and empty state are painted with.
    expect(heroGradientOf(tester), AuroraGradients.authHero);
    expect(heroGradientOf(tester), isNot(AuroraGradients.backdrop));
  });

  group('routes to two separate screens, not tabs', () {
    testWidgets('إنشاء حساب جديد pushes Sign Up', (tester) async {
      await pumpAt(tester, const WelcomeScreen(), phone);

      await tester.tap(find.text('إنشاء حساب جديد'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);

      // Welcome is still underneath: this is a push, so backing out returns
      // to it rather than to an empty navigator.
      expect(
        tester.widget<SignUpScreen>(find.byType(SignUpScreen)).cameFromSignIn,
        isFalse,
      );
    });

    testWidgets('تسجيل الدخول pushes Sign In', (tester) async {
      await pumpAt(tester, const WelcomeScreen(), phone);

      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('backing out of Sign In lands on Welcome', (tester) async {
      await pumpAt(tester, const WelcomeScreen(), phone);

      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('رفيقك في كل موعد طبي'), findsOneWidget);
    });
  });

  group('forced sign-out forwards to Sign In', () {
    const message = 'انتهت جلستك، سجّل دخولك مرة أخرى.';

    testWidgets('lands on Sign In with the banner, not on Welcome', (
      tester,
    ) async {
      await pumpAt(
        tester,
        const WelcomeScreen(initialErrorMessage: message),
        phone,
      );

      // AuthGate renders Welcome for every signed-out case, but a forced
      // sign-out has to reach the one screen that can act on it.
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('an unconfirmed address carries its resend action through', (
      tester,
    ) async {
      await pumpAt(
        tester,
        const WelcomeScreen(
          initialErrorMessage: message,
          initialUnconfirmedEmail: 'patient@example.com',
        ),
        phone,
      );

      final signIn = tester.widget<SignInScreen>(find.byType(SignInScreen));
      expect(signIn.initialErrorMessage, message);
      expect(signIn.initialUnconfirmedEmail, 'patient@example.com');
      // Not a dead-end message: the banner offers a way forward.
      expect(find.text('إرسال رمز تحقق جديد'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('Welcome stays underneath, so back still works', (
      tester,
    ) async {
      await pumpAt(
        tester,
        const WelcomeScreen(initialErrorMessage: message),
        phone,
      );

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    });

    testWidgets('a plain cold start does not forward', (tester) async {
      await pumpAt(tester, const WelcomeScreen(), phone);

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    });
  });
}
