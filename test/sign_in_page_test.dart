import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_in_page.dart';
import 'package:medico/screens/sign_up_screen.dart';
import 'package:medico/widgets/auth_tab_switcher.dart';

/// "تسجيل الدخول" now labels two different things — the switcher tab and the
/// submit button — so every finder for either has to say which it means.
final signInTab = find.descendant(
  of: find.byType(AuthTabSwitcher),
  matching: find.text('تسجيل الدخول'),
);
final signUpTab = find.descendant(
  of: find.byType(AuthTabSwitcher),
  matching: find.text('إنشاء حساب'),
);
final submitButton = find.descendant(
  of: find.byType(TextButton),
  matching: find.text('تسجيل الدخول'),
);

/// Renders [SignInPage] at a given logical size and fails on any overflow.
///
/// A RenderFlex overflow is reported as a Flutter error during paint, which
/// the test binding records and surfaces as a test failure — so simply pumping
/// at each size is the assertion.
Future<void> pumpAt(WidgetTester tester, Size logical, double dpr) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: SignInPage()));
  await tester.pumpAndSettle();
}

void main() {
  // Logical sizes, and the padding a notch/status bar would eat.
  const iphoneSe = Size(375, 667);
  const pixel8Pro = Size(448, 998);

  group('fits without scrolling or overflow', () {
    testWidgets('iPhone SE', (tester) async {
      await pumpAt(tester, iphoneSe, 2.0);

      expect(submitButton, findsOneWidget);
      expect(signInTab, findsOneWidget);
      expect(find.text('الاستمرار باستخدام Google'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Pixel 8 Pro', (tester) async {
      await pumpAt(tester, pixel8Pro, 2.625);

      expect(submitButton, findsOneWidget);
      expect(signInTab, findsOneWidget);
      expect(find.text('الاستمرار باستخدام Google'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('iPhone 15 Pro Max', (tester) async {
      await pumpAt(tester, const Size(430, 932), 3.0);
      expect(find.text('الاستمرار باستخدام Google'), findsOneWidget);
    });

    testWidgets('very short viewport still lays out', (tester) async {
      // Below anything shipping, to prove the gaps collapse rather than break.
      await pumpAt(tester, const Size(320, 568), 2.0);
      expect(find.text('الاستمرار باستخدام Google'), findsOneWidget);
    });
  });

  testWidgets('shows the returning-user copy, not a role toggle', (
    tester,
  ) async {
    await pumpAt(tester, iphoneSe, 2.0);

    expect(find.text('أهلاً بعودتك'), findsOneWidget);
    expect(
      find.text('سجّل دخولك وتابع دورك وحجوزاتك من مكان واحد.'),
      findsOneWidget,
    );

    // The مستخدم/طبيب toggle is gone: doctors use a separate app, so this
    // screen never asks anyone to declare a role.
    expect(find.text('طبيب'), findsNothing);
    expect(find.text('مستخدم'), findsNothing);
    expect(find.text('أهلاً دكتور'), findsNothing);

    // The pitch line moved to Sign Up, where a first-time visitor sees it.
    expect(
      find.text('انتظار العيادة صار من الماضي — تابع دورك من أي مكان.'),
      findsNothing,
    );
  });

  testWidgets('sign-in tab is the active one', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    expect(find.byType(AuthTabSwitcher), findsOneWidget);
    expect(signInTab, findsOneWidget);
    expect(signUpTab, findsOneWidget);

    final switcher = tester.widget<AuthTabSwitcher>(
      find.byType(AuthTabSwitcher),
    );
    expect(switcher.selectedIndex, 0);

    // RTL: the first label sits on the visual right.
    expect(
      tester.getCenter(signInTab).dx,
      greaterThan(tester.getCenter(signUpTab).dx),
    );
  });

  testWidgets('إنشاء حساب tab navigates to SignUpScreen', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);
    expect(find.byType(SignUpScreen), findsNothing);

    await tester.tap(signUpTab);
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);
  });

  testWidgets('tapping the active tab does not push a duplicate', (
    tester,
  ) async {
    await pumpAt(tester, iphoneSe, 2.0);

    await tester.tap(signInTab);
    await tester.pumpAndSettle();

    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);
  });

  testWidgets('the inline signup prompt is gone', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    // Superseded by the إنشاء حساب tab — two routes to one screen on one
    // card was redundant.
    expect(
      find.textContaining('مستخدم جديد؟', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('validation error fits on the smallest screen', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    // The error rows are extra children in an already-full column.
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
    expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
  });

  // There is deliberately no success-state test here. The inline "تم تسجيل
  // الدخول بنجاح" screen this file used to assert on was removed when sign-in
  // switched to routing straight to its destination via `pushAndRemoveUntil`,
  // so there is no longer an intermediate state to render. Covering the
  // navigation instead needs a Supabase test double, which this file does not
  // have.
}
