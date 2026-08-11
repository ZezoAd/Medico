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
}
