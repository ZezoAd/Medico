import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../utils/arabic_formatting.dart';
import '../utils/wait_estimate.dart';

/// The realtime state of the doctor's queue channel this card is showing.
///
/// Owned and decided upstream by whatever watches the queue's realtime
/// channel (not built yet) — this card is presentation-only and never
/// derives this itself.
enum QueueConnectionStatus {
  /// Realtime channel connected, data is current.
  live,

  /// The channel dropped but the device still has internet — a reconnect
  /// attempt is in flight. Visually identical to [live] except for the
  /// badge, so a brief drop never reads as "something is wrong."
  retrying,

  /// [retrying] didn't reconnect within its window, or the device is offline
  /// outright. Numbers on the card are frozen as of
  /// [QueueStatusCard.recordedAt].
  stale,
}

/// Why the card is stale.
///
/// The card stays unaware of the wider connectivity picture, but it does
/// need this one bit: a channel drop is recoverable by retrying, and device
/// offline is not. Passing it explicitly is what keeps that decision out of
/// the shape of [QueueStatusCard.onRetry] — a null callback used to be the
/// only signal, which meant the distinction lived in an unwritten convention
/// the caller had to remember.
enum StalenessReason {
  /// The realtime channel dropped while the device still has internet.
  /// Retrying is meaningful, so the card offers the manual retry button.
  channelDrop,

  /// The device itself has no connection. There is nothing for a retry to
  /// accomplish, so the card offers no button — the global offline strip
  /// states the device fact once, on its own.
  deviceOffline,
}

/// Home screen's hero card: a patient's live position in a doctor's clinic
/// queue.
///
/// Presentation-only — [connectionStatus], [patientsAhead] and [recordedAt]
/// all come from whatever owns the queue's realtime channel. This widget
/// never talks to Supabase and never reads a clock to decide what the
/// offline numbers say.
///
/// The card is deliberately unaware of *why* it is stale, only *that* it is.
/// Device-level offline is a separate, global concern — see
/// `global_offline_strip.dart`.
class QueueStatusCard extends StatefulWidget {
  const QueueStatusCard({
    super.key,
    required this.doctorName,
    required this.doctorLocation,
    required this.patientsAhead,
    required this.avgConsultMinutes,
    required this.doctorQueuePosition,
    required this.patientQueuePosition,
    required this.connectionStatus,
    required this.recordedAt,
    required this.onTap,
    this.doctorAvatarUrl,
    this.stalenessReason,
    this.onRetry,
  }) : assert(
         connectionStatus != QueueConnectionStatus.stale ||
             stalenessReason != null,
         'A stale card must say why it is stale: pass stalenessReason '
         'alongside QueueConnectionStatus.stale.',
       );

  /// The doctor's display name.
  final String doctorName;

  /// Floor/room within the shared building, e.g. "الطابق الثاني، غرفة ٣" —
  /// never a street address, since doctors share buildings.
  final String doctorLocation;

  /// URL for the doctor's avatar. Falls back to a plain icon when null.
  final String? doctorAvatarUrl;

  /// How many patients are ahead of this one in today's queue.
  final int patientsAhead;

  /// متوسط مدة الكشف — the doctor's average consultation duration in
  /// minutes, set during onboarding. Not a model field yet, so this is
  /// taken as a plain int for now.
  final int avgConsultMinutes;

  /// The queue position the doctor is currently serving, e.g. 5.
  final int doctorQueuePosition;

  /// This patient's own position in today's queue, e.g. 9. Used together
  /// with [doctorQueuePosition] to draw the progress bar.
  final int patientQueuePosition;

  final QueueConnectionStatus connectionStatus;

  /// Why the card is stale — required whenever [connectionStatus] is
  /// [QueueConnectionStatus.stale], and meaningless otherwise (the card
  /// ignores it in every other state). This, not the presence of [onRetry],
  /// is what decides whether the manual retry button appears.
  final StalenessReason? stalenessReason;

  /// The moment the numbers on this card were last confirmed live.
  ///
  /// Must be captured once by the caller, at the moment [connectionStatus]
  /// leaves [QueueConnectionStatus.live] — and held steady on every
  /// subsequent rebuild while still offline. Passing a constantly-updating
  /// value here reintroduces the exact drift bug this contract exists to
  /// prevent: the stale-state estimate would silently creep forward on
  /// every rebuild instead of staying pinned to when data was last real.
  final DateTime recordedAt;

  /// Opens the detail sheet. The whole card is tappable; there is no
  /// separate Details/Reschedule button on the card face.
  final VoidCallback onTap;

