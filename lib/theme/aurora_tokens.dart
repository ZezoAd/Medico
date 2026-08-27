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

  // Avatar colours. The Profile tab identifies the signed-in patient with a
  // silhouette rather than a photo — `profiles` has no avatar column and one
  // is not planned yet — so `profiles.gender` is the only thing that tints it.
  //
  // All three sit at roughly the same lightness (~54-58% L) and a deliberately
  // low saturation (~8-26% S) so the avatar reads as a quiet identity mark
  // next to the Aurora hues rather than competing with them. A literal blue or
  // pink at full chroma would be the loudest thing on the screen.

  /// Muted slate-blue — `profiles.gender == 'male'`.
  static const avatarMale = Color(0xFF6B8CA8);

  /// Muted dusty-rose — `profiles.gender == 'female'`.
  static const avatarFemale = Color(0xFFA87682);

  /// Muted grey-green for an unset gender — onboarding lets the step be
  /// skipped, so null is a real state and must not fall back to either
  /// gendered colour. Sits in the same family as [muted]/[secondary].
  static const avatarNeutral = Color(0xFF8B9C98);

  // Dark-mode counterparts. Additive: every light value above is unchanged,
  // and nothing reads these unless it has established that the platform is in
  // dark mode.
  //
  // Note that `main.dart` declares only a light `ThemeData` — no `darkTheme`,
  // no `themeMode` — so `Theme.of(context).brightness` reports `light` even on
  // a dark device and cannot be used to pick between the two sets. Widgets
  // read `MediaQuery.platformBrightnessOf(context)` instead, which is the
  // workaround `queue_status_card.dart` established. When real theme wiring
  // lands, these are the values it should carry.

  /// Blue stop of the card gradient in dark mode — [primaryBlue] scrimmed 22%
  /// toward black.
  ///
  /// Precomputed rather than blended at runtime: a soft light-mode glow reads
  /// as broken on a dark surface, so dark mode needs its own flat darkened
  /// value, not a shader blend.
  static const gradientStartDark = Color(0xFF20729D);

  /// Green stop of the card gradient in dark mode — [primary] scrimmed 22%
  /// toward black. See [gradientStartDark].
  static const gradientEndDark = Color(0xFF17794F);

  /// App background — the counterpart to [background].
  static const bgDark = Color(0xFF121A18);

  /// Tonal fill — the counterpart to [tonal].
  static const tonalDark = Color(0xFF1C2624);

  /// Primary text — the counterpart to [ink].
  static const inkDark = Color(0xFFEAF3F0);

  /// Secondary text — the counterpart to [secondary].
  static const secondaryDark = Color(0xFF9FB6B0);

  /// Tertiary text — the counterpart to [muted].
  static const mutedDark = Color(0xFF7C948E);
}

/// The auth surface's own palette.
///
/// Deliberately separate from [AuroraColors] rather than folded into it. The
/// app runs a two-surface system: Aurora for the in-app product (Home, queue
/// card, onboarding, empty states) and this for the brand/auth screens —
/// Welcome, Sign In, Sign Up, OTP. The two are close cousins, not the same
/// set: the auth ink is a cool navy (#0B2438) where Aurora's is a warm
/// blue-green (#122B28), and the field fill and hairlines shift with it.
///
/// Keeping them apart is what stops a future "tidy-up" from collapsing one
/// into the other and quietly restyling Home. Nothing outside the auth
/// screens should read these, and the auth screens should not read
/// [AuroraColors]' text/field tokens.
abstract final class AuthColors {
  // The four gradient stops. Named for their position on the ramp, not for
  // any semantic role — only [AuroraGradients.authHero] and
  // [AuroraGradients.authButton] should paint with them.
  static const green = Color(0xFF0FA57C);
  static const teal = Color(0xFF0D9E97);
  static const cyan = Color(0xFF1492C1);
  static const blue = Color(0xFF1E7FC6);

  /// Primary text on the white sheet.
  static const ink = Color(0xFF0B2438);

