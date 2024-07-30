import 'dart:async';
import 'package:asset_inspections/Pokit_Multimeter/Models/statusservice_model.dart';
import 'package:asset_inspections/Pokit_Multimeter/Models/mmservice_model.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'package:asset_inspections/Pokit_Multimeter/Services/mm_service.dart';
import 'package:asset_inspections/Pokit_Multimeter/Services/status_service.dart';
//import 'package:asset_inspections/Pokit_Multimeter/pokitpro.dart';
import 'package:asset_inspections/Pokit_Multimeter/Services/pokitpro_device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents the model for the Pokit Pro device.

class PokitProModel {
  final BluetoothDevice device;
  final List<BluetoothService> services;
  GenericAttributeServiceModel? genericAttributeServiceModel;
  GenericAccessServiceModel? genericAccessServiceModel;
  DeviceInfoServiceModel? deviceInfoServiceModel;
  StatusServiceModel? statusServiceModel;
  MMServiceModel? mmServiceModel;

  /// Returns the Bluetooth device.
  BluetoothDevice get bluetoothDevice => device;

  /// Constructs a [PokitProModel] with the given [device] and [services].
  PokitProModel(this.device, this.services);

  /// Initializes the Pokit services for the device.
  /// This method discovers and initializes various services for the Pokit device, such as the Generic Attribute Service, Generic Access Service, Device Info Service, and Status Service.
  /// It also initializes notifications for the device.
  Future<void> initializePokitServices() async {
    if (kDebugMode) {
      print('Initializing services for device: ${device.remoteId}');
    }
    for (var service in services) {
      var serviceUUID = service.uuid.toString();
      if (serviceUUID == PokitPro.genericAttributeServiceUUID) {
        if (kDebugMode) {
          print('Discovering service: ${PokitPro.genericAttributeServiceUUID} for device: ${device.remoteId}');
        }
        // This should initialize the GenericAttributeServiceModel
        genericAttributeServiceModel = GenericAttributeServiceModel(service);
        await genericAttributeServiceModel!.discoverGenericAttributeService();
        if (kDebugMode) {
          print('Service ${PokitPro.genericAttributeServiceUUID} initialized for device: ${device.remoteId}');
        }
      } else if (serviceUUID == PokitPro.genericAccessServiceUUID) {
        if (kDebugMode) {
          print('Discovering service: ${PokitPro.genericAccessServiceUUID} for device: ${device.remoteId}');
        }
        // This should initialize the GenericAccessServiceModel
        genericAccessServiceModel = GenericAccessServiceModel(service: service);
        if (kDebugMode) {
          print('Service ${PokitPro.genericAccessServiceUUID} initialized for device: ${device.remoteId}');
        }
      } else if (serviceUUID == PokitPro.deviceInfoServiceUUID) {
        if (kDebugMode) {
          print('Discovering service: ${PokitPro.deviceInfoServiceUUID} for device: ${device.remoteId}');
        }
        // This should initialize the DeviceInfoServiceModel
        deviceInfoServiceModel = DeviceInfoServiceModel(service: service);
        if (kDebugMode) {
          print('Service ${PokitPro.deviceInfoServiceUUID} initialized for device: ${device.remoteId}');
        }
      } else if (serviceUUID == StatusService.statusServiceUUID) {
        if (kDebugMode) {
          print('Discovering service: ${StatusService.statusServiceUUID} for device: ${device.remoteId}');
        }
        // This should initialize the StatusServiceModel
        statusServiceModel = StatusServiceModel(service);
        await statusServiceModel!.discoverStatusService();
        if (kDebugMode) {
          print('Service ${StatusService.statusServiceUUID} initialized for device: ${device.remoteId}');
        }

/*      
      } else if (serviceUUID == MMService.mmServiceUUID) {
        if (kDebugMode) {
          print('Discovering service: ${MMService.mmServiceUUID} for device: ${device.remoteId}');
        }
        // This should initialize the MMServiceModel
        mmServiceModel = MMServiceModel(service);
        await mmServiceModel!.discoverMMService();
*/

        if (kDebugMode) {
          print('Service ${MMService.mmServiceUUID} initialized for device: ${device.remoteId}');
        }
      }
    }
    if (kDebugMode) {
      print('Initializing notifications for device: ${device.remoteId}');
    }
    await _initializePokitNotifications();
    if (kDebugMode) {
      print('Notifications initialized for device: ${device.remoteId}');
    }
  }

