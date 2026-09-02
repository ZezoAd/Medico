import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Device-level "is there any network at all", as one deduped broadcast
/// stream plus a synchronous last-known value.
///
/// Deliberately narrow. This answers exactly one question — does the *device*
/// have a route to the internet — and never anything about whether a
/// particular request, channel or subscription is healthy. A Supabase realtime
/// channel can drop while this still reads online, which is the whole reason
/// `queue_status_card.dart` keeps `QueueConnectionStatus` and
/// `StalenessReason` as two separate axes.
///
/// Not a singleton and not global: whoever creates it owns it and must
/// [dispose] it. `HomeScreen` is that owner today, because it outlives every
/// tab switch while `HomeTab` and friends come and go.
///
/// `auth_gate.dart` keeps its own direct `connectivity_plus` subscription and
/// is intentionally left alone. It is not a consumer of this — it watches for
/// a single edge in order to drain one queued onboarding record, on a screen
/// that has usually been disposed by the time Home exists.
class ConnectivityService {
  /// [changes] and [probe] exist for tests only.
  ///
  /// `connectivity_plus`'s [Connectivity] is a factory-backed singleton with a
  /// private generative constructor, so it cannot be subclassed or replaced —
  /// the only other seam is swapping `ConnectivityPlatform.instance`, which
  /// means importing a transitive package the app does not depend on directly.
  /// Two optional parameters that default to the real plugin is the cheaper
  /// honest seam: production callers write `ConnectivityService()` and get the
  /// real thing.
  ConnectivityService({
    Stream<List<ConnectivityResult>>? changes,
    Future<List<ConnectivityResult>> Function()? probe,
  }) : _probe = probe ?? Connectivity().checkConnectivity {
    _sub = (changes ?? Connectivity().onConnectivityChanged).listen(_apply);
  }

  final Future<List<ConnectivityResult>> Function() _probe;

  /// Broadcast because more than one widget legitimately watches this —
  /// `HomeScreen` for the offline strip, `HomeTab` for its reconnect epoch —
  /// and a single-subscription stream would let whichever listened first
  /// starve the other.
  final _controller = StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Starts optimistic on purpose.
  ///
  /// Nothing is known until the first platform event or [checkNow] lands, and
  /// guessing "offline" during that window would flash the offline strip on
  /// every cold start. Guessing "online" is wrong for a strictly shorter time
  /// and fails in the quieter direction: at worst a genuinely offline device
  /// shows no strip for a moment, rather than an online one being told it has
  /// no connection.
  bool _isOnline = true;

  /// The last known answer. Safe to read synchronously during `build`.
  bool get isOnline => _isOnline;

  /// Fires only when [isOnline] actually flips — never once per raw platform
  /// event. Android in particular reports a burst of results when a network
  /// hands over (wifi → mobile → wifi), all of which mean "still online"; a
  /// listener that rebuilt on each would flicker for no reason.
  Stream<bool> get isOnlineStream => _controller.stream;

  /// The same definition `auth_gate.dart` uses, kept identical on purpose: any
  /// result that is not [ConnectivityResult.none] counts as online. An empty
  /// list falls out as offline, since `any` on an empty list is false.
  static bool _onlineFrom(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  void _apply(List<ConnectivityResult> results) {
    final online = _onlineFrom(results);
    if (online == _isOnline) return;
    _isOnline = online;
    if (!_controller.isClosed) _controller.add(online);
  }

  /// Asks the platform directly rather than waiting to be told.
  ///
  /// This exists because `onConnectivityChanged` is not reliable across a
  /// backgrounded app: Android does not guarantee delivery of network changes
  /// to a process that is not in the foreground, so an app that went offline
  /// while backgrounded and came back online before resuming can miss both
  /// edges and sit on a stale answer. Calling this on
  /// [AppLifecycleState.resumed] is what closes that gap. It also backs manual
  /// pull-to-refresh, so a person who suspects the strip is wrong has a way to
  /// make it re-check.
  ///
  /// Emits through [isOnlineStream] only if the answer actually changed, the
  /// same as any platform event.
  Future<void> checkNow() async {
    try {
      _apply(await _probe());
    } on Exception catch (error) {
      // A probe that fails is not evidence of being offline — it is evidence
      // of not knowing. Keeping the last known value is the honest response;
      // flipping to offline here would put the strip on screen because of a
      // plugin error rather than because of the network. Never rethrown: this
      // is awaited from a RefreshIndicator, where an exception would surface
      // as a red screen over a refresh that is otherwise harmless.
      debugPrint(
        'ConnectivityService.checkNow failed, keeping '
        'isOnline=$_isOnline: $error',
      );
    }
  }

  /// Cancels the platform subscription and closes the stream. The owner must
  /// call this; the service holds a live listener until it does.
  void dispose() {
    _sub?.cancel();
    _sub = null;
    _controller.close();
  }
}
