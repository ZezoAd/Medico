import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_in_page.dart';
import 'package:medico/screens/sign_up_screen.dart';
import 'package:medico/theme/aurora_tokens.dart';
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

  testWidgets('إنشاء حساب tab reveals the sign-up form', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    await tester.tap(signUpTab);
    await tester.pumpAndSettle();

    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    final switcher = tester.widget<AuthTabSwitcher>(
      find.byType(AuthTabSwitcher),
    );
    expect(switcher.selectedIndex, 1);
  });

  testWidgets('content slides on the onboarding mechanism', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    // Same widget onboarding_flow_screen.dart uses, same physics: the forms
    // are two named destinations, not a swipeable carousel.
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.physics, isA<NeverScrollableScrollPhysics>());

    // The curve stays the design system's shared ease-out.
    expect(AuroraMotion.easeOut, const Cubic(0.33, 1.0, 0.68, 1.0));

    // The pill was on 250ms/Curves.easeOut inherited from the old role
    // toggle; it is deliberately on the content's timing now.
    final pill = tester.widget<AnimatedPositioned>(
      find.descendant(
        of: find.byType(AuthTabSwitcher),
        matching: find.byType(AnimatedPositioned),
      ),
    );
    expect(pill.duration, authTabMotionDuration);
    expect(pill.curve, AuroraMotion.easeOut);

    // 300ms, inside the 300-400ms band a tab switch wants, and shared by the
    // pill and the forms so neither can arrive ahead of the other.
    expect(authTabMotionDuration, AuroraMotion.standard);
    expect(authTabMotionDuration, const Duration(milliseconds: 300));
  });

  testWidgets('each form is its own repaint layer', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    // Visit sign-up once so the PageView has actually built it — pages are
    // lazy, and keep-alive only holds a page after its first build.
    await tester.tap(signUpTab);
    await tester.pumpAndSettle();

    // Both forms are on screen together for the whole slide. Without a
    // boundary each, every frame repaints both card subtrees into one layer.
    // skipOffstage:false — a kept-alive page is in the tree but offstage
    // while the other tab shows, which is exactly the state being asserted.
    for (final form in [
      find.byType(SignInForm, skipOffstage: false),
      find.byType(SignUpForm, skipOffstage: false),
    ]) {
      expect(form, findsOneWidget);
      expect(
        find.ancestor(of: form, matching: find.byType(RepaintBoundary)),
        findsWidgets,
      );
    }
  });

  testWidgets('switching tabs preserves what was already typed', (
    tester,
  ) async {
    await pumpAt(tester, iphoneSe, 2.0);

    await tester.enterText(
      find
          .descendant(
            of: find.byType(SignInForm),
            matching: find.byType(TextField),
          )
          .first,
      'patient@example.com',
    );
    await tester.pump();

    await tester.tap(signUpTab);
    await tester.pumpAndSettle();
    await tester.tap(signInTab);
    await tester.pumpAndSettle();

    // The forms stay alive across the switch. An AnimatedSwitcher would have
    // discarded this state — and the controller holding it — on the first tap.
    expect(find.text('patient@example.com'), findsOneWidget);
  });

  testWidgets('the chrome stays put while the forms slide', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    final brandBefore = tester.getRect(find.text('Medico'));
    final tabsBefore = tester.getRect(find.byType(AuthTabSwitcher));

    await tester.tap(signUpTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    // Mid-flight the header has not moved a pixel — that is the whole point
    // of the shell, and what a route push could never give.
    expect(tester.getRect(find.text('Medico')), brandBefore);
    expect(tester.getRect(find.byType(AuthTabSwitcher)), tabsBefore);

    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Medico')), brandBefore);
    expect(tester.getRect(find.byType(AuthTabSwitcher)), tabsBefore);
  });

  testWidgets('forward slide: sign-up enters left, sign-in exits right', (
    tester,
  ) async {
    await pumpAt(tester, iphoneSe, 2.0);

    // Resting x is the shell's own 20px horizontal padding, not 0.
    final resting = tester.getTopLeft(find.byType(SignInForm)).dx;

    await tester.tap(signUpTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Mid-flight, both forms are on screen and moving as one track: the
    // incoming form is still left of centre, the outgoing one has been
    // carried off to the right.
    final entering = tester.getTopLeft(find.byType(SignUpForm)).dx;
    final leaving = tester.getTopLeft(find.byType(SignInForm)).dx;
    expect(entering, lessThan(resting));
    expect(leaving, greaterThan(resting));

    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(SignUpForm)).dx,
      moreOrLessEquals(resting),
    );
  });

  testWidgets('reverse slide: sign-in enters right, sign-up exits left', (
    tester,
  ) async {
    await pumpAt(tester, iphoneSe, 2.0);
    final resting = tester.getTopLeft(find.byType(SignInForm)).dx;
    await tester.tap(signUpTab);
    await tester.pumpAndSettle();

    await tester.tap(signInTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Exactly the mirror of the forward trip.
    expect(tester.getTopLeft(find.byType(SignInForm)).dx, greaterThan(resting));
    expect(tester.getTopLeft(find.byType(SignUpForm)).dx, lessThan(resting));

    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(SignInForm)).dx,
      moreOrLessEquals(resting),
    );
  });

  testWidgets('toggling repeatedly does not grow the navigation stack', (
    tester,
  ) async {
    final observer = _RouteCounter();
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = iphoneSe * 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(navigatorObservers: [observer], home: const SignInPage()),
    );
    await tester.pumpAndSettle();

    final baseline = observer.depth;
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('إنشاء حساب').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تسجيل الدخول').first);
      await tester.pumpAndSettle();
      // The switch never touches the Navigator at all now — both forms live
      // in one route — so there is nothing left that could accumulate.
      expect(observer.depth, baseline);
      expect(find.byType(SignInPage), findsOneWidget);
    }
  });

  testWidgets('tapping the active tab does not push a duplicate', (
    tester,
  ) async {
    await pumpAt(tester, iphoneSe, 2.0);

    await tester.tap(signInTab);
    await tester.pumpAndSettle();

    expect(find.byType(SignInPage), findsOneWidget);
    final switcher = tester.widget<AuthTabSwitcher>(
      find.byType(AuthTabSwitcher),
    );
    expect(switcher.selectedIndex, 0);
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
}
