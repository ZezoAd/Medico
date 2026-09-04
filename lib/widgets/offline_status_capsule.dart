import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../theme/aurora_tokens.dart';

/// The device-level "you have no internet" card.
///
/// Deliberately *not* part of `queue_status_card.dart`. It states a fact about
/// the device; the card states something narrower — whether one particular
/// queue is still being tracked — and owns its own retry cycle. Collapsing the
/// two would mean either the card claiming to retry when there is no network
/// to retry over, or this flickering in sympathy with a channel drop that has
/// nothing to do with the device being offline.
///
/// **Floats above the bottom navigation bar**, as a `Positioned` overlay in
/// the shell's `Stack` — over the tab content, not beside it.
///
/// It is app-wide by construction: the bottom nav is one Scaffold-level
/// element shared by all four tabs, so unlike a per-tab header there is no
/// question of which tabs get it.
///
/// It used to be a sibling in a `Column`, taking its own reserved row so that
/// `Expanded` shrank the tab content to make space. That guaranteed nothing
/// overlapped, but it also meant a transient message permanently re-laid-out
/// the page under it, and read as a slab wedged between the content and the
/// nav bar rather than as something floating over them — the mini-player
/// arrangement it is modelled on. Overlaying trades the automatic guarantee
/// for that, and pays for it with [overlayClearance]: a scroll view adds that
/// much bottom padding *while the capsule is showing*, so its last item can
/// still be reached. See `home_tab.dart`.
///
/// The name is historical. It was literally a pill for one round; it is now a
/// rounded card. "Capsule" is kept as the informal name for a small
/// self-contained status element rather than as a claim about its geometry —
/// a third rename in three rounds would churn the file, the test suite, the
/// design reference and every call site to describe a corner radius.
///
/// It occupies **zero** vertical space when fully hidden, which is why its
/// margins live inside the transition rather than in the parent's padding: a
/// parent `Padding` would have to re-test [visible] to honour that,
/// duplicating the one piece of state this widget exists to own, and leaving a
/// permanent dead band above the nav bar if anyone forgot.
///
/// It reads the **platform** brightness directly rather than the app's theme —
/// see [_CapsulePalette].
class OfflineStatusCapsule extends StatefulWidget {
  const OfflineStatusCapsule({
    super.key,
    required this.phase,
    this.onRefresh,
    this.titleOverride,
    this.subtitleOverride,
  });

  /// Copy for a device that has been confirmed offline.
  static const String offlineTitle = 'لا يوجد اتصال بالإنترنت حالياً';
  static const String offlineSubtitle =
      'سيتم التحديث تلقائياً عند عودة الاتصال';

  /// Copy while a reported change is being re-verified — in *either*
  /// direction. It never claims which way the answer will go.
  static const String confirmingTitle = 'جارٍ التأكد من الاتصال…';
  static const String confirmingSubtitle = 'لحظة واحدة من فضلك';

  /// Side inset. The same gutter `home_tab.dart` gives its own content, so the
  /// card's edges line up with the cards above it.
  static const double sideMargin = AuroraSpacing.lg;

  /// Clearance above and below. Unlike the docked pill this replaced, the card
  /// is meant to read as floating free, so it keeps real air between itself
  /// and both the tab content above and the nav bar below.
  static const double verticalMargin = AuroraSpacing.md;

  /// Diameter of the refresh control, and therefore its tap target. 48 is the
  /// standard comfortable minimum; the visual circle and the hit area are the
  /// same object here, so the number cannot drift apart from what is actually
  /// tappable.
  static const double actionSize = 48;

  /// Diameter of the no-connection mark. Deliberately smaller than
  /// [actionSize]: nothing taps it, so the 48dp floor does not apply, and
  /// matching the button's size made two equally-weighted circles that read as
  /// two buttons — one of which did nothing when pressed.
  static const double infoSize = 40;

  /// Room a scroll view should leave at its bottom **while this is showing**,
  /// so its last item can still be scrolled clear of the overlay.
  ///
  /// The capsule floats over the tab content rather than displacing it, so
  /// nothing reclaims this space automatically — a scrollable has to leave it,
  /// and only while the capsule is up. Approximate on purpose: it is clearance,
  /// not a lock-step measurement, and the card grows past it at large text
  /// scales. Sized to the resting card (48 control + 12 padding either side)
  /// plus both margins.
  static const double overlayClearance = 96;

  /// Entrance: slower, decelerating, so a new fact arrives and settles.
  static const Duration enterDuration = Duration(milliseconds: 300);

  /// Exit: quicker. Losing a connection is news; regaining one is a
  /// resolution, and a resolution that lingers on screen reads as hesitation.
  static const Duration exitDuration = Duration(milliseconds: 220);

  // Test seams. Finding the card by key rather than by "the first Container
  // inside the widget" keeps the assertions from silently re-targeting an
  // icon button the day the tree gains another wrapper.
  static const Key cardKey = Key('offlineStatusCapsule.card');
  static const Key refreshKey = Key('offlineStatusCapsule.refresh');
  static const Key infoKey = Key('offlineStatusCapsule.info');

