// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';

//import 'package:asset_inspections/Pokit_Multimeter/Models/mmservice_model.dart';
import 'package:flutter/material.dart';

import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart'; // Import the MultimeterService and related classes
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
//import 'package:asset_inspections/Pokit_Multimeter/Models/mmservice_model.dart';
import 'package:provider/provider.dart';

class DCvoltsMMButton extends StatefulWidget {
  final Mode selectedMode;
  final int? selectedRange;
  final TextEditingController? controller;
  final MultimeterService multimeterService;
  final Function(bool) onTimerStatusChanged;
  final Function(String) onSaveOrUpdate;
  final String containerName;

  const DCvoltsMMButton({
    super.key,
    this.selectedRange,
    required this.controller,
    required this.multimeterService,
    required this.onTimerStatusChanged,
    required this.onSaveOrUpdate,
    required this.containerName,
    required this.selectedMode,
  });

  @override
  createState() => _DCvoltsMMButtonState();
}

class _DCvoltsMMButtonState extends State<DCvoltsMMButton> {
  StreamSubscription<double>? _readingSubscription; // Make it nullable
  Timer? _timer;
  bool isDialogVisible = false;
  Mode idleMode = Mode.idle;

  void _startSubscriptionAndTimer() {
    // Cancel any existing subscription before starting a new one
    _readingSubscription?.cancel();
    _readingSubscription = widget.multimeterService.currentReadingStream.listen(
      (double reading) {
        widget.controller?.text = reading.toStringAsFixed(3);
      },
      onError: (error) {
        // Handle any errors here
      },
    );

    // Start the timer
    const duration = Duration(seconds: 5);
    widget.onTimerStatusChanged(true);
    _timer = Timer(duration, () {
      _readingSubscription?.cancel(); //This does not cancel the stream in the provider
      widget.onTimerStatusChanged(false);
      widget.onSaveOrUpdate(widget.containerName); // Still need to figure out if this is correct after modifying the onSaveOrUpdate function
      widget.multimeterService.subscribeToServiceAndReading(idleMode);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _readingSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> dcVoltsButtonStartService() async {
    if (isDialogVisible) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
      isDialogVisible = false;
    }

    widget.controller?.text = '';
    widget.multimeterService.setDevice(BluetoothManager.instance.pokitProModel!.device);
    await widget.multimeterService.initialize();
    await widget.multimeterService.subscribeToServiceAndReading(widget.selectedMode);
    _startSubscriptionAndTimer();
  }

  @override
  Widget build(BuildContext context) {
    // final bluetoothManager = Provider.of<BluetoothManager>(context);

    return Selector<BluetoothManager, String?>(
      selector: (_, manager) => manager.pokitProModel?.statusServiceModel?.statusCharacteristicModel?.switchPosition,
      builder: (context, switchPosition, child) {
        // Reactively close the dialog if the switch position is correct and the dialog is visible
        if (switchPosition == 'Voltage' && isDialogVisible) {
          dcVoltsButtonStartService();
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 43, 92),
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            color: const Color.fromARGB(255, 247, 143, 30),
            icon: const Icon(
              Icons.hourglass_bottom,
            ),
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
                await dcVoltsButtonStartService();
              }
            },
          ),
        );
      },
    );
  }
}
