import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_in_screen.dart';
import 'package:medico/screens/sign_up_screen.dart';
import 'package:medico/theme/aurora_tokens.dart';
import 'package:medico/widgets/auth_surface.dart';

import 'auth_test_support.dart';

/// The submit button. "إنشاء حساب" is the hero heading and "تسجيل الدخول" is
/// the footer link, so the button's own label is the unambiguous one.
final submitButton = find.descendant(
  of: find.byType(AuthPrimaryButton),
  matching: find.text('إنشاء الحساب'),
);

/// Ticks the checkbox, which gates the submit button.
Future<void> agreeToTerms(WidgetTester tester) async {
  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
}

void main() {
  group('lays out without overflow', () {
    for (final size in const [
      shortPhone,
      Size(360, 640),
      Size(375, 667),
      Size(393, 873),
      Size(428, 926),
    ]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpAt(tester, const SignUpScreen(), size);

        expect(submitButton, findsOneWidget);
        expect(find.text('إنشاء حساب باستخدام Google'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('an open keyboard scrolls rather than overflowing', (
      tester,
    ) async {
      // This is the regression the old height-threshold machinery existed
      // for. The sheet is Expanded now, so it simply gets shorter and its
      // scroll view takes over — there is no "should I scroll?" decision left
      // to get wrong, and nothing reads the window height.
      await pumpAt(
        tester,
        const SignUpScreen(),
        const Size(393, 873),
        keyboardInset: 340,
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 1.3x font setting still fits', (tester) async {
      await pumpAt(
        tester,
        const SignUpScreen(),
        const Size(360, 800),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('carries the sign-up copy from the design', (tester) async {
    await pumpAt(tester, const SignUpScreen(), phone);

    expect(find.text('إنشاء حساب'), findsOneWidget);
    expect(find.text('خطوة واحدة وتبدأ الحجز'), findsOneWidget);
    expect(heroGradientOf(tester), AuroraGradients.authHero);
  });

  testWidgets('has a single full name field, no first/last split', (
    tester,
  ) async {
    await pumpAt(tester, const SignUpScreen(), phone);

    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('الاسم الأول'), findsNothing);
    expect(find.text('اسم العائلة'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('numerals are Western, never Arabic-Indic', (tester) async {
    await pumpAt(tester, const SignUpScreen(), phone);

    // The design's placeholder reads "٨ أحرف على الأقل".
    expect(find.text('8 أحرف على الأقل'), findsOneWidget);
    expectNoArabicIndicDigits(tester);
  });

  group('the terms checkbox gates submit', () {
    testWidgets('starts unchecked, and an unchecked submit does nothing', (
      tester,
    ) async {
      await pumpAt(tester, const SignUpScreen(), phone);

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
      await tester.enterText(find.byType(TextField).at(1), 'jane@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // onPressed is null while unchecked, so not even validation runs.
      expect(find.text('الرجاء إدخال الاسم الكامل.'), findsNothing);
    });

    testWidgets('the copy beside the box is part of the tap target', (
      tester,
    ) async {
      await pumpAt(tester, const SignUpScreen(), phone);

      // A 20pt box is a hard thing to hit; the sentence is what people aim
      // at, so the whole row toggles.
      await tester.tap(find.textContaining('سياسة الخصوصية'));
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('checking it enables submit and validation runs', (
      tester,
    ) async {
      await pumpAt(tester, const SignUpScreen(), phone);
      await agreeToTerms(tester);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('الرجاء إدخال الاسم الكامل.'), findsOneWidget);
      expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
      expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
    });
  });

  group('password rules', () {
    testWidgets('eight characters is the whole rule', (tester) async {
      await pumpAt(tester, const SignUpScreen(), phone);
      await agreeToTerms(tester);

      // Letters-only, digits-only and symbols-only all pass: there is
      // deliberately no character-composition requirement.
      for (final password in ['abcdefgh', '12345678', r'!!!!!!!!']) {
        await tester.enterText(find.byType(TextField).at(2), password);
        await tester.pumpAndSettle();
        expect(
          find.text('يجب أن تكون كلمة المرور 8 أحرف على الأقل'),
          findsNothing,
          reason: '$password should be accepted',
        );
      }
    });

    testWidgets('seven characters is rejected', (tester) async {
      await pumpAt(tester, const SignUpScreen(), phone);
      await agreeToTerms(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
      await tester.enterText(find.byType(TextField).at(1), 'jane@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'short12');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(
        find.text('يجب أن تكون كلمة المرور 8 أحرف على الأقل'),
        findsOneWidget,
      );
    });

    testWidgets('nothing rates the password beyond the length rule', (
      tester,
    ) async {
      await pumpAt(tester, const SignUpScreen(), phone);

      // The three-segment strength meter was built and then removed. Its
      // segments were the only AnimatedContainers on this screen, so their
      // absence is the check that no remnant of it is still being drawn.
      await tester.enterText(find.byType(TextField).at(2), 'abc');
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedContainer), findsNothing);

      await tester.enterText(
        find.byType(TextField).at(2),
        r'Str0ng!Passphrase',
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedContainer), findsNothing);
    });
  });

  group('footer returns to Sign In without stacking', () {
    testWidgets('pushed from Sign In: pops back to the live route', (
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
      await tester.tap(find.text('أنشئ حسابًا'));
      await tester.pumpAndSettle();

      final depthOnSignUp = observer.depth;
      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pumpAndSettle();

      expect(observer.depth, depthOnSignUp - 1);
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(SignUpScreen), findsNothing);
    });

    testWidgets('pushed from Welcome: replaces itself with Sign In', (
      tester,
    ) async {
      await pumpAt(tester, const SignUpScreen(), phone);

      // Nothing to pop back to but Welcome, so the footer swaps this route
      // for a Sign In instead — the person still lands where the link said.
      await tester.tap(find.text('تسجيل الدخول'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(SignUpScreen), findsNothing);
    });
  });

  group('the footer folds away under the keyboard', () {
    testWidgets('folds when the keyboard opens, returns when it goes', (
      tester,
    ) async {
      const size = Size(360, 740);
      await pumpAt(tester, const SignUpScreen(), size);

      final collapsible = find.byType(AuthCollapsible);
      final resting = tester.getRect(collapsible).height;
      expect(resting, greaterThan(0));

      await setKeyboardInset(tester, const SignUpScreen(), size, 320);
      expect(tester.getRect(collapsible).height, 0);
      expect(tester.takeException(), isNull);

      await setKeyboardInset(tester, const SignUpScreen(), size, 0);
      expect(tester.getRect(collapsible).height, resting);
    });

    testWidgets('returns after a back-gesture dismiss, which never unfocuses', (
      tester,
    ) async {
      // Sign Up had the same latent bug as Sign In — three fields rather than
      // two, so it spends more of its life with the keyboard up, not less.
      const size = Size(360, 740);
      await pumpAt(tester, const SignUpScreen(), size);

      final node = tester
          .widget<TextField>(find.byType(TextField).first)
          .focusNode!;
      node.requestFocus();
      await setKeyboardInset(tester, const SignUpScreen(), size, 320);
      expect(tester.getRect(find.byType(AuthCollapsible)).height, 0);

      // Only the inset moves — no unfocus(), which is what makes this the
      // real back-gesture case rather than a trivially passing one.
      await setKeyboardInset(tester, const SignUpScreen(), size, 0);

      expect(
        node.hasFocus,
        isTrue,
        reason: 'the field must still be focused, or this is not the bug',
      );
      expect(tester.getRect(find.byType(AuthCollapsible)).height, isNonZero);
      expect(find.text('لديك حساب بالفعل؟'), findsOneWidget);
    });

    testWidgets('returns instantly, without animating back in', (tester) async {
      const size = Size(360, 740);
      await pumpAt(tester, const SignUpScreen(), size);
      final collapsible = find.byType(AuthCollapsible);
      final resting = tester.getRect(collapsible).height;

      await setKeyboardInset(tester, const SignUpScreen(), size, 320);
      expect(tester.getRect(collapsible).height, 0);

      // Same guarantee as Sign In's, asserted here because it is the same
      // widget doing it for both and a regression would hit both footers.
      await setKeyboardInsetForOneFrame(tester, const SignUpScreen(), size, 0);
      expect(tester.getRect(collapsible).height, resting);
      expect(find.text('لديك حساب بالفعل؟'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(tester.getRect(collapsible).height, resting);
    });
  });

  group('the focused field clears the keyboard', () {
    // The password field is the reported case — tapping it left it half under
    // the keyboard. The other two ride the same scroll view, so they are held
    // to the same bar. 640 is the tighter of the two heights and the one where
    // the framework's own caret reveal is not enough on its own.
    for (final size in const [Size(360, 740), Size(360, 640)]) {
      for (final (index, label) in const [
        (0, 'الاسم الكامل'),
        (1, 'البريد الإلكتروني'),
        (2, 'كلمة المرور'),
      ]) {
        final tag = '${size.width.toInt()}x${size.height.toInt()}';
        testWidgets('$tag: $label scrolls clear of the keyboard', (
          tester,
        ) async {
          await pumpAt(tester, const SignUpScreen(), size);

          final field = find.byType(AuthTextField).at(index);
          // Focus first, keyboard second — the real order, and the one that
          // matters: the field is not covered until the keyboard arrives, so
          // a reveal that fires only on focus would measure the wrong
          // viewport and stop short.
          tester.widget<AuthTextField>(field).focusNode.requestFocus();
          await setKeyboardInset(tester, const SignUpScreen(), size, 320);
          await tester.pumpAndSettle();

          expectFieldClearOfKeyboard(tester, field, label: label);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('has no back button of its own', (tester) async {
    await pumpAt(tester, const SignUpScreen(), phone);

    // The back chevron belongs to OTP. Sign Up is reached by a push, so the
    // system gesture already covers it.
    expect(find.byType(AuthBackButton), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('the tab-pill shell is gone', (tester) async {
    await pumpAt(tester, const SignUpScreen(), phone);

    expect(find.byType(PageView), findsNothing);
    expect(find.byType(SignInScreen, skipOffstage: false), findsNothing);
  });
}

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
