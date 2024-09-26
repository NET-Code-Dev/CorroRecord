// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GpsBleService {
  static final GpsBleService _instance = GpsBleService._internal();

  factory GpsBleService() {
    return _instance;
  }

  GpsBleService._internal();

  static const String DEVICE_NAME = 'P-7 Pro BLE';
  static final Guid SERVICE_UUID = Guid('0000FFF0-0000-1000-8000-00805F9B34FB');
  static final Guid CHARACTERISTIC_UUID = Guid('0000FFF1-0000-1000-8000-00805F9B34FB');

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription? _subscription;
////////////////////////////////////////////
  final _gpsDataController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get gpsDataStream => _gpsDataController.stream;

  Map<String, dynamic> _lastKnownGpsData = {};
  Map<String, dynamic> get lastKnownGpsData => _lastKnownGpsData;

  Timer? _updateTimer;
  bool _isRunning = false;

  Future<void> startGps() async {
    if (_isRunning) return;

    _isRunning = true;
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == DEVICE_NAME) {
          _connectToDevice(r.device);
          break;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 4));
    await FlutterBluePlus.stopScan();
    await subscription.cancel();
  }

/*
  final _gpsDataController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get gpsDataStream => _gpsDataController.stream;

  Map<String, dynamic> _accumulatedData = {};
  Timer? _updateTimer;
  bool _isRunning = false;

  Future<void> startGps() async {
    if (_isRunning) return;

    _isRunning = true;
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == DEVICE_NAME) {
          _connectToDevice(r.device);
          break;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 4));
    await FlutterBluePlus.stopScan();
    await subscription.cancel();
  }

*/
////////////////////////////////////////////////
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _device = device;
      if (kDebugMode) {
        print('Connected to ${device.platformName}');
      }

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid == SERVICE_UUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid == CHARACTERISTIC_UUID) {
              _characteristic = characteristic;
              await _setupNotifications();
              break;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting to device: $e');
      }
    }
  }

  Future<void> _setupNotifications() async {
    if (_characteristic == null) return;

    await _characteristic!.setNotifyValue(true);
    _subscription = _characteristic!.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        String nmeaString = String.fromCharCodes(value);
        _parseNmeaData(nmeaString);
      }
    });

    // Set up a timer to send accumulated data every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lastKnownGpsData.isNotEmpty) {
        _gpsDataController.add(_lastKnownGpsData);
        _lastKnownGpsData = {};
      }
    });
  }

  void _parseNmeaData(String nmeaString) {
    if (kDebugMode) {
      print('Received NMEA data: $nmeaString');
    }
    final sentences = nmeaString.split('\n');

    Map<String, dynamic> newData = {};

    for (final sentence in sentences) {
      final parts = sentence.split(',');
      if (parts.isEmpty) continue;

      if (kDebugMode) {
        print('Processing sentence: ${parts[0]}');
      }

      switch (parts[0]) {
        case '\$GNRMC':
          if (parts.length >= 12) {
            newData['timestamp'] = _parseTimestamp(parts[1], parts[9]);
            newData['latitude'] = _convertNmeaToDecimal(parts[3], parts[4]);
            newData['longitude'] = _convertNmeaToDecimal(parts[5], parts[6]);
            newData['speed'] = _convertKnotsToMph(double.tryParse(parts[7]) ?? 0.0);
            newData['course'] = double.tryParse(parts[8]);
          }
          break;

        case '\$GNGGA':
          if (parts.length >= 15) {
            newData['latitude'] = _convertNmeaToDecimal(parts[2], parts[3]);
            newData['longitude'] = _convertNmeaToDecimal(parts[4], parts[5]);
            newData['altitude'] = double.tryParse(parts[9]);
            newData['satellites'] = int.tryParse(parts[7]);
            newData['hdop'] = double.tryParse(parts[8]);
            newData['quality'] = _parseGpsQuality(parts[6]);
          }
          break;

        case '\$GNGSA':
          if (parts.length >= 18) {
            newData['pdop'] = double.tryParse(parts[15]);
            newData['hdop'] = double.tryParse(parts[16]);
            newData['vdop'] = double.tryParse(parts[17]);
            newData['accuracy'] =
                _calculateAccuracy(double.tryParse(parts[15]) ?? 0.0, double.tryParse(parts[16]) ?? 0.0, double.tryParse(parts[17]) ?? 0.0);
          }
          break;

        default:
          if (kDebugMode) {
            print('Unhandled NMEA sentence: $sentence');
          }
          break;
      }
    }

    // Update _lastKnownGpsData with new values, keeping old values if new ones are null
    newData.forEach((key, value) {
      if (value != null) {
        _lastKnownGpsData[key] = value;
      }
    });

    // Emit the updated GPS data
    _gpsDataController.add(_lastKnownGpsData);

    if (kDebugMode) {
      print('Updated GPS data: $_lastKnownGpsData');
    }
  }

  String _parseGpsQuality(String qualityIndicator) {
    switch (qualityIndicator) {
      case '0':
        return 'Invalid';
      case '1':
        return 'GPS fix';
      case '2':
        return 'DGPS fix';
      case '3':
        return 'PPS fix';
      case '4':
        return 'Real Time Kinematic';
      case '5':
        return 'Float RTK';
      case '6':
        return 'Estimated (dead reckoning)';
      case '7':
        return 'Manual input mode';
      case '8':
        return 'Simulation mode';
      default:
        return 'Unknown';
    }
  }

