//import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfo {
  static final DeviceInfo _instance = DeviceInfo._internal();
  factory DeviceInfo() => _instance;

  String? deviceId;

  DeviceInfo._internal();

  Future<void> initPlatformState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      try {
        if (deviceId == null || deviceId == 'unknown') {
          // Fallback to generating a UUID
          deviceId = const Uuid().v4();
        }

        await prefs.setString('device_id', deviceId!);
      } catch (e) {
        deviceId = const Uuid().v4();
        await prefs.setString('device_id', deviceId!);
      }
    }
  }
}
