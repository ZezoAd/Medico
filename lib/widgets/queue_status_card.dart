import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// [retrying] didn't reconnect within its window. Numbers on the card are
  /// frozen as of [QueueStatusCard.recordedAt].
  stale,
}

/// Home screen's hero card: a patient's live position in a doctor's clinic
/// queue.
///
/// Presentation-only — [connectionStatus], [patientsAhead] and
/// [recordedAt] all come from whatever owns the queue's realtime channel.
/// This widget never talks to Supabase and never reads a clock to decide
/// what the offline numbers say.
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
    this.onRetry,
  });

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

  /// Manual retry action. Only ever shown while [connectionStatus] is
  /// [QueueConnectionStatus.stale].
  final VoidCallback? onRetry;

  @override
  State<QueueStatusCard> createState() => _QueueStatusCardState();
}

class _QueueStatusCardState extends State<QueueStatusCard>
    with TickerProviderStateMixin {
  static const _gradientColors = [
    AuroraColors.primary,
    AuroraColors.primaryMid,
    AuroraColors.primaryBlue,
  ];
  static const _gradientStops = [0.0, 0.55, 1.0];

  // Same hues, precomputed at 22% toward black rather than blended at
  // runtime — a soft light-mode glow reads as broken on a dark surface, so
  // dark mode needs its own flat darkened values, not a shader blend.
  static const _gradientColorsDark = [
    Color(0xFF17794F), // #1D9E75 scrimmed 22% toward black
    Color(0xFF1B6386), // #227FAF scrimmed 22% toward black
    Color(0xFF20729D), // #2A93C9 scrimmed 22% toward black
  ];

  static const _blobDurations = [
    Duration(seconds: 21),
    Duration(seconds: 26),
    Duration(seconds: 34),
  ];

  late final List<AnimationController> _blobControllers;
  late final AnimationController _pulseController;
  AnimationController? _retryRingController;

  bool _reducedMotion = false;
  QueueConnectionStatus? _previousStatus;

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
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion != _reducedMotion) {
      _reducedMotion = reducedMotion;
      _syncAnimations();
    }
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

    if (status == QueueConnectionStatus.retrying) {
      if (_previousStatus != QueueConnectionStatus.retrying) {
        _retryRingController?.dispose();
        _retryRingController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 10),
        )..forward();
      }
    } else {
      _retryRingController?.dispose();
      _retryRingController = null;
    }

    _previousStatus = status;
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
    // First build: dependencies (MediaQuery) are already available by the
    // time build runs, but animations start from _syncAnimations, which
    // only otherwise fires on change — so kick it once here too.
    if (_previousStatus == null) {
      _previousStatus = widget.connectionStatus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncAnimations();
      });
    }

    // main.dart's MaterialApp declares only a light ThemeData — no
    // darkTheme/themeMode exists yet for Theme.of(context) to reflect — so
    // this reads the OS setting directly rather than through Theme.
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isStale = widget.connectionStatus == QueueConnectionStatus.stale;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.08))
              : null,
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AuroraColors.primary.withValues(alpha: 0.28),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark ? _gradientColorsDark : _gradientColors,
                      stops: _gradientStops,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -30,
                child: _DriftingBlob(
                  controller: _blobControllers[0],
                  size: 180,
                  opacity: 0.10,
                  drift: const Offset(14, 10),
                  blurred: isStale,
                ),
              ),
              Positioned(
                bottom: -60,
                left: -50,
                child: _DriftingBlob(
                  controller: _blobControllers[1],
                  size: 220,
                  opacity: 0.08,
                  drift: const Offset(-12, 14),
                  blurred: isStale,
                ),
              ),
              Positioned(
                top: 60,
                left: -20,
                child: _DriftingBlob(
                  controller: _blobControllers[2],
                  size: 120,
                  opacity: 0.07,
                  drift: const Offset(10, -12),
                  blurred: isStale,
                ),
              ),
              if (isStale)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: _CardContent(
                    card: widget,
                    pulseController: _pulseController,
                    retryRingController: _retryRingController,
                  ),
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
      children: [
        Row(
          children: [
            _DoctorAvatar(url: card.doctorAvatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.doctorName,
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.doctorLocation,
                    style: GoogleFonts.tajawal(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ConnectionBadge(
              status: card.connectionStatus,
              pulseController: pulseController,
              retryRingController: retryRingController,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          toArabicDigits('${card.patientsAhead}'),
          style: GoogleFonts.tajawal(
            fontSize: 64,
            height: 1.0,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          patientsAheadPhrase(card.patientsAhead),
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 16),
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
            style: GoogleFonts.tajawal(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        if (isStale && card.onRetry != null) ...[
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: card.onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

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
      children: [
        Text(
          'سُجّلت هذه الأرقام الساعة ${formatArabicClock12(recordedAt)}',
          style: GoogleFonts.tajawal(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'دورك المتوقع نحو الساعة ${formatArabicClock12(turnTime)}',
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white.withValues(alpha: 0.22),
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null
          ? const Icon(Icons.person_rounded, color: Colors.white, size: 22)
          : null,
    );
  }
}

/// Badge showing the queue channel's realtime health.
///
/// Live: pulsing dot. Retrying: a ring that visibly counts down over its
/// 10-second window — the card itself stays at full color during this
/// phase, only the badge changes. Stale: a clock icon with explicit label,
/// since "آخر تحديث" (last updated) is accurate where a phrase like
/// "متوقف مؤقتاً" would wrongly imply the doctor's queue itself paused.
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
      QueueConnectionStatus.live => AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final scale = 0.85 + (pulseController.value * 0.3);
          final opacity = 0.55 + (pulseController.value * 0.45);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
      QueueConnectionStatus.retrying => SizedBox(
        width: 16,
        height: 16,
        child: retryRingController == null
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              )
            : AnimatedBuilder(
                animation: retryRingController!,
                builder: (context, _) {
                  return CircularProgressIndicator(
                    strokeWidth: 2,
                    value: 1 - retryRingController!.value,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  );
                },
              ),
      ),
      QueueConnectionStatus.stale => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              'آخر تحديث',
              style: GoogleFonts.tajawal(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    };
  }
}

/// A single translucent decorative circle drifting on an irregular path.
///
/// Stays a direct child of the outer [Stack] via [Positioned] — the
/// animation is nested *inside* that [Positioned], never wrapping it,
/// since [Stack] only reads positioning off its immediate children.
class _DriftingBlob extends StatelessWidget {
  const _DriftingBlob({
    required this.controller,
    required this.size,
    required this.opacity,
    required this.drift,
    required this.blurred,
  });

  final AnimationController controller;
  final double size;
  final double opacity;
  final Offset drift;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );

    final maybeBlurred = blurred
        ? ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: circle,
          )
        : circle;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(controller.value);
        return Transform.translate(
          offset: Offset(drift.dx * t, drift.dy * t),
          child: child,
        );
      },
      child: maybeBlurred,
    );
  }
}
