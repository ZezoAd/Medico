/// The pill slider above the auth card.
library;

import 'package:flutter/material.dart';

/// A two-tab segmented control that rides on the auth screens' gradient
/// backdrop, above the white card.
///
/// Lifted verbatim out of `sign_in_page.dart`, where it was the
/// مستخدم/طبيب role switcher — same container, same 250ms `easeOut` slide,
/// same active/inactive text treatment. Only what the tabs *mean* changed:
/// they now move between Sign In and Sign Up.
///
/// Shared rather than copied into each screen because the two sit one tap
/// apart: the control has to look identical across that boundary or the slide
/// reads as the whole page jumping, and two copies would drift the first time
/// either is touched.
///
/// Purely presentational — it holds no selection state. Each screen passes
/// its own fixed [selectedIndex] and handles [onSelected] by navigating,
/// which is why tapping the already-active tab is a no-op rather than a
/// route push.
class AuthTabSwitcher extends StatelessWidget {
  const AuthTabSwitcher({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Exactly two labels. Under RTL the first renders on the visual right.
  final List<String> labels;

  final int selectedIndex;

  /// Fired for any tab, including the active one — callers ignore that case.
  final ValueChanged<int> onSelected;

  /// Active label colour. A deepened teal, because the pill behind it is
  /// solid white and [AuroraColors.primary] does not hold at 14px on white.
  static const _activeInk = Color(0xFF12664C);

  @override
  Widget build(BuildContext context) {
    assert(labels.length == 2, 'AuthTabSwitcher renders exactly two tabs');

    // Fixed outer height (38 tab + 4+4 padding). Nothing queries intrinsics,
    // but the strip is a fixed-height control regardless, so it stays pinned
    // here rather than being re-derived from the slider's inner layout.
    return SizedBox(
      height: 46,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 2;
            return SizedBox(
              height: 38,
              child: Stack(
                children: [
                  // Sliding white pill behind the active tab. Positioned from
                  // `right` because index 0 is the RTL-leading tab.
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    right: selectedIndex == 1 ? tabWidth : 0,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        _Tab(
                          label: labels[i],
                          active: selectedIndex == i,
                          onTap: () => onSelected(i),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active
                  ? AuthTabSwitcher._activeInk
                  : Colors.white.withValues(alpha: 0.8),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
