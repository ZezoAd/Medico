// Standalone preview for HomeEmptyStateCard — not wired into the real app.
// Run with:
//   flutter run -t lib/dev/home_empty_state_card_preview.dart
//
// A separate harness rather than a tab inside queue_status_card_preview.dart:
// that one is built around connectivity scenarios that mean nothing here, and
// each preview owns its own `main()` so it can be launched with -t on its own.
//
// The brightness switcher lives here, in the harness. The card reads the
// platform brightness and has no switcher of its own.
import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../widgets/home_empty_state_card.dart';

void main() => runApp(const _PreviewApp());

enum _Mode {
  system('حسب النظام'),
  light('فاتح'),
  dark('داكن');

  const _Mode(this.label);
  final String label;
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  _Mode _mode = _Mode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        // Inner context so the MediaQuery override below is the one the card
        // sees. Overriding `platformBrightness` — not `ThemeData.brightness`
        // or `themeMode` — is what actually drives the card: it reads
        // `MediaQuery.platformBrightnessOf`, which a theme toggle cannot
        // reach. That is the same reason the app can't theme these cards
        // today, so the harness has to reproduce it faithfully.
        builder: (context) {
          final platform = MediaQuery.platformBrightnessOf(context);
          final brightness = switch (_mode) {
            _Mode.system => platform,
            _Mode.light => Brightness.light,
            _Mode.dark => Brightness.dark,
          };
          final isDark = brightness == Brightness.dark;

          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(platformBrightness: brightness),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: isDark
                    ? AuroraColors.bgDark
                    : const Color(0xFFFAF7F2),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AuroraSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AuroraSpacing.sm,
                          runSpacing: AuroraSpacing.sm,
                          children: [
                            for (final mode in _Mode.values)
                              ChoiceChip(
                                label: Text(mode.label),
                                selected: _mode == mode,
                                onSelected: (_) => setState(() => _mode = mode),
                              ),
                          ],
                        ),
                        const SizedBox(height: AuroraSpacing.xl),
                        // Inert, as it is in the app: no search flow exists
                        // to open, so the harness does not invent one either.
                        const HomeEmptyStateCard(),
                        const SizedBox(height: AuroraSpacing.xxl),
                        // Both brightnesses at once, so the pair can be
                        // compared without toggling back and forth.
                        Text(
                          'المظهران معاً',
                          style: AuroraText.body(
                            size: AuroraFontSize.bodyLg,
                            weight: FontWeight.w700,
                            color: isDark
                                ? AuroraColors.inkDark
                                : AuroraColors.ink,
                          ),
                        ),
                        const SizedBox(height: AuroraSpacing.md),
                        const _Forced(
                          brightness: Brightness.light,
                          child: HomeEmptyStateCard(),
                        ),
                        const SizedBox(height: AuroraSpacing.lg),
                        const _Forced(
                          brightness: Brightness.dark,
                          child: HomeEmptyStateCard(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Renders [child] as though the platform were in [brightness], on the
/// background that brightness would put behind it.
class _Forced extends StatelessWidget {
  const _Forced({required this.brightness, required this.child});

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(platformBrightness: brightness),
      child: ColoredBox(
        color: brightness == Brightness.dark
            ? AuroraColors.bgDark
            : const Color(0xFFFAF7F2),
        child: Padding(
          padding: const EdgeInsets.all(AuroraSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
