/// Home's horizontal doctor carousel, titled by the selected specialty.
library;

import 'package:flutter/material.dart';

import '../dev/mock_doctors.dart';
import '../models/doctor.dart';
import '../theme/aurora_tokens.dart';
import 'doctor_card.dart';

/// A heading and a horizontally scrolling row of fixed-size doctor cards,
/// filtered to one specialty and capped at a handful.
///
/// The cap is what makes this a *sample* rather than a listing: the row shows a
/// random draw from the matching pool, and when the pool is bigger than the cap
/// it ends with a "عرض المزيد" card pointing at the full list. That keeps Home
/// a starting point instead of a directory.
///
/// **Presentation only.** The doctors come from [mockDoctors], not from a
/// query: `public.doctors` is empty and nothing fetches it yet. Every card's
/// "احجز الآن" button is inert for the same reason the empty-state card's CTA
/// is — there is no booking flow and no detail screen to open. [onBook] is the
/// seam that flow plugs into, left unwired rather than pointed at a stub.
class HomeSpecialtyDoctors extends StatefulWidget {
  const HomeSpecialtyDoctors({
    super.key,
    required this.refreshEpoch,
    this.selectedSpecialtyKey = allSpecialtiesKey,
    this.onBook,
  });

  /// The chip row's "no filter" sentinel. Not a specialty a doctor can carry —
  /// see the note on [Doctor.specialtyKey]. `home_specialty_chips.dart` reads
  /// this rather than spelling `'all'` out a second time.
  static const String allSpecialtiesKey = 'all';

  /// How many doctors the row shows for one specialty.
  static const int perSpecialtyCap = 5;

  /// How many it shows for [allSpecialtiesKey]. Higher than
  /// [perSpecialtyCap] because the unfiltered pool is the whole directory —
  /// a five-card sample of everyone would read as a shortlist rather than a
  /// glimpse.
  static const int allSpecialtiesCap = 10;

  /// Which specialty to show, as one of the chip keys in
  /// `home_specialty_chips.dart`. [allSpecialtiesKey] draws from every doctor;
  /// anything else draws only from doctors whose [Doctor.specialtyKey]
  /// matches, and a key nobody practises renders the empty state rather than a
  /// blank strip.
  final String selectedSpecialtyKey;

  /// Home's refresh counter. The *only* thing that may deal a new hand.
  ///
  /// Every specialty drawn during one epoch is remembered, so moving away from
  /// a chip and back shows the same people rather than a fresh shuffle — the
  /// row is a sample, but it should not feel like a slot machine. A bump
  /// throws the whole remembered set away; see `home_tab.dart`, which raises
  /// it on a pull-to-refresh and on the device coming back online.
  ///
  /// Note this deliberately does *not* track [selectedSpecialtyKey]: changing
  /// the selection picks which remembered draw to show, and never causes one.
  final int refreshEpoch;

  /// Fires with the tapped doctor. Null renders the button visibly present but
  /// unresponsive, which is the honest state today.
  final ValueChanged<Doctor>? onBook;

  @override
  State<HomeSpecialtyDoctors> createState() => _HomeSpecialtyDoctorsState();
}

class _HomeSpecialtyDoctorsState extends State<HomeSpecialtyDoctors> {
  /// The viewport is taller than a card so [AuroraPalette.cardShadow] — which
  /// throws 8pt down with a 24pt blur — is not clipped off. Same reasoning as
  /// `home_specialty_chips.dart`'s 52pt row around a 40pt pill.
  ///
  /// The card's own geometry lives on [DoctorCard], not here: the row hosts a
  /// shared component at the size that component is designed at, rather than
  /// holding an opinion about how big a doctor card should be.
  static const double _listHeight =
      DoctorCard.preferredHeight + AuroraSpacing.lg;

  /// One drawn sample per specialty key, for the life of one refresh epoch.
  ///
  /// Held in state rather than computed in `build` on purpose: a shuffle in
  /// `build` would deal a new hand on *every* rebuild — a parent `setState`, a
  /// theme change, a media query — so the row would visibly reshuffle itself
  /// under the patient's finger mid-scroll. Keyed by specialty rather than
  /// holding only the current draw so that returning to a chip returns to the
  /// *same doctors*, not merely to the same number of them.
  final Map<String, List<Doctor>> _cache = {};

  /// The epoch [_cache]'s contents belong to. Compared against
  /// [HomeSpecialtyDoctors.refreshEpoch] rather than against `oldWidget`, so a
  /// State that somehow rejoins the tree mid-flight still notices it is
  /// holding a stale generation.
  late int _cachedEpoch;

  /// Whether the content on screen right now is the empty state.
  late bool _wasEmpty;

  /// Whether the swap being built crosses between "has doctors" and "has
  /// none" — the only swap that changes this section's height.
  bool _crossesEmptiness = false;

