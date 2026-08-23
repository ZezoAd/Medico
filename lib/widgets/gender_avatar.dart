/// The silhouette avatar that stands in for a profile photo.
library;

import 'package:flutter/material.dart';

import '../models/onboarding_data.dart';
import '../theme/aurora_tokens.dart';

/// A circular tonal disc with a person silhouette on top, tinted by the
/// signed-in patient's `profiles.gender`.
///
/// There is no avatar/photo column on `profiles` and none is planned yet, so
/// this is the only identity mark the app has. It is built once and used at
/// two sizes: 24 in the bottom nav's Profile destination and 80 in the Profile
/// banner. The disc keeps the mark legible at nav size, where a bare outline
/// glyph at 24px would read as just another Material icon rather than as
/// "you".
///
/// A null [gender] is a real, expected state — onboarding step 1 is skippable
/// — and resolves to [AuroraColors.avatarNeutral]. It must never guess.
class GenderAvatar extends StatelessWidget {
  const GenderAvatar({
    super.key,
    required this.gender,
    required this.size,
    this.filled = false,
  });

  final Gender? gender;

  /// Diameter of the disc. The silhouette scales with it.
  final double size;

  /// Solid silhouette instead of the outlined one — the nav bar's selected
  /// state, matching the outlined/`_rounded` swap the other three
  /// destinations already use.
  final bool filled;

  /// The full-saturation tint for a gender. Exposed so a caller that needs
  /// the colour without the whole disc (nav label tinting, for instance) does
  /// not re-derive the mapping.
  static Color colorFor(Gender? gender) => switch (gender) {
    Gender.male => AuroraColors.avatarMale,
    Gender.female => AuroraColors.avatarFemale,
    null => AuroraColors.avatarNeutral,
  };

  /// Alpha for the disc behind the silhouette. Kept translucent rather than a
  /// pre-mixed opaque tint so the disc sits correctly on both the cream app
  /// background and the nav bar's selected indicator pill.
  static const double _discAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(gender);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _discAlpha),
        shape: BoxShape.circle,
      ),
      child: Icon(
        filled ? Icons.person_rounded : Icons.person_outline_rounded,
        size: size * 0.58,
        color: color,
      ),
    );
  }
}
