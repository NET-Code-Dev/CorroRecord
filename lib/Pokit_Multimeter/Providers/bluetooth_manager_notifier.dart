import 'dart:async';
import 'dart:io'; // Import Platform

import 'package:asset_inspections/Pokit_Multimeter/Models/mmservice_model.dart';
import 'package:asset_inspections/Pokit_Multimeter/Models/pokitpro_model.dart';
import 'package:asset_inspections/Pokit_Multimeter/Services/mm_service.dart';
import 'package:asset_inspections/Pokit_Multimeter/Services/status_service.dart';
import 'package:flutter/foundation.dart';
//import 'package:asset_inspections/Pokit_Multimeter/pokitpro.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

typedef DeviceDetailsCallback = void Function(PokitProModel deviceModel);

/// This class represents a Bluetooth manager that handles the connection and communication with a Bluetooth device.
/// It provides methods for scanning and connecting to devices, discovering services, enabling notifications, and updating device details.
class BluetoothManager with ChangeNotifier {
  static final BluetoothManager instance = BluetoothManager._();

  BluetoothManager._();

  final ValueNotifier<BluetoothConnectionState> deviceStateNotifier = ValueNotifier(BluetoothConnectionState.disconnected);
  final ValueNotifier<List<BluetoothDevice>> availableDevicesNotifier = ValueNotifier<List<BluetoothDevice>>([]);

  DeviceDetailsCallback? onDeviceDetailsUpdated;

  bool _isDeviceConnected = false;
//  String _switchPosition = '';
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, StreamSubscription> _enabledNotifications = {};
  // ignore: unused_field
  BluetoothDevice? _device;

  //Private member for the PokitProModel
  PokitProModel? _pokitProModel;
//  PokitProModel? _currentPokitProModel;

  // Private member for the MM Service Model
  MMServiceModel? _mmServiceModel;

  // Private members to store the current reading and settings
  MMReadingModel? _currentMMReading;
  MMSettingsModel? _currentMMSettings;
  double? _minReading;
  double? _maxReading;

  bool get isConnected => _isDeviceConnected;
  PokitProModel? get pokitProModel => _pokitProModel;

  // Getter for the MM Service Model
  MMServiceModel? get mmServiceModel => _mmServiceModel;

  MMReadingModel? get currentReading => _currentMMReading;
  MMSettingsModel? get currentSettings => _currentMMSettings;
  double? get minReading => _minReading;
  double? get maxReading => _maxReading;

  final StreamController<MMReadingModel> _readingStreamController = StreamController<MMReadingModel>.broadcast();
  Stream<MMReadingModel> get currentReadingStream => _readingStreamController.stream;

  /// Sets the [pokitProModel] and notifies listeners if it has changed.
  ///
  /// If the [pokitProModel] is different from the current value, it updates the [_pokitProModel] property,
  /// initializes the connection listener, and notifies listeners.
  ///
  /// This method is used to update the [pokitProModel] property in the [BluetoothManagerNotifier] class.
  /// It also includes a log statement for debugging purposes when running in debug mode.
  ///
  /// Parameters:
  /// - [pokitProModel]: The new [PokitProModel] to set.
  ///
  /// Returns: void
  set pokitProModel(PokitProModel? pokitProModel) {
    if (_pokitProModel != pokitProModel) {
      _pokitProModel = pokitProModel;
      if (kDebugMode) {
        print('pokitProModel is set: $_pokitProModel');
      } // Log statement for debugging
      _initializeConnectionListener();
      notifyListeners();
    }
  }

  /// Sets the Bluetooth device for the Bluetooth manager.
  ///
  /// The [device] parameter is the Bluetooth device to be set.
  void setDevice(BluetoothDevice device) {
    _device = device;
  }

  // ignore: unused_field
  Mode _selectedMode = Mode.idle;

  /// Sets the selected mode for the Bluetooth Manager.
  ///
  /// The [mode] parameter represents the mode to be set.
  /// This method updates the [_selectedMode] variable with the provided [mode]
  /// and notifies the listeners of the change.
  void setSelectedMode(Mode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  // Ensure that all subscriptions are cancelled when the model is disposed
  @override
  void dispose() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    // Dispose other resources if necessary
    super.dispose();
  }

