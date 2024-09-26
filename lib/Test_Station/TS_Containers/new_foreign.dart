import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';
import 'package:provider/provider.dart';

import '../../database_helper.dart';
import '../ts_notifier.dart';

class ForeignContainer extends BaseContainer<ForeignReading> {
  static const String containerName = 'ForeignContainers';

  const ForeignContainer({
    super.key,
    required super.readings,
    super.onReadingUpdated,
    required super.currentTestStation,
    required super.scaffoldMessengerKey,
  });

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