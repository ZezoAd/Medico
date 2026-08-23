import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../widgets/gender_avatar.dart';
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
  const HomeScreen({super.key, this.onSignedOut});

  /// Called after the Profile tab signs the session out, so `AuthGate` can
  /// re-resolve and land on the sign-in screen.
  ///
  /// A callback rather than an `onAuthStateChange` listener on purpose: the
  /// gate already signs out on two of its own failure paths and attaches an
  /// explanatory message to each, and a listener would race those and blank
  /// the message out.
  final Future<void> Function()? onSignedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

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
    _loadProfile();
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
          child: IndexedStack(
            index: _tabIndex,
            children: [
              const HomeTab(),
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
            NavigationDestination(
              // 24 matches the Material default the other three icons render
              // at, so the avatar sits on the same optical baseline inside
              // the selected-indicator pill. The outlined/filled swap is the
              // same state treatment they use — no new pattern here.
              icon: GenderAvatar(gender: gender, size: _navIconSize),
              selectedIcon: GenderAvatar(
                gender: gender,
                size: _navIconSize,
                filled: true,
              ),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }

  /// Material's default `NavigationBar` icon size.
  static const double _navIconSize = 24;

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    await widget.onSignedOut?.call();
  }
}
