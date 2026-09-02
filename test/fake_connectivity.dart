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
  FakeConnectivity({bool online = true}) : _results = online ? _on : _off {
    service = ConnectivityService(
      changes: _changes.stream,
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
