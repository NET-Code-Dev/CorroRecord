import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'package:asset_inspections/Util/cycle_settings_notifier.dart';

class DCvoltsButtonCycled extends StatefulWidget {
  final Mode selectedMode = Mode.dcVoltage;
  final int? selectedRange;
  final TextEditingController? onController;
  final TextEditingController? offController;
  final MultimeterService? multimeterService;
  final Function(bool) onTimerStatusChanged;
  final Function(bool) offTimerStatusChanged;
  final Function onSaveOrUpdate;
  final String? selectedCycle;
  final int? selectedRadio;
  final VoidCallback? onButtonPressed;
  final String containerName;

  const DCvoltsButtonCycled({
    Key? key,
    this.selectedRange,
    required this.onController,
    required this.offController,
    this.multimeterService,
    required this.onTimerStatusChanged,
    required this.offTimerStatusChanged,
    required this.onSaveOrUpdate,
    this.selectedCycle,
    this.selectedRadio,
    this.onButtonPressed,
    required this.containerName,
  }) : super(key: key);

  @override
  createState() => _DCvoltsButtonCycledState();
}

class _DCvoltsButtonCycledState extends State<DCvoltsButtonCycled> {
  StreamSubscription<double>? _readingSubscription;
  Timer? _captureTimer;
  List<double> _readings = [];
  bool isDialogVisible = false;

  // Defines an asynchronous method named `_syncAndStartCycle` that returns a Future<void>
  Future<void> _syncAndStartCycle() async {
    // Retrieves the CycleSettingsModel object from the provider without listening to changes,
    // which means it doesn't rebuild the widget when the model changes
    var cycleSettings = Provider.of<CycleSettingsModel>(context, listen: false);

    // Retrieves the currently selected cycle as a string from cycleSettings
    String? selectedCycle = cycleSettings.selectedCycle;

    // Splits the selectedCycle string into parts using '|' as a delimiter;
    // if selectedCycle is null, it defaults to ['1.5', '0.5']
    List<String> parts = selectedCycle?.split('|') ?? ['1.5', '0.5'];

    // Parses the first part of the split string, trims any whitespace, and converts it to a double
    // representing the "on" duration of the cycle
    double onDuration = double.parse(parts[0].trim());

    // Parses the second part of the split string, trims any whitespace, and converts it to a double
    // representing the "off" duration of the cycle
    double offDuration = double.parse(parts[1].trim());

    // Calculates the total cycle duration by adding the "on" and "off" durations
    double cycleDuration = onDuration + offDuration;

    // Converts the total cycle duration to milliseconds and then doubles it for the full capture duration
    double captureDuration = cycleDuration * 2 * 1000; // Convert to milliseconds and double it

    // Calls another method named `_startReadingSubscription` and passes the calculated captureDuration
    _startReadingSubscription(captureDuration);
  }

  // Defines a method named `_startReadingSubscription` that takes a double parameter 'duration' and does not return a value.
  void _startReadingSubscription(double duration) async {
    // Clears the existing readings data, preparing for a new set of data.
    _readings.clear();

    // Subscribes to a stream of readings from a multimeter service.
    // 'currentReadingStream' is expected to emit double values representing readings.
    // For each reading received, it adds the reading to the _readings list.
    _readingSubscription = widget.multimeterService?.currentReadingStream.listen((double reading) {
      _readings.add(reading);
    });

    // Creates a new timer that runs once after 'duration' milliseconds have passed.
    // The duration is rounded to the nearest millisecond.
    _captureTimer = Timer(Duration(milliseconds: duration.round()), () {
      // Once the timer expires, it cancels the subscription to the reading stream.
      _readingSubscription?.cancel();
      // Calls a method on the multimeter service to stop receiving readings.
      widget.multimeterService?.unsubscribeFromReading();
      // Processes the collected readings once reading collection is complete.
      _processReadings();
    });
  }

