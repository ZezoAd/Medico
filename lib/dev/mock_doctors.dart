/// Placeholder doctors for the Home carousel.
///
/// `public.doctors` exists in Supabase (RLS on, a `Signed-in users can browse
/// doctors` SELECT policy) but holds no rows, and there is no INSERT policy for
/// `authenticated` — so nothing the app can do today would populate it. This
/// list stands in until a real query lands, and is kept here under `lib/dev/`
/// rather than inside the widget so the widget file reads as presentation and
/// the seed data is obviously seed data.
///
/// The schema does not line up with [Doctor] yet: the table has no `name` (it
/// lives in `profiles.full_name`, so a real fetch is a join) and no rating
/// column at all. Nothing should grow a dependency on these exact field names.
library;

import '../models/doctor.dart';

/// Sixteen doctors spread across seven of the eight specialty keys
/// `home_specialty_chips.dart` offers.
///
/// `ophthalmology` is deliberately left with **zero** doctors: it is the
/// standing check that selecting a specialty nobody practises renders the
/// carousel's empty state rather than an empty scroll strip.
///
/// **Most carry a [Doctor.photoUrl], so the card can be reviewed with faces on
/// it.** They are `randomuser.me` portraits — stable numbered endpoints,
/// gender-matched to each name (an Arabic given name reads as one or the
/// other, and a mismatch is the first thing a patient would notice), and ~5KB
/// each so a rail of them is not a download. Verified reachable when added.
///
/// `mock-7` and `mock-15` are deliberately left photoless. The initials
/// fallback is the state nearly every *real* doctor will be in — `public.
/// doctors` has no photo column and no upload path — so it must stay visible
/// on Home rather than being something only a unit test ever sees. Do not
/// "finish the set" by giving those two portraits.
///
/// These are placeholder faces standing in for people who do not exist. They
/// go when real data does, and nothing should ship to a store with them in it.
///
/// **Every `rating` here is null, on purpose.** Reviews were deferred to V2:
/// there is no review system, no rating column on `public.doctors`, and so no
/// source that could produce a score. Inventing figures for placeholder people
/// would put a number on the card that the real app cannot yet show. The
/// card's rating pill is unchanged and still renders when a score is present —
/// `DoctorCard`'s own tests cover both states with their own fixtures. Do not
/// re-add scores here to "make the cards look finished".
///
/// The first six entries are the original in-widget mocks, order preserved —
/// the carousel's "second card peeks at rest" and one-line-ellipsis tests both
/// read positionally off the head of this list.
const mockDoctors = [
  Doctor(
    id: 'mock-1',
    name: 'د. زينب قاسم',
    specialty: 'أسنان',
    specialtyKey: 'dental',
    clinicName: 'لؤلؤة للأسنان',
    photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
  ),
  Doctor(
    id: 'mock-2',
    name: 'د. مصطفى العزاوي',
    specialty: 'طب عام',
    specialtyKey: 'general',
    clinicName: 'مجمع الرافدين',
    photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
  ),
  // Was the set's only eye doctor, reading "طب عيون". Refiled under `general`
  // so `ophthalmology` ends up empty and the no-doctors state has something to
  // exercise — and the label moved with the key, so the card no longer says one
  // specialty while filtering as another. The clinic name still reads as an eye
  // clinic; it is left alone as harmless colour in placeholder data.
  Doctor(
    id: 'mock-3',
    name: 'د. حسين الطائي',
    specialty: 'طب عام',
    specialtyKey: 'general',
    clinicName: 'عيادة النظر الواضح',
    photoUrl: 'https://randomuser.me/api/portraits/men/51.jpg',
  ),
  Doctor(
    id: 'mock-4',
    name: 'د. نور السامرائي',
    // Was "نسائية وتوليد". Standardised to the chip row's wording so the same
    // specialty is not spelled two ways across one screen.
    specialty: 'نساء وتوليد',
    specialtyKey: 'obgyn',
    clinicName: 'مستشفى الأمل',
    photoUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
  ),
  Doctor(
    id: 'mock-5',
    name: 'د. علي الدليمي',
    specialty: 'عظام',
    specialtyKey: 'orthopedics',
    clinicName: 'مركز العظام التخصصي',
    photoUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
  ),
  // The name is deliberately far too long for the card: it is the standing
  // check that the name ellipsises on one line instead of wrapping or
  // overflowing. Do not shorten it.
  Doctor(
    id: 'mock-6',
    name: 'د. عبدالرحمن ياسين الموسوي الكناني',
    specialty: 'طب عام',
    specialtyKey: 'general',
    clinicName: 'مجمع الشفاء للرعاية الصحية التخصصية',
    photoUrl: 'https://randomuser.me/api/portraits/men/9.jpg',
  ),
  // Photoless on purpose, with `mock-15` — see the note on this list. The
  // initials fallback is the normal state for a real doctor and has to stay
  // visible on the running app.
  Doctor(
    id: 'mock-7',
    name: 'د. أحمد كريم عبدالله',
    specialty: 'طب عام',
    specialtyKey: 'general',
    clinicName: 'عيادة النور الطبية',
  ),
  Doctor(
    id: 'mock-8',
    name: 'د. زينب كاظم الموسوي',
    specialty: 'نساء وتوليد',
    specialtyKey: 'obgyn',
    clinicName: 'عيادة الأمومة والطفولة',
    photoUrl: 'https://randomuser.me/api/portraits/women/25.jpg',
  ),
  Doctor(
    id: 'mock-9',
    name: 'د. رشا عبد الرزاق الدليمي',
    specialty: 'نساء وتوليد',
    specialtyKey: 'obgyn',
    clinicName: 'مستوصف الحياة',
    photoUrl: 'https://randomuser.me/api/portraits/women/12.jpg',
  ),
  Doctor(
    id: 'mock-10',
    name: 'د. نور فاضل السامرائي',
    specialty: 'أطفال',
    specialtyKey: 'pediatrics',
    clinicName: 'عيادة الطفولة السعيدة',
    photoUrl: 'https://randomuser.me/api/portraits/women/90.jpg',
  ),
  Doctor(
    id: 'mock-11',
    name: 'د. مصطفى جواد العبيدي',
    specialty: 'أطفال',
    specialtyKey: 'pediatrics',
    clinicName: 'مركز براعم الصحة',
    photoUrl: 'https://randomuser.me/api/portraits/men/46.jpg',
  ),
  Doctor(
    id: 'mock-12',
    name: 'د. حيدر صباح التميمي',
    specialty: 'جلدية',
    specialtyKey: 'dermatology',
    clinicName: 'عيادة الجمال الطبي',
    photoUrl: 'https://randomuser.me/api/portraits/men/83.jpg',
  ),
  Doctor(
    id: 'mock-13',
    name: 'د. ياسر عماد النعيمي',
    specialty: 'عظام',
    specialtyKey: 'orthopedics',
    clinicName: 'مركز العظام والمفاصل',
    photoUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
  ),
  Doctor(
    id: 'mock-14',
    name: 'د. فراس منذر الحسناوي',
    specialty: 'قلبية',
    specialtyKey: 'cardiology',
    clinicName: 'عيادة القلب السليم',
    photoUrl: 'https://randomuser.me/api/portraits/men/60.jpg',
  ),
  // These two take `general` to six, past HomeSpecialtyDoctors.perSpecialtyCap
  // — so the "عرض المزيد" card is reachable from a specific chip and not only
  // from "الكل". Do not trim `general` back to five without checking what that
  // does to the carousel's overflow test.
  Doctor(
    id: 'mock-15',
    name: 'د. سيف علاء الربيعي',
    specialty: 'طب عام',
    specialtyKey: 'general',
    clinicName: 'عيادة الصحة الأولى',
  ),
  Doctor(
    id: 'mock-16',
    name: 'د. لمى فؤاد الخزرجي',
    specialty: 'طب عام',
    specialtyKey: 'general',
    clinicName: 'مركز الرعاية الأساسية',
    photoUrl: 'https://randomuser.me/api/portraits/women/57.jpg',
  ),
];

