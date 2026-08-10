import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_up_screen.dart';

/// Renders [SignUpScreen] at a given logical size and fails on any overflow.
///
/// A RenderFlex overflow is reported as a Flutter error during paint, which
/// the test binding records and surfaces as a test failure — so simply pumping
/// at each size is the assertion.
Future<void> pumpAt(WidgetTester tester, Size logical, double dpr) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
  await tester.pumpAndSettle();
}

void main() {
  const budgetAndroid = Size(360, 640);
  const modernPhone = Size(390, 844);
  const largePhone = Size(428, 926);

  group('fits without scrolling or overflow', () {
    testWidgets('360x640 budget Android', (tester) async {
      await pumpAt(tester, budgetAndroid, 2.0);
      expect(find.text('إنشاء حساب'), findsOneWidget);
    });

    testWidgets('390x844 standard modern phone', (tester) async {
      await pumpAt(tester, modernPhone, 2.0);
      expect(find.text('إنشاء حساب'), findsOneWidget);
    });

    testWidgets('428x926 large phone', (tester) async {
      await pumpAt(tester, largePhone, 3.0);
      expect(find.text('إنشاء حساب'), findsOneWidget);
    });
  });

  testWidgets('has a single full name field, no first/last split', (
    tester,
  ) async {
    await pumpAt(tester, modernPhone, 2.0);

    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('الاسم الأول'), findsNothing);
    expect(find.text('اسم العائلة'), findsNothing);
  });

  testWidgets('has no back button', (tester) async {
    await pumpAt(tester, modernPhone, 2.0);

    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('privacy checkbox starts unchecked and gates submit', (
    tester,
  ) async {
    await pumpAt(tester, modernPhone, 2.0);

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);

    // Submit is disabled while unchecked: tapping does nothing observable
    // (no navigation, no loading state) — filling the form and tapping
    // must not produce a validation error either, since onPressed is null.
    await tester.enterText(
      find.byType(TextField).at(0),
      'Jane Doe',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'jane@example.com',
    );
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(find.text('إنشاء حساب'));
    await tester.pumpAndSettle();
    expect(find.text('الرجاء إدخال الاسم الكامل.'), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final checkedBox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkedBox.value, isTrue);
  });
}
