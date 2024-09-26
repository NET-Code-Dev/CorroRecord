/*

import 'package:flutter/services.dart';

class GpsDataPlugin {
  static const MethodChannel _channel = MethodChannel('com.acuren523.asset_inspections/gps_data');

  static Future<void> startGps() async {
    await _channel.invokeMethod('startGps');
  }

  static Future<void> stopGps() async {
    await _channel.invokeMethod('stopGps');
  }

  static void listenToGpsData(Function(Map<String, dynamic>) callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'updateGpsData') {
        callback(Map<String, dynamic>.from(call.arguments));
      }
    });
  }
}
*/