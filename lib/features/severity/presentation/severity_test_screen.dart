import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/severity_prediction_model.dart';
import '../viewmodel/severity_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

const _subCities = [
  'Bole',
  'Yeka',
  'Kirkos',
  'Arada',
  'Lideta',
  'Nifas Silk-Lafto',
  'Kolfe Keranio',
  'Gullele',
  'Akaki Kaliti',
  'Addis Ketema',
];

const _junctions = ['No junction', 'Y Shape', 'T Shape', 'X Shape', 'Crossing'];
const _roadSurfaces = ['Asphalt roads', 'Earth roads', 'Gravel roads'];
const _roadConditions = ['Dry', 'Wet or damp', 'Snowy or icy'];
const _lightConditions = ['Daylight', 'Darkness - lights lit', 'Darkness - lights unlit', 'Darkness - no lighting'];
const _collisionTypes = ['Vehicle with vehicle collision', 'Collision with roadside-objects', 'Collision with pedestrians', 'Rollover', 'Other'];
const _vehicleMovements = ['Going straight', 'Turning left', 'Turning right', 'U-Turn', 'Stopping', 'Overtaking'];
const _casualties = ['Driver or rider', 'Pedestrian', 'Passenger'];
const _ages = ['Under 18', '18-30', '31-50', '51-65', 'Over 65'];
const _sexes = ['Male', 'Female'];
const _education = ['Junior high school', 'High school', 'Above high school', 'Writing & reading'];
const _relations = ['Employee', 'Owner', 'Other'];
const _experience = ['No Licence', '<1yr', '1-2yr', '2-5yr', '5-10yr', 'Above 10yr'];
const _vehicles = ['Automobile', 'Lorry', 'Bus', 'Motorcycle', 'Bicycle', 'Other'];
const _owners = ['Owner', 'Governmental', 'Other'];
const _serviceYears = ['Below 1yr', '1-2yrs', '2-5yrs', '5-10yrs', 'Above 10yrs'];
const _defects = ['No defect', '7-10 years', '5-7 years', 'Other'];
const _lanes = ['Two-way (divided with broken lines)', 'Two-way (undivided)', 'One-way', 'Other'];
const _alignments = ['Tangent road with flat terrain', 'Tangent road with mild grade', 'Tangent road with rolling terrain', 'Other'];

class SeverityTestScreen extends ConsumerStatefulWidget {
  const SeverityTestScreen({super.key});

  @override
  ConsumerState<SeverityTestScreen> createState() => _SeverityTestScreenState();
}

