import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:asset_inspections/Pokit_Multimeter/Services/datalogger_service.dart';
//import 'package:asset_inspections/Pokit_Multimeter/Services/dso_service.dart';

/// Represents a model for a Datalogger service.
class DataloggerServiceModel {
  BluetoothService service;
  DataloggerSettingsModel? dataloggerSettingsModel;
  DataloggerReadingModel? dataloggerReadingModel;
  DataloggerMetadataModel? dataloggerMetadataModel;

  BluetoothCharacteristic? _settingsCharacteristic;
  BluetoothCharacteristic? _readingCharacteristic;

  /// Constructs a DataloggerServiceModel with the given Bluetooth service.
  DataloggerServiceModel(this.service);

  /// Discovers the DSO (Digital Storage Oscilloscope) service by iterating through the characteristics of the Bluetooth service.
  /// Reads the characteristics and initializes the corresponding models based on the characteristic UUID.
  Future<void> discoverDSOService() async {
    for (var characteristic in service.characteristics) {
      try {
        if (characteristic.properties.read) {
          var characteristicUUID = characteristic.uuid.toString();
          var data = await characteristic.read();

          if (characteristicUUID == DataloggerService.dataloggerSettingCharacteristicUUID) {
            _settingsCharacteristic = characteristic;
            dataloggerSettingsModel = DataloggerService.initializeDSOSettingsCharacteristic(characteristic);
          } else if (characteristicUUID == DataloggerService.dataloggerReadingCharacteristicUUID) {
            _readingCharacteristic = characteristic;
            dataloggerReadingModel = DataloggerService.handleDSOReadingCharacteristic(characteristic, data);
          } else if (characteristicUUID == DataloggerService.dataloggerMetadataCharacteristicUUID) {
            dataloggerMetadataModel = DataloggerService.handleDSOMetadataCharacteristic(characteristic, data);
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

/// Represents a model for Datalogger settings.
class DataloggerSettingsModel {
  BluetoothCharacteristic? bluetoothCharacteristic;
}

/// Represents a model for Datalogger metadata.
class DataloggerMetadataModel {
  BluetoothCharacteristic? bluetoothCharacteristic;
}

/// Represents a model for Datalogger readings.
class DataloggerReadingModel {
  BluetoothCharacteristic? bluetoothCharacteristic;
}
