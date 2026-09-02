/// Home's Featured Doctors carousel: placement, fixed card geometry, the
/// nullable rating, and the light/dark palette.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/models/doctor.dart';
import 'package:medico/screens/home_tab.dart';
import 'package:medico/theme/app_theme.dart';
import 'package:medico/theme/aurora_tokens.dart';
import 'package:medico/widgets/home_featured_doctors.dart';
import 'package:medico/widgets/home_specialty_chips.dart';

/// Pumps the real [HomeTab]. Animations are disabled because the empty-state
/// card's ambient blobs run on repeating controllers, so `pumpAndSettle`
/// against a live card never settles — see `home_specialty_chips_test.dart`.
///
/// A RenderFlex overflow surfaces as an error during paint, which the binding
/// records as a failure, so pumping at a given size *is* the no-overflow
/// assertion for that size.
Future<void> pumpHome(
  WidgetTester tester,
  Size logical, {
  ThemeMode mode = ThemeMode.light,
}) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: HomeTab()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Hosts a single [DoctorCard] at the size the carousel gives it.
Future<void> pumpCard(
  WidgetTester tester,
  Doctor doctor, {
  ThemeMode mode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 236,
              child: DoctorCard(doctor: doctor),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _rated = Doctor(
  id: 't1',
  name: 'د. زينب قاسم',
  specialty: 'أسنان',
  clinicName: 'لؤلؤة للأسنان',
  rating: 4.9,
);

/// The same doctor with no score — the state a real backend will hand back for
/// every doctor until a review system exists.
const _unrated = Doctor(
  id: 't2',
  name: 'د. زينب قاسم',
  specialty: 'أسنان',
  clinicName: 'لؤلؤة للأسنان',
);

void main() {
  const smallPhone = Size(375, 667);
  const mediumPhone = Size(448, 998);

  testWidgets('sits on Home directly below the specialty chips', (
    tester,
  ) async {
    await pumpHome(tester, mediumPhone);

    expect(find.byType(HomeFeaturedDoctors), findsOneWidget);
    expect(find.text('أطباء مميزون'), findsOneWidget);

    final chipsBottom = tester
        .getBottomLeft(find.byType(HomeSpecialtyChips))
        .dy;
    final featuredTop = tester.getTopLeft(find.byType(HomeFeaturedDoctors)).dy;
    expect(featuredTop, greaterThan(chipsBottom));
  });

  testWidgets('heading matches the chip heading\'s style exactly', (
    tester,
  ) async {
    await pumpHome(tester, mediumPhone);

    final featured = tester.widget<Text>(find.text('أطباء مميزون')).style!;
    final chips = tester.widget<Text>(find.text('تصفّح حسب التخصص')).style!;

    expect(featured.fontSize, chips.fontSize);
    expect(featured.fontWeight, chips.fontWeight);
    expect(featured.fontFamily, chips.fontFamily);
    expect(featured.color, chips.color);
  });

  testWidgets('cards keep a fixed 200x236 regardless of content length', (
    tester,
  ) async {
    await pumpHome(tester, mediumPhone);

    final cards = find.byType(DoctorCard);
    expect(cards, findsWidgets);

    // Every built card, including the one whose name and clinic are far longer
    // than the others. Equal heights are what the clinic row's Expanded buys.
    for (final size in tester.widgetList<DoctorCard>(cards).indexed.map(
      (e) => tester.getSize(cards.at(e.$1)),
    )) {
      expect(size.width, 200);
      expect(size.height, 236);
    }
  });

  testWidgets('the next card peeks at rest', (tester) async {
    await pumpHome(tester, smallPhone);

    final cards = find.byType(DoctorCard);
    expect(
      tester.widgetList(cards).length,
      greaterThan(1),
      reason: 'a second card must be partly on screen without scrolling',
    );

    // Under RTL the first card sits against the right edge and the second is
    // to its left, so a lower right-edge x means "further along the row".
    final first = tester.getTopRight(cards.at(0)).dx;
    final second = tester.getTopRight(cards.at(1)).dx;
    expect(second, lessThan(first));
  });

  testWidgets('the name ellipsises on one line rather than wrapping', (
    tester,
  ) async {
    await pumpHome(tester, mediumPhone);

    // The deliberately over-long mock name. Flutter's own truncation does the
    // work — there is no manual character-clipping anywhere in the widget.
    final name = find.text('د. عبدالرحمن ياسين الموسوي الكناني');
    await tester.scrollUntilVisible(name, 200, scrollable: find.descendant(
      of: find.byType(HomeFeaturedDoctors),
      matching: find.byType(Scrollable),
    ));
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(name);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  group('rating', () {
    testWidgets('renders in Western digits when present', (tester) async {
      await pumpCard(tester, _rated);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('٤٫٩'), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('pill is hidden entirely when the score is null', (
      tester,
    ) async {
      await pumpCard(tester, _unrated);

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      // Nothing stands in for it either — no zero, no placeholder dash. Match
      // on the rating's shape rather than on "contains a dot", which the
      // initials ("ز.ق") and the honorific ("د.") both legitimately do.
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'^\d+([.,]\d+)?$').hasMatch(w.data ?? ''),
        ),
        findsNothing,
      );
    });

    testWidgets('an unrated card is the same height as a rated one', (
      tester,
    ) async {
      await pumpCard(tester, _rated);
      final rated = tester.getSize(find.byType(DoctorCard));

      await pumpCard(tester, _unrated);
      final unrated = tester.getSize(find.byType(DoctorCard));

      expect(unrated, rated);
    });

    testWidgets('the pill sits in the true physical left corner under RTL', (
      tester,
    ) async {
      await pumpCard(tester, _rated);

      final cardLeft = tester.getTopLeft(find.byType(DoctorCard)).dx;
      final cardRight = tester.getTopRight(find.byType(DoctorCard)).dx;
      final pillLeft = tester.getTopLeft(find.byIcon(Icons.star_rounded)).dx;

      // Left half, comfortably — an AlignmentDirectional.topStart would have
      // mirrored it to the right under this Directionality.
      expect(pillLeft, lessThan((cardLeft + cardRight) / 2));
    });
  });

  group('theme', () {
    testWidgets('takes its colours from the light palette', (tester) async {
      await pumpCard(tester, _rated, mode: ThemeMode.light);

      expect(
        tester.widget<Text>(find.text('4.9')).style!.color,
        AuroraPalette.light.ratingAmber,
      );
      expect(
        tester.widget<Text>(find.text('أسنان')).style!.color,
        AuroraPalette.light.accentOnTonal,
      );
    });

    testWidgets('and the dark palette in dark mode', (tester) async {
      await pumpCard(tester, _rated, mode: ThemeMode.dark);

      expect(
        tester.widget<Text>(find.text('4.9')).style!.color,
        AuroraPalette.dark.ratingAmber,
      );
      expect(
        tester.widget<Text>(find.text('أسنان')).style!.color,
        AuroraPalette.dark.accentOnTonal,
      );
    });

    testWidgets('renders on Home in dark mode without overflowing', (
      tester,
    ) async {
      await pumpHome(tester, smallPhone, mode: ThemeMode.dark);
      expect(find.byType(HomeFeaturedDoctors), findsOneWidget);
    });
  });

  testWidgets('no overflow on a small phone', (tester) async {
    await pumpHome(tester, smallPhone);
    expect(find.byType(HomeFeaturedDoctors), findsOneWidget);
  });
}
