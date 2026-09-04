/// [ConnectivityService]'s two jobs: collapsing the plugin's raw result lists
/// into one online/offline bool, and only speaking up when that bool actually
/// moves.
///
/// The real plugin is never touched — the service takes its change stream and
/// its probe as constructor arguments, so everything here runs as a plain Dart
/// test with no platform channel and no widget tree.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/services/connectivity_service.dart';

import 'fake_connectivity.dart';

void main() {
  /// Collects everything [service] emits, for assertion after a flush.
  List<bool> record(ConnectivityService service) {
    final seen = <bool>[];
    service.isOnlineStream.listen(seen.add);
    return seen;
  }

  test('starts optimistic, before anything is known', () {
    final fake = useFakeConnectivity();
    expect(
      fake.service.isOnline,
      isTrue,
      reason: 'guessing offline would flash the strip on every cold start',
    );
  });

  test('a platform event that changes nothing emits nothing', () async {
    final fake = useFakeConnectivity();
    final seen = record(fake.service);

    // Already online by default, so this says only what is already believed.
    fake.emit(online: true);
    await pumpEventQueue();

    expect(seen, isEmpty);
    expect(fake.service.isOnline, isTrue);
  });

  test('a real change emits once, and repeats of it emit nothing', () async {
    final fake = useFakeConnectivity();
    final seen = record(fake.service);

    fake.emit(online: false);
    await pumpEventQueue();
    expect(seen, [false]);
    expect(fake.service.isOnline, isFalse);

    // Android reports a burst of results across a handover; all of them mean
    // the same thing and none of them should reach a listener.
    fake.emit(online: false);
    fake.emit(online: false);
    await pumpEventQueue();
    expect(seen, [false]);

    fake.emit(online: true);
    await pumpEventQueue();
    expect(seen, [false, true]);
    expect(fake.service.isOnline, isTrue);
  });

  test(
    'online means any result that is not none — matching auth_gate',
    () async {
      final changes = StreamController<List<ConnectivityResult>>();
      final service = ConnectivityService(
        changes: changes.stream,
        probe: () async => const [ConnectivityResult.none],
      );
      addTearDown(service.dispose);
      final seen = record(service);

      changes.add(const [ConnectivityResult.none]);
      await pumpEventQueue();
      expect(seen, [false], reason: 'a lone none is offline');

      // A handover can report several transports at once; one live transport is
      // enough, even alongside a none.
      changes.add(const [ConnectivityResult.none, ConnectivityResult.mobile]);
      await pumpEventQueue();
      expect(seen, [false, true]);

      // An empty list is "no transports", which is offline — `any` on an empty
      // list is false, so this falls out of the same expression rather than
      // needing a case of its own.
      changes.add(const []);
      await pumpEventQueue();
      expect(seen, [false, true, false]);

      await changes.close();
    },
  );

  group('checkNow', () {
    test('asks the platform and emits when the answer moved', () async {
      final fake = useFakeConnectivity();
      final seen = record(fake.service);

      // The edge the app missed while backgrounded: the device went offline
      // and the stream never said so.
      fake.changeSilently(online: false);
      expect(fake.service.isOnline, isTrue, reason: 'not told yet');

      await fake.service.checkNow();
      await pumpEventQueue();

      expect(fake.probeCount, 1);
      expect(fake.service.isOnline, isFalse);
      expect(seen, [false]);
    });

    test('emits nothing when the answer is unchanged', () async {
      final fake = useFakeConnectivity();
      final seen = record(fake.service);

      await fake.service.checkNow();
      await pumpEventQueue();

      expect(fake.probeCount, 1, reason: 'it must still actually ask');
      expect(seen, isEmpty);
    });

    test(
      'a failing probe keeps the last known value and does not throw',
      () async {
        final changes = StreamController<List<ConnectivityResult>>();
        final service = ConnectivityService(
          changes: changes.stream,
          probe: () async => throw Exception('no plugin here'),
        );
        addTearDown(service.dispose);
        final seen = record(service);

        changes.add(const [ConnectivityResult.none]);
        await pumpEventQueue();
        expect(service.isOnline, isFalse);

        // Awaited from a RefreshIndicator in the app, so this must not throw —
        // and a probe that failed is not evidence of being online again.
        await service.checkNow();
        await pumpEventQueue();

        expect(service.isOnline, isFalse);
        expect(seen, [false]);

        await changes.close();
      },
    );
  });

  group('confirmed phase', () {
    /// Collects committed-phase transitions.
    List<ConnectivityPhase> recordPhases(ConnectivityService service) {
      final seen = <ConnectivityPhase>[];
      service.phaseStream.listen(seen.add);
      return seen;
    }

    /// Long enough for either direction's floor plus the probe. The disconnect
    /// floor is the longer of the two, so waiting it out covers both.
    ///
    /// Updated for the split into per-direction constants; the bodies below
    /// are unchanged.
    Future<void> settle() => Future<void>.delayed(
      ConnectivityService.disconnectConfirmationHold +
          const Duration(milliseconds: 120),
    );

    test('starts committed-online, matching the optimistic raw default', () {
      final fake = useFakeConnectivity();
      expect(fake.service.phase, ConnectivityPhase.confirmedOnline);
    });

    test('a genuine drop passes through confirming, then commits', () async {
      final fake = useFakeConnectivity();
      final phases = recordPhases(fake.service);

      fake.emit(online: false);
      await pumpEventQueue();

      // Immediately: confirming, not yet offline. The queue card shows its
      // retry badge here rather than freezing.
      expect(phases, [ConnectivityPhase.confirming]);
      expect(fake.service.phase, ConnectivityPhase.confirming);
      expect(
        fake.service.isOnline,
        isFalse,
        reason: 'the raw layer is untouched and still instant',
      );

      await settle();
      expect(phases, [
        ConnectivityPhase.confirming,
        ConnectivityPhase.confirmedOffline,
      ]);
      expect(
        fake.probeCount,
        greaterThan(0),
        reason: 'confirmation must re-verify, not just wait',
      );
    });

    test('a genuine recovery also passes through confirming', () async {
      final fake = useFakeConnectivity();
      fake.emit(online: false);
      await settle();
      expect(fake.service.phase, ConnectivityPhase.confirmedOffline);

      final phases = recordPhases(fake.service);
      fake.emit(online: true);
      await pumpEventQueue();

      // Both directions go through the window — not just reconnect.
      expect(phases, [ConnectivityPhase.confirming]);

      await settle();
      expect(phases, [
        ConnectivityPhase.confirming,
        ConnectivityPhase.confirmedOnline,
      ]);
    });

    test('a flicker never commits and leaves the phase where it was', () async {
      final fake = useFakeConnectivity();
      final phases = recordPhases(fake.service);

      // Drops, then comes straight back before the hold elapses — a lift, a
      // handover, a tunnel. The raw stream reports both edges honestly.
      fake.emit(online: false);
      await pumpEventQueue();
      expect(phases, [ConnectivityPhase.confirming]);

      fake.emit(online: true);
      await settle();

      // Back to where it started, and confirmedOffline was never emitted.
      expect(fake.service.phase, ConnectivityPhase.confirmedOnline);
      expect(
        phases,
        isNot(contains(ConnectivityPhase.confirmedOffline)),
        reason: 'a change that undid itself must never commit',
      );
      expect(phases.last, ConnectivityPhase.confirmedOnline);
    });

    test(
      'a probe that contradicts the report discards the transition',
      () async {
        final fake = useFakeConnectivity();
        final phases = recordPhases(fake.service);

        // The stream claims offline, but by the time checkNow asks, the device
        // is fine — so the report is not corroborated.
        fake.emit(online: false);
        await pumpEventQueue();
        fake.changeSilently(online: true);

        await settle();

        expect(
          phases,
          isNot(contains(ConnectivityPhase.confirmedOffline)),
          reason: 'the re-check contradicted it',
        );
        expect(fake.service.phase, ConnectivityPhase.confirmedOnline);
      },
    );

    test('recheck shows confirming for the whole hold, then settles', () async {
      final fake = useFakeConnectivity();
      fake.emit(online: false);
      await settle();

      final phases = recordPhases(fake.service);
      final future = fake.service.recheck();
      await pumpEventQueue();

      expect(
        fake.service.phase,
        ConnectivityPhase.confirming,
        reason:
            'a tap must produce the same visible state as an automatic '
            'transition, not a private in-flight flag',
      );

      await future;
      expect(fake.service.phase, ConnectivityPhase.confirmedOffline);
      expect(phases.first, ConnectivityPhase.confirming);
      expect(fake.probeCount, greaterThan(0));
    });

    test('the raw stream keeps its instant, undebounced behaviour', () async {
      final fake = useFakeConnectivity();
      final raw = <bool>[];
      fake.service.isOnlineStream.listen(raw.add);

      fake.emit(online: false);
      await pumpEventQueue();

      // No waiting: the raw layer is exactly as it was before the phase layer
      // existed, for callers that want truth rather than presentation.
      expect(raw, [false]);
      expect(fake.service.isOnline, isFalse);
    });
  });

  /// The reconnect direction waits on real work, floored and capped. These
  /// drive it through [ConnectivityService.extraReconnectTasks], the same seam
  /// a real data refresh will plug into.
  group('reconnect confirmation work', () {
    /// A service already committed offline, with [tasks] appended to the
    /// reconnect list, ready for a reconnect to be reported.
    Future<FakeConnectivity> offlineWith(
      List<Future<void> Function()> tasks, {
      Duration? minimumHold,
      Duration? ceiling,
    }) async {
      final fake = FakeConnectivity(
        extraReconnectTasks: tasks,
        reconnectMinimumHold:
            minimumHold ?? ConnectivityService.defaultReconnectMinimumHold,
        reconnectCeiling:
            ceiling ?? ConnectivityService.defaultReconnectCeiling,
      );
      addTearDown(fake.dispose);
      fake.emit(online: false);
      await Future<void>.delayed(
        ConnectivityService.disconnectConfirmationHold +
            const Duration(milliseconds: 120),
      );
      expect(fake.service.phase, ConnectivityPhase.confirmedOffline);
      return fake;
    }

    test(
      'the floor is a floor, not the wait — slow work delays the commit',
      () async {
        // Comfortably past the 600ms floor, so if the floor were the whole story
        // this would already have committed.
        const taskDuration = Duration(milliseconds: 1500);
        final fake = await offlineWith([
          () => Future<void>.delayed(taskDuration),
        ]);

        final started = DateTime.now();
        fake.emit(online: true);

        // Past the floor, but the work is still running.
        await Future<void>.delayed(
          ConnectivityService.defaultReconnectMinimumHold +
              const Duration(milliseconds: 200),
        );
        expect(
          fake.service.phase,
          ConnectivityPhase.confirming,
          reason: 'the floor elapsed but the task had not finished',
        );

        await Future<void>.delayed(const Duration(milliseconds: 900));
        expect(fake.service.phase, ConnectivityPhase.confirmedOnline);
        expect(
          DateTime.now().difference(started),
          greaterThanOrEqualTo(taskDuration),
          reason: 'it waited for the work, not for the floor',
        );
      },
    );

    test('a fast reconnect still holds for the floor', () async {
      final fake = await offlineWith(const []);

      final started = DateTime.now();
      fake.emit(online: true);
      // The probe answers effectively instantly here.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(
        fake.service.phase,
        ConnectivityPhase.confirming,
        reason: 'an instant resolution must not flash past unread',
      );

      await Future<void>.delayed(
        ConnectivityService.defaultReconnectMinimumHold +
            const Duration(milliseconds: 200),
      );
      expect(fake.service.phase, ConnectivityPhase.confirmedOnline);
      expect(
        DateTime.now().difference(started),
        greaterThanOrEqualTo(ConnectivityService.defaultReconnectMinimumHold),
      );
    });

    test('two tasks run concurrently rather than stacking', () async {
      const each = Duration(milliseconds: 900);
      final fake = await offlineWith([
        () => Future<void>.delayed(each),
        () => Future<void>.delayed(each),
      ]);

      final started = DateTime.now();
      fake.emit(online: true);
      await Future<void>.delayed(each + const Duration(milliseconds: 400));

      expect(fake.service.phase, ConnectivityPhase.confirmedOnline);
      final elapsed = DateTime.now().difference(started);
      expect(
        elapsed,
        lessThan(each * 2),
        reason:
            'the slower task, not the sum — adding work later must not '
            'stack durations',
      );
    });

    test('the ceiling fails open when work never resolves', () async {
      // Scaled down, not restructured: the shipped relationship is floor well
      // below ceiling, with work outlasting both, and 50 < 200 keeps it. The
      // real 600ms/8s values would put ~9 seconds of sleeping into the suite
      // to prove the same branch.
      const floor = Duration(milliseconds: 50);
      const ceiling = Duration(milliseconds: 200);

      // Never completes: a hung refresh, a request with no timeout of its own.
      final fake = await offlineWith(
        [() => Completer<void>().future],
        minimumHold: floor,
        ceiling: ceiling,
      );

      fake.emit(online: true);

      // Past the floor, so the floor is not what is holding it — the unfinished
      // work is.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        fake.service.phase,
        ConnectivityPhase.confirming,
        reason: 'still waiting, right up to the ceiling',
      );

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(
        fake.service.phase,
        ConnectivityPhase.confirmedOnline,
        reason:
            'fail open — a slow refresh must never hang the UI on a '
            'spinner when the network itself is back',
      );
    });

    test('a task that throws still commits, like the ceiling case', () async {
      final fake = await offlineWith([
        () async => throw Exception('refresh blew up'),
      ]);

      fake.emit(online: true);
      await Future<void>.delayed(
        ConnectivityService.defaultReconnectMinimumHold +
            const Duration(milliseconds: 250),
      );

      expect(
        fake.service.phase,
        ConnectivityPhase.confirmedOnline,
        reason:
            'a thrown task must fail open exactly like a hung one — it is '
            'the commit that clears _pending, so an escaping error would '
            'strand the phase on confirming forever',
      );
    });

    test('a thrown Error is caught too, not just Exception', () async {
      // The unfiltered `catch` earns its keep here: `on Exception` would let
      // this escape, and the phase would never leave confirming.
      final fake = await offlineWith([
        () async => throw StateError('a bug in a future refresh task'),
      ]);

      fake.emit(online: true);
      await Future<void>.delayed(
        ConnectivityService.defaultReconnectMinimumHold +
            const Duration(milliseconds: 250),
      );

      expect(fake.service.phase, ConnectivityPhase.confirmedOnline);
    });

    test('a task that throws while genuinely offline does not commit', () async {
      // Failing open is not the same as lying: when the probe says the device
      // is still offline, a broken task is no reason to claim otherwise.
      final fake = await offlineWith([
        () async => throw Exception('refresh blew up'),
      ]);

      // The raw stream claims a reconnect, but the device is really still down.
      fake.emit(online: true);
      fake.changeSilently(online: false);
      await Future<void>.delayed(
        ConnectivityService.defaultReconnectMinimumHold +
            const Duration(milliseconds: 250),
      );

      expect(fake.service.phase, ConnectivityPhase.confirmedOffline);
    });

    test('a flicker still discards while slow work is in flight', () async {
      // The discard path has to stay live for the *whole* window, not just the
      // floor — this reverts long after the floor has elapsed.
      final fake = await offlineWith([
        () => Future<void>.delayed(const Duration(milliseconds: 1500)),
      ]);

      final phases = <ConnectivityPhase>[];
      fake.service.phaseStream.listen(phases.add);

      fake.emit(online: true);
      await Future<void>.delayed(
        ConnectivityService.defaultReconnectMinimumHold +
            const Duration(milliseconds: 200),
      );
      expect(fake.service.phase, ConnectivityPhase.confirming);

      // Gone again before the work finished.
      fake.emit(online: false);
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(fake.service.phase, ConnectivityPhase.confirmedOffline);
      expect(
        phases,
        isNot(contains(ConnectivityPhase.confirmedOnline)),
        reason: 'a reconnect that undid itself mid-work must never commit',
      );
    });
  });

  test('dispose closes the stream and stops listening', () async {
    final fake = FakeConnectivity();
    var done = false;
    fake.service.isOnlineStream.listen(null, onDone: () => done = true);

    fake.service.dispose();
    await pumpEventQueue();
    expect(done, isTrue);

    // Nothing arriving afterwards may reach a closed controller.
    fake.emit(online: false);
    await pumpEventQueue();

    fake.dispose();
  });
}