  /// Initializes the Pokit notifications.
  ///
  /// This method enables characteristic notifications for the service changed characteristic,
  /// status characteristic, torch characteristic, and button characteristic.
  ///
  /// Parameters:
  /// - `genericAttributeServiceModel`: The model representing the generic attribute service.
  /// - `statusServiceModel`: The model representing the status service.
  ///
  /// Returns:
  /// A `Future` that completes when the notifications are successfully enabled.
  Future<void> _initializePokitNotifications() async {
    if (genericAttributeServiceModel != null) {
      var serviceChangedCharacteristic = genericAttributeServiceModel?.serviceChangedCharacteristicModel?.bluetoothCharacteristic;
      if (serviceChangedCharacteristic != null) {
        await BluetoothManager.instance.enableCharacteristicNotifications(serviceChangedCharacteristic);
      }
    }

    if (statusServiceModel != null) {
      var statusCharacteristic = statusServiceModel?.statusCharacteristicModel?.bluetoothCharacteristic;
      if (statusCharacteristic != null) {
        await BluetoothManager.instance.enableCharacteristicNotifications(statusCharacteristic);
      }
      var torchCharacteristic = statusServiceModel?.torchCharacteristicModel?.bluetoothCharacteristic;
      if (torchCharacteristic != null) {
        await BluetoothManager.instance.enableCharacteristicNotifications(torchCharacteristic);
      }
      var buttonCharacteristic = statusServiceModel?.buttonCharacteristicModel?.bluetoothCharacteristic;
      if (buttonCharacteristic != null) {
        await BluetoothManager.instance.enableCharacteristicNotifications(buttonCharacteristic);
      }
    }
/*
    if (mmServiceModel != null) {
      var mmReadingCharacteristic = mmServiceModel?.mmReadingModel?.bluetoothCharacteristic;
      if (mmReadingCharacteristic != null) {
        await BluetoothManager.instance.enableCharacteristicNotifications(mmReadingCharacteristic);
      }
    }
*/
  }
}

/// Represents a model for the Generic Attribute Service.
class GenericAttributeServiceModel {
  final BluetoothService service;
  ServiceChangedCharacteristicModel? serviceChangedCharacteristicModel;
  ClientConfigurationCharacteristicModel? clientConfigurationCharacteristicModel; //Service Changed Descriptor
  DatabaseHashCharacteristicModel? databaseHashCharacteristicModel;
  ClientFeaturesCharacteristicModel? clientFeaturesCharacteristicModel;

  /// Constructs a [GenericAttributeServiceModel] with the given [service].
  GenericAttributeServiceModel(this.service);

  /// Discovers the characteristics and descriptors of the Generic Attribute Service.
  Future<void> discoverGenericAttributeService() async {
    // Discover characteristics and descriptors
    for (var characteristic in service.characteristics) {
      try {
        // Check if the characteristic is readable
        if (characteristic.properties.read) {
          var characteristicUUID = characteristic.uuid.toString();
          var data = await characteristic.read();

          if (characteristicUUID == PokitPro.serviceChangedUUID) {
            serviceChangedCharacteristicModel = PokitPro.handleServiceChangedCharacteristic(characteristic, data);
          } else if (characteristicUUID == PokitPro.databaseHashUUID) {
            databaseHashCharacteristicModel = PokitPro.handleDatabaseHashCharacteristic(characteristic, data);
          } else if (characteristicUUID == PokitPro.clientFeaturesUUID) {
            clientFeaturesCharacteristicModel = PokitPro.handleClientFeaturesCharacteristic(characteristic, data);
          } else if (characteristicUUID == PokitPro.clientConfigurationUUID) {
            clientConfigurationCharacteristicModel = PokitPro.handleClientConfigurationCharacteristic(characteristic, data);
          }
        }
      } catch (e) {
        // Handle the error, e.g., log or show a message to the user
        continue;
      }
    }
  }
}

/// Represents a model for the Service Changed characteristic in the Pokit Pro device.
class ServiceChangedCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  int? clientConfiguration; //Service Changed Descriptor

  /// Constructs a [ServiceChangedCharacteristicModel] with the given [bluetoothCharacteristic] and [clientConfiguration].
  ServiceChangedCharacteristicModel({required this.bluetoothCharacteristic, this.clientConfiguration});
}

/// Represents a model for the Database Hash characteristic.
class DatabaseHashCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  String? databaseHash;

  DatabaseHashCharacteristicModel({required this.bluetoothCharacteristic, this.databaseHash});
}

/// Represents a model for the Client Features characteristic.
class ClientFeaturesCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  String? clientFeatures;

  /// Constructs a [ClientFeaturesCharacteristicModel] with the given [bluetoothCharacteristic] and [clientFeatures].
  ClientFeaturesCharacteristicModel({required this.bluetoothCharacteristic, this.clientFeatures});
}

/// Represents a model for the Client Configuration characteristic.
class ClientConfigurationCharacteristicModel {
  final BluetoothCharacteristic bluetoothCharacteristic;
  int? clientConfiguration;

  /// Constructs a [ClientConfigurationCharacteristicModel] with the given [bluetoothCharacteristic] and [clientConfiguration].
  ClientConfigurationCharacteristicModel({required this.bluetoothCharacteristic, this.clientConfiguration});
}

//Class for the Device Information Service
class DeviceInfoServiceModel {
  final BluetoothService service;
  String? manufacturerName;
  String? modelNumber;
  String? firmwareRev;
  String? softwareRev;
  String? hardwareRev;
  String? serialNumber;

  /// Constructs a [DeviceInfoServiceModel] with the given [service].
  DeviceInfoServiceModel({
    required this.service,
    this.manufacturerName,
    this.modelNumber,
    this.firmwareRev,
    this.softwareRev,
    this.hardwareRev,
    this.serialNumber,
  });
}

/// Represents a model for the Generic Access Service.
class GenericAccessServiceModel {
  final BluetoothService service;
  String? gasDeviceName;
  int? deviceAppearance;

  /// Constructs a [GenericAccessServiceModel] with the given parameters.
  GenericAccessServiceModel({
    required this.service,
    this.gasDeviceName,
    this.deviceAppearance,
  });
}