/// One doctor the patient has seen before, and when.
///
/// A record rather than a field on [Doctor]: "when did *this patient* last see
/// them" is a fact about a visit, not about the doctor — it belongs to the
/// bookings/queue-history row that does not exist yet, and hanging it off the
/// directory model would be the wrong shape to unpick later.
typedef VisitedDoctor = ({Doctor doctor, DateTime lastVisit});

/// The three doctors Home's "زرتهم سابقاً" section shows.
///
/// **Placeholder, like everything else in this file** — and doubly so. There is
/// no bookings table and no queue history, so nothing in Supabase could say who
/// a patient has seen. This is a hand-picked slice of [mockDoctors] with dates
/// invented for it.
///
/// Picked *by id out of [mockDoctors]* rather than written out again, which is
/// the whole point: the previously-visited row and the specialty carousel show
/// the same people under the same names and specialties, and a rename over
/// there cannot leave a second stale copy over here. The three chosen span a
/// general practitioner, a cardiologist and a dermatologist so the section
/// reads as a real care history rather than three of one kind, and all three
/// now carry a [Doctor.photoUrl], so the row is reviewed with faces on it. The
/// row's initials fallback is still reachable from the carousel above, whose
/// pool holds the two deliberately photoless entries.
///
/// The dates are fixed rather than computed backwards from `DateTime.now()`, so
/// the section renders identically on every run and a widget test can assert on
/// the exact string. They will drift further into the past as time passes;
/// that is fine for seed data and is not worth a clock dependency.
final mockPreviouslyVisited = <VisitedDoctor>[
  (doctor: _doctorById('mock-3'), lastVisit: DateTime(2026, 8, 14)),
  (doctor: _doctorById('mock-14'), lastVisit: DateTime(2026, 6, 22)),
  (doctor: _doctorById('mock-12'), lastVisit: DateTime(2026, 4, 30)),
];

