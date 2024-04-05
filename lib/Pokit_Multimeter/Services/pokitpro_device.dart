import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:asset_inspections/Pokit_Multimeter/Models/pokitpro_model.dart';

/// Represents the PokitPro device and provides methods for handling various characteristics and services.
class PokitPro {
  // UUIDs for the Generic Attribute Service and its Characteristics
  static const String genericAttributeServiceUUID = '00001801-0000-1000-8000-00805f9b34fb';
  static const String serviceChangedUUID = '00002a05-0000-1000-8000-00805f9b34fb';
  static const String clientConfigurationUUID = '00002902-0000-1000-8000-00805f9b34fb'; // 2 bytes (uint16)
  static const String databaseHashUUID = '00002b2a-0000-1000-8000-00805f9b34fb'; // 16 bytes (uint???) try up to 128
  static const String clientFeaturesUUID = '00002b29-0000-1000-8000-00805f9b34fb'; // 1 byte (uint8)

  // UUIDs for the Generic Access Service and its Characteristics
  static const String genericAccessServiceUUID = '00001800-0000-1000-8000-00805f9b34fb';
  static const String gasDeviceNameUUID = '00002a00-0000-1000-8000-00805f9b34fb'; // Up to 11 bytes (UTF-8)
  static const String deviceAppearanceUUID = '00002a01-0000-1000-8000-00805f9b34fb'; // 4 bytes (uint16)

  //UUIDs for Device Info Service
  static const String deviceInfoServiceUUID = '0000180a-0000-1000-8000-00805f9b34fb';
  static const String manufacturerNameCharacteristicUUID = '00002a29-0000-1000-8000-00805f9b34fb'; // 16 bytes (UTF-8)
  static const String modelNumberCharacteristicUUID = '00002a24-0000-1000-8000-00805f9b34fb'; // 5 bytes (UTF-8)
  static const String firmwareRevCharacteristicUUID = '00002a26-0000-1000-8000-00805f9b34fb'; // 5 bytes (UTF-8)
  static const String softwareRevCharacteristicUUID = '00002a28-0000-1000-8000-00805f9b34fb'; // 5 bytes (UTF-8)
  static const String hardwareRevCharacteristicUUID = '00002a27-0000-1000-8000-00805f9b34fb'; // 5 bytes (UTF-8)
  static const String serialNumberCharacteristicUUID = '00002a25-0000-1000-8000-00805f9b34fb'; // 10 bytes (UTF-8)

  /// Handles the service changed characteristic by extracting the necessary information from the provided BluetoothCharacteristic and value.
  ///
  /// The [bluetoothCharacteristic] parameter represents the Bluetooth characteristic associated with the service changed characteristic.
  /// The [value] parameter is a list of integers representing the value of the characteristic.
  ///
  /// Returns a [ServiceChangedCharacteristicModel] object containing the extracted information.
  static ServiceChangedCharacteristicModel? handleServiceChangedCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    final int clientConfiguration = byteData.getUint8(0);

