import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'gps_ble_service.dart';
import 'gps_status_bar.dart';

enum ZoomLevel {
  centimeters,
  feet,
  meters,
  threeMeters,
}

class GpsFixView extends StatefulWidget {
  final GpsBleService gpsBleService;
  final Function(double, double)? onCoordinatesUpdated;

  const GpsFixView({
    super.key,
    required this.gpsBleService,
    this.onCoordinatesUpdated,
  });

  @override
  createState() => _GpsFixViewState();
}

class _GpsFixViewState extends State<GpsFixView> {
  final List<LatLng> _points = [];
  LatLng? _centerPoint;
  LatLng? _averagePoint;
  double _cep50 = 0.0;
  bool _isCollecting = false;
  bool _centeredOnAverage = false;
  ZoomLevel _currentZoom = ZoomLevel.meters;
  StreamSubscription? _gpsSubscription;
  Map<String, dynamic> _lastKnownGpsData = {};

  @override
  void initState() {
    super.initState();
    _setupGpsStream();
  }

  void _setupGpsStream() async {
    _gpsSubscription = widget.gpsBleService.gpsDataStream.listen((data) {
      setState(() {
        _lastKnownGpsData = data;
        if (_isCollecting && data['latitude'] != null && data['longitude'] != null) {
          LatLng newPoint = LatLng(data['latitude'], data['longitude']);
          if (_points.isEmpty) {
            _centerPoint = newPoint;
          }
          _points.add(newPoint);
          _updateStatistics();
        }
      });
    });
  }

  void _updateStatistics() {
    if (_points.isEmpty) return;

    // Calculate average point
    double sumLat = 0, sumLon = 0;
    for (var point in _points) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }
    _averagePoint = LatLng(sumLat / _points.length, sumLon / _points.length);

    // Calculate CEP(50%)
    List<double> distances = _points.map((point) => _calculateDistance(_averagePoint!, point)).toList();
    distances.sort();
    _cep50 = distances[distances.length ~/ 2];
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // in meters
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  String _formatLatLng(LatLng? point) {
    if (point == null) return "N/A";
    return "(${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})";
  }

