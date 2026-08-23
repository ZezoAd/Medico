import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../widgets/queue_status_card.dart';

/// Home tab body.
///
/// The fixed top bar plus the live queue status card, and nothing else — the
/// rest of the Home spec (location pill, specialty filters, previously-visited
/// doctors, upcoming booking) is still to come.
///
/// The card is fed **static demo data**. There is no realtime queue provider
/// yet, so nothing here talks to Supabase; when that provider lands, these
/// constants are what it replaces.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // A mid-queue scenario: the doctor is on #7, this patient holds #11, so
  // there are 4 people still ahead — far enough in to be interesting, but
  // neither next-up nor at the back of the line.
  static const _doctorName = 'د. أحمد الربيعي';
  static const _doctorLocation = 'الطابق الثاني، غرفة ٣';
  static const _patientsAhead = 4;
  static const _avgConsultMinutes = 10;
  static const _doctorQueuePosition = 7;
  static const _patientQueuePosition = 11;

  /// Captured once, not read per build.
  ///
  /// The card documents that this must be pinned at the moment the
  /// connection leaves `live` and held steady afterwards — recomputing it
  /// against `now` on every rebuild is the drift bug that contract exists to
  /// prevent. It goes unused while the card is `live`, but honouring the
  /// contract here means the widget stays correct the moment demo data is
  /// swapped for a real feed.
  late final DateTime _recordedAt = DateTime.now();

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
                QueueStatusCard(
                  doctorName: _doctorName,
                  doctorLocation: _doctorLocation,
                  patientsAhead: _patientsAhead,
                  avgConsultMinutes: _avgConsultMinutes,
                  doctorQueuePosition: _doctorQueuePosition,
                  patientQueuePosition: _patientQueuePosition,
                  // Default resting state — not stale, not retrying, so no
                  // stalenessReason and no retry action apply.
                  connectionStatus: QueueConnectionStatus.live,
                  recordedAt: _recordedAt,
                  // The queue detail sheet isn't built yet, so tapping is
                  // deliberately inert rather than wired to a stand-in route.
                  onTap: () {},
                ),
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
      // The placeholder takes the flexible slot so it is pinned to the pill's
      // own right-hand edge (its RTL start), with the magnifier parked at the
      // opposite end rather than crowding the text.
      child: Row(
        children: [
          Expanded(
            child: Text(
              'ابحث عن طبيب أو تخصص',
              style: AuroraText.body(
                size: 14,
                weight: FontWeight.w500,
                color: AuroraColors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AuroraSpacing.sm),
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: AuroraColors.secondary,
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
