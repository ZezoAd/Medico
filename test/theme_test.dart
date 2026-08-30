/// The light/dark/system theme: persistence, the palette, the Profile picker,
/// and the two rendering bugs that motivated all of it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/models/onboarding_data.dart';
import 'package:medico/screens/profile_tab.dart';
import 'package:medico/services/theme_service.dart';
import 'package:medico/theme/app_theme.dart';
import 'package:medico/theme/aurora_tokens.dart';
import 'package:medico/widgets/home_specialty_chips.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hosts [child] under the real app themes, with the *device* reporting
/// [platformBrightness].
///
/// Those two being separable is the whole point: before this work the widgets
/// read the device setting directly, so a dark phone dragged dark-mode colours
/// into a light-themed screen. Every assertion below that passes a dark
/// platform with a light theme is checking that they no longer talk to each
/// other.
Widget _host(
  Widget child, {
  ThemeMode mode = ThemeMode.light,
  Brightness platformBrightness = Brightness.light,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: mode,
    builder: (context, inner) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(platformBrightness: platformBrightness),
      child: inner!,
    ),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: child),
    ),
  );
}

Color _textColour(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data)).style!.color!;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeController.instance = ThemeController(ThemeMode.system);
  });

  group('ThemeService persistence', () {
    test('defaults to system when nothing is stored', () async {
      expect(await const ThemeService().load(), ThemeMode.system);
    });

    test('round-trips each mode', () async {
      const service = ThemeService();
      for (final mode in ThemeMode.values) {
        await service.save(mode);
        expect(await service.load(), mode);
      }
    });

    test('falls back to system on an unrecognised stored value', () async {
      // The reason the mode is stored by name and not by index: a value that
      // no longer maps to anything must not resolve to whichever enum entry
      // happens to sit at that position.
      SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
      expect(await const ThemeService().load(), ThemeMode.system);
    });

    test('init seeds the controller from the store', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      await ThemeController.init();
      expect(ThemeController.instance.value, ThemeMode.dark);
    });
  });

  group('ThemeController', () {
    test('setMode notifies listeners and persists', () async {
      final controller = ThemeController(ThemeMode.system);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setMode(ThemeMode.dark);

      expect(controller.value, ThemeMode.dark);
      expect(notified, 1);
      // The write is deliberately not awaited by `setMode` — the UI has
      // already changed by the time it starts — so the assertion has to let
      // it land rather than racing it.
      await pumpEventQueue();
      expect(await controller.service.load(), ThemeMode.dark);
    });

    test('setting the current mode again is a no-op', () {
      final controller = ThemeController(ThemeMode.light);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.setMode(ThemeMode.light);

      expect(notified, 0);
    });
  });

  group('AuroraPalette', () {
    testWidgets('resolves from the active theme, not the device', (
      tester,
    ) async {
      late AuroraPalette light;
      late AuroraPalette dark;

      await tester.pumpWidget(
        _host(
          Builder(builder: (context) {
            light = context.aurora;
            return const SizedBox.shrink();
          }),
          platformBrightness: Brightness.dark,
        ),
      );
      await tester.pumpWidget(
        _host(
          Builder(builder: (context) {
            dark = context.aurora;
            return const SizedBox.shrink();
          }),
          mode: ThemeMode.dark,
          platformBrightness: Brightness.light,
        ),
      );
      // `MaterialApp` swaps themes through `AnimatedTheme`, and [AuroraPalette]
      // lerps with it — so one frame in, the palette is still most of the way
      // light. Settle before reading, or this asserts against a tween.
      await tester.pumpAndSettle();

      // Light theme on a dark device stays light; dark theme on a light
      // device goes dark. The device no longer has a vote.
      expect(light.ink, AuroraColors.ink);
      expect(light.background, AuroraColors.background);
      expect(dark.ink, AuroraColors.inkDark);
      expect(dark.background, AuroraColors.bgDark);
    });

    testWidgets('falls back to light when the extension is missing', (
      tester,
    ) async {
      late AuroraPalette palette;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            palette = context.aurora;
            return const SizedBox.shrink();
          }),
        ),
      );
      expect(palette.ink, AuroraColors.ink);
    });
  });

  group('the specialty chips follow the theme, not the device', () {
    // Both bugs from the real-device screenshot: system dark on, app light.
    // The heading rendered near-white on cream, and every unselected chip
    // rendered near-black beside a correctly teal "الكل".
    testWidgets('a dark device does not lighten the heading on a light theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const HomeSpecialtyChips(), platformBrightness: Brightness.dark),
      );

      expect(_textColour(tester, 'تصفّح حسب التخصص'), AuroraColors.ink);
    });

    testWidgets('a dark device does not darken the unselected chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const HomeSpecialtyChips(), platformBrightness: Brightness.dark),
      );

      // "الكل" is selected and gradient-filled; "أسنان" is not, and is the
      // one that came out near-black.
      final chip = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('أسنان'),
              matching: find.byType(DecoratedBox),
            )
            .last,
      );
      final decoration = chip.decoration as BoxDecoration;

      expect(decoration.color, AuroraColors.tonal);
      expect(_textColour(tester, 'أسنان'), AuroraColors.secondary);
    });

    testWidgets('and does go dark when the theme actually is', (tester) async {
      await tester.pumpWidget(
        _host(
          const HomeSpecialtyChips(),
          mode: ThemeMode.dark,
          platformBrightness: Brightness.light,
        ),
      );

      expect(_textColour(tester, 'تصفّح حسب التخصص'), AuroraColors.inkDark);
      expect(_textColour(tester, 'أسنان'), AuroraColors.secondaryDark);
    });
  });

  group('the المظهر row', () {
    Widget profile() => _host(
      ProfileTab(
        isSignedIn: true,
        gender: Gender.male,
        fullName: 'سارة',
        phone: '07700000000',
        email: null,
        onSignOut: () async {},
      ),
    );

    testWidgets('shows the current mode and opens the picker', (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(profile());

      expect(find.text('المظهر'), findsOneWidget);
      // The trailing value, which is what the inert rows have no use for.
      expect(find.text('النظام'), findsOneWidget);

      await tester.tap(find.text('المظهر'));
      await tester.pumpAndSettle();

      // All three, now in the sheet.
      expect(find.text('فاتح'), findsOneWidget);
      expect(find.text('داكن'), findsOneWidget);
    });

    testWidgets('choosing a mode applies it, closes, and persists', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(profile());
      await tester.tap(find.text('المظهر'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('داكن'));
      await tester.pumpAndSettle();

      expect(ThemeController.instance.value, ThemeMode.dark);
      expect(find.text('فاتح'), findsNothing, reason: 'the sheet should close');
      // The row re-reads the controller, so the value it reports follows.
      expect(find.text('داكن'), findsOneWidget);
      expect(await ThemeController.instance.service.load(), ThemeMode.dark);
    });
  });
}
