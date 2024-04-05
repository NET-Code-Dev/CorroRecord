import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

class ForeignContainer extends BaseContainer<ForeignReading> {
  static const String containerName = 'ForeignContainers';

  const ForeignContainer({
    Key? key,
    required List<ForeignReading> readings,
    ValueChanged<ForeignReading>? onReadingUpdated,
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
  createState() => _ForeignContainerState();
}

class _ForeignContainerState extends BaseContainerState<ForeignContainer> {
  // Override the containerName getter
  @override
  String get containerName => ForeignContainer.containerName;
/*
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Additional disposals for PLTestLeadContainer
    super.dispose();
  }
*/
  @override
  Widget buildContent(BuildContext context,
      {Widget? onReadingRow, Widget? offReadingRow, Widget? bottomGraph, Widget? sideAtoSideB, Widget? shuntCalculationRows}) {
    final onReading = buildONReadingRow(context);
    final offReading = buildOFFReadingRow(context);
    final bottomGraph = buildBottomGraph(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(context, onReadingRow: onReading, offReadingRow: offReading, bottomGraph: bottomGraph);
  }
}
