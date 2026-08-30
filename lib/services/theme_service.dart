/// Persistence and app-wide broadcast for the light/dark/system preference.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads and writes the stored [ThemeMode].
///
/// `SharedPreferences` because it is already the app's local store — see
/// `onboarding_sync_service.dart`, whose `getInstance()`-per-call pattern this
/// follows rather than introducing a cached handle. Every call is wrapped:
/// a preference that cannot be read is not a reason to fail a launch, and the
/// fallback ([ThemeMode.system]) is the behaviour the app had before there was
/// a setting at all.
class ThemeService {
  const ThemeService();

  static const _key = 'theme_mode';

  /// Stored as the enum's name rather than its index, so reordering
  /// [ThemeMode] upstream cannot silently repoint an existing install at a
  /// different theme.
  Future<ThemeMode> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      return ThemeMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => ThemeMode.system,
      );
    } catch (e) {
      debugPrint('ThemeService.load failed: $e');
      return ThemeMode.system;
    }
  }

  Future<void> save(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (e) {
      debugPrint('ThemeService.save failed: $e');
    }
  }
}

/// The live theme mode, listened to by `MedicoApp` and set from Profile.
///
/// A [ValueNotifier] rather than a new dependency or an [InheritedWidget]: the
/// app has no state-management package and no ambient-state convention, and
/// exactly two parties care about this value — the [MaterialApp] that renders
/// it and the settings row that changes it. A notifier is the smallest thing
/// that connects those two without threading a callback through `AuthGate`,
/// `HomeScreen` and the tab bar to reach a leaf.
///
/// Deliberately not a general-purpose store. If a second app-wide preference
/// ever needs the same treatment (the numerals toggle is the obvious
/// candidate), that is the point to reach for a real pattern rather than
/// growing a second singleton beside this one.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(super.value, {this.service = const ThemeService()});

  /// The store this controller persists through. Injectable so a test can
  /// swap in a fake rather than reaching for real `SharedPreferences`.
  final ThemeService service;

  /// Pre-seeded with the default rather than declared `late`, so anything that
  /// builds a widget without going through `main()` — every widget test — gets
  /// a working controller instead of a `LateInitializationError`. [init]
  /// replaces it with the stored preference.
  static ThemeController instance = ThemeController(ThemeMode.system);

  /// Reads the stored preference and installs [instance]. Awaited in `main()`
  /// before `runApp`, so the first frame is already the right theme — no
  /// flash of light before a stored dark preference lands.
  static Future<void> init({ThemeService service = const ThemeService()}) async {
    instance = ThemeController(await service.load(), service: service);
  }

  /// Applies [mode] immediately and persists it in the background.
  ///
  /// The write is deliberately not awaited by callers: the UI has already
  /// changed by the time it starts, and making a settings tap wait on disk
  /// would only add latency to something that cannot fail visibly.
  void setMode(ThemeMode mode) {
    if (mode == value) return;
    value = mode;
    unawaited(service.save(mode));
  }
}