class _SeverityTestScreenState extends ConsumerState<SeverityTestScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 30);

  String _subCity = 'Bole';
  String _age = '31-50';
  String _sex = 'Male';
  String _educationValue = 'Above high school';
  String _relation = 'Employee';
  String _experienceValue = '5-10yr';
  String _vehicle = 'Automobile';
  String _owner = 'Owner';
  String _serviceYear = '2-5yrs';
  String _defect = 'No defect';
  String _lanesValue = _lanes.first;
  String _alignment = _alignments.first;
  String _junction = 'Y Shape';
  String _roadSurface = 'Asphalt roads';
  String _roadCondition = 'Dry';
  String _light = 'Daylight';
  String _collision = 'Collision with roadside-objects';
  String _movement = 'Going straight';
  String _casualty = 'Driver or rider';

  bool get _isPeak => (_time.hour >= 7 && _time.hour < 9) || (_time.hour >= 16 && _time.hour < 18);

  String get _peakLabel {
    if (_time.hour >= 7 && _time.hour < 9) return 'Morning peak · 7:00–9:00 AM';
    if (_time.hour >= 16 && _time.hour < 18) return 'Evening peak · 4:00–6:00 PM';
    return 'Off-peak period';
  }

  String get _timePeriod {
    if (_time.hour < 6) return 'Night';
    if (_time.hour < 12) return 'Morning';
    if (_time.hour < 18) return 'Afternoon';
    return 'Evening';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _predict() async {
    final day = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][_date.weekday - 1];
    final date = '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final time = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

    await ref.read(severityViewModelProvider.notifier).predictSeverity(
      date: date,
      time: time,
      dayOfWeek: day,
      subCity: _subCity,
      ageBandOfDriver: _age,
      sexOfDriver: _sex,
      educationalLevel: _educationValue,
      vehicleDriverRelation: _relation,
      drivingExperience: _experienceValue,
      typeOfVehicle: _vehicle,
      ownerOfVehicle: _owner,
      serviceYearOfVehicle: _serviceYear,
      defectOfVehicle: _defect,
      lanesOrMedians: _lanesValue,
      roadAllignment: _alignment,
      typesOfJunction: _junction,
      roadSurfaceType: _roadSurface,
      roadSurfaceConditions: _roadCondition,
      lightConditions: _light,
      typeOfCollision: _collision,
      vehicleMovement: _movement,
      casualtyType: _casualty,
      hour: _time.hour,
      minute: _time.minute,
      timePeriod: _timePeriod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(severityViewModelProvider);
    return Scaffold(
      backgroundColor: appColors.navyDark,
      appBar: AppBar(title: const Text('Accident Severity Assessment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Scenario location & time', [
            _dropdown('Sub-city', _subCity, _subCities, (v) => setState(() => _subCity = v!)),
            _tapField('Date', '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}', Icons.calendar_today, _pickDate),
            _tapField('Time', _time.format(context), Icons.access_time, _pickTime),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isPeak ? appColors.amber.withOpacity(.14) : appColors.navyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _isPeak ? appColors.amber : appColors.navyLight),
              ),
              child: Row(children: [
                Icon(_isPeak ? Icons.warning_amber_rounded : Icons.schedule, color: _isPeak ? appColors.amber : appColors.mutedText),
                const SizedBox(width: 10),
                Expanded(child: Text(_isPeak ? 'Peak accident period: $_peakLabel' : _peakLabel, style: TextStyle(color: appColors.white, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 10),
          ]),
          _section('Driver', [
            _dropdown('Age band', _age, _ages, (v) => setState(() => _age = v!)),
            _dropdown('Sex', _sex, _sexes, (v) => setState(() => _sex = v!)),
            _dropdown('Education', _educationValue, _education, (v) => setState(() => _educationValue = v!)),
            _dropdown('Driver relation', _relation, _relations, (v) => setState(() => _relation = v!)),
            _dropdown('Driving experience', _experienceValue, _experience, (v) => setState(() => _experienceValue = v!)),
          ]),
          _section('Vehicle', [
            _dropdown('Vehicle type', _vehicle, _vehicles, (v) => setState(() => _vehicle = v!)),
            _dropdown('Owner of vehicle', _owner, _owners, (v) => setState(() => _owner = v!)),
            _dropdown('Service year', _serviceYear, _serviceYears, (v) => setState(() => _serviceYear = v!)),
            _dropdown('Vehicle defect', _defect, _defects, (v) => setState(() => _defect = v!)),
          ]),
          _section('Road & accident conditions', [
            _dropdown('Lanes / medians', _lanesValue, _lanes, (v) => setState(() => _lanesValue = v!)),
            _dropdown('Road alignment', _alignment, _alignments, (v) => setState(() => _alignment = v!)),
            _dropdown('Junction type', _junction, _junctions, (v) => setState(() => _junction = v!)),
            _dropdown('Road surface type', _roadSurface, _roadSurfaces, (v) => setState(() => _roadSurface = v!)),
            _dropdown('Road surface condition', _roadCondition, _roadConditions, (v) => setState(() => _roadCondition = v!)),
            _dropdown('Light condition', _light, _lightConditions, (v) => setState(() => _light = v!)),
            _dropdown('Collision type', _collision, _collisionTypes, (v) => setState(() => _collision = v!)),
            _dropdown('Vehicle movement', _movement, _vehicleMovements, (v) => setState(() => _movement = v!)),
            _dropdown('Casualty type', _casualty, _casualties, (v) => setState(() => _casualty = v!)),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: state.isLoading ? null : _predict,
              icon: state.isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.analytics_outlined),
              label: Text(state.isLoading ? 'Predicting...' : 'Predict severity'),
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 14),
            _message(state.error!, appColors.red),
          ],
          if (state.prediction != null) ...[
            const SizedBox(height: 18),
            _predictionCard(state.prediction!),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: TextStyle(color: appColors.white, fontSize: 18, fontWeight: FontWeight.w800))),
      ...children.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: e)),
    ]),
  );

  Widget _dropdown(String label, String value, List<String> values, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(
    value: value,
    dropdownColor: appColors.navyCard,
    style: TextStyle(color: appColors.white),
    decoration: InputDecoration(labelText: label),
    items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
    onChanged: onChanged,
  );

  Widget _tapField(String label, String value, IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: Text(value, style: TextStyle(color: appColors.white)),
    ),
  );

  Widget _message(String text, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
    child: Text(text, style: TextStyle(color: color)),
  );

  Widget _predictionCard(SeverityPrediction p) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: appColors.navyCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: appColors.navyLight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Prediction', style: TextStyle(color: appColors.mutedText, fontSize: 13)),
      const SizedBox(height: 5),
      Text(p.predictedSeverity, style: TextStyle(color: appColors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      _probability('Fatal injury', p.fatalPercentage),
      _probability('Serious injury', p.seriousPercentage),
      _probability('Slight injury', p.slightPercentage),
      const Divider(height: 24),
      _contextRow('Sub-city', p.subCity ?? _subCity),
      _contextRow('Weather', p.weather ?? 'Not returned by server'),
      _contextRow('Light', p.lightConditions ?? _light),
      _contextRow('Peak period', p.peakPeriod ?? (_isPeak ? _peakLabel : 'Off-peak')),
      if (p.peakMessage != null) ...[
        const SizedBox(height: 8),
        Text(p.peakMessage!, style: TextStyle(color: appColors.amber, fontWeight: FontWeight.w600)),
      ],
    ]),
  );

  Widget _probability(String label, double value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: appColors.white))), Text('${value.toStringAsFixed(1)}%', style: TextStyle(color: appColors.amber, fontWeight: FontWeight.w700))]),
  );

  Widget _contextRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(children: [SizedBox(width: 105, child: Text(label, style: TextStyle(color: appColors.mutedText))), Expanded(child: Text(value, style: TextStyle(color: appColors.white, fontWeight: FontWeight.w600)))]),
  );
}