  /// Checks if the given [name] is a valid MAC address.
  /// Returns `true` if the [name] is a valid MAC address, otherwise `false`.
  bool isMacAddress(String? name) {
    if (name == null) return false;
    final RegExp macAddressPattern = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macAddressPattern.hasMatch(name);
  }

  /// Starts the Bluetooth scan to discover nearby devices.
  ///
  /// This method checks if Bluetooth is available on the device and turns it on if necessary.
  /// It then starts scanning for Bluetooth devices and adds them to the list of available devices
  /// if they meet the criteria. The scan is stopped if a device with the name "PokitPro" is found.
  ///
  /// Note: The scan has a timeout of 10 seconds.
  Future<void> startBluetoothScan() async {
    // print("Starting Bluetooth scan");

    // Set the log level to verbose for debugging purposes
    //FlutterBluePlus.setLogLevel(LogLevel.verbose);

    // Check if Bluetooth is available on the device
    if (await FlutterBluePlus.isSupported == false) {
      // print("Bluetooth not supported by this device");
      return;
    }

    // On Android, turn on Bluetooth if it is not already on
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    // Delay for 2 seconds before starting the scan
    await Future.delayed(const Duration(seconds: 2));

    // Clear the list of available devices
    availableDevicesNotifier.value = [];

    // Start scanning for Bluetooth devices
    StreamSubscription<List<ScanResult>>? subscription;
    subscription = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        // print("Device found: ${result.device.platformName}");

        // Add the device to the list of available devices if it meets the criteria
        if (!availableDevicesNotifier.value.contains(result.device) &&
            result.device.platformName.isNotEmpty &&
            !isMacAddress(result.device.platformName)) {
          availableDevicesNotifier.value = [...availableDevicesNotifier.value, result.device];
        }

        // Stop the scan if a device with the name "PokitPro" is found
        ////May need to change this since the user can change the name of the device
        if (result.device.platformName == 'PokitPro') {
          // print('Found PokitPro, stopping scan');
          FlutterBluePlus.stopScan();
          subscription?.cancel();
          break;
        }
      }
    });

    // Start the scan with a timeout of 10 seconds
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  /// Discovers the services provided by a Bluetooth device.
  ///
  /// This method takes a [device] as a parameter and asynchronously discovers the services
  /// provided by the device. It returns a [Future] that completes with a list of [BluetoothService]
  /// objects representing the discovered services.
  ///
  /// If any exceptions occur during the discovery process, they will be caught and an empty list
  /// will be returned.
  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      if (kDebugMode) {
        for (var service in services) {
          print('Service found: ${service.uuid}');
          for (var characteristic in service.characteristics) {
            print('Characteristic found: ${characteristic.uuid} with properties ${characteristic.properties}');
          }
        }
      }
      return services;
    } catch (e) {
      if (kDebugMode) {
        print('Error during service discovery: $e');
      }
      return [];
    }
  }

  /// Connects to the specified Bluetooth device and initializes the PokitPro services.
  ///
  /// This method establishes a connection with the given [device] and sets the [deviceStateNotifier]
  /// value to [BluetoothConnectionState.connected]. It then discovers the available services
  /// provided by the device and initializes the PokitPro services using the [pokitPro.initializePokitServices()]
  /// method. Finally, it notifies the listeners about the changes.
  ///
  /// Parameters:
  /// - [device]: The Bluetooth device to connect to.
  ///
  /// Throws:
  /// - Exception: If an error occurs during the Bluetooth connection.
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      if (kDebugMode) {
        print('Connecting to device: ${device.remoteId}');
      } // Log device ID or other identifying info
      await device.connect();
      deviceStateNotifier.value = BluetoothConnectionState.connected;
      if (kDebugMode) {
        print('Connected to device: ${device.remoteId}');
      }

      List<BluetoothService> services = await discoverServices(device);
      var pokitPro = PokitProModel(device, services);
      pokitProModel = pokitPro; // Set the new model

      if (kDebugMode) {
        print('Initializing PokitPro services...');
      }
      await pokitPro.initializePokitServices();
      if (kDebugMode) {
        print('PokitPro services initialized for device: ${device.remoteId}');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error during Bluetooth connection: $e');
      }
    }
  }

  /// Enables notifications for the given [characteristic].
  /// Returns a [Future] that completes when the notifications are enabled.
  /// Throws an [Exception] if the notifications could not be enabled.
  /// Subscribes to the characteristic and updates the [_enabledNotifications] map.
  /// Notifies listeners after enabling notifications.
  /// Handles exceptions by catching them and not doing anything.
  Future<void> enableCharacteristicNotifications(BluetoothCharacteristic characteristic) async {
    try {
      bool result = await characteristic.setNotifyValue(true);
      if (!result) {
        throw Exception("Failed to enable notifications for characteristic.");
      }

      // _enabledNotifications.add(characteristic.uuid.toString());
      // _subscribeToCharacteristic(characteristic);
      var subscription = _subscribeToCharacteristic(characteristic);
      _enabledNotifications[characteristic.uuid.toString()] = subscription;
      notifyListeners();
    } catch (e) {
      // Handle exceptions (e.g., log error, update UI)
    }
  }

  /// Updates the device details with the given [deviceModel].
  /// If [onDeviceDetailsUpdated] is not null, it invokes the callback with the [deviceModel].
  void updateDeviceDetails(PokitProModel deviceModel) async {
    if (onDeviceDetailsUpdated != null) {
      onDeviceDetailsUpdated!(deviceModel);
    }
  }

  /// Unpairs the device by disconnecting it, updating the device state, and resetting the PokitProModel.
  void unpairDevice() {
    if (_pokitProModel != null) {
      _pokitProModel!.device.disconnect();
      deviceStateNotifier.value = BluetoothConnectionState.disconnected;
      BluetoothManager.instance._isDeviceConnected = false;
      pokitProModel = null;
    }
  }

  /// Resets the minimum and maximum readings to 0 and notifies the listeners of the change.
  void resetMinMaxReadings() {
    _minReading = 0;
    _maxReading = 0;

    // Notify listeners that a change has occurred
    notifyListeners();
  }

  /// Updates the switch position with the given [newPosition].
  /// If the new position is different from the current position, it updates the PokitProModel and notifies the listeners.
  void updateSwitchPosition(String newPosition) {
    if (_pokitProModel?.statusServiceModel?.statusCharacteristicModel?.switchPosition != newPosition) {
      _pokitProModel?.statusServiceModel?.statusCharacteristicModel?.switchPosition = newPosition;
      notifyListeners();
    }
  }

  /// Updates the button pressed status with the given [newButtonPressed].
  /// If the new status is different from the current status, it updates the PokitProModel and notifies the listeners.
  void updateButtonPressed(String newButtonPressed) {
    if (_pokitProModel?.statusServiceModel?.buttonCharacteristicModel?.buttonStatus != newButtonPressed) {
      _pokitProModel?.statusServiceModel?.buttonCharacteristicModel?.buttonStatus = newButtonPressed;
      notifyListeners();
    }
  }

  /// Updates the Bluetooth service with the given [newService].
  /// If the current Bluetooth characteristic is not null, it updates the service in the PokitProModel and notifies the listeners.
  void updateService(BluetoothService newService) {
    if (_pokitProModel?.mmServiceModel!.mmReadingModel?.bluetoothCharacteristic != null) {
      _pokitProModel?.mmServiceModel?.service = newService;
      notifyListeners();
    }
  }

  /// Initializes the connection listener for the Bluetooth device.
  /// This method cancels any existing connection state subscription and sets up a new one.
  /// It listens to the connection state of the Pokit Pro device and updates the [_isDeviceConnected] flag accordingly.
  /// Finally, it notifies the listeners about the updated connection state.
  void _initializeConnectionListener() {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = _pokitProModel?.device.connectionState.listen((BluetoothConnectionState state) {
      _isDeviceConnected = state == BluetoothConnectionState.connected;
      notifyListeners();
    });
  }

  /// Subscribes to a Bluetooth characteristic and handles the received data.
  ///
  /// This method listens to the [characteristic] for the last value and performs
  /// specific actions based on the UUID of the characteristic. If the UUID matches
  /// the status characteristic UUID, it updates the status characteristic model
  /// in the PokitPro model. If the UUID matches the torch characteristic UUID,
  /// it updates the torch characteristic model. If the UUID matches the button
  /// characteristic UUID, it updates the button characteristic model. If the UUID
  /// matches the MM reading characteristic UUID, it updates the MM reading model.
  ///
  /// After updating the models, this method notifies the listeners or calls a
  /// callback to update the UI.
  ///
  /// Returns the [StreamSubscription] for the characteristic.
  StreamSubscription _subscribeToCharacteristic(BluetoothCharacteristic characteristic) {
    var subscription = characteristic.lastValueStream.listen((data) {
      if (characteristic.uuid.toString() == StatusService.statusCharacteristicUUID) {
        var updatedModel = StatusService.handleStatusCharacteristic(characteristic, data);
        _pokitProModel?.statusServiceModel?.statusCharacteristicModel = updatedModel;

        // Notify listeners or call a callback to update the UI
        notifyListeners();
      } else if (characteristic.uuid.toString() == StatusService.torchCharacteristicUUID) {
        var updatedModel = StatusService.handleTorchCharacteristic(characteristic, data);
        _pokitProModel?.statusServiceModel?.torchCharacteristicModel = updatedModel;

        // Notify listeners or call a callback to update the UI
        notifyListeners();
      } else if (characteristic.uuid.toString() == StatusService.buttonCharacteristicUUID) {
        var updatedModel = StatusService.handleButtonCharacteristic(characteristic, data);
        _pokitProModel?.statusServiceModel?.buttonCharacteristicModel = updatedModel;
        notifyListeners();
      } else if (characteristic.uuid.toString() == MMService.mmReadingCharacteristicUUID) {
        var updatedModel = MMService.handleMMReadingCharacteristic(characteristic, data);
        _pokitProModel?.mmServiceModel?.mmReadingModel = updatedModel;
        notifyListeners();
      }
    });

    // Store the subscription to manage it later
    _subscriptions[characteristic.uuid.toString()] = subscription;
    return subscription;
  }
}

