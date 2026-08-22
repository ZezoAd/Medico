import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/onboarding_data.dart';

/// Persists what the onboarding flow collected.
class OnboardingService {
  const OnboardingService();

  /// Writes the answers to the signed-in patient's `profiles` row.
  ///
  /// Returns false if the write failed. The caller still shows the completion
  /// screen either way — losing an optional answer is recoverable from
  /// Settings, whereas stranding someone on the last step of signup is not.
  Future<bool> saveOnboarding(OnboardingData data) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return false;

      await client
          .from('profiles')
          .update(data.toProfileUpdate())
          .eq('id', user.id);
      return true;
    } catch (error, stack) {
      debugPrint('Onboarding save failed: $error\n$stack');
      return false;
    }
  }
}
