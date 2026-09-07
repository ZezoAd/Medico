/// Home's specialty doctor carousel: placement, the capped random draw and its
/// "عرض المزيد" overflow card, fixed card geometry, the excluded rating, and
/// the light/dark palette.
///
/// The row draws a *random* sample from the matching pool, so nothing here may
/// assert which doctors appear — only how many, and that they all belong to the
/// selection. Anything needing a specific doctor pumps a [DoctorCard] directly.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/dev/mock_doctors.dart';
import 'package:medico/models/doctor.dart';
import 'package:medico/screens/home_tab.dart';
import 'package:medico/theme/app_theme.dart';
import 'package:medico/theme/aurora_tokens.dart';
import 'package:medico/widgets/doctor_card.dart';
import 'package:medico/widgets/home_specialty_chips.dart';
import 'package:medico/widgets/home_specialty_doctors.dart';
import 'package:medico/widgets/home_empty_state_card.dart';

import 'fake_connectivity.dart';

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
  FakeConnectivity? connectivity,
}) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.reset);

  final fake = connectivity ?? useFakeConnectivity();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: HomeTab(connectivityService: fake.service)),
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
              width: DoctorCard.preferredWidth,
              height: DoctorCard.preferredHeight,
              child: DoctorCard(doctor: doctor),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Hosts the carousel on its own at [selectedSpecialtyKey], without Home's
