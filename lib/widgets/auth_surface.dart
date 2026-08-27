/// The shared chrome and controls of the auth surface — Welcome, Sign In,
/// Sign Up and OTP.
///
/// Every one of those screens is a full route of its own, navigated to with
/// `Navigator.push`. They are not tabs and they do not share a shell: the
/// only thing they hold in common is the vocabulary in this file, so that
/// four independent screens still read as one surface.
///
/// This replaced a shared `AuthShell` that hosted Sign In and Sign Up as the
/// two pages of a sliding `PageView` behind a tab pill. That shape existed to
/// keep the header stationary across a tab switch; with separate full screens
/// there is no tab switch to keep anything stationary for, and the header is
/// now part of each screen rather than a thing they take turns standing
/// under.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/aurora_tokens.dart';

/// The top radius of the white sheet. Large enough that the corner reads as a
/// deliberate shoulder under the hero rather than as a rounded rectangle.
const double authSheetRadius = 34;

/// The gradient canvas every auth screen sits on, with its two decorative
/// circles.
///
/// The circles are positioned with physical `left`/`right`, not
/// start/end — they are painted texture, not content, and mirroring them
/// under RTL would move the bright one out from behind the heading, which is
/// the whole reason it sits where it does.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AuroraGradients.authHero),
          ),
        ),
        const Positioned(
          top: -80,
          left: -70,
          child: _SoftCircle(size: 250, opacity: 0.13),
        ),
        const Positioned(
          top: 180,
          right: -110,
          child: _SoftCircle(size: 220, opacity: 0.08),
        ),
      ],
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// A gradient hero over a white sheet — the shape Sign In, Sign Up and OTP
/// all take.
///
/// [hero] is fixed-height and never scrolls; the sheet takes whatever is
/// left. Inside the sheet, [body] scrolls and [footer] is pinned to the
/// bottom edge, which is how the design's `flex:1` spacer behaves and, more
/// importantly, is what keeps the footer prompt reachable when the keyboard
/// has taken half the screen.
///
/// The scroll lives *inside* the sheet rather than wrapping the whole screen
/// on purpose: scrolling the hero away would slide the gradient's brightest
/// band off the top and leave the sheet floating on the pale end of the ramp.
class AuthSheetScaffold extends StatelessWidget {
  const AuthSheetScaffold({
    super.key,
    required this.hero,
    required this.body,
    this.footer,
    this.sheetPadding = const EdgeInsets.fromLTRB(28, 24, 28, 20),
  });

  final Widget hero;
  final Widget body;
  final Widget? footer;
  final EdgeInsets sheetPadding;

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hero,
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(authSheetRadius),
                ),
              ),
              child: Padding(
                padding: sheetPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: body,
                      ),
                    ),
                    ?footer,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// RTL directionality, the gradient canvas, a tap-to-dismiss-keyboard
/// target, and a top safe area — everything an auth route needs before it
/// starts drawing anything of its own.
///
/// Bottom safe area is deliberately *not* applied: the white sheet is meant
/// to run to the physical bottom edge of the screen, under the home
/// indicator. Screens pad their own footers instead.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              const Positioned.fill(child: AuthBackdrop()),
              SafeArea(bottom: false, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// The heading + subheading block that opens Sign In and Sign Up, painted on
/// the gradient.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.heading,
    required this.subheading,
    this.headingSize = 27,
    this.subheadingSize = 14,
    this.padding = const EdgeInsets.fromLTRB(28, 30, 28, 26),
    this.leading,
  });

  final String heading;
  final String subheading;
  final double headingSize;
  final double subheadingSize;
  final EdgeInsets padding;

  /// Optional control above the heading — the back chevron on OTP.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(height: 16)],
          Text(
            heading,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.display(
              size: headingSize,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subheading,
            style: AuroraText.body(
              size: subheadingSize,
              weight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The 38pt glass chevron in the top-start corner of the OTP hero.
///
/// [Icons.chevron_right] and not `chevron_left`: under RTL "back" points to
/// the right, and the design's `‹` glyph is mirrored by the browser for the
/// same reason.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed, this.tooltip});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? 'رجوع',
      child: SizedBox(
        width: 38,
        height: 38,
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: InkWell(
            onTap: onPressed,
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// A field label on the white sheet.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AuroraText.body(
        size: 13,
        weight: FontWeight.w500,
        color: AuthColors.ink,
      ),
    );
  }
}

/// The auth surface's text field.
///
/// Deliberately icon-less, unlike the Aurora field: the design drops the
/// leading mail/lock glyphs, because with a visible label above every field
/// the icon was restating the label at a glance-cost of 40pt of line width in
/// a language that reads right-to-left.
///
/// Focus changes both the border *and* the fill (tonal → white), which
/// `InputDecoration` cannot express on its own — `fillColor` takes a single
/// colour with no focused variant — so this watches [focusNode] and rebuilds.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.height = 50,
    this.radius = 16,
    this.hasError = false,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final double height;
  final double radius;
  final bool hasError;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _focused = widget.focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _focused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    // Only the listener is removed — the node itself belongs to the screen
    // that created it, which also validates on its blur.
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    final focused = widget.focusNode.hasFocus;
    if (focused != _focused) setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      borderSide: BorderSide(color: color, width: width),
    );

    final resting = widget.hasError
        ? AuthColors.danger
        : AuthColors.fieldBorder;
    final focused = widget.hasError ? AuthColors.danger : AuthColors.green;

    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: AuroraText.body(
          size: 14.5,
          weight: FontWeight.w500,
          color: AuthColors.ink,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AuroraText.body(size: 14.5, color: AuthColors.muted),
          filled: true,
          fillColor: _focused ? Colors.white : AuthColors.fieldFill,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: widget.suffix,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          border: border(resting, 1.5),
          enabledBorder: border(resting, 1.5),
          focusedBorder: border(focused, 1.5),
        ),
      ),
    );
  }
}

