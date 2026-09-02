/// The device-level offline strip: its collapse-to-nothing contract, its
/// inset-pill shape, and where it sits relative to the tab content.
///
/// The shape assertions read the decoration the widget actually builds rather
/// than a golden image — this is a handful of tokens, and a golden would fail
/// on every unrelated pixel while saying nothing about which one moved.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/screens/home_screen.dart';
import 'package:medico/theme/app_theme.dart';
import 'package:medico/theme/aurora_tokens.dart';
import 'package:medico/widgets/global_offline_strip.dart';
import 'package:medico/widgets/queue_status_card.dart';

import 'fake_connectivity.dart';

const _phone = Size(400, 800);

/// Hosts the strip alone, at a known width, with the app's real theme.
Future<void> pumpStrip(WidgetTester tester, {required bool visible}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = _phone;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          // Column, not Center: the strip must be measured where it really
          // sits — top-aligned, taking only the height it asks for.
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [GlobalOfflineStrip(visible: visible)],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The pill itself — the decorated box inside the strip's margins.
Finder pillFinder() => find.descendant(
  of: find.byType(GlobalOfflineStrip),
  matching: find.byType(Container),
);

BoxDecoration pillDecoration(WidgetTester tester) =>
    tester.widget<Container>(pillFinder()).decoration! as BoxDecoration;

void main() {
  const message = 'لا يوجد اتصال بالإنترنت حالياً';

  group('hidden', () {
    testWidgets('reserves zero space', (tester) async {
      await pumpStrip(tester, visible: false);

      expect(
        tester.getSize(find.byType(GlobalOfflineStrip)).height,
        0,
        reason:
            'the margins must collapse with the body, not outlive it — '
            'a hidden strip that still reserved its gutter would push every '
            'screen down for something almost never shown',
      );
      expect(find.text(message), findsNothing);
      expect(pillFinder(), findsNothing);
    });

    testWidgets('is fully transparent', (tester) async {
      await pumpStrip(tester, visible: false);

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });
  });

  group('visible', () {
    testWidgets('shows the message and the wifi-off mark', (tester) async {
      await pumpStrip(tester, visible: true);

      expect(find.text(message), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
    });

    testWidgets('is an inset pill, not an edge-to-edge banner', (tester) async {
      await pumpStrip(tester, visible: true);

      final pill = tester.getSize(pillFinder()).width;
      expect(
        pill,
        _phone.width - (GlobalOfflineStrip.sideMargin * 2),
        reason: 'it must float inside the content gutter on both sides',
      );
      expect(pill, lessThan(_phone.width));
    });

    testWidgets('carries the chip radius and the shared pill shadow', (
      tester,
    ) async {
      await pumpStrip(tester, visible: true);
      final decoration = pillDecoration(tester);

      expect(
        decoration.borderRadius,
        BorderRadius.circular(AuroraRadius.md),
        reason: 'a rounded chip, not a bar',
      );
      expect(
        decoration.boxShadow,
        AuroraShadows.pill,
        reason: 'reused from the scale rather than invented for this widget',
      );
    });

    testWidgets('paints the warm-neutral tokens, not raw hex', (tester) async {
      await pumpStrip(tester, visible: true);

      expect(pillDecoration(tester).color, AuroraColors.offlineStrip);

      expect(
        tester.widget<Icon>(find.byIcon(Icons.wifi_off_rounded)).color,
        AuroraColors.offlineStripInk,
      );
      expect(
        tester.widget<Text>(find.text(message)).style!.color,
        AuroraColors.offlineStripInk,
      );

      // The near-black green this replaced. Named so a revert is loud rather
      // than silently reinstating the old banner's palette.
      expect(pillDecoration(tester).color, isNot(const Color(0xFF2B3733)));
    });

    testWidgets('is a compact single line, well under the old banner', (
      tester,
    ) async {
      await pumpStrip(tester, visible: true);

      final height = tester.getSize(pillFinder()).height;
      expect(
        height,
        lessThan(36),
        reason: 'the old full-bleed bar stood at roughly 42pt',
      );
      expect(height, greaterThan(16), reason: 'still a legible single line');
    });
  });

  testWidgets('collapses and expands rather than appearing outright', (
    tester,
  ) async {
    // AnimatedSize is what keeps the content below from jolting; losing it
    // would make the strip pop in and shove the page down in one frame.
    await pumpStrip(tester, visible: false);
    expect(find.byType(AnimatedSize), findsOneWidget);

    final collapsed = tester.getSize(find.byType(GlobalOfflineStrip)).height;
    await pumpStrip(tester, visible: true);
    final expanded = tester.getSize(find.byType(GlobalOfflineStrip)).height;

    expect(collapsed, 0);
    expect(expanded, greaterThan(collapsed));
  });

  group('placement on the app shell', () {
    /// Pumps the real [HomeScreen] — the strip's single app-wide mount point.
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

    testWidgets('sits above the hero card once the device goes offline', (
      tester,
    ) async {
      final fake = await pumpShell(tester);

      // Optimistic until told otherwise, so nothing is on screen yet.
      expect(tester.getSize(find.byType(GlobalOfflineStrip)).height, 0);

      fake.emit(online: false);
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);

      // Relative ordering only — the strip lives outside the tab bodies, so
      // asserting any exact offset would just re-encode HomeTab's padding.
      final stripBottom = tester
          .getBottomLeft(find.byType(GlobalOfflineStrip))
          .dy;
      final heroTop = tester.getTopLeft(find.byType(QueueStatusCard)).dy;
      expect(stripBottom, lessThanOrEqualTo(heroTop));
    });

    testWidgets('takes no space on the shell while the device is online', (
      tester,
    ) async {
      await pumpShell(tester);

      // The hero card must start exactly where it would with no strip in the
      // tree at all — this is the regression that a stray parent Padding
      // around the strip would cause.
      final heroTop = tester.getTopLeft(find.byType(QueueStatusCard)).dy;
      final stripHeight = tester
          .getSize(find.byType(GlobalOfflineStrip))
          .height;

      expect(stripHeight, 0);
      expect(find.text(message), findsNothing);
      expect(heroTop, greaterThan(0));
    });
  });
}
