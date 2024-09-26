import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';
import 'package:provider/provider.dart';

import '../../database_helper.dart';
import '../ts_notifier.dart';

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
    super.key,
    required super.readings,
    super.onReadingUpdated,
    required super.currentTestStation,
    required super.scaffoldMessengerKey,
  });

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
    final pipeDiamter = buildPipeDiameterRow(context);

    return super.buildContent(context,
        labelRow: labelRow,
        acReadingRow: acRow,
        onReadingRow: onReading,
        offReadingRow: offReading,
        bottomGraph: bottomGraph,
        pipeDiameterRow: pipeDiamter);
  }

  @override
  void deleteContainer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete ${containerName.replaceAll('Containers', '')}'),
          content: const Text('Are you sure you want to delete this reading? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                if (kDebugMode) {
                  print('Delete confirmed for $containerName, orderIndex: $orderIndex');
                }
                Navigator.of(context).pop();
                await _deleteContainer();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteContainer() async {
    if (kDebugMode) {
      print('Deleting container: $containerName, orderIndex: $orderIndex');
    }

    final dbHelper = DatabaseHelper.instance;
    final tsNotifier = Provider.of<TSNotifier>(context, listen: false);
    final tableName = containerName;

    // Delete from database
    int deletedRows = await dbHelper.deleteReading(tableName, widget.currentTestStation.id!, orderIndex!);

    if (kDebugMode) {
      print('Rows deleted from database: $deletedRows');
    }

    // Update TSNotifier
    tsNotifier.removeReading(containerName, widget.currentTestStation.id!, orderIndex!);

    // Remove from UI
    if (mounted) {
      setState(() {
        // This will trigger a rebuild of the parent widget
      });
    }

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${containerName.replaceAll('Containers', '')} deleted successfully')),
      );
    }
  }
}




/*
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
*/