  /// Manual retry action.
  ///
  /// Whether the retry button is *shown* is decided by [stalenessReason]
  /// alone; this only decides whether it is *enabled*. A null callback under
  /// [StalenessReason.channelDrop] renders the button disabled rather than
  /// hiding it, so a caller that forgets to wire the action gets a visibly
  /// dead button instead of a silently missing one.
  final VoidCallback? onRetry;

  @override
  State<QueueStatusCard> createState() => _QueueStatusCardState();
}

class _QueueStatusCardState extends State<QueueStatusCard>
    with TickerProviderStateMixin {
  /// How long the badge's countdown ring takes to drain. Purely a visual
  /// window — the actual reconnect is driven upstream; this only paces the
  /// ring so a drop reads as "working on it" rather than "frozen".
  static const _retryWindow = Duration(seconds: 10);

  // The dark gradient's stops used to be a private copy here. They are
  // [AuroraColors.gradientStartDark]/[gradientEndDark], reached through
  // [AuroraPalette.heroGradient], so this card and the empty state cannot
  // drift apart.

  // Each blob drifts on its own prime-ish period so the three never visibly
  // resynchronise into a pulse. Mirrors the reference's 26s/34s/21s.
  static const _blobDurations = [
    Duration(seconds: 26),
    Duration(seconds: 34),
    Duration(seconds: 21),
  ];

  late final List<AnimationController> _blobControllers;
  late final AnimationController _pulseController;
  AnimationController? _retryRingController;

  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _blobControllers = [
      for (final duration in _blobDurations)
        AnimationController(vsync: this, duration: duration),
    ];
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
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

  @override
  void didUpdateWidget(covariant QueueStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionStatus != widget.connectionStatus) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    final status = widget.connectionStatus;

    // Blobs drift in every state except stale, where they freeze mid-path.
    final shouldDrift =
        !_reducedMotion && status != QueueConnectionStatus.stale;
    for (final controller in _blobControllers) {
      if (shouldDrift) {
        if (!controller.isAnimating) controller.repeat(reverse: true);
      } else {
        controller.stop();
      }
    }

    final shouldPulse = !_reducedMotion && status == QueueConnectionStatus.live;
    if (shouldPulse) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }

    // Keyed off the controller's own existence rather than the previous
    // status, so a card that is *mounted* already in `retrying` still gets
    // its ring — and so a MediaQuery change mid-retry doesn't restart the
    // countdown from full.
    if (status == QueueConnectionStatus.retrying) {
      _retryRingController ??= AnimationController(
        vsync: this,
        duration: _retryWindow,
      )..forward();
    } else {
      _retryRingController?.dispose();
      _retryRingController = null;
    }
  }

  @override
  void dispose() {
    for (final controller in _blobControllers) {
      controller.dispose();
    }
    _pulseController.dispose();
    _retryRingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Was `MediaQuery.platformBrightnessOf`, back when main.dart declared no
    // darkTheme for `Theme.of` to reflect. The card's dark treatment now lives
    // in the palette — see [AuroraPalette.heroShadow], which carries the
    // reference's 0 18px 36px -20px rgba(6,45,36,0.55) in light and a plain
    // black drop in dark.
    final palette = context.aurora;
    final isStale = widget.connectionStatus == QueueConnectionStatus.stale;

    return GestureDetector(
      onTap: widget.onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AuroraRadius.xl),
          border: palette.heroBorder,
          boxShadow: palette.heroShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AuroraRadius.xl),
          // The decorative layers are Positioned/Positioned.fill so they
          // bleed to the card's true rounded edges; the content is the one
          // *non-positioned* child, which is what gives the Stack its height
          // (a Stack whose children are all positioned collapses, and blows
          // up outright under the unbounded height of a scroll view). It is
          // last in the list so it paints above the blobs and scrim, and it
          // carries the padding — so no padding is ever applied to the
          // layers underneath it.
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
                  frozen: isStale,
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
                  frozen: isStale,
                ),
              ),
              // The reference pins this one at 40% of the card's height.
              // Stretching the Positioned top-to-bottom and aligning inside
              // it resolves that against the real height without a
              // LayoutBuilder, which here would only ever see the unbounded
              // incoming constraints.
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
                      frozen: isStale,
                    ),
                  ),
                ),
              ),
              if (isStale)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        // rgba(10,20,17,0.30)
                        color: Color(0x4D0A1411),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AuroraSpacing.xl),
                child: _CardContent(
                  card: widget,
                  pulseController: _pulseController,
                  retryRingController: _retryRingController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.card,
    required this.pulseController,
    required this.retryRingController,
  });

  final QueueStatusCard card;
  final AnimationController pulseController;
  final AnimationController? retryRingController;

  @override
  Widget build(BuildContext context) {
    final isStale = card.connectionStatus == QueueConnectionStatus.stale;
    final progress = card.patientQueuePosition == 0
        ? 0.0
        : (card.doctorQueuePosition / card.patientQueuePosition).clamp(
            0.0,
            1.0,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _DoctorAvatar(url: card.doctorAvatarUrl),
            const SizedBox(width: AuroraSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.doctorName,
                    style: AuroraText.body(
                      size: AuroraFontSize.body,
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: AuroraSpacing.xs),
                      Expanded(
                        child: Text(
                          card.doctorLocation,
                          style: AuroraText.body(
                            size: AuroraFontSize.caption,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AuroraSpacing.sm),
            _ConnectionBadge(
              status: card.connectionStatus,
              pulseController: pulseController,
              retryRingController: retryRingController,
            ),
          ],
        ),
        const SizedBox(height: AuroraSpacing.xxl),
        _PatientsAheadHeadline(patientsAhead: card.patientsAhead),
        const SizedBox(height: AuroraSpacing.md),
        if (isStale)
          _StaleTimestampBlock(
            recordedAt: card.recordedAt,
            patientsAhead: card.patientsAhead,
            avgConsultMinutes: card.avgConsultMinutes,
          )
        else
          Text(
            waitRangeLabel(
              patientsAhead: card.patientsAhead,
              avgConsultMinutes: card.avgConsultMinutes,
            ),
            style: AuroraText.body(
              size: AuroraFontSize.body,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        const SizedBox(height: AuroraSpacing.xl),
        _QueueProgressBar(progress: progress),
        const SizedBox(height: AuroraSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('الطبيب الآن', style: _progressCaptionStyle),
            Text('دورك', style: _progressCaptionStyle),
          ],
        ),
        // Only offered when the channel dropped but the device is still
        // online. Device-offline staleness gets no button — a retry there
        // can only fail.
        if (isStale && card.stalenessReason == StalenessReason.channelDrop) ...[
          const SizedBox(height: AuroraSpacing.lg),
          _RetryButton(onPressed: card.onRetry),
        ],
      ],
    );
  }

  static final _progressCaptionStyle = AuroraText.body(
    size: AuroraFontSize.caption,
    weight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.80),
  );
}

