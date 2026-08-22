/// The one tap-to-choose field used across the onboarding steps.
library;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';
import 'aurora_buttons.dart';

/// A tappable field that opens a picker: leading icon in a tonal circle, the
/// chosen value (or a muted placeholder), and a trailing chevron.
///
/// Steps 1 and 2 previously each had their own take on this — a flat tonal
/// bar for the birth year and a raised white card for the city — which made
/// two identical interactions look like two different kinds of control. This
/// is the single shared shape; the only thing a caller varies is the icon,
/// the copy, and whether a [subtitle] is shown.
class AuroraSelectField extends StatelessWidget {
  const AuroraSelectField({
    super.key,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;

  /// Null renders [placeholder] in the muted, unselected treatment.
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  /// Optional hint shown under a filled value, e.g. "اضغط للتغيير".
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;

    return AuroraPressable(
      onTap: onTap,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AuroraSpacing.lg),
        decoration: BoxDecoration(
          color: AuroraColors.surface,
          borderRadius: BorderRadius.circular(AuroraRadius.md),
          border: Border.all(
            width: 1.5,
            // A filled field warms its border toward the brand rather than
            // adding a checkmark — the value itself is the confirmation.
            color: selected
                ? AuroraColors.primary.withValues(alpha: 0.35)
                : AuroraColors.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AuroraColors.tonal,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AuroraColors.primary),
            ),
            const SizedBox(width: AuroraSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: selected
                        ? AuroraText.body(
                            size: AuroraFontSize.bodyLg,
                            weight: FontWeight.w700,
                          )
                        : AuroraText.body(
                            size: AuroraFontSize.bodyLg,
                            color: AuroraColors.muted,
                          ),
                  ),
                  if (selected && subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AuroraText.body(
                        size: AuroraFontSize.caption,
                        weight: FontWeight.w600,
                        color: AuroraColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AuroraSpacing.md),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AuroraColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
