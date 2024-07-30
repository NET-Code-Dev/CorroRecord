import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

class AnodeContainer extends BaseContainer<AnodeReading> {
  static const String containerName = 'AnodeContainers';

  const AnodeContainer({
    super.key,
    required super.readings,
    super.onReadingUpdated,
    required super.currentTestStation,
    required super.scaffoldMessengerKey,
  });

  @override
  createState() => _AnodeContainerState();
}

class _AnodeContainerState extends BaseContainerState<AnodeContainer> {
  // Override the containerName getter
  @override
  String get containerName => AnodeContainer.containerName;
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
  Widget buildContent(
    BuildContext context, {
    Widget? labelRow,
    Widget? acReadingRow,
    Widget? onReadingRow,
    Widget? offReadingRow,
    Widget? wireColorAndLugNumberRow,
    Widget? bottomGraph,
    Widget? sideAtoSideB,
    Widget? shuntCalculationRows,
    Widget? currentReadingRow,
    Widget? pipeDiameterRow,
    Widget? passFailRow,
  }) {
    final labelRow = buildLabelRow(context);
    final acRow = buildACReadingRow(context);
    final onReading = buildONReadingRow(context);
    final offReading = buildOFFReadingRow(context);
    final currentReading = buildCurrentReadingRow(context);
    //  final wireColorAndLugNumber = buildWireColorAndLugNumberRow(context);
    final bottomGraph = buildBottomGraph(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(context,
        labelRow: labelRow,
        acReadingRow: acRow,
        onReadingRow: onReading,
        offReadingRow: offReading,
        currentReadingRow: currentReading,
        /* wireColorAndLugNumberRow: wireColorAndLugNumber,*/ bottomGraph: bottomGraph);
  }
}



/*
import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

class AnodeContainer extends BaseContainer<AnodeReading> {
  static const String containerName = 'AnodeContainers';

  const AnodeContainer({
    Key? key,
    required List<AnodeReading> readings,
    ValueChanged<AnodeReading>? onReadingUpdated,
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
  createState() => _AnodeContainerState();
}

class _AnodeContainerState extends BaseContainerState<AnodeContainer> {
  // Override the containerName getter
  @override
  String get containerName => AnodeContainer.containerName;
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
    final onReading = buildONReadingRow(context);
    final offReading = buildOFFReadingRow(context);
    //  final wireColorAndLugNumber = buildWireColorAndLugNumberRow(context);
    final bottomGraph = buildBottomGraph(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(context,
        onReadingRow: onReading, offReadingRow: offReading, /* wireColorAndLugNumberRow: wireColorAndLugNumber,*/ bottomGraph: bottomGraph);
  }
}
*/