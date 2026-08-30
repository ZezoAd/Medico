/// Home's "أطباء مميزون" horizontal doctor carousel.
library;

import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/aurora_tokens.dart';

/// Placeholder content. **Hardcoded, not a decision** — there is no `doctors`
/// table and no query behind this, so the list is baked in rather than fetched
/// from a stub service that would imply one exists. See `doctor.dart`.
///
/// The last entry's name is deliberately far too long for the card: it is the
/// standing check that the name ellipsises on one line instead of wrapping or
/// overflowing.
const _mockDoctors = [
  Doctor(
    id: 'mock-1',
    name: 'د. زينب قاسم',
    specialty: 'أسنان',
    clinicName: 'لؤلؤة للأسنان',
    photoUrl: 'https://i.pravatar.cc/200?img=47',
    rating: 4.9,
  ),
  Doctor(
    id: 'mock-2',
    name: 'د. مصطفى العزاوي',
    specialty: 'طب عام',
    clinicName: 'مجمع الرافدين',
    rating: 4.8,
  ),
  Doctor(
    id: 'mock-3',
    name: 'د. حسين الطائي',
    specialty: 'طب عيون',
    clinicName: 'عيادة النظر الواضح',
    photoUrl: 'https://i.pravatar.cc/200?img=32',
    rating: 4.7,
  ),
  Doctor(
    id: 'mock-4',
    name: 'د. نور السامرائي',
    specialty: 'نسائية وتوليد',
    clinicName: 'مستشفى الأمل',
    rating: 4.9,
  ),
  Doctor(
    id: 'mock-5',
    name: 'د. علي الدليمي',
    specialty: 'عظام',
    clinicName: 'مركز العظام التخصصي',
    photoUrl: 'https://i.pravatar.cc/200?img=68',
    rating: 4.6,
  ),
  Doctor(
    id: 'mock-6',
    name: 'د. عبدالرحمن ياسين الموسوي الكناني',
    specialty: 'طب عام',
    clinicName: 'مجمع الشفاء للرعاية الصحية التخصصية',
    rating: 4.7,
  ),
];

/// A heading and a horizontally scrolling row of fixed-size doctor cards.
///
/// **Presentation only.** Every card's "احجز الآن" button is inert for the
/// same reason the empty-state card's CTA and the specialty chips are: there
/// is no doctor record, no booking flow and no detail screen to open. [onBook]
/// is the seam that flow plugs into, left unwired rather than pointed at a
/// stub.
class HomeFeaturedDoctors extends StatelessWidget {
  const HomeFeaturedDoctors({super.key, this.onBook});

  /// Fires with the tapped doctor. Null renders the button visibly present but
  /// unresponsive, which is the honest state today.
  final ValueChanged<Doctor>? onBook;

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

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          // "Featured", not "موثّق"/verified — the established naming. This
          // card makes no trust claim; see the deliberate absence of a badge.
          'أطباء مميزون',
          // RTL-aware rather than a hardcoded `right`, matching the
          // "تصفّح حسب التخصص" heading directly above it.
          textAlign: TextAlign.start,
          style: AuroraText.display(
            size: AuroraFontSize.h3,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: AuroraSpacing.md),
        // Bounded cross-axis extent, because a horizontal list inside Home's
        // vertically unbounded SingleChildScrollView cannot measure its own.
        //
        // The row scrolls within Home's existing 16pt side padding rather than
        // bleeding to the screen edge — the precedent the chip row set. The
        // peek does not need the bleed: at 200pt cards the narrowest supported
        // phone still shows ~118pt of the second card at rest.
        SizedBox(
          height: _listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // The page already bounces; the row should not bounce on top.
            physics: const ClampingScrollPhysics(),
            itemCount: _mockDoctors.length,
            separatorBuilder: (_, _) => const SizedBox(width: AuroraSpacing.md),
            itemBuilder: (context, index) {
              final doctor = _mockDoctors[index];
              return Align(
                // The list hands each item the full viewport height; without
                // this the card would stretch into the shadow's room.
                alignment: Alignment.topCenter,
                child: SizedBox(
                  // A fixed width, not a flex: the card keeps its exact size
                  // however long or short the list turns out to be.
                  width: _cardWidth,
                  height: _cardHeight,
                  child: DoctorCard(
                    doctor: doctor,
                    onBook: onBook == null ? null : () => onBook!(doctor),
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
            child: Center(
              child: _ClinicRow(clinicName: doctor.clinicName),
            ),
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
