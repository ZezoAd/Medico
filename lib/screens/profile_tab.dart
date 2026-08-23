/// The bottom nav's fourth tab — the patient's own profile and settings.
library;

import 'package:flutter/material.dart';

import '../models/onboarding_data.dart';
import '../theme/aurora_tokens.dart';
import '../widgets/gender_avatar.dart';

/// Banner plus settings list, in one scroll view.
///
/// Deliberately *not* a banner that opens a nested settings screen behind a
/// second tap: there are five rows in total, which is far too few to justify
/// a route of their own. Everything the tab does is visible at once.
///
/// A dumb widget — it takes already-resolved strings and never reads Supabase
/// itself. [HomeScreen] owns the single `profiles` fetch and feeds both this
/// screen and the nav bar's avatar icon from it, so there is exactly one read
/// per session rather than one per consumer.
class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.isSignedIn,
    required this.gender,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.onSignOut,
  });

  /// False only in the development edge case where the tab is reached without
  /// a session. Suppresses the sign-out row and shows [_notSignedInName].
  final bool isSignedIn;

  /// `profiles.gender`. Null tints the avatar neutral — never a guess.
  final Gender? gender;

  /// `profiles.full_name`. Null or blank falls back to [_fallbackName].
  final String? fullName;

  /// `profiles.phone`, preferred for the contact line.
  final String? phone;

  /// The auth session email, used only when [phone] is missing.
  final String? email;

  /// Signs the session out. Routing afterwards is `AuthGate`'s job — this
  /// screen never navigates.
  final Future<void> Function() onSignOut;

  /// Shown when the profile row has no usable name. Every account has a row,
  /// but `full_name` is copied from auth metadata that a provider may not
  /// have supplied.
  static const _fallbackName = 'مستخدم';

  /// Shown when neither a phone number nor a session email exists.
  static const _fallbackContact = 'غير متوفر';

  /// Shown in place of a name when there is no session at all.
  static const _notSignedInName = 'غير مسجل';

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  /// Guards against a second tap while `signOut()` is in flight. Without it a
  /// double tap fires two sign-outs and the second throws into nothing.
  bool _signingOut = false;

  Future<void> _handleSignOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  String get _displayName {
    if (!widget.isSignedIn) return ProfileTab._notSignedInName;
    final name = widget.fullName?.trim();
    return (name == null || name.isEmpty) ? ProfileTab._fallbackName : name;
  }

  /// Phone first, session email second, placeholder third.
  String get _displayContact {
    final phone = widget.phone?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    final email = widget.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return ProfileTab._fallbackContact;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AuroraSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileBanner(
            // Without a session there is nothing to colour by, so the
            // neutral disc is the honest mark regardless of what a stale
            // profile object might still be holding.
            gender: widget.isSignedIn ? widget.gender : null,
            name: _displayName,
            contact: _displayContact,
          ),
          const SizedBox(height: AuroraSpacing.lg),
          _SettingsCard(
            signOutEnabled: widget.isSignedIn,
            signingOut: _signingOut,
            onSignOut: _handleSignOut,
          ),
        ],
      ),
    );
  }
}

/// Avatar, name, contact line and an edit affordance.
class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({
    required this.gender,
    required this.name,
    required this.contact,
  });

  final Gender? gender;
  final String name;
  final String contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AuroraSpacing.lg),
      decoration: BoxDecoration(
        color: AuroraColors.surface,
        borderRadius: BorderRadius.circular(AuroraRadius.lg),
        boxShadow: AuroraShadows.card,
      ),
      // RTL puts the avatar at the visual right, the text block beside it and
      // the pencil at the far left — the mirror of the LTR mock, which is the
      // intended reading order for an Arabic-first layout.
      child: Row(
        children: [
          GenderAvatar(gender: gender, size: 80),
          const SizedBox(width: AuroraSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AuroraText.body(size: 18, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AuroraSpacing.xs),
                Text(
                  contact,
                  style: AuroraText.body(
                    size: 14,
                    color: AuroraColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AuroraSpacing.sm),
          // INERT. No edit-profile screen exists yet, so this is the
          // affordance only — deliberately not an IconButton, which would
          // ripple and imply it did something.
          const Icon(Icons.edit_outlined, size: 20, color: AuroraColors.muted),
        ],
      ),
    );
  }
}

/// The five settings rows. Only the last one does anything.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.signOutEnabled,
    required this.signingOut,
    required this.onSignOut,
  });

  final bool signOutEnabled;
  final bool signingOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuroraColors.surface,
        borderRadius: BorderRadius.circular(AuroraRadius.lg),
        boxShadow: AuroraShadows.card,
      ),
      // Clips the sign-out row's ripple to the card's rounded corners.
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _SettingsRow(
            icon: Icons.notifications_none_rounded,
            label: 'إشعاراتي',
          ),
          const _RowDivider(),
          // The Arabic/Western numeral switch itself is separate work; this
          // is only its entry point.
          const _SettingsRow(icon: Icons.pin_outlined, label: 'الأرقام'),
          const _RowDivider(),
          const _SettingsRow(
            icon: Icons.headset_mic_outlined,
            label: 'تواصل معنا',
          ),
          const _RowDivider(),
          // The document does not exist yet.
          const _SettingsRow(
            icon: Icons.description_outlined,
            label: 'الشروط والأحكام',
          ),
          const _RowDivider(),
          _SignOutRow(
            enabled: signOutEnabled,
            busy: signingOut,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

/// An inert settings row.
///
/// Has no [InkWell] on purpose. Every one of these is a placeholder for a
/// destination that has not been built, and a ripple would promise a tap
/// target that does nothing — so the row is a plain layout, not a disabled
/// button.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.lg,
        vertical: AuroraSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AuroraColors.secondary),
          const SizedBox(width: AuroraSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AuroraText.body(size: 15, weight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Points away from the text, i.e. leftward under RTL.
          const Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: AuroraColors.muted,
          ),
        ],
      ),
    );
  }
}

/// The one functional row.
class _SignOutRow extends StatelessWidget {
  const _SignOutRow({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = enabled ? AuroraColors.danger : AuroraColors.disabledInk;

    return InkWell(
      onTap: enabled && !busy ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.lg,
          vertical: AuroraSpacing.lg,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: busy
                  ? CircularProgressIndicator(strokeWidth: 2, color: ink)
                  : Icon(Icons.logout_rounded, size: 20, color: ink),
            ),
            const SizedBox(width: AuroraSpacing.md),
            Expanded(
              child: Text(
                'تسجيل الخروج',
                style: AuroraText.body(
                  size: 15,
                  weight: FontWeight.w500,
                  color: ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: AuroraSpacing.lg,
      endIndent: AuroraSpacing.lg,
      color: AuroraColors.divider,
    );
  }
}
