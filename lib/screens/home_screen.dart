import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/connectivity_service.dart';
import '../services/profile_service.dart';
import '../widgets/offline_status_capsule.dart';
import 'bookings_tab.dart';
import 'browse_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

/// Root shell landed on by signup, sign-in (Google and email/password), and
/// SplashScreen's cold-start session check — bottom nav across the app's
/// four top-level sections. The Browse and Bookings tab bodies are still
/// placeholders.
///
/// Also the single owner of the `profiles` read that the Profile tab and its
/// nav icon both need. `AuthGate` deliberately throws its own copy away once
/// it has routed, so there is nothing cached to reuse; fetching here rather
/// than inside `ProfileTab` keeps it to one round trip and keeps the nav
/// avatar tinted even before the tab is first opened.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSignedOut, this.connectivityService});

  /// Called after the Profile tab signs the session out, so `AuthGate` can
  /// re-resolve and land on the sign-in screen.
  ///
  /// A callback rather than an `onAuthStateChange` listener on purpose: the
  /// gate already signs out on two of its own failure paths and attaches an
  /// explanatory message to each, and a listener would race those and blank
  /// the message out.
  final Future<void> Function()? onSignedOut;

  /// Test seam. Null — the production case — means this screen builds and owns
  /// its own [ConnectivityService]; an injected one belongs to the caller and
  /// is never disposed here. Exists because the real service reaches
  /// `connectivity_plus`'s platform channels the moment it is constructed,
  /// which no widget test can satisfy.
  final ConnectivityService? connectivityService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tabIndex = 0;

  /// Bookings' position in both the [IndexedStack] children and the
  /// [NavigationBar] destinations below — the two lists are index-matched, so
  /// this is one number, not two.
  ///
  /// Named rather than written as a bare `2` at the call site, so a section
  /// inserted into that pair cannot silently repoint Home's
  /// "عرض السجل الكامل" at Browse.
  static const int _bookingsTabIndex = 2;

  /// Owned here rather than inside a tab because it must outlive tab
  /// switches, and because the offline strip it feeds is app-wide chrome
  /// sitting above the [IndexedStack] rather than part of any one tab.
  late final ConnectivityService _connectivity;

  /// Whether [_connectivity] was built here, and so must be torn down here.
  /// An injected one outlives this screen and is the caller's to dispose.
  late final bool _ownsConnectivity;

  StreamSubscription<ConnectivityPhase>? _phaseSub;

  /// Mirrors [ConnectivityService.phase] for `build`.
  ///
  /// The *committed* phase, not the raw bool: the capsule must stay on screen
  /// through the confirmation window rather than disappearing the instant the
  /// platform mentions a network.
  ///
  /// A local field kept in sync, not a `StreamBuilder`: this file already
  /// holds every other piece of async state ([_profile], [_email],
  /// [_isSignedIn]) the same way. Seeded from the service so the first frame
  /// agrees with it.
  late ConnectivityPhase _phase;

  UserProfile? _profile;

  /// Read once alongside the profile. `profiles.phone` is nullable, and for a
  /// Google account it usually is, so the session email is the fallback the
  /// Profile banner shows instead.
  String? _email;

  /// Whether a session existed when [_loadProfile] ran.
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ownsConnectivity = widget.connectivityService == null;
    _connectivity = widget.connectivityService ?? ConnectivityService();
    _phase = _connectivity.phase;
    _phaseSub = _connectivity.phaseStream.listen((phase) {
      if (!mounted) return;
      setState(() => _phase = phase);
    });
    // The plugin's change stream may not say anything until the network next
    // moves, so the first real answer is asked for outright.
    _connectivity.checkNow();

    _loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phaseSub?.cancel();
    if (_ownsConnectivity) _connectivity.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Android does not reliably deliver network changes to a backgrounded
    // process, so what the service was last told may be stale by the time the
    // app is looked at again. Re-asking on resume is the only way the strip is
    // correct on the first frame after a return.
    if (state == AppLifecycleState.resumed) {
      _connectivity.checkNow();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final profile = user == null
          ? null
          : await const ProfileService().fetchCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _email = user?.email;
        _isSignedIn = user != null;
      });
    } catch (_) {
      // A failed read is not worth interrupting Home for — the avatar simply
      // stays neutral and the banner falls back to its placeholders. Swallows
      // the "Supabase not initialised" case too, which is how a dev preview
      // reaches this screen without an .env.
      if (!mounted) return;
      setState(() {
        _profile = null;
        _email = null;
        _isSignedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gender = _profile?.gender;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        body: SafeArea(
          // Two rows: the tab content, then the offline capsule docked under
          // it. Being offline is a fact about the *device*, so the capsule
          // lives out here in the shell rather than inside any tab — it must
          // not vanish when the person moves from Home to Bookings.
          //
          // It is the LAST child on purpose, so it lands directly above
          // `bottomNavigationBar`. Superseded the top-of-screen strip that used
          // to be the first child, for two reasons:
          //
          // 1. Product: docked by the nav bar it sits where the thumb already
          //    is, so its "تحديث" is reachable one-handed, and it is out of the
          //    reading path of whatever heading a screen opens with. At the top
          //    it displaced the first thing every screen wanted to say.
          // 2. Structural: the bottom nav is one Scaffold-level element shared
          //    by all four tabs, so "below the shared chrome" is unambiguous
          //    here in a way "below the header" never was — Browse and Bookings
          //    have no header at all, and Profile scrolls its banner with its
          //    content.
          //
          // A Stack, not a Column. The capsule floats *over* the tab content
          // rather than taking a reserved row of its own, so a message that is
          // usually absent no longer re-lays-out the page underneath it every
          // time it appears — it reads as a mini-player bar riding above the
          // content, which is the arrangement it is modelled on.
          //
          // The cost of dropping the Column is that nothing reclaims the space
          // automatically any more. A scroll view that wants its last item
          // reachable adds [OfflineStatusCapsule.overlayClearance] to its
          // bottom padding while the capsule is showing; `home_tab.dart` does.
          //
          // No padding wrapper here on purpose — the capsule owns its own
          // margins ([OfflineStatusCapsule.sideMargin] / `verticalMargin`) so
          // that it still occupies nothing at all while hidden.
          child: Stack(
            fit: StackFit.expand,
            children: [
              IndexedStack(
                index: _tabIndex,
                children: [
                  HomeTab(
                    connectivityService: _connectivity,
                    // Home's previously-visited section points at the full
                    // history, which lives on Bookings. Routed through the same
                    // `_tabIndex` setState the nav bar itself uses, so the two
                    // ways of reaching that tab cannot drift apart.
                    onOpenBookings: () =>
                        setState(() => _tabIndex = _bookingsTabIndex),
                  ),
                  const BrowseTab(),
                  const BookingsTab(),
                  ProfileTab(
                    isSignedIn: _isSignedIn,
                    gender: gender,
                    fullName: _profile?.fullName,
                    phone: _profile?.phone,
                    email: _email,
                    onSignOut: _signOut,
                  ),
                ],
              ),
              // Pinned to the bottom of the body, so it lands just above the
              // nav bar and floats over whichever tab is showing.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: OfflineStatusCapsule(
                  phase: _phase,
                  // Routed through `recheck` rather than `checkNow` so a tap
                  // enters the same confirming window an automatic transition
                  // does, instead of a private disabled-while-in-flight state
                  // only this button would understand.
                  onRefresh: _connectivity.recheck,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: 'تصفح',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'الحجوزات',
            ),
            const NavigationDestination(
              // Plain outlined/filled glyph pair, exactly like the other
              // three. It deliberately carries no avatar disc and no
              // gender tint: a permanent tonal circle here read as a
              // selected tab even when it wasn't, since NavigationBar
              // already supplies the only container this row should have —
              // the indicator pill behind whichever tab is active.
              // Gender-tinted avatars are deferred to v2 alongside real
              // photo uploads.
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    await widget.onSignedOut?.call();
  }
}
