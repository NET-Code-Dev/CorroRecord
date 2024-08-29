import 'dart:async';

//import 'package:asset_inspections/Pokit_Multimeter/Models/mmservice_model.dart';
//import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'package:asset_inspections/Pokit_Multimeter/Utility/range_enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// This file contains the definition of the `Mode` enum and its extension methods.
/// The `Mode` enum represents different modes of operation for a multimeter.
/// Each mode is associated with a numeric value and a corresponding mode name.
/// The extension methods provide convenient access to the numeric value and mode name for a given mode.
enum Mode {
  idle, // 0
  dcVoltage, // 1
  acVoltage, // 2
  dcCurrent, // 3
  acCurrent, // 4
  resistance, // 5
  diode, // 6
  continuity, // 7
  temperature, // 8
  capacitance, // 9
  externalTemperature // 10
}

extension ModeValue on Mode {
  int get value {
    switch (this) {
      case Mode.idle:
        return 0;
      case Mode.dcVoltage:
        return 1;
      case Mode.acVoltage:
        return 2;
      case Mode.dcCurrent:
        return 3;
      case Mode.acCurrent:
        return 4;
      case Mode.resistance:
        return 5;
      case Mode.diode:
        return 6;
      case Mode.continuity:
        return 7;
      case Mode.temperature:
        return 8;
      case Mode.capacitance:
        return 9;
      case Mode.externalTemperature:
        return 10;
      default:
        return 0;
    }
  }

  String get modeName {
    switch (this) {
      case Mode.idle:
        return 'Idle';
      case Mode.dcVoltage:
        return 'DC Voltage';
      case Mode.acVoltage:
        return 'AC Voltage';
      case Mode.dcCurrent:
        return 'DC Current';
      case Mode.acCurrent:
        return 'AC Current';
      case Mode.resistance:
        return 'Resistance';
      case Mode.diode:
        return 'Diode';
      case Mode.continuity:
        return 'Continuity';
      case Mode.temperature:
        return 'Temperature';
      case Mode.capacitance:
        return 'Capacitance';
      case Mode.externalTemperature:
        return 'External Temperature';
      default:
        return 'Idle';
    }
  }
}

/// Enum representing the status of a multimeter.
enum MeterStatus {
  autoRangeOff, // 0
  autoRangeOn, // 1
  noContinuity, // Also 0 in continuity mode
  continuity, // Also 1 in continuity mode
  ok, // 0 in diode mode
  error // 255 in all modes
}

extension MeterStatusValue on MeterStatus {
  /// Returns the integer value corresponding to the meter status for a given mode.
  ///
  /// The value is determined based on the mode and the meter status.
  /// For resistance, DC voltage, AC voltage, DC current, and AC current modes,
  /// the value is 0 if the meter status is autoRangeOff, 1 if it is autoRangeOn,
  /// and 255 for any other status.
  /// For continuity mode, the value is 0 if the meter status is noContinuity,
  /// 1 if it is continuity, and 255 for any other status.
  /// For diode and temperature modes, the value is 0 if the meter status is ok,
  /// and 255 for any other status.
  /// For any other mode, the value is always 255.
  int value(Mode mode) {
    switch (mode) {
      case Mode.resistance:
      case Mode.dcVoltage:
      case Mode.acVoltage:
      case Mode.dcCurrent:
      case Mode.acCurrent:
        return this == MeterStatus.autoRangeOff
            ? 0
            : this == MeterStatus.autoRangeOn
                ? 1
                : 255; // Error or default
      case Mode.continuity:
        return this == MeterStatus.noContinuity
            ? 0
            : this == MeterStatus.continuity
                ? 1
                : 255; // Error or default
      case Mode.diode:
      case Mode.temperature:
        return this == MeterStatus.ok ? 0 : 255; // Error or default
      default:
        return 255; // Error or default for other modes
    }
  }

