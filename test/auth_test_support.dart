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
  int? frames,
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
  if (frames != null) {
    // `pumpWidget` has already laid out one frame; anything beyond that is
    // deliberate extra time, so the caller's count starts from there.
    for (var i = 1; i < frames; i++) {
      await tester.pump();
    }
  } else if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Changes the reported keyboard inset on an already-pumped screen, leaving
/// its [State] — and its focus — untouched.
///
/// This is how a keyboard dismissal gets simulated honestly. Android's back
/// gesture hides the IME without closing the input connection, so
/// `EditableText.connectionClosed()` never fires and the focused node keeps
/// `hasFocus == true`; the *only* thing that actually changes is
/// `viewInsets.bottom` going to zero. Calling `FocusNode.unfocus()` or
/// `tester.testTextInput.receiveAction()` instead would flip focus as a side
/// effect and quietly paper over exactly the bug worth catching.
///
/// Re-pumps rather than mutating in place: `tester.view.viewInsets` is
/// physical-pixel plumbing that a `MediaQuery` override in [pumpAt] would
/// shadow anyway. Passing the same `screen` widget of the same type means the
/// element is updated rather than replaced, so the `State` object, its
/// controllers and its focus nodes all survive the pump — which is the whole
/// point.
Future<void> setKeyboardInset(
  WidgetTester tester,
  Widget screen,
  Size size,
  double inset, {
  double dpr = 2.0,
}) async {
  await pumpAt(tester, screen, size, dpr: dpr, keyboardInset: inset);
}

/// [setKeyboardInset], stopped after a single frame.
///
/// The one frame is the whole point. An `Animated*` wrapper is still mid-tween
/// one frame in, so anything measured here that already equals its settled
/// value cannot have animated to get there — which is how the footer's
/// instant show/hide is asserted rather than assumed. Pumping and settling
/// would report the same numbers either way.
Future<void> setKeyboardInsetForOneFrame(
  WidgetTester tester,
  Widget screen,
  Size size,
  double inset, {
  double dpr = 2.0,
}) async {
  await pumpAt(
    tester,
    screen,
    size,
    dpr: dpr,
    keyboardInset: inset,
    settle: false,
    frames: 1,
  );
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

/// Fails unless [field] ended up clear of the keyboard rather than balanced
/// on its edge.
///
/// The bar is deliberately above what Flutter gives you for free. The
/// framework reveals the *caret* when the keyboard arrives and stops the
/// instant it is technically on screen, which on these two forms leaves
/// 26-45pt under the field — visible, but the cramped "half-covered" state
/// that prompted `AuthTextField`'s own reveal. That reveal centres the field
/// in what is left of the viewport, which measures 51pt or better for every
/// field on both screens at both sizes below, so [minSlack] separates the two
/// outcomes rather than merely restating whichever one is current.
///
/// Not applicable where the scroll extent runs out first — at 320x568 with a
/// 320pt keyboard the viewport is under 100pt and centring is all the room
/// there is.
void expectFieldClearOfKeyboard(
  WidgetTester tester,
  Finder field, {
  double minSlack = 48,
  String? label,
}) {
  final rect = tester.getRect(field);
  final viewport = tester.getRect(find.byType(SingleChildScrollView));
  final where = label == null ? '' : ' ($label)';

  expect(
    rect.top,
    greaterThanOrEqualTo(viewport.top),
    reason: 'the field$where scrolled off the top of the sheet',
  );
  expect(
    viewport.bottom - rect.bottom,
    greaterThanOrEqualTo(minSlack),
    reason:
        'the field$where is sitting on the keyboard, not clear of it — '
        'only ${(viewport.bottom - rect.bottom).toStringAsFixed(1)}pt below it',
  );
}

/// Every [Text] on screen, flattened — including the rich-text runs, which
/// `find.text` cannot see.
List<String> visibleText(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];
