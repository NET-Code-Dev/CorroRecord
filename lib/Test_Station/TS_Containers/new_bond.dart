import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

class BondContainer extends BaseContainer<BondReading> {
  static const String containerName = 'BondContainers';

  const BondContainer({
    Key? key,
    required List<BondReading> readings,
    ValueChanged<BondReading>? onReadingUpdated,
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
  createState() => _BondContainerState();
}

class _BondContainerState extends BaseContainerState<BondContainer> {
  // Override the containerName getter
  @override
  String get containerName => BondContainer.containerName;
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
      {Widget? onReadingRow, Widget? offReadingRow, Widget? bottomGraph, Widget? sideAtoSideB, Widget? shuntCalculationRows}) {
    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(
      context,
    );
  }
}
