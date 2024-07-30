import 'dart:async';

import 'package:asset_inspections/Pokit_Multimeter/Services/mm_service.dart';
import 'package:asset_inspections/Pokit_Multimeter/Utility/range_enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Enum for Modes
/// This file contains the [Mode] enum and its extension [ModeValue].
/// The [Mode] enum represents different modes of a multimeter.
/// Each mode is associated with a numeric value and a mode name.
/// The [ModeValue] extension provides methods to get the numeric value and mode name for a given mode.
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
  /// Returns the numeric value associated with the mode.
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

  /// Returns the mode name associated with the mode.
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

/// Represents the status of a multimeter.
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
  /// the value is 0 if the meter status is autoRangeOff, 1 if the meter status is autoRangeOn,
  /// and 255 for all other cases.
  /// For continuity mode, the value is 0 if the meter status is noContinuity,
  /// 1 if the meter status is continuity, and 255 for all other cases.
  /// For diode and temperature modes, the value is 0 if the meter status is ok,
  /// and 255 for all other cases.
  /// For other modes, the value is always 255.
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
  /// The string value is determined based on the mode and the meter status.
  /// For resistance, DC voltage, AC voltage, DC current, and AC current modes,
  /// the string value is "Auto Range Off" if the meter status is autoRangeOff,
  /// "Auto Range On" if the meter status is autoRangeOn, and "Error" for all other cases.
  /// For continuity mode, the string value is "No Continuity" if the meter status is noContinuity,
  /// "Continuity" if the meter status is continuity, and "Error" for all other cases.
  /// For diode and temperature modes, the string value is "OK" if the meter status is ok,
  /// and "Error" for all other cases.
  /// For other modes, the string value is always "Error".
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

/// Represents the model for the Pokit Meter service.
class MMServiceModel {
  BluetoothService service;
  MMReadingModel? mmReadingModel;
  MMSettingsModel? mmSettingsModel;

  // The following two characteristics are used to communicate with the Pokit Meter
  BluetoothCharacteristic? settingsCharacteristic;
  // BluetoothCharacteristic? _readingCharacteristic;

  // Private members to store the current reading and settings
//  MMReadingModel? _currentReading;
//  MMSettingsModel? _currentSettings;

  MMServiceModel(this.service);

  /// Discovers the MMService by iterating through the characteristics of the service.
  /// For each characteristic, if it has the read property, it reads the data from the characteristic.
  /// If the characteristic UUID matches the MMService's mmReadingCharacteristicUUID,
  /// it calls the handleMMReadingCharacteristic method to handle the characteristic and data.
  /// If the characteristic UUID matches the MMService's mmSettingsCharacteristicUUID,
  /// it calls the initializeMMSettingsCharacteristic method to initialize the characteristic.
  /// If an error occurs while reading a characteristic, it prints the error message and continues to the next characteristic.
  Future<void> discoverMMService() async {
    for (var characteristic in service.characteristics) {
      try {
        if (characteristic.properties.read) {
          var characteristicUUID = characteristic.uuid.toString();
          var data = await characteristic.read();

          if (characteristicUUID == MMService.mmReadingCharacteristicUUID) {
            mmReadingModel = MMService.handleMMReadingCharacteristic(characteristic, data);
          } else if (characteristicUUID == MMService.mmSettingsCharacteristicUUID) {
            mmSettingsModel = MMService.initializeMMSettingsCharacteristic(characteristic);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error while reading characteristic: ${characteristic.uuid}');
        }
        if (kDebugMode) {
          print(e);
        }
        continue;
      }
    }
  }

  /// Initializes the MMService with the specified Bluetooth device and selected mode.
  ///
  /// The [device] parameter represents the Bluetooth device to be used.
  /// The [selectedMode] parameter represents the mode to be set.
  ///
  /// The [initializeWithDevice] method prepares the initial settings for the MMService
  /// using the specified [device] and [selectedMode]. It creates an instance of the
  /// [MMSettingsModel] class with the specified [selectedMode], a range of 255 (Auto Range),
  /// and an update interval of 1000 milliseconds. It then calls the [_prepareSettingsData]
  /// method to prepare the settings data.
  ///
  /// Throws an exception if an error occurs during the initialization process.
  Future<void> initializeWithDevice(BluetoothDevice device, Mode selectedMode) async {
    MMSettingsModel initialSettings = MMSettingsModel(
      mode: selectedMode,
      range: 255, // Auto Range
      updateInterval: 1000, // Interval is in milliseconds
    );

    await _prepareSettingsData(initialSettings);
  }

  /// Prepares the settings data for the MMService.
  ///
  /// Takes a [settings] object of type [MMSettingsModel] and prepares the data
  /// to be written to the settings characteristic. The data includes the mode,
  /// range, and update interval values. The update interval is split into bytes
  /// and stored in a Uint8List of 6 bytes. Finally, the data is written to the
  /// settings characteristic.
  ///
  /// Throws an exception if the settings characteristic is null.
  Future<void> _prepareSettingsData(MMSettingsModel settings) async {
    var data = Uint8List(6); // Create a Uint8List of 6 bytes
    data[0] = settings.mode.index; // Mode as integer value
    data[1] = settings.range; // Range as integer value
    data[2] = settings.updateInterval & 0xFF; // Split updateInterval into bytes
    data[3] = (settings.updateInterval >> 8) & 0xFF;
    data[4] = (settings.updateInterval >> 16) & 0xFF;
    data[5] = (settings.updateInterval >> 24) & 0xFF;

    await settingsCharacteristic?.write(data, withoutResponse: false);
  }
}

/// Model class representing a multimeter reading from the Pokit Pro.
class MMReadingModel {
  BluetoothCharacteristic? bluetoothCharacteristic;
  final MeterStatus status;
  final double value;
  final Mode mode;
  final int range;
  String? rangeString;
  // String? statusString;

