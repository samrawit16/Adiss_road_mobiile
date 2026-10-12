import 'dart:math' as math;
import '../../../core/constants/api_constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../severity/data/severity_prediction_model.dart';
import '../viewmodels/risk_map_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class _SubCity {
  const _SubCity(this.name, this.center);

  final String name;
  final LatLng center;
}

const _subCities = <_SubCity>[
  _SubCity('Bole', LatLng(8.9955, 38.7890)),
  _SubCity('Yeka', LatLng(9.0400, 38.8200)),
  _SubCity('Kirkos', LatLng(9.0000, 38.7600)),
  _SubCity('Arada', LatLng(9.0350, 38.7500)),
  _SubCity('Lideta', LatLng(9.0100, 38.7350)),
  _SubCity('Nifas Silk-Lafto', LatLng(8.9550, 38.7100)),
  _SubCity('Kolfe Keranio', LatLng(9.0100, 38.6800)),
  _SubCity('Gullele', LatLng(9.0800, 38.7200)),
  _SubCity('Akaki Kaliti', LatLng(8.8800, 38.7900)),
  _SubCity('Addis Ketema', LatLng(9.0300, 38.7350)),
];

class RiskMapScreen extends ConsumerStatefulWidget {
  const RiskMapScreen({super.key});

  @override
  ConsumerState<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends ConsumerState<RiskMapScreen> {
  final MapController _mapController = MapController();

  LatLng? _selectedPoint;
  String? _selectedSubCity;
  SeverityPrediction? _prediction;

  bool _loading = false;
  String? _error;

  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 30);

  String _junction = 'Y Shape';
  String _roadSurface = 'Asphalt roads';
  String _roadCondition = 'Dry';
  String _light = 'Daylight';
  String _collision = 'Vehicle with vehicle collision';
  String _movement = 'Going straight';

  bool get _isPeak =>
      (_time.hour >= 7 && _time.hour < 9) ||
      (_time.hour >= 16 && _time.hour < 18);

  _SubCity _nearestSubCity(LatLng point) {
    double best = double.infinity;
    _SubCity result = _subCities.first;

    for (final city in _subCities) {
      final dLat = point.latitude - city.center.latitude;

      final dLon = (point.longitude - city.center.longitude) *
          math.cos(point.latitude * math.pi / 180);

      final distance = dLat * dLat + dLon * dLon;

      if (distance < best) {
        best = distance;
        result = city;
      }
    }

    return result;
  }

