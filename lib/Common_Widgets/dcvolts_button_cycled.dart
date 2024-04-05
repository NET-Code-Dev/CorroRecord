import 'dart:async';

//import 'package:asset_inspections/Pokit_Multimeter/Models/mmservice_model.dart';
//import 'package:asset_inspections/Common_Widgets/live_graph.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ntp/ntp.dart';

import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart'; // Import the MultimeterService and related classes
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'package:asset_inspections/Util/cycle_settings_notifier.dart';
//import 'package:asset_inspections/multimeter_ui.dart';
//import 'package:path/path.dart';
//import 'package:provider/provider.dart'; // Import the BluetoothManager

/// A widget that represents a button for cycling through DC voltage modes.
///
/// This widget is used to display a button for capturing DC voltage readings on a interputed cycle.
/// It takes in various parameters such as the selected range, text controllers for on/off values,
/// a multimeter service, callbacks for timer status changes and save/update actions,
/// the selected cycle and radio values, and a callback for button press events.
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

/// This class represents the state of the DCvoltsButtonCycled widget.
/// It manages the cycle process and synchronization with the multimeter service.
class _DCvoltsButtonCycledState extends State<DCvoltsButtonCycled> {
  StreamSubscription<double>? _readingSubscription; // Make it nullable
  Timer? _timer;
  int _onCycleCount = 0;
  int _offCycleCount = 0;
  bool on = true;
  bool isDialogVisible = false;

  /// Fetches the current UTC time using the NTP package.
  /// Returns a [Future] that completes with a [DateTime] object representing the current UTC time.
  Future<DateTime> _fetchUtcTime() async {
    return NTP.now();
  }

  /// Synchronizes data and starts the cycle.
  ///
  /// This method fetches the current UTC time and accesses the [CycleSettingsModel] from the provider.
  /// It then parses the selected cycle to get the ON and OFF durations in seconds.
  /// The exact times for the ON and OFF cycles are calculated based on the current UTC time and the durations.
  /// Finally, it sets the cycle timers using the provided UTC time and durations.
  Future<void> _syncAndStartCycle() async {
    // Fetch the current UTC time
    DateTime utcTime = await _fetchUtcTime();

    // Access CycleSettingsModel from the provider
    // ignore: use_build_context_synchronously
    var cycleSettings = Provider.of<CycleSettingsModel>(context, listen: false);
    String? selectedCycle = cycleSettings.selectedCycle;

    // Parse your selectedCycle to get ON and OFF durations in seconds
    List<String> parts = selectedCycle?.split('|') ?? ['1.5', '0.5']; // Default values
    int onDurationInSeconds = (double.parse(parts[0].trim()) * 1000).round();
    int offDurationInSeconds = (double.parse(parts[1].trim()) * 1000).round();

    // Calculate the exact times for the ON and OFF cycles
    DateTime onStartTime = utcTime.add(Duration(milliseconds: onDurationInSeconds));
    DateTime offStartTime = onStartTime.add(Duration(milliseconds: offDurationInSeconds));

    if (kDebugMode) {
      print('On cycle starts at: $onStartTime');
      print('Off cycle starts at: $offStartTime');
    }

    _setCycleTimers(utcTime, onDurationInSeconds, offDurationInSeconds);
  }

  /// Sets the cycle timers for the button.
  ///
  /// The [startTime] parameter specifies the starting time for the cycle.
  /// The [onDuration] parameter specifies the duration in milliseconds for which the button is on.
  /// The [offDuration] parameter specifies the duration in milliseconds for which the button is off.
  ///
  /// This method sets a periodic timer that toggles the cycle state without cancelling the subscription.
  /// It also starts the reading subscription independently.
  void _setCycleTimers(DateTime startTime, int onDuration, int offDuration) {
    _timer = Timer.periodic(Duration(milliseconds: onDuration + offDuration), (timer) {
      // Toggle the cycle state without cancelling the subscription
      _updateCycleState();
    });

    // Start the subscription independently
    _startReadingSubscription();
  }

  /// Updates the cycle state by incrementing the cycle count based on the current state.
  /// If the state is 'on', the '_onCycleCount' is incremented, otherwise '_offCycleCount' is incremented.
  /// The state is then toggled for the next cycle.
  /// If both '_onCycleCount' and '_offCycleCount' reach 3, the timer and reading subscription are paused.
  void _updateCycleState() async {
    if (on) {
      _onCycleCount++;
    } else {
      _offCycleCount++;
    }

    // Toggle the state for the next cycle
    on = !on;

    if (_onCycleCount >= 3 && _offCycleCount >= 3) {
      _timer?.cancel();
      _readingSubscription?.pause();
      //  await MultimeterService.instance.unsubscribeFromReading();
      widget.onSaveOrUpdate(widget.containerName);
      widget.onButtonPressed!();
      await MultimeterService.instance.unsubscribeFromReading();

      if (kDebugMode) {
        print('Reached 3 complete cycles. Stopping readings.');
      }
      return;
    }
  }

  /// Starts the reading subscription for the multimeter service.
  /// Cancels any existing subscription before starting a new one.
  /// Updates the reading value in the appropriate text field based on the 'on' state.
  ///
  /// If an error occurs during the subscription, it is handled by the onError callback.
  void _startReadingSubscription() {
    _readingSubscription?.cancel(); // Cancel any existing subscription
    _readingSubscription = widget.multimeterService?.currentReadingStream.listen(
      (double reading) {
        String readingStr = reading.toStringAsFixed(3);
        if (on) {
          widget.onController?.text = readingStr;
        } else {
          widget.offController?.text = readingStr;
        }
      },
      onError: (error) {
        // Handle error
      },
    );

    //  widget.onTimerStatusChanged(true);
    //  widget.offTimerStatusChanged(true);
    //  MultimeterService.instance.unsubscribeFromReading();
  }

  @override
  void dispose() {
    _readingSubscription?.cancel();
    _timer?.cancel();
    CycleSettingsModel().dispose();
    // MultimeterService().dispose();
    MultimeterService.instance.unsubscribeFromReading();

    super.dispose();
  }

  Future<void> dcVoltsButtonCycledStartService() async {
    if (isDialogVisible) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
    }

    widget.onController?.text = '';
    widget.offController?.text = '';
    widget.multimeterService?.setDevice(BluetoothManager.instance.pokitProModel!.device);

    await widget.multimeterService?.initialize();
    await widget.multimeterService?.subscribeToServiceAndReading(widget.selectedMode);
    _syncAndStartCycle();
    if (widget.onButtonPressed != null) {
      widget.onButtonPressed!();
      //       _showGraphBottomSheet();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No device connected')),
        );
      }
    }
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


/*
  void _updateReading({required bool on}) {
    if (on) {
      _onCycleCount++;
    } else {
      _offCycleCount++;
    }

    if (_onCycleCount >= 3 && _offCycleCount >= 3) {
      _timer?.cancel();
      _readingSubscription?.cancel();
      if (kDebugMode) {
        print('Reached 3 complete cycles. Stopping readings.');
      }
      return;
    }

    _readingSubscription?.cancel(); // Cancel any existing subscription
    _readingSubscription = widget.multimeterService.currentReadingStream.listen(
      (double reading) {
        String readingStr = reading.toStringAsFixed(3);
        if (on) {
          widget.onController.text = readingStr;
        } else {
          widget.offController.text = readingStr;
        }
      },
      onError: (error) {
        // Handle error
      },
    );
  }
*/
