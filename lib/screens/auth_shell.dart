/// The persistent chrome both auth forms live inside.
library;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../utils/auth_error_mapper.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_tab_switcher.dart';
import 'sign_in_page.dart';
import 'sign_up_screen.dart';

/// What the shell needs in order to draw a banner on a form's behalf.
///
/// The forms own their own error state — this is only the rendered shape of
/// it, republished whenever that state changes.
class AuthBannerData {
  const AuthBannerData({
    required this.info,
    required this.onDismiss,
    this.action,
    this.actionLabel,
  });

  final AuthErrorInfo info;
  final VoidCallback onDismiss;
  final VoidCallback? action;
  final String? actionLabel;
}

/// Lets a form hand its banner up to the shell without the shell knowing
/// anything about how that form decides what to show.
///
/// A [ValueNotifier] rather than a callback so republishing never has to
/// happen during the parent's build — the shell listens and rebuilds only the
/// banner slot.
typedef AuthBannerSlot = ValueNotifier<AuthBannerData?>;

/// Gradient canvas, decorative circles, brand, tab switcher and banner — all
/// of it stationary — wrapped around a two-page [PageView] holding the sign-in
/// and sign-up forms.
///
/// This exists because the tab switch used to be a `Navigator.push` between
/// two complete screens. Every pixel moved on a tap, including the brand and
/// the tab strip itself, which is what made it read as a page swap rather than
/// a tab switch no matter what curve the route transition used. Now only the
/// forms travel, and they travel on exactly the mechanism the onboarding flow
/// uses for its own step-to-step slide: a [PageView] with
/// [NeverScrollableScrollPhysics] driven by `animateToPage`, at
/// [authTabMotionDuration] / [AuroraMotion.easeOut].
///
/// A `PageView` and not an `AnimatedSwitcher`: the switcher builds a *new*
/// child and discards the old one, which for two `StatefulWidget` forms means
/// destroying their `TextEditingController`s, focus nodes, validation errors
/// and in-flight loading flags on every tab tap. Half-typed input would
/// vanish, and a switch during a Supabase call would dispose the state that
/// call returns into. The `PageView` keeps both alive side by side, which is
/// also why the slide can show both forms moving as one track.
///
/// Under RTL a `PageView` lays page 1 to the *left* of page 0, so advancing
/// sign-in → sign-up carries the outgoing form off to the right and brings the
/// incoming one in from the left. That is the app's established forward
/// direction, and it falls out of the layout rather than being hand-rolled
/// with offsets — the same reason onboarding gets it right for free.
class AuthShell extends StatefulWidget {
  const AuthShell({
    super.key,
    this.initialTab = 0,
    this.initialErrorMessage,
    this.initialUnconfirmedEmail,
  });

  /// 0 = sign in, 1 = sign up.
  final int initialTab;

  /// Forwarded to the sign-in form. See [SignInPage.initialErrorMessage].
  final String? initialErrorMessage;
  final String? initialUnconfirmedEmail;

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  static const _signIn = 0;

  late int _tab = widget.initialTab;
  late final PageController _pageController = PageController(
    initialPage: widget.initialTab,
  );

  /// One slot per form. Keeping them separate means switching tabs cannot
  /// carry one form's error across to the other.
  final _signInBanner = AuthBannerSlot(null);
  final _signUpBanner = AuthBannerSlot(null);

  @override
  void dispose() {
    _pageController.dispose();
    _signInBanner.dispose();
    _signUpBanner.dispose();
    super.dispose();
  }

  void _goTo(int tab) {
    if (tab == _tab) return;
    // Dismiss the keyboard first: sliding a page out from under a focused
    // field leaves the keyboard up over a form that no longer owns it.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = tab);
    _pageController.animateToPage(
      tab,
      duration: authTabMotionDuration,
      curve: AuroraMotion.easeOut,
    );
  }

  AuthBannerSlot get _activeBanner =>
      _tab == _signIn ? _signInBanner : _signUpBanner;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Let the keyboard resize the body so the scroll views below can
        // bring a focused field above it instead of the keyboard covering it.
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              const Positioned.fill(child: AuthGradientBackdrop()),
              // Top-left circle (RTL: visually the trailing side of the
              // header).
              const Positioned(
                top: -120,
                left: -100,
                child: AuthSoftCircle(size: 280, opacity: 0.06),
              ),
              const Positioned(
                bottom: -80,
                right: -70,
                child: AuthSoftCircle(size: 220, opacity: 0.05),
              ),
              SafeArea(child: _buildBody()),
              // Same slot, same padding, same stacking order the two screens
              // each used before they shared a shell — so a banner still lands
              // over the brand rather than inside the form area.
              ValueListenableBuilder<AuthBannerData?>(
                valueListenable: _activeBanner,
                builder: (context, banner, _) {
                  if (banner == null) return const SizedBox.shrink();
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: AuthErrorBanner(
                          message: banner.info.message,
                          severity: banner.info.severity,
                          onRetry: banner.action,
                          retryLabel: banner.actionLabel,
                          onDismiss: banner.onDismiss,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // The same "Holy Grail" gap scaling both screens used when each owned its
    // own copy of this column, so nothing shifts position now that it is
    // shared.
    return LayoutBuilder(
      builder: (context, constraints) {
        final brandToTabs = (constraints.maxHeight * 0.015).clamp(10.0, 16.0);
        final tabsToCard = (constraints.maxHeight * 0.025).clamp(16.0, 24.0);
        const minTopGap = 24.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: minTopGap),
              const _Brand(),
              SizedBox(height: brandToTabs),
              AuthTabSwitcher(
                labels: const ['تسجيل الدخول', 'إنشاء حساب'],
                selectedIndex: _tab,
                onSelected: _goTo,
              ),
              SizedBox(height: tabsToCard),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  // Button-driven only, exactly like onboarding: these are two
                  // named destinations, not a carousel to swipe through.
                  physics: const NeverScrollableScrollPhysics(),
                  // Each form gets its own layer. Both are on screen together
                  // for the whole slide, and both are expensive — a dozen
                  // fields, a shadowed card, gradient text. Without the
                  // boundaries every frame of the slide repaints both
                  // subtrees into one layer; with them the compositor just
                  // moves two cached layers, which is the difference between
                  // a smooth slide and a stuttering one on a mid-range phone.
                  children: [
                    RepaintBoundary(
                      child: SignInForm(
                        banner: _signInBanner,
                        initialErrorMessage: widget.initialErrorMessage,
                        initialUnconfirmedEmail: widget.initialUnconfirmedEmail,
                      ),
                    ),
                    RepaintBoundary(child: SignUpForm(banner: _signUpBanner)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The Medico wordmark row above the switcher.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'Medico',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// The 165° teal→blue canvas the whole screen sits on.
class AuthGradientBackdrop extends StatelessWidget {
  const AuthGradientBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AuroraGradients.backdrop),
      child: SizedBox.expand(),
    );
  }
}

/// Translucent decorative circle bleeding off the screen edges.
class AuthSoftCircle extends StatelessWidget {
  const AuthSoftCircle({super.key, required this.size, required this.opacity});

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