/// The hero count.
///
/// The numeral is typeset separately from the noun so 1 and 2 — which carry
/// their count inside the word and take no numeral at all — render as the
/// word alone, rather than as a hero digit sitting next to a phrase that
/// already says the same number.
class _PatientsAheadHeadline extends StatelessWidget {
  const _PatientsAheadHeadline({required this.patientsAhead});

  final int patientsAhead;

  @override
  Widget build(BuildContext context) {
    final parts = patientsAheadParts(patientsAhead);

    if (parts.numeral == null) {
      return Text(
        parts.noun,
        style: AuroraText.body(
          size: AuroraFontSize.h2,
          weight: FontWeight.w800,
          color: Colors.white,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          parts.numeral!,
          style: AuroraText.body(
            size: AuroraFontSize.hero,
            weight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(width: AuroraSpacing.md),
        Flexible(
          child: Text(
            parts.noun,
            style: AuroraText.body(
              size: AuroraFontSize.h3,
              weight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _QueueProgressBar extends StatelessWidget {
  const _QueueProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuroraRadius.pill),
      child: Stack(
        children: [
          Container(height: 8, color: Colors.white.withValues(alpha: 0.24)),
          Positioned.fill(
            child: AnimatedFractionallySizedBox(
              duration: AuroraMotion.standard,
              curve: AuroraMotion.easeOut,
              widthFactor: progress,
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AuroraRadius.pill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onPressed});

  /// Null renders the button disabled — visibility is [StalenessReason]'s
  /// call, not this callback's.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.refresh_rounded, size: 14),
        label: Text(
          'إعادة المحاولة الآن',
          style: AuroraText.body(
            size: AuroraFontSize.caption,
            weight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: Colors.white.withValues(alpha: 0.16),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuroraRadius.sm),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.26)),
          ),
        ),
      ),
    );
  }
}

/// The frozen state's two-line absolute-time display: when the numbers were
/// true, then what they implied — both computed off the pinned
/// [recordedAt], never off `now`.
class _StaleTimestampBlock extends StatelessWidget {
  const _StaleTimestampBlock({
    required this.recordedAt,
    required this.patientsAhead,
    required this.avgConsultMinutes,
  });

  final DateTime recordedAt;
  final int patientsAhead;
  final int avgConsultMinutes;

  @override
  Widget build(BuildContext context) {
    final turnTime = estimatedTurnTime(
      recordedAt: recordedAt,
      patientsAhead: patientsAhead,
      avgConsultMinutes: avgConsultMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'سُجّلت هذه الأرقام الساعة ${formatArabicClock12(recordedAt)}',
          style: AuroraText.body(
            size: AuroraFontSize.caption,
            weight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: AuroraSpacing.xs),
        Text(
          'دورك المتوقع نحو الساعة ${formatArabicClock12(turnTime)}',
          style: AuroraText.body(
            size: AuroraFontSize.h3,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AuroraRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        image: url != null
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
      ),
      child: url == null
          ? const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 20,
            )
          : null,
    );
  }
}

/// Badge showing the queue channel's realtime health.
///
/// Live: pulsing dot. Retrying: a ring that visibly drains over its
/// 10-second window — the card itself stays at full colour during this
/// phase, only the badge changes, so a brief drop never reads as an outage.
/// Stale: a clock icon with an explicit label, since "آخر تحديث" (last
/// updated) points at the *data* — a phrase like "متوقف مؤقتاً" would
/// wrongly imply the doctor's queue itself had paused.
class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({
    required this.status,
    required this.pulseController,
    required this.retryRingController,
  });

  final QueueConnectionStatus status;
  final AnimationController pulseController;
  final AnimationController? retryRingController;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      QueueConnectionStatus.live => _BadgeShell(
        fill: 0.18,
        stroke: 0.28,
        label: 'مباشر',
        leading: _PulsingDot(controller: pulseController),
      ),
      QueueConnectionStatus.retrying => _BadgeShell(
        fill: 0.16,
        stroke: 0.26,
        label: 'يعيد الاتصال',
        leading: _RetryRing(controller: retryRingController),
      ),
      QueueConnectionStatus.stale => const _BadgeShell(
        fill: 0.14,
        stroke: 0.22,
        label: 'آخر تحديث',
        leading: Icon(Icons.access_time_rounded, size: 12, color: Colors.white),
      ),
    };
  }
}

class _BadgeShell extends StatelessWidget {
  const _BadgeShell({
    required this.fill,
    required this.stroke,
    required this.label,
    required this.leading,
  });

