import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';

/// A container widget for managing riser readings.
///
/// This widget extends the [BaseContainer] class and provides functionality
/// for displaying and updating a list of [RiserReading] objects.
/// It requires a list of [RiserReading] objects, a callback function for
/// updating readings, the current test station, and a [GlobalKey] for
/// accessing the [ScaffoldMessengerState].
class RiserContainer extends BaseContainer<RiserReading> {
  static const String containerName = 'RiserContainers';

  const RiserContainer({
    Key? key,
    required List<RiserReading> readings,
    ValueChanged<RiserReading>? onReadingUpdated,
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
  createState() => _RiserContainerState();
}

class _RiserContainerState extends BaseContainerState<RiserContainer> {
  @override
  String get containerName => RiserContainer.containerName;

  /// Builds the content for the new riser widget.
  ///
  /// This method is responsible for constructing the content of the new riser widget.
  /// It takes several optional parameters for customizing the appearance of the widget.
  ///
  /// - The [context] parameter is the build context.
  /// - The [onReadingRow] parameter is an optional widget for the on-reading row.
  /// - The [offReadingRow] parameter is an optional widget for the off-reading row.
  /// - The [bottomGraph] parameter is an optional widget for the bottom graph.
  ///
  /// The method first builds the [onReadingRow], [offReadingRow], and bottomGraph widgets using
  /// their respective build methods. Then, it calls the super class's buildContent method
  /// and passes the onReading and offReading widgets as parameters.
  ///
  /// Returns the constructed content widget.
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

    return super.buildContent(context, onReadingRow: onReading, offReadingRow: offReading, bottomGraph: bottomGraph);
  }
}
