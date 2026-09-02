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
