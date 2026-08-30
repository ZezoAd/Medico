import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_in_screen.dart';
import 'package:medico/screens/sign_up_screen.dart';
import 'package:medico/theme/aurora_tokens.dart';
import 'package:medico/widgets/auth_surface.dart';

import 'auth_test_support.dart';

/// The submit button, pinned past the footer link so "تسجيل الدخول" can only
/// mean one of them.
final submitButton = find.descendant(
  of: find.byType(AuthPrimaryButton),
  matching: find.text('تسجيل الدخول'),
);

void main() {
  group('lays out without overflow', () {
    for (final size in const [
      shortPhone,
      Size(360, 640),
      Size(375, 667),
      Size(393, 873),
      Size(430, 932),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpAt(tester, const SignInScreen(), size);

        expect(submitButton, findsOneWidget);
        expect(find.text('تسجيل الدخول باستخدام Google'), findsOneWidget);
        expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an open keyboard scrolls rather than overflowing', (
      tester,
    ) async {
      // The sheet is Expanded under a fixed hero, so an open keyboard
      // collapses it to a fraction of its resting height. The scroll view
      // inside the sheet is the only reason that is survivable.
      await pumpAt(
        tester,
        const SignInScreen(),
        const Size(393, 873),
        keyboardInset: 340,
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 1.3x font setting still fits', (tester) async {
      await pumpAt(
        tester,
        const SignInScreen(),
        const Size(360, 640),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('the tab-pill shell is gone', () {
    testWidgets('no switcher, no PageView, no second form', (tester) async {
      await pumpAt(tester, const SignInScreen(), phone);

      // Sign In and Sign Up are separate routes now. Nothing on this screen
      // may host the other one, and there is no segmented control to switch
      // between them.
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(SignUpScreen, skipOffstage: false), findsNothing);
      expect(find.text('إنشاء حساب'), findsNothing);

      // The old role toggle stayed gone through the rewrite too.
      expect(find.text('طبيب'), findsNothing);
      expect(find.text('مستخدم'), findsNothing);
    });
  });

  testWidgets('carries the returning-user copy from the design', (
    tester,
  ) async {
    await pumpAt(tester, const SignInScreen(), phone);

    expect(find.text('أهلاً بعودتك'), findsOneWidget);
    expect(find.text('سجّل دخولك لمتابعة مواعيدك'), findsOneWidget);
    // The pitch line belongs on Sign Up, in front of someone who has not
    // signed up yet.
    expect(
      find.text('انتظار العيادة صار من الماضي — تابع دورك من أي مكان.'),
      findsNothing,
    );
  });

  testWidgets('hero over a 34pt white sheet', (tester) async {
    await pumpAt(tester, const SignInScreen(), phone);

    expect(authSheetRadius, 34);
    expect(heroGradientOf(tester), AuroraGradients.authHero);
    // The in-app product gradient is a separate token and must not leak in.
    expect(heroGradientOf(tester), isNot(AuroraGradients.backdrop));
  });

  testWidgets('numerals are Western, never Arabic-Indic', (tester) async {
    await pumpAt(tester, const SignInScreen(), phone);
    expectNoArabicIndicDigits(tester);
  });

  group('validation', () {
    testWidgets('an empty submit marks both fields', (tester) async {
      await pumpAt(tester, const SignInScreen(), phone);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
      expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
    });

    testWidgets('a short password is not rejected client-side', (tester) async {
      await pumpAt(tester, const SignInScreen(), phone);

      // Sign In only checks emptiness. Holding a *typed* password to Sign
      // Up's 8-character bar would lock an account created before that rule
      // existed out of its own app, and the server is the authority on
      // whether a password is right regardless.
      await tester.enterText(find.byType(TextField).at(1), 'short');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.text('يجب أن تكون كلمة المرور 8 أحرف على الأقل'),
        findsNothing,
      );
      await unmount(tester);
    });

    testWidgets('a malformed address is caught', (tester) async {
      await pumpAt(tester, const SignInScreen(), phone);

      await tester.enterText(find.byType(TextField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('الرجاء إدخال بريد إلكتروني صحيح'), findsOneWidget);
    });
  });

  testWidgets('the password toggle flips obscuring both ways', (tester) async {
    await pumpAt(tester, const SignInScreen(), phone);

    TextField passwordField() =>
        tester.widget<TextField>(find.byType(TextField).at(1));

    expect(passwordField().obscureText, isTrue);
    expect(find.text('إظهار'), findsOneWidget);

    await tester.tap(find.text('إظهار'));
    await tester.pumpAndSettle();
    expect(passwordField().obscureText, isFalse);
    expect(find.text('إخفاء'), findsOneWidget);

    await tester.tap(find.text('إخفاء'));
    await tester.pumpAndSettle();
    expect(passwordField().obscureText, isTrue);
  });

  testWidgets('نسيت كلمة المرور؟ opens the existing reset sheet', (
    tester,
  ) async {
    await pumpAt(tester, const SignInScreen(), phone);

    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();

    // Unchanged mechanism: the same modal sheet, which sends a Supabase
    // reset mail whose link opens the external page. It is deliberately not
    // an in-app reset screen and not a pushed route.
    expect(find.text('استعادة كلمة المرور'), findsOneWidget);
    expect(
      find.text(
        'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  group('the footer folds away under the keyboard', () {
    // The two sizes the collapsible was originally verified at.
    for (final size in const [Size(360, 740), Size(412, 915)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: folds when the keyboard opens, returns when it goes', (
        tester,
      ) async {
        await pumpAt(tester, const SignInScreen(), size);

        // Measured on the collapsible itself rather than on the prompt: the
        // prompt is not in the tree at all while collapsed, so a finder for it
        // cannot report a height of zero — only an absence.
        final collapsible = find.byType(AuthCollapsible);
        final resting = tester.getRect(collapsible).height;
        expect(resting, greaterThan(0));
        expect(find.text('ليس لديك حساب؟'), findsOneWidget);

        await setKeyboardInset(tester, const SignInScreen(), size, 320);
        expect(tester.getRect(collapsible).height, 0);

        await setKeyboardInset(tester, const SignInScreen(), size, 0);
        expect(tester.getRect(collapsible).height, resting);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$tag: no overflow with the keyboard up', (tester) async {
        // The footer is a fixed sibling pinned to the sheet's bottom edge, and
        // resizeToAvoidBottomInset moves that edge. Left in place it rode up
        // the screen; collapsed it is simply not there, and the scroll area
        // above gets the space back.
        await pumpAt(tester, const SignInScreen(), size, keyboardInset: 320);

        expect(tester.getRect(find.byType(AuthCollapsible)).height, 0);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('returns after a back-gesture dismiss, which never unfocuses', (
      tester,
    ) async {
      const size = Size(360, 740);
      await pumpAt(tester, const SignInScreen(), size);

      final field = tester.widget<TextField>(find.byType(TextField).first);
      final node = field.focusNode!;

      // Open the keyboard the way a tap does.
      node.requestFocus();
      await setKeyboardInset(tester, const SignInScreen(), size, 320);
      expect(tester.getRect(find.byType(AuthCollapsible)).height, 0);

      // Now the actual regression. Android's back gesture hides the IME
      // without closing the input connection, so EditableText's
      // connectionClosed() — the only thing in Flutter that unfocuses on
      // dismissal — never runs. Reproduced faithfully by dropping the inset
      // and touching nothing else: no unfocus(), no receiveAction, no tap
      // elsewhere, any of which would mask the bug by flipping focus for us.
      await setKeyboardInset(tester, const SignInScreen(), size, 0);

      // The premise of the bug: focus really does survive the dismissal.
      // If this ever stops holding, the test below stops proving anything.
      expect(
        node.hasFocus,
        isTrue,
        reason: 'the field must still be focused, or this is not the bug',
      );

      // …and the footer is back anyway, because the collapse follows the
      // keyboard rather than the focus node.
      expect(tester.getRect(find.byType(AuthCollapsible)).height, isNonZero);
      expect(find.text('ليس لديك حساب؟'), findsOneWidget);

      // Back, and genuinely usable — not merely painted.
      await tester.tap(find.text('أنشئ حسابًا'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);
    });

    testWidgets('the collapsed prompt cannot be tapped by accident', (
      tester,
    ) async {
      const size = Size(360, 740);
      await pumpAt(tester, const SignInScreen(), size, keyboardInset: 320);

      // The collapse is a plain swap for a zero-height box, not a crossfade
      // that keeps its hidden child built — so while the keyboard is up the
      // prompt is out of the tree entirely and there is nothing left to
      // mis-tap. That is strictly stronger than the old guarantee (built, but
      // outside the hit-test rect), which is why this asserts absence rather
      // than tapping and hoping the tap misses.
      expect(find.text('أنشئ حسابًا'), findsNothing);
      expect(find.text('ليس لديك حساب؟'), findsNothing);

      await setKeyboardInset(tester, const SignInScreen(), size, 0);

      expect(find.text('أنشئ حسابًا'), findsOneWidget);
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('returns instantly, without animating back in', (tester) async {
      const size = Size(360, 740);
      await pumpAt(tester, const SignInScreen(), size);
      final collapsible = find.byType(AuthCollapsible);
      final resting = tester.getRect(collapsible).height;

      await setKeyboardInset(tester, const SignInScreen(), size, 320);
      expect(tester.getRect(collapsible).height, 0);

      // One frame after the keyboard leaves, the prompt is already at its full
      // resting height. A crossfade or a size tween would still be partway
      // through here — which is exactly what this used to look like on the
      // device, the prompt visibly growing back after the keyboard had gone.
      await setKeyboardInsetForOneFrame(tester, const SignInScreen(), size, 0);
      expect(tester.getRect(collapsible).height, resting);
      expect(find.text('أنشئ حسابًا'), findsOneWidget);

      // ...and settling changes nothing, so there was no tween to finish.
      await tester.pumpAndSettle();
      expect(tester.getRect(collapsible).height, resting);
    });

    testWidgets('hides instantly too, in the other direction', (tester) async {
      const size = Size(360, 740);
      await pumpAt(tester, const SignInScreen(), size);

      await setKeyboardInsetForOneFrame(
        tester,
        const SignInScreen(),
        size,
        320,
      );
      expect(tester.getRect(find.byType(AuthCollapsible)).height, 0);
      expect(find.text('أنشئ حسابًا'), findsNothing);
    });
  });

  group('the focused field clears the keyboard', () {
    // Sign Up's password field is what was reported, but both screens share
    // AuthSheetScaffold's scroll view, so the same guarantee is asserted here
    // rather than assumed from the sibling suite.
    for (final size in const [Size(360, 740), Size(360, 640)]) {
      for (final (index, label) in const [
        (0, 'البريد الإلكتروني'),
        (1, 'كلمة المرور'),
      ]) {
        final tag = '${size.width.toInt()}x${size.height.toInt()}';
        testWidgets('$tag: $label scrolls clear of the keyboard', (
          tester,
        ) async {
          await pumpAt(tester, const SignInScreen(), size);

          final field = find.byType(AuthTextField).at(index);
          tester.widget<AuthTextField>(field).focusNode.requestFocus();
          await setKeyboardInset(tester, const SignInScreen(), size, 320);
          await tester.pumpAndSettle();

          expectFieldClearOfKeyboard(tester, field, label: label);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('footer', () {
    testWidgets('أنشئ حسابًا pushes Sign Up', (tester) async {
      await pumpAt(tester, const SignInScreen(), phone);

      expect(find.text('ليس لديك حساب؟'), findsOneWidget);
      await tester.tap(find.text('أنشئ حسابًا'));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);
      // Sign In is directly underneath, so Sign Up's own footer can pop back
      // to this live route instead of pushing a second copy of it.
      expect(
        tester.widget<SignUpScreen>(find.byType(SignUpScreen)).cameFromSignIn,
        isTrue,
      );
    });

    testWidgets('bouncing between the two does not grow the stack', (
      tester,
    ) async {
      final observer = _RouteCounter();
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = phone * 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(navigatorObservers: [observer], home: const SignInScreen()),
      );
      await tester.pumpAndSettle();

      final baseline = observer.depth;
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('أنشئ حسابًا'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تسجيل الدخول'));
        await tester.pumpAndSettle();

        // Sign Up pops back to the Sign In already underneath rather than
        // pushing a fresh one, so four round trips leave the stack where it
        // started.
        expect(observer.depth, baseline);
        expect(find.byType(SignInScreen), findsOneWidget);
      }
    });
  });

  group('the opening banner', () {
    const message = 'انتهت جلستك، سجّل دخولك مرة أخرى.';

    testWidgets('renders inside the sheet, above the email field', (
      tester,
    ) async {
      await pumpAt(
        tester,
        const SignInScreen(initialErrorMessage: message),
        phone,
      );

      expect(find.text(message), findsOneWidget);
      // Inside the white sheet, not floating over the hero the way it did
      // under the old shell — where it covered the heading.
      expect(
        tester.getRect(find.text(message)).top,
        greaterThan(tester.getRect(find.text('أهلاً بعودتك')).bottom),
      );
      expect(
        tester.getRect(find.text(message)).bottom,
        lessThan(tester.getRect(find.text('البريد الإلكتروني')).top),
      );
      await unmount(tester);
    });

    testWidgets('an unconfirmed address gets a way forward', (tester) async {
      await pumpAt(
        tester,
        const SignInScreen(
          initialErrorMessage: message,
          initialUnconfirmedEmail: 'patient@example.com',
        ),
        phone,
      );

      expect(find.text('إرسال رمز تحقق جديد'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('typing clears it', (tester) async {
      await pumpAt(
        tester,
        const SignInScreen(initialErrorMessage: message),
        phone,
      );

      await tester.enterText(find.byType(TextField).at(0), 'a');
      await tester.pumpAndSettle();

      expect(find.text(message), findsNothing);
    });

    testWidgets('a cold start shows no banner at all', (tester) async {
      await pumpAt(tester, const SignInScreen(), phone);
      expect(find.text(message), findsNothing);
    });
  });
}

/// Tracks live route depth so a "does the stack grow?" claim is measured
/// rather than assumed.
class _RouteCounter extends NavigatorObserver {
  int depth = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => depth++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => depth--;

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      depth--;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {}
}
