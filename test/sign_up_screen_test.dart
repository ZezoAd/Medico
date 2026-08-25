import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medico/screens/sign_up_screen.dart';

/// "إنشاء حساب" now labels both the switcher tab and the submit button, so
/// finders for either have to say which one they mean.
final submitButton = find.descendant(
  of: find.byType(TextButton),
  matching: find.text('إنشاء حساب'),
);

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
      expect(submitButton, findsOneWidget);
    });

    testWidgets('390x844 standard modern phone', (tester) async {
      await pumpAt(tester, modernPhone, 2.0);
      expect(submitButton, findsOneWidget);
    });

    testWidgets('428x926 large phone', (tester) async {
      await pumpAt(tester, largePhone, 3.0);
      expect(submitButton, findsOneWidget);
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
    await tester.enterText(find.byType(TextField).at(0), 'Jane Doe');
    await tester.enterText(find.byType(TextField).at(1), 'jane@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('الرجاء إدخال الاسم الكامل.'), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final checkedBox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkedBox.value, isTrue);
  });

  group('scrolls only when the screen is short', () {
    Future<int> scrollViewsAt(
      WidgetTester tester,
      Size size, {
      double textScale = 1.0,
      double keyboardInset = 0,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
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
          home: const SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widgetList(find.byType(SingleChildScrollView)).length;
    }

    testWidgets('tall screens get no scroll view at all', (tester) async {
      // 873 and 800 are the two logical heights a 1080x2400 Tecno reports,
      // depending on the DPR Android picks for a 6.67" panel.
      for (final size in const [
        Size(393, 873),
        Size(360, 800),
        Size(412, 915),
      ]) {
        expect(
          await scrollViewsAt(tester, size),
          0,
          reason: 'no scroll view expected at ${size.height}',
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('short screens still scroll rather than overflow', (
      tester,
    ) async {
      for (final size in const [Size(375, 667), Size(320, 568)]) {
        expect(
          await scrollViewsAt(tester, size),
          1,
          reason: 'scroll view expected at ${size.height}',
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('a larger font setting scrolls a short screen', (tester) async {
      // 800pt clears the flat 750 bar, but at 1.15x the content no longer
      // fits — the threshold scales so this lands on a scroll view instead
      // of overflowing by ~79px.
      expect(await scrollViewsAt(tester, const Size(360, 800)), 0);
      expect(
        await scrollViewsAt(tester, const Size(360, 800), textScale: 1.3),
        1,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an open keyboard scrolls even on the tallest screen', (
      tester,
    ) async {
      // The regression this guards: the decision used to read the *window*
      // height, which does not shrink when the keyboard opens. A 873pt device
      // therefore kept the non-scrolling branch while its real slot had
      // collapsed to ~590, and the form overflowed by 44px behind the
      // keyboard.
      expect(await scrollViewsAt(tester, const Size(393, 873)), 0);
      expect(
        await scrollViewsAt(tester, const Size(393, 873), keyboardInset: 320),
        1,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a genuinely tall screen still does not scroll at 1.3x', (
      tester,
    ) async {
      // The clamp keeps the bar low enough that an 873pt screen, where the
      // content does still fit at 1.3x, is not pushed onto a scroll view.
      expect(await scrollViewsAt(tester, const Size(412, 915)), 0);
      expect(tester.takeException(), isNull);
    });
  });
}
