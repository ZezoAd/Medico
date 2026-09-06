import 'dart:async';

import 'package:flutter/material.dart';

import '../dev/mock_doctors.dart';
import '../services/connectivity_service.dart';
import '../theme/aurora_tokens.dart';
import '../widgets/home_empty_state_card.dart';
import '../widgets/home_previously_visited.dart';
import '../widgets/home_specialty_doctors.dart';
import '../widgets/home_specialty_chips.dart';
import '../widgets/offline_status_capsule.dart';

/// Home tab body.
///
/// The fixed top bar, then a pull-to-refresh scrolling column: the hero card,
/// the browse-by-specialty chips, the featured-doctors carousel, and the
/// previously-visited doctors. The rest of the Home spec (location pill,
/// upcoming booking) is still to come.
///
/// Everything below the top bar is presentation only. None of it has a backing
/// query — the doctors are hardcoded and every CTA is inert — because the rows
/// and flows they would talk to do not exist yet. The specialty filter is the
/// one exception: it is real, but it filters the hardcoded list. Each widget
/// carries its own note on what it is waiting for.
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.connectivityService,
    this.onOpenBookings,
  });

  /// Asks the shell to switch to the Bookings tab.
  ///
  /// A callback up to `HomeScreen` rather than a `Navigator.push` from here:
  /// the four sections are an [IndexedStack] behind one [NavigationBar], and
  /// the only thing that selects between them is `_HomeScreenState._tabIndex`.
  /// Pushing a route would stack a second Bookings *over* the nav bar, leaving
  /// the Home tab still lit underneath and the back gesture meaning "return to
  /// Home" instead of "leave the app".
  ///
  /// Nullable so the tab still builds standalone — a dev preview or a widget
  /// test that has no shell around it gets an inert CTA rather than a required
  /// argument it has nothing to satisfy.
  final VoidCallback? onOpenBookings;

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

  StreamSubscription<ConnectivityPhase>? _phaseSub;

  /// The device's *committed* connection phase, mirrored for `build`.
  ///
  /// Not the raw bool. A lift ride used to take the queue card straight from
  /// live to a device-offline stale and back, twice, in under a second.
  late ConnectivityPhase _phase;

  /// The last *committed* phase this tab saw, or null before the first one.
  ///
  /// Null, not a value, on purpose: the first committed phase only confirms
  /// what the device was already doing, and treating that as a reconnect would
  /// fire a refresh on a launch where nothing ever went wrong. Only settled
  /// phases are recorded here — [ConnectivityPhase.confirming] is a window,
  /// not a destination, so it never counts as the "previous" state.
  ConnectivityPhase? _lastCommitted;

  @override
  void initState() {
    super.initState();
    _phase = widget.connectivityService.phase;
    _phaseSub = widget.connectivityService.phaseStream.listen((phase) {
      final previous = _lastCommitted;
      if (phase != ConnectivityPhase.confirming) _lastCommitted = phase;
      // Only a *committed* reconnect bumps the epoch. This is the whole point
      // of moving off the raw stream: a flicker that reverted before
      // confirmation never reaches here at all, so it can no longer deal the
      // carousel a fresh hand for nothing. Going offline refreshes nothing
      // either — there is nothing to fetch — and the first committed phase has
      // no predecessor to be a transition from. The card still has to repaint
      // on every phase change, so the setState itself is unconditional.
      final reconnected =
          previous == ConnectivityPhase.confirmedOffline &&
          phase == ConnectivityPhase.confirmedOnline;
      setState(() {
        _phase = phase;
        if (reconnected) _refreshEpoch++;
      });
    });
  }

  @override
  void dispose() {
    _phaseSub?.cancel();
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
    // Deliberately silent: OfflineStatusCapsule is on screen throughout and
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
              // The offline capsule floats over this content rather than
              // displacing it, so the last card would sit under it. Room is
              // added only while it is actually showing — reserving it
              // permanently would leave a dead band at the foot of Home for a
              // message that is almost never up.
              //
              // **No horizontal padding here, deliberately.** The side gutter
              // is applied per child instead, so the two horizontal rows below
              // can run full-bleed: a card scrolling out of view travels to the
              // real screen edge rather than being cut at a fixed inset. When
              // every row stopped at the same 16pt, the hero card's edge, the
              // clipped chip and the clipped doctor card all lined up into one
              // continuous vertical boundary down each side of the page, which
              // read as a pair of thin lines framing the content. Anything that
              // should *not* bleed carries an AuroraSpacing.lg gutter of its
              // own — the same value `OfflineStatusCapsule.sideMargin` uses, so
              // the resting edges still line up.
              padding: EdgeInsets.fromLTRB(
                0,
                AuroraSpacing.sm,
                0,
                AuroraSpacing.lg +
                    (_phase == ConnectivityPhase.confirmedOnline
                        ? 0
                        : OfflineStatusCapsule.overlayClearance),
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
                  // that, just unreferenced from here in the meantime — see
                  // `dev/queue_status_card_preview.dart`, which is where its
                  // connection states are exercised.
                  //
                  // The CTA is inert for the same reason — no search flow yet.
                  // Gutter applied here rather than on the scroll view, so the
                  // rows below stay free to bleed.
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AuroraSpacing.lg),
                    child: HomeEmptyStateCard(),
                  ),
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
                  const SizedBox(height: AuroraSpacing.xxl),
                  // Same placeholder footing as the carousel above, and drawing
                  // from the same `lib/dev/mock_doctors.dart` list so both
                  // sections name the same people. There is no bookings table
                  // and no queue history, so *which* doctors were "visited" is
                  // invented too — see `mockPreviouslyVisited`.
                  //
                  // A card rather than a bleeding row, so it carries the page
                  // gutter itself. `onBook` stays unwired for the same reason
                  // the carousel's does; the footer CTA is the one live action
                  // on this screen, and it only switches tabs.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AuroraSpacing.lg,
                    ),
                    child: HomePreviouslyVisited(
                      visited: mockPreviouslyVisited,
                      onOpenHistory: widget.onOpenBookings,
                    ),
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