  /// Supporting copy — footer prompts, checkbox terms, resend timer.
  static const secondary = Color(0xFF5A7386);

  /// The quietest text tier: the "أو" divider label and the OTP spam-folder
  /// hint.
  static const muted = Color(0xFF8C9A9E);

  /// Interactive text on white — "نسيت كلمة المرور؟", the footer links, the
  /// password show/hide toggle. Darker than [green] so it holds at 13px.
  static const link = Color(0xFF0E8F79);

  /// The Welcome screen's primary button label, on solid white.
  static const onWhiteButton = Color(0xFF0E7F6E);

  /// Field fill at rest. Fields go white on focus.
  static const fieldFill = Color(0xFFF2F7F6);
  static const fieldBorder = Color(0xFFE3EBEA);

  /// The Google button's resting border — a touch warmer than [fieldBorder],
  /// because it sits on white rather than on a filled field.
  static const outlineBorder = Color(0xFFDDE5E4);

  /// The "أو" hairline.
  static const divider = Color(0xFFE6ECEB);

  /// The unchecked terms box.
  static const checkboxBorder = Color(0xFFC3D0CE);

  /// Inline field-level validation text. Not [AuroraColors.danger] — that red
  /// is tuned against the Aurora palette and reads hotter than this surface
  /// wants at 11.5px.
  static const danger = Color(0xFFC0392B);
}

/// The four gradients in the app. They are genuinely different treatments and
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

  /// The auth screens' full-screen canvas: CSS `linear-gradient(163deg,
  /// #0FA57C 0%, #0D9E97 36%, #1492C1 70%, #1E7FC6 100%)`.
  ///
  /// A four-stop ramp, one stop longer than [backdrop], because it travels
  /// further across the hue wheel — green all the way to a true blue rather
  /// than green to the brand's blue — and three stops band visibly over 800pt
  /// of phone.
  ///
  /// 163° in CSS is measured clockwise from "to top", so the axis points down
  /// and slightly to the right: `(sin 163°, -cos 163°)` = `(0.29, 0.96)`,
  /// which is the begin/end pair below. Absolute [Alignment], not
  /// [AlignmentDirectional] — the ramp is a fixed physical diagonal and must
  /// not mirror under the app's RTL directionality.
  ///
  /// Separate from [backdrop] on purpose. [backdrop] is consumed by the
  /// in-app product surface and is locked; this is the auth/brand surface.
  /// The two-gradient split is deliberate and permanent.
  static const authHero = LinearGradient(
    begin: Alignment(-0.29, -0.96),
    end: Alignment(0.29, 0.96),
    colors: [
      AuthColors.green,
      AuthColors.teal,
      AuthColors.cyan,
      AuthColors.blue,
    ],
    stops: [0.0, 0.36, 0.70, 1.0],
  );

  /// The auth screens' primary button: CSS `linear-gradient(270deg, #0FA57C
  /// 0%, #0D9E97 50%, #1E7FC6 100%)`.
  ///
  /// 270° points to the left, so the 0% stop sits on the *right* edge —
  /// green on the right, blue on the left. A different geometry from
  /// [authHero]'s diagonal, which is why it is its own token rather than a
  /// reuse: a button is 54pt tall and a diagonal ramp across it reads as a
  /// smudge, where a horizontal one reads as a sweep.
  ///
  /// [AuthColors.cyan] is deliberately absent — over ~300pt of button width
  /// three stops are plenty, and dropping it keeps the blue end from arriving
  /// too early.
  static const authButton = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [AuthColors.green, AuthColors.teal, AuthColors.blue],
    stops: [0.0, 0.5, 1.0],
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

  /// One step above [display], for a single number that is the whole point of
  /// a view — the Home queue card's patients-ahead count. Off the 1.25 ratio
  /// on purpose: at this size the glyph is read as a figure, not as text, so
  /// it is tuned to the card rather than to the scale.
  static const double hero = 60;
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
