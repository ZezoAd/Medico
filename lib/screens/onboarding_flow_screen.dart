/// The post-signup onboarding flow — three steps and a success screen behind
/// one persistent header.
library;

import 'package:flutter/material.dart';

import '../models/onboarding_data.dart';
import '../services/notification_service.dart';
import '../services/onboarding_service.dart';
import '../theme/aurora_tokens.dart';
import 'home_screen.dart';
import 'onboarding_completion_screen.dart';
import 'onboarding_step1_basics.dart';
import 'onboarding_step2_city.dart';
import 'onboarding_step3_notifications.dart';
import 'onboarding_step_header.dart';

/// Owns the step index, the collected [OnboardingData], and the page
/// controller. The header lives outside the page area so it stays put while
/// the steps slide beneath it.
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  static const int _completionStep = 3;

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final _pageController = PageController();
  final _onboardingService = const OnboardingService();
  final _notifications = const NotificationService();

  OnboardingData _data = const OnboardingData();
  int _step = 0;

  /// Held back a beat after landing on the last page so the completion
  /// sequence starts once the slide has settled, not underneath it.
  bool _playCompletion = false;

  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    if (step == _step) return;

    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: AuroraMotion.page,
      curve: AuroraMotion.easeOut,
    );

    if (step == OnboardingFlowScreen._completionStep) {
      _finish();
    } else if (_playCompletion) {
      setState(() => _playCompletion = false);
    }
  }

  Future<void> _finish() async {
    // The animation and the write are independent: the sequence starts on
    // its own timer and never waits on the network.
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _playCompletion = true);
    });

    if (_saving) return;
    _saving = true;
    await _onboardingService.saveOnboarding(_data);
    _saving = false;
  }

  /// Asks once and advances only on a grant. A denial keeps the patient on
  /// step 3, which then offers Settings instead of re-prompting — the OS will
  /// not raise a dismissed prompt again, so asking twice would be a dead
  /// button. "ليس الآن" remains the way forward either way, so this is never
  /// a dead end.
  Future<bool> _enableNotifications() async {
    final granted = await _notifications.requestPermission();
    if (!granted) return false;

    await _notifications.registerDeviceToken();
    if (mounted) _goTo(OnboardingFlowScreen._completionStep);
    return true;
  }

  void _openHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Widget _softCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }

  /// Non-active pages sit back at 55% so the active step reads as the one
  /// in focus during the slide.
  Widget _page(int index, Widget child) {
    return AnimatedOpacity(
      opacity: _step == index ? 1 : 0.55,
      duration: AuroraMotion.page,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AuroraColors.background,
        body: Stack(
          children: [
            // Two soft circles bleeding off the edges, echoing the
            // translucent blobs on the auth backdrop. Tonal rather than white
            // because this canvas is already near-white — white would be
            // invisible here.
            Positioned(
              top: -70,
              right: -60,
              child: _softCircle(220, AuroraColors.tonal, 0.55),
            ),
            Positioned(
              bottom: -50,
              left: -70,
              child: _softCircle(190, AuroraColors.tonalBlue, 0.5),
            ),
            SafeArea(
              child: Column(
                children: [
                  OnboardingStepHeader(
                    step: _step.clamp(0, 2),
                    visible: _step < OnboardingFlowScreen._completionStep,
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      // Navigation is button-driven only. The steps are a
                      // sequence with a required field in the middle, not a
                      // carousel to swipe through.
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _page(
                          0,
                          OnboardingStep1Basics(
                            data: _data,
                            onChanged: (data) => setState(() => _data = data),
                            onContinue: () => _goTo(1),
                            onSkip: () => _goTo(1),
                          ),
                        ),
                        _page(
                          1,
                          OnboardingStep2City(
                            data: _data,
                            onChanged: (data) => setState(() => _data = data),
                            onContinue: () => _goTo(2),
                          ),
                        ),
                        _page(
                          2,
                          OnboardingStep3Notifications(
                            onEnable: _enableNotifications,
                            onMaybeLater: () =>
                                _goTo(OnboardingFlowScreen._completionStep),
                          ),
                        ),
                        _page(
                          OnboardingFlowScreen._completionStep,
                          OnboardingCompletionScreen(
                            show: _playCompletion,
                            onEnter: _openHome,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
