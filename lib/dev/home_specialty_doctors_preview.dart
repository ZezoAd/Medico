// Standalone preview for HomeSpecialtyDoctors — not wired into the real app.
// Run with:
//   flutter run -t lib/dev/home_specialty_doctors_preview.dart
//
// Its own main(), like the other two previews, so it can be launched with -t
// without dragging their scenarios along.
//
// This harness exists mainly to check the card's *geometry* on a real handset,
// and it matters more since the 2026-09-07 banner redesign than it did before.
// DoctorCard.preferredWidth/Height are a scaled-down reading of
// lib/design_reference/doctor_card_banner_shape.html — the reference draws the
// card at 320×440, which was far too big in the hand — and the type is snapped
// to AuroraFontSize rather than to either set of off-scale sizes. What is worth
// eyeballing here is whether 210×300 still gives the banner and the avatar
// enough room to read as the reference's shape. The three cards at the bottom
// are the stress cases: a long name that must ellipsise on one line, a long
// clinic that must wrap to two and stop, and a short-everything card that must
// still line up with its neighbours.
import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/app_theme.dart';
import '../theme/aurora_tokens.dart';
import '../widgets/doctor_card.dart';
import '../widgets/home_specialty_doctors.dart';

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
    specialtyKey: 'general',
    clinicName: 'مجمع الشفاء للرعاية الصحية التخصصية',
    rating: 4.7,
  ),
  Doctor(
    id: 'p2',
    name: 'د. نور',
    specialty: 'نساء وتوليد',
    specialtyKey: 'obgyn',
    clinicName: 'الأمل',
    rating: 5.0,
  ),
  // Short name, short clinic — the opposite stress from the first card. It
  // must sit flush with the two beside it rather than riding higher or
  // shorter, which is what the clinic row's Expanded buys.
  //
  // The `rating` on the two above is now ignored: the redesigned card carries
  // no rating pill. They are left set so this harness still proves that.
  Doctor(
    id: 'p3',
    name: 'د. حسين الطائي',
    specialty: 'طب عيون',
    specialtyKey: 'ophthalmology',
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

  /// Stands in for Home's refresh counter. The app raises it on a
  /// pull-to-refresh or a reconnect; here it is a button, so the cache-clearing
  /// half of the carousel can be eyeballed without a network to unplug.
  int _refreshEpoch = 0;

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
                      const SizedBox(height: AuroraSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _refreshEpoch++),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text('تحديث (الجيل $_refreshEpoch)'),
                      ),
                      const SizedBox(height: AuroraSpacing.xl),
                      // Inert here as in the app: there is no booking flow, so
                      // the harness does not invent one either.
                      HomeSpecialtyDoctors(refreshEpoch: _refreshEpoch),
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
      height: DoctorCard.preferredHeight + AuroraSpacing.lg,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _edgeCases.length,
        separatorBuilder: (_, _) => const SizedBox(width: AuroraSpacing.md),
        itemBuilder: (context, index) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: DoctorCard.preferredWidth,
            height: DoctorCard.preferredHeight,
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
