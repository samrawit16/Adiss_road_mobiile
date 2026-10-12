import 'dart:typed_data';
import '../../../core/constants/api_constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../alerts/data/safety_repository.dart';
import '../viewmodels/report_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({
    super.key,
    this.initialType = 'road_accident',
  });

  final String initialType;

  @override
  ConsumerState<ReportFormScreen> createState() =>
      _ReportFormScreenState();
}

class _ReportFormScreenState
    extends ConsumerState<ReportFormScreen> {
  final TextEditingController _description =
      TextEditingController();

  // Road or place where it happened: filled from GPS, editable, or typed.
  final TextEditingController _road =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String _type = 'road_accident';
  String _severity = 'unknown';

  bool _injuries = false;
  bool _emergency = false;
  bool _sending = false;
  bool _detecting = false;
  bool _roadEdited = false;

  String? _error;
  String? _roadHint;

  XFile? _image;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;

    // Try to name the road from GPS as soon as the form opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detectRoad();
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _road.dispose();
    super.dispose();
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Future<void> _pick(ImageSource source) async {
    if (_sending) return;

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        _image = file;
        _imageBytes = bytes;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<Position> _getPosition() async {
    final enabled =
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception(
        'Turn on GPS/location services before submitting this report.',
      );
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission is required to submit a report.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Enable location permission in your browser/device settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ============================================================
  // ROAD NAME (GPS detection, or typed by the reporter)
  // ============================================================

  Future<void> _detectRoad({bool force = false}) async {
    if (_detecting || _sending) return;

    setState(() {
      _detecting = true;
      _roadHint = null;
    });

    try {
      final position = await _getPosition();

      final roadContext = await ref
          .read(safetyRepositoryProvider)
          .getContext(
            latitude: position.latitude,
            longitude: position.longitude,
            speedKmh: 0,
          );

      if (!mounted) return;

      final name = (roadContext.roadName ?? '').trim();

      setState(() {
        // Never overwrite something the user typed, unless they tapped the GPS button.
        if (name.isNotEmpty && (force || !_roadEdited)) {
          _road.text = name;
          _roadEdited = false;
        }

        _roadHint = name.isNotEmpty
            ? 'Detected from GPS. You can change it.'
            : 'GPS could not find a road name here. Please type it.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _roadHint =
            '${e.toString().replaceFirst('Exception: ', '')} '
            'You can type the road instead.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _detecting = false;
        });
      }
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    if (_sending) return;

    FocusScope.of(context).unfocus();

    // The police need to know where it happened. An emergency report may be sent without a
    // name because its exact GPS position is always included.
    if (_road.text.trim().isEmpty && !_emergency) {
      setState(() {
        _error = _detecting
            ? 'Still finding your road from GPS. '
                'Wait a moment, or type the road or place.'
            : 'Please type the road or place where this happened, '
                'or tap the GPS button to detect it.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      // --------------------------------------------------------
      // GET GPS
      // --------------------------------------------------------

      final position = await _getPosition();

      if (!mounted) return;

      // --------------------------------------------------------
      // SUBMIT
      // --------------------------------------------------------

      await ref
          .read(reportViewModelProvider.notifier)
          .submit(
            reportType: _type,
            description: _description.text.trim(),
            severity: _severity,
            injuriesReported: _injuries,
            emergencyRequired: _emergency,
            latitude: position.latitude,
            longitude: position.longitude,
            gpsAccuracyM: position.accuracy,
            roadName: _road.text.trim(),
            imageBytes: _imageBytes,
            imageName: _image?.name,
            occurredAt: DateTime.now(),
          );

      if (!mounted) return;

      final result =
          ref.read(reportViewModelProvider);

      // --------------------------------------------------------
      // BACKEND ERROR
      // --------------------------------------------------------

      if (result.error != null) {
        setState(() {
          _sending = false;
          _error = result.error;
        });
        return;
      }

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (result.submitted) {
        setState(() {
          _sending = false;
        });

        await _showSuccessDialog();

        return;
      }

      // --------------------------------------------------------
      // UNKNOWN RESULT
      // --------------------------------------------------------

      setState(() {
        _sending = false;
        _error =
            'The report could not be submitted. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: appColors.success,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Report submitted',
                  style: TextStyle(
                    color: appColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Thank you for helping keep our roads safer.\n\n'
            'Your report has been submitted successfully. '
            'You can view its status in My Reports.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors.amber,
                foregroundColor: appColors.navy,
              ),
              child: const Text(
                'View My Reports',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    context.pushReplacement(
      '/police/my-reports',
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: appColors.navy,
        ),
        title: Text(
          'Submit report',
          style: TextStyle(
            color: appColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ------------------------------------------------------
          // INCIDENT TYPE
          // ------------------------------------------------------

          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Incident type',
            ),
            items: const [
              DropdownMenuItem(
                value: 'road_accident',
                child: Text('Traffic Accident'),
              ),
              DropdownMenuItem(
                value: 'hazard',
                child: Text('Road Hazard'),
              ),
              DropdownMenuItem(
                value: 'hit_and_run',
                child: Text('Hit and Run'),
              ),
              DropdownMenuItem(
                value: 'vehicle_breakdown',
                child: Text('Vehicle Breakdown'),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text('Other'),
              ),
            ],
            onChanged: _sending
                ? null
                : (value) {
                    setState(() {
                      _type =
                          value ?? 'road_accident';
                    });
                  },
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // SEVERITY
          // ------------------------------------------------------

          DropdownButtonFormField<String>(
            value: _severity,
            decoration: const InputDecoration(
              labelText: 'Severity',
            ),
            items: const [
              DropdownMenuItem(
                value: 'unknown',
                child: Text('Unknown'),
              ),
              DropdownMenuItem(
                value: 'minor',
                child: Text('Minor'),
              ),
              DropdownMenuItem(
                value: 'serious',
                child: Text('Serious'),
              ),
              DropdownMenuItem(
                value: 'critical',
                child: Text('Critical'),
              ),
            ],
            onChanged: _sending
                ? null
                : (value) {
                    setState(() {
                      _severity =
                          value ?? 'unknown';
                    });
                  },
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // ROAD OR PLACE
          // ------------------------------------------------------

          TextField(
            controller: _road,
            enabled: !_sending,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _roadEdited = true,
            decoration: InputDecoration(
              labelText: 'Road or place',
              hintText: 'e.g. Bole Road near Edna Mall',
              helperText: _detecting
                  ? 'Finding your road from GPS...'
                  : _roadHint,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.place_outlined),
              suffixIcon: _detecting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Detect with GPS',
                      icon: const Icon(Icons.my_location),
                      onPressed: _sending
                          ? null
                          : () => _detectRoad(force: true),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------

          TextField(
            controller: _description,
            enabled: !_sending,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe what happened...',
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // PHOTOS
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sending
                      ? null
                      : () =>
                          _pick(ImageSource.camera),
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                  ),
                  label: const Text(
                    'Take photo',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sending
                      ? null
                      : () =>
                          _pick(ImageSource.gallery),
                  icon: const Icon(
                    Icons.upload_file,
                  ),
                  label: const Text(
                    'Upload photo',
                  ),
                ),
              ),
            ],
          ),

          if (_imageBytes != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(12),
              child: Image.memory(
                _imageBytes!,
                height: 190,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ------------------------------------------------------
          // GPS
          // ------------------------------------------------------

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.gps_fixed,
              color: appColors.success,
            ),
            title: Text(
              'Current GPS location',
            ),
            subtitle: Text(
              'Your report is submitted with the '
              'location where it was created.',
            ),
          ),

          // ------------------------------------------------------
          // INJURIES
          // ------------------------------------------------------

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Injuries reported',
            ),
            value: _injuries,
            activeColor: appColors.danger,
            onChanged: _sending
                ? null
                : (value) {
                    setState(() {
                      _injuries = value;
                    });
                  },
          ),

          // ------------------------------------------------------
          // EMERGENCY
          // ------------------------------------------------------

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Emergency assistance required',
            ),
            value: _emergency,
            activeColor: appColors.danger,
            onChanged: _sending
                ? null
                : (value) {
                    setState(() {
                      _emergency = value;
                    });
                  },
          ),

          // ------------------------------------------------------
          // ERROR
          // ------------------------------------------------------

          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appColors.danger
                    .withOpacity(.08),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  color: appColors.danger,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ------------------------------------------------------
          // SUBMIT BUTTON
          // ------------------------------------------------------

          ElevatedButton.icon(
            onPressed:
                _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(
              _sending
                  ? 'Submitting...'
                  : 'Submit Report',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  appColors.amber,
              foregroundColor:
                  appColors.navy,
              minimumSize:
                  const Size.fromHeight(54),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}