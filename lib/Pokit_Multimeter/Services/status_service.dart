import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:asset_inspections/Pokit_Multimeter/Models/statusservice_model.dart';

/// This class provides static methods to handle different characteristics of a status service.
class StatusService {
  static const String statusServiceUUID = '57d3a771-267c-4394-8872-78223e92aec5'; // 1
  static const String deviceCharacteristicUUID = '6974f5e5-0e54-45c3-97dd-29e4b5fb0849'; // 2
  static const String statusCharacteristicUUID = '3dba36e1-6120-4706-8dfd-ed9c16e569b6'; // 3
  static const String nameCharacteristicUUID = '7f0375de-077e-4555-8f78-800494509cc3'; // 4
  static const String ledCharacteristicUUID = 'ec9bb1f3-05a9-4277-8dd0-60a7896f0d6e';
  static const String torchCharacteristicUUID = 'aaf3f6d5-43d4-4a83-9510-dff3d858d4cc';
  static const String buttonCharacteristicUUID = '8fe5b5a9-b5b4-4a7b-8ff2-87224b970f89';

  //TODO: wrap in try/catch block
  /// Handles the device characteristic received from the Bluetooth characteristic.
  ///
  /// This method takes a [bluetoothCharacteristic] and a [value] as input parameters.
  /// It checks if the length of the value is 20. If not, it returns null.
  ///
  /// It then extracts various data from the [value] using byte manipulation and creates a [DeviceCharacteristicModel] object.
  /// The extracted data includes version major, version minor, max voltage, max current, max resistance, max sampling rate,
  /// sampling buffer size, capability mask, and MAC address.
  ///
  /// The MAC address is corrected for consistency by reversing the bytes, converting them to hexadecimal strings, and joining them with colons.
  /// The MAC address is then converted to uppercase and reversed again to match the standard format.
  static DeviceCharacteristicModel? handleDeviceCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    if (value.length != 20) {
      return null;
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    final int versionMajor = byteData.getUint8(0);
    final int versionMinor = byteData.getUint8(1);
    final int maxVoltage = byteData.getUint16(2, Endian.little);
    final int maxCurrent = byteData.getUint16(4, Endian.little);
    final int maxResistance = byteData.getUint16(6, Endian.little);
    final int maxSamplingRate = byteData.getUint16(8, Endian.little);
    final int samplingBufferSize = byteData.getUint16(10, Endian.little);
    final int capabilityMask = byteData.getUint16(12, Endian.little);

    final List<int> macAddressBytes = [
      byteData.getUint8(14),
      byteData.getUint8(15),
      byteData.getUint8(16),
      byteData.getUint8(17),
      byteData.getUint8(18),
      byteData.getUint8(19),
    ];

    final String macAddressCorrection =
        macAddressBytes.reversed.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase(); // Ensure uppercase for consistency

    final String macAddress = macAddressCorrection.split(':').reversed.join(':');

    return DeviceCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      capabilityMask: capabilityMask,
      macAddress: macAddress,
      maxCurrent: maxCurrent,
      maxResistance: maxResistance,
      maxSampleRate: maxSamplingRate,
      maxVoltage: maxVoltage,
      sampleBufferSize: samplingBufferSize,
      version: '$versionMajor.$versionMinor',
    );
  }

  /// Handles the status characteristic received from the Bluetooth device.
  ///
  /// This method takes a [bluetoothCharacteristic] and a [value] list as input and processes the data to extract various status information.
  /// It returns a [StatusCharacteristicModel] object containing the extracted values.
  ///
  /// The [value] list should have a length of 8. If the length is different, null is returned.
  ///
  /// The first byte of the [value] list represents the status, which is mapped to a descriptive string using a switch statement.
  ///
  /// The second byte represents the battery voltage, which is converted to a battery percentage using a formula.
  ///
  /// The fifth byte represents the battery status, which is mapped to a descriptive string using a switch statement.
  ///
  /// The sixth byte represents the switch position, which is mapped to a descriptive string using a switch statement.
  ///
  /// The seventh byte represents the charging status, which is mapped to a descriptive string using a switch statement.
  static StatusCharacteristicModel? handleStatusCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    if (kDebugMode) {
      print('Entering handleStatusCharacteristic method');
    }
    if (kDebugMode) {
      print('Received byte data for Status: $value');
    }
    // Ensure that the data is of the expected size
    if (value.length != 8) {
      if (kDebugMode) {
        print('Unexpected data size for status characteristic: ${value.length}');
      }
      if (kDebugMode) {
        print('Data: $value');
      }
      return null;
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    // Extract Status
    final int status = byteData.getUint8(0);
    String statusDescription;
    switch (status) {
      case 0:
        statusDescription = 'IDLE';
        break;
      case 1:
        statusDescription = 'MM meas. DC Voltage';
        break;
      case 2:
        statusDescription = 'MM meas. AC Voltage';
        break;
      case 3:
        statusDescription = 'MM meas. DC Current';
        break;
      case 4:
        statusDescription = 'MM meas. AC Current';
        break;
      case 5:
        statusDescription = 'MM meas. Resistance';
        break;
      case 6:
        statusDescription = 'MM meas. Diode';
        break;
      case 7:
        statusDescription = 'MM meas. Continuity';
        break;
      case 8:
        statusDescription = 'MM meas. Temperature';
        break;
      case 9:
        statusDescription = 'DSO Mode (Sampling)';
        break;
      case 10:
        statusDescription = 'Logger Mode (Sampling)';
        break;
      default:
        statusDescription = 'Unknown';
        break;
    }

    // Extract Battery Voltage
    final double batteryVoltage = byteData.getFloat32(1, Endian.little);
    // Define the voltage range
    const double minVoltage = 3.0; // Voltage corresponding to 0%
    const double maxVoltage = 4.2; // Voltage corresponding to 100%

    // Calculate battery percentage
    final double batteryPercentage = ((batteryVoltage - minVoltage) / (maxVoltage - minVoltage)) * 100;
    final double correctedBatteryPercentage = batteryPercentage.clamp(0, 100); // Ensure the value is within 0-100%

    final int battStatus = byteData.getUint8(5);
    String batteryStatus;
    switch (battStatus) {
      case 0:
        batteryStatus = 'Low';
        break;
      case 1:
        batteryStatus = 'Good';
        break;
      default:
        batteryStatus = 'Unknown';
        break;
    }

    final int position = byteData.getUint8(6);

    String switchPosition;
    switch (position) {
      case 0:
        switchPosition = 'Voltage';
        break;
      case 1:
        switchPosition = 'MultiMode';
        break;
      case 2:
        switchPosition = 'High Current';
        break;
      default:
        switchPosition = 'Unknown';
        break;
    }

    final int charging = byteData.getUint8(7);
    String chargingStatus;
    switch (charging) {
      case 0:
        chargingStatus = 'Discharging';
        break;
      case 1:
        chargingStatus = 'Charging';
        break;
      case 2:
        chargingStatus = 'Charged';
        break;
      default:
        chargingStatus = 'Unknown';
        break;
    }

    if (kDebugMode) {
      print('Exiting handleStatusCharacteristic method');
    }

    // Return a BluetoothDeviceModel object with the extracted values
    return StatusCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      statusDescription: statusDescription,
      batteryLevel: correctedBatteryPercentage,
      batteryStatus: batteryStatus,
      switchPosition: switchPosition,
      chargingStatus: chargingStatus,
    );
  }

  /// Handles the device name characteristic received from a Bluetooth device.
  ///
  /// This method takes a [bluetoothCharacteristic] and a [value] list of integers
  /// representing the byte data for the device name. It extracts the device name
  /// from the byte data and returns a [DeviceNameCharacteristicModel] object
  /// containing the extracted device name and the original Bluetooth characteristic.
  static DeviceNameCharacteristicModel? handleDeviceNameCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    if (kDebugMode) {
      print('Entering handleDeviceNameCharacteristic method');
    }
    if (kDebugMode) {
      print('Received byte data for Device Name: $value');
    }

    // Extract Device Name from the byte data
    final String deviceName = String.fromCharCodes(value);

    if (kDebugMode) {
      print('Device Name: $deviceName');
    }
    if (kDebugMode) {
      print('Exiting handleDeviceNameCharacteristic method');
    }

    // Return a DeviceNameCharacteristic object with the extracted device name
    return DeviceNameCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      deviceName: deviceName,
    );
  }

  /// Handles the LED characteristic by extracting the LED status from the received byte data.
  ///
  /// The [bluetoothCharacteristic] parameter represents the Bluetooth characteristic associated with the LED.
  /// The [value] parameter contains the byte data received for the LED.
  static LEDCharacteristicModel? handleLEDCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    if (kDebugMode) {
      print('Entering handleLEDCharacteristic method');
    }
    if (kDebugMode) {
      print('Received byte data for LED: $value');
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    // Extract LED Status
    final int ledStatus = byteData.getUint8(0);

    if (kDebugMode) {
      print('LED Status: $ledStatus');
    }
    if (kDebugMode) {
      print('Exiting handleLEDCharacteristic method');
    }

    // Return a LEDCharacteristic object with the extracted LED status
    return LEDCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      ledStatus: ledStatus,
    );
  }

  /// Handles the torch characteristic received from a Bluetooth device.
  ///
  /// This method takes a [bluetoothCharacteristic] and a [value] list as parameters.
  /// It extracts the torch status from the byte data in the value list and returns
  /// a [TorchCharacteristicModel] object containing the extracted torch status.
  static TorchCharacteristicModel? handleTorchCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    if (kDebugMode) {
      print('Entering handleTorchCharacteristic method');
    }
    if (kDebugMode) {
      print('Received byte data for Torch: $value');
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    // Extract Torch Status
    final int torchStatus = byteData.getUint8(0);

    if (kDebugMode) {
      print('Torch Status: $torchStatus');
    }
    if (kDebugMode) {
      print('Exiting handleTorchCharacteristic method');
    }

    // Return a TorchCharacteristic object with the extracted Torch status
    return TorchCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      torchStatus: torchStatus,
    );
  }

  /// Handles the button characteristic received from the Bluetooth device.
  ///
  /// This method takes a [bluetoothCharacteristic] and a [value] list as parameters.
  /// It extracts the button status from the received byte data and returns a [ButtonCharacteristicModel]
  /// object containing the extracted button status.
  static ButtonCharacteristicModel? handleButtonCharacteristic(BluetoothCharacteristic bluetoothCharacteristic, List<int> value) {
    if (kDebugMode) {
      print('Entering handleButtonCharacteristic method');
    }
    if (kDebugMode) {
      print('Received byte data for Button: $value');
    }

    final byteData = ByteData.sublistView(Uint8List.fromList(value));

    // Extract Button Status
    final int buttonUnknown = byteData.getUint8(0);
    final int status = byteData.getUint8(1);
    String buttonStatus;
    switch (status) {
      case 0:
        buttonStatus = 'Released';
        break;
      case 1:
        buttonStatus = 'Pressed';
        break;
      case 2:
        buttonStatus = 'Held';
        break;
      default:
        buttonStatus = 'Unknown';
        break;
    }

    // Return a ButtonCharacteristic object with the extracted Button status
    return ButtonCharacteristicModel(
      bluetoothCharacteristic: bluetoothCharacteristic,
      buttonUnknown: buttonUnknown,
      buttonStatus: buttonStatus,
    );
  }
}
