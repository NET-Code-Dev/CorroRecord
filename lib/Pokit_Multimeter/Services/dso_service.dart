import 'dart:typed_data';

import 'package:asset_inspections/Pokit_Multimeter/Models/dsoservice_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DSOService {
  static const String dsoServiceUUID = '1569801e-1425-4a7a-b617-a4f4ed719de6';
  static const String dsoSettingCharacteristicUUID = 'a81af1b6-b8b3-4244-8859-3da368d2be39';
  static const String dsoMetadataCharacteristicUUID = '970f00ba-f46f-4825-96a8-153a5cd0cda9';
  static const String dsoReadingCharacteristicUUID = '98e14f8e-536e-4f24-b4f4-1debfed0a99e';

  static DSOSettingsModel initializeDSOSettingsCharacteristic(BluetoothCharacteristic bluetoothCharacteristic) {
    return DSOSettingsModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      command: Command.freeRunning,
      mode: Mode.idle,
      range: 255,
      triggerLevel: 0,
      sampleWindow: 1000,
      sampleCount: 100,
    );
  }

  static DSOMetadataModel handleDSOMetadataCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> rawData) {
    // Assuming rawData follows the structure as defined in your DSO service
    var dataBuffer = ByteData.sublistView(Uint8List.fromList(rawData));
    int status = dataBuffer.getUint8(0);
    double scale = dataBuffer.getFloat32(1, Endian.little);
    int mode = dataBuffer.getUint8(5);
    int range = dataBuffer.getUint8(6);
    int samplingWindow = dataBuffer.getUint32(7, Endian.little);
    int numberOfSamples = dataBuffer.getUint16(11, Endian.little);
    int samplingRate = dataBuffer.getUint32(13, Endian.little);

    return DSOMetadataModel(
      status: status,
      scale: scale,
      mode: mode,
      range: range,
      samplingWindow: samplingWindow,
      numberOfSamples: numberOfSamples,
      samplingRate: samplingRate,
    );
  }

  static DSOReadingModel handleDSOReadingCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> rawData) {
    var dataBuffer = ByteData.sublistView(Uint8List.fromList(rawData));
    var samples = List<int>.generate((rawData.length ~/ 2), (index) {
      return dataBuffer.getInt16(index * 2, Endian.little);
    });
    return DSOReadingModel(samples: samples);
  }
}
