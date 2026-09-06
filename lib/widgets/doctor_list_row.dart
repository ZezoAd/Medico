/// A doctor as one row in a vertical list.
library;

import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/aurora_tokens.dart';

/// Circular avatar, a stacked name/specialty/meta column, and a pill action
/// button — the row shape Home's vertical doctor lists are built from.
///
/// **Deliberately says nothing about *why* the doctor is in the list.** The
/// third line and the button label both arrive as parameters, so the same row
/// carries "زرتهم سابقاً" (last visit, "احجز") and the Newly Added section
/// (joined-on date, its own CTA) without either section's copy being baked in
/// here. Anything that would make this row mean one thing — a "last visit"
/// prefix, a hardcoded "احجز" — belongs in the caller.
///
/// Emphatically **not** a variant of `DoctorCard` in
/// `home_specialty_doctors.dart`. That is a fixed 200×236 card in a horizontal
/// carousel, with a rounded-square avatar and a rating pill; this is a
/// full-width list row with a circular avatar and no rating. They are two
/// different components that happen to draw the same model.
///
/// Presentation only: it takes its one action as a callback and never touches
/// Supabase. A null [onAction] renders the button fully styled but unresponsive
/// — the honest state while there is no booking flow to open — matching how
/// `DoctorCard` and `HomeEmptyStateCard` treat their own CTAs.
class DoctorListRow extends StatelessWidget {
  const DoctorListRow({
    super.key,
    required this.doctor,
    required this.actionLabel,
    this.metaLine,
    this.onAction,
  });

  final Doctor doctor;

  /// The pill button's label, e.g. "احجز".
  final String actionLabel;

  /// The quiet third line under the specialty, already formatted by the
  /// caller — e.g. "آخر زيارة · ٢٠ أيار ٢٠٢٥". Null drops the line entirely
  /// rather than reserving blank space for it: unlike `DoctorCard`'s rating,
  /// these rows are read one under another in a column, so a missing line
  /// shortens its own row without knocking anything out of alignment.
  final String? metaLine;

  final VoidCallback? onAction;

  /// Big enough to read a face at arm's length, and the tallest thing in the
  /// row — so it, not the text column, sets the row's height. Roughly 3.5× the
  /// name's type size, which is the avatar-to-name proportion in the design.
  static const double _avatarSize = 52;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;
    final meta = metaLine;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.md,
        vertical: AuroraSpacing.md,
      ),
      decoration: BoxDecoration(
        // The same tinted accent `DoctorCard._DoctorAvatar` settled on, and for
        // the same reason: [AuroraPalette.tonal] is the obvious choice and is
        // invisible here, because the dark palette maps `tonal` and `surface`
        // to the same #1C2624 — so a tonal row inside a surface card would
        // disappear completely in dark mode. Tinting the accent holds in both
        // themes: over white it lands within a point or two of
        // [AuroraColors.tonal], which is the light design, and over the dark
        // card it lifts clear of the surface.
        //
        // No shadow on the row, deliberately. This fill is translucent, and a
        // BoxShadow under a translucent fill shows through as a dirty edge —
        // the section card is the layer that carries elevation.
        color: palette.accentOnTonal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AuroraRadius.md),
      ),
      // Under RTL the first child lands on the visual right, so the avatar
      // leads on the right, the text column reads leftward from it, and the
      // action pill sits at the far left — the mirrored arrangement of the
      // LTR design, and what the Arabic reference shows.
      child: Row(
        children: [
          _RowAvatar(
            size: _avatarSize,
            photoUrl: doctor.photoUrl,
            name: doctor.name,
          ),
          const SizedBox(width: AuroraSpacing.md),
          // Takes the slack between the avatar and the button, so a long name
          // ellipsises instead of shoving the pill off the row.
          Expanded(
            child: Column(
              // Start, not left: under RTL this pins the stack to the avatar
              // beside it rather than to a fixed physical edge.
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doctor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuroraText.display(
                    size: AuroraFontSize.bodyLg,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: AuroraSpacing.xs / 2),
                Text(
                  doctor.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuroraText.body(
                    size: AuroraFontSize.caption,
                    weight: FontWeight.w500,
                    color: palette.secondary,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: AuroraSpacing.xs / 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraText.body(
                      size: AuroraFontSize.micro,
                      color: palette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AuroraSpacing.sm),
          _ActionPill(label: actionLabel, onTap: onAction),
        ],
      ),
    );
  }
}

/// The doctor's photo, or their initials, on a circular disc.
///
/// A circle, unlike `DoctorCard`'s rounded square. The two lists are read in
/// different postures — a carousel of cards you scan sideways versus a column
/// of people you read down — and the round mark is what makes this one read as
/// a roster of individuals rather than a second row of cards.
class _RowAvatar extends StatelessWidget {
  const _RowAvatar({
    required this.size,
    required this.photoUrl,
    required this.name,
  });

  final double size;
  final String? photoUrl;
  final String name;

  /// Two Arabic initials, e.g. "د. حسين الطائي" → "ح.ط".
  ///
  /// First and last name word, skipping the "د." honorific and the "ال"
  /// definite article — "الطائي" initialises to ط, not ا, which is what makes
  /// the pair read as two distinct letters rather than as a row of alifs.
  ///
  /// A near-copy of `_DoctorAvatar._initialsFor` in
  /// `home_specialty_doctors.dart`. That helper is private to the locked
  /// carousel card and this task is scoped not to touch that file, so the two
  /// are duplicated for now — the same arrangement `_DriftingBlob` is in
  /// between the two hero cards. Worth lifting into one shared helper the next
  /// time either avatar is edited.
  static String _initialsFor(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w != 'د.' && w != 'د')
        .map((w) => w.startsWith('ال') && w.length > 2 ? w.substring(2) : w)
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return '؟';
    if (words.length == 1) return words.first.substring(0, 1);
    return '${words.first.substring(0, 1)}.${words.last.substring(0, 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;
    final url = photoUrl;

    final fallback = Center(
      child: Text(
        _initialsFor(name),
        style: AuroraText.display(
          size: AuroraFontSize.body,
          color: palette.accentOnTonal,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // [AuroraPalette.surface], not another accent tint: the row's own fill
        // is already the tinted accent, so a disc in the same family would
        // vanish into it. Surface reads as a lighter disc on the row in light
        // mode and as a darker one in dark, and is distinct from the row fill
        // in both.
        color: palette.surface,
        shape: BoxShape.circle,
      ),
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: size,
              height: size,
              // A URL that fails to load degrades to exactly the same initials
              // as a null one — a broken-image glyph on a doctor's face is
              // worse than no photo at all. This also keeps a widget test from
              // failing on the sandbox's blocked network.
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

/// The row's gradient pill CTA.
class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AuroraRadius.pill);

    return DecoratedBox(
      decoration: BoxDecoration(
        // The in-app two-stop brand ramp, same as the carousel card's button
        // and the selected specialty chip. Not AuroraGradients.authButton —
        // that four-stop ramp belongs to the auth surface.
        gradient: AuroraGradients.aurora,
        borderRadius: radius,
      ),
      // Transparent Material so the ripple clips to the pill and paints over
      // the gradient rather than under it.
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AuroraSpacing.lg,
              vertical: AuroraSpacing.sm + 2,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              // White in both themes: the fill is the brand ramp, which does
              // not darken, so its label must not either.
              style: AuroraText.body(
                size: AuroraFontSize.caption,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
