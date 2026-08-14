import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_in_page.dart';
import 'package:medico/screens/sign_up_screen.dart';

/// Regression guard for the transient overflow that appeared while an inline
/// field error was animating away.
///
/// The other auth suites assert with pumpAndSettle(), which runs the error
/// row's AnimatedSize to completion before looking at anything — so they were
/// structurally blind to this. These pump *into* the 200ms animation instead,
/// which is the only window the overflow ever existed in.
///
/// A RenderFlex overflow surfaces as a Flutter error during paint, which the
/// test binding records and reports as a failure, so reaching the end of each
/// body without an exception is the assertion.
Future<void> sizeTo(WidgetTester tester, Size logical, double dpr) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
  addTearDown(tester.view.reset);
}

void main() {
  // A short viewport, where the card content already meets or exceeds the
  // available height. That is the condition the bug needed: with room to
  // spare the slack absorbed the in-flight animation residual and nothing
  // was visible.
  const budgetAndroid = Size(360, 640);

  testWidgets('sign up survives inline errors collapsing', (tester) async {
    await sizeTo(tester, budgetAndroid, 2.0);
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Grow: submit empty so every field error appears.
    await tester.tap(find.text('إنشاء حساب'));
    await tester.pumpAndSettle();

    // Shrink: fill everything validly and resubmit so all three errors
    // collapse to zero height at once — the same transition a blur-triggered
    // revalidation runs when the keyboard is dismissed.
    await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextField).at(1), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(find.text('إنشاء حساب'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('sign in survives inline errors collapsing', (tester) async {
    await sizeTo(tester, budgetAndroid, 2.0);
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('تسجيل الدخول'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
