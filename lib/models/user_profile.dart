/// The account kind stored in the `profiles.role` text column.
///
/// This is the *only* authority on whether an account is a doctor — the
/// طبيب/مستخدم tab on the sign-in screen is presentation copy, not a role
/// selector.
enum UserRole {
  patient,
  doctor;

  /// Parses the raw `role` text column. Anything unrecognised (or null, for
  /// rows written before the column existed) falls back to [patient], the
  /// least-privileged role.
  static UserRole fromText(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'doctor' => UserRole.doctor,
      _ => UserRole.patient,
    };
  }

  /// The value as it is stored in the database.
  String get text => name;
}

/// A row of the `profiles` table — created by the database trigger that runs
/// on sign-up and copies `full_name` out of the auth user's metadata.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.signupVerified = false,
    this.onboardingCompletedAt,
  });

  /// Matches `auth.users.id`.
  final String id;
  final String fullName;
  final UserRole role;
  final String? phone;

  /// Whether this account finished the real signup OTP flow (or was created
  /// by a provider that proves email ownership itself).
  ///
  /// Deliberately *not* the same thing as Supabase's own confirmation state,
  /// which also flips on a completed password recovery — see
  /// `004_signup_verified.sql`. Defaults to false when the column is missing
  /// from the row, so a partial read can never wave an account through.
  final bool signupVerified;

  /// When the patient finished the onboarding flow, or null if they never
  /// did. Null is what routes a signed-in user into onboarding instead of
  /// Home — which also covers accounts created before onboarding shipped,
  /// and anyone who quit part-way through it.
  final DateTime? onboardingCompletedAt;

  bool get isDoctor => role == UserRole.doctor;

  bool get hasCompletedOnboarding => onboardingCompletedAt != null;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?)?.trim() ?? '',
      role: UserRole.fromText(map['role'] as String?),
      phone: map['phone'] as String?,
      signupVerified: map['signup_verified'] as bool? ?? false,
      onboardingCompletedAt: DateTime.tryParse(
        map['onboarding_completed_at'] as String? ?? '',
      ),
    );
  }
}
