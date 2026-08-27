/// Shared scaffolding for the auth-surface suites.
///
/// The four auth screens are separate routes now rather than tabs inside one
/// shell, so each has its own suite. These helpers are what keep those suites
/// from re-deriving the same setup four times.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/widgets/auth_surface.dart';

/// A middle-of-the-road modern phone. Most assertions do not care about size
/// and use this one.
const phone = Size(390, 844);

/// The smallest viewport anything is expected to survive.
const shortPhone = Size(320, 568);

/// Renders [screen] at [size] and fails on any overflow.
///
/// A RenderFlex overflow is reported as a Flutter error during paint, which
/// the test binding records and surfaces as a test failure — so pumping at a
/// given size is itself the assertion.
///
/// [keyboardInset] simulates an open soft keyboard. It matters here because
/// the sheet's scroll view is the only thing standing between a focused field
/// and an overflow once the keyboard has taken 300pt of the screen.
///
/// [settle] must be false for any screen carrying a perpetual animation.
/// The OTP screen has two — an autofocused `Pinput` whose caret blinks on a
/// repeating timer, and the resend countdown — so `pumpAndSettle` there waits
/// for a quiescence that never arrives and times out. Those tests pump a
/// fixed number of frames instead.
Future<void> pumpAt(
  WidgetTester tester,
  Widget screen,
  Size size, {
  double dpr = 2.0,
  double textScale = 1.0,
  double keyboardInset = 0,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: child!,
      ),
      home: screen,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Tears the tree down inside the test body.
///
/// Several auth screens hold live timers — the banner's five-second
/// self-dismiss, the OTP resend cooldown — and both are cancelled in
/// `dispose`. Replacing the tree runs those disposals while the test's fake
/// clock is still around, instead of leaving a pending timer for the binding
/// to complain about at teardown.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// The gradient the screen's backdrop is actually painted with.
///
/// Reads the real [DecoratedBox] rather than trusting the token constant, so
/// the assertion covers the wiring and not just the value.
Gradient? heroGradientOf(WidgetTester tester) {
  final decorated = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(AuthBackdrop),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (decorated.decoration as BoxDecoration).gradient;
}

/// Fails if any rendered string contains an Arabic-Indic digit.
///
/// The locked numerals default is Western digits, and the design source this
/// surface was rebuilt from is full of ٠-٩ — a fake status-bar clock, a
/// doctor count, "٦ أرقام", "٨ أحرف". This is the guard that none of them
/// were carried across verbatim.
void expectNoArabicIndicDigits(WidgetTester tester) {
  final arabicIndic = RegExp(r'[٠-٩۰-۹]');
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data ?? text.textSpan?.toPlainText();
    if (data == null) continue;
    expect(
      arabicIndic.hasMatch(data),
      isFalse,
      reason: 'Arabic-Indic digits in: $data',
    );
  }
}

/// Every [Text] on screen, flattened — including the rich-text runs, which
/// `find.text` cannot see.
List<String> visibleText(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];
