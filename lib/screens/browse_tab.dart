import 'package:flutter/material.dart';
import '../theme/aurora_tokens.dart';

/// Browse tab body. Placeholder — doctor search/listing lands here later.
class BrowseTab extends StatelessWidget {
  const BrowseTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'تصفح',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AuroraColors.secondary,
        ),
      ),
    );
  }
}
