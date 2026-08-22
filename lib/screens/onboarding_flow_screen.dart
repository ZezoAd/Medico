/// The post-signup onboarding flow — three steps and a success screen behind
/// one persistent header.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_data.dart';

import '../services/notification_service.dart';
import '../services/onboarding_sync_service.dart';
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
  const OnboardingFlowScreen({
    super.key,
    this.onFinished,
    this.initialStep = 0,
    this.initialData = const OnboardingData(),
  });

  /// Invoked once the answers are staged locally and the server write has
  /// been started. [AuthGate] passes a re-resolve here so it stays mounted
  /// and keeps owning the connectivity retry; the dev harness leaves it null
  /// and gets a plain push to Home instead.
  final VoidCallback? onFinished;

  /// Where to pick up. Non-zero when a previous run was force-quit partway
  /// through; [AuthGate] reads it back off the device. Already clamped to a
  /// real page index by the service that loads it.
  final int initialStep;

  /// The answers that run had collected. Paired with [initialStep] — resuming
  /// at step 2 with an empty city field would be worse than not resuming.
  final OnboardingData initialData;

  static const int _completionStep = 3;

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final PageController _pageController;
  final _sync = const OnboardingSyncService();
  final _notifications = const NotificationService();

  late OnboardingData _data;
  late int _step;

  /// Held back a beat after landing on the last page so the completion
  /// sequence starts once the slide has settled, not underneath it.
  bool _playCompletion = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _data = widget.initialData;
    _pageController = PageController(initialPage: _step);

    // A resume that lands straight on Completion still has to play its
    // sequence — nothing slid into place to trigger it.
    if (_step == OnboardingFlowScreen._completionStep) _finish();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Fire-and-forget by design: a step transition must never wait on a disk
  /// write, and a failed write only costs a restart from the beginning.
  void _saveProgress(int step) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    unawaited(_sync.saveProgress(userId, step, _data));
  }

  void _goTo(int step) {
    if (step == _step) return;

    setState(() => _step = step);
    // Saved on every transition, backwards included: the record answers
    // "where are they", not "how far did they ever get", so a back press
    // followed by a force-quit must not resume ahead of where they stood.
    _saveProgress(step);
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

  void _finish() {
    // The celebration is local and immediate; nothing here waits on a server.
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _playCompletion = true);
    });
  }

  /// Asks once, then advances regardless of the answer. Grant, deny and
  /// "ليس الآن" all land on Completion — a permission answer decides whether
  /// a token is registered, never whether the person can finish.
  Future<void> _enableNotifications() async {
    final granted = await _notifications.requestPermission();
    if (granted) await _notifications.registerDeviceToken();
    if (mounted) _goTo(OnboardingFlowScreen._completionStep);
  }

  /// Offline-first finish: stage on-device, start the push, leave. The write
  /// is deliberately not awaited — a person who is offline must reach Home
  /// exactly as fast as one who is not, and the queued record plus the
  /// launch/connectivity retries are what get it to the server eventually.
  Future<void> _openHome() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _sync.savePending(userId, _data);
        // Handover point: the flow is over, so the in-progress breadcrumb has
        // nothing left to describe. Cleared only after the pending record is
        // safely written, so a kill between the two resumes at Completion
        // rather than losing the answers entirely.
        await _sync.clearProgress(userId);
        // Fire-and-forget: failure just leaves the record queued.
        unawaited(_sync.syncPending());
      }
    } catch (error, stack) {
      // Staging is best-effort by definition. Nothing here — not a missing
      // session, not an unwritable disk — may stand between the person and
      // Home, which is the entire point of the offline-first change.
      debugPrint('Onboarding staging skipped: $error\n$stack');
    }

    if (!mounted) return;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }
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

  /// System back. Steps 2 and 3 walk back a step; step 1 has nothing before it
  /// inside the flow, so the platform handles it and the app backgrounds as
  /// usual. Completion swallows it outright — the answers are already staged
  /// (possibly already on the server) by the time that screen appears, so
  /// there is no coherent state to return to.
  void _handleBack(bool didPop) {
    if (didPop) return;
    if (_step == 0 || _step == OnboardingFlowScreen._completionStep) return;
    _goTo(_step - 1);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Only step 1 lets the pop through to the platform.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) => _handleBack(didPop),
      child: Directionality(
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
      ),
    );
  }
}
