// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, prefer_const_constructors, avoid_print

import 'package:asset_inspections/Pokit_Multimeter/Models/pokitpro_model.dart';
import 'package:asset_inspections/Pokit_Multimeter/Models/statusservice_model.dart';
import 'package:flutter/material.dart'; // Import MaterialApp and Key
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';

//import '../Pokit_Multimeter/Models/bluetooth_device_model.dart';
import 'cycle_settings.dart';

class BluetoothConnectionPage extends StatefulWidget {
  @override
  _BluetoothConnectionPageState createState() => _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  PokitProModel? pairedDevice;
  StatusServiceModel? statusServiceModel;
  BluetoothManager? bluetoothManager;
  String? selectedCycle;
  int? selectedRadio;

  @override
  void initState() {
    super.initState();

    bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);

    // Fetch current device details if available
    pairedDevice = bluetoothManager?.pokitProModel;

    // Set the callback for when device details are updated
    bluetoothManager!.onDeviceDetailsUpdated = (deviceModel) {
      setState(() {
        pairedDevice = deviceModel;
      });
    };
  }

/*
  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    FlutterBluePlus.stopScan();
    bluetoothManager?.serviceChangedSubscription?.cancel();
    bluetoothManager?.statusCharacteristicSubscription?.cancel();
    bluetoothManager?.torchCharacteristicSubscription?.cancel();
    bluetoothManager?.buttonCharacteristicSubscription?.cancel();
    bluetoothManager?.mmReadingSubscription?.cancel();
    bluetoothManager?.dsoReadingSubscription?.cancel();
    bluetoothManager?.dsoMetadataSubscription?.cancel();
    bluetoothManager?.dataloggerReadingSubscription?.cancel();
    bluetoothManager?.dataloggerMetadataSubscription?.cancel();
    bluetoothManager?.onDeviceDetailsUpdated = null; // Nullify the callback
    super.dispose();
  }
*/
  /// Builds the UI for connecting to Bluetooth devices.
  ///
  /// This method returns a [Widget] that displays the UI for connecting to Bluetooth devices.
  /// It uses the [Consumer] widget to listen for changes in the [BluetoothManager] and rebuilds
  /// the UI accordingly. The UI consists of an [AppBar] with a custom title and color, and a
  /// [ValueListenableBuilder] that listens for changes in the [BluetoothConnectionState].
  /// If the state is [BluetoothConnectionState.connected], it displays the connected view,
  /// otherwise it displays the disconnected view.
  ///
  /// The connected view includes the [_buildConnectedView] widget and the [InterruptionCycleSelector]
  /// widget, while the disconnected view includes the [_buildDisconnectedView] widget.
  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothManager>(builder: (context, bluetoothManager, child) {
      // Access bluetoothManager properties here
      pairedDevice = bluetoothManager.pokitProModel;

      return Scaffold(
        appBar: AppBar(
          title: Text('Bluetooth Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22,
              )),
          backgroundColor: Color.fromARGB(255, 0, 43, 92), // Custom color
          centerTitle: true,
        ),
        body: ValueListenableBuilder<BluetoothConnectionState>(
          // Add a ValueListenableBuilder
          valueListenable: bluetoothManager.deviceStateNotifier,
          builder: (context, state, _) {
            if (state == BluetoothConnectionState.connected) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildConnectedView(), // Add the connected view, defined below
                    InterruptionCycleSelector(),
                  ],
                ),
              );
            } else {
              return _buildDisconnectedView(); // Add the disconnected view, defined below
            }
          },
        ),
      );
    });
  }

  /// Builds the view for when there is no Bluetooth device connected.
  ///
  /// This widget displays an icon indicating that Bluetooth is disabled,
  /// along with a message instructing the user to tap a button to scan for devices.
  /// The button triggers the [_pairDevice] method when pressed.
  Widget _buildDisconnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Align items to center
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.bluetooth_disabled,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 20), // Spacing
          Text(
            'No Bluetooth device is connected.\nTap the button below to scan for devices.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 30), // Spacing
          ElevatedButton.icon(
            icon: Icon(Icons.search),
            label: Text('Scan for Devices'),
            onPressed: _pairDevice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor, // Use theme color
              foregroundColor: Colors.white, // Text color
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the connected view widget.
  ///
  /// This widget displays the UI for the connected state, showing information about the paired device.
  /// It includes the device name, disconnect button, and various details about the device such as battery level, version, status, etc.
  /// The details are obtained from the [pairedDevice] object.
  Widget _buildConnectedView() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        children: <Widget>[
          Card(
            elevation: 4,
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pairedDevice?.device.platformName ?? 'No device selected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    //  Expanded(
                    //   child:
                    ElevatedButton.icon(
                      icon: Icon(Icons.power_settings_new),
                      label: Text('Disconnect'),
                      onPressed: bluetoothManager?.unpairDevice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 247, 143, 30), // Custom color
                      ),
                    ),
                    //  ),
                  ],
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(Icons.battery_charging_full, 'Battery Level',
                        pairedDevice?.statusServiceModel?.statusCharacteristicModel?.batteryLevel), // Double
                    _detailRowString(Icons.memory, 'Version', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.version), // String
                    _detailRowString(
                        Icons.info_outline, 'Status', pairedDevice?.statusServiceModel?.statusCharacteristicModel?.statusDescription), // String

                    _detailRowInt(Icons.electrical_services, 'Max Voltage', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.maxVoltage,
                        ' V'), // Int with unit
                    _detailRowInt(Icons.flash_on, 'Max Current', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.maxCurrent,
                        ' mA'), // Int with unit
                    _detailRowInt(Icons.build_circle, 'Max Resistance', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.maxResistance,
                        ' Ω'), // Int with unit
                    _detailRowInt(Icons.speed, 'Max Sampling Rate', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.maxSampleRate,
                        ' Hz'), // Int with unit
                    _detailRowInt(Icons.storage, 'Sampling Buffer Size',
                        pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.sampleBufferSize, ' Bytes'), // Int with unit
                    _detailRowInt(
                        Icons.settings, 'Capability Mask', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.capabilityMask), // Int
                    _detailRowString(
                        Icons.bluetooth, 'MAC Address', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.macAddress), // String
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildConnectedView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Card(
            elevation: 4,
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 0),
                child: Row(
                  children: [
                    Text(
                      pairedDevice?.device.localName ?? 'No device selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      icon: Icon(Icons.power_settings_new),
                      label: Text('Disconnect'),
                      onPressed: bluetoothManager?.unpairDevice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 247, 143, 30), // Custom color
                      ),
                    ),
                  ],
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(Icons.battery_charging_full, 'Battery Level',
                        pairedDevice?.statusServiceModel?.statusCharacteristicModel?.batteryLevel), // Double
                    _detailRowString(Icons.memory, 'Version', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.version), // String
                    _detailRowString(
                        Icons.info_outline, 'Status', pairedDevice?.statusServiceModel?.statusCharacteristicModel?.statusDescription), // String

                    _detailRowInt(Icons.electrical_services, 'Max Voltage', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.maxVoltage,
                        ' V'), // Int with unit
                    _detailRowInt(Icons.flash_on, 'Max Current', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.maxCurrent,
                        ' mA'), // Int with unit
                    _detailRowInt(Icons.build_circle, 'Max Resistance', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.maxResistance,
                        ' Ω'), // Int with unit
                    _detailRowInt(Icons.speed, 'Max Sampling Rate', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.maxSampleRate,
                        ' Hz'), // Int with unit
                    _detailRowInt(Icons.storage, 'Sampling Buffer Size',
                        pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.sampleBufferSize, ' Bytes'), // Int with unit
                    _detailRowInt(
                        Icons.settings, 'Capability Mask', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.capabilityMask), // Int
                    _detailRowString(
                        Icons.bluetooth, 'MAC Address', pairedDevice?.statusServiceModel?.deviceCharacteristicModel?.macAddress), // String
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  */
  /// Builds a row widget that displays an icon, title, and progress indicator.
  ///
  /// The [icon] parameter specifies the icon to be displayed.
  /// The [title] parameter specifies the title text.
  /// The [value] parameter specifies the progress value as a percentage (0-100).
  /// If [value] is null, the progress indicator will be set to 0.
  Widget _detailRow(IconData icon, String title, double? value) {
    // Assuming the value is a percentage (0-100)
    double progress = (value ?? 0) / 100;

    //String displayValue =
    value != null ? '${value.toStringAsFixed(1)}%' : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20.sp),
          SizedBox(width: 8.w),
          Text('$title: ', style: TextStyle(fontWeight: FontWeight.bold)),
          // Container(
          // child:
          Stack(
            alignment: Alignment.center,
            children: [
              // ignore: sized_box_for_whitespace
              Container(
                width: 100.w, // Set your desired width here
                child: LinearProgressIndicator(
                  minHeight: 20.h,
                  value: progress,
                  backgroundColor: Colors.grey[500],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              //  Align(
              //    alignment: Alignment.center,
              // padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              //   child: Center(
              //    child:
              Text(
                '${value?.toStringAsFixed(1) ?? 'N/A'}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 20.sp,
                ),
              ),
              //   ),
              //  ),
            ],
          ),
          //   ),
        ],
      ),
    );
  }

  /// Builds a row widget with an icon, title, and value.
  ///
  /// The [icon] parameter specifies the icon to be displayed.
  /// The [title] parameter specifies the title text.
  /// The [value] parameter specifies the value text.
  ///
  /// Returns a [Widget] containing the row widget.
  Widget _detailRowString(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text('$title: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? 'N/A'),
        ],
      ),
    );
  }

  /// Builds a row widget with an icon, title, value, and optional unit.
  ///
  /// The [icon] parameter specifies the icon to be displayed.
  /// The [title] parameter specifies the title text.
  /// The [value] parameter specifies the integer value to be displayed.
  /// The [unit] parameter specifies the optional unit of measurement.
  ///
  /// Returns a [Widget] containing the row with the specified icon, title, value, and unit.
  Widget _detailRowInt(IconData icon, String title, int? value, [String? unit]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text('$title: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value != null ? '$value${unit ?? ''}' : 'N/A'),
        ],
      ),
    );
  }

  /// Function to pair a Bluetooth device.
  /// This function shows a modal bottom sheet with a list of available devices.
  /// The user can select a device from the list to connect to.
  /// If the device is already connected, it displays the device name and battery level.
  /// If there is an error connecting to the device, it displays an error message.
  void _pairDevice() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        bluetoothManager?.startBluetoothScan();
        return ValueListenableBuilder(
            valueListenable: bluetoothManager!.availableDevicesNotifier,
            builder: (context, List<BluetoothDevice> devices, _) {
              if (bluetoothManager?.isConnected == false) {
                if (devices.isEmpty) {
                  return Center(child: Text('Scanning for devices...'));
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.platformName),
                      subtitle: Text(device.remoteId.toString()),
                      onTap: () {
                        FlutterBluePlus.stopScan();
                        bluetoothManager?.connectToDevice(device).then((_) {
                          setState(() {
                            pairedDevice = bluetoothManager?.pokitProModel;
                          });
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
                // ignore: unrelated_type_equality_checks
              } else if (bluetoothManager?.pokitProModel?.device.connectionState == BluetoothConnectionState.connected) {
                // Optionally, stop the scan here too
                FlutterBluePlus.stopScan();
                return Center(
                    child: Text(
                        'Connected to ${bluetoothManager?.pokitProModel?.device.platformName} Battery Level: ${pairedDevice?.statusServiceModel?.statusCharacteristicModel?.batteryPercentage ?? 'N/A'}%'));
              } else {
                return Center(child: Text('Error connecting to device'));
              }
            });
      },
    ).then((_) {
      FlutterBluePlus.stopScan();
    });
  }
}
