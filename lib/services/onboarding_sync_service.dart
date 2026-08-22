import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_data.dart';

/// Where someone had got to in an onboarding run that was never finished.
///
/// Distinct from the pending-sync record in every way that matters: that one
/// means "done, the server just has not heard yet", this one means "not done".
/// They are never both meaningful for the same user at the same time.
class OnboardingProgress {
  const OnboardingProgress({required this.step, required this.data});

  /// The page index they had reached. Clamped on read — a corrupt value must
  /// not be able to index the `PageView` out of range.
  final int step;

  final OnboardingData data;
}

/// Offline-first persistence for the single onboarding write.
///
/// Deliberately not a general sync framework: it queues exactly one record,
/// for one user, for one table. Finishing onboarding must never depend on
/// connectivity, so the answers are written to the device first and pushed to
/// Supabase whenever that next becomes possible — on the next launch, or the
/// moment the radio comes back.
///
/// The local record is a *staging* copy, never a second source of truth: the
/// instant the server accepts the write it is deleted, and
/// `profiles.onboarding_completed_at` is authoritative again.
///
/// It also holds the mid-flow progress record — same storage, same per-user
/// keying, but answering the opposite question. See [OnboardingProgress].
class OnboardingSyncService {
  const OnboardingSyncService();

  static const _prefix = 'onboarding_pending_';
  static const _progressPrefix = 'onboarding_progress_';

  /// The highest page index that can be resumed to. Anything read back above
  /// this is a corrupt record, not a step.
  static const _maxStep = 3;

  /// Keyed per user so signing into a different account on the same device
  /// can never inherit someone else's queued record.
  String _key(String userId) => '$_prefix$userId';

  String _progressKey(String userId) => '$_progressPrefix$userId';

  /// Stores the answers locally and marks them unsynced. Called before the
  /// network is even attempted, so a crash or a kill between here and the
  /// server accepting still leaves the flow recoverable.
  Future<void> savePending(String userId, OnboardingData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId),
        jsonEncode({
          'gender': data.gender?.text,
          'birth_year': data.birthYear,
          'city': data.city?.trim(),
          // Stamped on the device at the moment the person finished, not when
          // the server eventually hears about it — otherwise a week offline
          // would backdate to the sync, not the act.
          'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (error, stack) {
      debugPrint('Onboarding local save failed: $error\n$stack');
    }
  }

  /// Whether this user finished onboarding on this device without the server
  /// having confirmed it yet. `AuthGate` treats this as equivalent to a
  /// non-null `onboarding_completed_at`.
  Future<bool> hasPending(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_key(userId));
    } catch (error) {
      debugPrint('Onboarding pending check failed: $error');
      return false;
    }
  }

  Future<void> clearPending(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (error) {
      debugPrint('Onboarding pending clear failed: $error');
    }
  }

  /// Records how far through the flow this user got, so a force-quit resumes
  /// where they left off instead of throwing the answers away.
  ///
  /// Overwrites rather than merges: [data] is the whole picture at [step], and
  /// the caller always holds every answer collected so far.
  Future<void> saveProgress(
    String userId,
    int step,
    OnboardingData data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _progressKey(userId),
        jsonEncode({
          'step': step,
          'gender': data.gender?.text,
          'birth_year': data.birthYear,
          'city': data.city?.trim(),
        }),
      );
    } catch (error, stack) {
      // Losing the breadcrumb costs a restart from step one, nothing more. It
      // must never take the step transition down with it.
      debugPrint('Onboarding progress save failed: $error\n$stack');
    }
  }

  /// Reads back an unfinished run, or null if there isn't one. A record that
  /// fails to parse is treated as absent — starting over beats crashing on
  /// launch, and the caller cannot do anything useful with a half-record.
  Future<OnboardingProgress?> loadProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey(userId));
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final step = (json['step'] as num?)?.toInt() ?? 0;
      final city = json['city'] as String?;

      return OnboardingProgress(
        step: step.clamp(0, _maxStep),
        data: OnboardingData(
          gender: Gender.fromText(json['gender'] as String?),
          birthYear: (json['birth_year'] as num?)?.toInt(),
          city: (city != null && city.trim().isNotEmpty) ? city : null,
        ),
      );
    } catch (error, stack) {
      debugPrint('Onboarding progress read failed: $error\n$stack');
      return null;
    }
  }

  Future<void> clearProgress(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey(userId));
    } catch (error) {
      debugPrint('Onboarding progress clear failed: $error');
    }
  }

  /// Pushes the queued record if there is one. Returns true when nothing is
  /// outstanding any more — either it just synced, or there was nothing to
  /// sync in the first place.
  ///
  /// Never throws and never surfaces anything: a failure here just means the
  /// record stays queued for the next trigger.
  Future<bool> syncPending() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(user.id));
      if (raw == null) return true;

      final payload = jsonDecode(raw) as Map<String, dynamic>;
      await client.from('profiles').update(payload).eq('id', user.id);

      await prefs.remove(_key(user.id));
      return true;
    } catch (error, stack) {
      debugPrint('Onboarding sync failed, staying queued: $error\n$stack');
      return false;
    }
  }
}
