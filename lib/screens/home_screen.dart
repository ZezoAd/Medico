import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/connectivity_service.dart';
import '../services/profile_service.dart';
import '../widgets/global_offline_strip.dart';
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

  /// Owned here rather than inside a tab because it must outlive tab
  /// switches, and because the offline strip it feeds is app-wide chrome
  /// sitting above the [IndexedStack] rather than part of any one tab.
  late final ConnectivityService _connectivity;

  /// Whether [_connectivity] was built here, and so must be torn down here.
  /// An injected one outlives this screen and is the caller's to dispose.
  late final bool _ownsConnectivity;

  StreamSubscription<bool>? _onlineSub;

  /// Mirrors [ConnectivityService.isOnline] for `build`.
  ///
  /// A local field kept in sync, not a `StreamBuilder`: this file already
  /// holds every other piece of async state ([_profile], [_email],
  /// [_isSignedIn]) the same way, and the strip's visibility is one bool that
  /// several future consumers may want to read without another builder in the
  /// tree. Seeded from the service so the first frame agrees with it.
  late bool _isOnline;

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
    _isOnline = _connectivity.isOnline;
    _onlineSub = _connectivity.isOnlineStream.listen((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
    });
    // The plugin's change stream may not say anything until the network next
    // moves, so the first real answer is asked for outright.
    _connectivity.checkNow();

    _loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onlineSub?.cancel();
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
          // The strip sits above the IndexedStack, not inside any tab: being
          // offline is a fact about the device, so it must not vanish when the
          // person moves from Home to Bookings.
          //
          // Above each tab's header rather than below it, for two separate
          // reasons. Both are recorded because either one alone reads as
          // provisional, and this position is not.
          //
          // 1. Product: while the device is offline, the chrome it outranks is
          //    close to inert anyway. Home's top bar is a search field that
          //    cannot reach the doctor directory and a bell that cannot fetch
          //    a notification. Ranking a live statement about *why* nothing
          //    works above two controls that silently will not work is the
          //    intended order, not a compromise — the strip explains the dead
          //    search bar, so it has to be readable before it.
          //
          // 2. Structural: there is no per-tab header to sit below on three of
          //    the four tabs. Browse and Bookings are one centred Text apiece,
          //    and Profile scrolls its banner with its content; only HomeTab
          //    has a fixed top bar.
          //
          // Reason 2 expires once Browse and Bookings are built out. Reason 1
          // does not — so building those headers is not on its own a licence
          // to move the strip beneath them. That would need its own decision,
          // taken against the offline experience rather than against layout
          // tidiness.
          //
          // No padding wrapper here on purpose — the strip owns its own
          // margins ([GlobalOfflineStrip.topMargin] / `sideMargin`) so that it
          // can still collapse to genuinely zero space when hidden.
          child: Column(
            children: [
              GlobalOfflineStrip(visible: !_isOnline),
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    HomeTab(connectivityService: _connectivity),
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
