import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';

/// The device-level "you have no internet" strip.
///
/// Deliberately *not* part of [QueueStatusCard], and deliberately not
/// animated: it states a fact about the device, once, and holds still. The
/// card underneath it describes something narrower — whether this particular
/// queue is still being tracked — and owns its own retry cycle. Collapsing
/// the two would mean either the card claiming to retry when there is no
/// network to retry over, or the strip flickering in sympathy with a channel
/// drop that has nothing to do with the device being offline.
///
/// Sits at the top of the app shell, above the tab bodies, as an **inset
/// rounded pill** rather than an edge-to-edge banner: a full-bleed bar reads as
/// a system-level takeover of the whole screen, which overstates a condition
/// the person can often do nothing about and cannot dismiss. Floating it inside
/// the same [AuroraSpacing.lg] gutter the tab content uses puts it in the app's
/// own layout, as one more element on the page.
///
/// It animates its own height so appearing and disappearing doesn't jolt the
/// layout below it. That height includes its own margins, which is why they
/// live here rather than in the parent's padding: the strip's contract is that
/// it occupies **zero** vertical space while hidden, and a parent `Padding`
/// would have to re-test [visible] to honour that — duplicating the one piece
/// of state this widget exists to own, and leaving a permanent gap on every
/// screen if anyone forgot. Inside the ternary the margins also animate in and
/// out with the body instead of appearing an instant before it.
class GlobalOfflineStrip extends StatelessWidget {
  const GlobalOfflineStrip({super.key, required this.visible});

  /// Breathing room above the strip, so it does not sit flush against the
  /// status bar at the top of the safe area. Confirmed against a device
  /// recording, not eyeballed in a preview.
  static const double topMargin = AuroraSpacing.sm;

  /// Side inset. The same gutter `home_tab.dart` gives its own content, so the
  /// pill's edges line up with the cards below it rather than floating at an
  /// unrelated width.
  static const double sideMargin = AuroraSpacing.lg;

  /// Whether the *device* has no internet connection at all. Sourced from
  /// whatever watches device connectivity — never from the queue channel's
  /// own state.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AuroraMotion.standard,
      curve: AuroraMotion.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: AuroraMotion.standard,
        curve: AuroraMotion.easeOut,
        opacity: visible ? 1 : 0,
        child: visible
            ? const Padding(
                padding: EdgeInsets.fromLTRB(
                  sideMargin,
                  topMargin,
                  sideMargin,
                  0,
                ),
                child: _OfflineStripBody(),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}

class _OfflineStripBody extends StatelessWidget {
  const _OfflineStripBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Compact enough to read as one line of chrome rather than as a panel.
      // The old 10pt vertical made a ~42pt slab; this holds the row to roughly
      // the height of its own text.
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.md,
        vertical: AuroraSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AuroraColors.offlineStrip,
        borderRadius: BorderRadius.circular(AuroraRadius.md),
        // Reused, not invented: [AuroraShadows.pill] is the scale's existing
        // tight lift for exactly this size of element, and its own doc warns
        // that [AuroraShadows.card]'s 24pt blur smudges at these dimensions.
        // Taken as the constant rather than through `palette.pillShadow`
        // because the strip's colours are the same in both themes — a shadow
        // that vanished in dark mode while the pill stayed identical would be
        // the inconsistency, not the fix.
        boxShadow: AuroraShadows.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 14,
            color: AuroraColors.offlineStripInk,
          ),
          const SizedBox(width: AuroraSpacing.sm),
          Flexible(
            child: Text(
              'لا يوجد اتصال بالإنترنت حالياً',
              style: AuroraText.body(
                size: AuroraFontSize.micro,
                weight: FontWeight.w700,
                color: AuroraColors.offlineStripInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
