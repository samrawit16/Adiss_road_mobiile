import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/live_safety_viewmodel.dart';
import '../../../core/localization/app_localizations.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(liveSafetyProvider);
    final l10n = appLocalizations.of(context);

    return Scaffold(
      backgroundColor: appColors.bgLight,
      appBar: AppBar(
        title: Text(
          l10n.t('liveRoadSafety'),
          style: TextStyle(color: appColors.navy, fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!vm.isMonitoring) await vm.startMonitoring();
        },
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _statusCard(vm),
            const SizedBox(height: 14),
            if (vm.isSpeeding) _dangerCard(vm),
            if (vm.isSpeeding) const SizedBox(height: 14),
            _speedCard(vm),
            const SizedBox(height: 14),
            _roadCard(vm),
            const SizedBox(height: 14),
            _nearbyAlertsCard(vm),
            if (vm.errorMessage != null) ...[
              const SizedBox(height: 14),
              _messageCard(vm.errorMessage!),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: vm.isLoading
                  ? null
                  : () => vm.isMonitoring
                      ? vm.stopMonitoring()
                      : vm.startMonitoring(),
              icon: Icon(vm.isMonitoring ? Icons.stop : Icons.gps_fixed),
              label: Text(vm.isMonitoring ? 'Stop Live Safety' : 'Turn On GPS Safety'),
              style: FilledButton.styleFrom(
                backgroundColor: vm.isMonitoring ? appColors.danger : appColors.navy,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'When GPS is active, the app checks the current road speed limit. If your speed goes above that limit, the danger warning and repeated sound stay active until your speed returns to the safe range.',
              textAlign: TextAlign.center,
              style: TextStyle(color: appColors.textMuted, fontSize: 12, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(LiveSafetyViewModel vm) {
    final active = vm.isMonitoring;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? appColors.success.withOpacity(.35) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (active ? appColors.success : appColors.navy).withOpacity(.1),
            child: Icon(active ? Icons.gps_fixed : Icons.gps_off, color: active ? appColors.success : appColors.navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(active ? 'GPS safety is active' : 'GPS safety is off', style: TextStyle(fontWeight: FontWeight.w800, color: appColors.navy)),
              const SizedBox(height: 4),
              Text(active ? 'Monitoring your driving speed' : 'Turn on GPS to begin monitoring', style: TextStyle(color: appColors.textMuted)),
            ]),
          ),
          if (vm.isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _dangerCard(LiveSafetyViewModel vm) {
    final limit = vm.context?.speedLimitKmh;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appColors.danger.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appColors.danger.withOpacity(.45), width: 1.5),
      ),
      child: Row(children: [
        CircleAvatar(radius: 25, backgroundColor: appColors.danger, child: Icon(Icons.warning_rounded, color: Colors.white, size: 30)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DANGER — SLOW DOWN', style: TextStyle(color: appColors.danger, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 5),
          Text('You are ${vm.speedKmh.toStringAsFixed(0)} km/h${limit == null ? '' : ' · limit ${limit.toStringAsFixed(0)} km/h'}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(vm.soundEnabled ? 'Warning sound is active until your speed returns below the road limit.' : 'Slow down until your speed is below the road limit.', style: TextStyle(color: appColors.textMuted, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _speedCard(LiveSafetyViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: appColors.navy, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Icon(Icons.speed, color: appColors.amber, size: 34),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CURRENT SPEED', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
          Text('${vm.speedKmh.toStringAsFixed(0)} km/h', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Widget _roadCard(LiveSafetyViewModel vm) {
    final c = vm.context;
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Road information', style: TextStyle(color: appColors.navy, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          _row(Icons.route, 'Road', c?.roadName ?? 'Waiting for GPS road data'),
          _row(Icons.alt_route, 'Road type', c?.highwayType ?? 'Not available yet'),
          _row(Icons.speed, 'Speed limit', c?.speedLimitKmh == null ? 'Not available yet' : '${c!.speedLimitKmh!.toStringAsFixed(0)} km/h'),
          _row(Icons.source, 'Limit source', c?.speedLimitSource ?? 'Waiting for road data'),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [Icon(icon, size: 19, color: appColors.amber), const SizedBox(width: 10), Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)), Expanded(child: Text(value, style: TextStyle(color: appColors.textMuted)))],),
  );

  Widget _nearbyAlertsCard(LiveSafetyViewModel vm) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nearby road alerts', style: TextStyle(color: appColors.navy, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          if (!vm.nearbyAlertsEnabled)
            Text('Nearby incident alerts are turned off. You can turn them on in Profile > Settings > Notifications.', style: TextStyle(color: appColors.textMuted))
          else if (vm.nearbyAlerts.isEmpty)
            Text('No active community reports were found nearby.', style: TextStyle(color: appColors.textMuted))
          else
            ...vm.nearbyAlerts.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded, color: appColors.amber, size: 21),
                const SizedBox(width: 9),
                Expanded(child: Text('${a['report_type'] ?? 'Road report'} · ${a['road_name'] ?? 'Nearby location'}\n${a['severity'] ?? 'unknown'}', style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            )),
        ]),
      ),
    );
  }

  Widget _messageCard(String message) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Text(message, style: TextStyle(color: appColors.textMuted)),
  );
}
