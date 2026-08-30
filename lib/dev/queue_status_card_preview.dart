// Standalone preview for QueueStatusCard — not wired into the real app.
// Run with:
//   flutter run -t lib/dev/queue_status_card_preview.dart
//
// Mirrors the three scenarios in design_reference/ConnectivityArchitecture
// so the card can be reviewed against it directly. The scenario switcher
// lives here, in the harness — the real card takes its state as parameters
// and has no switcher of its own.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/global_offline_strip.dart';
import '../widgets/queue_status_card.dart';

void main() => runApp(const _PreviewApp());

/// What the *device* and the *channel* are each doing. These are two
/// different facts, which is the whole point of the architecture.
enum _Scenario {
  /// Channel connected, device online.
  live('متصل'),

  /// Channel dropped, device still online — retry is meaningful here.
  channelDrop('انقطاع القناة فقط'),

  /// Device offline. Nothing to retry, so the card gets no retry button;
  /// the global strip states the device fact instead.
  noInternet('لا إنترنت كلياً');

  const _Scenario(this.label);
  final String label;
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  _Scenario _scenario = _Scenario.live;
  QueueConnectionStatus _status = QueueConnectionStatus.live;
  late DateTime _recordedAt = DateTime.now();

  /// Null unless the card is actually stale; otherwise the device-level
  /// scenario decides. `noInternet` is the only one that is unrecoverable by
  /// retrying, so it is the only one that yields
  /// [StalenessReason.deviceOffline] — including when the raw status chips
  /// below force `stale` while the device is notionally online.
  StalenessReason? get _stalenessReason {
    if (_status != QueueConnectionStatus.stale) return null;
    return _scenario == _Scenario.noInternet
        ? StalenessReason.deviceOffline
        : StalenessReason.channelDrop;
  }

  void _setScenario(_Scenario scenario) {
    setState(() {
      _scenario = scenario;
      final next = switch (scenario) {
        _Scenario.live => QueueConnectionStatus.live,
        // A channel drop shows the retry badge first, then goes stale — the
        // preview jumps straight to `retrying` and the card's own ring
        // paces the window.
        _Scenario.channelDrop => QueueConnectionStatus.retrying,
        // No internet skips retrying entirely; there is nothing to retry.
        _Scenario.noInternet => QueueConnectionStatus.stale,
      };

      // Freeze recordedAt exactly once, at the moment we leave `live` —
      // mirrors the contract QueueStatusCard.recordedAt documents.
      if (_status == QueueConnectionStatus.live &&
          next != QueueConnectionStatus.live) {
        _recordedAt = DateTime.now();
      }
      _status = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Themed so the card resolves the same [AuroraPalette] it does in the app.
    // This harness is about connectivity scenarios, not appearance, so it
    // stays pinned to light — `home_empty_state_card_preview.dart` is the one
    // with the light/dark switcher.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final scenario in _Scenario.values)
                        ChoiceChip(
                          label: Text(scenario.label),
                          selected: _scenario == scenario,
                          onSelected: (_) => _setScenario(scenario),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlobalOfflineStrip(
                    visible: _scenario == _Scenario.noInternet,
                  ),
                  const SizedBox(height: 16),
                  QueueStatusCard(
                    doctorName: 'د. سارة الجبوري',
                    doctorLocation: 'الطابق الثاني، غرفة ٣',
                    doctorAvatarUrl: null,
                    patientsAhead: 5,
                    avgConsultMinutes: 5,
                    doctorQueuePosition: 6,
                    patientQueuePosition: 11,
                    connectionStatus: _status,
                    // Stated explicitly rather than inferred from whether
                    // onRetry happens to be null.
                    stalenessReason: _stalenessReason,
                    recordedAt: _recordedAt,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('opened detail sheet')),
                    ),
                    onRetry: () => _setScenario(_Scenario.live),
                  ),
                  const SizedBox(height: 24),
                  // Drives the card's own badge/frozen states directly,
                  // independent of the device-level scenario above.
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in QueueConnectionStatus.values)
                        ChoiceChip(
                          label: Text(status.name),
                          selected: _status == status,
                          onSelected: (_) => setState(() {
                            if (_status == QueueConnectionStatus.live &&
                                status != QueueConnectionStatus.live) {
                              _recordedAt = DateTime.now();
                            }
                            _status = status;
                          }),
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