/*
  // Setter for the MM Service Model
   set mmServiceModel(MMServiceModel? mmServiceModel) {
    _mmServiceModel = mmServiceModel;
    notifyListeners();
  }


  Future<void> startReadingStream() async {
    if (mmServiceModel?.mmReadingModel != null) {
      var readingCharacteristic = mmServiceModel?.mmReadingModel!.bluetoothCharacteristic;

      // Set the characteristic to notify on value changes
      await readingCharacteristic?.setNotifyValue(true);

      // Listen to the characteristic's value changes
      readingCharacteristic?.lastValueStream.listen((List<int> data) {
        // Corrected to accept List<int>
        // Process the incoming data
        var reading = MMService.handleMMReadingCharacteristic(readingCharacteristic, data);

        // Add the reading to the stream
        _readingStreamController.add(reading); // Ensure _readingStreamController is of type StreamController<MMReadingModel>
        notifyListeners();
      });
    }
  }


    Future<void> startReadingStream(Mode mode) async {
    try {
      BluetoothCharacteristic? characteristic = _getCharacteristicForMode(mode);
      if (characteristic == null) {
        throw Exception("Characteristic not found for mode $mode");
      }

      // Subscribe to the characteristic
      await enableCharacteristicNotifications(characteristic);
      var subscription = characteristic.lastValueStream.listen((data) {
        _handleCharacteristicData(mode, data);
      });

      // Store the subscription so it can be cancelled later
      _subscriptions[characteristic.uuid.toString()] = subscription;
    } catch (e) {
      // Handle errors, such as characteristic not found, subscription failed, etc.
      print("Error starting reading stream: $e");
    }
  }


  void handleCharacteristicData(Mode mode, List<int> rawData) {
    // Assuming _pokitProModel is your device model which contains the service model
    // and the bluetoothCharacteristic for the MM reading is stored there.
    BluetoothCharacteristic? bluetoothCharacteristic = _pokitProModel?.mmServiceModel?.mmReadingModel?.bluetoothCharacteristic;

    if (bluetoothCharacteristic != null) {
      var reading = MMService.handleMMReadingCharacteristic(bluetoothCharacteristic, rawData);
      _currentMMReading = reading;
      notifyListeners();
    } else {
      // Handle the case where the characteristic is not found
      print("BluetoothCharacteristic for MM readings is not found.");
    }
  }

  // This method is used to subscribe to a characteristic
  void _subscribeToCharacteristic(BluetoothCharacteristic characteristic) {
    var subscription = characteristic.lastValueStream.listen((data) {
      // Handle the incoming data
      // For example, processing and updating the state
    });

    // Store the subscription to manage it later
    _subscriptions[characteristic.uuid.toString()] = subscription;
  }
*/
