import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class ReportTypeScreen extends StatelessWidget {
  const ReportTypeScreen({super.key});

  /// No statics: the list is an instance getter now.
  List<(String, String, IconData, Color, String)> get types => [
    ('Traffic Accident', 'Vehicle collision or crash', Icons.directions_car, appColors.danger, 'road_accident'),
    ('Road Hazard', 'Pothole, debris, obstruction or danger', Icons.construction, Colors.orange, 'hazard'),
    ('Hit and Run', 'A vehicle left after a collision', Icons.directions_car_filled, appColors.navy, 'hit_and_run'),
    ('Vehicle Breakdown', 'A disabled vehicle affecting road safety', Icons.car_repair, appColors.navy, 'vehicle_breakdown'),
    ('Other', 'Another road safety incident', Icons.report_problem_outlined, appColors.navy, 'other'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: appColors.navy),
        title: Text('Report an incident', style: TextStyle(color: appColors.navy, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Choose what you want to report', textAlign: TextAlign.center, style: TextStyle(color: appColors.textMuted)),
          const SizedBox(height: 24),
          ...types.map((t) => Card(
            color: Colors.white,
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: t.$4.withOpacity(.12), borderRadius: BorderRadius.circular(13)),
                child: Icon(t.$3, color: t.$4, size: 29),
              ),
              title: Text(t.$1, style: TextStyle(fontWeight: FontWeight.w800, color: appColors.navy)),
              subtitle: Text(t.$2),
              trailing: Icon(Icons.chevron_right, color: appColors.textMuted),
              onTap: () => context.push('/report/form?type=${t.$5}'),
            ),
          )),
        ],
      ),
    );
  }
}