/// empty-state card above it — the filter has nothing to do with that card, and
/// leaving it out keeps the whole list within reach of a short scroll.
///
/// Re-pumping lands on the same [State], which is what makes this the harness
/// for the cache: a second call with a different key is a chip tap, and one
/// with a different [refreshEpoch] is a refresh.
Future<void> pumpCarousel(
  WidgetTester tester,
  Size logical,
  String selectedSpecialtyKey, {
  int refreshEpoch = 0,
}) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = logical * 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AuroraSpacing.lg),
            child: HomeSpecialtyDoctors(
              selectedSpecialtyKey: selectedSpecialtyKey,
              refreshEpoch: refreshEpoch,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every doctor name in the carousel, dragging the row to its end so the lazy
/// viewport builds all of them.
///
/// A count taken from whatever happens to be built at rest would pass for a
/// filter that returned too many, since only the first two or three are ever
/// on screen. Returns a set: names are the fixture's identity here.
Future<Set<String>> scrollAllCardNames(WidgetTester tester) async {
  final row = find.descendant(
    of: find.byType(HomeSpecialtyDoctors),
    matching: find.byType(Scrollable),
  );
  if (tester.widgetList(row).isEmpty) return {};

  final names = <String>{};
  // Under RTL the row extends off the *left* edge, which a positive dx drag
  // pulls into view. Progress is read off the scroll offset rather than off a
  // card's position — which card is `.first` changes as the viewport recycles,
  // so comparing that would compare two different widgets. Bounded rather than
  // while(true): a row that will not scroll must end the loop, not hang.
  final position = tester.state<ScrollableState>(row).position;
  // Rewound first, so calling this twice in one test sees the whole row the
  // second time instead of resuming from the end with the head unbuilt.
  position.jumpTo(0);
  await tester.pumpAndSettle();
  for (var i = 0; i < 40; i++) {
    for (final card in tester.widgetList<DoctorCard>(find.byType(DoctorCard))) {
      names.add(card.doctor.name);
    }
    if (position.pixels >= position.maxScrollExtent) break;
    await tester.drag(row, const Offset(300, 0));
    await tester.pumpAndSettle();
  }
  return names;
}

/// The over-long name and clinic, copied from `mock_doctors.dart`'s `mock-6`.
///
/// Copied rather than looked up: this fixture's whole job is to be too long,
/// and a test that reached into the mock list would quietly stop testing
/// anything the day someone shortened that entry. Unrated, matching the mocks —
/// the rating is irrelevant here either way, since the card reserves the pill's
/// row whether or not a score exists.
const _longName = Doctor(
  id: 't3',
  name: 'د. عبدالرحمن ياسين الموسوي الكناني',
  specialty: 'طب عام',
  specialtyKey: 'general',
  clinicName: 'مجمع الشفاء للرعاية الصحية التخصصية',
);

const _rated = Doctor(
  id: 't1',
  name: 'د. زينب قاسم',
  specialty: 'أسنان',
  specialtyKey: 'dental',
  clinicName: 'لؤلؤة للأسنان',
  rating: 4.9,
);

/// The same doctor with no score — the state a real backend will hand back for
/// every doctor until a review system exists.
const _unrated = Doctor(
  id: 't2',
  name: 'د. زينب قاسم',
  specialty: 'أسنان',
  specialtyKey: 'dental',
  clinicName: 'لؤلؤة للأسنان',
);

void main() {
  const smallPhone = Size(375, 667);
  const mediumPhone = Size(448, 998);

  testWidgets('sits on Home directly below the specialty chips', (
    tester,
  ) async {
    await pumpHome(tester, mediumPhone);

    expect(find.byType(HomeSpecialtyDoctors), findsOneWidget);

    final chipsBottom = tester
        .getBottomLeft(find.byType(HomeSpecialtyChips))
        .dy;
    final carouselTop = tester.getTopLeft(find.byType(HomeSpecialtyDoctors)).dy;
    expect(carouselTop, greaterThan(chipsBottom));
    // The section carries no heading of its own — the chip row above already
    // names the selection. What separates them is deliberately *tighter* than
    // the AuroraSpacing.xxl between every other pair of sections on Home: the
    // chips are this row's control rather than a section of their own, and the
    // 12pt they give back is what keeps a whole card above the fold.
    expect(carouselTop - chipsBottom, AuroraSpacing.md);
  });

  /// The Tecno Camon 20 Pro in logical pixels — 1080×2400 at its 2.75 device
  /// pixel ratio. The primary real-world target, and the one this card's
  /// height was actually sized against.
  const tecno = Size(393, 873);

  /// What the shell's [NavigationBar] and the system navigation bar take off
  /// the bottom of [tecno] before Home's scroll view sees it.
  ///
  /// [pumpHome] hosts [HomeTab] in a bare Scaffold with no bottom navigation,
  /// so the test viewport is taller than the real one — measuring against the
  /// full 873 would pass while the CTA sat under the nav bar on the device.
  /// Read off a screenshot of the running app: the shell's bar starts at ~764.
  const shellChrome = 109.0;

  testWidgets('a whole card clears the bottom nav on the target phone', (
    tester,
  ) async {
    await pumpHome(tester, tecno);

    final card = find.byType(DoctorCard).first;
    final fold = tecno.height - shellChrome;
    expect(
      tester.getBottomLeft(card).dy,
      lessThanOrEqualTo(fold),
      reason:
          'the card runs under the bottom navigation bar — its CTA is the '
          'one control on the card and must not need a scroll to reach',
    );
  });

  testWidgets('a whole card is on screen at rest on the target phone', (
    tester,
  ) async {
    // The point of both the card's 210×300 and the tightened chips-to-carousel
    // gap: at rest, without scrolling, a patient must see a complete doctor
    // card — CTA included — rather than one cut off by the bottom of the
    // screen. A card whose booking button is below the fold reads as the end of
    // the page rather than as something to act on.
    //
    // Asserted at [mediumPhone] because that is the primary target. It is
    // **not** true on [smallPhone], and no gap on this page can make it true:
    // at 375×667 the card's top lands at ~531, so the fold cuts it with 164pt
    // still to go. Closing that needs the empty-state hero above it to shrink
    // or go, which is a separate decision — the hero is a deliberate
    // placeholder for the queue card. Do not "fix" this by asserting the small
    // phone here; it will just fail.
    await pumpHome(tester, mediumPhone);

    expect(
      tester.getBottomLeft(find.byType(DoctorCard).first).dy,
      lessThanOrEqualTo(mediumPhone.height),
      reason: 'the first card is clipped by the fold at rest',
    );
  });

  testWidgets('cards keep their designed size regardless of content length', (
    tester,
  ) async {
    await pumpHome(tester, mediumPhone);

    final cards = find.byType(DoctorCard);
    expect(cards, findsWidgets);

    // Every built card, including the one whose name and clinic are far longer
    // than the others. Equal heights are what the clinic row's Expanded buys.
    for (final size
        in tester
            .widgetList<DoctorCard>(cards)
            .indexed
            .map((e) => tester.getSize(cards.at(e.$1)))) {
      expect(size.width, DoctorCard.preferredWidth);
      expect(size.height, DoctorCard.preferredHeight);
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
    // Pumped directly rather than hunted for on Home. The carousel now shows a
    // random sample, so scrolling the row until this doctor appears would fail
    // whenever the draw left them out — a flake, not a regression. The card is
    // what is under test here anyway; how it got on screen is beside the point.
    await pumpCard(tester, _longName);

    // Flutter's own truncation does the work — there is no manual
    // character-clipping anywhere in the widget.
    final name = find.text('د. عبدالرحمن ياسين الموسوي الكناني');
    final text = tester.widget<Text>(name);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  /// The banner redesign dropped the rating pill outright — the card no longer
  /// reads [Doctor.rating] at all, where the 200×236 card rendered a pill
  /// whenever a score was present. These now guard the *exclusion*, against a
  /// locally rated fixture rather than against the mocks, which is what lets
  /// the mock data carry no scores while this still means something.
  group('rating', () {
    test('no mock doctor carries a score', () {
      expect(
        mockDoctors.where((doctor) => doctor.rating != null),
        isEmpty,
        reason: 'reviews are V2; placeholder people must not invent figures',
      );
    });

    testWidgets('no rating pill appears anywhere on Home', (tester) async {
      await pumpHome(tester, mediumPhone);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('a scored doctor still renders no rating anywhere', (
      tester,
    ) async {
      await pumpCard(tester, _rated);

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text('4.9'), findsNothing);
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

    testWidgets('a scored card is laid out identically to an unscored one', (
      tester,
    ) async {
      await pumpCard(tester, _rated);
      final rated = tester.getSize(find.byType(DoctorCard));

      await pumpCard(tester, _unrated);
      final unrated = tester.getSize(find.byType(DoctorCard));

      expect(unrated, rated);
    });
  });

  group('banner and avatar', () {
    /// The gradient banner: the first of the card's two [AuroraGradients.aurora]
    /// boxes, the other being the CTA at the foot.
    Finder banner() => find
        .byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient ==
                  AuroraGradients.aurora,
        )
        .first;

    testWidgets('the banner cuts the avatar across its middle', (tester) async {
      await pumpCard(tester, _unrated);

      // The initials stand in for the avatar's centre — no fixture here
      // carries a photo, which is the state nearly every real doctor is in.
      final avatar = find.text('ز.ق');
      expect(avatar, findsOneWidget);

      // The whole point of the shape: the gradient's lower edge passes through
      // the avatar's centre line, so the avatar reads as bisected by the
      // banner rather than as dropped on top of it and clipped near its foot.
      expect(
        tester.getCenter(avatar).dy,
        closeTo(tester.getBottomLeft(banner()).dy, 1.0),
      );
    });

    testWidgets('the avatar straddles the banner and the card body', (
      tester,
    ) async {
      await pumpCard(tester, _unrated);

      final avatar = find.text('ز.ق');
      final cardTop = tester.getTopLeft(find.byType(DoctorCard)).dy;
      final cardBottom = tester.getBottomLeft(find.byType(DoctorCard)).dy;
      final cardHeight = cardBottom - cardTop;
      final avatarCentre = tester.getCenter(avatar).dy - cardTop;

      // Stated as a fraction of the card rather than in points, so resizing
      // the card does not silently retune the assertion — an earlier absolute
      // threshold here was pinned to a banner height that has since changed.
      // Straddling means the avatar's centre is well clear of the top edge and
      // still in the card's upper half.
      expect(avatarCentre, greaterThan(cardHeight * 0.10));
      expect(avatarCentre, lessThan(cardHeight * 0.45));
    });

    testWidgets('the hairlines bracket the clinic tightly, not a gap', (
      tester,
    ) async {
      await pumpCard(tester, _longName);

      // The clinic's own two lines, and little else. The band used to be the
      // column's flex child, so it swallowed every spare point in the card and
      // the rules read as a box rather than as a bracket.
      final clinic = find.text(_longName.clinicName);
      expect(clinic, findsOneWidget);

      final clinicHeight = tester.getSize(clinic).height;
      final band = tester
          .getSize(
            find.ancestor(of: clinic, matching: find.byType(SizedBox)).first,
          )
          .height;

      expect(
        band - clinicHeight,
        lessThan(AuroraSpacing.md),
        reason: 'the hairlines are bracketing air, not the clinic name',
      );
    });

    testWidgets('the CTA runs the full width inside the card gutter', (
      tester,
    ) async {
      await pumpCard(tester, _unrated);

      final cta = find.text('احجز الآن');
      expect(cta, findsOneWidget);

      final cardWidth = tester.getSize(find.byType(DoctorCard)).width;
      final ctaWidth = tester
          .getSize(find.ancestor(of: cta, matching: find.byType(InkWell)))
          .width;

      // The card's 16pt side gutter either side, and nothing else.
      expect(ctaWidth, cardWidth - AuroraSpacing.lg * 2);
    });
  });

  group('theme', () {
    testWidgets('takes its colours from the light palette', (tester) async {
      await pumpCard(tester, _rated, mode: ThemeMode.light);

      expect(
        tester.widget<Text>(find.text('د. زينب قاسم')).style!.color,
        AuroraPalette.light.ink,
      );
      expect(
        tester.widget<Text>(find.text('أسنان')).style!.color,
        AuroraPalette.light.accentOnTonal,
      );
      // The initials, which are the avatar's normal state rather than a
      // fallback — and the one place the card's teal has to hold as *type* on
      // a tinted fill rather than as a gradient behind white.
      expect(
        tester.widget<Text>(find.text('ز.ق')).style!.color,
        AuroraPalette.light.accentOnTonal,
      );
    });

    testWidgets('and the dark palette in dark mode', (tester) async {
      await pumpCard(tester, _rated, mode: ThemeMode.dark);

      expect(
        tester.widget<Text>(find.text('د. زينب قاسم')).style!.color,
        AuroraPalette.dark.ink,
      );
      expect(
        tester.widget<Text>(find.text('أسنان')).style!.color,
        AuroraPalette.dark.accentOnTonal,
      );
      expect(
        tester.widget<Text>(find.text('ز.ق')).style!.color,
        AuroraPalette.dark.accentOnTonal,
      );
    });

    testWidgets('renders on Home in dark mode without overflowing', (
      tester,
    ) async {
      await pumpHome(tester, smallPhone, mode: ThemeMode.dark);
      expect(find.byType(HomeSpecialtyDoctors), findsOneWidget);
    });
  });

  group('specialty filter', () {
    const emptyMessage = 'لا يوجد أطباء في هذا التخصص حالياً';
    const showMore = 'عرض المزيد';
    const allKey = HomeSpecialtyDoctors.allSpecialtiesKey;

    /// The full pool for [key], before the cap.
    Set<String> poolFor(String key) => {
      for (final doctor in mockDoctors)
        if (key == allKey || doctor.specialtyKey == key) doctor.name,
    };

    int capFor(String key) => key == allKey
        ? HomeSpecialtyDoctors.allSpecialtiesCap
        : HomeSpecialtyDoctors.perSpecialtyCap;

    /// Asserts the row for [key] draws exactly `min(pool, cap)` doctors, all
    /// of them from the pool, and shows the overflow card iff the pool
    /// outran the cap.
    Future<void> expectCappedDraw(WidgetTester tester, String key) async {
      final pool = poolFor(key);
      final cap = capFor(key);
      final expected = pool.length < cap ? pool.length : cap;

      final seen = await scrollAllCardNames(tester);

      expect(seen.length, expected, reason: 'wrong number drawn for "$key"');
      // The draw is random, so which names came up is not assertable — that
      // they all belong to the selection is.
      expect(pool.containsAll(seen), isTrue, reason: 'drew outside "$key"');
      expect(
        find.text(showMore),
        pool.length > cap ? findsOneWidget : findsNothing,
      );
    }

    testWidgets('"all" draws allSpecialtiesCap of a larger pool', (
      tester,
    ) async {
      expect(
        poolFor(allKey).length,
        greaterThan(HomeSpecialtyDoctors.allSpecialtiesCap),
        reason: 'the fixture must overflow the cap for this to mean anything',
      );

      await pumpCarousel(tester, mediumPhone, allKey);

      await expectCappedDraw(tester, allKey);
      expect(find.text(emptyMessage), findsNothing);
    });

    testWidgets('an over-full specialty is capped and offers "عرض المزيد"', (
      tester,
    ) async {
      // `general` is stocked past perSpecialtyCap on purpose — see the note in
      // `mock_doctors.dart`. This asserts that rather than assuming it.
      expect(
        poolFor('general').length,
        greaterThan(HomeSpecialtyDoctors.perSpecialtyCap),
      );

      await pumpCarousel(tester, mediumPhone, 'general');

      await expectCappedDraw(tester, 'general');
    });

    testWidgets(
      'an under-full specialty shows all of it and no overflow card',
      (tester) async {
        expect(
          poolFor('obgyn').length,
          lessThan(HomeSpecialtyDoctors.perSpecialtyCap),
        );

        await pumpCarousel(tester, mediumPhone, 'obgyn');

        await expectCappedDraw(tester, 'obgyn');
        // The whole pool, not a sample, since it fits under the cap.
        expect(await scrollAllCardNames(tester), poolFor('obgyn'));
      },
    );

    testWidgets('a specialty nobody practises shows the empty message', (
      tester,
    ) async {
      // `ophthalmology` is deliberately unstaffed in `mock_doctors.dart` — see
      // the note there. If a doctor is ever filed under it, this fails loudly
      // rather than silently stopping testing the empty state.
      expect(poolFor('ophthalmology'), isEmpty);

      await pumpCarousel(tester, mediumPhone, 'ophthalmology');

      expect(find.text(emptyMessage), findsOneWidget);
      // Replaced, not merely emptied: no card and no leftover scroll strip.
      expect(find.byType(DoctorCard), findsNothing);
      expect(find.text(showMore), findsNothing);
      expect(
        find.descendant(
          of: find.byType(HomeSpecialtyDoctors),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
    });

    testWidgets('tapping a chip on Home filters the carousel below', (
      tester,
    ) async {
      await pumpHome(tester, mediumPhone);

      // "أسنان" has exactly one doctor, so the row must shrink to it.
      final chip = find.descendant(
        of: find.byType(HomeSpecialtyChips),
        matching: find.text('أسنان'),
      );
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(await scrollAllCardNames(tester), poolFor('dental'));
      expect(find.text(showMore), findsNothing);
    });

    testWidgets('the draw survives an unrelated rebuild', (tester) async {
      // "all" rather than a specialty: its pool of 16 into a cap of 10 gives
      // 8008 possible hands, so a hand that comes back identical is evidence
      // of a cache hit rather than of a lucky reshuffle. Against `general`'s
      // 6-into-5 the same assertion would pass one time in six even with the
      // caching removed.
      await pumpCarousel(tester, mediumPhone, allKey);
      final first = await scrollAllCardNames(tester);

      // Re-pumped with the same key and the same epoch: a new widget instance
      // reaching the same State, which is what a parent setState does. Nothing
      // was invalidated, so `didUpdateWidget` must find the entry already in
      // the cache and leave it alone. A shuffle in build() would deal a fresh
      // hand here — which is what would reshuffle the row under the patient's
      // finger mid-scroll.
      await pumpCarousel(tester, mediumPhone, allKey);

      expect(await scrollAllCardNames(tester), first);
    });
  });

  /// The refresh epoch is the only thing allowed to deal a new hand. Selecting
  /// a specialty picks which remembered hand to show; it never causes one.
  group('refresh epoch', () {
    const allKey = HomeSpecialtyDoctors.allSpecialtiesKey;

    testWidgets('a round trip through another specialty shows the same '
        'doctors, not just the same count', (tester) async {
      await pumpCarousel(tester, mediumPhone, allKey);
      final first = await scrollAllCardNames(tester);
      expect(first, hasLength(HomeSpecialtyDoctors.allSpecialtiesCap));

      // Away to a specialty with its own draw, then back. The old behaviour
      // redrew on every key change, so coming back dealt a fresh hand — the
      // row looked like it had quietly refreshed itself for no reason.
      await pumpCarousel(tester, mediumPhone, 'dental');
      await pumpCarousel(tester, mediumPhone, allKey);

      expect(
        await scrollAllCardNames(tester),
        first,
        reason: 'returning to a chip must return to the same people',
      );
    });

    testWidgets('the away-and-back draw is itself remembered', (tester) async {
      // The cache must hold every key visited this epoch, not just the last
      // one — otherwise A→B→A→B hands B a new draw.
      await pumpCarousel(tester, mediumPhone, 'general');
      final general = await scrollAllCardNames(tester);

      await pumpCarousel(tester, mediumPhone, allKey);
      final all = await scrollAllCardNames(tester);

      await pumpCarousel(tester, mediumPhone, 'general');
      expect(await scrollAllCardNames(tester), general);

      await pumpCarousel(tester, mediumPhone, allKey);
      expect(await scrollAllCardNames(tester), all);
    });

    testWidgets('bumping the epoch clears the cache and redraws', (
      tester,
    ) async {
      await pumpCarousel(tester, mediumPhone, allKey);
      final first = await scrollAllCardNames(tester);

      // A single redraw cannot be asserted directly: a fresh shuffle may
      // legitimately deal the same 10 of 16 again. Across five bumps, though,
      // "every hand identical to the first" has probability (1/8008)^4 if the
      // cache really is being cleared — so a run where nothing ever differs is
      // a broken cache, not bad luck. Conversely each hand is still checked
      // for being a valid capped draw, so a redraw that returned junk fails
      // here too.
      final pool = {for (final doctor in mockDoctors) doctor.name};
      var sawDifferent = false;

      for (var epoch = 1; epoch <= 5; epoch++) {
        await pumpCarousel(tester, mediumPhone, allKey, refreshEpoch: epoch);
        final hand = await scrollAllCardNames(tester);

        expect(hand, hasLength(HomeSpecialtyDoctors.allSpecialtiesCap));
        expect(pool.containsAll(hand), isTrue);
        if (!setEquals(hand, first)) sawDifferent = true;
      }

      expect(
        sawDifferent,
        isTrue,
        reason:
            'five refreshes all dealing the identical hand means the '
            'cache was never cleared',
      );
    });

    testWidgets('an epoch bump invalidates the specialties not on screen too', (
      tester,
    ) async {
      // Drawn during epoch 0, then left behind while "all" is shown.
      await pumpCarousel(tester, mediumPhone, 'general');
      await pumpCarousel(tester, mediumPhone, allKey);
      final beforeRefresh = await scrollAllCardNames(tester);

      // The refresh happens while "all" is selected; `general`'s stale entry
      // must go with it rather than surviving until its chip is next tapped.
      var sawDifferent = false;
      for (var epoch = 1; epoch <= 5; epoch++) {
        await pumpCarousel(tester, mediumPhone, 'general', refreshEpoch: epoch);
        await pumpCarousel(tester, mediumPhone, allKey, refreshEpoch: epoch);
        if (!setEquals(await scrollAllCardNames(tester), beforeRefresh)) {
          sawDifferent = true;
        }
      }

      expect(sawDifferent, isTrue);
    });

    testWidgets('coming back online bumps the epoch; going offline does not', (
      tester,
    ) async {
      final connectivity = useFakeConnectivity();
      await pumpHome(tester, mediumPhone, connectivity: connectivity);

      HomeSpecialtyDoctors carousel() => tester.widget<HomeSpecialtyDoctors>(
        find.byType(HomeSpecialtyDoctors),
      );

      expect(carousel().refreshEpoch, 0);

      // The first emission only confirms what the device was already doing.
      // Counting it as a reconnect would refresh Home on every launch.
      await connectivity.emitAndSettle(tester, online: false);
      expect(
        carousel().refreshEpoch,
        0,
        reason:
            'losing the network refreshes nothing — there is nothing to '
            'fetch, and the first emission has no predecessor anyway',
      );

      await connectivity.emitAndSettle(tester, online: true);
      expect(carousel().refreshEpoch, 1);

      // Redundant "still online" events are already swallowed by the service,
      // but the tab must not count them either if one ever gets through.
      await connectivity.emitAndSettle(tester, online: true);
      expect(carousel().refreshEpoch, 1);
    });

    /// Drags the scrolling half of the tab down far enough to trigger the
    /// indicator. Anchored on the hero card because it is always on screen at
    /// rest; 300 comfortably clears the trigger distance.
    Future<void> pullToRefresh(WidgetTester tester) async {
      await tester.fling(
        find.byType(HomeEmptyStateCard),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();
    }

    int epochOf(WidgetTester tester) => tester
        .widget<HomeSpecialtyDoctors>(find.byType(HomeSpecialtyDoctors))
        .refreshEpoch;

    testWidgets('pull-to-refresh re-checks connectivity and bumps the epoch', (
      tester,
    ) async {
      final connectivity = useFakeConnectivity();
      await pumpHome(tester, mediumPhone, connectivity: connectivity);

      expect(find.byType(RefreshIndicator), findsOneWidget);
      final probesBefore = connectivity.probeCount;

      await pullToRefresh(tester);

      expect(
        connectivity.probeCount,
        greaterThan(probesBefore),
        reason: 'a pull must freshen the offline strip, not only the content',
      );
      expect(epochOf(tester), 1);
    });

    testWidgets('a pull while offline asks, but rerolls nothing', (
      tester,
    ) async {
      final connectivity = useFakeConnectivity(online: false);
      await pumpHome(tester, mediumPhone, connectivity: connectivity);

      await connectivity.emitAndSettle(tester, online: false);
      expect(epochOf(tester), 0);

      final before = await scrollAllCardNames(tester);
      final probesBefore = connectivity.probeCount;

      // Three pulls, because the bug this covers was only obvious on repeat:
      // in airplane mode each pull dealt a visibly different set of doctors,
      // so the screen kept claiming to have fetched something over a
      // connection that did not exist.
      for (var i = 0; i < 3; i++) {
        await pullToRefresh(tester);
      }

      expect(
        connectivity.probeCount,
        greaterThan(probesBefore),
        reason: 'the pull must still ask — that is how the strip stays honest',
      );
      expect(
        epochOf(tester),
        0,
        reason: 'an offline pull must not invalidate anything',
      );
      expect(
        await scrollAllCardNames(tester),
        before,
        reason: 'the same doctors, not a fresh draw',
      );
    });

    testWidgets('a pull that finds the network back on does refresh', (
      tester,
    ) async {
      final connectivity = useFakeConnectivity(online: false);
      await pumpHome(tester, mediumPhone, connectivity: connectivity);

      await connectivity.emitAndSettle(tester, online: false);

      // Back online, but silently — the plugin never said so, which is the
      // case the probe inside the pull exists to catch. The reconnect is
      // noticed by checkNow's own emission, so the epoch moves.
      connectivity.changeSilently(online: true);
      await pullToRefresh(tester);

      expect(epochOf(tester), greaterThan(0));
    });
  });

  testWidgets('no overflow on a small phone', (tester) async {
    await pumpHome(tester, smallPhone);
    expect(find.byType(HomeSpecialtyDoctors), findsOneWidget);
  });
}
