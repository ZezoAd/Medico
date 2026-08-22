/// Onboarding step 3 — notification opt-in.
library;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/aurora_tokens.dart';
import '../widgets/aurora_buttons.dart';

/// Screen height at or above which the column is laid out without a scroll
/// view. Below it the same content scrolls instead — a safety net for very
/// short devices and large system font scales, not the normal case.
const double _nonScrollingMinHeight = 640;

/// The three things a notification will actually be about. Deliberately terse
/// — they are a reassurance strip, not a feature list.
const _chips = <(IconData, String)>[
  (Icons.timer_outlined, 'اقتراب دورك'),
  (Icons.verified_outlined, 'تأكيد الحجز'),
  (Icons.pause_circle_outline, 'تغييرات الطبيب'),
];

class OnboardingStep3Notifications extends StatefulWidget {
  const OnboardingStep3Notifications({
    super.key,
    required this.onEnable,
    required this.onMaybeLater,
  });

  /// Raises the real OS permission prompt once and reports whether it was
  /// granted. Advancing on a grant is the caller's job; a denial keeps the
  /// patient here so the recovery path can be offered.
  final Future<bool> Function() onEnable;

  /// Proceeds *without* asking. That is the point: the OS allows one
  /// automatic prompt, so someone who is not ready now keeps it for a moment
  /// when the value is obvious, rather than spending it on a reflexive
  /// decline.
  final VoidCallback onMaybeLater;

  @override
  State<OnboardingStep3Notifications> createState() =>
      _OnboardingStep3NotificationsState();
}

class _OnboardingStep3NotificationsState
    extends State<OnboardingStep3Notifications>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  late final Animation<double> _ring;

  /// Set once the OS prompt comes back denied. From then on the CTA offers
  /// Settings instead of asking again — a dismissed prompt cannot be raised a
  /// second time, so re-offering it would be a button that does nothing.
  bool _denied = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // A single gentle swing, decaying — enough to draw the eye to the glyph
    // without turning into an alert.
    _ring = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ringController.forward();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (_requesting || _denied) return;
    setState(() => _requesting = true);
    final granted = await widget.onEnable();
    if (!mounted) return;
    setState(() {
      _requesting = false;
      _denied = !granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 36),
        Center(
          child: AnimatedBuilder(
            animation: _ring,
            builder: (context, child) => Transform.rotate(
              // Pivot at the bell's crown rather than its centre, so it swings
              // like a bell instead of spinning like a dial.
              alignment: Alignment.topCenter,
              angle: _ring.value * 3.1415926535 / 180,
              child: child,
            ),
            child: const _GradientBell(),
          ),
        ),
        const SizedBox(height: AuroraSpacing.xxl),
        Text(
          'ابقَ على اطلاع',
          style: AuroraText.display(size: AuroraFontSize.h1, height: 1.3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AuroraSpacing.md),
        Text(
          'ننبّهك عند اقتراب دورك أو أي تغيير مهم — ويمكنك تعديل ذلك لاحقاً من الإعدادات.',
          style: AuroraText.body(
            size: AuroraFontSize.body,
            color: AuroraColors.secondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AuroraSpacing.xl),
        const _ChipRow(),
        if (_denied) ...[
          const SizedBox(height: AuroraSpacing.xl),
          Text(
            'لم يتم تفعيل الإشعارات. يمكنك السماح بها من إعدادات التطبيق.',
            style: AuroraText.body(
              size: AuroraFontSize.caption,
              color: AuroraColors.secondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuroraPrimaryButton(
          label: _denied ? 'افتح الإعدادات' : 'تفعيل الإشعارات',
          icon: _denied
              ? Icons.settings_outlined
              : Icons.notifications_active_outlined,
          onTap: _requesting
              ? null
              : _denied
              ? openAppSettings
              : _request,
        ),
        const SizedBox(height: 10),
        AuroraSecondaryButton(label: 'ليس الآن', onTap: widget.onMaybeLater),
        const SizedBox(height: AuroraSpacing.xl),
      ],
    );

    final tall = MediaQuery.sizeOf(context).height >= _nonScrollingMinHeight;

    if (tall) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [content, const Spacer(), footer],
        ),
      );
    }

    // Short screen: same ladder, but the flexible gap becomes a fixed one so
    // the column can live inside a scroll view.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          const SizedBox(height: AuroraSpacing.xxl),
          footer,
        ],
      ),
    );
  }
}

/// 96dp gradient disc with a white bell, matching the stepper nodes.
class _GradientBell extends StatelessWidget {
  const _GradientBell();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AuroraGradients.aurora,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.notifications_none,
        size: 44,
        color: Colors.white,
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AuroraSpacing.sm,
      runSpacing: AuroraSpacing.sm,
      children: [
        for (final (icon, label) in _chips) _Chip(icon: icon, label: label),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.md,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AuroraColors.divider),
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AuroraColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AuroraText.body(
              size: 12,
              weight: FontWeight.w600,
              color: AuroraColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
