import 'dart:async';
//import 'package:flutter/foundation.dart';
import 'package:asset_inspections/Pokit_Multimeter/Models/pokitpro_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'package:asset_inspections/Util/cycle_settings_notifier.dart';

/// A button widget for controlling voltage.
///
/// This widget is used to control voltage settings and timers. It is a stateful widget
/// that allows the user to select a cycle mode, a selected mode, and provides callbacks
/// for handling timer status changes, button presses, and saving or updating data.
///
/// The [VoltageButton] requires the following parameters:
/// - [cycleMode]: The cycle mode for the voltage button.
/// - [selectedMode]: The selected mode for the voltage button.
/// - [multimeterService]: The multimeter service for the voltage button.
/// - [onTimerStatusChanged]: A callback function that is called when the on timer status changes.
/// - [onSaveOrUpdate]: A callback function that is called when data needs to be saved or updated.
/// - [containerName]: The name of the container for the voltage button.
///
/// The [VoltageButton] also accepts optional parameters:
/// - [onController]: A text editing controller for the on timer.
/// - [offController]: A text editing controller for the off timer.
/// - [offTimerStatusChanged]: A callback function that is called when the off timer status changes.
/// - [onButtonPressed]: A callback function that is called when the button is pressed.
class VoltageButton extends StatefulWidget {
  final CycleMode cycleMode;
  final Mode selectedMode;
  final MultimeterService multimeterService;
  final TextEditingController? acController;
  final TextEditingController? onController;
  final TextEditingController? offController;
  final Function(bool)? acTimerStatusChanged;
  final Function(bool)? onTimerStatusChanged;
  final Function(bool)? offTimerStatusChanged;
  final Function()? onButtonPressed;
  final Function(String, [List<String>]) onSaveOrUpdate;
  final String containerName;

  const VoltageButton({
    super.key,
    required this.selectedMode,
    required this.multimeterService,
    required this.onSaveOrUpdate,
    required this.containerName,
    required this.cycleMode,
    this.acController,
    this.onController,
    this.offController,
    this.acTimerStatusChanged,
    this.onTimerStatusChanged,
    this.offTimerStatusChanged,
    this.onButtonPressed,
  });

  @override
  createState() => _VoltageButtonState();
}

enum CycleMode { staticMode, cycledMode }

class _VoltageButtonState extends State<VoltageButton> {
  StreamSubscription<double>? _readingSubscription;
  Timer? _timer;
  Timer? _cycleTimer;
  bool isDialogVisible = false;
  bool isCycleOn = false;
  final List<double> _readings = [];
  Mode idleMode = Mode.idle;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _readingSubscription?.cancel();
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _updateController(TextEditingController? controller, double value) {
    if (controller != null) {
      if (kDebugMode) {
        print('Updating controller: $controller with value: $value');
      }
      setState(() {
        controller.text = value.toStringAsFixed(3);
      });
    }
  }

  Future<void> _syncAndStartCycle() async {
    if (kDebugMode) {
      print('_syncAndStartCycle started');
    }
    var cycleSettings = Provider.of<CycleSettingsModel>(context, listen: false);

    String? selectedCycle = cycleSettings.selectedCycle;
    List<String> parts = selectedCycle?.split('|') ?? ['1.5', '0.5'];

    double onDuration = double.parse(parts[0].trim());
    double offDuration = double.parse(parts[1].trim());
    double cycleDuration = onDuration + offDuration;
    double captureDuration = cycleDuration * 2 * 1000;
    _startReadingSubscription(captureDuration);
  }

  void _startReadingSubscription(double duration) {
    if (kDebugMode) {
      print('_startReadingSubscription started with duration: $duration');
    }
    _readings.clear();
    _readingSubscription = widget.multimeterService.currentReadingStream.listen((double reading) {
      if (kDebugMode) {
        print('Received reading (cycled mode): $reading');
      }
      _readings.add(reading);
      _updateController(widget.onController, reading);
    });

    _timer = Timer(Duration(milliseconds: duration.round()), () {
      _processReadings();
    });
  }

