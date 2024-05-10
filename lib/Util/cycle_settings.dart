import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:asset_inspections/Common_Widgets/custom_radio.dart';
import 'package:asset_inspections/Util/cycle_settings_notifier.dart';

class InterruptionCycleSelector extends StatefulWidget {
  const InterruptionCycleSelector({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _InterruptionCycleSelectorState createState() => _InterruptionCycleSelectorState();
}

class _InterruptionCycleSelectorState extends State<InterruptionCycleSelector> {
  String? selectedCycle;
  final List<String> cycles = ['1.5 | .5', '2.5 | .5', '3 | 1', '4 | 1']; // Static list of cycles
  // int? _radioSelectedCycle;

  @override
  void initState() {
    super.initState();
    selectedCycle = cycles.first; // Initialize with the first cycle
  }

  /// Builds the cycle settings widget.
  ///
  /// This widget displays the cycle settings UI, allowing the user to select a cycle and set the desired settings.
  /// It uses the [CycleSettingsModel] to manage the selected cycle and radio button values.
  ///
  /// The UI consists of a card with the title "Cycle Settings" and three rows representing different cycle options.
  /// Each row contains a radio button and a description of the cycle option.
  ///
  /// The selected cycle and radio button values are updated using the [cycleSettings] provider.
  @override
  Widget build(BuildContext context) {
    var cycleSettings = Provider.of<CycleSettingsModel>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const Text('Cycle Settings',
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 15.0),
                  Wrap(
                    spacing: 4.0, // Adjust spacing as needed
                    children: cycles.map((cycle) {
                      return SizedBox(
                        width: 70.0,
                        child: ElevatedButton(
                          onPressed: () {
                            cycleSettings.setSelectedCycle(cycle);
                          },
                          style: ElevatedButton.styleFrom(
                            // Use the selectedCycle from CycleSettingsModel
                            backgroundColor: cycleSettings.selectedCycle == cycle
                                ? const Color.fromARGB(255, 247, 143, 30)
                                : const Color.fromARGB(255, 188, 188, 188),
                            elevation: 6.0,
                            shadowColor: Colors.black,
                            padding: const EdgeInsets.all(2.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(180.0),
                            ),
                          ),
                          child: Text(cycle,
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                // color: Color.fromARGB(255, 247, 143, 30),
                                color: Color.fromARGB(255, 0, 43, 92),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 25.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items at the start vertically
                    children: [
                      CustomRadio(
                        value: 1,
                        groupValue: cycleSettings.selectedRadio, // Use provider value here
                        onChanged: (value) {
                          cycleSettings.setSelectedRadio(value);
                        },
                      ),
                      const SizedBox(width: 50.0), // Adjust as needed for spacing
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GPS',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                )),
                            Text('Uses GPS to sync with UTC time, reports values at the beginning of the ON and OFF cycles'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items at the start vertically
                    children: [
                      CustomRadio(
                        value: 2,
                        groupValue: cycleSettings.selectedRadio, // Use provider value here
                        onChanged: (value) {
                          cycleSettings.setSelectedRadio(value);
                        },
                      ),
                      const SizedBox(width: 50.0), // Adjust as needed for spacing
                      const Expanded(
                        // Wrap the text in an Expanded widget
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('High | Low',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                )),
                            Text('Captures the highest and lowest values within the selected cycle, updates once per cycle'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items at the start vertically
                    children: [
                      CustomRadio(
                        value: 3,
                        groupValue: cycleSettings.selectedRadio, // Use provider value here
                        onChanged: (value) {
                          cycleSettings.setSelectedRadio(value);
                        },
                      ),
                      const SizedBox(width: 50.0), // Adjust as needed for spacing
                      const Expanded(
                        // Wrap the text in an Expanded widget
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Shift',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                )),
                            Text(
                                'Evaluates values and determines the shift between cycles, reports captured values at the beginning of the ON and OFF'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

                  //  const SizedBox(height: 15.0),
/*
                  const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                Text('ON: ',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    )),
                                SizedBox(
                                    height: 35,
                                    width: 85.0,
                                    child: TextField(
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              EdgeInsets.fromLTRB(10, 3, 10, 3),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 67, 197, 228),
                                                width: 1.5),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ))),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                Text('OFF: ',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    )),
                                SizedBox(
                                    height: 35,
                                    width: 85.0,
                                    child: TextField(
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding:
                                              EdgeInsets.fromLTRB(10, 3, 10, 3),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Color.fromARGB(
                                                    255, 67, 197, 228),
                                                width: 1.5),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ))),
                              ],
                            ),
                          ],
                        ),
                      ]),
*/
