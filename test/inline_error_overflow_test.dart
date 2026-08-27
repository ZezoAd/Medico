import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/sign_in_screen.dart';
import 'package:medico/screens/sign_up_screen.dart';
import 'package:medico/widgets/auth_surface.dart';

import 'auth_test_support.dart';

/// Regression guard for the transient overflow that appeared while an inline
/// field error was animating away.
///
/// The other auth suites assert with `pumpAndSettle()`, which runs the error
/// row's 200ms `AnimatedSize` to completion before looking at anything — so
/// they are structurally blind to this. These pump *into* that window
/// instead, which is the only time the overflow ever existed.
///
/// A RenderFlex overflow surfaces as a Flutter error during paint, which the
/// test binding records and reports as a failure, so reaching the end of each
/// body without an exception is the assertion.
///
/// Kept after the tab shell was replaced by separate full screens. The sheet
/// scrolls now, which should make the whole class of failure impossible — but
/// "should be impossible" is exactly what was believed the first time, and
/// the check costs two pumps.
final signInSubmit = find.descendant(
  of: find.byType(AuthPrimaryButton),
  matching: find.text('تسجيل الدخول'),
);
final signUpSubmit = find.descendant(
  of: find.byType(AuthPrimaryButton),
  matching: find.text('إنشاء الحساب'),
);

void main() {
  // A short viewport, where the sheet's content already meets or exceeds the
  // height available to it. That is the condition the bug needed: with room
  // to spare the slack absorbed the in-flight animation residual and nothing
  // was visible.
  const budgetAndroid = Size(360, 640);

  testWidgets('sign up survives inline errors collapsing', (tester) async {
    await pumpAt(tester, const SignUpScreen(), budgetAndroid);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Grow: submit empty so every field error appears.
    await tester.tap(signUpSubmit);
    await tester.pumpAndSettle();

    // Shrink: fill everything validly and resubmit so all three errors
    // collapse to zero height at once — the same transition a blur-triggered
    // revalidation runs when the keyboard is dismissed.
    await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextField).at(1), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(signUpSubmit);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('sign in survives inline errors collapsing', (tester) async {
    await pumpAt(tester, const SignInScreen(), budgetAndroid);

    await tester.tap(signInSubmit);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(signInSubmit);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