  void _toggleCenterPoint() {
    setState(() {
      _centeredOnAverage = !_centeredOnAverage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Fix View'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 0, 43, 92),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(25.h),
          child: CompactGPSStatusBar(gpsBleService: widget.gpsBleService),
        ),
      ),
      body: Stack(
        children: [
          CustomPaint(
            painter: FixViewPainter(
              _points,
              _centeredOnAverage ? _averagePoint : _centerPoint,
              _averagePoint,
              _cep50,
              _currentZoom,
              _centeredOnAverage,
            ),
            child: Container(),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.zoom_in),
                ),
                SizedBox(height: 8.h),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: _buildLegend(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'info',
            mini: true,
            onPressed: _showSideSheet,
            child: const Icon(Icons.info_outline),
          ),
          SizedBox(height: 10.h),
          FloatingActionButton(
            heroTag: 'toggle_center',
            mini: true,
            onPressed: _toggleCenterPoint,
            tooltip: _centeredOnAverage ? 'Center on Start Point' : 'Center on Average Point',
            child: Icon(
              _centeredOnAverage ? Icons.center_focus_strong : Icons.center_focus_weak,
              color: _centeredOnAverage ? Colors.purple : Colors.blue,
            ),
          ),
          SizedBox(height: 10.h),
          FloatingActionButton(
            heroTag: 'toggle_collection',
            onPressed: _toggleDataCollection,
            tooltip: _isCollecting ? 'Stop Collecting' : 'Start Collecting',
            child: Icon(_isCollecting ? Icons.stop : Icons.play_arrow, color: _isCollecting ? Colors.red : Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        //color: Colors.white.withOpacity(0.8),
        color: const Color.fromRGBO(255, 255, 255, 0.8),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: const [
          BoxShadow(
            //color: Colors.black.withOpacity(0.1),
            color: Color.fromRGBO(0, 0, 0, 0.8),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(Colors.red, 'GPS Points'),
          SizedBox(height: 4.h),
          _buildLegendItem(Colors.blue, 'Start Point'),
          SizedBox(height: 4.h),
          _buildLegendItem(Colors.purple, 'Average Point'),
          SizedBox(height: 4.h),
          _buildLegendItem(Colors.green, 'CEP (50%)'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  void _showSideSheet() {
    showModalSideSheet(
      context: context,
      body: StreamBuilder<Map<String, dynamic>>(
        stream: widget.gpsBleService.gpsDataStream,
        initialData: _lastKnownGpsData,
        builder: (context, snapshot) {
          return SideSheetContent(
            points: _points,
            centerPoint: _centerPoint,
            averagePoint: _averagePoint,
            cep50: _cep50,
            lastKnownGpsData: snapshot.data ?? _lastKnownGpsData,
          );
        },
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = ZoomLevel.values[(_currentZoom.index - 1).clamp(0, ZoomLevel.values.length - 1)];
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = ZoomLevel.values[(_currentZoom.index + 1).clamp(0, ZoomLevel.values.length - 1)];
    });
  }

  void _toggleDataCollection() {
    if (_isCollecting) {
      _stopCollection();
    } else {
      _startCollection();
    }
  }

  void _startCollection() {
    setState(() {
      _isCollecting = true;
      _points.clear();
      _centerPoint = null;
      _averagePoint = null;
      _cep50 = 0.0;
      _centeredOnAverage = false;
    });
  }

  void _stopCollection() {
    setState(() {
      _isCollecting = false;
    });

    if (_averagePoint != null && widget.onCoordinatesUpdated != null) {
      // Round to 6 decimal places
      double roundedLatitude = double.parse(_averagePoint!.latitude.toStringAsFixed(6));
      double roundedLongitude = double.parse(_averagePoint!.longitude.toStringAsFixed(6));

      widget.onCoordinatesUpdated!(roundedLatitude, roundedLongitude);

      // Update the display of coordinates in the GpsFixView
      setState(() {
        _averagePoint = LatLng(roundedLatitude, roundedLongitude);
      });
    }
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
class FixViewPainter extends CustomPainter {
  final List<LatLng> points;
  final LatLng? centerPoint;
  final LatLng? averagePoint;
  final double cep50;
  final ZoomLevel zoomLevel;
  final bool centeredOnAverage;

  FixViewPainter(this.points, this.centerPoint, this.averagePoint, this.cep50, this.zoomLevel, this.centeredOnAverage);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      //..color = Colors.blue.withOpacity(0.5)
      ..color = const Color.fromRGBO(33, 150, 143, 0.5)
      ..strokeWidth = 1;

    if (centerPoint != null) {
      final center = Offset(size.width / 2, size.height / 2);
      final (maxRadius, scale, unitLabel) = _getZoomParameters(size);

      // Draw concentric circles
      for (int i = 1; i <= 5; i++) {
        double radius = i * (maxRadius / 5) * scale;
        canvas.drawCircle(center, radius, paint..style = PaintingStyle.stroke);

        // Draw distance label
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: '${(i * maxRadius / 5).toStringAsFixed(1)}$unitLabel',
            style: const TextStyle(color: Colors.black, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(center.dx + radius - 20, center.dy));
      }

      // Draw points relative to center point
      final pointPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 1;
      for (var point in points) {
        final offset = _pointToOffset(point, centerPoint!, size, scale);
        canvas.drawCircle(offset, 2, pointPaint..style = PaintingStyle.fill);
      }

      // Draw average point
      if (averagePoint != null) {
        final avgOffset = _pointToOffset(averagePoint!, centerPoint!, size, scale);
        canvas.drawCircle(avgOffset, 4, Paint()..color = Colors.purple);
      }

      // Draw CEP(50%) circle
      final cepPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, cep50 * scale, cepPaint);

      // Draw center point
      canvas.drawCircle(center, 4, Paint()..color = centeredOnAverage ? Colors.purple : Colors.blue);

      // Draw first point when centered on average
      if (centeredOnAverage) {
        final firstPointOffset = _pointToOffset(points.first, centerPoint!, size, scale);
        canvas.drawCircle(firstPointOffset, 4, Paint()..color = Colors.blue);
      }
    }
  }

  (double, double, String) _getZoomParameters(Size size) {
    switch (zoomLevel) {
      case ZoomLevel.centimeters:
        return (0.5, size.width / 1, 'cm'); // 50 cm max
      case ZoomLevel.feet:
        return (16.4, size.width / 32.8, 'ft'); // ~5 meters (16.4 feet) max
      case ZoomLevel.meters:
        return (5.0, size.width / 10, 'm'); // 5 meters max
      case ZoomLevel.threeMeters:
        return (15.0, size.width / 30, 'm'); // 15 meters max
    }
  }

  Offset _pointToOffset(LatLng point, LatLng center, Size size, double scale) {
    final latDiff = point.latitude - center.latitude;
    final lonDiff = point.longitude - center.longitude;
    final x = size.width / 2 + (lonDiff * 111320 * scale); // 111320 meters per degree of longitude at the equator
    final y = size.height / 2 - (latDiff * 110574 * scale); // 110574 meters per degree of latitude
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SideSheetContent extends StatelessWidget {
  final List<LatLng> points;
  final LatLng? centerPoint;
  final LatLng? averagePoint;
  final double cep50;
  final Map<String, dynamic> lastKnownGpsData;

  const SideSheetContent({
    super.key,
    required this.points,
    required this.centerPoint,
    required this.averagePoint,
    required this.cep50,
    required this.lastKnownGpsData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            _buildTable('GNSS DETAILS', [
              ['UTC Time', _formatDateTime(lastKnownGpsData['timestamp'])],
              ['Latitude', _formatCoordinate(lastKnownGpsData['latitude'])],
              ['Longitude', _formatCoordinate(lastKnownGpsData['longitude'])],
              ['Altitude', _formatWithUnit(lastKnownGpsData['altitude'], 'm')],
              ['Quality', lastKnownGpsData['quality'] ?? 'N/A'],
              ['HDOP', _formatValue(lastKnownGpsData['hdop'])],
              ['SVInUse', _formatValue(lastKnownGpsData['satellites'])],
              ['Speed', _formatWithUnit(lastKnownGpsData['speed'], 'mph')],
              ['StdLat', _calculateStdDev(points.map((p) => p.latitude).toList()).toStringAsFixed(6)],
              ['StdLon', _calculateStdDev(points.map((p) => p.longitude).toList()).toStringAsFixed(6)],
              ['StdAlt', 'N/A'], // You'll need to collect altitude data for each point to calculate this
            ]),
            SizedBox(height: 10.h),
            _buildTable('MEAN', [
              ['AvgLat', _formatCoordinate(averagePoint?.latitude)],
              ['AvgLon', _formatCoordinate(averagePoint?.longitude)],
              ['AvgAlt', 'N/A'], // You'll need to collect altitude data for each point to calculate this
            ]),
            SizedBox(height: 10.h),
            _buildTable('STATISTICS', [
              ['CEP(50%)', '${cep50.toStringAsFixed(2)} m'],
              ['DRMS(65%)', '${_calculateDRMS().toStringAsFixed(2)} m'],
              ['R95(95%)', '${_calculateR95().toStringAsFixed(2)} m'],
              ['R100(100%)', '${_calculateR100().toStringAsFixed(2)} m'],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(String title, List<List<String>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold))),
        SizedBox(height: 4.h),
        Table(
          border: TableBorder.all(),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(2),
          },
          children: rows.map((row) {
            return TableRow(
              children: [
                // First column: right-aligned
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Text(
                    row[0],
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Second column: left-aligned (default)
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Text(row[1]),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'N/A';
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    return value.toString();
  }

  String _formatCoordinate(dynamic value) {
    if (value == null) return 'N/A';
    if (value is double) {
      return value.toStringAsFixed(6);
    }
    return value.toString();
  }

  String _formatWithUnit(dynamic value, String unit) {
    if (value == null) return 'N/A';
    if (value is double) {
      return '${value.toStringAsFixed(2)} $unit';
    }
    return '$value $unit';
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  double _calculateDRMS() {
    // Distance Root Mean Square (65% probability)
    return cep50 * 1.2;
  }

  double _calculateR95() {
    // 95% probability radius
    return cep50 * 2.08;
  }

  double _calculateR100() {
    // 100% probability radius (approximation)
    return cep50 * 3;
  }

  double _calculateStdDev(List<double> values) {
    if (values.isEmpty) return 0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    num sumSquaredDiffs = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b);
    return sqrt(sumSquaredDiffs / values.length);
  }
}

void showModalSideSheet({
  required BuildContext context,
  required Widget body,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            color: Colors.white,
            child: body,
          );
        },
      );
    },
  );
}