  /// Returns the string representation of the meter status for a given mode.
  ///
  /// The string representation is determined based on the mode and the meter status.
  /// For resistance, DC voltage, AC voltage, DC current, and AC current modes,
  /// the string is "Auto Range Off" if the meter status is autoRangeOff,
  /// "Auto Range On" if it is autoRangeOn, and "Error" for any other status.
  /// For continuity mode, the string is "No Continuity" if the meter status is noContinuity,
  /// "Continuity" if it is continuity, and "Error" for any other status.
  /// For diode and temperature modes, the string is "OK" if the meter status is ok,
  /// and "Error" for any other status.
  /// For any other mode, the string is always "Error".
  String stringValue(Mode mode) {
    switch (mode) {
      case Mode.resistance:
      case Mode.dcVoltage:
      case Mode.acVoltage:
      case Mode.dcCurrent:
      case Mode.acCurrent:
        return this == MeterStatus.autoRangeOff
            ? "Auto Range Off"
            : this == MeterStatus.autoRangeOn
                ? "Auto Range On"
                : "Error";
      case Mode.continuity:
        return this == MeterStatus.noContinuity
            ? "No Continuity"
            : this == MeterStatus.continuity
                ? "Continuity"
                : "Error";
      case Mode.diode:
      case Mode.temperature:
        return this == MeterStatus.ok ? "OK" : "Error";
      default:
        return "Error";
    }
  }
}

/// Represents a reading from a multimeter.
class Reading {
  /// The status of the meter.
  final MeterStatus status;

  /// The measured value.
  double value;

  /// The mode of the meter.
  final Mode mode;

  /// The range of the meter.
  final int range;

  /// The range string of the meter.
  String? rangeString;

  /// Creates a new instance of the [Reading] class.
  ///
  /// The [status], [value], [mode], and [range] parameters are required.
  /// The [rangeString] parameter is optional.
  Reading({
    required this.status,
    required this.value,
    required this.mode,
    required this.range,
    required String rangeString,
  });
}

/// Represents the settings for a multimeter.
class Settings {
  final Mode mode;
  final int range;
  final int updateInterval;

  /// Creates a new instance of the [Settings] class.
  ///
  /// The [mode] parameter specifies the mode of the multimeter.
  /// The [range] parameter specifies the range of the multimeter.
  /// The [updateInterval] parameter specifies the update interval of the multimeter.
  Settings({required this.mode, required this.range, required this.updateInterval});
}

/// A service class that provides functionality for interacting with a multimeter device.
class MultimeterService with ChangeNotifier {
  // UUIDs for the Multimeter service and characteristics
  static const String multimeterServiceUUID = 'e7481d2f-5781-442e-bb9a-fd4e3441dadc';
  static const String settingsCharacteristicUUID = '53dc9a7a-bc19-4280-b76b-002d0e23b078';
  static const String readingCharacteristicUUID = '047d3559-8bee-423a-b229-4417fa603b90';

  static const Duration retryDelay = Duration(milliseconds: 500); // Delay between retries

  // Private members to manage the Bluetooth device and characteristics
  BluetoothDevice? _device; // The connected Bluetooth device.

  // The following two characteristics are used to communicate with the Pokit Meter
  BluetoothCharacteristic? _settingsCharacteristic;
  BluetoothCharacteristic? _readingCharacteristic;

  StreamSubscription? _readingSubscription;

  // Private members to store the current reading and settings
  Reading? _currentReading;
  double? _minReading;
  double? _maxReading;

  // Public getters
  Reading get currentReading => _currentReading!;

  double? get minReading => _minReading;
  double? get maxReading => _maxReading;

  // ignore: unused_field
  Mode _selectedMode = Mode.idle;

