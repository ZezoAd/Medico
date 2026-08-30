// Standalone preview for HomeEmptyStateCard — not wired into the real app.
// Run with:
//   flutter run -t lib/dev/home_empty_state_card_preview.dart
//
// A separate harness rather than a tab inside queue_status_card_preview.dart:
// that one is built around connectivity scenarios that mean nothing here, and
// each preview owns its own `main()` so it can be launched with -t on its own.
//
// The mode switcher lives here, in the harness. The card has none of its own —
// it reads [AuroraPalette] off the ambient theme, so switching `themeMode` is
// what drives it. This used to override `MediaQuery.platformBrightness`
// instead, back when the card read the device setting directly because the app
// had no dark theme for it to follow; there is one now, and the override no
// longer reaches the card at all.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/aurora_tokens.dart';
import '../widgets/home_empty_state_card.dart';

void main() => runApp(const _PreviewApp());

enum _Mode {
  system('حسب النظام', ThemeMode.system),
  light('فاتح', ThemeMode.light),
  dark('داكن', ThemeMode.dark);

  const _Mode(this.label, this.themeMode);
  final String label;
  final ThemeMode themeMode;
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode.themeMode,
      home: Builder(
        builder: (context) {
          final palette = context.aurora;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
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
                      // Inert, as it is in the app: no search flow exists to
                      // open, so the harness does not invent one either.
                      const HomeEmptyStateCard(),
                      const SizedBox(height: AuroraSpacing.xxl),
                      // Both themes at once, so the pair can be compared
                      // without toggling back and forth.
                      Text(
                        'المظهران معاً',
                        style: AuroraText.body(
                          size: AuroraFontSize.bodyLg,
                          weight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: AuroraSpacing.md),
                      const _Forced(
                        theme: AppThemeVariant.light,
                        child: HomeEmptyStateCard(),
                      ),
                      const SizedBox(height: AuroraSpacing.lg),
                      const _Forced(
                        theme: AppThemeVariant.dark,
                        child: HomeEmptyStateCard(),
                      ),
                    ],
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

enum AppThemeVariant { light, dark }

/// Renders [child] under one theme regardless of the harness's own setting,
/// on the background that theme would put behind it.
class _Forced extends StatelessWidget {
  const _Forced({required this.theme, required this.child});

  final AppThemeVariant theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = theme == AppThemeVariant.dark ? AppTheme.dark : AppTheme.light;

    return Theme(
      data: data,
      child: Builder(
        builder: (context) => ColoredBox(
          color: context.aurora.background,
          child: Padding(
            padding: const EdgeInsets.all(AuroraSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