  @override
  void initState() {
    super.initState();
    _cachedEpoch = widget.refreshEpoch;
    _ensureDrawn();
    _wasEmpty = _cache[widget.selectedSpecialtyKey]!.isEmpty;
  }

  @override
  void didUpdateWidget(HomeSpecialtyDoctors oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A new epoch invalidates every remembered draw, not just the visible one:
    // a refresh means "all of this is old", and leaving the hidden entries
    // behind would hand back last epoch's doctors the next time their chip was
    // tapped.
    if (widget.refreshEpoch != _cachedEpoch) {
      _cache.clear();
      _cachedEpoch = widget.refreshEpoch;
    }

    // Cheap and idempotent — draws only for a key with no entry this epoch, so
    // an unrelated rebuild passes straight through it.
    _ensureDrawn();

    // Recorded here rather than in `build`, which stays free of side effects.
    final nowEmpty = _cache[widget.selectedSpecialtyKey]!.isEmpty;
    _crossesEmptiness = nowEmpty != _wasEmpty;
    _wasEmpty = nowEmpty;
  }

  /// Draws for the current selection if this epoch has not drawn it yet.
  ///
  /// Called from [initState] and [didUpdateWidget] rather than from `build`,
  /// which stays free of side effects. Every build is preceded by one of the
  /// two, so the entry `build` reads is always present.
  void _ensureDrawn() {
    _cache.putIfAbsent(widget.selectedSpecialtyKey, _drawCurrent);
  }

  /// Filters, shuffles, and takes the cap.
  List<Doctor> _drawCurrent() {
    final pool = _poolFor(widget.selectedSpecialtyKey);
    // Shuffles the copy, never `mockDoctors` itself — that list is shared, and
    // reordering it in place would scramble every other reader of it.
    pool.shuffle();
    return pool
        .take(_capFor(widget.selectedSpecialtyKey))
        .toList(growable: false);
  }

  /// Every doctor matching [key], uncapped. A fresh growable copy each call,
  /// since callers shuffle it.
  static List<Doctor> _poolFor(String key) =>
      key == HomeSpecialtyDoctors.allSpecialtiesKey
      ? [...mockDoctors]
      : [
          for (final doctor in mockDoctors)
            if (doctor.specialtyKey == key) doctor,
        ];

  static int _capFor(String key) =>
      key == HomeSpecialtyDoctors.allSpecialtiesKey
      ? HomeSpecialtyDoctors.allSpecialtiesCap
      : HomeSpecialtyDoctors.perSpecialtyCap;

  @override
  Widget build(BuildContext context) {
    final shown = _cache[widget.selectedSpecialtyKey]!;

    // Whether the pool outran the cap is a fact about the *pool*, not about
    // the hand that was dealt from it, so it is recomputed here rather than
    // cached beside the draw — the same key gives the same answer in every
    // epoch. An empty specialty falls out as false, which is why the empty
    // state below never carries an overflow card.
    final hasMore =
        _poolFor(widget.selectedSpecialtyKey).length >
        _capFor(widget.selectedSpecialtyKey);

    // The "عرض المزيد" card rides in the same list as one extra trailing item,
    // rather than in a Row beside it, so it scrolls with the cards and cannot
    // fall out of reach.
    final itemCount = shown.length + (hasMore ? 1 : 0);

    // Crossfaded on the specialty key, so changing filters reads as this row
    // answering rather than as the page redrawing. The old set fades out and
    // the new one rises a few points into place — a short travel, because the
    // content is *replaced* rather than moved, and a longer slide would imply
    // the doctors went somewhere.
    //
    // Keyed on the epoch too: a pull-to-refresh deals a genuinely new hand,
    // and that deserves the same acknowledgement as a filter change. Without
    // the epoch in the key a refresh would silently swap the cards underneath.
    // Crossfaded between one set of doctors and another, and **snapped**
    // whenever the swap crosses the empty state.
    //
    // The distinction is the whole design, and it falls out of one fact: every
    // populated state is exactly [_listHeight] tall, so a doctors-to-doctors
    // swap changes nothing about this section's size and the crossfade is pure
    // content. Crossing to or from the empty message is the only swap that
    // changes the height — and animating *that* is what makes the section feel
    // broken, whichever way it is done. Holding the old height keeps a one-line
    // message floating in a card-sized hole; animating the height instead drags
    // every section below it up the page for the duration, and clips the
    // outgoing cards on the way. Neither is worth having: an absence should
    // just be there.
    //
    // So the rule is "never animate a height change", and the crossfade
    // survives exactly where it earns its place.
    final motion = _crossesEmptiness
        ? Duration.zero
        : AuroraMotion.timed(context, AuroraMotion.standard);

    return AnimatedSwitcher(
      duration: motion,
      switchInCurve: AuroraMotion.easeOut,
      switchOutCurve: AuroraMotion.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _content(
        key: ValueKey('${widget.refreshEpoch}:${widget.selectedSpecialtyKey}'),
        shown: shown,
        hasMore: hasMore,
        itemCount: itemCount,
      ),
    );
  }

