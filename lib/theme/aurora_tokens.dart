/// The Aurora sheet design system — the single source of truth for colour,
/// spacing, radius, type, motion and elevation.
///
/// Before this file existed every screen declared its own private copy of the
/// palette, and they had already drifted apart (the sign-in screen was on a
/// slate/teal set that never matched the locked Aurora hues). Anything new
/// must reference these tokens rather than re-declaring literals.
library;

import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens. Values are locked — see CLAUDE.md "Locked design system".
abstract final class AuroraColors {
  static const primary = Color(0xFF1D9E75);
  static const primaryBlue = Color(0xFF2A93C9);

  /// The mid-stop used only by [AuroraGradients.backdrop]. It is not a
  /// standalone brand colour and nothing should paint with it directly.
  static const primaryMid = Color(0xFF227FAF);

  static const ink = Color(0xFF122B28);
  static const secondary = Color(0xFF5C7A74);
  static const muted = Color(0xFF8FA5A0);
  static const background = Color(0xFFF5F9F8);
  static const surface = Color(0xFFFFFFFF);
  static const tonal = Color(0xFFE6F1EE);

  /// The blue-side counterpart to [tonal], for decorative surfaces that need
  /// to echo the gradient's cool end rather than its green one.
  static const tonalBlue = Color(0xFFE4F0F7);

  /// Deliberately low-contrast — it is a hairline separator, nothing else.
  /// Against [tonal] it measures ~1.07:1, i.e. invisible, so never reach for
  /// it when a mark actually has to be seen; use [secondary] (~4.05:1) there.
  static const divider = Color(0xFFDEEAE7);

  static const disabledInk = Color(0xFF9DB0AB);

  // Status colours. Not part of the Aurora palette proper, but the auth
  // screens need states the brand hues cannot carry — a validation error in
  // Aurora green would be unreadable as an error. Kept here anyway so there
  // is still exactly one definition of each.

  /// Validation and failure.
  static const danger = Color(0xFFDC2626);

  /// Recoverable warnings — the amber variant of the auth error banner.
  static const warning = Color(0xFFD97706);

  /// Confirmation, e.g. the OTP verify checkmark. Deliberately *not*
  /// [primary]: it reads as a system success state, not as branding.
  static const success = Color(0xFF16A34A);
}

/// The two gradients in the app. They are genuinely different treatments and
/// are not interchangeable.
abstract final class AuroraGradients {
  /// The 135° two-stop brand gradient: blue at the start, green at the end.
  /// Used for buttons, active stepper nodes, and the completion badge.
  static const aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AuroraColors.primaryBlue, AuroraColors.primary],
  );

  /// The 165° three-stop full-screen canvas the auth screens sit on. The
  /// [AuroraColors.primaryMid] stop at 0.55 keeps the long diagonal from
  /// banding, which the two-stop version does over that much height — that is
  /// why this is a separate token rather than a reuse of [aurora].
  static const backdrop = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [
      AuroraColors.primary,
      AuroraColors.primaryMid,
      AuroraColors.primaryBlue,
    ],
    stops: [0.0, 0.55, 1.0],
  );
}

/// 4pt spacing scale.
abstract final class AuroraSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Corner radius scale.
abstract final class AuroraRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// Type scale — 1.25 ratio.
abstract final class AuroraFontSize {
  static const double micro = 11;
  static const double caption = 12.5;
  static const double body = 14;
  static const double bodyLg = 15;
  static const double h3 = 17;
  static const double h2 = 20;
  static const double h1 = 26;
  static const double display = 34;
}

/// Motion. Durations and curves are paired deliberately — in particular
/// [pageDuration]/[page] is shared by the onboarding header fill bar *and*
/// the page slide so the two read as a single movement rather than two
/// animations that happen to overlap.
abstract final class AuroraMotion {
  /// The shared ease-out used by press, standard and page motion. Not one of
  /// the `Curves.*` presets — `Curves.easeOutCubic` is Cubic(0.215, 0.61,
  /// 0.355, 1) and lands noticeably softer than this.
  static const easeOut = Cubic(0.33, 1.0, 0.68, 1.0);

  /// Overshoot, for things that should feel like they pop into place: the
  /// completion checkmark badge.
  static const spring = Cubic(0.34, 1.56, 0.64, 1.0);

  /// The gender segmented-control indicator slide.
  static const genderSlide = Cubic(0.32, 0.72, 0.0, 1.0);

  static const press = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 300);
  static const page = Duration(milliseconds: 520);
  static const genderSlideDuration = Duration(milliseconds: 420);
}

/// The two type faces. Loaded through `google_fonts` at the call site, which
/// is how Tajawal was already being pulled in before this file existed —
/// neither face is asset-bundled, so a first launch with no network falls
/// back to the platform default.
abstract final class AuroraText {
  /// Tajawal — body copy, labels, and anything the user reads at length.
  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AuroraColors.ink,
    double? height,
  }) {
    return GoogleFonts.tajawal(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  /// Noto Kufi Arabic — headings and step labels only. Its wider counters
  /// stop carrying at body sizes, which is why it is not the body face.
  static TextStyle display({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = AuroraColors.ink,
    double? height,
  }) {
    return GoogleFonts.notoKufiArabic(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}

/// Elevation. The design caps a view at two shadowed layers.
abstract final class AuroraShadows {
  /// Resting card lift.
  static const card = [
    BoxShadow(
      color: Color(0x0F122B28), // rgba(18,43,40,0.06)
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  /// The green glow under an enabled primary button or the active gender pill.
  static const lift = [
    BoxShadow(
      color: Color(0x471D9E75), // rgba(29,158,117,0.28)
      offset: Offset(0, 10),
      blurRadius: 26,
    ),
  ];

  /// A small, tight lift for a selected pill riding inside a tonal track.
  /// [card]'s 24px blur is far too diffuse at this size — it reads as a smudge
  /// rather than an edge.
  static const pill = [
    BoxShadow(
      color: Color(0x1A122B28), // rgba(18,43,40,0.10)
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  /// Bottom-sheet edge — throws upward, hence the negative dy.
  static const sheet = [
    BoxShadow(
      color: Color(0x24122B28), // rgba(18,43,40,0.14)
      offset: Offset(0, -8),
      blurRadius: 40,
    ),
  ];
}
