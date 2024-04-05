import 'package:asset_inspections/Pokit_Multimeter/Services/dso_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// This file contains the models for the DSO (Digital Storage Oscilloscope) service.
/// It defines two enums: `Command` and `Mode`.
///
/// The `Command` enum represents different commands that can be sent to the DSO service.
/// It has the following values:
/// - `freeRunning`: Represents the free running command.
/// - `risingEdge`: Represents the rising edge command.
/// - `fallingEdge`: Represents the falling edge command.
/// - `resend`: Represents the resend command.
///
/// The `CommandValue` extension provides additional functionality to the `Command` enum.
/// It defines two getters:
/// - `value`: Returns the integer value associated with each command.
/// - `commandName`: Returns the string representation of each command.
///
/// The `Mode` enum represents different modes of operation for the DSO service.
/// It has the following values:
/// - `idle`: Represents the idle mode.
/// - `dcVoltage`: Represents the DC voltage mode.
/// - `acVoltage`: Represents the AC voltage mode.
/// - `dcCurrent`: Represents the DC current mode.
/// - `acCurrent`: Represents the AC current mode.
///
/// The `ModeValue` extension provides additional functionality to the `Mode` enum.
/// It defines two getters:
/// - `value`: Returns the integer value associated with each mode.
/// - `modeName`: Returns the string representation of each mode.
enum Command {
  freeRunning,
  risingEdge,
  fallingEdge,
  resend,
}

extension CommandValue on Command {
  int get value {
    switch (this) {
      case Command.freeRunning:
        return 0;
      case Command.risingEdge:
        return 1;
      case Command.fallingEdge:
        return 2;
      case Command.resend:
        return 3;
      default:
        return 0;
    }
  }

  String get commandName {
    switch (this) {
      case Command.freeRunning:
        return 'Free Running';
      case Command.risingEdge:
        return 'Rising Edge';
      case Command.fallingEdge:
        return 'Falling Edge';
      case Command.resend:
        return 'Resend';
      default:
        return 'Free Running';
    }
  }
}

enum Mode {
  idle,
  dcVoltage,
  acVoltage,
  dcCurrent,
  acCurrent,
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
      default:
        return 'Idle';
    }
  }
}

/// Represents a model for the DSO service.
class DSOServiceModel {
  BluetoothService service;
  DSOSettingsModel? dsoSettingsModel;
  DSOReadingModel? dsoReadingModel;
  DSOMetadataModel? dsoMetadataModel;

  BluetoothCharacteristic? _settingsCharacteristic;
  BluetoothCharacteristic? _readingCharacteristic;

  DSOServiceModel(this.service);

  /// Discovers the DSO service by iterating through the characteristics of the Bluetooth service.
  Future<void> discoverDSOService() async {
    for (var characteristic in service.characteristics) {
      try {
        if (characteristic.properties.read) {
          var characteristicUUID = characteristic.uuid.toString();
          var data = await characteristic.read();

          if (characteristicUUID == DSOService.dsoSettingCharacteristicUUID) {
            _settingsCharacteristic = characteristic;
            dsoSettingsModel = DSOService.initializeDSOSettingsCharacteristic(characteristic);
          } else if (characteristicUUID == DSOService.dsoReadingCharacteristicUUID) {
            _readingCharacteristic = characteristic;
            dsoReadingModel = DSOService.handleDSOReadingCharacteristic(characteristic, data);
          } else if (characteristicUUID == DSOService.dsoMetadataCharacteristicUUID) {
            dsoMetadataModel = DSOService.handleDSOMetadataCharacteristic(characteristic, data);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        continue;
      }
    }
  }
}

/// Represents the settings model for the DSO service.
class DSOSettingsModel {
  BluetoothCharacteristic? bluetoothCharacteristic;
  Command command;
  int? triggerLevel;
  Mode mode;
  int range;
  int sampleWindow;
  int sampleCount;

  DSOSettingsModel({
    required this.bluetoothCharacteristic,
    required this.command,
    this.triggerLevel,
    required this.mode,
    required this.range,
    required this.sampleWindow,
    required this.sampleCount,
  });
}

/// Represents the metadata model for the DSO service.
class DSOMetadataModel {
  int status;
  double scale;
  int mode;
  int range;
  int samplingWindow;
  int numberOfSamples;
  int samplingRate;

  DSOMetadataModel({
    this.status = 0,
    this.scale = 1.0,
    this.mode = 0,
    this.range = 0,
    this.samplingWindow = 0,
    this.numberOfSamples = 0,
    this.samplingRate = 0,
  });
}

/// Represents the reading model for the DSO service.
class DSOReadingModel {
  List<int> samples;

  DSOReadingModel({this.samples = const []});

  /// Applies the given scale to each sample in the reading model and returns the real values.
  List<double> applyScale(double scale) {
    // Apply the scale to each sample to get the real value
    return samples.map((sample) => sample * scale).toList();
  }
}
