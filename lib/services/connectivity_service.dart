import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// A *committed* view of the device's connection, as opposed to
/// [ConnectivityService.isOnline]'s instant one.
///
/// Three states rather than a bool because the window between "the platform
/// said something changed" and "we believe it" is real, lasts most of a
/// second, and both consumers have to render something during it. Modelling it
/// as a bool would have forced each of them to invent a private "probably
/// changing?" flag and keep it in sync with a timer of its own.
enum ConnectivityPhase {
  /// Believed online, verified.
  confirmedOnline,

  /// Believed offline, verified.
  confirmedOffline,

  /// A change was reported and is being re-verified. The previous committed
  /// value is still the last thing anyone was told; this is not a claim that
  /// it has flipped, only that it might be about to.
  confirming,
}

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
    List<Future<void> Function()> extraReconnectTasks = const [],
    this.reconnectMinimumHold = defaultReconnectMinimumHold,
    this.reconnectCeiling = defaultReconnectCeiling,
  }) : _probe = probe ?? Connectivity().checkConnectivity {
    // Assigned here rather than in the initializer list: a named parameter
    // cannot be an initializing formal for a private field.
    _extraReconnectTasks = extraReconnectTasks;
    _sub = (changes ?? Connectivity().onConnectivityChanged).listen(_apply);
  }

  final Future<List<ConnectivityResult>> Function() _probe;

  /// Additional work a reconnect must wait for, beyond the probe.
  ///
  /// Empty in production today. This is the seam a real data refresh plugs
  /// into when one exists, and the one the tests use to stand in for slow or
  /// hung work — see [_reconnectWork].
  late final List<Future<void> Function()> _extraReconnectTasks;

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

  // ---------------------------------------------------------------------
  // The confirmed layer.
  //
  // The raw stream above is instant and honest but twitchy: a lift ride, a
  // wifi/mobile handover or a tunnel produces flips that are true for a few
  // hundred milliseconds and mean nothing to a person. Everything below turns
  // that into a value that only moves when the change survives a re-check and
  // a minimum visible window.
  // ---------------------------------------------------------------------

  /// Shipped value for [reconnectMinimumHold].
  static const Duration defaultReconnectMinimumHold = Duration(
    milliseconds: 600,
  );

  /// Shipped value for [reconnectCeiling].
  static const Duration defaultReconnectCeiling = Duration(seconds: 8);

  /// The **floor** on a reconnect, not the wait.
  ///
  /// Purely perceptibility: a confirmation that resolves in 40ms would flash
  /// past unread, and the capsule would vanish before a thumb reached its
  /// refresh button. The actual wait is however long [_reconnectWork] takes —
  /// this only stops it being shorter than the eye can follow.
  ///
  /// Injectable for the same reason [_extraReconnectTasks] is: a test that had
  /// to sit through the real values would be slow enough that nobody ran it.
  final Duration reconnectMinimumHold;

  /// Safety timeout on a reconnect. If the confirmation work has not resolved
  /// by now, commit to [ConnectivityPhase.confirmedOnline] anyway on the best
  /// currently-known result.
  ///
  /// Fail *open*, matching how the app already treats ambiguity elsewhere:
  /// `auth_gate.dart` keeps a session rather than signing someone out on an
  /// inconclusive answer, and `checkNow` keeps its last known value rather
  /// than flipping to offline on a failed probe. A person whose network is
  /// back but whose refresh is merely slow must not be held on a "confirming"
  /// spinner indefinitely — the worst case of committing early is one stale
  /// screen, which a pull-to-refresh fixes.
  final Duration reconnectCeiling;

  /// The disconnect floor. Unchanged in shape from the single hold this
  /// replaced: going offline has no async work to wait for — there is nothing
  /// to fetch and nothing to re-subscribe — so this is perceptibility alone,
  /// with no task list and no ceiling. Longer than [reconnectMinimumHold]
  /// because losing a connection is the claim worth being slower to make.
  static const Duration disconnectConfirmationHold = Duration(
    milliseconds: 1200,
  );

  /// The last committed direction. Distinct from [_isOnline], which moves the
  /// instant the platform says so.
  bool _committedOnline = true;

  /// The direction awaiting confirmation, or null when nothing is pending.
  bool? _pending;

  /// True while [recheck] is asking on someone's behalf.
  bool _probing = false;

  /// Invalidates in-flight confirmations. Bumped whenever a pending
  /// transition is superseded, abandoned, or the service is disposed, so a
  /// confirmation that wakes up late can tell it no longer speaks for anyone.
  int _seq = 0;

  final _phaseController = StreamController<ConnectivityPhase>.broadcast();

  ConnectivityPhase? _lastEmittedPhase;

  /// The committed view. Safe to read synchronously during `build`.
  ConnectivityPhase get phase {
    if (_pending != null || _probing) return ConnectivityPhase.confirming;
    return _committedOnline
        ? ConnectivityPhase.confirmedOnline
        : ConnectivityPhase.confirmedOffline;
  }

  /// Emits [phase] whenever it changes, and only then.
  ///
  /// Prefer this over [isOnlineStream] for anything a person looks at.
  /// [isOnlineStream] stays available and unchanged for callers that genuinely
  /// want instant truth — the pull-to-refresh guard in `home_tab.dart` is one:
  /// it is answering "should I fetch right now", not "what should I show".
  Stream<ConnectivityPhase> get phaseStream => _phaseController.stream;

  void _apply(List<ConnectivityResult> results) {
    final online = _onlineFrom(results);
    if (online == _isOnline) return;
    _isOnline = online;
    if (!_controller.isClosed) _controller.add(online);
    _onRawChanged(online);
  }

  void _onRawChanged(bool online) {
    if (online == _committedOnline) {
      // Back where we started. Any pending transition was a flicker that undid
      // itself before it could be confirmed — drop it and stay put. Nothing
      // new is committed; the phase simply returns to the value it held.
      if (_pending != null) {
        _pending = null;
        _seq++;
        _emitPhase();
      }
      return;
    }
    if (_pending == online) return; // already confirming this direction
    _pending = online;
    _emitPhase();
    _confirm(++_seq, online);
  }

  /// Everything that must finish before a reconnect may commit.
  ///
  /// One entry today. A real data refresh — re-subscribing the queue's
  /// realtime channel, re-fetching whatever Home is showing — belongs here as
  /// a second entry once it exists, and needs no other change: the list is
  /// awaited as a whole, concurrently, so a second task costs the *slower*
  /// task's duration rather than the sum of both.
  List<Future<void>> _reconnectWork() => [
    checkNow(),
    for (final task in _extraReconnectTasks) task(),
  ];

  Future<void> _confirm(int seq, bool direction) =>
      direction ? _confirmReconnect(seq) : _confirmDisconnect(seq);

  /// Coming back: wait for the real work, floored and capped.
  Future<void> _confirmReconnect(int seq) async {
    // Started together, before either is awaited, so the floor overlaps the
    // work instead of following it.
    final work = Future.wait<void>([
      ..._reconnectWork(),
      Future<void>.delayed(reconnectMinimumHold),
    ]);

    var hitCeiling = false;
    try {
      // `timeout` cancels its own timer the moment `work` wins, so a fast
      // confirmation leaves no ceiling-length timer dangling behind it.
      await work.timeout(reconnectCeiling);
    } on TimeoutException {
      // MUST stay above the general clause below. `TimeoutException`
      // implements `Exception`, and Dart matches `on` clauses top-down, so
      // reversing these two would let the general handler swallow the ceiling
      // and lose `hitCeiling` — the fail-open commit would silently become an
      // ordinary "did the probe agree?" check.
      hitCeiling = true;
    } catch (error) {
      // Deliberately unfiltered, and deliberately second. A task that failed
      // is not a reason to hang: whatever it threw, this method still has to
      // reach the commit below, because it is the only thing that will ever
      // clear `_pending`. An escaping error would strand the phase on
      // `confirming` for the life of the app — the exact hang the ceiling
      // exists to prevent, arrived at by another road. Caught rather than
      // filtered to `Exception` so an `Error` from a future refresh task
      // cannot do that either.
      debugPrint('ConnectivityService reconnect task failed: $error');
    }

    // Superseded while we waited: a newer transition started, or the raw
    // signal reverted and [_onRawChanged] stood this one down. The flicker and
    // contradiction paths stay live for the *whole* window, floor and work
    // alike — not just the floor.
    if (seq != _seq) return;

    if (hitCeiling) {
      // Fail open on the best currently-known result.
      _pending = null;
      _committedOnline = true;
      _emitPhase();
      return;
    }

    if (!_isOnline) {
      // The work contradicted the report. Discard without committing.
      _pending = null;
      _emitPhase();
      return;
    }

    _pending = null;
    _committedOnline = true;
    _emitPhase();
  }

  /// Going away: a fixed perceptibility floor, then verify. No task list and
  /// no ceiling — there is nothing to wait for, so there is nothing to time
  /// out. Probing after the floor rather than at the start of it asks about
  /// the state that actually settled.
  Future<void> _confirmDisconnect(int seq) async {
    await Future<void>.delayed(disconnectConfirmationHold);
    if (seq != _seq) return;

    await checkNow();
    if (seq != _seq) return;

    if (_isOnline) {
      // The re-check contradicted the report. Discard without committing.
      _pending = null;
      _emitPhase();
      return;
    }

    _pending = null;
    _committedOnline = false;
    _emitPhase();
  }

  /// A person explicitly asking "check again" — the capsule's refresh button.
  ///
  /// Routed through the same confirming window as an automatic transition
  /// rather than through a private in-flight flag, so a tap produces the same
  /// visible state the rest of the app already understands. If the answer
  /// turns out to be a change, the normal confirmation takes over from here.
  Future<void> recheck() async {
    if (_probing) return;
    _probing = true;
    _emitPhase();
    try {
      await Future.wait([
        Future<void>.delayed(reconnectMinimumHold),
        checkNow(),
      ]);
    } finally {
      _probing = false;
      _emitPhase();
    }
  }

  void _emitPhase() {
    final next = phase;
    if (next == _lastEmittedPhase) return;
    _lastEmittedPhase = next;
    if (!_phaseController.isClosed) _phaseController.add(next);
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
    // Stands down any confirmation still counting: it will wake, see the
    // sequence has moved, and return without touching a closed controller.
    _seq++;
    _sub?.cancel();
    _sub = null;
    _controller.close();
    _phaseController.close();
  }
}
