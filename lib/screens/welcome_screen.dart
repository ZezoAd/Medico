import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../widgets/auth_surface.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// The signed-out root: a single glass panel carrying the mark, the name and
/// a one-line pitch, over two buttons.
///
/// [AuthGate] renders this rather than pushing it, so it is the bottom of the
/// auth stack — Sign In and Sign Up are both pushed on top of it and the
/// system back gesture returns here from either.
///
/// It replaced Sign In as the root when the tab-pill shell was retired. With
/// two full screens instead of two tabs, something has to answer "which one?"
/// before either is shown, and a screen that asks it plainly beats defaulting
/// to Sign In and burying إنشاء حساب in a footer.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.initialErrorMessage,
    this.initialUnconfirmedEmail,
  });

  /// Set by [AuthGate] when it lands here after a *forced* sign-out rather
  /// than a cold start — an expired session, or an account that never
  /// finished signup verification.
  ///
  /// That message belongs on Sign In, which is the only screen that can act
  /// on it, so its presence turns this screen into a pass-through: see
  /// [_forwardToSignIn].
  final String? initialErrorMessage;

  /// The address the forced sign-out was about, forwarded alongside
  /// [initialErrorMessage] so Sign In's banner can offer to resend a code to
  /// it. See `SignInScreen.initialUnconfirmedEmail`.
  final String? initialUnconfirmedEmail;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// True only for the single frame before the forward push lands.
  ///
  /// It is state and not a getter over [WelcomeScreen.initialErrorMessage],
  /// because the forward happens exactly once. Leaving it derived kept this
  /// screen blank forever — so backing out of the Sign In it forwarded to
  /// landed on an empty gradient instead of on Welcome.
  late bool _forwarding = widget.initialErrorMessage != null;

  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    if (_forwarding) {
      // Pushed rather than replaced: Sign In sits on top of this route
      // exactly as it would have if the person had tapped تسجيل الدخول, so
      // backing out of the banner lands on Welcome like it does everywhere
      // else instead of on an empty navigator.
      WidgetsBinding.instance.addPostFrameCallback((_) => _forwardToSignIn());
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mounted = true);
    });
  }

  void _forwardToSignIn() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignInScreen(
          initialErrorMessage: widget.initialErrorMessage,
          initialUnconfirmedEmail: widget.initialUnconfirmedEmail,
        ),
      ),
    );
    // Drop the blank pass-through state now that Sign In covers this route.
    // The rebuild is invisible — nothing can see Welcome at this moment — and
    // it is what makes the screen underneath a real Welcome to come back to.
    setState(() {
      _forwarding = false;
      _mounted = true;
    });
  }

  void _goSignIn() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignInScreen()));
  }

  void _goSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // While forwarding, paint the bare gradient. The panel and buttons would
    // be on screen for exactly one frame before Sign In covers them, which
    // reads as a flash of the wrong screen rather than as a fast transition.
    if (_forwarding) return const AuthScreen(child: SizedBox.expand());

    return AuthScreen(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 500),
                  curve: AuroraMotion.easeOut,
                  offset: _mounted ? Offset.zero : const Offset(0, 0.04),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _mounted ? 1 : 0,
                    child: const _BrandPanel(),
                  ),
                ),
              ),
            ),
            const _TrustRow(),
            const SizedBox(height: 18),
            _WelcomePrimaryButton(
              label: 'إنشاء حساب جديد',
              onPressed: _goSignUp,
            ),
            const SizedBox(height: 11),
            _WelcomeSecondaryButton(
              label: 'تسجيل الدخول',
              onPressed: _goSignIn,
            ),
          ],
        ),
      ),
    );
  }
}

/// The frosted panel: mark, wordmark, tagline.
///
/// A fixed 330pt tall, as drawn, but wrapped so a short screen shrinks it
/// rather than overflowing — on a 568pt phone the buttons and trust row
/// alone claim ~230pt of the column.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 330),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              offset: const Offset(0, 12),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BrandMark(),
            const SizedBox(height: 24),
            // Latin wordmark, so it is force-wrapped LTR rather than
            // inheriting the screen's RTL and rendering its letters in the
            // wrong order at the margins.
            const Directionality(
              textDirection: TextDirection.ltr,
              child: _Wordmark(),
            ),
            const SizedBox(height: 9),
            Text(
              'رفيقك في كل موعد طبي',
              textAlign: TextAlign.center,
              style: AuroraText.body(
                size: 13.5,
                weight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Medico',
      style: AuroraText.display(
        size: 30,
        weight: FontWeight.w700,
        color: Colors.white,
      ).copyWith(letterSpacing: -0.6),
    );
  }
}

/// The placeholder mark: a medical cross built from two rounded bars inside a
/// frosted tile.
///
/// Drawn rather than bundled because the design's own notes call the mark
/// provisional and ask for the real logo file to be dropped into this exact
/// 104pt slot. Keeping it as widgets means the swap is one `Image.asset`.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 14),
            blurRadius: 28,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _CrossBar(width: 48, height: 12),
              _CrossBar(width: 12, height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrossBar extends StatelessWidget {
  const _CrossBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Three claims, dot-separated, above the buttons.
///
/// The design's first item was a doctor count. It is gone: there is no real
/// number to put there before launch, and a made-up one on the first screen
/// anybody sees is the wrong thing to be approximate about. "تتبّع مباشر
/// للدور" says what the app actually does and needs no maintenance.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final style = AuroraText.body(
      size: 11.5,
      color: Colors.white.withValues(alpha: 0.8),
    );
    // The separators sit a tier quieter than the claims they separate, so the
    // row reads as three items rather than five.
    final dotStyle = style.copyWith(color: Colors.white.withValues(alpha: 0.4));

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 6,
      children: [
        Text('تتبّع مباشر للدور', style: style),
        Text('·', style: dotStyle),
        Text('حجز فوري', style: style),
        Text('·', style: dotStyle),
        Text('بيانات مشفّرة', style: style),
      ],
    );
  }
}

/// Solid white on the gradient — the loudest thing on the screen, because
/// signing up is the action this screen exists to get.
class _WelcomePrimaryButton extends StatelessWidget {
  const _WelcomePrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              offset: const Offset(0, 9),
              blurRadius: 22,
            ),
          ],
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            label,
            style: AuroraText.body(
              size: 16,
              weight: FontWeight.w600,
              color: AuthColors.onWhiteButton,
            ),
          ),
        ),
      ),
    );
  }
}

/// The glass counterpart — present and tappable, but visibly the second
/// choice.
class _WelcomeSecondaryButton extends StatelessWidget {
  const _WelcomeSecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: AuroraText.body(
            size: 16,
            weight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
