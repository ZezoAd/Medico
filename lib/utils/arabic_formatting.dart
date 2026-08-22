/// Arabic-Indic digit and counting-grammar helpers shared by any UI copy
/// that reports a count to a patient — the Home queue card today, and the
/// 10/5/3 progressive notification system next.
library;

const _easternArabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Replaces every Western digit (0-9) found in [input] with its
/// Arabic-Indic equivalent (٠-٩). Leaves everything else — including
/// separators like the en dash in a range — untouched, so it's safe to call
/// on an already-formatted string such as a zero-padded minute or a range
/// like "20–30".
String toArabicDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final digit = int.tryParse(char);
    buffer.write(digit == null ? char : _easternArabicDigits[digit]);
  }
  return buffer.toString();
}

/// The counting-grammar shape shared by [patientsAheadPhrase] and
/// [minutesPhrase]: Arabic counted nouns take a different form depending on
/// the count — a bare word for 1, a dual for 2, جمع تكسير with the numeral
/// for 3-10, and مفرد منصوب with the numeral for 11 and up.
String _countedPhrase({
  required int count,
  required String wordOnlyForOne,
  required String dualForm,
  required String pluralFewSuffix,
  required String singularAccusativeSuffix,
}) {
  if (count == 1) return wordOnlyForOne;
  if (count == 2) return dualForm;
  final digits = toArabicDigits('$count');
  if (count <= 10) return '$digits $pluralFewSuffix';
  return '$digits $singularAccusativeSuffix';
}

/// "Patients ahead of you" phrase, e.g. "مريض واحد قبلك", "مريضان قبلك",
/// "٥ مرضى قبلك", "١١ مريضاً قبلك".
///
/// 0 is a real state (the person ahead of you just finished) and isn't part
/// of standard counting grammar, so it's handled separately here rather than
/// forcing it through the 1/2/3-10/11+ rules.
String patientsAheadPhrase(int patientsAhead) {
  assert(patientsAhead >= 0, 'patientsAhead cannot be negative');
  if (patientsAhead == 0) return 'لا يوجد مرضى قبلك';
  return _countedPhrase(
    count: patientsAhead,
    wordOnlyForOne: 'مريض واحد قبلك',
    dualForm: 'مريضان قبلك',
    pluralFewSuffix: 'مرضى قبلك',
    singularAccusativeSuffix: 'مريضاً قبلك',
  );
}

/// A standalone minutes count, e.g. "دقيقة واحدة", "دقيقتان", "٥ دقائق",
/// "٣٠ دقيقة".
///
/// [afterPreposition] switches the dual from its default مرفوع form
/// ("دقيقتان") to the مجرور/منصوب form governed prepositions like بعد or
/// خلال require ("دقيقتين") — e.g. "دورك بعد دقيقتين", not "بعد دقيقتان".
/// Every other count form (1, 3-10, 11+) doesn't change shape under a
/// preposition, so this only affects the count == 2 case.
String minutesPhrase(int minutes, {bool afterPreposition = false}) {
  assert(minutes >= 0, 'minutes cannot be negative');
  if (minutes == 0) return 'أقل من دقيقة';
  return _countedPhrase(
    count: minutes,
    wordOnlyForOne: 'دقيقة واحدة',
    dualForm: afterPreposition ? 'دقيقتين' : 'دقيقتان',
    pluralFewSuffix: 'دقائق',
    singularAccusativeSuffix: 'دقيقة',
  );
}

/// Formats [time] as a 12-hour Arabic-Indic clock string, e.g. "٤:١٥ م".
/// Minutes are always two digits — "٤:٠٥ م", never "٤:٥ م".
String formatArabicClock12(DateTime time) {
  final hour24 = time.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = hour24 < 12 ? 'ص' : 'م';
  return '${toArabicDigits('$hour12')}:${toArabicDigits(minute)} $period';
}