  final double fill;
  final double stroke;
  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.md,
        vertical: AuroraSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: fill),
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: stroke)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: AuroraSpacing.sm),
          Text(
            label,
            style: AuroraText.body(
              size: AuroraFontSize.micro,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The solid dot with the expanding halo behind it — the reference's
/// `animate-ping`. The dot itself never moves; only the halo scales and
/// fades, so the indicator stays legible at every point in the cycle.
class _PulsingDot extends StatelessWidget {
  const _PulsingDot({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    const dot = SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      ),
    );

    return SizedBox(
      width: 8,
      height: 8,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final t = Curves.easeOut.transform(controller.value);
              return Transform.scale(
                scale: 1 + (t * 1.4),
                child: Opacity(opacity: 0.75 * (1 - t), child: child),
              );
            },
            child: dot,
          ),
          dot,
        ],
      ),
    );
  }
}

/// The countdown ring. Drains clockwise from full to empty across the retry
/// window; falls back to a full static ring if no controller exists yet.
class _RetryRing extends StatelessWidget {
  const _RetryRing({required this.controller});

  final AnimationController? controller;

  @override
  Widget build(BuildContext context) {
    final ring = controller;
    return SizedBox(
      width: 16,
      height: 16,
      child: ring == null
          ? _ringOf(1)
          : AnimatedBuilder(
              animation: ring,
              builder: (context, _) => _ringOf(1 - ring.value),
            ),
    );
  }

  Widget _ringOf(double value) => CircularProgressIndicator(
    value: value,
    strokeWidth: 2.5,
    strokeCap: StrokeCap.round,
    backgroundColor: Colors.white.withValues(alpha: 0.28),
    valueColor: const AlwaysStoppedAnimation(Colors.white),
  );
}

/// A single translucent decorative circle drifting on an irregular path.
///
/// Stays a direct child of the outer [Stack] via [Positioned] — the
/// animation is nested *inside* that [Positioned], never wrapping it,
/// since [Stack] only reads positioning off its immediate children.
///
/// When [frozen] it stops mid-path and softens, so the card's whole
/// decorative layer visibly settles rather than snapping to a pose.
class _DriftingBlob extends StatelessWidget {
  const _DriftingBlob({
    required this.controller,
    required this.size,
    required this.opacity,
    required this.drift,
    required this.frozen,
  });

  final AnimationController controller;
  final double size;
  final double opacity;
  final Offset drift;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    Widget blob = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );

    if (frozen) {
      blob = Opacity(
        opacity: 0.7,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: blob,
        ),
      );
    }

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
