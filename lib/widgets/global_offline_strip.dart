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
/// Lives at the top of the Home screen, above the card, and animates its own
/// height so appearing and disappearing doesn't jolt the layout below it.
class GlobalOfflineStrip extends StatelessWidget {
  const GlobalOfflineStrip({super.key, required this.visible});

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
            ? const _OfflineStripBody()
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
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.md,
        vertical: AuroraSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        // A desaturated near-black green — reads as "system chrome", not as
        // an Aurora surface and not as a red error state. Being offline is a
        // condition, not a failure.
        color: const Color(0xFF2B3733),
        borderRadius: BorderRadius.circular(AuroraRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 14,
            color: Color(0xFFEAF0EC),
          ),
          const SizedBox(width: AuroraSpacing.sm),
          Flexible(
            child: Text(
              'لا يوجد اتصال بالإنترنت حالياً',
              style: AuroraText.body(
                size: AuroraFontSize.micro,
                weight: FontWeight.w700,
                color: const Color(0xFFEAF0EC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
