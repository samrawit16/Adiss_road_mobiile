import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      ('Night Driving', 'Stay alert, avoid distractions.', Icons.dark_mode, appColors.navy),
      ('Rainy Season Tips', 'Slow down, increase distance.', Icons.water_drop, Colors.blue),
      ('Speed Limits', 'Know the limits, save lives.', Icons.speed, appColors.amber),
    ];
    return Scaffold(
      backgroundColor: appColors.bgLight,
      appBar: AppBar(
        title: Text('Safety Tips',
            style: TextStyle(color: appColors.navy, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: tips.map((t) => Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: t.$4.withOpacity(.12),
              child: Icon(t.$3, color: t.$4),
            ),
            title: Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(t.$2),
            trailing: Icon(Icons.bookmark_border, color: appColors.textMuted),
          ),
        )).toList(),
      ),
    );
  }
}
