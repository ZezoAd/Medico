// Standalone preview for QueueStatusCard — not wired into the real app.
// Run with:
//   flutter run -t lib/dev/queue_status_card_preview.dart
import 'package:flutter/material.dart';

import '../widgets/queue_status_card.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  QueueConnectionStatus _status = QueueConnectionStatus.live;
  late DateTime _recordedAt;

  @override
  void initState() {
    super.initState();
    _recordedAt = DateTime.now();
  }

  void _setStatus(QueueConnectionStatus status) {
    setState(() {
      // Freeze recordedAt exactly once, at the moment we leave `live` —
      // mirrors the contract QueueStatusCard.recordedAt documents.
      if (_status == QueueConnectionStatus.live &&
          status != QueueConnectionStatus.live) {
        _recordedAt = DateTime.now();
      }
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFFAF7F2),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QueueStatusCard(
                    doctorName: 'د. سارة الجبوري',
                    doctorLocation: 'الطابق الثاني، غرفة ٣',
                    doctorAvatarUrl: null,
                    patientsAhead: 5,
                    avgConsultMinutes: 12,
                    doctorQueuePosition: 6,
                    patientQueuePosition: 11,
                    connectionStatus: _status,
                    recordedAt: _recordedAt,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('opened detail sheet')),
                    ),
                    onRetry: () => _setStatus(QueueConnectionStatus.live),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in QueueConnectionStatus.values)
                        ChoiceChip(
                          label: Text(status.name),
                          selected: _status == status,
                          onSelected: (_) => _setStatus(status),
                        ),
                    ],
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
