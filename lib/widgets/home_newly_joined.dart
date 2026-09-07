/// Home's "انضموا حديثاً" section — the doctors most recently on the platform.
library;

import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/aurora_tokens.dart';
import 'doctor_card.dart';

/// A titled header over a horizontally scrolling rail of [DoctorCard]s.
///
/// **Newness lives in this section, never in the card.** There is no "جديد"
/// badge on the banner and no "joined X ago" line under the name: the title
/// alone says what this row is, and [DoctorCard] renders exactly as it does in
/// the specialty carousel. That is the point — the same card appears in
/// several places on Home, and a doctor must not look like a different kind of
/// thing depending on which row they happen to be in. Anything that would make
/// a card mean "new" belongs here, in the container.
///
/// **Presentation only.** [doctors] arrives from the caller; nothing in here
/// reaches for a mock list or a query. `onBook` is left unwired by Home for the
/// same reason the carousel's is — there is no booking flow to open.
class HomeNewlyJoined extends StatelessWidget {
  const HomeNewlyJoined({
    super.key,
    required this.doctors,
    this.onBook,
    this.onSeeAll,
  });

  /// The doctors to show, **newest first** — already ordered and capped by the
  /// caller. Empty renders nothing at all; see [build].
  ///
  /// Required rather than defaulted to the mock set, matching
  /// `HomePreviouslyVisited`: the day a real query exists, it is swapped in at
  /// the `home_tab.dart` call site and this file does not change.
  final List<Doctor> doctors;

  /// Fires with the tapped doctor's card button. Null renders every button
  /// visibly present but unresponsive, which is the honest state today.
  final ValueChanged<Doctor>? onBook;

  /// Fires when "عرض الكل" is tapped.
  ///
  /// **Inert on Home today, on purpose.** There is no Browse destination to
  /// send anyone to, so `home_tab.dart` passes nothing and the link renders
  /// fully styled but dead — the same placeholder footing as the notification
  /// bell's unread dot. It is here as the seam that routing plugs into, rather
  /// than pointed at a stub.
  final VoidCallback? onSeeAll;

  /// The rail is taller than a card so [AuroraPalette.cardShadow] — which
  /// throws 8pt down with a 24pt blur — is not clipped off. Same reasoning as
  /// the specialty carousel's viewport.
  static const double _railHeight =
      DoctorCard.preferredHeight + AuroraSpacing.lg;

  @override
  Widget build(BuildContext context) {
    // A platform with no recent joins has nothing to say here, and a header
    // with a "لا يوجد أطباء" pill over an empty rail would be worse than the
    // section simply not being on the page. Unreachable with today's fixed
    // seed data; it is here so the real query cannot render a hollow section
    // the day it lands.
    if (doctors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The header takes the page gutter itself; the rail below does not, so
        // a card scrolling out of view runs to the real screen edge. The same
        // full-bleed arrangement the specialty carousel and the chip row use.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
          child: _Header(onSeeAll: onSeeAll),
        ),
        const SizedBox(height: AuroraSpacing.md),
        // Bounded cross-axis extent, because a horizontal list inside Home's
        // vertically unbounded SingleChildScrollView cannot measure its own.
        SizedBox(
          height: _railHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
            scrollDirection: Axis.horizontal,
            // The page already bounces; the rail should not bounce on top.
            physics: const ClampingScrollPhysics(),
            itemCount: doctors.length,
            separatorBuilder: (_, _) => const SizedBox(width: AuroraSpacing.md),
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              final book = onBook;

              return Align(
                // The list hands each item the full viewport height; without
                // this the card would stretch into the shadow's room.
                alignment: Alignment.topCenter,
                child: SizedBox(
                  // Fixed, not a flex: the card keeps the exact size it is
                  // designed at however long the row turns out to be.
                  width: DoctorCard.preferredWidth,
                  height: DoctorCard.preferredHeight,
                  child: DoctorCard(
                    doctor: doctor,
                    onBook: book == null ? null : () => book(doctor),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The section title on one side, the "see all" link on the other.
///
/// **No count pill.** The visited section carries one, but this row is a
/// browsable rail rather than a closed set — "how many recent joins are we
/// showing right now" is not a fact worth a chip, and on a 393pt phone it cost
/// the title the room to say itself.
class _Header extends StatelessWidget {
  const _Header({required this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;

    // Under RTL the Row's first child lands on the visual right, so the title
    // reads from the right edge and the link sits opposite it on the left —
    // the mirrored arrangement of the LTR design.
    return Row(
      children: [
        // [Expanded], not [Flexible] beside a [Spacer]. That pairing is what
        // truncated this title to "انضموا ح…" on the Tecno: both are flex
        // children with the default flex of 1, so the row split its free space
        // evenly between the text and the gap, handing the title about half of
        // what it needed. One flex child, taking everything the link does not,
        // gives the title its full width and still pushes the link to the far
        // edge.
        Expanded(
          child: Text(
            // "انضموا" (joined) rather than "المضافون" (were added): a doctor
            // joins a platform, they are not added to it like a row to a table.
            'انضموا حديثاً',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.display(
              size: AuroraFontSize.h3,
              color: palette.ink,
            ),
          ),
        ),
        const SizedBox(width: AuroraSpacing.sm),
        _SeeAllLink(onTap: onSeeAll),
      ],
    );
  }
}

/// The quiet trailing "عرض الكل" link.
class _SeeAllLink extends StatelessWidget {
  const _SeeAllLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;
    final radius = BorderRadius.circular(AuroraRadius.sm);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          // Vertical padding rather than a bare label: it gives the link a tap
          // target taller than its text without moving it off the title's line.
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.xs,
            vertical: AuroraSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'عرض الكل',
                style: AuroraText.body(
                  size: AuroraFontSize.caption,
                  weight: FontWeight.w700,
                  color: palette.accentOnTonal,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                // Points the way an Arabic reader moves — forward is *left*
                // under RTL. Explicitly the non-directional glyph, following
                // `ShowMoreDoctorsCard`, so it cannot flip back to the right.
                Icons.arrow_back_rounded,
                size: 14,
                color: palette.accentOnTonal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