  // Defines a method named `_processReadings` that processes the data collected in _readings.
  void _processReadings() {
    // Calculates the sum of all readings using the fold method, which iterates over each item,
    // adding each to the accumulator (sum), starting from an initial value of 0.
    double sum = _readings.fold(0, (sum, item) => sum + item);

    // Computes the average of all readings by dividing the sum by the number of readings.
    double cycleAverage = sum / _readings.length;

    // Filters the readings to create a new list containing only values above the calculated average.
    List<double> aboveAverage = _readings.where((r) => r > cycleAverage).toList();

    // Filters the readings to create a new list containing only values at or below the calculated average.
    List<double> belowAverage = _readings.where((r) => r <= cycleAverage).toList();

    // Calculates the median of the readings above the average using a helper method.
    double medianAbove = _calculateMedian(aboveAverage);

    // Calculates the median of the readings below the average using a helper method.
    double medianBelow = _calculateMedian(belowAverage);

    // Check if the widget is still in the widget tree and can handle setState calls.
    if (mounted) {
      // Updates the text of an input field (or similar widget) for off duration to the formatted median of readings above average.
      widget.offController?.text = medianAbove.toStringAsFixed(3);
      // Updates the text of another input field for on duration to the formatted median of readings below average.
      widget.onController?.text = medianBelow.toStringAsFixed(3);

      // Converts each reading in the _readings list to a formatted string and collects them into a new list.
      List<String> stringReadings = _readings.map((reading) => reading.toStringAsFixed(3)).toList();
      // Invokes a method to save or update these formatted readings, possibly in a database or external storage.
      widget.onSaveOrUpdate(widget.containerName, stringReadings);

      // Logs the list of original readings as doubles to the console for debugging or verification.
      print('Wave Form Readings as double: $_readings');
      // Logs the list of formatted readings as strings to the console for debugging or verification.
      print('Wave Form Readings as string: $stringReadings');
    }
  }

  // Defines a method named '_calculateMedian' that takes a list of double values as input
// and returns a double, which is the median of the list.
  double _calculateMedian(List<double> list) {
    // Checks if the list is empty; if yes, it returns 0.0 as the median.
    if (list.isEmpty) return 0.0;

    // Sorts the list in ascending order. This is necessary for median calculation,
    // as the median depends on the central values in a sorted sequence.
    list.sort();

    // Finds the middle index of the list. If the list length is odd, this is the median;
    // if even, the median will be the average of the two central values.
    int mid = list.length ~/ 2;

    // Returns the median value:
    // If the list has an odd number of elements, it returns the element at the middle index.
    // If the list has an even number of elements, it calculates the median as the average
    // of the two central elements.
    return list.length % 2 == 1 ? list[mid] : (list[mid - 1] + list[mid]) / 2;
  }

  // Defines an asynchronous method named 'dcVoltsButtonCycledStartService'.
  Future<void> dcVoltsButtonCycledStartService() async {
    // Checks if a dialog is currently displayed; if so, closes it.
    if (isDialogVisible) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
    }

    // Clears the text in the user interface controllers, likely used for displaying device status or readings.
    widget.onController?.text = '';
    widget.offController?.text = '';

    // Sets the device for the multimeter service using a specific Bluetooth manager instance.
    widget.multimeterService?.setDevice(BluetoothManager.instance.pokitProModel!.device);

    // Initializes the multimeter service asynchronously.
    await widget.multimeterService?.initialize();

    // Subscribes to updates from the multimeter service for a specific mode, likely the DC voltage measurement mode.
    await widget.multimeterService?.subscribeToServiceAndReading(widget.selectedMode);

    // Calls a method to synchronize and start a measurement cycle.
    _syncAndStartCycle();

    // Conditional block to check if an event handler is assigned to the button press action.
    if (widget.onButtonPressed != null) {
      // This line is commented out, but it suggests that originally the event would show a graph bottom sheet.
      // widget.onButtonPressed!();  // Uncomment this to trigger the action when the button is pressed.
      // _showGraphBottomSheet();    // This would show additional UI component, like a graph.
    } else {
      // If no device is connected (or no action is defined), shows a snack bar notification.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No device connected')),
        );
      }
    }
  }

  @override
  void dispose() {
    _readingSubscription?.cancel();
    _captureTimer?.cancel();
    CycleSettingsModel().dispose();
    // MultimeterService().dispose();
    //  MultimeterService.instance.unsubscribeFromReading();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<BluetoothManager, String?>(
      selector: (_, manager) => manager.pokitProModel?.statusServiceModel?.statusCharacteristicModel?.switchPosition,
      builder: (context, switchPosition, child) {
        // Reactively close the dialog if the switch position is correct and the dialog is visible
        if (switchPosition == 'Voltage' && isDialogVisible) {
          dcVoltsButtonCycledStartService();
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 43, 92),
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            color: const Color.fromARGB(255, 247, 143, 30),
            icon: const Icon(Icons.monitor_heart_outlined),
            onPressed: () async {
              // Check the switch position and show the dialog if necessary
              if (switchPosition != 'Voltage') {
                if (!isDialogVisible) {
                  isDialogVisible = true;
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const AlertDialog(
                        title: Text('Error'),
                        content: Text('Please switch to Voltage mode on the multimeter'),
                      );
                    },
                  );
                  if (mounted) {
                    setState(() => isDialogVisible = false);
                  }
                }
              } else {
                await dcVoltsButtonCycledStartService();
              }
            },
          ),
        );
      },
    );
  }
}
