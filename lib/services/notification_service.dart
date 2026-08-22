import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notification permission and FCM device-token registration.
class NotificationService {
  const NotificationService();

  /// Triggers the real OS permission prompt and reports whether it was
  /// granted.
  ///
  /// Android 13+ gates notifications behind a runtime permission, which
  /// `permission_handler` asks for; on iOS the equivalent prompt is owned by
  /// FirebaseMessaging. Either way this is the *system* dialog — the flow
  /// never shows an in-app imitation of it.
  ///
  /// Only call this from an explicit opt-in tap. The OS grants one automatic
  /// ask per install, and a dismissed prompt cannot simply be raised again.
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }

      final settings = await FirebaseMessaging.instance.requestPermission();
      final authorized = settings.authorizationStatus;
      return authorized == AuthorizationStatus.authorized ||
          authorized == AuthorizationStatus.provisional;
    } catch (error, stack) {
      debugPrint('Notification permission request failed: $error\n$stack');
      return false;
    }
  }

  /// Fetches this device's FCM token and stores it against the signed-in
  /// user. Failures are swallowed: a missing token costs the patient a push
  /// later, but it must never block them from finishing onboarding.
  Future<void> registerDeviceToken() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await client.from('device_tokens').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        // `updated_at` only defaults on insert, so re-registering an
        // existing token would otherwise leave its timestamp frozen at
        // whenever the device first reported in.
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        // Targets the composite UNIQUE (user_id, fcm_token) — the same
        // device re-reporting updates its row instead of duplicating it.
      }, onConflict: 'user_id,fcm_token');
    } catch (error, stack) {
      debugPrint('Device token registration failed: $error\n$stack');
    }
  }
}
