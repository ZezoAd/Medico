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

/// A counted phrase split into the numeral and the noun that follows it.
///
/// [numeral] is null for the counts that take no numeral at all — Arabic
/// puts the count inside the word itself for 1 and 2, so a numeral there
/// would be redundant.
typedef CountedParts = ({String? numeral, String noun});

/// The counting-grammar shape shared by [patientsAheadPhrase] and
/// [minutesPhrase]: Arabic counted nouns take a different form depending on
/// the count — a bare word for 1, a dual for 2, جمع تكسير with the numeral
/// for 3-10, and مفرد منصوب with the numeral for 11 and up.
CountedParts _countedParts({
  required int count,
  required String wordOnlyForOne,
  required String dualForm,
  required String pluralFewSuffix,
  required String singularAccusativeSuffix,
}) {
  if (count == 1) return (numeral: null, noun: wordOnlyForOne);
  if (count == 2) return (numeral: null, noun: dualForm);
  final digits = toArabicDigits('$count');
  if (count <= 10) return (numeral: digits, noun: pluralFewSuffix);
  return (numeral: digits, noun: singularAccusativeSuffix);
}

String _joinParts(CountedParts parts) =>
    parts.numeral == null ? parts.noun : '${parts.numeral} ${parts.noun}';

/// "Patients ahead of you" phrase, e.g. "مريض واحد قبلك", "مريضان قبلك",
/// "٥ مرضى قبلك", "١١ مريضاً قبلك".
///
/// 0 is a real state (the person ahead of you just finished) and isn't part
/// of standard counting grammar, so it's handled separately here rather than
/// forcing it through the 1/2/3-10/11+ rules.
String patientsAheadPhrase(int patientsAhead) =>
    _joinParts(patientsAheadParts(patientsAhead));

/// [patientsAheadPhrase] split into its numeral and noun, for callers that
/// typeset the two at different sizes — the Home card renders the numeral as
/// a hero glyph with the noun beside it.
///
/// Composing the phrase from these same parts is what stops the card from
/// printing the count twice (a hero "٥" above a "٥ مرضى قبلك" line), and
/// keeps the numeral-less 1 and 2 cases correct for free: they come back
/// with a null [CountedParts.numeral], so the card knows to render the word
/// alone rather than reaching for a digit that shouldn't be there.
CountedParts patientsAheadParts(int patientsAhead) {
  assert(patientsAhead >= 0, 'patientsAhead cannot be negative');
  if (patientsAhead == 0) return (numeral: null, noun: 'لا يوجد مرضى قبلك');
  return _countedParts(
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
  return _joinParts(
    _countedParts(
      count: minutes,
      wordOnlyForOne: 'دقيقة واحدة',
      dualForm: afterPreposition ? 'دقيقتين' : 'دقيقتان',
      pluralFewSuffix: 'دقائق',
      singularAccusativeSuffix: 'دقيقة',
    ),
  );
}

/// "Doctors" as a counted noun, e.g. "طبيب واحد", "طبيبان", "٣ أطباء",
/// "١٢ طبيباً" — the Home section headers that report how many doctors a
/// list holds.
///
/// 0 is handled separately for the same reason [patientsAheadParts] does it:
/// zero is not part of the 1/2/3-10/11+ counting rules, and forcing it through
/// them produces "٠ أطباء". Callers that hide their section when the list is
/// empty will never see this branch, but it should not be a lie if they do.
String doctorsPhrase(int count) {
  assert(count >= 0, 'count cannot be negative');
  if (count == 0) return 'لا يوجد أطباء';
  return _joinParts(
    _countedParts(
      count: count,
      wordOnlyForOne: 'طبيب واحد',
      dualForm: 'طبيبان',
      pluralFewSuffix: 'أطباء',
      singularAccusativeSuffix: 'طبيباً',
    ),
  );
}

/// The Levantine/Iraqi month names, which is what an Iraqi patient reads —
/// "أيار", not the transliterated "مايو" of the Gulf and Egypt. Indexed by
/// `month - 1`.
const _levantineMonths = [
  'كانون الثاني',
  'شباط',
  'آذار',
  'نيسان',
  'أيار',
  'حزيران',
  'تموز',
  'آب',
  'أيلول',
  'تشرين الأول',
  'تشرين الثاني',
  'كانون الأول',
];

/// Formats [date] as a day/month-name/year string, e.g. "٢٠ أيار ٢٠٢٥".
///
/// A month *name* rather than a numeral, deliberately: "٥/٨/٢٠٢٥" is ambiguous
/// between day-first and month-first readings, and this string is read at a
/// glance under a doctor's name where there is no room to disambiguate it.
///
/// The day is not zero-padded — "٩ أيلول", not "٠٩ أيلول" — because unlike
/// [formatArabicClock12]'s minutes there is nothing here for a leading zero to
/// keep aligned.
///
/// **This is the single place a date becomes digits in the UI**, which is what
/// makes it the seam the numerals toggle plugs into. There is no toggle yet —
/// `theme_service.dart` names it as the next app-wide preference after the
/// theme — so this emits Arabic-Indic today, matching [formatArabicClock12]
/// and [patientsAheadPhrase]. Nothing should format a date inline instead.
String formatArabicDate(DateTime date) {
  final day = toArabicDigits('${date.day}');
  final year = toArabicDigits('${date.year}');
  return '$day ${_levantineMonths[date.month - 1]} $year';
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