  /// The *committed* connection phase — never the raw instant bool.
  ///
  /// The card shows for both [ConnectivityPhase.confirmedOffline] and
  /// [ConnectivityPhase.confirming], and hides only once
  /// [ConnectivityPhase.confirmedOnline] actually commits. That is the point:
  /// it used to vanish the moment the platform reported a network, which was
  /// often before a thumb had reached the refresh button — and sometimes
  /// before the connection was real.
  final ConnectivityPhase phase;

  /// Whether the card is on screen at all.
  bool get visible => phase != ConnectivityPhase.confirmedOnline;

  /// Test seams. Production always uses the constants above; these exist so a
  /// layout test can prove the card has headroom for copy slightly longer than
  /// what ships, the same way the doctor-card tests pump a deliberately
  /// over-long name rather than trusting the fixture to stay long.
  final String? titleOverride;
  final String? subtitleOverride;

  /// One-shot "check again now".
  ///
  /// The same real mechanism the queue card's retry uses — a direct
  /// `ConnectivityService.checkNow()`, not a new retry loop of its own. Null
  /// renders the control visibly present but inert, matching the convention
  /// `QueueStatusCard.onRetry` established: a caller that forgets to wire it
  /// gets a visibly dead button rather than a silently missing one.
  final VoidCallback? onRefresh;

  @override
  State<OfflineStatusCapsule> createState() => _OfflineStatusCapsuleState();
}

class _OfflineStatusCapsuleState extends State<OfflineStatusCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: OfflineStatusCapsule.enterDuration,
      reverseDuration: OfflineStatusCapsule.exitDuration,
      value: widget.visible ? 1 : 0,
    );

    // Decelerate in, accelerate out. [AuroraMotion.easeOut] is the app's own
    // ease-out — sharper than Curves.easeOutCubic, which is why it is a token
    // rather than a preset — and carries the entrance so the card arrives and
    // settles. The reverse curve is the mirror: it lets go quickly, because
    // "you are back online" does not deserve a slow farewell.
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AuroraMotion.easeOut,
      reverseCurve: Curves.easeInCubic,
    );

    _fade = curved;
    // Rises into place from just below, and settles back down on the way out.
    // A fraction of its own height, not a fixed pixel offset, so the movement
    // stays proportional if the card's content ever grows a line.
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didUpdateWidget(covariant OfflineStatusCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const palette = _CapsulePalette.light;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Fully dismissed is the only state that reserves nothing. Slide and
        // fade are paint-time effects — they do not shrink the box — so the
        // zero-space contract is honoured here instead, by declining to build
        // the row at all once the exit has finished. The height therefore
        // returns in one step at the end of the exit rather than easing away,
        // which is invisible: opacity is already at zero by then.
        if (_controller.isDismissed) {
          return const SizedBox(width: double.infinity);
        }
        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(position: _slide, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OfflineStatusCapsule.sideMargin,
          vertical: OfflineStatusCapsule.verticalMargin,
        ),
        child: _CapsuleCard(
          palette: palette,
          onRefresh: widget.onRefresh,
          title:
              widget.titleOverride ??
              (widget.phase == ConnectivityPhase.confirming
                  ? OfflineStatusCapsule.confirmingTitle
                  : OfflineStatusCapsule.offlineTitle),
          subtitle:
              widget.subtitleOverride ??
              (widget.phase == ConnectivityPhase.confirming
                  ? OfflineStatusCapsule.confirmingSubtitle
                  : OfflineStatusCapsule.offlineSubtitle),
        ),
      ),
    );
  }
}

/// The capsule's own two palettes, resolved from the **platform** brightness.
///
/// Deliberately independent of `Theme.of` and of `context.aurora`: the app
/// ships a single light `ThemeData` and does not follow the system setting
/// yet, so an app-theme lookup here would report light on a dark handset. This
/// is the workaround `aurora_tokens.dart` documents for exactly this case.
///
/// Both sets are built from existing tokens rather than new hexes — the light
/// half from [AuroraColors]' base values, the dark half from its `*Dark`
/// counterparts — so this widget cannot drift away from the rest of the app's
/// colour.
class _CapsulePalette {
  const _CapsulePalette({
    required this.surface,
    required this.title,
    required this.subtitle,
    required this.actionFill,
    required this.actionIcon,
    required this.infoFill,
    required this.infoIcon,
    required this.shadow,
  });

  final Color surface;
  final Color title;
  final Color subtitle;
  final Color actionFill;
  final Color actionIcon;
  final Color infoFill;
  final Color infoIcon;
  final List<BoxShadow> shadow;

