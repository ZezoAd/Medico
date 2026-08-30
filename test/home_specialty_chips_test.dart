import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/home_tab.dart';
import 'package:medico/widgets/home_empty_state_card.dart';
import 'package:medico/widgets/home_specialty_chips.dart';

/// Declaration order is display order — see the note in
/// `home_specialty_chips.dart` on why this must not be reversed for RTL.
const labels = [
  'الكل',
  'طب عام',
  'أسنان',
  'نساء وتوليد',
  'أطفال',
  'جلدية',
  'عظام',
  'قلبية',
  'عيون',
];

/// Pumps the real [HomeTab] at a given logical size, in RTL, with animations
/// disabled.
///
/// The disable matters for more than speed: [HomeEmptyStateCard]'s three
/// ambient blobs run on `repeat(reverse: true)` controllers, so a
/// `pumpAndSettle` against a live card never settles. The card already reads
/// `MediaQuery.disableAnimationsOf`, which is the supported way to park them.
///
/// A RenderFlex overflow surfaces as a Flutter error during paint, which the
/// binding records as a test failure — so pumping at each size is itself the
/// no-overflow assertion.
Future<void> pumpHome(WidgetTester tester, Size logical) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: HomeTab()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The gradient-filled box is the selected chip; the tonal ones are not. This
/// reads the paint rather than any private state, so it stays honest about
/// what the patient actually sees.
Finder selectedChipLabel() {
  return find.descendant(
    of: find.descendant(
      of: find.byType(HomeSpecialtyChips),
      matching: find.byWidgetPredicate((w) {
        return w is DecoratedBox &&
            (w.decoration as BoxDecoration).gradient != null;
      }),
    ),
    matching: find.byType(Text),
  );
}

/// The chip row's own [Scrollable] — [HomeTab] also has the page's, so this
/// has to say which.
final chipRow = find.descendant(
  of: find.byType(HomeSpecialtyChips),
  matching: find.byType(Scrollable),
);

/// [label] as rendered *inside the chip row*.
///
/// A bare `find.text` is no longer unambiguous on Home: the Featured Doctors
/// carousel below renders specialty labels drawn from the same vocabulary, so
/// "أسنان", "طب عام" and "عظام" each match a chip *and* a doctor card. That
/// overlap is correct — both name the same specialty — so the fix is for these
/// assertions to say which one they mean, not for either widget to reword.
Finder chipLabel(String label) => find.descendant(
  of: find.byType(HomeSpecialtyChips),
  matching: find.text(label),
);

/// Scrolls [label] into view. The row is lazy, so anything past the viewport
/// is genuinely not built until dragged to — under RTL the later chips sit off
/// the *left* edge, which a positive dx drag pulls in.
Future<void> revealChip(WidgetTester tester, String label) async {
  // Two steps, because they do different things: the drag stops the moment
  // the chip is *built*, which can still leave it hanging off the viewport
  // edge and un-tappable. `ensureVisible` then scrolls it fully in.
  await tester.dragUntilVisible(chipLabel(label), chipRow, const Offset(120, 0));
  await tester.ensureVisible(chipLabel(label));
  await tester.pumpAndSettle();
}

void main() {
  const smallPhone = Size(375, 667);
  const mediumPhone = Size(448, 998);

  testWidgets('sits on Home below the empty-state card', (tester) async {
    await pumpHome(tester, mediumPhone);

    expect(find.byType(HomeSpecialtyChips), findsOneWidget);
    expect(find.text('تصفّح حسب التخصص'), findsOneWidget);

    final cardBottom = tester.getBottomLeft(find.byType(HomeEmptyStateCard)).dy;
    final chipsTop = tester.getTopLeft(find.byType(HomeSpecialtyChips)).dy;
    expect(chipsTop, greaterThan(cardBottom));
  });

  testWidgets('renders all nine specialties, "الكل" rightmost', (tester) async {
    await pumpHome(tester, mediumPhone);

    // Under RTL the list's first item must land against the right edge and
    // each following one further left. The row is lazy, so this only checks
    // the run that is actually built at rest — enough to catch a reversed
    // list, which is the failure mode worth guarding.
    var previousX = double.infinity;
    for (final label in labels) {
      final finder = chipLabel(label);
      if (tester.widgetList(finder).isEmpty) break;
      final x = tester.getTopRight(finder).dx;
      if (x > previousX) {
        fail('"$label" laid out right of the chip before it — list reversed?');
      }
      previousX = x;
    }
    // "الكل" must be in that first run, hard against the right edge.
    expect(chipLabel(labels.first), findsOneWidget);

    // The rest exist, but only once scrolled to.
    for (final label in labels) {
      await revealChip(tester, label);
      expect(chipLabel(label), findsOneWidget, reason: 'missing "$label"');
    }
  });

  testWidgets('defaults to "الكل" and moves the highlight on tap', (
    tester,
  ) async {
    await pumpHome(tester, mediumPhone);

    expect(tester.widget<Text>(selectedChipLabel()).data, 'الكل');

    await tester.tap(chipLabel('أسنان'));
    await tester.pumpAndSettle();

    // Exactly one gradient box: the highlight moved rather than accumulating.
    expect(selectedChipLabel(), findsOneWidget);
    expect(tester.widget<Text>(selectedChipLabel()).data, 'أسنان');
  });

  testWidgets('reports the selected key, and only on a change', (tester) async {
    final keys = <String>[];

    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = mediumPhone * 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: HomeSpecialtyChips(onSpecialtySelected: keys.add),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await revealChip(tester, 'قلبية');
    await tester.tap(chipLabel('قلبية'));
    await tester.pumpAndSettle();
    expect(keys, ['cardiology']);

    // Re-tapping the live chip is not a change and must stay silent.
    await tester.tap(chipLabel('قلبية'));
    await tester.pumpAndSettle();
    expect(keys, ['cardiology']);
  });

  testWidgets('no overflow on a small phone', (tester) async {
    await pumpHome(tester, smallPhone);
    expect(find.byType(HomeSpecialtyChips), findsOneWidget);
  });
}
