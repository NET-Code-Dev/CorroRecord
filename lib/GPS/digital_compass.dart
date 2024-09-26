import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'compass_calibrator.dart';
import 'gps_ble_service.dart';

class GPSDigitalCompass extends StatefulWidget {
  final GpsBleService gpsBleService;

  const GPSDigitalCompass({super.key, required this.gpsBleService});

  @override
  createState() => _GPSDigitalCompassState();
}

class _GPSDigitalCompassState extends State<GPSDigitalCompass> {
  late CompassCalibrator _calibrator;

  @override
  void initState() {
    super.initState();
    _calibrator = CompassCalibrator(gpsBleService: widget.gpsBleService);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.gpsBleService.gpsDataStream,
      builder: (context, gpsSnapshot) {
        return StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, compassSnapshot) {
            double? gpsBearing = gpsSnapshot.data?['course'];
            double? magnetometerBearing = compassSnapshot.data?.heading;
            double? speed = gpsSnapshot.data?['speed'];
            bool isMoving = (speed ?? 0) > 0.5;

            double? calibratedBearing = _calibrator.getCalibratedBearing(gpsBearing, magnetometerBearing);

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore, color: Colors.white, size: 24.sp),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 200.w,
                      child: _buildCompassDisplay(calibratedBearing, isMoving),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _formatBearing(calibratedBearing),
                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (!_calibrator.isCalibrationValid())
                  ElevatedButton(
                    child: const Text('Calibration Required'),
                    onPressed: () => _calibrator.calibrate(context),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCompassDisplay(double? bearing, bool isMoving) {
    String direction = _getDirection(bearing);
    return Center(
      child: Text(
        direction,
        style: TextStyle(color: isMoving ? Colors.white : Colors.grey, fontSize: 24.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getDirection(double? bearing) {
    if (bearing == null) return 'N/A';
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((bearing + 22.5) % 360 ~/ 45)];
  }

  String _formatBearing(double? bearing) {
    if (bearing == null) return 'N/A';
    return '${bearing.round()}°';
  }
}

/*
class GPSDigitalCompass extends StatelessWidget {
  final GpsBleService gpsBleService;

  const GPSDigitalCompass({super.key, required this.gpsBleService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: gpsBleService.gpsDataStream,
      builder: (context, snapshot) {
        double? course = snapshot.data?['course'];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, color: Colors.white70, size: 24.sp),
            SizedBox(width: 8.w),
            SizedBox(
              width: 200.w,
              child: _buildCompassDisplay(course),
            ),
            SizedBox(width: 8.w),
            Text(
              _formatCourse(course),
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompassDisplay(double? course) {
    String direction = _getDirection(course);
    return Center(
      child: Text(
        direction,
        style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getDirection(double? course) {
    if (course == null) return 'N/A';
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((course + 22.5) % 360 ~/ 45)];
  }

  String _formatCourse(double? course) {
    if (course == null) return 'N/A';
    return '${course.round()}°';
  }
}
*/