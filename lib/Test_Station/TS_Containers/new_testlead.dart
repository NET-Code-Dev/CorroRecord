import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';
import 'package:flutter/material.dart';

/// A container widget for managing test lead readings.
///
/// This widget extends the [BaseContainer] class and provides functionality
/// for displaying and updating test lead readings. It requires a list of
/// [TestLeadReading] objects, a callback function for when a reading is updated,
/// the current test station, and a [GlobalKey] to access the [ScaffoldMessengerState].
class TestLeadContainer extends BaseContainer<TestLeadReading> {
  static const String containerName = 'TestLeadContainers';

  const TestLeadContainer({
    Key? key,
    required List<TestLeadReading> readings,
    ValueChanged<TestLeadReading>? onReadingUpdated,
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
  createState() => _TestLeadContainerState();
}

/// This class represents the state of the TestLeadContainer widget.
/// It extends the BaseContainerState class.
class _TestLeadContainerState extends BaseContainerState<TestLeadContainer> {
  // Override the containerName getter
  @override
  String get containerName => TestLeadContainer.containerName;

  /// Builds the content of the test lead widget.
  ///
  /// This method is responsible for constructing the content of the Test Lead widget.
  /// It takes optional parameters for customizing the appearance of the widget.
  ///
  /// - The [context] parameter is the build context.
  /// - The [onReadingRow] parameter is an optional widget for the on-reading row.
  /// - The [offReadingRow] parameter is an optional widget for the off-reading row.
  /// - The [bottomGraph] parameter is an optional widget for the bottom graph.
  ///
  /// It internally calls the [buildONReadingRow], [buildOFFReadingRow], and [buildBottomGraph] methods
  /// to construct the individual components of the widget.
  /// Finally, it invokes the [super.buildContent] method from the parent class,
  /// passing the constructed components as parameters.
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
