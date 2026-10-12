import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/police_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class PoliceInfoScreen extends ConsumerStatefulWidget {
  const PoliceInfoScreen({super.key});

  @override
  ConsumerState<PoliceInfoScreen> createState() =>
      _PoliceInfoScreenState();
}

class _PoliceInfoScreenState extends ConsumerState<PoliceInfoScreen> {
  List<Map<String, dynamic>> _authorities = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Do not load data while the widget tree is being built.
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
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Turn on GPS to find nearby authorities.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final authorities = await ref
          .read(policeViewModelProvider.notifier)
          .loadAuthorities(
            latitude: position.latitude,
            longitude: position.longitude,
          );

      if (!mounted) return;

      setState(() {
        _authorities = authorities;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizations.of(context);

    final police = _authorities
        .where(
          (a) => a['authority_type'] == 'police',
        )
        .toList();

    final emergency = _authorities
        .where(
          (a) => a['authority_type'] != 'police',
        )
        .toList();

    return Scaffold(
      backgroundColor: appColors.bgLight,
      appBar: AppBar(
        title: Text(
          l10n.t('nearbyAuthorities'),
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) _errorCard(_error!),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!_loading && _error == null) ...[
              _section(
                'Police and traffic authorities',
                police,
              ),
              const SizedBox(height: 20),
              _section(
                'Emergency and support',
                emergency,
              ),
              const SizedBox(height: 20),
            ],

            OutlinedButton.icon(
              onPressed: () => context.push('/police/report'),
              icon: const Icon(Icons.report),
              label: const Text('Submit a report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: appColors.navy,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () =>
                  context.push('/police/my-reports'),
              child: Text(
                'View my reports',
                style: TextStyle(
                  color: appColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    String title,
    List<Map<String, dynamic>> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: appColors.navy,
          ),
        ),

        const SizedBox(height: 10),

        if (rows.isEmpty)
          Text(
            'No nearby authority data is available.',
            style: TextStyle(
              color: appColors.textMuted,
            ),
          ),

        ...rows.map(
          (a) => Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
              side: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0x12173350),
                child: Icon(
                  Icons.local_police,
                  color: appColors.navy,
                ),
              ),
              title: Text(
                a['name']?.toString() ?? 'Authority',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${a['distance_km'] ?? '—'} km'
                '${a['coverage_area'] == null ? '' : ' · ${a['coverage_area']}'}',
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.phone,
                  color: appColors.amber,
                ),
                onPressed: () =>
                    _call(a['phone']?.toString()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: appColors.danger,
        ),
      ),
    );
  }
}