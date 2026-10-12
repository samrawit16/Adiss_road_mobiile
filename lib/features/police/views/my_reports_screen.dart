import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/police_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Wait until the first frame is finished before
    // changing the Riverpod provider state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final reports = await ref
          .read(policeViewModelProvider.notifier)
          .loadMyReports();

      if (!mounted) return;

      setState(() {
        _reports = reports;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizations.of(context);

    return Scaffold(
      backgroundColor: appColors.bgLight,
      appBar: AppBar(
        title: Text(
          l10n.t('myReports'),
          style: TextStyle(
            color: appColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 260),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 220),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: appColors.danger,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: appColors.danger,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_reports.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'You have not submitted any reports yet.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        return _reportCard(_reports[index]);
      },
    );
  }

  Widget _reportCard(Map<String, dynamic> report) {
    final String status =
        report['status']?.toString().toLowerCase() ?? 'submitted';

    final Color statusColor = _statusColor(status);

    final String reportType =
        _typeLabel(report['report_type']?.toString() ?? 'report');

    final String roadName =
        report['road_name']?.toString() ?? 'GPS location';

    final String createdAt =
        _formatTime(report['created_at']?.toString() ?? '');

    final String severity =
        report['severity']?.toString() ?? 'unknown';

    final bool emergency = report['emergency_required'] == true;

    final String description =
        report['description']?.toString() ?? '';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.12),
              child: Icon(
                Icons.description,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$reportType · $roadName',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (createdAt.isNotEmpty)
                    Text(
                      createdAt,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    emergency
                        ? 'Severity: $severity · Emergency requested'
                        : 'Severity: $severity',
                    style: TextStyle(
                      color: emergency
                          ? appColors.danger
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'road_accident':
        return 'Traffic accident';
      case 'hazard':
        return 'Road hazard';
      case 'hit_and_run':
        return 'Hit and run';
      case 'vehicle_breakdown':
        return 'Vehicle breakdown';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  /// The server sends UTC ("...Z"). Show it in the phone's local time
  /// (Addis Ababa is UTC+3).
  String _formatTime(String raw) {
    if (raw.isEmpty) return '';

    var text = raw;
    final hasZone = RegExp(r'(Z|[+-]\d\d:?\d\d)$').hasMatch(text);
    if (!hasZone) text = '${text}Z';

    final parsed = DateTime.tryParse(text);
    if (parsed == null) return raw;

    final t = parsed.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    String two(int n) => n.toString().padLeft(2, '0');

    return '${t.day} ${months[t.month - 1]} ${t.year}, '
        '${two(t.hour)}:${two(t.minute)}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return appColors.success;

      case 'rejected':
        return appColors.danger;

      case 'under_review':
        return appColors.amber;

      case 'submitted':
      default:
        return appColors.navy;
    }
  }
}