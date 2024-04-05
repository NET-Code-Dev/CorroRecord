import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:asset_inspections/Pokit_Multimeter/Services/status_service.dart';

/// Represents a model for the Status Service.
/// This model contains various characteristics related to the status service,
/// such as device name, device characteristic, status characteristic, LED characteristic, torch characteristic, and button characteristic.
class StatusServiceModel {
  final BluetoothService service;
  DeviceNameCharacteristicModel? deviceNameCharacteristicModel;
  DeviceCharacteristicModel? deviceCharacteristicModel;
  StatusCharacteristicModel? statusCharacteristicModel;
  LEDCharacteristicModel? ledCharacteristicModel;
  TorchCharacteristicModel? torchCharacteristicModel;
  ButtonCharacteristicModel? buttonCharacteristicModel;

  StatusServiceModel(this.service);

  /// Discovers the characteristics and descriptors of the status service.
  /// This method iterates through the service characteristics and assigns the corresponding characteristic models based on their UUIDs.
  Future<void> discoverStatusService() async {
    for (var characteristic in service.characteristics) {
      var characteristicUUID = characteristic.uuid.toString();
      var data = await characteristic.read();

      if (characteristicUUID == StatusService.deviceCharacteristicUUID) {
        deviceCharacteristicModel = StatusService.handleDeviceCharacteristic(characteristic, data);
      } else if (characteristicUUID == StatusService.statusCharacteristicUUID) {
        statusCharacteristicModel = StatusService.handleStatusCharacteristic(characteristic, data);
      } else if (characteristicUUID == StatusService.nameCharacteristicUUID) {
        deviceNameCharacteristicModel = StatusService.handleDeviceNameCharacteristic(characteristic, data);
      } else if (characteristicUUID == StatusService.ledCharacteristicUUID) {
        ledCharacteristicModel = StatusService.handleLEDCharacteristic(characteristic, data);
      } else if (characteristicUUID == StatusService.torchCharacteristicUUID) {
        torchCharacteristicModel = StatusService.handleTorchCharacteristic(characteristic, data);
      } else if (characteristicUUID == StatusService.buttonCharacteristicUUID) {
        buttonCharacteristicModel = StatusService.handleButtonCharacteristic(characteristic, data);
      }
      // ... other cases ...
    }
  }
}

/// Represents a model for device characteristics.
class DeviceCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  String? version;
  int? maxVoltage;
  int? maxCurrent;
  int? maxResistance;
  int? maxSampleRate;
  int? sampleBufferSize;
  int? capabilityMask;
  String? macAddress;

  /// Constructs a [DeviceCharacteristicModel] with the given parameters.
  DeviceCharacteristicModel({
    required this.bluetoothCharacteristic,
    this.version,
    this.maxVoltage,
    this.maxCurrent,
    this.maxResistance,
    this.maxSampleRate,
    this.sampleBufferSize,
    this.capabilityMask,
    this.macAddress,
  });
}

/// Represents the model for the status characteristic of a Pokit Multimeter.
class StatusCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  String? statusDescription;
  double? batteryLevel;
  String? batteryStatus;
  String? switchPosition; // Capability mask [0 = Voltage] [1 = Resistance/Low Current/Capacitance/Diodes] [2 = High Current]
  String? chargingStatus;

  /// Returns the battery percentage based on the battery level.
  double get batteryPercentage => (batteryLevel ?? 0) / 4.2 * 100;

  /// Constructs a [StatusCharacteristicModel] instance.
  ///
  /// The [bluetoothCharacteristic] parameter is required.
  StatusCharacteristicModel({
    required this.bluetoothCharacteristic,
    this.statusDescription,
    this.batteryLevel,
    this.batteryStatus,
    this.switchPosition,
    this.chargingStatus,
  });
}

/// Represents the model for the device name characteristic.
class DeviceNameCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  String? deviceName;

  /// Constructs a [DeviceNameCharacteristicModel] instance.
  DeviceNameCharacteristicModel({
    required this.bluetoothCharacteristic,
    this.deviceName,
  });
}

/// Represents the model for the LED characteristic.
class LEDCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  int? ledStatus;

  /// Constructs a [LEDCharacteristicModel] instance.
  LEDCharacteristicModel({
    required this.bluetoothCharacteristic,
    this.ledStatus,
  });
}

/// Represents the model for the torch characteristic.
class TorchCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  int? torchStatus;

  /// Constructs a [TorchCharacteristicModel] instance.
  TorchCharacteristicModel({
    required this.bluetoothCharacteristic,
    this.torchStatus,
  });
}

/// Represents the model for the button characteristic.
class ButtonCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  int? buttonUnknown;
  String? buttonStatus;

  /// Constructs a [ButtonCharacteristicModel] instance.
  ButtonCharacteristicModel({
    required this.bluetoothCharacteristic,
    this.buttonUnknown,
    this.buttonStatus,
  });
}