  void _onMapTap(TapPosition _, LatLng point) {
    final city = _nearestSubCity(point);

    setState(() {
      _selectedPoint = point;
      _selectedSubCity = city.name;
      _prediction = null;
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (value != null) {
      setState(() {
        _date = value;
        _prediction = null;
        _error = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _time,
    );

    if (value != null) {
      setState(() {
        _time = value;
        _prediction = null;
        _error = null;
      });
    }
  }

  String _timePeriod() {
    if (_time.hour < 6) return 'Night';
    if (_time.hour < 12) return 'Morning';
    if (_time.hour < 18) return 'Afternoon';
    return 'Evening';
  }

  Future<void> _predict() async {
    if (_selectedSubCity == null) {
      setState(() {
        _error = 'Tap a location on the Addis Ababa map first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _prediction = null;
    });

    final day = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][_date.weekday - 1];

    final date =
        '${_date.year.toString().padLeft(4, '0')}-'
        '${_date.month.toString().padLeft(2, '0')}-'
        '${_date.day.toString().padLeft(2, '0')}';

    final time =
        '${_time.hour.toString().padLeft(2, '0')}:'
        '${_time.minute.toString().padLeft(2, '0')}';

    try {
      await ref
          .read(riskMapViewModelProvider.notifier)
          .predict(
        inputs: {
          'date': date,
          'time': time,
          'dayOfWeek': day,
          'subCity': _selectedSubCity!,

          // Existing model inputs.
          'ageBandOfDriver': '31-50',
          'sexOfDriver': 'Male',
          'educationalLevel': 'Above high school',
          'vehicleDriverRelation': 'Employee',
          'drivingExperience': '5-10yr',
          'typeOfVehicle': 'Automobile',
          'ownerOfVehicle': 'Owner',
          'serviceYearOfVehicle': '2-5yrs',
          'defectOfVehicle': 'No defect',
          'lanesOrMedians': 'Two-way (divided with broken lines)',
          'roadAllignment': 'Tangent road with flat terrain',
          'typesOfJunction': _junction,
          'roadSurfaceType': _roadSurface,
          'roadSurfaceConditions': _roadCondition,
          'lightConditions': _light,
          'typeOfCollision': _collision,
          'vehicleMovement': _movement,
          'casualtyType': 'Driver or rider',

          // Time information.
          'hour': _time.hour.toString(),
          'minute': _time.minute.toString(),
          'timePeriod': _timePeriod(),
        },
      );

      if (!mounted) return;

      final vm = ref.read(riskMapViewModelProvider);

      setState(() {
        _prediction = vm.result;
        _error = vm.error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors.navyDark,
      appBar: AppBar(
        title: const Text('Addis Risk Map'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(9.0108, 38.7613),
                initialZoom: 12.2,
                minZoom: 10,
                maxZoom: 18,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.aaguardian.road_safety',
                ),
                MarkerLayer(
                  markers: [
                    ..._subCities.map(
                      (city) => Marker(
                        point: city.center,
                        width: 70,
                        height: 38,
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_city,
                              color: appColors.amber,
                              size: 18,
                            ),
                            Text(
                              city.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedPoint != null)
                      Marker(
                        point: _selectedPoint!,
                        width: 46,
                        height: 46,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 42,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_selectedSubCity == null)
                  Text(
                    'Tap anywhere inside Addis Ababa to resolve the nearest supported sub-city.',
                    style: TextStyle(
                      color: appColors.mutedText,
                    ),
                  )
                else
                  _selectedLocationCard(),

                const SizedBox(height: 12),

                _tapField(
                  'Date',
                  '${_date.year}-'
                      '${_date.month.toString().padLeft(2, '0')}-'
                      '${_date.day.toString().padLeft(2, '0')}',
                  Icons.calendar_today,
                  _pickDate,
                ),

                const SizedBox(height: 10),

                _tapField(
                  'Time',
                  _time.format(context),
                  Icons.access_time,
                  _pickTime,
                ),

                const SizedBox(height: 10),

                _dropdown(
                  'Junction type',
                  _junction,
                  const [
                    'No junction',
                    'Y Shape',
                    'T Shape',
                    'X Shape',
                    'Crossing',
                  ],
                  (v) => setState(() {
                    _junction = v!;
                  }),
                ),

                const SizedBox(height: 10),

                _dropdown(
                  'Road type',
                  _roadSurface,
                  const [
                    'Asphalt roads',
                    'Earth roads',
                    'Gravel roads',
                  ],
                  (v) => setState(() {
                    _roadSurface = v!;
                  }),
                ),

                const SizedBox(height: 10),

                _dropdown(
                  'Road condition',
                  _roadCondition,
                  const [
                    'Dry',
                    'Wet or damp',
                    'Snowy or icy',
                  ],
                  (v) => setState(() {
                    _roadCondition = v!;
                  }),
                ),

                const SizedBox(height: 10),

                _dropdown(
                  'Light condition',
                  _light,
                  const [
                    'Daylight',
                    'Darkness - lights lit',
                    'Darkness - lights unlit',
                    'Darkness - no lighting',
                  ],
                  (v) => setState(() {
                    _light = v!;
                  }),
                ),

                const SizedBox(height: 10),

                _dropdown(
                  'Collision type',
                  _collision,
                  const [
                    'Vehicle with vehicle collision',
                    'Collision with roadside-objects',
                    'Collision with pedestrians',
                    'Rollover',
                    'Other',
                  ],
                  (v) => setState(() {
                    _collision = v!;
                  }),
                ),

                const SizedBox(height: 10),

                _dropdown(
                  'Vehicle movement',
                  _movement,
                  const [
                    'Going straight',
                    'Turning left',
                    'Turning right',
                    'U-Turn',
                    'Stopping',
                    'Overtaking',
                  ],
                  (v) => setState(() {
                    _movement = v!;
                  }),
                ),

                const SizedBox(height: 12),

                if (_isPeak)
                  _info(
                    'Peak accident period: '
                    '${_time.hour >= 7 && _time.hour < 9 ? '7:00–9:00 AM' : '4:00–6:00 PM'}',
                    appColors.amber,
                  ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _predict,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.analytics),
                    label: Text(
                      _loading ? 'Predicting...' : 'Check risk',
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _info(_error!, Colors.red),
                ],

                if (_prediction != null) ...[
                  const SizedBox(height: 12),
                  _resultCard(_prediction!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: appColors.amber,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: appColors.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Resolved sub-city: $_selectedSubCity',
              style: TextStyle(
                color: appColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tapField(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: appColors.white,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: appColors.navyCard,
      style: TextStyle(
        color: appColors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
      ),
      items: values
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(v),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _info(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _resultCard(SeverityPrediction p) {
    final weather = p.weather?.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.navyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: appColors.navyLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predicted severity: ${p.predictedSeverity}',
            style: TextStyle(
              color: appColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Fatal ${p.fatalPercentage.toStringAsFixed(1)}% · '
            'Serious ${p.seriousPercentage.toStringAsFixed(1)}% · '
            'Slight ${p.slightPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: appColors.white,
            ),
          ),

          const SizedBox(height: 14),

          // Weather comes from the backend.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.cloud,
                color: appColors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  weather != null && weather.isNotEmpty
                      ? 'Weather: $weather'
                      : 'Weather data unavailable',
                  style: TextStyle(
                    color: appColors.mutedText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Light: ${p.lightConditions ?? _light}',
            style: TextStyle(
              color: appColors.mutedText,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Peak: ${p.peakPeriod ?? (_isPeak ? 'Peak period' : 'Off-peak')}',
            style: TextStyle(
              color: _isPeak
                  ? appColors.amber
                  : appColors.mutedText,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Safety recommendation',
            style: TextStyle(
              color: appColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _recommendation(p),
            style: TextStyle(
              color: appColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  String _recommendation(SeverityPrediction p) {
    if (_isPeak) {
      return 'Exercise extra caution during this peak period and reduce speed around the selected junction.';
    }

    if (p.predictedSeverity.toLowerCase().contains('fatal')) {
      return 'Treat this scenario as high concern and use additional caution around the selected road conditions.';
    }

    if (p.predictedSeverity.toLowerCase().contains('serious')) {
      return 'Use additional caution and reduce speed around the selected junction.';
    }

    return 'Stay alert, follow road rules, and maintain a safe speed for the selected conditions.';
  }
}