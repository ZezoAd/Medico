/// A doctor as a banner-topped card.
library;

import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/aurora_tokens.dart';

/// Gradient banner, a rounded-square avatar straddling its lower edge, then a
/// centred name/specialty/clinic column over a full-width "احجز الآن" CTA.
///
/// **The 2026-09-07 redesign of the old 200×236 card**, built to
/// `lib/design_reference/doctor_card_banner_shape.html` and then scaled down
/// from it. The reference is drawn at 320×440, which is most of a phone's
/// width and read as a page rather than as a card in a row; this keeps its
/// shape — banner, straddling avatar, bracketed clinic, full-width CTA — at
/// 210×256, barely wider than the card it replaces and about 8% taller. Every
/// pixel value here is that reduction, not the reference's own number, and the
/// height is what fits above the bottom navigation bar on the target handset
/// rather than a proportion carried over from the mockup.
///
/// The vertical layout is an explicit grid of fixed zones that sum to
/// [preferredHeight] — see the block of constants below.
///
/// **Deliberately knows nothing about the carousel it is currently shown in.**
/// It takes a [Doctor] and a callback, sizes itself to whatever box its parent
/// gives it, and is hosted by `home_specialty_doctors.dart` today and by the
/// not-yet-built Newly Added Doctors section later. Nothing about a specialty
/// filter, a draw, or a refresh epoch reaches in here.
///
/// Emphatically **not** a variant of `DoctorListRow` in `doctor_list_row.dart`.
/// That is a full-width list row with a small circular avatar, read down a
/// column; this is a large standalone card read one at a time. They are two
/// components that happen to draw the same model.
///
/// Presentation only: it takes its one action as a callback and never touches
/// Supabase. A null [onBook] renders the CTA fully styled but unresponsive —
/// the honest state while there is no booking flow to open.
///
/// **Carries no rating pill, no availability dot and no verified badge**, the
/// same three exclusions the card it replaces was specified with. The rating
/// pill is the one that actually went: the old card rendered
/// [Doctor.rating] when it was non-null, which no mock doctor is and no real
/// row can be until a review system exists, so it only ever reserved empty
/// space. [Doctor.rating] is untouched on the model; nothing on this card reads
/// it.
class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.onBook});

  final Doctor doctor;

  /// Fires when "احجز الآن" is tapped. Null renders the CTA visibly present
  /// but inert.
  final VoidCallback? onBook;

  /// The size the card is designed at, and what every host should give it.
  ///
  /// Public so the carousel, the dev preview and the widget tests all size it
  /// from one place instead of restating the pair — the old card's 200×236 was
  /// spelled out in all three, and a redesign meant finding every copy.
  ///
  /// **Scaled down from the reference's 320×440**, which was faithful to the
  /// mockup and far too big in the hand: at 320 a card was most of a phone's
  /// width, so the carousel read as a stack of pages rather than as a row to
  /// scan. 210 keeps the banner shape while landing within a few points of the
  /// 200 the old card used, which is a width this carousel is known to work at.
  static const double preferredWidth = 210;

  /// Every card in a row is exactly this tall whatever its content does — a
  /// long clinic name wraps into the band held for it rather than growing the
  /// card, and a short one leaves that band the same size.
  ///
  /// **Set by what fits above the fold, not by taste.** On the Tecno (360×800
  /// logical) the carousel's top edge lands at ~436 and the bottom navigation
  /// bar starts at ~700, so a card has ~264pt to live in. At 300 the CTA fell
  /// off the bottom of the screen — the one control on the card, invisible
  /// until you scrolled. 256 clears it with room to spare.
  ///
  /// **Not a free parameter** — it is the sum of the two blocks below, and
  /// every one of their parts is a fixed number rather than something measured
  /// from text:
  ///
  ///     _avatarBlockHeight   // 112
  ///   + _bodyHeight          // 144
  ///
  /// Change any zone and this has to follow, or the column overflows rather
  /// than shrinking — which the widget tests fail on.
  static const double preferredHeight = _avatarBlockHeight + _bodyHeight;

  /// Off the [AuroraRadius] scale on purpose — the reference specifies 22, and
  /// the nearest tokens (20, 28) are visibly rounder or squarer at this card
  /// size. Worth folding back onto the scale if it survives device review.
  static const double _cardRadius = 22;

  // ---------------------------------------------------------------------
  // The vertical grid.
  //
  // Every zone below is a fixed height on a 4pt scale, and the card is their
  // sum. Nothing here is measured from rendered text: each text zone declares
  // its own line box (font size × line height, both constants), so the layout
  // is arithmetic rather than something that happens to fit. That is what lets
  // [preferredHeight] be derived instead of guessed, and what keeps the
  // hairlines at the same height on every card in a row.
  // ---------------------------------------------------------------------

  static const double _bannerHeight = 72;

  static const double _avatarSize = 72;

  /// The ring of card surface around the avatar, which is what separates it
  /// from the gradient behind its upper half.
  static const double _avatarBorder = 4;

  /// The avatar's full footprint, border included.
  static const double _avatarBox = _avatarSize + _avatarBorder * 2;

  /// **Exactly half the avatar** — so the banner's lower edge passes through
  /// the avatar's centre line rather than clipping it near the bottom.
  ///
  /// The reference straddles at about three quarters, which put the cut just
  /// under the initials and read as the avatar having been *dropped* onto the
  /// banner. Bisecting it reads as one deliberate shape: equal gradient above
  /// and card below, and the avatar's own centre as the seam between the two
  /// halves of the card.
  static const double _avatarOverlap = _avatarBox / 2;

  /// Banner plus the half of the avatar that hangs below it.
  static const double _avatarBlockHeight =
      _bannerHeight - _avatarOverlap + _avatarBox;

  /// The name's line box: [AuroraFontSize.bodyLg] at [_nameLineHeight] = 21.
  static const double _nameLineHeight = 1.4;

  /// The specialty's and the CTA label's line box:
  /// [AuroraFontSize.caption] at [_metaLineHeight] = 18.
  static const double _metaLineHeight = 1.44;

  /// One line of clinic text: [AuroraFontSize.micro] at [_clinicLineHeight] =
  /// 15.4. [_ClinicRow] sets the same multiplier on the text itself — change
  /// one and the other has to follow, or the band stops matching its contents.
  static const double _clinicLineHeight = 1.4;

  static const double _clinicLine = AuroraFontSize.micro * _clinicLineHeight;

  /// The gap between the two hairlines: two lines of clinic and a little air,
  /// and nothing else. `_ClinicRow` caps itself at those two lines, so this is
  /// the most it can ever need — a one-line clinic simply centres in it.
  static const double _clinicBandHeight = _clinicLine * 2 + AuroraSpacing.xs;

  /// The CTA's own height: its label's line box inside symmetrical padding.
  static const double _ctaHeight =
      AuroraFontSize.caption * _metaLineHeight + _ctaPadding * 2;

  static const double _ctaPadding = 7;

  /// The body's total, and the second half of [preferredHeight].
  ///
  /// The parts, top to bottom: 8 padding, the name's 21, a 2pt gap, the
  /// specialty's 18, the [Spacer] that takes the remainder (~14), a hairline,
  /// the clinic band, a second hairline, an 8pt gap, the CTA, and 12 of bottom
  /// padding. The Spacer is the only elastic thing in the card — it exists so
  /// this number can be a round 144 rather than the exact sum of the rest.
  static const double _bodyHeight = 144;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;
    final radius = BorderRadius.circular(_cardRadius);

    return Container(
      decoration: BoxDecoration(
        // Opaque, and the layer that carries the elevation — the banner and
        // the avatar both paint on top of it.
        color: palette.surface,
        borderRadius: radius,
        boxShadow: palette.cardShadow,
      ),
      // The banner is a square-cornered box; this is what rounds its top two
      // corners into the card's.
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              // Down to the avatar's bottom edge, not to the banner's: the
              // body below starts under the avatar, whose lower half hangs
              // past the gradient.
              height: _avatarBlockHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: _bannerHeight,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        // The raw two-stop brand ramp, flat — no blobs, no
                        // texture, no watermark. Deliberately
                        // [AuroraGradients.aurora] rather than the theme-aware
                        // [AuroraPalette.heroGradient] the queue card uses:
                        // this is the brand mark, and the design calls for the
                        // same ramp in both themes. Still worth a look on the
                        // Tecno in dark mode, though 72pt of undarkened
                        // gradient is a far smaller claim than the reference's
                        // 150 made.
                        gradient: AuroraGradients.aurora,
                      ),
                    ),
                  ),
                  Positioned(
                    top: _bannerHeight - _avatarOverlap,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _DoctorAvatar(
                        size: _avatarSize,
                        borderWidth: _avatarBorder,
                        photoUrl: doctor.photoUrl,
                        name: doctor.name,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Takes the rest of whatever height the parent handed the card.
            Expanded(
              child: Padding(
                // 16pt gutter rather than the reference's 22: on a 210pt card
                // that left only 166 for a doctor's name, and Arabic names of
                // three and four words were ellipsising that the design never
                // meant to truncate.
                //
                // Asymmetric top and bottom on purpose. The avatar's lower half
                // already sits in this block's airspace, so the name needs less
                // clearance above it than the CTA needs below it — equal
                // padding read as the whole column having slipped upward.
                padding: const EdgeInsets.fromLTRB(
                  AuroraSpacing.lg,
                  AuroraSpacing.sm,
                  AuroraSpacing.lg,
                  AuroraSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      doctor.name,
                      textAlign: TextAlign.center,
                      // Flutter's own truncation — it ellipsises RTL correctly
                      // under the app's Directionality, so there is no manual
                      // character-clipping anywhere here.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // One step down from the reference's h3, along with the
                      // specialty and clinic below it: the whole card came down
                      // by a third, and type that did not follow would have
                      // read as a large card's text crammed into a small one.
                      style: AuroraText.display(
                        size: AuroraFontSize.bodyLg,
                        color: palette.ink,
                        height: _nameLineHeight,
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
                        height: _metaLineHeight,
                      ),
                    ),
                    // The card is a fixed height, so *something* in this column
                    // has to absorb the leftover. It used to be the clinic
                    // band, which meant the two hairlines were pushed apart by
                    // every spare point and bracketed far more air than text.
                    // The slack lives here instead, above the pair, where it
                    // reads as separation between the doctor's identity and
                    // their clinic rather than as a hole inside a rule.
                    const Spacer(),
                    _Divider(color: palette.divider),
                    // Exactly two lines of clinic plus a little air, whether or
                    // not the name needs the second one. Fixed rather than
                    // wrapped so the hairlines land at the same height on every
                    // card in a row — a band that hugged its text would make
                    // the rules stagger from card to card.
                    SizedBox(
                      height: _clinicBandHeight,
                      child: Center(
                        child: _ClinicRow(clinicName: doctor.clinicName),
                      ),
                    ),
                    _Divider(color: palette.divider),
                    const SizedBox(height: AuroraSpacing.sm),
                    _BookButton(onTap: onBook),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the two hairlines bracketing the clinic row.
class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(height: 1, color: color);
}

/// The doctor's photo, or their initials, on a rounded-square disc ringed in
/// the card's own surface colour.
///
/// A rounded square, not a circle: the same shape language as the queue card's
/// doctor avatar, and deliberately unlike the circular patient avatar in
/// Profile — a doctor and the signed-in patient are different things being
/// identified.
///
/// **The initials are the normal state, not the fallback.** `public.doctors`
/// has no photo column and no upload path, so all but one of the mocks and
/// every real doctor for the foreseeable future render as two Arabic letters.
/// The photo branch is the exception being designed for, not the default.
class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({
    required this.size,
    required this.borderWidth,
    required this.photoUrl,
    required this.name,
  });

  final double size;
  final double borderWidth;
  final String? photoUrl;
  final String name;

  /// The locked ratio: 20% of the avatar's size, the top of the agreed
  /// 15–20% band. Expressed as a ratio rather than as a constant precisely so
  /// the shape survives a resize — which it has already had to, the avatar
  /// having come down from the reference's 140pt to 72 when the card shrank.
  static const double _radiusRatio = 0.20;

  /// Two Arabic initials, e.g. "د. حسين الطائي" → "ح.ط".
  ///
  /// First and last name word, skipping the "د." honorific and the "ال"
  /// definite article — "الطائي" initialises to ط, not ا, which is what makes
  /// the pair read as two distinct letters rather than as a row of alifs.
  ///
  /// Still duplicated in `doctor_list_row.dart`, which has the same helper
  /// private to its own avatar. Lifting the two into one shared place is worth
  /// doing, but that row is explicitly out of scope for this redesign — so the
  /// note moves here with the card rather than the duplication being resolved
  /// on the way past.
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
    final innerRadius = size * _radiusRatio;

    final fallback = ColoredBox(
      // Deliberately *not* [AuroraPalette.tonal], which is what the reference
      // specifies and is invisible here: the dark palette maps `tonal` and
      // `surface` to the same #1C2624, so a tonal square ringed in surface and
      // sitting on a surface card disappears completely in dark mode — the old
      // card hit exactly this on the Tecno, where the initials floated with no
      // container behind them.
      //
      // Tinting the accent instead holds in both themes: over white it lands
      // within a point or two of [AuroraColors.tonal], which *is* the
      // reference's tonal teal, and over the dark card it lifts clear of the
      // surface.
      color: palette.accentOnTonal.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          // Tracks the avatar rather than the type scale's intent: ~26% of the
          // disc, which is where the reference's 34-on-140 sat and where the
          // old 200×236 card's 17-on-60 sat too.
          _initialsFor(name),
          style: AuroraText.display(
            size: AuroraFontSize.h2,
            color: palette.accentOnTonal,
          ),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        // The ring. [AuroraPalette.surface] rather than a literal white, so it
        // matches the card body it merges into at the avatar's lower half in
        // both themes.
        color: palette.surface,
        // Concentric with the inner corner: an outer radius that ignored the
        // border width would leave the ring visibly thicker at the corners
        // than along the edges.
        borderRadius: BorderRadius.circular(innerRadius + borderWidth),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: url == null
              ? fallback
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  // A URL that fails to load degrades to exactly the same
                  // initials as a null one — a broken-image glyph on a
                  // doctor's face is worse than no photo at all. This also
                  // keeps a widget test from failing on the sandbox's blocked
                  // network.
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
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
            // Two lines is the cap the band above is sized against — see
            // [DoctorCard._clinicBandHeight]. A longer name ellipsises rather
            // than pushing the hairlines apart.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.body(
              size: AuroraFontSize.micro,
              color: palette.muted,
              height: DoctorCard._clinicLineHeight,
            ),
          ),
        ),
      ],
    );
  }
}

