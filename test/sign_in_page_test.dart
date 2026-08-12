import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_in_page.dart';

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

      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('الاستمرار باستخدام Google'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Pixel 8 Pro', (tester) async {
      await pumpAt(tester, pixel8Pro, 2.625);

      expect(find.text('تسجيل الدخول'), findsOneWidget);
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

  testWidgets('doctor tab swaps the copy without overflowing', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    expect(find.text('أهلًا بعودتك'), findsOneWidget);
    await tester.tap(find.text('طبيب'));
    await tester.pumpAndSettle();

    expect(find.text('مرحبًا دكتور'), findsOneWidget);
    // The signup prompt is one rich-text run: "دكتور جديد؟ إنشاء حساب".
    expect(
      find.textContaining('دكتور جديد؟', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('validation error fits on the smallest screen', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    // The error rows are extra children in an already-full column.
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsOneWidget);
    expect(find.text('الرجاء إدخال كلمة المرور'), findsOneWidget);
  });

  testWidgets('success state renders after a valid submit', (tester) async {
    await pumpAt(tester, iphoneSe, 2.0);

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('تم تسجيل الدخول بنجاح'), findsOneWidget);
  });
}
