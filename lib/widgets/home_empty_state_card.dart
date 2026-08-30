/// Home's no-active-booking card.
library;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';

/// Shown on Home when the patient has no active booking, in place of
/// `QueueStatusCard`.
///
/// Presentation only, exactly like the queue card: it takes its one action as
/// a constructor argument and never touches Supabase. Which of the two cards
/// Home shows is the caller's decision — this widget has no opinion and no
/// knowledge of booking state.
///
/// Shares the queue card's visual identity deliberately: same
/// [AuroraRadius.xl] corner, same [AuroraSpacing.xl] padding, same three
/// ambient blobs on the same 26s/34s/21s periods, same gradient. The two are
/// the same object in two states, so a patient who books should see the
/// surface persist rather than swap.
class HomeEmptyStateCard extends StatefulWidget {
  const HomeEmptyStateCard({super.key, this.onSearch});

  /// The CTA's action. Null renders the button fully styled but inert, which
  /// is the current state of the world — no search flow exists to open yet.
  final VoidCallback? onSearch;

  @override
  State<HomeEmptyStateCard> createState() => _HomeEmptyStateCardState();
}

class _HomeEmptyStateCardState extends State<HomeEmptyStateCard>
    with TickerProviderStateMixin {
  /// Each blob drifts on its own prime-ish period so the three never visibly
  /// resynchronise into a pulse. Same periods, and same order, as the queue
  /// card's — the two cards sit in the same slot, so a mismatch would read as
  /// a stutter when one replaces the other.
  static const _blobDurations = [
    Duration(seconds: 26),
    Duration(seconds: 34),
    Duration(seconds: 21),
  ];

  /// The CTA label against white. Deliberately *not*
  /// [AuroraColors.primary]: that hue is tuned to carry white text on top of
  /// it, and inverted to teal-on-white it drops under the contrast floor.
  /// This is the same green deepened until it holds.
  static const _ctaInk = Color(0xFF177A5E);

  late final List<AnimationController> _blobControllers;

  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _blobControllers = [
      for (final duration in _blobDurations)
        AnimationController(vsync: this, duration: duration),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs before the first build and again whenever MediaQuery changes, so
    // this is where animation state gets established — not in build(), which
    // must stay free of side effects.
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _syncAnimations();
  }

  void _syncAnimations() {
    for (final controller in _blobControllers) {
      if (_reducedMotion) {
        controller.stop();
      } else if (!controller.isAnimating) {
        controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _blobControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Was `MediaQuery.platformBrightnessOf`, back when main.dart declared no
    // darkTheme for `Theme.of` to reflect. The card's own dark treatment —
    // pre-darkened gradient stops, a hairline edge, a plain black drop instead
    // of the green one — now lives in the palette, so it follows the app's
    // theme rather than the device's.
    final palette = context.aurora;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuroraRadius.xl),
        border: palette.heroBorder,
        boxShadow: palette.heroShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AuroraRadius.xl),
        // The decorative layers are Positioned/Positioned.fill so they bleed
        // to the card's true rounded edges; the content is the one
        // *non-positioned* child, which is what gives the Stack its height (a
        // Stack whose children are all positioned collapses, and blows up
        // outright under the unbounded height of a scroll view). It is last
        // so it paints above the blobs, and it carries the padding — so no
        // padding is ever applied to the layers underneath it.
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: palette.heroGradient),
              ),
            ),
            Positioned(
              top: -95,
              right: -55,
              child: _DriftingBlob(
                controller: _blobControllers[0],
                size: 190,
                opacity: 0.11,
                drift: const Offset(-14, 14),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -35,
              child: _DriftingBlob(
                controller: _blobControllers[1],
                size: 130,
                opacity: 0.07,
                drift: const Offset(16, -12),
              ),
            ),
            // Pinned at 40% of the card's height. Stretching the Positioned
            // top-to-bottom and aligning inside it resolves that against the
            // real height without a LayoutBuilder, which here would only ever
            // see the unbounded incoming constraints.
            Positioned(
              top: 0,
              bottom: 0,
              left: -20,
              child: SizedBox(
                width: 90,
                child: Align(
                  alignment: const Alignment(0, -0.2),
                  child: _DriftingBlob(
                    controller: _blobControllers[2],
                    size: 90,
                    opacity: 0.05,
                    drift: const Offset(10, -8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AuroraSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'احجز دورك، وانتظر أينما كنت',
                    textAlign: TextAlign.start,
                    style: AuroraText.display(
                      size: AuroraFontSize.h2,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AuroraSpacing.md),
                  Text(
                    'لا حاجة للانتظار في العيادة ، تابع دورك مباشرة من '
                    'هاتفك أينما كنت ، وستصلك إشعارات فورية عند اقتراب دورك.',
                    textAlign: TextAlign.start,
                    style: AuroraText.body(
                      size: AuroraFontSize.body,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: AuroraSpacing.xl),
                  _SearchCta(onTap: widget.onSearch, ink: _ctaInk),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The full-width white pill CTA.
///
/// Stays white in both brightnesses on purpose: it sits on the gradient card,
/// not on the app's outer background, so the surface underneath it does not
/// change between light and dark.
class _SearchCta extends StatelessWidget {
  const _SearchCta({required this.onTap, required this.ink});

  final VoidCallback? onTap;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AuroraRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.lg),
          // Under RTL the Row's first child lands on the visual right, which
          // is where the icon belongs — leading position for an Arabic
          // reader. The pair is centred as a unit.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, size: 20, color: ink),
              const SizedBox(width: AuroraSpacing.sm),
              Text(
                'ابحث عن طبيب',
                style: AuroraText.body(
                  size: AuroraFontSize.bodyLg,
                  weight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One slow-drifting translucent circle in the card's decorative layer.
///
/// A near-copy of the queue card's blob. That widget is private to
/// `queue_status_card.dart` and this task is scoped not to touch that file,
/// so the two are duplicated for now — worth lifting into one shared widget
/// the next time either card's decoration is edited.
class _DriftingBlob extends StatelessWidget {
  const _DriftingBlob({
    required this.controller,
    required this.size,
    required this.opacity,
    required this.drift,
  });

  final AnimationController controller;
  final double size;
  final double opacity;
  final Offset drift;

  @override
  Widget build(BuildContext context) {
    final blob = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(controller.value);
        return Transform.translate(
          offset: Offset(drift.dx * t, drift.dy * t),
          child: Transform.scale(scale: 1 + (0.06 * t), child: child),
        );
      },
      child: blob,
    );
  }
}