/// The full-width gradient CTA at the foot of the card.
class _BookButton extends StatelessWidget {
  const _BookButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // A rounded rectangle, not [AuroraRadius.pill]: the reference puts 15 on a
    // ~48pt-tall full-width button, which a pill radius would round into a
    // lozenge. [AuroraRadius.sm] holds that same proportion now the button is
    // ~36pt tall on the smaller card.
    final radius = BorderRadius.circular(AuroraRadius.sm);

    return DecoratedBox(
      decoration: BoxDecoration(
        // The in-app two-stop brand ramp, matching the banner above it — the
        // same token the selected specialty chip already paints with.
        // Emphatically not AuroraGradients.authButton: that four-stop ramp
        // belongs to the auth surface, and the two systems are kept apart on
        // purpose.
        gradient: AuroraGradients.aurora,
        borderRadius: radius,
      ),
      // Transparent Material so the ripple clips to the button and paints over
      // the gradient rather than under it.
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          // A declared height rather than padding around the label, so the CTA
          // occupies exactly the zone the card's grid budgeted for it whatever
          // the font does. [DoctorCard._ctaHeight] is that budget.
          child: const SizedBox(
            height: DoctorCard._ctaHeight,
            child: Center(child: _BookLabel()),
          ),
        ),
      ),
    );
  }
}

/// Split out only so [_BookButton]'s padding can stay `const`.
class _BookLabel extends StatelessWidget {
  const _BookLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'احجز الآن',
      textAlign: TextAlign.center,
      // Noto Kufi, unlike the old card's Tajawal CTA — the reference sets the
      // button in the display face, which even at caption size on a full-width
      // control reads as a heading rather than as body copy.
      //
      // White in both themes: the fill is the brand ramp, which does not
      // darken, so its label must not either.
      style: AuroraText.display(
        size: AuroraFontSize.caption,
        color: Colors.white,
        height: DoctorCard._metaLineHeight,
      ),
    );
  }
}
