/// Home's horizontal doctor carousel, titled by the selected specialty.
library;

import 'package:flutter/material.dart';

import '../dev/mock_doctors.dart';
import '../models/doctor.dart';
import '../theme/aurora_tokens.dart';

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
  /// Card height, from the agreed design. Tested only in an HTML mockup so
  /// far — the text column below the avatar is snapped to [AuroraFontSize],
  /// which runs ~2pt taller than the mockup's off-scale sizes, and the slack
  /// is absorbed by the clinic row's [Expanded]. Worth re-checking on the
  /// Tecno before treating this number as settled.
  static const double _cardHeight = 236;

  static const double _cardWidth = 200;

  /// The viewport is taller than a card so [AuroraPalette.cardShadow] — which
  /// throws 8pt down with a 24pt blur — is not clipped off. Same reasoning as
  /// `home_specialty_chips.dart`'s 52pt row around a 40pt pill.
  static const double _listHeight = _cardHeight + AuroraSpacing.lg;

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

  @override
  void initState() {
    super.initState();
    _cachedEpoch = widget.refreshEpoch;
    _ensureDrawn();
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

    return Column(
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
              padding: const EdgeInsets.symmetric(
                horizontal: AuroraSpacing.lg,
              ),
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
                    width: _cardWidth,
                    height: _cardHeight,
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

/// One doctor card. Sized by its parent — it fills whatever box it is given.
///
/// Public so the dev previews under `lib/dev/` can host it on its own, the
/// same arrangement `queue_status_card.dart` uses.
class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.onBook});

  final Doctor doctor;
  final VoidCallback? onBook;

  /// The rating row's height is reserved whether or not a rating exists.
  ///
  /// Hiding the pill must not shift the avatar up on that one card — in a row
  /// of cards seen side by side, a doctor without a score would otherwise
  /// visibly sit higher than its neighbours. The pill is omitted; its space is
  /// not. (The card's *total* height is fixed regardless, by the clinic row's
  /// [Expanded].)
  static const double _ratingRowHeight = 20;

  static const double _avatarSize = 60;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;
    final rating = doctor.rating;

    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AuroraRadius.md),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _ratingRowHeight,
            // [Alignment], not [AlignmentDirectional]: the pill belongs in the
            // card's true physical left corner and must stay there under RTL
            // rather than mirroring to the right. This is the design as
            // agreed, not an oversight about directionality.
            child: rating == null
                ? null
                : Align(
                    alignment: Alignment.topLeft,
                    child: _RatingPill(rating: rating),
                  ),
          ),
          const SizedBox(height: AuroraSpacing.sm),
          Center(
            child: _DoctorAvatar(
              size: _avatarSize,
              photoUrl: doctor.photoUrl,
              name: doctor.name,
            ),
          ),
          const SizedBox(height: AuroraSpacing.sm),
          Text(
            doctor.name,
            textAlign: TextAlign.center,
            // Flutter's own truncation. The mockup clipped the string by hand
            // at 20 characters, which was a workaround for a bug in the
            // web tool it was built in — Flutter's text layout ellipsises RTL
            // correctly on its own under the app's Directionality, so there is
            // nothing here to work around.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.display(
              size: AuroraFontSize.body,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: AuroraSpacing.xs / 2),
          Text(
            doctor.specialty,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.body(
              size: AuroraFontSize.caption,
              weight: FontWeight.w500,
              color: palette.accentOnTonal,
            ),
          ),
          // Takes whatever vertical space the rest of the column leaves and
          // centres the clinic in it. This is what makes every card the same
          // height regardless of how long its clinic name runs — the row grows
          // and shrinks inside a fixed box instead of pushing the card taller.
          Expanded(
            child: Center(child: _ClinicRow(clinicName: doctor.clinicName)),
          ),
          Container(height: 1, color: palette.divider),
          const SizedBox(height: AuroraSpacing.sm + 2),
          _BookButton(onTap: onBook),
        ],
      ),
    );
  }
}

/// The star-and-figure rating chip.
class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: palette.ratingAmberBg,
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
      ),
      // Under RTL the first child lands on the visual right, which is the
      // leading position for an Arabic reader — so the star sits ahead of its
      // figure, the same ordering every other icon+label pair in the app uses.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: palette.ratingAmber),
          const SizedBox(width: 2),
          Text(
            // Western digits, per the app default — `toStringAsFixed` emits
            // them and `toArabicDigits` is deliberately not called here.
            rating.toStringAsFixed(1),
            style: AuroraText.body(
              size: AuroraFontSize.micro,
              weight: FontWeight.w700,
              color: palette.ratingAmber,
            ),
          ),
        ],
      ),
    );
  }
}

/// The doctor's photo, or their initials on a tonal square.
///
/// A rounded square, not a circle: the design uses the same shape language as
/// the queue card's doctor avatar rather than the circular patient avatar in
/// Profile, which is a different thing being identified.
class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({
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
          size: AuroraFontSize.h3,
          color: palette.accentOnTonal,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // Deliberately *not* [AuroraPalette.tonal], which is the obvious
        // choice and is invisible here: the dark palette maps `tonal` and
        // `surface` to the same #1C2624, so a tonal square on a surface card
        // disappears completely in dark mode — verified on the Tecno, where
        // the initials floated with no container behind them.
        //
        // Tinting the accent instead holds in both themes: over white it
        // lands within a point or two of [AuroraColors.tonal], which is the
        // light design; over the dark card it lifts clear of the surface.
        color: palette.accentOnTonal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AuroraRadius.sm),
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

/// Pin plus clinic name, centred, wrapping to at most two lines.
class _ClinicRow extends StatelessWidget {
  const _ClinicRow({required this.clinicName});

  final String clinicName;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;

    return Row(
      // Top-aligned so the pin sits beside the *first* line when the name
      // wraps to two, rather than floating between them.
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.location_on_outlined,
            size: 12,
            color: palette.muted,
          ),
        ),
        const SizedBox(width: 2),
        // Flexible, so the text may wrap inside whatever the pin leaves rather
        // than forcing the row wider than the card.
        Flexible(
          child: Text(
            clinicName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.body(
              size: AuroraFontSize.micro,
              color: palette.muted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// The gradient pill CTA.
class _BookButton extends StatelessWidget {
  const _BookButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AuroraRadius.pill);

    return DecoratedBox(
      decoration: BoxDecoration(
        // The in-app two-stop brand ramp — the same token the selected
        // specialty chip on this screen already paints with. Emphatically not
        // AuroraGradients.authButton: that four-stop ramp belongs to the auth
        // surface, and the two systems are kept apart on purpose.
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
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              'احجز الآن',
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
