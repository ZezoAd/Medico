/// The onboarding success screen.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import '../widgets/aurora_buttons.dart';

/// A soft blue that only appears among the decorative blobs here.
const _blobBlue = Color(0xFFE4F0F7);

/// Plays a single choreographed sequence once [show] turns true: the badge
/// springs in, the checkmark draws itself, then the copy and the CTA fade up
/// behind it. One controller drives all four so the beats can never drift
/// apart.
class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({
    super.key,
    required this.show,
    required this.onEnter,
  });

  final bool show;
  final VoidCallback onEnter;

  @override
  State<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _badgeScale;
  late final Animation<double> _checkDraw;
  late final Animation<double> _textFade;
  late final Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();
    // 1250ms is the full sequence: the CTA's 750ms delay plus its own 500ms
    // fade. Every interval below is a slice of that one timeline.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );

    _badgeScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.52, curve: AuroraMotion.spring),
    );
    _checkDraw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.72, curve: AuroraMotion.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 0.92, curve: Curves.easeOut),
    );
    _buttonFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant OnboardingCompletionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    } else if (!widget.show && oldWidget.show) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Decorative blobs bleeding off the edges. Physical left/right, not
        // directional — this is a symmetric ambient composition, not content
        // that should mirror.
        const Positioned(
          top: 40,
          right: -30,
          child: _Blob(size: 140, color: AuroraColors.tonal, opacity: 0.7),
        ),
        const Positioned(
          top: 90,
          left: -20,
          child: _Blob(size: 100, color: _blobBlue, opacity: 0.7),
        ),
        const Positioned(
          bottom: 60,
          left: -30,
          child: _Blob(size: 180, color: AuroraColors.tonal, opacity: 0.5),
        ),
        const Positioned(
          bottom: 30,
          right: -20,
          child: _Blob(size: 120, color: _blobBlue, opacity: 0.5),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  width: 128,
                  height: 128,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AuroraGradients.aurora,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x591D9E75), // rgba(29,158,117,0.35)
                        offset: Offset(0, 12),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: AnimatedBuilder(
                      animation: _checkDraw,
                      builder: (context, _) => CustomPaint(
                        painter: _CheckmarkPainter(progress: _checkDraw.value),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AuroraSpacing.xxxl),
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    // 10px at a 26px type size ≈ 0.09 of the block's height.
                    begin: const Offset(0, 0.09),
                    end: Offset.zero,
                  ).animate(_textFade),
                  child: Column(
                    children: [
                      Text(
                        'أنت جاهز الآن!',
                        style: AuroraText.display(
                          size: AuroraFontSize.h1,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AuroraSpacing.md),
                      Text(
                        'ملفك الشخصي جاهز — رحلة العناية بصحتك تبدأ من هنا.',
                        style: AuroraText.body(
                          size: AuroraFontSize.body,
                          color: AuroraColors.secondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _buttonFade,
                child: AuroraPrimaryButton(
                  label: 'الانتقال إلى الصفحة الرئيسية',
                  onTap: widget.onEnter,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

/// Draws the checkmark progressively, the Flutter equivalent of animating an
/// SVG `stroke-dashoffset`: the full path is measured once, then only the
/// leading [progress] fraction of it is extracted and stroked.
class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Coordinates come straight from the design's 56x56 viewBox and are
    // scaled to whatever this actually gets laid out at.
    final scale = size.width / 56;
    final path = Path()
      ..moveTo(14 * scale, 29 * scale)
      ..lineTo(23 * scale, 37 * scale)
      ..lineTo(42 * scale, 16 * scale);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (progress >= 1) {
      canvas.drawPath(path, paint);
      return;
    }

    for (final ui.PathMetric metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
