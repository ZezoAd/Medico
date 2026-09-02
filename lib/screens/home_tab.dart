import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../theme/aurora_tokens.dart';
import '../widgets/home_specialty_doctors.dart';
import '../widgets/home_specialty_chips.dart';
import '../widgets/queue_status_card.dart';

/// TEMPORARY / TEST-ONLY. The simulated channel-drop cycle driven by the test
/// button on Home — see the block in [_HomeTabState]. Deleted along with it
/// once a real realtime channel reports its own status.
enum _ChannelDropPhase {
  /// No simulation running; the card follows real device connectivity.
  none,

  /// Pretending a reconnect is in flight, for the badge's countdown window.
  retrying,

  /// The pretend reconnect gave up — a stale card offering manual retry.
  dropped,
}

/// Home tab body.
///
/// The fixed top bar, then a pull-to-refresh scrolling column: the hero card,
/// the browse-by-specialty chips, and the featured-doctors carousel. The rest
/// of the Home spec (location pill, previously-visited doctors, upcoming
/// booking) is still to come.
///
/// The hero slot currently holds [QueueStatusCard] as a placeholder, driven by
/// real device connectivity plus one test-only control — see the marked block
/// below.
///
/// Everything below the top bar is presentation only. None of it has a backing
/// query — the doctors are hardcoded and every CTA is inert — because the rows
/// and flows they would talk to do not exist yet. The specialty filter is the
/// one exception: it is real, but it filters the hardcoded list. Each widget
/// carries its own note on what it is waiting for.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.connectivityService});

  /// Owned by `HomeScreen`, which outlives every tab switch. Passed in rather
  /// than created here so this tab does not start and stop a platform
  /// subscription each time somebody visits Bookings and comes back — and so
  /// the strip above the tabs and the reconnect epoch below them are reading
  /// the same answer rather than two independently-timed ones.
  final ConnectivityService connectivityService;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  /// The chip row's live selection, held here rather than inside
  /// [HomeSpecialtyChips] because two siblings need it: the chips paint the
  /// highlight from their own state, and the carousel filters on this.
  String _selectedSpecialtyKey = HomeSpecialtyDoctors.allSpecialtiesKey;

  /// Bumped every time Home's content should be considered re-fetched — by a
  /// pull-to-refresh, or by the device coming back online. Sections below read
  /// it as "throw away what you were showing and draw again"; nothing else on
  /// Home is allowed to invalidate them, which is what keeps an unrelated
  /// rebuild from reshuffling the carousel.
  ///
  /// A counter rather than a bool or a timestamp: monotonic, cheap to compare
  /// in `didUpdateWidget`, and it cannot collide with itself the way a clock
  /// read twice in the same millisecond can.
  int _refreshEpoch = 0;

  /// **Placeholder duration.** Nothing on Home has a backing query yet, so a
  /// refresh has no real work to await. Holding the spinner briefly is what
  /// makes the gesture legible — releasing into an instant snap-back reads as
  /// the pull having failed. Delete this the moment there is a fetch to await
  /// instead; it is not a deliberate minimum-spinner policy.
  static const _placeholderRefreshDelay = Duration(milliseconds: 500);

  StreamSubscription<bool>? _onlineSub;

  /// The device's current connection, mirrored for `build`.
  late bool _isOnline;

  /// The last online value this tab saw, or null before the first one.
  ///
  /// Null, not false, on purpose. The service's first emission only confirms
  /// what the device was already doing, and treating that as a false→true
  /// transition would fire a "reconnected" refresh on a launch where nothing
  /// ever went wrong.
  bool? _wasOnline;

  // ===========================================================================
  // TEMPORARY / TEST-ONLY — delete with the placeholder card below.
  //
  // There is no realtime channel for a doctor's queue yet, so `retrying` and a
  // channel-drop `stale` cannot occur on their own: device connectivity only
  // ever produces `live` or a device-offline `stale`. This block fakes the
  // missing third case on demand so all three states can be exercised on a
  // real handset. Everything under this banner goes when the real Supabase
  // channel lands and starts reporting its own status.
  // ===========================================================================

  /// Which simulated channel state the test button has forced, if any.
  _ChannelDropPhase _dropPhase = _ChannelDropPhase.none;

  /// Matches `RETRY_SECONDS` in `design_reference/ConnectivityArchitecture.jsx`
  /// and [QueueStatusCard]'s own badge window, so the ring finishes draining
  /// exactly as the card settles into stale.
  static const _retryWindow = Duration(seconds: 10);

  Timer? _channelDropTimer;

  // ======================= end TEMPORARY / TEST-ONLY =========================

  /// When the queue numbers were last confirmed live.
  ///
  /// Frozen once, on the live→not-live edge, and never touched again while
  /// non-live — the contract [QueueStatusCard.recordedAt] documents, and the
  /// same handling `queue_status_card_preview.dart` uses. Recomputing it on
  /// rebuild would let the stale estimate creep forward while nothing was
  /// actually being received.
  DateTime _recordedAt = DateTime.now();

  /// The card's connection state, derived rather than stored.
  ///
  /// A genuinely offline device outranks the simulation: there is nothing for
  /// a retry to accomplish without a network, so the test phase must never put
  /// a retry button on screen in that case.
  QueueConnectionStatus get _queueStatus {
    if (!_isOnline) return QueueConnectionStatus.stale;
    return switch (_dropPhase) {
      _ChannelDropPhase.retrying => QueueConnectionStatus.retrying,
      _ChannelDropPhase.dropped => QueueConnectionStatus.stale,
      _ChannelDropPhase.none => QueueConnectionStatus.live,
    };
  }

  /// Only meaningful while stale. Stale *and* online can only be the simulated
  /// channel drop, since real connectivity would have said live; stale and
  /// offline is the device itself.
  StalenessReason? get _stalenessReason {
    if (_queueStatus != QueueConnectionStatus.stale) return null;
    return _isOnline
        ? StalenessReason.channelDrop
        : StalenessReason.deviceOffline;
  }

  /// Applies [change] and pins [_recordedAt] if it moved the card off live.
  ///
  /// Wrapping every mutation that can reach [_queueStatus] is what guarantees
  /// the timestamp is captured on the edge and only on the edge, without each
  /// caller having to remember to check.
  void _withQueueState(VoidCallback change) {
    final wasLive = _queueStatus == QueueConnectionStatus.live;
    setState(() {
      change();
      if (wasLive && _queueStatus != QueueConnectionStatus.live) {
        _recordedAt = DateTime.now();
      }
    });
  }

  /// TEST-ONLY. Simulates the channel dropping while the device stays online:
  /// the badge counts down for [_retryWindow], then the card settles into a
  /// channel-drop stale that offers the manual retry button.
  void _simulateChannelDrop() {
    _channelDropTimer?.cancel();
    _withQueueState(() => _dropPhase = _ChannelDropPhase.retrying);
    _channelDropTimer = Timer(_retryWindow, () {
      if (!mounted) return;
      _withQueueState(() => _dropPhase = _ChannelDropPhase.dropped);
    });
  }

  /// The card's "إعادة المحاولة الآن". With no channel to reconnect to, the
  /// honest thing a retry can do is drop the simulation and show whatever the
  /// device's real connectivity says.
  void _handleQueueRetry() {
    _channelDropTimer?.cancel();
    _channelDropTimer = null;
    _withQueueState(() => _dropPhase = _ChannelDropPhase.none);
  }

  @override
  void initState() {
    super.initState();
    _isOnline = widget.connectivityService.isOnline;
    _onlineSub = widget.connectivityService.isOnlineStream.listen((online) {
      final wasOnline = _wasOnline;
      _wasOnline = online;
      // Only a genuine reconnect bumps the epoch. Going *offline* refreshes
      // nothing — there is nothing to fetch — and the very first emission has
      // no predecessor to be a transition from. The card below still has to
      // repaint either way, so the setState itself is unconditional.
      final reconnected = wasOnline == false && online;
      _withQueueState(() {
        _isOnline = online;
        if (reconnected) _refreshEpoch++;
      });
    });
  }

  @override
  void dispose() {
    _onlineSub?.cancel();
    _channelDropTimer?.cancel();
    super.dispose();
  }

  /// Pull-to-refresh.
  ///
  /// Re-checks connectivity first so the gesture also freshens the offline
  /// strip above the tabs — someone who pulls because the screen looks wrong
  /// usually means "re-check everything", and the strip is the part of that
  /// they can actually see change.
  Future<void> _handleRefresh() async {
    await widget.connectivityService.checkNow();
    if (!mounted) return;

    // A pull while genuinely offline must not reroll the carousel. It used to,
    // which meant airplane mode still dealt a different set of doctors on
    // every pull — the screen claiming to have fetched something over a
    // connection that did not exist. Returning here lets RefreshIndicator play
    // its normal dismiss animation, so the gesture still feels answered, while
    // nothing downstream is invalidated.
    //
    // Deliberately silent: GlobalOfflineStrip is on screen throughout and
    // already says this. A snackbar would be the same fact twice.
    if (!widget.connectivityService.isOnline) return;

    await Future.delayed(_placeholderRefreshDelay);
    if (!mounted) return;
    setState(() => _refreshEpoch++);
  }

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
          // Wraps only the scrolling half, so the spinner comes down over the
          // content and leaves the top bar where it is.
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              // Home's content is short enough to fit on a tall phone, and a
              // scroll view with nothing to scroll refuses the gesture outright.
              // This is what makes the pull available regardless of how much is
              // on screen.
              physics: const AlwaysScrollableScrollPhysics(),
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
                  // booking flow — so neither placeholder here is reading real
                  // data. This becomes a real conditional (HomeEmptyStateCard
                  // when there is no active booking vs. QueueStatusCard when
                  // there is) once the Booking tab and its backing data land.
                  //
                  // **Currently active placeholder: QueueStatusCard**, mounted
                  // unconditionally so its three connection states can be
                  // exercised on a real handset. `home_empty_state_card.dart`
                  // stays built and ready, just unreferenced from here in the
                  // meantime — the two swapped roles, and swapping them back is
                  // this one widget and its import.
                  //
                  // The doctor, location and queue numbers below mirror
                  // `design_reference/ConnectivityArchitecture.jsx`; positions
                  // 7 and 12 reproduce that reference's 7/12 progress bar and
                  // its five-patients-ahead headline at the same time.
                  QueueStatusCard(
                    doctorName: 'د. محمد طاهر',
                    doctorLocation: 'عيادة النخيل · الطابق الثاني',
                    doctorAvatarUrl: null,
                    patientsAhead: 5,
                    avgConsultMinutes: 5,
                    doctorQueuePosition: 7,
                    patientQueuePosition: 12,
                    connectionStatus: _queueStatus,
                    stalenessReason: _stalenessReason,
                    recordedAt: _recordedAt,
                    // Inert, like every other CTA on this screen: there is no
                    // detail sheet to open. The print is the seam.
                    onTap: () =>
                        debugPrint('TODO: open the queue detail sheet'),
                    onRetry: _handleQueueRetry,
                  ),
                  // TEMPORARY / TEST-ONLY — delete with the block in the State.
                  const SizedBox(height: AuroraSpacing.sm),
                  _ChannelDropTestButton(onPressed: _simulateChannelDrop),
                  const SizedBox(height: AuroraSpacing.xxl),
                  // The chips now drive the carousel below. The chip row still
                  // owns its own highlight; this callback only reports the key,
                  // which is why the two are not fighting over one source of
                  // truth. "all" is not reported as a specialty — the carousel
                  // reads it as "no filter".
                  HomeSpecialtyChips(
                    onSpecialtySelected: (key) =>
                        setState(() => _selectedSpecialtyKey = key),
                  ),
                  const SizedBox(height: AuroraSpacing.xxl),
                  // The filter is real; the doctors are not. This section draws
                  // placeholder people from `lib/dev/mock_doctors.dart` because
                  // `public.doctors` is still empty and nothing queries it — the
                  // list is replaced wholesale once a real query exists. `onBook`
                  // stays unwired: there is no booking flow for it to open.
                  HomeSpecialtyDoctors(
                    selectedSpecialtyKey: _selectedSpecialtyKey,
                    refreshEpoch: _refreshEpoch,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// TEMPORARY / TEST-ONLY.
///
/// Forces the queue card through the one connection state real device
/// connectivity cannot produce — a channel drop while the device is still
/// online. Deliberately plain and quiet: a text button, not an Aurora surface,
/// so nobody mistakes it for shipped UI. Delete it, [_ChannelDropPhase], and
/// the marked block in [_HomeTabState] once a real realtime channel exists for
/// the doctor queue.
class _ChannelDropTestButton extends StatelessWidget {
  const _ChannelDropTestButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.bolt_rounded, size: 16),
        label: Text(
          'اختبار: انقطاع القناة',
          style: AuroraText.body(
            size: AuroraFontSize.caption,
            weight: FontWeight.w700,
            color: context.aurora.muted,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: context.aurora.muted,
          padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.sm),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
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
    final palette = context.aurora;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
      decoration: BoxDecoration(
        color: palette.tonal,
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
          Icon(Icons.search_rounded, size: 20, color: palette.secondary),
          const SizedBox(width: AuroraSpacing.sm),
          Expanded(
            child: Text(
              'ابحث عن طبيب أو تخصص',
              textAlign: TextAlign.start,
              style: AuroraText.body(
                size: 14,
                weight: FontWeight.w500,
                color: palette.secondary,
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
    final palette = context.aurora;

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
            decoration: BoxDecoration(
              color: palette.tonal,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 22,
              color: palette.ink,
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
                border: Border.all(color: palette.tonal, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
