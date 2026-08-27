/// Home's browse-by-specialty chip row.
library;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/aurora_tokens.dart';

/// One entry in the specialty row.
///
/// [key] is the stable ASCII identifier the future doctor-list filter will
/// match on; [label] is what the patient reads. They are kept apart on purpose
/// so the Arabic copy can be reworded without silently changing the filter
/// contract.
@immutable
class _Specialty {
  const _Specialty(this.key, this.label, this.icon);

  final String key;
  final String label;

  /// `FaIconData`, not `IconData`: as of font_awesome_flutter 11 the constants
  /// are a wrapper type that does *not* extend [IconData], so this field and
  /// everything it is threaded through have to name the wrapper.
  final FaIconData icon;
}

/// A horizontally scrollable, single-select row of specialty pills.
///
/// **Presentation only.** Selecting a chip moves the local highlight and
/// reports the new key through [onSpecialtySelected]; nothing filters yet
/// because no doctor list or Browse tab exists to filter. The callback is the
/// seam that flow will plug into.
///
/// Icons come from `font_awesome_flutter` rather than Material's [Icons] —
/// see the file-level notes on `handDots` and `tableCellsLarge`, the two that
/// are approximations rather than exact matches.
class HomeSpecialtyChips extends StatefulWidget {
  const HomeSpecialtyChips({super.key, this.onSpecialtySelected});

  /// Fires with the newly selected specialty's key. Re-tapping the already
  /// selected chip does not fire — the selection did not change.
  final ValueChanged<String>? onSpecialtySelected;

  @override
  State<HomeSpecialtyChips> createState() => _HomeSpecialtyChipsState();
}

class _HomeSpecialtyChipsState extends State<HomeSpecialtyChips> {
  /// Declaration order **is** display order. Under RTL a horizontal
  /// [ListView] lays its first child against the visual right edge and scrolls
  /// leftward, so "الكل" leading this list is what puts it rightmost. Do not
  /// reverse it to compensate.
  static const _specialties = [
    // Solid grid — the conventional "all categories" mark. An approximation:
    // there is no literal "everything" medical glyph.
    _Specialty('all', 'الكل', FontAwesomeIcons.tableCellsLarge),
    _Specialty('general', 'طب عام', FontAwesomeIcons.stethoscope),
    _Specialty('dental', 'أسنان', FontAwesomeIcons.tooth),
    _Specialty('obgyn', 'نساء وتوليد', FontAwesomeIcons.personPregnant),
    _Specialty('pediatrics', 'أطفال', FontAwesomeIcons.baby),
    // Font Awesome's "allergies" glyph — a hand with skin spots. The closest
    // free-tier dermatology mark; an approximation, not a purpose-built one.
    _Specialty('dermatology', 'جلدية', FontAwesomeIcons.handDots),
    _Specialty('orthopedics', 'عظام', FontAwesomeIcons.bone),
    _Specialty('cardiology', 'قلبية', FontAwesomeIcons.heartPulse),
    // `solidEye`, not `eye`: the unprefixed name resolves to the Regular
    // weight, which would read visibly thinner than the other eight.
    _Specialty('ophthalmology', 'عيون', FontAwesomeIcons.solidEye),
  ];

  /// Tall enough for a 40pt pill plus the room [AuroraShadows.pill] throws
  /// downward, so the selected chip's lift is not clipped by the viewport.
  static const double _rowHeight = 52;

  String _selectedKey = _specialties.first.key;

  void _select(String key) {
    if (key == _selectedKey) return;
    setState(() => _selectedKey = key);
    widget.onSpecialtySelected?.call(key);
  }

  @override
  Widget build(BuildContext context) {
    // main.dart declares only a light ThemeData — no darkTheme, no themeMode —
    // so Theme.of(context).brightness reports `light` even on a dark device.
    // Read the platform setting directly, the same workaround (and for the
    // same reason) as queue_status_card.dart and home_empty_state_card.dart.
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تصفّح حسب التخصص',
          // RTL-aware rather than a hardcoded `right`, matching every other
          // heading in the app.
          textAlign: TextAlign.start,
          style: AuroraText.display(
            size: AuroraFontSize.h3,
            color: isDark ? AuroraColors.inkDark : AuroraColors.ink,
          ),
        ),
        const SizedBox(height: AuroraSpacing.md),
        // A horizontal list needs a bounded cross-axis extent, and this widget
        // sits inside Home's vertically unbounded SingleChildScrollView, so
        // the height has to be stated rather than measured.
        //
        // The row scrolls within Home's existing 16pt side padding rather than
        // bleeding to the screen edge: escaping that padding would mean
        // restructuring home_tab's scroll view, which this change is scoped
        // not to touch.
        SizedBox(
          height: _rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // The pills are the only thing here; the row should not add a
            // second scroll bounce on top of the page's.
            physics: const ClampingScrollPhysics(),
            itemCount: _specialties.length,
            separatorBuilder: (_, _) => const SizedBox(width: AuroraSpacing.sm),
            itemBuilder: (context, index) {
              final specialty = _specialties[index];
              return _SpecialtyChip(
                label: specialty.label,
                icon: specialty.icon,
                selected: specialty.key == _selectedKey,
                isDark: isDark,
                onTap: () => _select(specialty.key),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One pill. Gradient-filled with white content when selected, tonal with
/// [AuroraColors.secondary] content otherwise.
class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final FaIconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color content;
    if (selected) {
      content = Colors.white;
    } else {
      content = isDark ? AuroraColors.secondaryDark : AuroraColors.secondary;
    }

    final radius = BorderRadius.circular(AuroraRadius.pill);

    return Align(
      // The ListView hands each item the full 52pt height; without this the
      // pill would stretch to fill it instead of keeping its own 40pt.
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: selected ? AuroraGradients.aurora : null,
          color: selected
              ? null
              : (isDark ? AuroraColors.tonalDark : AuroraColors.tonal),
          borderRadius: radius,
          boxShadow: selected && !isDark ? AuroraShadows.pill : null,
        ),
        // Transparent Material so the ripple clips to the pill and paints over
        // the gradient rather than under it.
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Semantics(
              selected: selected,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuroraSpacing.lg,
                  vertical: AuroraSpacing.md - 2,
                ),
                // Under RTL the first child lands on the visual right, which
                // is the leading position for an Arabic reader — so the icon
                // comes first in code to sit ahead of its label.
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(icon, size: 15, color: content),
                    const SizedBox(width: AuroraSpacing.sm),
                    Text(
                      label,
                      style: AuroraText.body(
                        size: AuroraFontSize.body,
                        weight: FontWeight.w700,
                        color: content,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
