/// A doctor as the Home carousel needs to render one.
///
/// **A placeholder, not the eventual schema.** There is no `doctors` table in
/// Supabase and no query behind this — the only tables the app touches today
/// are `profiles` and `device_tokens`. This exists so the Featured Doctors
/// carousel can be built as a dumb widget (the UI-first rule in CLAUDE.md)
/// without inventing a service layer that would imply a backend that is not
/// there. Real integration replaces this wholesale; nothing should grow a
/// dependency on these exact field names in the meantime.
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
    required this.clinicName,
    this.photoUrl,
    this.rating,
  });

  /// Stable identifier. A plain [String] rather than a UUID type — what the
  /// real key looks like is a backend decision that has not been made.
  final String id;

  /// Display name including the honorific, e.g. "د. زينب قاسم".
  final String name;

  /// Human-readable specialty label, e.g. "أسنان".
  ///
  /// Not the ASCII key `home_specialty_chips.dart` filters on. When the two
  /// have to line up, that widget's `_Specialty.key` is the contract and this
  /// is the copy — see the note there on why they are kept apart.
  final String specialty;

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
