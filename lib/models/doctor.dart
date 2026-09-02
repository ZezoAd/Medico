/// A doctor as the Home carousel needs to render one.
///
/// **A placeholder, not the eventual schema.** `public.doctors` exists in
/// Supabase but is empty, and nothing in the app queries it yet — the tables it
/// actually touches are `profiles` and `device_tokens`. This model is shaped
/// for what the card draws, not for that table: there is no `name` column (it
/// lives in `profiles.full_name`, so a real fetch is a join) and no rating
/// column at all. It exists so the Featured Doctors carousel can be built as a
/// dumb widget (the UI-first rule in CLAUDE.md) without a service layer for a
/// table with no rows in it. Real integration replaces this wholesale; nothing
/// should grow a dependency on these exact field names in the meantime.
///
/// Deliberately *not* [UserProfile]. That model answers "who is signed in and
/// what is their role" — its `UserRole.doctor` is the account's own role, not
/// a directory listing. The two are unrelated concerns.
library;

import 'package:flutter/foundation.dart';

@immutable
class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.specialtyKey,
    required this.clinicName,
    this.photoUrl,
    this.rating,
  });

  /// Stable identifier. A plain [String] rather than a UUID type — what the
  /// real key looks like is a backend decision that has not been made.
  final String id;

  /// Display name including the honorific, e.g. "د. زينب قاسم".
  final String name;

  /// Human-readable specialty label, e.g. "أسنان". Display copy only — never
  /// match on this. [specialtyKey] is what filtering reads.
  final String specialty;

  /// The ASCII specialty identifier the Home chip row filters on — one of
  /// `general`, `dental`, `obgyn`, `pediatrics`, `dermatology`, `orthopedics`,
  /// `cardiology`, `ophthalmology`, matching `_Specialty.key` in
  /// `home_specialty_chips.dart`. Never `all`: that is the chip row's
  /// "no filter" sentinel, not a specialty a doctor can practise.
  ///
  /// Required rather than defaulted, and kept apart from [specialty], so the
  /// Arabic copy can be reworded without silently changing what a chip matches
  /// — and so a new doctor cannot quietly file itself under a wrong default.
  ///
  /// `public.doctors.specialty` is plain unconstrained `text` with no CHECK and
  /// no enum behind it, and the table is empty, so nothing has yet decided
  /// whether that column will hold these keys or the Arabic labels. Until it
  /// does, this vocabulary is the app's own.
  final String specialtyKey;

  /// The clinic or complex this doctor practises at, e.g. "مجمع الرافدين".
  final String clinicName;

  /// Remote avatar. Null is a first-class state, not a missing value: the card
  /// draws initials on a tonal square instead, and a URL that fails to load
  /// degrades to the same fallback.
  final String? photoUrl;

  /// Average review score out of 5, or null when this doctor has none.
  ///
  /// Nullable on purpose. Ratings/reviews were deferred to V2 — there is no
  /// review system and no source that could populate this. The field exists so
  /// the card's rating pill is *ready* rather than *promised*: it renders when
  /// a score is present and is omitted entirely when it is not. Introducing it
  /// here is not a decision that reviews are now v1 scope.
  final double? rating;
}
