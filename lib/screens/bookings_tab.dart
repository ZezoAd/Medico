import 'package:flutter/material.dart';
import '../theme/aurora_tokens.dart';

/// Bookings tab body. Placeholder — appointment history/upcoming lands here
/// later.
class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'الحجوزات',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AuroraColors.secondary,
        ),
      ),
    );
  }
}
