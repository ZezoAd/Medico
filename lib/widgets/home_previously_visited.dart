/// Home's "زرتهم سابقاً" section — the doctors this patient has seen before.
library;

import 'package:flutter/material.dart';

import '../dev/mock_doctors.dart';
import '../models/doctor.dart';
import '../theme/aurora_tokens.dart';
import '../utils/arabic_formatting.dart';
import 'doctor_list_row.dart';

/// A titled card holding a short column of [DoctorListRow]s and a footer CTA
/// into the full history.
///
/// **Presentation only, and standing on invented data.** There is no bookings
/// table and no queue history in Supabase, so nothing could say who a patient
/// has actually seen — today's caller hands it [mockPreviouslyVisited], a
/// hand-picked slice of the same [mockDoctors] list the specialty carousel
/// draws from. That shared source is the point: the two sections show the same
/// people under the same names.
///
/// The list arrives as a parameter rather than being read off the mock in
/// here, so swapping in a real bookings query is a change at the call site and
/// not surgery on this widget — and so [visited] can be empty, which is the
/// one case the seed data can never produce.
///
/// Deliberately a *sample*, not a listing. It shows what it is given and points
/// at the Bookings tab for the rest, the same way the carousel caps itself and
/// offers "عرض المزيد".
class HomePreviouslyVisited extends StatelessWidget {
  const HomePreviouslyVisited({
    super.key,
    required this.visited,
    this.onOpenHistory,
    this.onBook,
  });

  /// The doctors to list, newest visit first — the caller's slice, already
  /// ordered and capped. Empty renders nothing at all; see [build].
  final List<VisitedDoctor> visited;

  /// Fires when the footer CTA is tapped. Wired by `home_tab.dart` to Home's
  /// tab-switch callback, which lands on Bookings — this is a *tab switch*,
  /// not a push, so the person stays inside the shell's bottom nav and the
  /// back gesture still means "leave the app", not "return to Home".
  ///
  /// Null renders the CTA styled but inert.
  final VoidCallback? onOpenHistory;

  /// Fires with the tapped doctor's row button. Null renders every button
  /// visibly present but unresponsive, which is the honest state today — there
  /// is no booking flow for it to open, exactly as on the carousel's cards.
  final ValueChanged<Doctor>? onBook;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;

    // A patient with no history has nothing to say here, and an empty card
    // with a "٠" pill and a dead CTA would be worse than the section simply
    // not being on the page. Deliberately no placeholder and no "you haven't
    // visited anyone yet" copy either — the section takes zero height and Home
    // closes over the gap. Unreachable with today's fixed seed data; it is
    // here so the real query cannot render a hollow card the day it lands.
    if (visited.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.lg,
        vertical: AuroraSpacing.xl,
      ),
      decoration: BoxDecoration(
        // Opaque, unlike the rows inside it: this is the layer that carries
        // the elevation, and a BoxShadow under a translucent fill shows
        // through the fill as a dirty edge.
        color: palette.surface,
        borderRadius: BorderRadius.circular(AuroraRadius.lg),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Under RTL the Row's first child lands on the visual right, so the
          // heading block reads from the right edge and the count pill sits
          // opposite it on the left — the mirrored arrangement of the LTR
          // design, and what the Arabic reference shows.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'زرتهم سابقاً',
                      style: AuroraText.display(
                        size: AuroraFontSize.h3,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: AuroraSpacing.xs),
                    Text(
                      'أطباؤك الذين زرتهم مؤخراً',
                      style: AuroraText.body(
                        size: AuroraFontSize.caption,
                        color: palette.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AuroraSpacing.md),
              // Nudged down so the pill centres on the title line rather than
              // on the whole two-line heading block, which is where the
              // reference puts it.
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _CountPill(count: visited.length),
              ),
            ],
          ),
          const SizedBox(height: AuroraSpacing.lg),
          // A plain Column, not a ListView: three rows inside an already
          // scrolling page. A nested scroller here would either need a fixed
          // height or fight the page's gesture, and neither is worth it for a
          // list that is capped this short by design.
          //
          // Indexed rather than `for (final entry in visited)` with an
          // `entry != visited.last` separator check: [VisitedDoctor] is a
          // record, so that comparison is structural, and two entries that
          // happened to match would silently drop a gap.
          for (var i = 0; i < visited.length; i++) ...[
            DoctorListRow(
              doctor: visited[i].doctor,
              actionLabel: 'احجز',
              // Composed here, not inside the row: DoctorListRow is shared
              // with the Newly Added section, which will pass a different
              // sentence built from a different date. The row renders whatever
              // string it is handed and knows nothing about visits.
              //
              // The date goes through `formatArabicDate` rather than being
              // assembled inline — that helper is the single place a date
              // becomes digits, and so the seam the numerals toggle will plug
              // into when it lands.
              metaLine: 'آخر زيارة · ${formatArabicDate(visited[i].lastVisit)}',
              onAction: onBook == null
                  ? null
                  : () => onBook!(visited[i].doctor),
            ),
            if (i < visited.length - 1)
              const SizedBox(height: AuroraSpacing.sm),
          ],
          const SizedBox(height: AuroraSpacing.md),
          _FullHistoryCta(onTap: onOpenHistory),
        ],
      ),
    );
  }
}

/// The "٣ أطباء" chip beside the heading.
///
/// Counts what the section is *showing*, and says so in words — not "الإجمالي".
/// Nothing here knows how many visits the patient really has, and a total would
/// be a claim this section cannot back up until there is a bookings table.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.md,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        // Same tinted accent as the rows below, for the same dark-mode reason:
        // [AuroraPalette.tonal] collapses onto `surface` in dark and would
        // leave the pill invisible on the card.
        color: palette.accentOnTonal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
      ),
      child: Text(
        // Arabic counted-noun grammar — "طبيب واحد", "طبيبان", "٣ أطباء",
        // "١٢ طبيباً". Through the shared helper rather than interpolated, so
        // the section cannot print "٢ أطباء" the day the count changes.
        doctorsPhrase(count),
        style: AuroraText.body(
          size: AuroraFontSize.micro,
          weight: FontWeight.w700,
          color: palette.accentOnTonal,
        ),
      ),
    );
  }
}

/// The full-width gradient pill at the foot of the section.
class _FullHistoryCta extends StatelessWidget {
  const _FullHistoryCta({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AuroraRadius.pill);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AuroraGradients.aurora,
        borderRadius: radius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.md),
            // Under RTL the Row's first child lands on the visual right, so
            // the label reads from the right and the arrow trails it on the
            // left — the pair centred as a unit.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'عرض السجل الكامل',
                  style: AuroraText.body(
                    size: AuroraFontSize.bodyLg,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AuroraSpacing.sm),
                Icon(
                  // Points the way an Arabic reader moves — forward is *left*
                  // under RTL. Explicitly the non-directional glyph, following
                  // `ShowMoreDoctorsCard`, so it cannot flip back to the right.
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
