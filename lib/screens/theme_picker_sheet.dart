/// The appearance picker bottom sheet — النظام / فاتح / داكن.
library;

import 'package:flutter/material.dart';

import '../services/theme_service.dart';
import '../theme/aurora_tokens.dart';

/// Opens the appearance picker.
///
/// A sheet rather than an inline control because that is what the settings
/// card already advertises: every row carries a chevron, which promises a
/// destination. Modelled on `onboarding_city_picker_sheet.dart` — same handle,
/// same title treatment, same selected-row fill — so it reads as the same
/// component family rather than a second picker idiom.
///
/// Applies immediately on tap and closes; there is no confirm step. The change
/// is visible behind the sheet as it dismisses, which is its own confirmation,
/// and it is trivially reversible.
Future<void> showThemePickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Colour, shape and elevation come from `bottomSheetTheme` now, so they
    // follow the active theme instead of being pinned to the light surface.
    builder: (_) => const Directionality(
      textDirection: TextDirection.rtl,
      child: _ThemePickerSheet(),
    ),
  );
}

/// The three modes, in the order the sheet lists them.
const _options = <(ThemeMode, String, IconData)>[
  (ThemeMode.system, 'النظام', Icons.brightness_auto_outlined),
  (ThemeMode.light, 'فاتح', Icons.light_mode_outlined),
  (ThemeMode.dark, 'داكن', Icons.dark_mode_outlined),
];

/// The Arabic label for [mode], for the settings row's trailing value.
String themeModeLabel(ThemeMode mode) =>
    _options.firstWhere((o) => o.$1 == mode).$2;

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(color: palette.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AuroraSpacing.xxl,
              AuroraSpacing.xs,
              AuroraSpacing.xxl,
              AuroraSpacing.md,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'المظهر',
                style: AuroraText.display(
                  size: AuroraFontSize.h3,
                  color: palette.ink,
                ),
              ),
            ),
          ),
          // Rebuilds with the controller so the checkmark lands on the tapped
          // row before the sheet finishes dismissing.
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.instance,
            builder: (context, current, _) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AuroraSpacing.lg,
                0,
                AuroraSpacing.lg,
                AuroraSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (mode, label, icon) in _options)
                    _ThemeOptionTile(
                      label: label,
                      icon: icon,
                      selected: mode == current,
                      onTap: () {
                        ThemeController.instance.setMode(mode);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AuroraSpacing.md),
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AuroraRadius.pill),
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.aurora;
    final radius = BorderRadius.circular(AuroraRadius.sm);
    final ink = selected ? AuroraColors.primary : palette.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? palette.tonal : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Semantics(
            selected: selected,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.all(AuroraSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? AuroraColors.primary : palette.secondary,
                  ),
                  const SizedBox(width: AuroraSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AuroraText.body(
                        size: AuroraFontSize.bodyLg,
                        weight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: ink,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: AuroraColors.primary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
