import 'package:asset_inspections/Pokit_Multimeter/Models/dataloggerservice_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DataloggerService {
  static const String dataloggerServiceUUID = 'a5ff3566-1fd8-4e10-8362-590a578a4121';
  static const String dataloggerSettingCharacteristicUUID = '5f97c62b-a83b-46c6-b9cd-cac59e130a78';
  static const String dataloggerMetadataCharacteristicUUID = '9acada2e-3936-430b-a8f7-da407d97ca6e';
  static const String dataloggerReadingCharacteristicUUID = '3c669dab-fc86-411c-9498-4f9415049cc0';

  static DataloggerSettingsModel initializeDSOSettingsCharacteristic(BluetoothCharacteristic bluetoothCharacteristic) {
    //TODO; Implement this

    //...
    return DataloggerSettingsModel();
  }

  static DataloggerMetadataModel handleDSOMetadataCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> rawData) {
    //TODO; Implement this

    //...
    return DataloggerMetadataModel();
  }

  static DataloggerReadingModel handleDSOReadingCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> rawData) {
    //TODO; Implement this

    //...
    return DataloggerReadingModel();
  }
}
