/// Home's browse-by-specialty chip row.
library;

import 'package:flutter/material.dart';
// For HapticFeedback, which material.dart does not re-export.
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/aurora_tokens.dart';
import 'home_specialty_doctors.dart';

/// One entry in the specialty row.
///
/// [key] is the stable ASCII identifier the doctor list filters on; [label] is
/// what the patient reads. They are kept apart on purpose so the Arabic copy
/// can be reworded without silently changing the filter contract.
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
    //
    // The key is borrowed from the carousel rather than spelled out again:
    // the two widgets have to agree on the "no filter" sentinel exactly, and
    // one shared constant is what guarantees they cannot drift apart. The
    // dependency runs one way only — the carousel knows nothing about this
    // row.
    _Specialty(
      HomeSpecialtyDoctors.allSpecialtiesKey,
      'الكل',
      FontAwesomeIcons.tableCellsLarge,
    ),
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

  /// One key per chip, so a newly selected chip can be scrolled into view.
  /// Built once and reused — a fresh [GlobalKey] every build would detach and
  /// re-attach the whole row on each rebuild.
  late final Map<String, GlobalKey> _chipKeys = {
    for (final specialty in _specialties) specialty.key: GlobalKey(),
  };

  void _select(String key) {
    if (key == _selectedKey) return;

    // A selection *tick*, not an impact: this is the same class of gesture as
    // moving a picker or switching a segment, and `selectionClick` is the
    // lightest of the haptics — the one Android reserves for exactly this.
    // Anything heavier would be shouting about a filter change.
    HapticFeedback.selectionClick();

    setState(() => _selectedKey = key);
    widget.onSpecialtySelected?.call(key);
    _revealChip(key);
  }

  /// Brings the newly selected chip fully into view.
  ///
  /// Without this, tapping a chip that is half off the edge leaves it half off
  /// the edge — now highlighted, so the row reads as having a selected item
  /// the patient cannot fully see. Centring rather than nudging is the tab-strip
  /// convention, and it clamps at both ends on its own, so selecting the
  /// leading "الكل" simply returns the row to its start.
  void _revealChip(String key) {
    final chipContext = _chipKeys[key]?.currentContext;
    if (chipContext == null) return;

    Scrollable.ensureVisible(
      chipContext,
      alignment: 0.5,
      duration: AuroraMotion.timed(context, AuroraMotion.standard),
      curve: AuroraMotion.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The app's own theme, not the device's. This used to read
    // `MediaQuery.platformBrightnessOf` because there was no darkTheme for
    // `Theme.of` to reflect — which meant that with the system in dark mode
    // this widget painted dark-mode colours into a screen that was still
    // light: a near-white heading on cream, and near-black chips beside a
    // correctly teal "الكل". Both are gone now that the palette and the
    // surface it sits on come from the same place.
    final palette = context.aurora;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The heading keeps the page gutter; the row below deliberately does
        // not — see the note on the ListView's own padding.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
          child: Text(
            'تصفّح حسب التخصص',
            // RTL-aware rather than a hardcoded `right`, matching every other
            // heading in the app.
            textAlign: TextAlign.start,
            style: AuroraText.display(
              size: AuroraFontSize.h3,
              color: palette.ink,
            ),
          ),
        ),
        const SizedBox(height: AuroraSpacing.md),
        // A horizontal list needs a bounded cross-axis extent, and this widget
        // sits inside Home's vertically unbounded SingleChildScrollView, so
        // the height has to be stated rather than measured.
        //
        // The row runs full-bleed and carries the page gutter as its *own*
        // padding, which is what lets a chip scrolling out of view travel to
        // the real screen edge instead of being cut at a fixed inset. At rest
        // the leading chip still lines up with the heading above it, so the
        // resting layout is unchanged — only what happens mid-scroll differs.
        SizedBox(
          height: _rowHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
            scrollDirection: Axis.horizontal,
            // The pills are the only thing here; the row should not add a
            // second scroll bounce on top of the page's.
            physics: const ClampingScrollPhysics(),
            itemCount: _specialties.length,
            separatorBuilder: (_, _) => const SizedBox(width: AuroraSpacing.sm),
            itemBuilder: (context, index) {
              final specialty = _specialties[index];
              return _SpecialtyChip(
                key: _chipKeys[specialty.key],
                label: specialty.label,
                icon: specialty.icon,
                selected: specialty.key == _selectedKey,
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
///
/// **The two states are crossfaded, not swapped.** Selection used to flip the
/// fill, the shadow and the content colour between two frames, which read as
/// the row redrawing itself rather than as one chip handing off to another —
/// and gave the eye nothing to follow from the chip you left to the chip you
/// chose. The gradient now fades up over the tonal base while the label and
/// icon travel to white, and it fades back down on the chip being deselected,
/// so the two halves of the change are visibly one movement.
class _SpecialtyChip extends StatefulWidget {
  const _SpecialtyChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final FaIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SpecialtyChip> createState() => _SpecialtyChipState();
}

class _SpecialtyChipState extends State<_SpecialtyChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;
    final radius = BorderRadius.circular(AuroraRadius.pill);
    final selected = widget.selected ? 1.0 : 0.0;

    return Align(
      // The ListView hands each item the full 52pt height; without this the
      // pill would stretch to fill it instead of keeping its own 40pt.
      alignment: Alignment.topCenter,
      child: AnimatedScale(
        // A touch deeper than the 0.97 house press: a chip is small, and the
        // gradient swallows most of the ripple on the selected one, so the
        // scale is doing most of the acknowledging here.
        scale: _pressed ? 0.95 : 1,
        duration: AuroraMotion.timed(context, AuroraMotion.press),
        curve: AuroraMotion.easeOut,
        child: TweenAnimationBuilder<double>(
          // `begin` is read only on the first build; after that
          // TweenAnimationBuilder animates from wherever it currently is to
          // the new `end`, which is what makes a mid-flight reselection pick
          // up from the partial state instead of jumping.
          tween: Tween(begin: selected, end: selected),
          duration: AuroraMotion.timed(context, AuroraMotion.select),
          curve: AuroraMotion.easeOut,
          builder: (context, t, child) {
            // White on the gradient in both themes — the selected pill's fill
            // is the brand ramp, which does not darken, so its content must
            // not either.
            final content = Color.lerp(palette.secondary, Colors.white, t)!;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: palette.tonal,
                borderRadius: radius,
                // Empty in dark, where a drop shadow reads as grime rather
                // than lift — the palette carries that decision, not this
                // widget, and lerping to an empty list simply keeps it absent.
                boxShadow: BoxShadow.lerpList(const [], palette.pillShadow, t),
              ),
              child: Stack(
                children: [
                  // The gradient rides *over* the tonal fill rather than
                  // replacing it, so the crossfade is one layer's opacity
                  // rather than two decorations being interpolated — which
                  // cannot be done cleanly between a gradient and a flat
                  // colour.
                  Positioned.fill(
                    child: Opacity(
                      opacity: t,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AuroraGradients.aurora,
                          borderRadius: radius,
                        ),
                      ),
                    ),
                  ),
                  // Transparent Material so the ripple clips to the pill and
                  // paints over the gradient rather than under it.
                  Material(
                    color: Colors.transparent,
                    borderRadius: radius,
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: radius,
                      onHighlightChanged: _setPressed,
                      child: Semantics(
                        selected: widget.selected,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AuroraSpacing.lg,
                            vertical: AuroraSpacing.md - 2,
                          ),
                          // Under RTL the first child lands on the visual
                          // right, which is the leading position for an Arabic
                          // reader — so the icon comes first in code to sit
                          // ahead of its label.
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(widget.icon, size: 15, color: content),
                              const SizedBox(width: AuroraSpacing.sm),
                              Text(
                                widget.label,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
