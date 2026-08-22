/// What the post-signup onboarding flow collects before it hands the patient
/// to Home. Every field is nullable because only the city step is required —
/// the other two are skippable by design.
library;

/// Patient gender. Stored as a stable English token in `profiles.gender` so
/// the column stays queryable and survives a copy change; the Arabic label is
/// presentation only.
enum Gender {
  male('ذكر'),
  female('أنثى');

  const Gender(this.arabicLabel);

  /// The label shown on the segmented control.
  final String arabicLabel;

  /// The value as it is stored in the database.
  String get text => name;

  /// Parses the raw `gender` text column. Unrecognised or null reads back as
  /// null rather than a default — an unset gender is a real, valid state and
  /// must not silently become "male".
  static Gender? fromText(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'male' => Gender.male,
      'female' => Gender.female,
      _ => null,
    };
  }
}

/// The in-flight answers, carried across the three steps by
/// `OnboardingFlowScreen` and written once on completion.
class OnboardingData {
  const OnboardingData({this.gender, this.birthYear, this.city});

  final Gender? gender;
  final int? birthYear;

  /// A governorate from the picker, or free text the patient typed. The list
  /// of 18 governorates is a convenience, not a constraint — a required field
  /// that can't accept your town is a dead end, so anything non-empty is
  /// accepted here.
  final String? city;

  /// The only field the flow refuses to advance without.
  bool get hasCity => (city?.trim().isNotEmpty) ?? false;

  /// `clearGender`/`clearBirthYear` exist because `copyWith(gender: null)`
  /// cannot express "unset this" — tapping the selected gender again
  /// deselects it, so the flow genuinely needs to write a null back.
  OnboardingData copyWith({
    Gender? gender,
    int? birthYear,
    String? city,
    bool clearGender = false,
    bool clearBirthYear = false,
  }) {
    return OnboardingData(
      gender: clearGender ? null : (gender ?? this.gender),
      birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
      city: city ?? this.city,
    );
  }

  /// The `profiles` update payload. Null answers are sent as nulls rather
  /// than omitted so that re-running onboarding can clear a previous value.
  Map<String, dynamic> toProfileUpdate() {
    return {
      'gender': gender?.text,
      'birth_year': birthYear,
      'city': city?.trim(),
      'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
