// Covers the mid-flow resume record: the thing that decides whether a
// force-quit costs you your answers. The step transitions that write it are
// exercised on-device; what is worth pinning down here is the storage
// contract those transitions depend on.
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/models/onboarding_data.dart';
import 'package:medico/services/onboarding_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = OnboardingSyncService();
  const userA = 'aaaaaaaa-0000-0000-0000-000000000001';
  const userB = 'bbbbbbbb-0000-0000-0000-000000000002';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('no record for a user who has never started returns null', () async {
    expect(await service.loadProgress(userA), isNull);
  });

  test('round-trips every field', () async {
    await service.saveProgress(
      userA,
      2,
      const OnboardingData(
        gender: Gender.female,
        birthYear: 2010,
        city: 'بغداد',
      ),
    );

    final progress = await service.loadProgress(userA);
    expect(progress, isNotNull);
    expect(progress!.step, 2);
    expect(progress.data.gender, Gender.female);
    expect(progress.data.birthYear, 2010);
    expect(progress.data.city, 'بغداد');
  });

  test('a skipped step 1 round-trips as nulls, not defaults', () async {
    // The trap this guards: reading an unset gender back as `male`.
    await service.saveProgress(userA, 1, const OnboardingData());

    final progress = await service.loadProgress(userA);
    expect(progress!.step, 1);
    expect(progress.data.gender, isNull);
    expect(progress.data.birthYear, isNull);
    expect(progress.data.city, isNull);
  });

  test('saving again overwrites rather than merging', () async {
    await service.saveProgress(
      userA,
      1,
      const OnboardingData(gender: Gender.male, birthYear: 1990),
    );
    await service.saveProgress(
      userA,
      2,
      const OnboardingData(
        gender: Gender.male,
        birthYear: 1990,
        city: 'أربيل',
      ),
    );

    final progress = await service.loadProgress(userA);
    expect(progress!.step, 2);
    expect(progress.data.city, 'أربيل');
    expect(progress.data.birthYear, 1990);
  });

  test('a back-navigation save moves the step down again', () async {
    await service.saveProgress(userA, 2, const OnboardingData(city: 'بغداد'));
    await service.saveProgress(userA, 1, const OnboardingData(city: 'بغداد'));

    expect((await service.loadProgress(userA))!.step, 1);
  });

  test('one user cannot read another user record', () async {
    await service.saveProgress(
      userA,
      2,
      const OnboardingData(gender: Gender.female, city: 'البصرة'),
    );

    expect(await service.loadProgress(userB), isNull);
  });

  test('clearing one user leaves the other intact', () async {
    await service.saveProgress(userA, 1, const OnboardingData());
    await service.saveProgress(userB, 2, const OnboardingData(city: 'دهوك'));

    await service.clearProgress(userA);

    expect(await service.loadProgress(userA), isNull);
    expect((await service.loadProgress(userB))!.step, 2);
  });

  test('an out-of-range step is clamped to a real page index', () async {
    // Guards the PageView: a corrupt record must not become a RangeError on
    // launch, which would be unrecoverable without clearing app data.
    SharedPreferences.setMockInitialValues({
      'onboarding_progress_$userA': '{"step":99}',
    });
    expect((await service.loadProgress(userA))!.step, 3);

    SharedPreferences.setMockInitialValues({
      'onboarding_progress_$userA': '{"step":-4}',
    });
    expect((await service.loadProgress(userA))!.step, 0);
  });

  test('a malformed record reads as absent instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_progress_$userA': 'not json at all',
    });
    expect(await service.loadProgress(userA), isNull);
  });

  test('progress and pending-sync records are independent', () async {
    // They answer opposite questions ("not done" vs "done, not yet synced"),
    // so clearing one must never disturb the other.
    await service.savePending(userA, const OnboardingData(city: 'بغداد'));
    await service.saveProgress(userA, 2, const OnboardingData(city: 'بغداد'));

    await service.clearProgress(userA);

    expect(await service.loadProgress(userA), isNull);
    expect(await service.hasPending(userA), isTrue);
  });
}
