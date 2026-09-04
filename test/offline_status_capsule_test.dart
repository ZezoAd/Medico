/// The device-level offline capsule: its collapse-to-nothing contract, its
/// capsule shape, its refresh affordance, and — the point of the redesign —
/// that it is genuinely *docked* above the bottom nav rather than floating
/// over the tab content.
///
/// The shape assertions read the decoration the widget actually builds rather
/// than a golden image — this is a handful of tokens, and a golden would fail
/// on every unrelated pixel while saying nothing about which one moved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/home_screen.dart';
import 'package:medico/screens/home_tab.dart';
import 'package:medico/services/connectivity_service.dart';
import 'package:medico/theme/app_theme.dart';
import 'package:medico/theme/aurora_tokens.dart';
import 'package:medico/widgets/offline_status_capsule.dart';

import 'fake_connectivity.dart';

const _phone = Size(400, 800);

/// Hosts the capsule alone, at a known width.
///
/// [brightness] drives `MediaQuery.platformBrightnessOf`, which is the only
/// thing the widget's palette reads — deliberately not `MaterialApp.themeMode`,
/// since the app ships light-only and would otherwise report light on a dark
/// handset.
/// [visible] is kept as the helper's vocabulary so the shape, sizing and
/// palette tests written before the phase enum existed read unchanged; it maps
/// onto the two settled phases. Pass [phase] directly to reach `confirming`.
Future<void> pumpCapsule(
  WidgetTester tester, {
  bool visible = true,
  ConnectivityPhase? phase,
  VoidCallback? onRefresh,
  Brightness brightness = Brightness.light,
  Size size = _phone,
  double textScale = 1.0,
  String? titleOverride,
  String? subtitleOverride,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          platformBrightness: brightness,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            // Column, not Center: the capsule must be measured where it really
            // sits — taking only the height it asks for.
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                OfflineStatusCapsule(
                  phase:
                      phase ??
                      (visible
                          ? ConnectivityPhase.confirmedOffline
                          : ConnectivityPhase.confirmedOnline),
                  onRefresh: onRefresh,
                  titleOverride: titleOverride,
                  subtitleOverride: subtitleOverride,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The card itself, by key — not "the first Container inside the widget",
/// which would silently re-target one of the two circular buttons.
Finder capsuleFinder() => find.byKey(OfflineStatusCapsule.cardKey);

BoxDecoration capsuleDecoration(WidgetTester tester) =>
    tester.widget<Container>(capsuleFinder()).decoration! as BoxDecoration;

/// The capsule's *own* transitions. Scoped, because MaterialApp wraps every
/// route in a FadeTransition/SlideTransition of its own — those are ancestors
/// of this widget, and an unscoped `find.byType` sweeps them up too.
Finder capsuleFade() => find.descendant(
  of: find.byType(OfflineStatusCapsule),
  matching: find.byType(FadeTransition),
);

Finder capsuleSlide() => find.descendant(
  of: find.byType(OfflineStatusCapsule),
  matching: find.byType(SlideTransition),
);

void main() {
  const message = 'لا يوجد اتصال بالإنترنت حالياً';
  const subMessage = 'سيتم التحديث تلقائياً عند عودة الاتصال';

  group('hidden', () {
    testWidgets('reserves zero space', (tester) async {
      await pumpCapsule(tester, visible: false);

      expect(
        tester.getSize(find.byType(OfflineStatusCapsule)).height,
        0,
        reason:
            'the margins must collapse with the body, not outlive it — a '
            'hidden capsule that still reserved its gutter would sit as a '
            'permanent dead band above the nav bar on every screen',
      );
      expect(find.text(message), findsNothing);
      expect(capsuleFinder(), findsNothing);
    });

    testWidgets('builds no card at all once dismissed', (tester) async {
      await pumpCapsule(tester, visible: false);

      // Slide and fade are paint-time effects and do not shrink the box, so
      // the zero-space contract is kept by not building the row at rest.
      expect(capsuleFade(), findsNothing);
      expect(find.byKey(OfflineStatusCapsule.refreshKey), findsNothing);
    });
  });

  group('visible', () {
    testWidgets('shows both lines and both circular marks', (tester) async {
      await pumpCapsule(tester, visible: true);

      expect(find.text(message), findsOneWidget);
      expect(find.text(subMessage), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Tab-agnostic wording: this renders on Browse, Bookings and Profile
      // too, where the reference's queue-specific line would be false, not
      // merely irrelevant.
      expect(find.textContaining('الدور محفوظ'), findsNothing);
      expect(find.textContaining('دورك'), findsNothing);
    });

    testWidgets('is inset, not edge-to-edge', (tester) async {
      await pumpCapsule(tester, visible: true);

      final width = tester.getSize(capsuleFinder()).width;
      expect(width, _phone.width - (OfflineStatusCapsule.sideMargin * 2));
      expect(width, lessThan(_phone.width));
    });

    testWidgets('floats with real margin on all four sides', (tester) async {
      await pumpCapsule(tester, visible: true);

      final outer = tester.getRect(find.byType(OfflineStatusCapsule));
      final card = tester.getRect(capsuleFinder());

      expect(card.left - outer.left, OfflineStatusCapsule.sideMargin);
      expect(outer.right - card.right, OfflineStatusCapsule.sideMargin);
      expect(
        card.top - outer.top,
        OfflineStatusCapsule.verticalMargin,
        reason: 'space above, so it does not touch the tab content',
      );
      expect(
        outer.bottom - card.bottom,
        OfflineStatusCapsule.verticalMargin,
        reason: 'space below, so it does not sit on the nav bar',
      );
    });

    testWidgets('takes the elevated-card radius, not the old full pill', (
      tester,
    ) async {
      await pumpCapsule(tester, visible: true);

      expect(
        capsuleDecoration(tester).borderRadius,
        BorderRadius.circular(AuroraRadius.lg),
        reason: 'the app-wide elevated-card radius, as on the Profile banner',
      );
      expect(
        capsuleDecoration(tester).borderRadius,
        isNot(BorderRadius.circular(AuroraRadius.pill)),
        reason: 'the dark pill this superseded',
      );
    });

    testWidgets('carries the floating shadow, not a docked or subtle one', (
      tester,
    ) async {
      await pumpCapsule(tester, visible: true);
      final shadow = capsuleDecoration(tester).boxShadow;

      expect(shadow, AuroraShadows.floating);
      expect(shadow, isNot(AuroraShadows.sheet), reason: 'sheet throws upward');
      expect(shadow, isNot(AuroraShadows.pill));
      expect(
        shadow!.single.blurRadius,
        greaterThan(AuroraShadows.card.single.blurRadius),
        reason:
            'a card with air on every side needs more presence than one '
            'resting among others',
      );
    });

    testWidgets('the refresh control meets the 48dp tap target', (
      tester,
    ) async {
      await pumpCapsule(tester, visible: true, onRefresh: () {});

      final size = tester.getSize(find.byKey(OfflineStatusCapsule.refreshKey));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(
        size,
        const Size(
          OfflineStatusCapsule.actionSize,
          OfflineStatusCapsule.actionSize,
        ),
        reason: 'the drawn circle and the hit area must be the same box',
      );
    });

    testWidgets('reads larger than the pill it replaced', (tester) async {
      await pumpCapsule(tester, visible: true);

      expect(
        tester.getSize(capsuleFinder()).height,
        greaterThan(48),
        reason: 'the old pill stood around 28pt',
      );
      expect(
        tester.widget<Text>(find.text(message)).style!.fontSize,
        AuroraFontSize.body,
        reason:
            'was micro (11) on the pill. Stepped back down from bodyLg '
            '(15), which overflowed both strings at 360dp once accessibility '
            'text scaling was applied',
      );
    });

    testWidgets('refresh calls the one-shot recheck', (tester) async {
      var refreshes = 0;
      await pumpCapsule(tester, visible: true, onRefresh: () => refreshes++);

      await tester.tap(find.byKey(OfflineStatusCapsule.refreshKey));
      await tester.pumpAndSettle();

      expect(refreshes, 1);
    });

    testWidgets('a null onRefresh renders refresh disabled, not missing', (
      tester,
    ) async {
      await pumpCapsule(tester, visible: true);

      expect(find.byKey(OfflineStatusCapsule.refreshKey), findsOneWidget);
      expect(
        tester.widget<InkWell>(find.byType(InkWell)).onTap,
        isNull,
        reason: 'a forgotten callback must be visibly dead, not invisible',
      );
    });

    testWidgets('the informational mark is not tappable', (tester) async {
      await pumpCapsule(tester, visible: true, onRefresh: () {});

      // Exactly one InkWell in the whole card: the refresh control. A ripple
      // on the wifi-off mark would promise an action that does not exist.
      expect(find.byType(InkWell), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(OfflineStatusCapsule.infoKey),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });
  });

  /// The narrowest device the app targets, from `profile_tab_test.dart`.
  const narrow = Size(360, 800);

  /// Plausible copy a shade longer than what ships — the same discipline the
  /// doctor-card tests use with their deliberately over-long name, so this
  /// keeps testing something the day someone shortens the real strings.
  const longTitle = 'لا يوجد اتصال بالإنترنت في الوقت الحالي';
  const longSubtitle =
      'سيتم تحديث البيانات تلقائياً فور عودة الاتصال بالإنترنت';

  group('copy never truncates', () {
    /// Every Text the card draws.
    Iterable<Text> capsuleTexts(WidgetTester tester) => tester.widgetList<Text>(
      find.descendant(
        of: find.byType(OfflineStatusCapsule),
        matching: find.byType(Text),
      ),
    );

    for (final scale in [1.0, 1.3]) {
      testWidgets('no ellipsis at 360dp, text scale $scale', (tester) async {
        await pumpCapsule(
          tester,
          visible: true,
          onRefresh: () {},
          size: narrow,
          textScale: scale,
          titleOverride: longTitle,
          subtitleOverride: longSubtitle,
        );

        expect(find.text(longTitle), findsOneWidget);
        expect(find.text(longSubtitle), findsOneWidget);

        for (final text in capsuleTexts(tester)) {
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason:
                'truncating the sentence that explains why the app is not '
                'working is worse than a taller card — it must wrap instead',
          );
          expect(
            text.maxLines,
            isNull,
            reason: 'a line cap is how ellipsis creeps back in',
          );
        }

        // A RenderFlex overflow surfaces as an error during paint, which the
        // binding records as a failure — so pumping at this size with this
        // scale is itself the no-overflow assertion.
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the shipped copy fits the narrowest phone', (tester) async {
      await pumpCapsule(
        tester,
        visible: true,
        onRefresh: () {},
        size: narrow,
        textScale: 1.3,
      );

      expect(find.text(OfflineStatusCapsule.offlineTitle), findsOneWidget);
      expect(find.text(OfflineStatusCapsule.offlineSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('badge sizing', () {
    testWidgets('the info mark is smaller than the 48dp action', (
      tester,
    ) async {
      await pumpCapsule(tester, visible: true, onRefresh: () {});

      final info = tester.getSize(find.byKey(OfflineStatusCapsule.infoKey));
      final action = tester.getSize(
        find.byKey(OfflineStatusCapsule.refreshKey),
      );

      // Nothing taps the info mark, so the 48dp floor does not apply to it.
      expect(info.width, lessThan(action.width));
      expect(info.width, inInclusiveRange(36, 40));
      expect(info.height, inInclusiveRange(36, 40));

      // The action keeps its floor regardless.
      expect(action, const Size(48, 48));
    });
  });

  group('confirming', () {
    testWidgets('stays on screen and swaps to transitional copy', (
      tester,
    ) async {
      await pumpCapsule(
        tester,
        phase: ConnectivityPhase.confirming,
        onRefresh: () {},
      );

      // The fix for "it disappears before I can press the button": the card is
      // still here, and so is its refresh control.
      expect(
        tester.getSize(find.byType(OfflineStatusCapsule)).height,
        greaterThan(0),
      );
      expect(find.byKey(OfflineStatusCapsule.refreshKey), findsOneWidget);

      expect(find.text(OfflineStatusCapsule.confirmingTitle), findsOneWidget);
      expect(
        find.text(OfflineStatusCapsule.confirmingSubtitle),
        findsOneWidget,
      );
      // Not still claiming to be offline — it does not yet know.
      expect(find.text(OfflineStatusCapsule.offlineTitle), findsNothing);
    });

    testWidgets('only confirmedOnline hides it', (tester) async {
      for (final phase in ConnectivityPhase.values) {
        await pumpCapsule(tester, phase: phase);
        final height = tester.getSize(find.byType(OfflineStatusCapsule)).height;

        if (phase == ConnectivityPhase.confirmedOnline) {
          expect(height, 0, reason: '$phase must hide');
        } else {
          expect(height, greaterThan(0), reason: '$phase must stay visible');
        }
      }
    });
  });

  group('palette', () {
    testWidgets('light: white surface on the warm page background', (
      tester,
    ) async {
      await pumpCapsule(tester, visible: true, onRefresh: () {});

      expect(capsuleDecoration(tester).color, AuroraColors.surface);
      expect(
        tester.widget<Text>(find.text(message)).style!.color,
        AuroraColors.ink,
      );
      expect(
        tester.widget<Text>(find.text(subMessage)).style!.color,
        AuroraColors.muted,
      );
      // Actionable carries brand colour; informational is drained of it.
      expect(
        tester.widget<Icon>(find.byIcon(Icons.refresh_rounded)).color,
        AuroraColors.accentOnTonal,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.wifi_off_rounded)).color,
        AuroraColors.muted,
      );
      expect(capsuleDecoration(tester).boxShadow, AuroraShadows.floating);
    });

    testWidgets('stays light on a dark-mode device', (tester) async {
      // The capsule used to resolve platform brightness on its own. On a
      // dark-mode handset that turned it near-black while every surface around
      // it stayed white, and it read as a slab dropped over the page. One
      // palette until the app itself follows the system setting.
      await pumpCapsule(
        tester,
        visible: true,
        onRefresh: () {},
        brightness: Brightness.dark,
      );

      expect(capsuleDecoration(tester).color, AuroraColors.surface);
      expect(
        capsuleDecoration(tester).color,
        isNot(AuroraColors.tonalDark),
        reason: 'the dark palette this dropped',
      );
      expect(
        tester.widget<Text>(find.text(message)).style!.color,
        AuroraColors.ink,
      );
      expect(capsuleDecoration(tester).boxShadow, AuroraShadows.floating);
    });

    testWidgets('renders identically at either brightness', (tester) async {
      await pumpCapsule(tester, visible: true, onRefresh: () {});
      final light = capsuleDecoration(tester);

      await pumpCapsule(
        tester,
        visible: true,
        onRefresh: () {},
        brightness: Brightness.dark,
      );
      final dark = capsuleDecoration(tester);

      expect(dark.color, light.color);
      expect(dark.boxShadow, light.boxShadow);
      expect(dark.borderRadius, light.borderRadius);
    });
  });

  group('motion', () {
    testWidgets('slides and fades rather than collapsing its size', (
      tester,
    ) async {
      await pumpCapsule(tester, visible: true);

      expect(capsuleFade(), findsOneWidget);
      expect(capsuleSlide(), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(OfflineStatusCapsule),
          matching: find.byType(AnimatedSize),
        ),
        findsNothing,
        reason: 'the mechanical size-collapse is what this replaced',
      );
    });

    testWidgets('enters by rising into place over ~300ms', (tester) async {
      await pumpCapsule(tester, visible: false);
      final hidden = tester.getSize(find.byType(OfflineStatusCapsule)).height;
      expect(hidden, 0, reason: 'still zero space at rest while hidden');

      // Flip to visible and step into the middle of the entrance.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Spacer(),
                    OfflineStatusCapsule(
                      phase: ConnectivityPhase.confirmedOffline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final mid = tester.widget<FadeTransition>(capsuleFade());
      expect(
        mid.opacity.value,
        greaterThan(0),
        reason: 'decelerating in, so it is already well past zero at halfway',
      );
      expect(mid.opacity.value, lessThan(1));

      // Still travelling upward into place, not already parked.
      final slide = tester.widget<SlideTransition>(capsuleSlide());
      expect(slide.position.value.dy, greaterThan(0));

      await tester.pumpAndSettle();
      expect(tester.widget<FadeTransition>(capsuleFade()).opacity.value, 1);
      expect(
        tester.widget<SlideTransition>(capsuleSlide()).position.value,
        Offset.zero,
      );
    });

    testWidgets('leaves faster than it arrives, and gives the space back', (
      tester,
    ) async {
      expect(
        OfflineStatusCapsule.exitDuration,
        lessThan(OfflineStatusCapsule.enterDuration),
        reason: 'losing a connection is news; regaining one is a resolution',
      );
      // Both inside the agreed 200-300ms window.
      expect(
        OfflineStatusCapsule.enterDuration.inMilliseconds,
        inInclusiveRange(200, 300),
      );
      expect(
        OfflineStatusCapsule.exitDuration.inMilliseconds,
        inInclusiveRange(200, 300),
      );

      await pumpCapsule(tester, visible: true);
      expect(
        tester.getSize(find.byType(OfflineStatusCapsule)).height,
        greaterThan(0),
      );

      await pumpCapsule(tester, visible: false);
      expect(
        tester.getSize(find.byType(OfflineStatusCapsule)).height,
        0,
        reason: 'the reserved row must be handed back once the exit finishes',
      );
    });
  });

  group('floating on the app shell', () {
    /// Pumps the real [HomeScreen] — the capsule's single app-wide mount point.
    Future<FakeConnectivity> pumpShell(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = _phone;
      addTearDown(tester.view.reset);

      final fake = useFakeConnectivity();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: HomeScreen(connectivityService: fake.service),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('is a Positioned overlay, not a row in a Column', (
      tester,
    ) async {
      final fake = await pumpShell(tester);
      await fake.emitAndSettle(tester, online: false);

      // Replaces the old "plain Column sibling" assertion. The capsule now
      // floats over the tab content instead of displacing it, so a message
      // that is usually absent no longer re-lays-out the page beneath it.
      expect(
        find.ancestor(
          of: find.byType(OfflineStatusCapsule),
          matching: find.byType(Positioned),
        ),
        findsOneWidget,
        reason: 'it must be pinned in the shell Stack, not stacked in a Column',
      );

      final stack = find.ancestor(
        of: find.byType(OfflineStatusCapsule),
        matching: find.byType(Stack),
      );
      expect(
        find.ancestor(of: find.byType(IndexedStack), matching: stack.first),
        findsOneWidget,
        reason: 'capsule and tab content must share one Stack',
      );
    });

    testWidgets('rides above the nav bar without crossing into it', (
      tester,
    ) async {
      final fake = await pumpShell(tester);
      await fake.emitAndSettle(tester, online: false);

      expect(find.text(message), findsOneWidget);

      final capsuleBottom = tester
          .getBottomLeft(find.byType(OfflineStatusCapsule))
          .dy;
      final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;

      // Relative ordering, not a pixel offset.
      expect(
        capsuleBottom,
        lessThanOrEqualTo(navTop),
        reason: 'its bottom edge must never cross into the nav bar',
      );
    });

    testWidgets('does not resize the tab content when it appears', (
      tester,
    ) async {
      final fake = await pumpShell(tester);

      expect(tester.getSize(find.byType(OfflineStatusCapsule)).height, 0);
      final before = tester.getSize(find.byType(IndexedStack)).height;

      await fake.emitAndSettle(tester, online: false);

      expect(
        tester.getSize(find.byType(OfflineStatusCapsule)).height,
        greaterThan(0),
      );
      // The inverse of what the docked version asserted, and the point of the
      // change: the tab keeps its full height and the capsule sits on top.
      expect(
        tester.getSize(find.byType(IndexedStack)).height,
        before,
        reason: 'an overlay must not reflow the page underneath it',
      );
    });

    testWidgets('Home leaves scroll clearance only while it is showing', (
      tester,
    ) async {
      final fake = await pumpShell(tester);

      double homeBottomPadding() => tester
          .widget<SingleChildScrollView>(
            find.descendant(
              of: find.byType(HomeTab),
              matching: find.byType(SingleChildScrollView),
            ),
          )
          .padding!
          .resolve(TextDirection.rtl)
          .bottom;

      final online = homeBottomPadding();

      await fake.emitAndSettle(tester, online: false);

      // Nothing reclaims the space automatically once the capsule overlays, so
      // the scroll view has to leave room for it — and give it back after.
      expect(
        homeBottomPadding() - online,
        OfflineStatusCapsule.overlayClearance,
        reason: 'the last card must still be scrollable clear of the overlay',
      );
    });
  });
}
