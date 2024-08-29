import 'package:asset_inspections/Common_Widgets/bottomsheet_livegraph.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
//import 'package:provider/provider.dart';

//import 'package:asset_inspections/Common_Widgets/live_graph.dart';
//import 'package:asset_inspections/Pokit_Multimeter/Models/mmservice_model.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart'; // Import the BluetoothManager
import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart'; // Import the MultimeterService and related classes

class MultimeterUIPage extends StatefulWidget {
  const MultimeterUIPage({super.key});

  @override
  createState() => _MultimeterUIPageState();
}

class _MultimeterUIPageState extends State<MultimeterUIPage> {
  Mode selectedMode = Mode.idle; // Set the default mode to DC Voltage
  int? selectedRange;
  String? previousSwitchPosition;
  String? bmcurrentSwitchPosition;
  List<Mode> availableModes = [];
  // Create an instance of MultimeterService
//  final MultimeterService multimeterService = MultimeterService();
  final MultimeterService multimeterService = MultimeterService.instance;
  final BluetoothManager bluetoothManager = BluetoothManager.instance;

  bool showMin = false;
  bool showMax = false;

  @override
  void initState() {
    super.initState();

    bluetoothManager.addListener(_bluetoothStateChanged);
    bmcurrentSwitchPosition = bluetoothManager.pokitProModel?.statusServiceModel?.statusCharacteristicModel?.switchPosition;

    if (bluetoothManager.pokitProModel != null) {
      multimeterService.setDevice(BluetoothManager.instance.pokitProModel!.device);
      _setupAndStartMultimeterService(multimeterService);
      if (kDebugMode) {
        print('Available Modes: $availableModes');
        // Temporary listener for debugging
        multimeterService.currentReadingStream.listen((value) {
          //    print("Stream emitted: $value");
        });
      }
    }
  }

  /// Sets up and starts the multimeter service.
  ///
  /// This method initializes the [multimeterService] and updates the available modes
  /// using the [BluetoothManager.instance].
  ///
  /// Parameters:
  /// - [multimeterService]: The multimeter service to be set up and started.
  ///
  /// Returns: A Future that completes when the multimeter service is set up and started.
  void _setupAndStartMultimeterService(MultimeterService multimeterService) async {
    await multimeterService.initialize();
    _updateAvailableModes(BluetoothManager.instance);
  }

  /// Callback function that is called when the Bluetooth state changes.
  void _bluetoothStateChanged() {
    String? currentSwitchPosition = bluetoothManager.pokitProModel?.statusServiceModel?.statusCharacteristicModel?.switchPosition;
    if (currentSwitchPosition != previousSwitchPosition) {
      if (mounted) {
        setState(() {
          //   bluetoothManager.updateSwitchPosition(newPosition);
          _updateAvailableModes(BluetoothManager.instance);
        });
      }
      previousSwitchPosition = currentSwitchPosition;
    }
  }

  /// Updates the available modes based on the switch position of the Pokit Pro model.
  /// Sets the [availableModes] list to the appropriate modes based on the switch position.
  /// If the switch position is 'Voltage', the available modes are [Mode.dcVoltage, Mode.acVoltage].
  /// If the switch position is 'MultiMode', the available modes are [Mode.dcCurrent, Mode.acCurrent, Mode.resistance, Mode.diode, Mode.continuity].
  /// If the switch position is 'High Current', the available modes are [Mode.dcCurrent, Mode.acCurrent].
  /// If the switch position is none of the above, the [availableModes] list is set to an empty list.
  /// Sets the [selectedMode] to the first mode in the [availableModes] list, or to [Mode.idle] if the list is empty.
  /// Resets the min and max readings of the multimeter service.
  /// Subscribes to the multimeter service with the updated selected mode.
  /// Stores the previous switch position for reference.
  /// Prints a debug message if in debug mode.
  void _updateAvailableModes(BluetoothManager bluetoothManager) {
    var statusModel = bluetoothManager.pokitProModel?.statusServiceModel?.statusCharacteristicModel;

    // Determine available modes based on switchPosition
    switch (statusModel?.switchPosition) {
      case 'Voltage':
        availableModes = [Mode.dcVoltage, Mode.acVoltage];
        break;
      case 'MultiMode':
        availableModes = [Mode.dcCurrent, Mode.acCurrent, Mode.resistance, Mode.diode, Mode.continuity];
        break;
      case 'High Current':
        availableModes = [Mode.dcCurrent, Mode.acCurrent];
        break;
      default:
        availableModes = []; // Empty or some default modes
    }

    // Select a default mode from the available modes or set to idle if none are available
    selectedMode = availableModes.isNotEmpty ? availableModes.first : Mode.idle;

    multimeterService.resetMinMaxReadings();

    // Now subscribe to the service with the updated selected mode
    multimeterService.subscribeToServiceAndReading(selectedMode);
    previousSwitchPosition = bluetoothManager.pokitProModel?.statusServiceModel?.statusCharacteristicModel?.switchPosition;
    if (kDebugMode) {
      print('Set State called to resubscribe');
    }
  }

