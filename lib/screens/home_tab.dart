import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../widgets/home_empty_state_card.dart';

/// Home tab body.
///
/// The fixed top bar plus the empty-state card, and nothing else — the rest
/// of the Home spec (location pill, specialty filters, previously-visited
/// doctors, upcoming booking) is still to come.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    // The top bar sits outside the scroll view so it stays put while the
    // queue card and everything that lands under it scrolls beneath.
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AuroraSpacing.lg,
            AuroraSpacing.lg,
            AuroraSpacing.lg,
            AuroraSpacing.sm,
          ),
          child: _HomeTopBar(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AuroraSpacing.lg,
              AuroraSpacing.sm,
              AuroraSpacing.lg,
              AuroraSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TEMPORARY: hardcoded, not a decision. Nobody can hold a
                // queue position yet — there is no bookings table and no
                // booking flow — so "no active booking" is the only state
                // that can honestly be true, and showing it unconditionally
                // is more truthful than branching on data that does not
                // exist. This becomes a real conditional (empty state vs.
                // QueueStatusCard) once the Booking tab and its backing data
                // land; `queue_status_card.dart` stays built and ready for
                // that, just unreferenced from here in the meantime.
                //
                // The CTA is inert for the same reason — no search flow yet.
                const HomeEmptyStateCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Notification bell and search field.
///
/// Both halves are **inert**: there is no notification centre and no search
/// flow to open yet. Neither is an [InkWell] or a real [TextField] — a ripple
/// or a blinking caret would promise behaviour that does not exist. The search
/// bar becomes a real field when the search screen it should push to is built.
class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  /// Diameter of the bell's tonal disc, and therefore the bar's height.
  static const double _bellSize = 44;

  @override
  Widget build(BuildContext context) {
    // Under RTL a Row lays its first child out on the visual *right*, so the
    // search bar comes first in code to land on the right and the bell comes
    // last to land on the left. That mirroring is intended: the mock's
    // bell-left / search-right arrangement is what the user sees.
    return Row(
      children: const [
        Expanded(child: _SearchBar(height: _bellSize)),
        SizedBox(width: AuroraSpacing.md),
        _NotificationBell(size: _bellSize),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
      decoration: BoxDecoration(
        color: AuroraColors.tonal,
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
      ),
      // Magnifier and placeholder read as one cluster on the pill's right
      // edge, with the slack falling on the left beside the bell.
      //
      // The alignment that matters here is [Text.textAlign], not the Row's.
      // A `Text` carrying `overflow: ellipsis` reports its width as the whole
      // constraint it was offered rather than the width of its glyphs, so the
      // text box always spans the full remaining width no matter which flex
      // widget wraps it — leaving `mainAxisAlignment` no free space to push
      // around, and letting the glyphs sit wherever inside that box. Pinning
      // them with an explicit RTL-aware `TextAlign.start` is what actually
      // parks the placeholder against the magnifier.
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AuroraColors.secondary,
          ),
          const SizedBox(width: AuroraSpacing.sm),
          Expanded(
            child: Text(
              'ابحث عن طبيب أو تخصص',
              textAlign: TextAlign.start,
              style: AuroraText.body(
                size: 14,
                weight: FontWeight.w500,
                color: AuroraColors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      // Lets the unread dot overhang the disc's edge without being clipped.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AuroraColors.tonal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 22,
              color: AuroraColors.ink,
            ),
          ),
          // Static. Nothing counts unread notifications yet, so this is the
          // design's indicator and not a live badge.
          Positioned(
            top: 10,
            right: 11,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AuroraColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: AuroraColors.tonal, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
