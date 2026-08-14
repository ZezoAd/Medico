import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

/// Reads the signed-in user's row out of the `profiles` table.
class ProfileService {
  const ProfileService();

  /// Returns the current user's profile, or null when nobody is signed in or
  /// the trigger hasn't written their row yet.
  Future<UserProfile?> fetchCurrentProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final row = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;

    return UserProfile.fromMap(row);
  }

  /// Records that the caller finished the real signup OTP flow.
  ///
  /// Goes through the `mark_signup_verified` RPC rather than a plain update
  /// because `profiles.signup_verified` is deliberately not writable by the
  /// `authenticated` role — a client that could set it directly could walk
  /// straight past the check it exists to enforce. See
  /// `004_signup_verified.sql`.
  Future<void> markSignupVerified() async {
    await Supabase.instance.client.rpc('mark_signup_verified');
  }
}