  @override
  void dispose() {
    //   multimeterService.unsubscribeFromReading();
    bluetoothManager.removeListener(_bluetoothStateChanged);
    WakelockPlus.disable();
    super.dispose();
  }

  // Define a list of modes to show
  List<Mode> desiredModes = [
    Mode.dcVoltage,
    Mode.acVoltage,
    Mode.resistance,
    Mode.dcCurrent,
    Mode.acCurrent,
    Mode.temperature,
    Mode.capacitance,
    Mode.diode,
    Mode.continuity,
  ];

  /// Returns the display name for the given [mode].
  ///
  /// The display names are defined in a map where the [Mode] enum values are
  /// mapped to their corresponding display names. If the [mode] is not found
  /// in the map, the method returns 'N/A' as the default value.
  ///
  /// Example usage:
  /// ```dart
  /// Mode mode = Mode.dcVoltage;
  /// String displayName = getDisplayNameForMode(mode);
  /// print(displayName); // Output: "DC Volts"
  /// ```
  String getDisplayNameForMode(Mode mode) {
    Map<Mode, String> displayNames = {
      Mode.dcVoltage: "DC Volts ",
      Mode.acVoltage: "AC Volts",
      Mode.resistance: "Resistance ",
      Mode.dcCurrent: "DC Current",
      Mode.acCurrent: "AC Current",
      Mode.temperature: "Temperature",
      Mode.capacitance: "Capacitance",
      Mode.diode: "Diode",
      Mode.continuity: "Continuity",
    };
    return displayNames[mode] ?? 'N/A'; // Default value if mode isn't found
  }

  /// Returns the display mode for the given [mode].
  ///
  /// The display mode is a string representation of the mode used in the multimeter UI.
  ///
  /// - For [Mode.dcVoltage], it returns 'V DC'.
  /// - For [Mode.acVoltage], it returns 'V AC'.
  /// - For [Mode.resistance], it returns 'Ω'.
  /// - For [Mode.dcCurrent], it returns 'A DC'.
  /// - For [Mode.acCurrent], it returns 'A AC'.
  /// - For [Mode.temperature], it returns '°C'.
  /// - For [Mode.capacitance], it returns 'Cap'.
  /// - For [Mode.diode], it returns 'Diode'.
  /// - For [Mode.continuity], it returns 'Cont'.
  /// - For any other mode, it returns 'Idle'.
  String modeToDisplay(Mode? mode) {
    switch (mode) {
      case Mode.dcVoltage:
        return 'V DC';
      case Mode.acVoltage:
        return 'V AC';
      case Mode.resistance:
        return 'Ω';
      case Mode.dcCurrent:
        return 'A DC';
      case Mode.acCurrent:
        return 'A AC';
      case Mode.temperature:
        return '°C';
      case Mode.capacitance:
        return 'Cap';
      case Mode.diode:
        return 'Diode';
      case Mode.continuity:
        return 'Cont';
      default:
        return 'Idle';
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(384, 824));
    WakelockPlus.enable();

    // Fetch Min and Max readings directly from the service
    // double? minReading = multimeterService.minReading;
    // double? maxReading = multimeterService.maxReading;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40.0), // Set height of the AppBar
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 43, 92),
          title: Text(
            'Multimeter',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          actions: const [Icon(Icons.bluetooth)],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 12.h),
            //Show the Live Graph
            Center(
              child: SizedBox(
                height: 350.h,
                width: 360.w,
                child: const BottomSheetLiveGraph(), //LiveGraph(),
              ),
            ),
            SizedBox(height: 8.h),

