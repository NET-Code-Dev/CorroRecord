import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

class PLTestLeadContainer extends BaseContainer<PLTestLeadReading> {
  static const String containerName = 'PLTestLeadContainers';

  const PLTestLeadContainer({
    super.key,
    required super.readings,
    super.onReadingUpdated,
    required super.currentTestStation,
    required super.scaffoldMessengerKey,
  });

  @override
  createState() => _PLTestLeadContainerState();
}

class _PLTestLeadContainerState extends BaseContainerState<PLTestLeadContainer> {
  // Override the containerName getter
  @override
  String get containerName => PLTestLeadContainer.containerName;
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
    final bottomGraph = buildBottomGraph(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super
        .buildContent(context, labelRow: labelRow, acReadingRow: acRow, onReadingRow: onReading, offReadingRow: offReading, bottomGraph: bottomGraph);
  }
}




/*
import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

class PLTestLeadContainer extends BaseContainer<PLTestLeadReading> {
  static const String containerName = 'PLTestLeadContainers';

  const PLTestLeadContainer({
    Key? key,
    required List<PLTestLeadReading> readings,
    ValueChanged<PLTestLeadReading>? onReadingUpdated,
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
  createState() => _PLTestLeadContainerState();
}

class _PLTestLeadContainerState extends BaseContainerState<PLTestLeadContainer> {
  // Override the containerName getter
  @override
  String get containerName => PLTestLeadContainer.containerName;
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
      {Widget? onReadingRow,
      Widget? offReadingRow,
      Widget? wireColorAndLugNumberRow,
      Widget? bottomGraph,
      Widget? sideAtoSideB,
      Widget? shuntCalculationRows}) {
    final onReading = buildONReadingRow(context);
    final offReading = buildOFFReadingRow(context);
    final bottomGraph = buildBottomGraph(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(context, onReadingRow: onReading, offReadingRow: offReading, bottomGraph: bottomGraph);
  }
}
*/