/*
  void _parseNmeaData(String nmeaString) {
    if (kDebugMode) {
      print('Received NMEA data: $nmeaString');
    }
    final sentences = nmeaString.split('\n');

    for (final sentence in sentences) {
      final parts = sentence.split(',');
      if (parts.isEmpty) continue;

      if (kDebugMode) {
        print('Processing sentence: ${parts[0]}');
      }

      switch (parts[0]) {
        case '\$GNRMC':
          if (kDebugMode) {
            print('Found GNRMC sentence: $sentence');
          }
          if (parts.length >= 12) {
            _accumulatedData['timestamp'] = _parseTimestamp(parts[1], parts[9]);
            _accumulatedData['latitude'] = _convertNmeaToDecimal(parts[3], parts[4]);
            _accumulatedData['longitude'] = _convertNmeaToDecimal(parts[5], parts[6]);
            _accumulatedData['speed'] = _convertKnotsToMph(double.tryParse(parts[7]) ?? 0.0);
            _accumulatedData['course'] = double.tryParse(parts[8]) ?? 0.0;
            if (kDebugMode) {
              print('Parsed GNRMC data: $_accumulatedData');
            }
          }
          break;

        case '\$GNGGA':
          if (kDebugMode) {
            print('Found GNGGA sentence: $sentence');
          }
          if (parts.length >= 15) {
            _accumulatedData['latitude'] = _convertNmeaToDecimal(parts[2], parts[3]);
            _accumulatedData['longitude'] = _convertNmeaToDecimal(parts[4], parts[5]);
            _accumulatedData['altitude'] = double.tryParse(parts[9]) ?? 0.0;
            _accumulatedData['satellites'] = int.tryParse(parts[7]) ?? 0;
            _accumulatedData['hdop'] = double.tryParse(parts[8]) ?? 0.0;
            if (kDebugMode) {
              print('Parsed GNGGA data: $_accumulatedData');
            }
          }
          break;

        case '\$GNGSA':
          if (kDebugMode) {
            print('Found GNGSA sentence: $sentence');
          }
          if (parts.length >= 18) {
            _accumulatedData['pdop'] = double.tryParse(parts[15]) ?? 0.0;
            _accumulatedData['hdop'] = double.tryParse(parts[16]) ?? 0.0;
            _accumulatedData['vdop'] = double.tryParse(parts[17]) ?? 0.0;
            _accumulatedData['accuracy'] =
                _calculateAccuracy(_accumulatedData['pdop'] ?? 0.0, _accumulatedData['hdop'] ?? 0.0, _accumulatedData['vdop'] ?? 0.0);
            if (kDebugMode) {
              print('Parsed GNGSA data: $_accumulatedData');
            }
          }
          break;

        default:
          if (kDebugMode) {
            print('Unhandled NMEA sentence: $sentence');
          }
          break;
      }
    }

    if (kDebugMode) {
      print('Accumulated GPS data: $_accumulatedData');
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    if (_accumulatedData.containsKey('latitude') && _accumulatedData.containsKey('longitude')) {
      return LatLng(
        _accumulatedData['latitude'] as double,
        _accumulatedData['longitude'] as double,
      );
    }
    return null;
  }
*/
  double _calculateAccuracy(double pdop, double hdop, double vdop) {
    // This is a more comprehensive approximation using all three DOP values
    // We're using a base accuracy of 2 meters (you may need to adjust this based on your GPS module's specifications)
    // Then converting to feet (1 meter = 3.28084 feet)
    double baseAccuracy = 0.5; // in meters
    double horizontalError = baseAccuracy * hdop;
    double verticalError = baseAccuracy * vdop;
    double positionError = baseAccuracy * pdop;

    // Using the root mean square to combine the errors
    double combinedError = sqrt(pow(horizontalError, 2) + pow(verticalError, 2) + pow(positionError, 2));

    return combinedError * 3.28084; // Convert to feet
  }

  DateTime _parseTimestamp(String time, String date) {
    if (time.length >= 6 && date.length == 6) {
      final hours = int.tryParse(time.substring(0, 2)) ?? 0;
      final minutes = int.tryParse(time.substring(2, 4)) ?? 0;
      final seconds = int.tryParse(time.substring(4, 6)) ?? 0;
      final day = int.tryParse(date.substring(0, 2)) ?? 1;
      final month = int.tryParse(date.substring(2, 4)) ?? 1;
      final year = 2000 + (int.tryParse(date.substring(4, 6)) ?? 0);
      return DateTime.utc(year, month, day, hours, minutes, seconds);
    }
    return DateTime.now();
  }

  double _convertKnotsToMph(double knots) {
    return knots * 1.15078;
  }

  double _convertNmeaToDecimal(String value, String direction) {
    if (kDebugMode) {
      print('Converting NMEA to decimal: value=$value, direction=$direction');
    }
    final decimalDegrees = double.tryParse(value) ?? 0.0;
    final degrees = decimalDegrees ~/ 100;
    final minutes = decimalDegrees % 100;
    var result = degrees + (minutes / 60);
    if (direction == 'S' || direction == 'W') {
      result = -result;
    }
    if (kDebugMode) {
      print('Converted result: $result');
    }
    return result;
  }

  Future<void> stopGps() async {
    _isRunning = false;
    _updateTimer?.cancel();
    await _subscription?.cancel();
    await _device?.disconnect();
    _device = null;
    _characteristic = null;
  }

  void dispose() {
    stopGps();
    _gpsDataController.close();
  }
}