  Widget _content({
    required Key key,
    required List<Doctor> shown,
    required bool hasMore,
    required int itemCount,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No heading. The chip row directly above already names the selection —
        // a title restating it was saying the same thing twice. What separates
        // this section from the chips is `home_tab`'s AuroraSpacing.xxl, the
        // same gap it puts between every other pair of sections on Home.
        //
        // The carousel is replaced outright when nothing matches, rather than
        // left in place as an empty scroll strip — an empty row reads as a
        // widget that failed to load, not as an answer.
        if (shown.isEmpty)
          // Not a scroller, so it takes the page gutter directly.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
            child: _NoDoctorsForSpecialty(),
          )
        else
          // Bounded cross-axis extent, because a horizontal list inside Home's
          // vertically unbounded SingleChildScrollView cannot measure its own.
          //
          // Full-bleed, carrying the page gutter as its own padding — the
          // precedent the chip row set. A card scrolling out of view now runs
          // to the real screen edge instead of being cut at a fixed inset,
          // which is what stops every row sharing one vertical boundary down
          // the page. Resting layout is unchanged.
          SizedBox(
            height: _listHeight,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
              // Rebuilds the row from its start when the filter changes, so
              // switching specialties never lands mid-scroll in the new set.
              // The epoch is in the key for the same reason: a refresh deals a
              // new hand into the same key, and holding the old scroll offset
              // would drop the patient into the middle of a row they have not
              // seen.
              key: ValueKey(
                '${widget.refreshEpoch}:'
                '${widget.selectedSpecialtyKey}',
              ),
              scrollDirection: Axis.horizontal,
              // The page already bounces; the row should not bounce on top.
              physics: const ClampingScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AuroraSpacing.md),
              itemBuilder: (context, index) {
                return Align(
                  // The list hands each item the full viewport height; without
                  // this the card would stretch into the shadow's room.
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    // A fixed width, not a flex: the card keeps its exact size
                    // however long or short the list turns out to be.
                    width: DoctorCard.preferredWidth,
                    height: DoctorCard.preferredHeight,
                    child: index < shown.length
                        ? _doctorCard(shown[index])
                        : ShowMoreDoctorsCard(
                            specialtyKey: widget.selectedSpecialtyKey,
                          ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _doctorCard(Doctor doctor) {
    final onBook = widget.onBook;
    return DoctorCard(
      doctor: doctor,
      onBook: onBook == null ? null : () => onBook(doctor),
    );
  }
}

/// The trailing "see the rest" card, shown only when the pool outran the cap.
///
/// **A placeholder pending a design pass.** Deliberately plain — a tonal panel
/// with an icon and a label — so it reads as clearly *not* a doctor rather than
/// as a doctor card that failed to load. Nothing about it is settled.
class ShowMoreDoctorsCard extends StatelessWidget {
  const ShowMoreDoctorsCard({super.key, required this.specialtyKey});

  /// The selection to carry into Browse once that tab exists.
  final String specialtyKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;
    final radius = BorderRadius.circular(AuroraRadius.md);

    return Material(
      color: palette.tonal,
      borderRadius: radius,
      child: InkWell(
        // Inert, like every other CTA on this screen: there is no Browse tab to
        // open. The print is the seam, so the wiring is obvious when it lands.
        onTap: () =>
            debugPrint('TODO: route to Browse tab filtered by $specialtyKey'),
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AuroraSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                // Points the way an Arabic reader moves — the list continues
                // off the *left* edge under RTL. Explicitly non-directional so
                // it does not flip back to the right.
                Icons.arrow_back_rounded,
                size: 28,
                color: palette.accentOnTonal,
              ),
              const SizedBox(height: AuroraSpacing.sm),
              Text(
                'عرض المزيد',
                textAlign: TextAlign.center,
                style: AuroraText.body(
                  size: AuroraFontSize.body,
                  weight: FontWeight.w700,
                  color: palette.accentOnTonal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown in the carousel's place when the selected specialty has no doctors.
///
/// Bare centred text, no card or container: this is an inline "nothing here"
/// inside a section that already has its heading, not a surface of its own —
/// boxing it would give an absence more visual weight than the doctors it
/// stands in for. [AuroraPalette.muted] at body size is the same quiet
/// treatment the card's clinic line uses.
class _NoDoctorsForSpecialty extends StatelessWidget {
  const _NoDoctorsForSpecialty();

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;

    return Padding(
      // Nowhere near the carousel's 252pt: the section is meant to visibly
      // collapse when it is empty. Enough room that the line does not crowd
      // the heading above or whatever lands below it.
      padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.xl),
      child: Text(
        'لا يوجد أطباء في هذا التخصص حالياً',
        textAlign: TextAlign.center,
        style: AuroraText.body(
          size: AuroraFontSize.body,
          color: palette.muted,
          height: 1.6,
        ),
      ),
    );
  }
}