    return ServiceChangedCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      clientConfiguration: clientConfiguration,
    );
  }

  /// Handles the Database Hash Characteristic received from the Pokit Pro device.
  ///
  /// This method takes a [bluetoothCharacteristic] and a list of [value] bytes as input.
  /// It converts the byte data to a hexadecimal string and returns a [DatabaseHashCharacteristicModel]
  /// object containing the Bluetooth characteristic and the database hash.
  static DatabaseHashCharacteristicModel? handleDatabaseHashCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    if (kDebugMode) {
      print('Entered handleDatabaseHashCharacteristic');
    }
    if (kDebugMode) {
      print('Received byte data for Database Hash Characteristic: $value');
    }
    if (kDebugMode) {
      print('Received byte data size for Database Hash Characteristic: ${value.length}');
    }

    // Convert to a Hexadecimal String
    final hexString = value.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    if (kDebugMode) {
      print('Hexadecimal String: $hexString');
    }

    return DatabaseHashCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      databaseHash: hexString,
    );
  }

  /// Handles the client features characteristic received from the Pokit Pro device.
  ///
  /// This method takes a [bluetoothCharacteristic] and a [value] list of integers as parameters.
  /// It converts the [value] list into a [ByteData] object and extracts the client features information.
  /// The client features length is obtained from the first byte of the [value] list.
  /// The client features bytes are then extracted from the [value] list based on the length.
  /// Finally, the client features are converted into a string and returned as a [ClientFeaturesCharacteristicModel].
  ///
  /// Returns a [ClientFeaturesCharacteristicModel] object containing the Bluetooth characteristic and client features.
  static ClientFeaturesCharacteristicModel? handleClientFeaturesCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    final int clientFeaturesLength = byteData.getUint8(0);
    final List<int> clientFeaturesBytes = value.sublist(1, 1 + clientFeaturesLength);
    final String clientFeatures = String.fromCharCodes(clientFeaturesBytes);

    return ClientFeaturesCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      clientFeatures: clientFeatures,
    );
  }

  /// Handles the client configuration characteristic of a Bluetooth device.
  ///
  /// This method takes a [bluetoothCharacteristic] and a [value] as parameters.
  /// The [value] is a list of integers representing the byte data.
  /// It creates a [ByteData] view of the [value] list and extracts the client configuration value.
  /// Finally, it returns a [ClientConfigurationCharacteristicModel] object containing the Bluetooth characteristic and client configuration.
  static ClientConfigurationCharacteristicModel? handleClientConfigurationCharacteristic(
      BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    final int clientConfiguration = byteData.getUint8(0);

    return ClientConfigurationCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      clientConfiguration: clientConfiguration,
    );
  }

  /// Handles the Generic Access Service of a Pokit Pro device.
  ///
  /// Given a [service] and a [value] containing the data, this method extracts the necessary information
  /// from the byte data and returns a [GenericAccessServiceModel] object.
  ///
  /// The byte data is expected to have the following structure:
  /// - Byte 0: Length of the gas device name
  /// - Bytes 1-2: Device appearance (little endian)
  /// - Bytes 3 onwards: Gas device name (UTF-8 encoded)
  ///
  /// Returns a [GenericAccessServiceModel] object containing the extracted information.
  static GenericAccessServiceModel? handleGenericAccessService(BluetoothService service, List<int> value) {
    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    final int gasDeviceNameLength = byteData.getUint8(0);
    final int deviceAppearance = byteData.getUint16(1, Endian.little);

    final List<int> gasDeviceNameBytes = value.sublist(3, 3 + gasDeviceNameLength);
    final String gasDeviceName = String.fromCharCodes(gasDeviceNameBytes);

    return GenericAccessServiceModel(
      service: service,
      gasDeviceName: gasDeviceName,
      deviceAppearance: deviceAppearance,
    );
  }

  /// Handles the device information service for a given Bluetooth service.
  ///
  /// This method retrieves the device information from the specified Bluetooth service.
  /// It assumes that you know the UUIDs of the characteristics required to fetch the information.
  /// The method reads the values of the characteristics and assigns them to the corresponding variables.
  /// Finally, it returns a [DeviceInfoServiceModel] object containing the retrieved device information.
  ///
  /// Parameters:
  /// - [service]: The Bluetooth service from which to retrieve the device information.
  ///
  /// Returns:
  /// A [DeviceInfoServiceModel] object containing the device information.
  static Future<DeviceInfoServiceModel?> handleDeviceInfoService(BluetoothService service) async {
    // Assuming you know the UUIDs of the characteristics
    var manufacturerNameCharacteristic = service.characteristics.firstWhereOrNull((c) => c.uuid.toString() == manufacturerNameCharacteristicUUID);
    var modelNumberCharacteristic = service.characteristics.firstWhereOrNull((c) => c.uuid.toString() == modelNumberCharacteristicUUID);
    var firmwareRevCharacteristic = service.characteristics.firstWhereOrNull((c) => c.uuid.toString() == firmwareRevCharacteristicUUID);
    var softwareRevCharacteristic = service.characteristics.firstWhereOrNull((c) => c.uuid.toString() == softwareRevCharacteristicUUID);
    var hardwareRevCharacteristic = service.characteristics.firstWhereOrNull((c) => c.uuid.toString() == hardwareRevCharacteristicUUID);
    var serialNumberCharacteristic = service.characteristics.firstWhereOrNull((c) => c.uuid.toString() == serialNumberCharacteristicUUID);

    String manufacturerName = '';
    String modelNumber = '';
    String firmwareRev = '';
    String softwareRev = '';
    String hardwareRev = '';
    String serialNumber = '';

    if (manufacturerNameCharacteristic != null) {
      var nameValue = await manufacturerNameCharacteristic.read();
      manufacturerName = String.fromCharCodes(nameValue);
    }

    if (modelNumberCharacteristic != null) {
      var modelValue = await modelNumberCharacteristic.read();
      modelNumber = String.fromCharCodes(modelValue);
    }

    if (firmwareRevCharacteristic != null) {
      var firmwareValue = await firmwareRevCharacteristic.read();
      firmwareRev = String.fromCharCodes(firmwareValue);
    }

    if (softwareRevCharacteristic != null) {
      var softwareValue = await softwareRevCharacteristic.read();
      softwareRev = String.fromCharCodes(softwareValue);
    }

    if (hardwareRevCharacteristic != null) {
      var hardwareValue = await hardwareRevCharacteristic.read();
      hardwareRev = String.fromCharCodes(hardwareValue);
    }

    if (serialNumberCharacteristic != null) {
      var serialValue = await serialNumberCharacteristic.read();
      serialNumber = String.fromCharCodes(serialValue);
    }

    return DeviceInfoServiceModel(
      service: service,
      manufacturerName: manufacturerName,
      modelNumber: modelNumber,
      firmwareRev: firmwareRev,
      softwareRev: softwareRev,
      hardwareRev: hardwareRev,
      serialNumber: serialNumber,
    );
  }
}
