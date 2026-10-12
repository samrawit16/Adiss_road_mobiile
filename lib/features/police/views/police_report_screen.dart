import 'package:flutter/material.dart';

import '../../report/views/report_form_screen.dart';

class PoliceReportScreen extends StatelessWidget {
  const PoliceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportFormScreen(initialType: 'other');
  }
}
