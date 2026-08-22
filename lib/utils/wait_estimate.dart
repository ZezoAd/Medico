/// Wait-time math shared by the Home queue card and the 10/5/3 progressive
/// notification system — both need "patients ahead × average consult
/// duration" turned into either copy or an absolute clock time.
library;

import 'arabic_formatting.dart';

/// Total estimated minutes until this patient's turn: patients ahead times
/// the doctor's average consultation duration (متوسط مدة الكشف, set during
/// doctor onboarding). That field doesn't exist yet, so it's taken as a
/// plain int here rather than read off a model.
int totalWaitMinutes({
  required int patientsAhead,
  required int avgConsultMinutes,
}) => patientsAhead * avgConsultMinutes;

int _roundToNearest5(num value) => (value / 5).round() * 5;

/// Home-card copy for the current wait: a range like "دورك خلال ٢٠–٣٠ دقيقة
/// تقريباً" that deliberately absorbs normal variance in consultation
/// length, rather than a single number or clock time that can read as a
/// broken promise the moment reality drifts from it.
///
/// The range is ±20% of the point estimate, rounded to the nearest 5
/// minutes. Collapses to a single number whenever the total is under 10
/// minutes, or whenever rounding would otherwise produce a degenerate range
/// like "٥–٥ دقيقة".
String waitRangeLabel({
  required int patientsAhead,
  required int avgConsultMinutes,
}) {
  final total = totalWaitMinutes(
    patientsAhead: patientsAhead,
    avgConsultMinutes: avgConsultMinutes,
  );

  if (total < 10) {
    return 'دورك خلال ${minutesPhrase(total, afterPreposition: true)} تقريباً';
  }

  final low = _roundToNearest5(total * 0.8).clamp(1, total).toInt();
  final high = _roundToNearest5(total * 1.2).toInt();

  if (low >= high) {
    return 'دورك خلال ${minutesPhrase(total, afterPreposition: true)} تقريباً';
  }

  return 'دورك خلال ${toArabicDigits('$low')}–${toArabicDigits('$high')} دقيقة تقريباً';
}

/// Absolute estimated turn time for the offline/stale state, computed from
/// a frozen [recordedAt] moment rather than the current time. Callers must
/// capture [recordedAt] once, at the moment the connection leaves the live
/// state, and keep passing that same value on every rebuild while still
/// offline — recomputing it against "now" on each rebuild would make the
/// estimate silently drift forward every time the widget redraws.
DateTime estimatedTurnTime({
  required DateTime recordedAt,
  required int patientsAhead,
  required int avgConsultMinutes,
}) {
  final total = totalWaitMinutes(
    patientsAhead: patientsAhead,
    avgConsultMinutes: avgConsultMinutes,
  );
  return recordedAt.add(Duration(minutes: total));
}
