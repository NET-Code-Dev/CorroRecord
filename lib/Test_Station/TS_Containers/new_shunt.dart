import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

/// A container widget for managing shunt readings.
///
/// This widget extends the [BaseContainer] class and provides functionality
/// for displaying and updating shunt readings. It requires a list of [ShuntReading]
/// objects, a callback function for when a reading is updated, the current test station,
/// and a [GlobalKey] to access the [ScaffoldMessengerState].
class ShuntContainer extends BaseContainer<ShuntReading> {
  static const String containerName = 'ShuntContainers';

  const ShuntContainer({
    Key? key,
    required List<ShuntReading> readings,
    ValueChanged<ShuntReading>? onReadingUpdated,
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
  createState() => _ShuntContainerState();
}

/// This class represents the state of the ShuntContainer widget.
/// It extends the BaseContainerState class.
class _ShuntContainerState extends BaseContainerState<ShuntContainer> {
  @override
  String get containerName => ShuntContainer.containerName;

  /// Builds the content of the widget.
  ///
  /// This method is responsible for building the main content of the Shunt Container widget,
  /// including the dropdowns for side A and side B, the shunt calculation rows,
  /// and any additional widgets provided as parameters.
  ///
  /// - The [context] parameter is the build context.
  /// - The [sideAtoSideB] parameter is an optional widget for the side A to side B dropdowns.
  /// - The [shuntCalculationRows] parameter is an optional widget for the shunt calculation rows.
  @override
  Widget buildContent(BuildContext context,
      {Widget? onReadingRow, Widget? offReadingRow, Widget? bottomGraph, Widget? sideAtoSideB, Widget? shuntCalculationRows}) {
    final sidesDropdown = buildSideAtoSideBDropdowns(context);
    final shuntCalculation = buildShuntCalculationRows(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(context, sideAtoSideB: sidesDropdown, shuntCalculationRows: shuntCalculation);
  }
}