  /// One palette, deliberately, until the app itself has two.
  ///
  /// This used to resolve `MediaQuery.platformBrightnessOf` and carry its own
  /// dark set. That was correct in isolation and wrong on screen: the rest of
  /// the app ships a single light `ThemeData` and does not follow the system
  /// setting, so on a dark-mode handset the capsule turned near-black while
  /// every surface around it stayed white — it stopped reading as a card on
  /// the page and started reading as a slab dropped over it. Following the OS
  /// alone is only an improvement once the screens behind it do too; bring the
  /// dark set back at that point, not before.
  ///
  /// White card on the warm page background, the same arrangement
  /// `_ProfileBanner` and the doctor cards already use. This is the app's
  /// elevated-surface convention; the "never pure white" rule governs page
  /// backgrounds, not surfaces that sit above them.
  static const light = _CapsulePalette(
    surface: AuroraColors.surface,
    title: AuroraColors.ink,
    subtitle: AuroraColors.muted,
    // Actionable: brand tonal fill with the green that is tuned to sit on it.
    actionFill: AuroraColors.tonal,
    actionIcon: AuroraColors.accentOnTonal,
    // Informational: the same shape drained of colour, so the pair reads as
    // "one of these does something" without a label saying so.
    infoFill: Color(0x248FA5A0), // AuroraColors.muted at 14%
    infoIcon: AuroraColors.muted,
    shadow: AuroraShadows.floating,
  );

  // The dark counterpart that used to live here is gone, not disabled. It was
  // AuroraColors.tonalDark / inkDark / mutedDark / accentOnTonalDark with
  // AuroraShadows.cardDark — every value already exists in the token file, so
  // restoring it is a matter of writing the constant again once the app has a
  // dark theme of its own to sit inside.
}

class _CapsuleCard extends StatelessWidget {
  const _CapsuleCard({
    required this.palette,
    required this.onRefresh,
    required this.title,
    required this.subtitle,
  });

  final _CapsulePalette palette;
  final VoidCallback? onRefresh;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: OfflineStatusCapsule.cardKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.md,
        vertical: AuroraSpacing.md,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        // The app's elevated-card radius, as used by the Profile banner and
        // the settings card. Not [AuroraRadius.pill] — this is a card with two
        // lines of copy, and a full pill radius on a 72pt box bows the long
        // edges inward.
        borderRadius: BorderRadius.circular(AuroraRadius.lg),
        boxShadow: palette.shadow,
      ),
      // Under RTL a Row lays its first child on the visual *right*. The
      // no-connection mark leads on the right, the copy sits beside it, and
      // the refresh control lands on the far left — the reference's
      // arrangement, and the natural one for an Arabic reader: state the
      // condition first, offer the action last.
      child: Row(
        children: [
          _CircleBadge(
            key: OfflineStatusCapsule.infoKey,
            icon: Icons.wifi_off_rounded,
            fill: palette.infoFill,
            iconColor: palette.infoIcon,
          ),
          const SizedBox(width: AuroraSpacing.md),
          Expanded(
            // Neither line caps its lines or declares an overflow, so nothing
            // here can ever ellipsise: the copy wraps and the card grows
            // instead. Truncating a sentence that explains why the app is not
            // working is the one outcome worse than a taller card — and at
            // 360dp with accessibility text scaling, `bodyLg` on one line was
            // already losing the end of both strings.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  // Deliberately app-wide and tab-agnostic. The design
                  // reference's "الدور محفوظ بأمان" is queue-specific and
                  // cannot be used here: this card renders on Browse, Bookings
                  // and Profile too, where there is no turn being held — it
                  // would be a false statement, not merely an irrelevant one.
                  title,
                  style: AuroraText.body(
                    size: AuroraFontSize.body,
                    weight: FontWeight.w700,
                    color: palette.title,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // The reassurance the reference carries, rewritten to name
                  // no particular thing being restored.
                  subtitle,
                  style: AuroraText.body(
                    size: AuroraFontSize.micro,
                    weight: FontWeight.w500,
                    color: palette.subtitle,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AuroraSpacing.md),
          _RefreshButton(
            key: OfflineStatusCapsule.refreshKey,
            fill: palette.actionFill,
            iconColor: palette.actionIcon,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

/// The informational mark. A circle for symmetry with the refresh control, but
/// deliberately not an [InkWell] — there is nothing to tap, and a ripple would
/// promise otherwise.
class _CircleBadge extends StatelessWidget {
  const _CircleBadge({
    super.key,
    required this.icon,
    required this.fill,
    required this.iconColor,
  });

  final IconData icon;
  final Color fill;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: OfflineStatusCapsule.infoSize,
      height: OfflineStatusCapsule.infoSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}

/// The "check again now" control.
///
/// Its box *is* its tap target: [OfflineStatusCapsule.actionSize] square, at
/// the 48dp comfortable minimum, with the ripple clipped to the same circle
/// that is drawn. Nothing shrinks the hit area below what the eye sees.
class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    super.key,
    required this.fill,
    required this.iconColor,
    required this.onPressed,
  });

  final Color fill;
  final Color iconColor;

  /// Null renders it disabled rather than hidden — see
  /// [OfflineStatusCapsule.onRefresh].
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return SizedBox(
      width: OfflineStatusCapsule.actionSize,
      height: OfflineStatusCapsule.actionSize,
      child: Material(
        color: fill,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            Icons.refresh_rounded,
            size: 22,
            color: enabled ? iconColor : iconColor.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
