import 'dart:typed_data';
import 'package:asset_inspections/Pokit_Multimeter/Models/mmservice_model.dart';
import 'package:asset_inspections/Pokit_Multimeter/Utility/range_enums.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// A class that provides services for the Pokit Multimeter.
class MMService {
  /// The UUID for the Pokit Multimeter service.
  static const String mmServiceUUID = 'e7481d2f-5781-442e-bb9a-fd4e3441dadc';

  /// The UUID for the MM settings characteristic.
  static const String mmSettingsCharacteristicUUID = '53dc9a7a-bc19-4280-b76b-002d0e23b078';

  /// The UUID for the MM reading characteristic.
  static const String mmReadingCharacteristicUUID = '047d3559-8bee-423a-b229-4417fa603b90';

  /// Initializes the MM settings characteristic with default values or based on some logic.
  ///
  /// Returns an instance of [MMSettingsModel] with the initialized values.
  static MMSettingsModel initializeMMSettingsCharacteristic(BluetoothCharacteristic characteristic) {
    // Initialize with default values or based on some logic
    return MMSettingsModel(
        bluetoothCharacteristic: characteristic,
        mode: Mode.dcVoltage, // Default mode
        range: 255,
        updateInterval: 1000 // Default update interval
        );
  }

  /// Handles the MM reading characteristic and parses the raw data.
  ///
  /// Returns an instance of [MMReadingModel] with the parsed data.
  static MMReadingModel handleMMReadingCharacteristic(BluetoothCharacteristic characteristic, List<int> rawData) {
    final parsedData = _parseRawData(rawData);
    final rangeString = _getRangeString(parsedData.mode, parsedData.rangeValue);

    return MMReadingModel(
      bluetoothCharacteristic: characteristic,
      status: parsedData.status,
      value: parsedData.value,
      mode: parsedData.mode,
      range: parsedData.rangeValue,
      rangeString: rangeString,
      //   statusString: parsedData.status.stringValue(parsedData.mode),
    );
  }

  /// Parses the raw data received from the MM reading characteristic.
  ///
  /// Returns an instance of [_ParsedData] with the parsed values.
  static _ParsedData _parseRawData(List<int> rawData) {
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(rawData));

    int receivedStatus = byteData.getUint8(0);
    double value = byteData.getFloat32(1, Endian.little);
    int receivedMode = byteData.getUint8(5);
    int rangeValue = byteData.getUint8(6);

    Mode mode = Mode.values.elementAt(receivedMode);
    MeterStatus status = MeterStatus.values.elementAt(receivedStatus);

    return _ParsedData(status, value, mode, rangeValue);
  }

  /// Gets the range string based on the mode and range value.
  ///
  /// Returns the range string.
  static String _getRangeString(Mode mode, int rangeValue) {
    switch (mode) {
      case Mode.dcVoltage:
      case Mode.acVoltage:
        return VoltageRange.voltageRangeToString(VoltageRangeEnum.values[rangeValue]);
      case Mode.dcCurrent:
      case Mode.acCurrent:
        return CurrentRange.currentRangeToString(CurrentRangeEnum.values[rangeValue]);
      case Mode.resistance:
        return ResistanceRange.resistanceRangeToString(ResistanceRangeEnum.values[rangeValue]);
      default:
        return 'Unknown';
    }
  }
}

/// Represents the parsed data from the multimeter service.
class _ParsedData {
  final MeterStatus status;
  final double value;
  final Mode mode;
  final int rangeValue;

  /// Creates a new instance of [_ParsedData].
  ///
  /// [status] represents the status of the meter.
  /// [value] represents the measured value.
  /// [mode] represents the mode of the meter.
  /// [rangeValue] represents the range value of the meter.
  _ParsedData(this.status, this.value, this.mode, this.rangeValue);
}



/*
  // Method to update the model with new data from the characteristic
  static MMReadingModel handleMMReadingCharacteristic(BluetoothCharacteristic characteristic, List<int> rawData) {
/*    
    final byteData = ByteData.sublistView(Uint8List.fromList(rawData));

    int status = byteData.getUint8(0);
    double value = byteData.getFloat32(1, Endian.little);
    Mode modeEnum = Mode.values[byteData.getUint8(5)]; // This assumes Mode enum values match the raw data
    ModeSetting modeSetting = ModeSettingFactory.fromRawValue(modeEnum.value); // Use factory to create the correct ModeSetting

    // Determine the correct RangeSetting based on the mode
    int rawRange = byteData.getUint8(6);
    RangeSetting rangeSetting = modeSetting.getRangeSetting(rawRange); // Implemented in concrete ModeSetting classes

    return MMReadingModel(
      bluetoothCharacteristic: characteristic,
      status: status,
      value: value,
      modeSetting: modeSetting,
      range: rangeSetting,
    );
*/
ByteData byteData = ByteData.sublistView(Uint8List.fromList(rawData));

    int receivedStatus = byteData.getUint8(0);
    double value = byteData.getFloat32(1, Endian.little);
    int receivedMode = byteData.getUint8(5);
    int rangeValue = byteData.getUint8(6);

    Mode mode = Mode.values.elementAt(receivedMode);
    MeterStatus status; // Initialize based on receivedStatus and mode
    // Example of status initialization (adjust according to your logic)
    status = MeterStatus.values.elementAt(receivedStatus);

    // Determine the correct Range class and method based on mode
    String? rangeString;
    switch (mode) {
      case Mode.capacitance:
        rangeString = CapacitanceRange.capacitanceRangeToString(CapacitanceRangeEnum.values[rangeValue]);
        break;
      case Mode.dcVoltage:
      case Mode.acVoltage:
        // Assuming VoltageRange applies to both DC and AC Voltage
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
    }

    return MMReadingModel(
      bluetoothCharacteristic: characteristic,
      status: status,
      value: value,
      mode: mode,
      range: rangeValue,
      rangeString: rangeString!,
      statusString: status.stringValue(mode),
    );
  }
  */

