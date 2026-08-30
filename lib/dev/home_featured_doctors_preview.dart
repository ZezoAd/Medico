// Standalone preview for HomeFeaturedDoctors — not wired into the real app.
// Run with:
//   flutter run -t lib/dev/home_featured_doctors_preview.dart
//
// Its own main(), like the other two previews, so it can be launched with -t
// without dragging their scenarios along.
//
// This harness exists mainly to check the card's *geometry* on a real handset.
// The 200x236 came from an HTML mockup and the type is snapped to
// AuroraFontSize rather than the mockup's off-scale sizes, so the text column
// runs a little taller than it did there. The three cards at the bottom are
// the stress cases: a long name that must ellipsise on one line, a long clinic
// that must wrap to two and stop, and a doctor with no rating whose card must
// still line up with its neighbours.
import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/app_theme.dart';
import '../theme/aurora_tokens.dart';
import '../widgets/home_featured_doctors.dart';

void main() => runApp(const _PreviewApp());

enum _Mode {
  system('حسب النظام', ThemeMode.system),
  light('فاتح', ThemeMode.light),
  dark('داكن', ThemeMode.dark);

  const _Mode(this.label, this.themeMode);
  final String label;
  final ThemeMode themeMode;
}

/// The three cases worth eyeballing rather than asserting.
const _edgeCases = [
  Doctor(
    id: 'p1',
    name: 'د. عبدالرحمن ياسين الموسوي الكناني',
    specialty: 'طب عام',
    clinicName: 'مجمع الشفاء للرعاية الصحية التخصصية',
    rating: 4.7,
  ),
  Doctor(
    id: 'p2',
    name: 'د. نور',
    specialty: 'نسائية وتوليد',
    clinicName: 'الأمل',
    rating: 5.0,
  ),
  // No rating: the pill is omitted and its row's height is kept, so this card
  // must sit flush with the two beside it rather than riding higher.
  Doctor(
    id: 'p3',
    name: 'د. حسين الطائي',
    specialty: 'طب عيون',
    clinicName: 'عيادة النظر الواضح',
  ),
];

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
                  // 16pt sides, matching what home_tab actually gives the
                  // section — the peek depends on this being right.
                  padding: const EdgeInsets.all(AuroraSpacing.lg),
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
                      // Inert here as in the app: there is no booking flow, so
                      // the harness does not invent one either.
                      const HomeFeaturedDoctors(),
                      const SizedBox(height: AuroraSpacing.xxl),
                      Text(
                        'حالات حدّية',
                        style: AuroraText.body(
                          size: AuroraFontSize.bodyLg,
                          weight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: AuroraSpacing.md),
                      const _EdgeCaseRow(),
                      const SizedBox(height: AuroraSpacing.xxl),
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
                        child: _EdgeCaseRow(),
                      ),
                      const SizedBox(height: AuroraSpacing.lg),
                      const _Forced(
                        theme: AppThemeVariant.dark,
                        child: _EdgeCaseRow(),
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

/// The three stress cards side by side, at the exact size the carousel uses.
class _EdgeCaseRow extends StatelessWidget {
  const _EdgeCaseRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 236 + AuroraSpacing.lg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _edgeCases.length,
        separatorBuilder: (_, _) => const SizedBox(width: AuroraSpacing.md),
        itemBuilder: (context, index) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 200,
            height: 236,
            child: DoctorCard(doctor: _edgeCases[index]),
          ),
        ),
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
