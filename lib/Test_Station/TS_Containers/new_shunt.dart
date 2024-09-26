import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';
import 'package:provider/provider.dart';

import '../../database_helper.dart';
import '../ts_notifier.dart';

/// A container widget for managing shunt readings.
///
/// This widget extends the [BaseContainer] class and provides functionality
/// for displaying and updating shunt readings. It requires a list of [ShuntReading]
/// objects, a callback function for when a reading is updated, the current test station,
/// and a [GlobalKey] to access the [ScaffoldMessengerState].
class ShuntContainer extends BaseContainer<ShuntReading> {
  static const String containerName = 'ShuntContainers';

  const ShuntContainer({
    super.key,
    required super.readings,
    super.onReadingUpdated,
    required super.currentTestStation,
    required super.scaffoldMessengerKey,
  });

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
    final sidesDropdown = buildSideAtoSideBDropdowns(context);
    final shuntCalculation = buildShuntCalculationRows(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(context, labelRow: labelRow, acReadingRow: acRow, sideAtoSideB: sidesDropdown, shuntCalculationRows: shuntCalculation);
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
    final sidesDropdown = buildSideAtoSideBDropdowns(context);
    final shuntCalculation = buildShuntCalculationRows(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(context, labelRow: labelRow, acReadingRow: acRow, sideAtoSideB: sidesDropdown, shuntCalculationRows: shuntCalculation);
  }
}

*/





/*
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
      {Widget? onReadingRow,
      Widget? offReadingRow,
      Widget? wireColorAndLugNumberRow,
      Widget? bottomGraph,
      Widget? sideAtoSideB,
      Widget? shuntCalculationRows}) {
    final sidesDropdown = buildSideAtoSideBDropdowns(context);
    final shuntCalculation = buildShuntCalculationRows(context);

    // Call super.buildContent and pass onReading and offReading as parameters
    return super.buildContent(context, sideAtoSideB: sidesDropdown, shuntCalculationRows: shuntCalculation);
  }
}
*/