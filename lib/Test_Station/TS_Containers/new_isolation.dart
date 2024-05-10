import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

class IsolationContainer extends BaseContainer<IsolationReading> {
  static const String containerName = 'IsolationContainers';

  const IsolationContainer({
    Key? key,
    required List<IsolationReading> readings,
    ValueChanged<IsolationReading>? onReadingUpdated,
    required TestStation currentTestStation,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) : super(
          key: key,
          readings: readings,
          onReadingUpdated: onReadingUpdated,
          currentTestStation: currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );

  @override
  createState() => _IsolationContainerState();
}

class _IsolationContainerState extends BaseContainerState<IsolationContainer> {
  // Override the containerName getter
  @override
  String get containerName => IsolationContainer.containerName;
/*
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
*/
  @override
  Widget buildContent(BuildContext context,
      {Widget? onReadingRow,
      Widget? offReadingRow,
      Widget? wireColorAndLugNumberRow,
      Widget? bottomGraph,
      Widget? sideAtoSideB,
      Widget? shuntCalculationRows}) {
    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(
      context,
    );
  }
}
