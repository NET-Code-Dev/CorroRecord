import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'digital_compass.dart';
import 'gps_ble_service.dart';
import 'gps_fix_view.dart';

enum AccuracyStage {
  good,
  moderate,
  poor,
}

class GPSStatusBar extends StatefulWidget {
  const GPSStatusBar({super.key});

  @override
  createState() => _GPSStatusBarState();
}

class _GPSStatusBarState extends State<GPSStatusBar> {
  final GpsBleService _gpsService = GpsBleService();
  StreamSubscription? _gpsSubscription;
  final Map<String, dynamic> _lastKnownGpsData = {};

  @override
  void initState() {
    super.initState();
    _startGps();
  }

  Future<void> _startGps() async {
    await _gpsService.startGps();
    _gpsSubscription = _gpsService.gpsDataStream.listen((data) {
      setState(() {
        data.forEach((key, value) {
          if (value != null) {
            _lastKnownGpsData[key] = value;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  AccuracyStage _getAccuracyStage() {
    final hdop = _lastKnownGpsData['hdop'] as double?;
    final satellites = _lastKnownGpsData['satellites'] as int?;
    final accuracy = _lastKnownGpsData['accuracy'] as double?;

    if (hdop != null && hdop < 1.0 && satellites != null && satellites >= 8 && accuracy != null && accuracy < 5.0) {
      return AccuracyStage.good;
    } else if (hdop != null && hdop < 2.0 && satellites != null && satellites >= 6 && accuracy != null && accuracy < 10.0) {
      return AccuracyStage.moderate;
    } else {
      return AccuracyStage.poor;
    }
  }

  Color _getColor(AccuracyStage stage) {
    switch (stage) {
      case AccuracyStage.good:
        return Colors.green;
      case AccuracyStage.moderate:
        return Colors.yellow;
      case AccuracyStage.poor:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracyStage = _getAccuracyStage();
    final color = _getColor(accuracyStage);

    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusItem(Icons.satellite_alt, _lastKnownGpsData['satellites']?.toString() ?? '-', color),
              _buildDivider(),
              _buildStatusItem(Icons.graphic_eq_rounded, _formatDOP(_lastKnownGpsData['hdop']), color),
              _buildDivider(),
              _buildStatusItem(Icons.gps_fixed, _formatAccuracy(_lastKnownGpsData['accuracy']), color),
              _buildDivider(),
              _buildStatusItem(Icons.navigation, _lastKnownGpsData['course']?.toStringAsFixed(1) ?? '-', color),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.location_on, color: color, size: 20.sp),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GpsFixView(gpsBleService: _gpsService)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          //    GPSDigitalCompass(gpsBleService: _gpsService),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String value, Color color) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white24,
    );
  }

  String _formatAccuracy(dynamic accuracy) {
    if (accuracy == null) return '-';
    return '${(accuracy as num).round()} ft';
  }

  String _formatDOP(dynamic dop) {
    if (dop == null) return '-';
    return (dop as num).toStringAsFixed(2);
  }
}

class CompactGPSStatusBar extends StatefulWidget {
  final GpsBleService gpsBleService;

  const CompactGPSStatusBar({super.key, required this.gpsBleService});

  @override
  createState() => _CompactGPSStatusBarState();
}

class _CompactGPSStatusBarState extends State<CompactGPSStatusBar> {
  StreamSubscription? _gpsSubscription;
  final Map<String, dynamic> _lastKnownGpsData = {};

  @override
  void initState() {
    super.initState();
    _setupGpsStream();
  }

  void _setupGpsStream() {
    _gpsSubscription = widget.gpsBleService.gpsDataStream.listen((data) {
      setState(() {
        data.forEach((key, value) {
          if (value != null) {
            _lastKnownGpsData[key] = value;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  Color _getColor() {
    final hdop = _lastKnownGpsData['hdop'] as double?;
    final satellites = _lastKnownGpsData['satellites'] as int?;
    final accuracy = _lastKnownGpsData['accuracy'] as double?;

    if (hdop != null && hdop < 1.0 && satellites != null && satellites >= 8 && accuracy != null && accuracy < 5.0) {
      return Colors.green;
    } else if (hdop != null && hdop < 2.0 && satellites != null && satellites >= 6 && accuracy != null && accuracy < 10.0) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusItem(Icons.satellite_alt, _lastKnownGpsData['satellites']?.toString() ?? '-', color),
          _buildDivider(),
          _buildStatusItem(Icons.precision_manufacturing, _formatDOP(_lastKnownGpsData['hdop']), color),
          _buildDivider(),
          _buildStatusItem(Icons.gps_fixed, _formatAccuracy(_lastKnownGpsData['accuracy']), color),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 10,
      color: Colors.grey,
    );
  }

  Widget _buildStatusItem(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatAccuracy(dynamic accuracy) {
    if (accuracy == null) return '-';
    return '${(accuracy as num).round()}';
  }

  String _formatDOP(dynamic dop) {
    if (dop == null) return '-';
    return (dop as num).toStringAsFixed(1);
  }
}



/*
class GPSStatusBar extends StatefulWidget {
  const GPSStatusBar({super.key});

  @override
  createState() => _GPSStatusBarState();
}

class _GPSStatusBarState extends State<GPSStatusBar> {
  final GpsBleService _gpsService = GpsBleService();
  StreamSubscription? _gpsSubscription;
  final Map<String, dynamic> _lastKnownGpsData = {};

  @override
  void initState() {
    super.initState();
    _startGps();
  }

  Future<void> _startGps() async {
    await _gpsService.startGps();
    _gpsSubscription = _gpsService.gpsDataStream.listen((data) {
      if (kDebugMode) {
        print('Received GPS data in widget: $data');
      }
      setState(() {
        data.forEach((key, value) {
          if (value != null) {
            _lastKnownGpsData[key] = value;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusItem(Icons.satellite_alt, _lastKnownGpsData['satellites']?.toString() ?? '-'),
          _buildDivider(),
          _buildStatusItem(Icons.precision_manufacturing, _formatDOP(_lastKnownGpsData['hdop'])),
          _buildDivider(),
          _buildStatusItem(Icons.gps_fixed, _formatAccuracy(_lastKnownGpsData['accuracy'])),
          _buildDivider(),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.location_on, color: Colors.white70, size: 20.sp),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GpsFixView(gpsBleService: _gpsService)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String value) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 20.sp),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white24,
    );
  }

  String _formatAccuracy(dynamic accuracy) {
    if (accuracy == null) return '-';
    return '${(accuracy as num).round()} ft';
  }

/*
  String _formatCoordinate(dynamic coord) {
    if (coord == null) return '-';
    return (coord as num).toStringAsFixed(6);
  }
*/
  String _formatDOP(dynamic dop) {
    if (dop == null) return '-';
    return (dop as num).toStringAsFixed(2);
  }

/*
  String _formatSpeed(dynamic speed) {
    if (speed == null) return '-';
    return '${(speed as num).round()} mph';
  }
*/
}

*/