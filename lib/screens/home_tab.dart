import 'package:flutter/material.dart';
import '../theme/aurora_tokens.dart';

/// Home tab body. Placeholder — the real content (live queue status card,
/// etc.) is being built separately and wires in here later.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'الرئيسية',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AuroraColors.secondary,
        ),
      ),
    );
  }
}