  /// Constructs a new [MMReadingModel] instance.
  ///
  /// [bluetoothCharacteristic] is the Bluetooth characteristic associated with the reading.
  /// [status] is the status of the reading.
  /// [value] is the measured value.
  /// [mode] is the measurement mode.
  /// [range] is the measurement range.
  /// [rangeString] is the string representation of the measurement range.
  MMReadingModel({
    this.bluetoothCharacteristic,
    required this.status,
    required this.value,
    required this.mode,
    required this.range,
    required String rangeString,
    // required String statusString
  }) {
    // statusString = status.stringValue(mode);
    switch (mode) {
      case Mode.capacitance:
        rangeString = CapacitanceRange.capacitanceRangeToString(CapacitanceRangeEnum.values[range]);
        break;
      case Mode.dcVoltage:
      case Mode.acVoltage:
        // Assuming voltage range applies to both DC and AC Voltage
        rangeString = VoltageRange.voltageRangeToString(VoltageRangeEnum.values[range]);
        break;
      case Mode.dcCurrent:
      case Mode.acCurrent:
        // Assuming current range applies to both DC and AC Current
        rangeString = CurrentRange.currentRangeToString(CurrentRangeEnum.values[range]);
        break;
      case Mode.resistance:
        rangeString = ResistanceRange.resistanceRangeToString(ResistanceRangeEnum.values[range]);
        break;
      default:
        rangeString = 'Error';
    }
  }
}

/// Model class representing multimeter settings for the Pokit Pro.
class MMSettingsModel {
  BluetoothCharacteristic? bluetoothCharacteristic;
  Mode mode;
  //RangeSetting range;
  int range;
  int updateInterval;

  /// Constructs a new [MMSettingsModel] instance.
  ///
  /// [bluetoothCharacteristic] is the Bluetooth characteristic used for communication.
  /// [mode] is the mode of the multimeter.
  /// [range] is the range setting of the multimeter.
  /// [updateInterval] is the interval at which the multimeter updates its readings.
  MMSettingsModel({
    this.bluetoothCharacteristic,
    this.mode = Mode.idle, // Default to IDLE mode using enum
    required this.range, // Require a RangeSetting object
    this.updateInterval = 1000, // Default to 1-second interval, adjust as needed
  });

  /// Writes the [settings] to the multimeter service.
  ///
  /// The [settings] parameter is an instance of [MMSettingsModel] that contains the settings to be written.
  /// The settings include the mode, range, and update interval.
  /// The mode is represented as an integer value.
  /// The range is represented as an integer value.
  /// The update interval is split into four bytes and stored in a [Uint8List].
  /// The [writeSettings] method uses the Bluetooth characteristic to write the settings data.
  /// If the [kDebugMode] flag is enabled, a debug message is printed.
  ///
  /// Throws an exception if the write operation fails.
  Future<void> writeSettings(MMSettingsModel settings) async {
    if (kDebugMode) {
      print('Writing settings in multimeterservice.dart called');
    }
    List<int> data = Uint8List(6); // Assuming a total of 6 bytes as described
    data[0] = settings.mode.index; // Mode as integer value
    data[1] = settings.range; // Range as integer value
    data[2] = settings.updateInterval & 0xFF; // Split updateInterval into bytes
    data[3] = (settings.updateInterval >> 8) & 0xFF;
    data[4] = (settings.updateInterval >> 16) & 0xFF;
    data[5] = (settings.updateInterval >> 24) & 0xFF;

    await bluetoothCharacteristic?.write(data, withoutResponse: false);
  }

  /// Creates an instance of [MMSettingsModel] from the provided parameters.
  ///
  /// The [bluetoothCharacteristic] parameter is the Bluetooth characteristic associated with the multimeter service.
  /// The [modeString] parameter is the string representation of the mode.
  /// The [rangeString] parameter is the string representation of the range.
  /// The [updateInterval] parameter is the interval at which the multimeter readings should be 0.
  ///
  /// Returns an instance of [MMSettingsModel] with the specified settings.
  factory MMSettingsModel.fromString(
      {required BluetoothCharacteristic bluetoothCharacteristic,
      required String modeString,
      required String rangeString,
      required int updateInterval}) {
    Mode mode = Mode.values.firstWhere((m) => m.modeName == modeString, orElse: () => Mode.idle);
    int range;
    switch (mode) {
      case Mode.capacitance:
        range = CapacitanceRange.capacitanceRangeFromString(rangeString) ?? 0;
        break;
      case Mode.dcVoltage:
      case Mode.acVoltage:
        // Assuming voltage range applies to both DC and AC Voltage
        range = VoltageRange.voltageRangeFromString(rangeString) ?? 0;
        break;
      case Mode.dcCurrent:
      case Mode.acCurrent:
        // Assuming current range applies to both DC and AC Current
        range = CurrentRange.currentRangeFromString(rangeString) ?? 0;
        break;
      case Mode.resistance:
        range = ResistanceRange.resistanceRangeFromString(rangeString) ?? 0;
        break;
      default:
        range = 0;
    }
    return MMSettingsModel(bluetoothCharacteristic: bluetoothCharacteristic, mode: mode, range: range, updateInterval: updateInterval);
  }
}