/// The five doctors Home's "انضموا حديثاً" section shows, newest first.
///
/// **Placeholder, like everything else in this file**, and invented for the
/// same reason [mockPreviouslyVisited] is: `public.doctors` has no
/// `created_at` the app reads and no onboarding flow behind it, so nothing
/// could say who joined recently. Picked by id out of [mockDoctors] so the
/// section names the same people as the carousel and the visited list.
///
/// **A plain [List<Doctor>], deliberately not a record carrying a join date.**
/// The agreed design communicates newness through the *section* — its title
/// and count — and never through the card, which is the same [DoctorCard] the
/// specialty carousel draws and has to look identical in every context. With
/// no "joined X ago" line to render, a date here would be a field nothing
/// reads. **List order is the newness signal**: most recently joined first,
/// which is what a real `ORDER BY created_at DESC` will hand back.
///
/// Five, not three: enough that the rail scrolls on a phone, so the section
/// reads as a row to browse rather than as a short fixed set. Deliberately no
/// overlap with [mockPreviouslyVisited] — a doctor you have already visited is
/// a poor example of one who just joined — and five distinct specialties, all
/// five carrying a [Doctor.photoUrl] so the rail can be judged with faces in
/// it. The initials state is not represented here on purpose: it is the
/// carousel's pool that holds the photoless entries, and this rail is the one
/// most often looked at while the card's design is still moving.
final mockNewlyJoined = <Doctor>[
  _doctorById('mock-16'),
  _doctorById('mock-11'),
  _doctorById('mock-1'),
  _doctorById('mock-8'),
  _doctorById('mock-13'),
];

/// Throws if the id is gone, which is deliberate: an entry deleted from
/// [mockDoctors] should fail loudly here at first use rather than silently
/// shortening the section.
Doctor _doctorById(String id) => mockDoctors.firstWhere((d) => d.id == id);
