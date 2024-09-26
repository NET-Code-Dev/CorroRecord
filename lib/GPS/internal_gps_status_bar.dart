import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

class InternalGPSStatusBar extends StatefulWidget {
  const InternalGPSStatusBar({super.key});

  @override
  createState() => _InternalGPSStatusBarState();
}

class _InternalGPSStatusBarState extends State<InternalGPSStatusBar> {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastKnownPosition;
  int? _satelliteCount;

  @override
  void initState() {
    super.initState();
    _startListeningToGPS();
  }

  Future<void> _startListeningToGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try requesting permissions again
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _lastKnownPosition = position;
        if (position is AndroidPosition) {
          _satelliteCount = position.satellitesUsedInFix.toInt();
        } else {
          _satelliteCount = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
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
          _buildStatusItem(Icons.satellite_alt, _formatSatellites(_satelliteCount)),
          _buildDivider(),
          _buildStatusItem(Icons.precision_manufacturing, _formatAccuracy(_lastKnownPosition?.accuracy)),
          _buildDivider(),
          _buildStatusItem(Icons.speed, _formatSpeed(_lastKnownPosition?.speed)),
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
      height: 24.h,
      color: Colors.white24,
    );
  }

  String _formatSatellites(int? satellites) {
    return satellites?.toString() ?? '-';
  }

  String _formatAccuracy(double? accuracy) {
    if (accuracy == null) return '-';
    return '${accuracy.round()} m';
  }

  String _formatSpeed(double? speed) {
    if (speed == null) return '-';
    // Convert m/s to mph
    double speedMph = speed * 2.23694;
    return '${speedMph.round()} mph';
  }
}
