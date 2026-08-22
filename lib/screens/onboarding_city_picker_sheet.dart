/// The governorate picker bottom sheet.
library;

import 'package:flutter/material.dart';

import '../theme/aurora_tokens.dart';

/// The 18 Iraqi governorates, in the order the design lists them.
const List<String> kGovernorates = [
  'بغداد',
  'البصرة',
  'نينوى',
  'أربيل',
  'السليمانية',
  'دهوك',
  'كركوك',
  'الأنبار',
  'ديالى',
  'صلاح الدين',
  'بابل',
  'كربلاء',
  'النجف',
  'واسط',
  'القادسية',
  'ميسان',
  'ذي قار',
  'المثنى',
];

/// Opens the city picker. Resolves to the chosen governorate, or to whatever
/// the patient typed if it matches none of them, or null if dismissed.
Future<String?> showOnboardingCityPicker(
  BuildContext context, {
  String? current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AuroraColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AuroraRadius.xl),
      ),
    ),
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _CityPickerSheet(current: current),
    ),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({required this.current});

  final String? current;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _matches {
    final query = _query.trim();
    if (query.isEmpty) return kGovernorates;
    return kGovernorates.where((g) => g.contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final query = _query.trim();

    // The governorate list is a convenience, not a whitelist. City is the one
    // required field in the flow, so a patient whose town is not one of the
    // 18 must still be able to answer — otherwise "required" becomes a trap
    // with no way forward.
    final showFreeform = query.isNotEmpty && !kGovernorates.contains(query);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
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
                  'اختر محافظتك',
                  style: AuroraText.display(size: AuroraFontSize.h3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AuroraSpacing.xl),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.done,
                onSubmitted: (v) {
                  final typed = v.trim();
                  if (typed.isNotEmpty) Navigator.of(context).pop(typed);
                },
                style: AuroraText.body(size: AuroraFontSize.bodyLg),
                decoration: InputDecoration(
                  hintText: 'ابحث أو اكتب اسم مدينتك',
                  hintStyle: AuroraText.body(
                    size: AuroraFontSize.bodyLg,
                    color: AuroraColors.muted,
                  ),
                  filled: true,
                  fillColor: AuroraColors.tonal,
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AuroraColors.secondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AuroraSpacing.lg,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AuroraRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AuroraSpacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                // Bottom inset as padding rather than a SafeArea wrapper, so
                // the list still scrolls *through* the gesture bar instead of
                // ending above it with dead space.
                padding: EdgeInsets.fromLTRB(
                  AuroraSpacing.xl,
                  0,
                  AuroraSpacing.xl,
                  AuroraSpacing.xl + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  if (showFreeform)
                    _CityRow(
                      label: 'استخدام "$query"',
                      selected: false,
                      leading: const Icon(
                        Icons.add_location_alt_outlined,
                        size: 20,
                        color: AuroraColors.primary,
                      ),
                      onTap: () => Navigator.of(context).pop(query),
                    ),
                  for (final name in matches)
                    _CityRow(
                      label: name,
                      selected: name == widget.current,
                      onTap: () => Navigator.of(context).pop(name),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AuroraColors.tonal : Colors.transparent,
        borderRadius: BorderRadius.circular(AuroraRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AuroraRadius.sm),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.all(AuroraSpacing.lg),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AuroraSpacing.md),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AuroraText.body(
                      size: AuroraFontSize.bodyLg,
                      weight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? AuroraColors.primary : AuroraColors.ink,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check,
                    size: 20,
                    color: AuroraColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: AuroraSpacing.md,
        bottom: AuroraSpacing.sm,
      ),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AuroraColors.divider,
        borderRadius: BorderRadius.circular(AuroraRadius.pill),
      ),
    );
  }
}