  void _processReadings() {
    if (kDebugMode) {
      print('_processReadings started');
    }
    double sum = _readings.fold(0, (sum, item) => sum + item);
    double cycleAverage = sum / _readings.length;

    List<double> aboveAverage = _readings.where((r) => r > cycleAverage).toList();
    List<double> belowAverage = _readings.where((r) => r <= cycleAverage).toList();

    double medianAbove = _calculateMedian(aboveAverage);
    double medianBelow = _calculateMedian(belowAverage);

    if (kDebugMode) {
      print('Median Above: $medianAbove, Median Below: $medianBelow');
    }
    if (mounted) {
      _updateController(widget.onController, medianBelow);
      _updateController(widget.offController, medianAbove);
      List<String> stringReadings = _readings.map((reading) => reading.toStringAsFixed(3)).toList();
      widget.onSaveOrUpdate(widget.containerName, stringReadings);
      widget.multimeterService.subscribeToServiceAndReading(idleMode);
      _readingSubscription?.cancel();
    }
  }

  double _calculateMedian(List<double> list) {
    if (list.isEmpty) return 0.0;
    list.sort();
    int mid = list.length ~/ 2;
    return list.length % 2 == 1 ? list[mid] : (list[mid - 1] + list[mid]) / 2;
  }

  Future<void> _startSubscriptionAndTimer() async {
    if (kDebugMode) {
      print('_startSubscriptionAndTimer started');
    }
    _readingSubscription = widget.multimeterService.currentReadingStream.listen(
      (double reading) {
        if (kDebugMode) {
          print('Received reading (static mode): $reading');
        }
        _updateController(widget.acController, reading);
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error in subscription: $error');
        }
      },
    );

    _timer = Timer(const Duration(seconds: 4), () {
      if (kDebugMode) {
        print('_startSubscriptionAndTimer timer ended');
      }
      widget.onSaveOrUpdate(widget.containerName);
      widget.multimeterService.subscribeToServiceAndReading(idleMode);
      _readingSubscription?.cancel();
    });
  }

  Future<void> _startService() async {
    if (kDebugMode) {
      print('Starting service with cycleMode: ${widget.cycleMode}');
      print(
          'Initial state - acController: ${widget.acController?.text}, onController: ${widget.onController?.text}, offController: ${widget.offController?.text}');
      print(
          'Initial state - acController: ${widget.acController?.text}, onController: ${widget.onController?.text}, offController: ${widget.offController?.text}');
    }

    if (isDialogVisible) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
      isDialogVisible = false;
    }

    widget.multimeterService.setDevice(BluetoothManager.instance.pokitProModel!.device);
    await widget.multimeterService.initialize();
    await widget.multimeterService.subscribeToServiceAndReading(widget.selectedMode);

    if (widget.cycleMode == CycleMode.cycledMode) {
      if (mounted) {
        widget.onController?.text = 'Starting...';
        widget.offController?.text = '';
        if (kDebugMode) {
          print('Entering cycle mode: ${widget.cycleMode}');
        }
        await _syncAndStartCycle();
      }
    } else {
      if (widget.cycleMode == CycleMode.staticMode) {
        if (mounted) {
          widget.acController?.text = 'Starting...';
          if (kDebugMode) {
            print('Entering cycle mode: ${widget.cycleMode}');
          }
          await _startSubscriptionAndTimer();
        }
      }
      if (kDebugMode) {
        print(
            'End of _startService - acController: ${widget.acController?.text}, onController: ${widget.onController?.text}, offController: ${widget.offController?.text}');
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
          _startService();
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 43, 92),
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            color: const Color.fromARGB(255, 247, 143, 30),
            icon: Icon(widget.cycleMode == CycleMode.cycledMode ? Icons.monitor_heart : Icons.hourglass_bottom),
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
                await _startService();
              }
            },
          ),
        );
      },
    );
  }
}
