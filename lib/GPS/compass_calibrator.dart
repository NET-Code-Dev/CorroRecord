import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'gps_ble_service.dart';

class CompassCalibrator {
  final GpsBleService gpsBleService;
  List<CalibrationPoint> _calibrationPoints = [];
  DateTime? _lastCalibrationTime;
  static const String _calibrationDataKey = 'user_friendly_compass_calibration_data';
  static const String _calibrationTimeKey = 'user_friendly_compass_calibration_time';

  CompassCalibrator({required this.gpsBleService}) {
    _loadCalibration();
  }

  Future<void> _loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final calibrationData = prefs.getStringList(_calibrationDataKey);
    if (calibrationData != null) {
      _calibrationPoints = calibrationData.map((data) {
        final parts = data.split(',');
        return CalibrationPoint(
          gpsBearing: double.parse(parts[0]),
          magnetometerBearing: double.parse(parts[1]),
        );
      }).toList();
    }
    final calibrationTimeString = prefs.getString(_calibrationTimeKey);
    if (calibrationTimeString != null) {
      _lastCalibrationTime = DateTime.parse(calibrationTimeString);
    }
  }

  Future<void> _saveCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final calibrationData = _calibrationPoints.map((point) => '${point.gpsBearing},${point.magnetometerBearing}').toList();
    await prefs.setStringList(_calibrationDataKey, calibrationData);
    if (_lastCalibrationTime != null) {
      await prefs.setString(_calibrationTimeKey, _lastCalibrationTime!.toIso8601String());
    }
  }

  Future<void> calibrate(BuildContext context) async {
    _calibrationPoints.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compass Calibration'),
        content: const Text('To calibrate the compass, you\'ll need to walk in three different directions. '
            'Start by facing any direction, then walk straight for about 10 seconds when prompted.'),
        actions: [
          TextButton(
            child: const Text('Start'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    for (int i = 1; i <= 3; i++) {
      await _calibrateDirection(context, i);
    }

    _lastCalibrationTime = DateTime.now();
    await _saveCalibration();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calibration complete')),
    );
  }

  Future<void> _calibrateDirection(BuildContext context, int stepNumber) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Step $stepNumber of 3'),
        content: const Text('Face any direction different from the previous step(s), '
            'then press Start and walk straight for 10 seconds.'),
        actions: [
          TextButton(
            child: const Text('Start'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    List<double> gpsCourses = [];
    List<double> magnetometerBearings = [];
    Timer? timer;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Calibrating...'),
        content: Text('Keep walking in a straight line for 10 seconds.'),
      ),
    );

    timer = Timer(const Duration(seconds: 10), () {
      Navigator.of(context).pop();
    });

    // Collect GPS and magnetometer data simultaneously
    await Future.wait([
      gpsBleService.gpsDataStream.listen((data) {
        if (data['course'] != null && data['speed'] != null && data['speed'] > 0.5) {
          gpsCourses.add(data['course']);
        }
      }).asFuture<void>(),
      FlutterCompass.events!.listen((event) {
        if (event.heading != null) {
          magnetometerBearings.add(event.heading!);
        }
      }).asFuture<void>(),
    ]).timeout(const Duration(seconds: 10));

    timer.cancel();

    if (gpsCourses.isNotEmpty && magnetometerBearings.isNotEmpty) {
      double avgGpsCourse = gpsCourses.reduce((a, b) => a + b) / gpsCourses.length;
      double avgMagnetometerBearing = magnetometerBearings.reduce((a, b) => a + b) / magnetometerBearings.length;
      _calibrationPoints.add(CalibrationPoint(gpsBearing: avgGpsCourse, magnetometerBearing: avgMagnetometerBearing));
    }
  }

  bool isCalibrationValid() {
    if (_calibrationPoints.isEmpty || _lastCalibrationTime == null) return false;
    return DateTime.now().difference(_lastCalibrationTime!).inDays < 7; // Consider calibration valid for 7 days
  }

  double? getCalibratedBearing(double? gpsBearing, double? magnetometerBearing) {
    if (gpsBearing == null || magnetometerBearing == null || _calibrationPoints.isEmpty) return null;

    // Find the two closest calibration points
    _calibrationPoints
        .sort((a, b) => (a.magnetometerBearing - magnetometerBearing).abs().compareTo((b.magnetometerBearing - magnetometerBearing).abs()));
    var point1 = _calibrationPoints[0];
    var point2 = _calibrationPoints[1];

    // Interpolate between the two points
    double t = (magnetometerBearing - point1.magnetometerBearing) / (point2.magnetometerBearing - point1.magnetometerBearing);
    double interpolatedGpsBearing = point1.gpsBearing + t * (point2.gpsBearing - point1.gpsBearing);

    // Calculate the offset between GPS and interpolated bearing
    double offset = (interpolatedGpsBearing - gpsBearing + 360) % 360;

    // Apply the offset to the current GPS bearing
    return (gpsBearing + offset) % 360;
  }
}

class CalibrationPoint {
  final double gpsBearing;
  final double magnetometerBearing;

  CalibrationPoint({required this.gpsBearing, required this.magnetometerBearing});
}