/// The إظهار / إخفاء text toggle that rides inside a password field.
///
/// A word rather than an eye glyph, per the design: at 12px the label is
/// unambiguous about which state a tap produces, where a crossed-out eye is
/// read both ways depending on who is looking.
class AuthPasswordToggle extends StatelessWidget {
  const AuthPasswordToggle({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          visible ? 'إخفاء' : 'إظهار',
          style: AuroraText.body(
            size: 12,
            weight: FontWeight.w600,
            color: AuthColors.link,
          ),
        ),
      ),
    );
  }
}

/// The inline validation line under a field.
///
/// Collapses to zero height rather than disappearing, so the controls below
/// it slide instead of jumping. [AnimatedSize] and not a bare `if` for the
/// same reason the Aurora version used one.
class AuthInlineError extends StatelessWidget {
  const AuthInlineError(this.message, {super.key, this.center = false});

  final String? message;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      curve: Curves.easeOut,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                message,
                textAlign: center ? TextAlign.center : TextAlign.start,
                style: AuroraText.body(size: 11.5, color: AuthColors.danger),
              ),
            ),
    );
  }
}

/// The gradient primary button.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 54,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  /// Dims the button to half strength and drops the shadow. Separate from a
  /// null [onPressed] so a gated-but-tappable state stays expressible.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AuroraGradients.authButton,
          boxShadow: enabled
              ? const [
                  // 0 16px 30px -14px rgba(15,140,140,.55) — a tinted lift in
                  // the button's own hue, not a grey drop shadow.
                  BoxShadow(
                    color: Color(0x8C0F8C8C),
                    offset: Offset(0, 10),
                    blurRadius: 24,
                  ),
                ]
              : null,
        ),
        child: SizedBox(
          height: height,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 9),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AuroraText.body(
                      size: 16,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "أو" rule between the gradient button and the Google button.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1, color: AuthColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'أو',
            style: AuroraText.body(size: 12, color: AuthColors.muted),
          ),
        ),
        const Expanded(child: Divider(height: 1, color: AuthColors.divider)),
      ],
    );
  }
}

/// The Google button.
///
/// The design draws a placeholder "G" in a circle and its own notes list the
/// official mark as outstanding work — so the real
/// `assets/icons/google_logo.svg` the app already ships is kept, and only the
/// button's frame follows the design.
class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AuthColors.outlineBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: SvgPicture.asset('assets/icons/google_logo.svg'),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AuroraText.body(
                  size: 14.5,
                  weight: FontWeight.w500,
                  color: AuthColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Folds [child] away — height and all — while a field is focused.
///
/// Restored from the retired `auth_shell.dart`, where it wrapped each card's
/// pitch line for exactly this reason. It came back for the footer prompt,
/// which has the same problem in a worse form: the footer is a fixed sibling
/// pinned to the bottom of the sheet, so when `resizeToAvoidBottomInset`
/// shrinks the Scaffold for the keyboard, the footer rides up the screen with
/// the sheet's bottom edge instead of staying put or scrolling away. Collapsed
/// it simply is not there, and the scroll area above gets the space back.
///
/// [AnimatedCrossFade] rather than a bare `if`: it tweens the height and the
/// opacity together, so the content above glides rather than snapping, and it
/// keeps both children built so there is no rebuild cost at the moment of the
/// switch. Aligned to the bottom here — the collapse should close downward,
/// toward the edge the footer is anchored to, rather than dragging the form
/// above it along.
///
/// While collapsed the layout sizes to a zero-height box, so the hidden child
/// falls outside the hit-test rect and the link underneath it cannot be
/// tapped by accident.
class AuthCollapsibleOnFocus extends StatelessWidget {
  const AuthCollapsibleOnFocus({
    super.key,
    required this.collapsed,
    required this.child,
  });

  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: child,
      secondChild: const SizedBox(width: double.infinity, height: 0),
      crossFadeState: collapsed
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: AuroraMotion.standard,
      firstCurve: AuroraMotion.easeOut,
      secondCurve: AuroraMotion.easeOut,
      sizeCurve: AuroraMotion.easeOut,
      alignment: Alignment.bottomCenter,
    );
  }
}

/// The "ليس لديك حساب؟ أنشئ حسابًا" line pinned to the bottom of a sheet.
class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
    this.fontSize = 13.5,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            prompt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuroraText.body(
              size: fontSize,
              weight: FontWeight.w300,
              color: AuthColors.secondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: AuroraText.body(
              size: fontSize,
              weight: FontWeight.w600,
              color: AuthColors.link,
            ),
          ),
        ),
      ],
    );
  }
}