  void setSelectedMode(Mode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  //MultimeterService() {}

  static final MultimeterService instance = MultimeterService._();

  MultimeterService._();

  final StreamController<double> _readingStreamController = StreamController<double>.broadcast();
  Stream<double> get currentReadingStream => _readingStreamController.stream;

  final StreamController<double> _minReadingStreamController = StreamController<double>.broadcast();
  Stream<double> get minReadingStream => _minReadingStreamController.stream;

  final StreamController<double> _maxReadingStreamController = StreamController<double>.broadcast();
  Stream<double> get maxReadingStream => _maxReadingStreamController.stream;

  void setDevice(BluetoothDevice device) {
    _device = device;
  }

  /// Initializes the multimeter service by discovering the Bluetooth services and characteristics.
  /// If the Bluetooth device is not set, an error message is printed.
  /// If an exception occurs during the initialization process, the exception is caught and handled accordingly.
  Future<void> initialize() async {
    if (_device == null) {
      if (kDebugMode) {
        print('Error: Bluetooth device is not set.');
      }
      //TODO: Handle the error accordingly...
      return;
    }

    try {
      List<BluetoothService> services = await _device!.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == multimeterServiceUUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == settingsCharacteristicUUID) {
              _settingsCharacteristic = characteristic;
              if (kDebugMode) {
                print('Settings characteristic found: ${characteristic.uuid}');
              }
            } else if (characteristic.uuid.toString() == readingCharacteristicUUID) {
              _readingCharacteristic = characteristic;
              if (kDebugMode) {
                print('Reading characteristic found: ${characteristic.uuid}');
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Bluetooth services: $e');
      }
      //TODO: Handle the exception by retrying or notifying the user.
    }
  }

  /// Writes the provided [settings] to the settings characteristic of the multimeter service.
  /// The [settings] include the mode, range, and update interval.
  /// The [settings] are converted into a byte array and written to the characteristic.
  /// If the settings characteristic is not available, the write operation is skipped.
  /// After writing the settings, the listeners are notified.
  Future<void> writeSettings(Settings settings) async {
    if (_settingsCharacteristic != null) {
      List<int> data = Uint8List(6);
      data[0] = settings.mode.index;
      data[1] = settings.range;
      data[2] = settings.updateInterval & 0xFF;
      data[3] = (settings.updateInterval >> 8) & 0xFF;
      data[4] = (settings.updateInterval >> 16) & 0xFF;
      data[5] = (settings.updateInterval >> 24) & 0xFF;

      if (kDebugMode) {
        print('Writing settings: $data');
      }
      await _settingsCharacteristic!.write(data);
      if (kDebugMode) {
        print('Settings written successfully');
      }
    } else {
      if (kDebugMode) {
        print('Settings characteristic is null');
      }
    }
    notifyListeners();
  }

/*
  // This method will write the given settings to the Settings characteristic
  Future<bool> writeSettings(MMSettingsModel settings) async {
    if (_settingsCharacteristic != null) {
      List<int> data = Uint8List(6);
      data[0] = settings.mode.index; // Mode as integer value
      data[1] = settings.range; // Range as integer value
      data[2] = settings.updateInterval & 0xFF; // Split updateInterval into bytes
      data[3] = (settings.updateInterval >> 8) & 0xFF;
      data[4] = (settings.updateInterval >> 16) & 0xFF;
      data[5] = (settings.updateInterval >> 24) & 0xFF;

      bool writeSuccessful = false;
      int retries = 0;

      try {
        await _settingsCharacteristic!.write(data);
        writeSuccessful = true;
      } catch (e) {
        print('Write attempt $retries failed: $e');
        if (e is PlatformException && e.code == 'ERROR_GATT_WRITE_REQUEST_BUSY') {
          await Future.delayed(retryDelay);
          retries++;
        }
      }
      if (writeSuccessful) {
        notifyListeners();
      } else {
        print('writeSettings failed after attempts.');
      }

      return writeSuccessful;
    }
    return false;
  }
*/

  /// Subscribes to the service and reading for the specified [selectedMode].
  ///
  /// This method ensures that the necessary services and characteristics are discovered and identified.
  /// It then writes the initial settings to the Settings characteristic to start the Multimeter mode.
  /// Finally, it subscribes to the Reading characteristic.
  ///
  /// This method notifies listeners after completing the subscription.
  Future<void> subscribeToServiceAndReading(Mode selectedMode) async {
    // First, ensure that we have discovered services and identified the needed characteristics
    if (_settingsCharacteristic == null || _readingCharacteristic == null) {
      await initialize();
    }

    // Next, write to the Settings characteristic to start the Multimeter mode
    Settings initialSettings = Settings(
      mode: selectedMode,
      range: 255, // Auto Range
      updateInterval: 100, // Interval is in milliseconds
    );
    await writeSettings(initialSettings);

    // Finally, subscribe to Reading
    if (_readingSubscription == null) {
      await subscribeToReading();
    }
    notifyListeners();
  }

  /// Subscribes to the reading characteristic and listens for data updates.
  /// If the reading characteristic is not null, it sets the notify value to true and
  /// starts listening to the last value stream. When data is received, it calls the
  /// [_onDataReceived] method and updates the UI by notifying listeners.
  /// If an error occurs during the stream, it prints the error message in debug mode.
  Future<void> subscribeToReading() async {
    if (_readingCharacteristic != null) {
      if (kDebugMode) {
        print('Subscribing to Reading characteristic: $_readingCharacteristic');
      }
      await _readingCharacteristic!.setNotifyValue(true);
      _readingSubscription = _readingCharacteristic!.lastValueStream.listen((data) {
        _onDataReceived(data);
        // Notify listeners to update the UI
        //   notifyListeners();
      }, onError: (error) {
        if (kDebugMode) {
          print('Stream error: $error');
        }
      });
    } else {
      if (kDebugMode) {
        print('Reading characteristic is null');
      }
    }
  }

  // Stop listening to notifications from the Reading characteristic
  /// Unsubscribes from the reading characteristic.
  ///
  /// This method disables the notification for the reading characteristic and cancels any active subscription.
  /// It also clears the reference to the reading subscription.
  ///
  /// Throws an exception if the reading characteristic is null.
  Future<void> unsubscribeFromReading() async {
    if (_readingCharacteristic != null) {
      await _readingCharacteristic!.setNotifyValue(false);
      await _readingSubscription?.cancel();
      _readingSubscription = null; // Clear the reference
    }
  }

/*
  void _printPacketDetails(List<int> data) {
    for (int i = 0; i < data.length; i++) {
      if (kDebugMode) {
        print("Byte $i: ${data[i]}");
      }
    }
  }
*/
  /// Callback function that is called when data is received.
  /// It processes the received data and prints the packet details.
  /// It also notifies the listeners and prints the reading characteristic.
  void _onDataReceived(List<int> data) async {
    if (kDebugMode) {
      print("Data received: $data");
    } // Check if data is received
    //   _printPacketDetails(data);
    _processReceivedData(data);
    //  notifyListeners();
    //  print(_readingCharacteristic);
  }

  /// Processes the received data from the multimeter servive.
  ///
  /// The [data] parameter is a list of integers representing the received data.
  /// If the length of the data is not 7, the function returns without processing.
  /// The function extracts various values from the received data, such as the status,
  /// value, mode, range, and range string. It updates the minimum and maximum readings
  /// based on the current reading value. It also notifies the listeners about the
  /// current reading, minimum reading, and maximum reading. If the received status
  /// is 255, indicating an error, the function returns without further processing.
  /// If the received mode is invalid, the function returns without further processing.
  /// The function handles different modes and their corresponding range values to
  /// determine the range string. It also adds the current reading, minimum reading,
  /// and maximum reading to their respective stream controllers if they are open
  /// and have listeners. Finally, the function catches any errors that occur during
  /// the processing and prints them in debug mode.
  void _processReceivedData(List<int> data) {
    if (data.length != 7) {
      return;
    }
    try {
      ByteData byteData = ByteData.sublistView(Uint8List.fromList(data));

      int receivedStatus = byteData.getUint8(0);
      if (receivedStatus == 255) {
        if (kDebugMode) {
          print("Error status received");
        }
        return;
      }

      double value = byteData.getFloat32(1, Endian.little);
      // Update the min and max readings based on the currentReading

      int receivedMode = byteData.getUint8(5);
      if (receivedMode > 8) {
        if (kDebugMode) {
          print("Invalid mode value: $receivedMode");
        }
        return;
      }

      Mode mode = Mode.values.elementAt(receivedMode);
      MeterStatus status;
      status = MeterStatus.values.elementAt(receivedStatus);

      if (kDebugMode) {
        print('Received Status: $receivedStatus, Value: $value, Mode: $receivedMode');
      }

      int rangeValue = byteData.getUint8(6);
      String? rangeString;

      // Directly assign "No Range" for modes where range is N/A
      if (mode == Mode.diode || mode == Mode.continuity || mode == Mode.temperature) {
        rangeString = "No Range";
      } else {
        // For modes where rangeValue is applicable
        if (rangeValue == 255) {
          rangeString = "Auto Range";
        } else {
          // Handle the conversion from rangeValue to rangeString for applicable modes
          switch (mode) {
            case Mode.capacitance:
              rangeString = CapacitanceRange.capacitanceRangeToString(CapacitanceRangeEnum.values[rangeValue]);
              break;
            case Mode.dcVoltage:
            case Mode.acVoltage:
              rangeString = VoltageRange.voltageRangeToString(VoltageRangeEnum.values[rangeValue]);
              break;
            case Mode.dcCurrent:
            case Mode.acCurrent:
              rangeString = CurrentRange.currentRangeToString(CurrentRangeEnum.values[rangeValue]);
              break;
            case Mode.resistance:
              rangeString = ResistanceRange.resistanceRangeToString(ResistanceRangeEnum.values[rangeValue]);
              break;
            default:
              rangeString = 'Unknown';
              break;
          }
        }
      }

      if (kDebugMode) {
        print('$_maxReading, $_minReading');
      }

      if (kDebugMode) {
        print("Processed Data: $status, $value, $mode, $rangeValue, $rangeString");
      }
      _currentReading = Reading(status: status, value: value, mode: mode, range: rangeValue, rangeString: rangeString);

      if (kDebugMode) {
        print('$value 1');
      }
      if (_minReading == null || value < _minReading!) {
        _minReading = value;
        notifyListeners();
        if (kDebugMode) {
          print('Min Reading:$_minReading');
        }
      }
      if (kDebugMode) {
        print('$value 2');
      }
      if (_maxReading == null || value > _maxReading!) {
        _maxReading = value;
        notifyListeners();
        if (kDebugMode) {
          print('Max Reading:$_maxReading');
        }
      }
      if (kDebugMode) {
        print('Min Reading: $_minReading, Max Reading: $_maxReading');
      }
      if (kDebugMode) {
        print('Updating listeners with Current Reading: $_currentReading');
      }
      notifyListeners();
      if (!_readingStreamController.isClosed && _readingStreamController.hasListener) {
        _readingStreamController.add(value);
      }

      if (!_minReadingStreamController.isClosed && _minReadingStreamController.hasListener) {
        _minReadingStreamController.add(_minReading!);
      }

      if (!_maxReadingStreamController.isClosed && _maxReadingStreamController.hasListener) {
        _maxReadingStreamController.add(_maxReading!);
      }

      // notifyListeners();
      //  print('Current Reading: $_currentReading');
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  /// Resets the minimum and maximum readings of the multimeter service.
  ///
  /// This method sets the [_minReading] and [_maxReading] variables to null,
  /// indicating that there are no minimum and maximum readings recorded.
  /// After resetting the readings, it notifies the listeners that a change has occurred.
  void resetMinMaxReadings() {
    _minReading = null;
    _maxReading = null;

    // Notify listeners that a change has occurred
    notifyListeners();
  }
}