            // Show Min and Max readings when toggled on
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Center the items in the row
              children: [
                // Min display
                if (showMin)
                  StreamBuilder<double>(
                    stream: multimeterService.minReadingStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(text: 'Min: ', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                              TextSpan(
                                  text: snapshot.data!.toStringAsFixed(3),
                                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, fontFamily: 'DS-Digital', color: Colors.black)),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox(); // Or some other placeholder widget
                      }
                    },
                  ),

                // Max display
                if (showMax)
                  StreamBuilder<double>(
                    stream: multimeterService.maxReadingStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(text: 'Max: ', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                              TextSpan(
                                  text: snapshot.data!.toStringAsFixed(3),
                                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, fontFamily: 'DS-Digital', color: Colors.black)),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox(); // Or some other placeholder widget
                      }
                    },
                  ),

                // Reset button
                if (showMin || showMax)
                  ElevatedButton(
                    onPressed: () {
                      multimeterService.resetMinMaxReadings();
                    },
                    child: const Text('Reset Min & Max'),
                  ),
              ],
            ),

            // Large Display Section for Current Reading
            SizedBox(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center items in the row

                      children: [
                        StreamBuilder<double>(
                          stream: multimeterService.currentReadingStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.active) {
                              if (snapshot.hasData) {
                                // Display the current value from the stream and the mode in a Row
                                return Row(
                                  children: [
                                    Text(
                                      snapshot.data!.toStringAsFixed(3),
                                      style: TextStyle(
                                        fontSize: 96.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DS-Digital', // Use the DS-Digital font
                                      ),
                                    ),
                                    SizedBox(width: 16.w), // Space between currentReading and selectedMode
                                    Text(
                                      modeToDisplay(selectedMode),
                                      style: TextStyle(
                                        fontSize: 56.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DS-Digital',
                                      ),
                                    ),
                                  ],
                                );
                              } else if (snapshot.hasError) {
                                // Handle error
                                return Text('Error: ${snapshot.error}');
                              }
                            }
                            // Default placeholder or loading indicator
                            return const CircularProgressIndicator();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
            // Optionally, add options to set the range
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Menu Button
            ElevatedButton(onPressed: () {}, child: const Text('Menu')),

            // Mode Button
            ElevatedButton(
              onPressed: () {
                List<Mode> supportedModes = availableModes;
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 300.h, // Using screenutil for height
                      child: GridView.builder(
                        padding: EdgeInsets.all(10.w), // Using screenutil for padding
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10.w, // Using screenutil for spacing
                          mainAxisSpacing: 10.h, // Using screenutil for spacing
                          childAspectRatio: 3 / 2,
                        ),
                        itemCount: desiredModes.length,
                        itemBuilder: (BuildContext context, int index) {
                          Mode mode = desiredModes[index];
                          bool isSupported = supportedModes.contains(mode); // Check if the mode is supported
                          bool isSelected = mode == selectedMode; // Check if the mode is selected

                          return Opacity(
                            opacity: isSupported ? 1.0 : 0.5, // Dim the card if the mode is not supported
                            child: GestureDetector(
                              onTap: isSupported
                                  ? () async {
                                      Navigator.of(context).pop();
                                      //  await multimeterService.unsubscribeFromReading();
                                      multimeterService.resetMinMaxReadings();
                                      setState(() {
                                        selectedMode = mode;
                                      });
                                      multimeterService.setSelectedMode(selectedMode);

                                      multimeterService.setDevice(BluetoothManager.instance.pokitProModel!.device);
                                      await multimeterService.initialize();
                                      await multimeterService.subscribeToServiceAndReading(selectedMode);
                                      //  _updateAvailableModes(BluetoothManager.instance);
                                    }
                                  : null,
                              child: Card(
                                color: isSelected
                                    ? const Color.fromARGB(255, 0, 43, 92) // Color when selected
                                    : Colors.white, // Color when not selected// Color when not selected
                                elevation: isSelected
                                    ? 0 // Elevation when selected
                                    : 12, // Elevation when not selected
                                child: Center(
                                  child: Text(
                                    getDisplayNameForMode(mode),
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white // Text color when selected
                                          : Colors.black, // Text color when not selected
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              child: const Text('Mode'),
            ),

            // Func Button
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Allow the modal to take up the entire screen height
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: 150.h, // Set the height of the modal
                      child: Column(
                        children: [
                          const ListTile(
                            title: Text('Min/Max Toggle'),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showMin = !showMin;
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.pressed) || showMin) {
                                        return Theme.of(context).primaryColor.withOpacity(0.5);
                                      }
                                      return Theme.of(context).primaryColor;
                                    },
                                  ),
                                ),
                                child: const Text('Min'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showMax = !showMax;
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.pressed) || showMax) {
                                        return Theme.of(context).primaryColor.withOpacity(0.5);
                                      }
                                      return Theme.of(context).primaryColor;
                                    },
                                  ),
                                ),
                                child: const Text('Max'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Text('Func'),
            ),

            // History Button
            ElevatedButton(onPressed: () {}, child: const Text('History')),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(const MaterialApp(home: MultimeterUIPage()));
