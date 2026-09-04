/// A real [ConnectivityService] wired to a controller the test pushes into,
/// instead of to `connectivity_plus`'s platform channel.
///
/// Kept out of `_test.dart` so `flutter test` does not try to run it as a
/// suite. The service takes its change stream and its probe as optional
/// constructor arguments for exactly this — see the note there on why
/// `Connectivity` itself cannot be faked.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medico/services/connectivity_service.dart';

class FakeConnectivity {
  /// [extraReconnectTasks] stands in for the real data-refresh work a
  /// reconnect will one day wait on — a slow task, one that never resolves, or
  /// one that throws. [reconnectMinimumHold] and
  /// [reconnectCeiling] default to the shipped values and are overridden only
  /// to keep a test from sitting through the real ones.
  FakeConnectivity({
    bool online = true,
    List<Future<void> Function()> extraReconnectTasks = const [],
    Duration reconnectMinimumHold =
        ConnectivityService.defaultReconnectMinimumHold,
    Duration reconnectCeiling = ConnectivityService.defaultReconnectCeiling,
  }) : _results = online ? _on : _off {
    service = ConnectivityService(
      changes: _changes.stream,
      extraReconnectTasks: extraReconnectTasks,
      reconnectMinimumHold: reconnectMinimumHold,
      reconnectCeiling: reconnectCeiling,
      probe: () async {
        probeCount++;
        return _results;
      },
    );
  }

  static const _on = [ConnectivityResult.wifi];
  static const _off = [ConnectivityResult.none];

  final _changes = StreamController<List<ConnectivityResult>>.broadcast();

  /// What the next probe will find, and what the last [emit] announced.
  List<ConnectivityResult> _results;

  late final ConnectivityService service;

  /// How many times a [ConnectivityService.checkNow] actually reached the
  /// "platform" — the assertion that resume and pull-to-refresh really ask
  /// rather than trusting what they were last told.
  int probeCount = 0;

  /// Announces a change, the way the plugin's own stream would.
  void emit({required bool online}) {
    _results = online ? _on : _off;
    _changes.add(_results);
  }

  /// Announces a change *and* advances the clock past the confirmation window,
  /// so the service actually commits instead of sitting on
  /// [ConnectivityPhase.confirming].
  ///
  /// [emit] on its own is not enough in a widget test. `pumpAndSettle` returns
  /// as soon as nothing schedules a frame, and both confirmation windows are
  /// bare timers that schedule none — so a test that emits and only settles
  /// sees the phase stranded mid-confirmation and ends with a pending timer.
  ///
  /// Several tests used to get past this without asking: the queue card that
  /// sat in Home's hero slot started a ten-second countdown animation whenever
  /// the phase was `confirming`, and `pumpAndSettle` chased that animation
  /// right through the hold. That was incidental — the empty-state card now
  /// back in that slot has no such animation — so the wait is stated here
  /// rather than borrowed from whatever happens to be on screen.
  Future<void> emitAndSettle(
    WidgetTester tester, {
    required bool online,
  }) async {
    emit(online: online);
    await tester.pump(
      online
          ? service.reconnectMinimumHold
          : ConnectivityService.disconnectConfirmationHold,
    );
    await tester.pumpAndSettle();
  }

  /// Changes what a probe will find **without** announcing it — the
  /// backgrounded-Android case the whole `checkNow` path exists for.
  void changeSilently({required bool online}) {
    _results = online ? _on : _off;
  }

  void dispose() {
    service.dispose();
    _changes.close();
  }
}

/// A [FakeConnectivity] torn down at the end of the test.
FakeConnectivity useFakeConnectivity({bool online = true}) {
  final fake = FakeConnectivity(online: online);
  addTearDown(fake.dispose);
  return fake;
}
