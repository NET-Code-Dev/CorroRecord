// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, no_leading_underscores_for_local_identifiers
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import 'package:asset_inspections/Models/project_model.dart';
import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Test_Station/ts_notifier.dart';
import 'package:asset_inspections/Common_Widgets/gps_location.dart';

import '../GPS/gps_status_bar.dart';
import 'ts_details.dart';
import '../Common_Widgets/mapview.dart';

class TestStationsPage extends StatefulWidget {
  // Stateful widget to hold the test stations page
  const TestStationsPage({super.key}); // Ensure key is passed properly to super

  @override
  createState() => _TestStationsPageState();
}

class _TestStationsPageState extends State<TestStationsPage> {
  Future<void> importCsv(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String filePath = result.files.single.path!;
      // ignore: use_build_context_synchronously
      int projectID = Provider.of<ProjectModel>(context, listen: false).id;
      // ignore: use_build_context_synchronously
      TSNotifier tsNotifier = Provider.of<TSNotifier>(context, listen: false);
      List<TestStation> testStations = await parseCsvFromPath(filePath, projectID, context);
      await tsNotifier.addTestStations(testStations, projectID);
    } else {
      // User canceled the picker
    }
  }

  /// Parses a CSV file from the given [filePath] and returns a list of [TestStation] objects.
  ///
  /// The [filePath] parameter specifies the path to the CSV file.
  /// The [projectID] parameter is used to set the project ID for each [TestStation].
  ///
  /// Returns a [Future] that completes with a list of [TestStation] objects.
  /// Each [TestStation] object is created from a row in the CSV file, with the following properties:
  /// - [projectID]: The provided project ID.
  /// - [area]: The value at index 0 in the CSV row.
  /// - [tsID]: The value at index 1 in the CSV row.
  /// - [tsstatus]: The value at index 2 in the CSV row. If empty, it defaults to 'Unchecked'.
  /// - [latitude]: The value at index 3 in the CSV row.
  /// - [longitude]: The value at index 4 in the CSV row.
  ///
  /// Example usage:
  /// ```dart
  /// String filePath = '/path/to/csv/file.csv';
  /// int projectID = 123;
  /// List<TestStation> testStations = await parseCsvFromPath(filePath, projectID);
  /// ```
  Future<List<TestStation>> parseCsvFromPath(String filePath, int projectID, BuildContext context) async {
    final csvFile = File(filePath).openRead();
    List<List<dynamic>> rowsAsListOfValues = await csvFile.transform(utf8.decoder).transform(CsvToListConverter()).toList();

    List<TestStation> testStations = [];
    List<int> invalidRows = [];
    //   RegExp validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    RegExp validPattern = RegExp(r'^[a-zA-Z0-9_\- ]+$');

    for (var i = 1; i < rowsAsListOfValues.length; i++) {
      var row = rowsAsListOfValues[i];
      String area = row[0].toString().trim();
      String tsID = row[1].toString().trim();

      if (!validPattern.hasMatch(area) || !validPattern.hasMatch(tsID)) {
        if (kDebugMode) {
          print("Invalid input detected in row $i: Area or TS ID contains invalid characters.");
        }
      }
    }

    if (invalidRows.isNotEmpty) {
      // Inform the user about the invalid rows and do not proceed with the import
      String errorMessage =
          "Import aborted!\n\nInvalid characters found in rows: ${invalidRows.join(', ')}. \nOnly alphanumeric characters, spaces, underscores and dashes are allowed in columns 1 and 2.\n\nPlease correct the CSV file and try again.";
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Import Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return []; // Return an empty list as nothing should be imported
    } else {
      // If all rows are valid, proceed to import the data
      for (var row in rowsAsListOfValues.skip(1)) {
        // Skip header if present
        String tsstatus = row[2].toString().isEmpty ? 'Unchecked' : row[2];
        TestStation testStation = TestStation(
          projectID: projectID,
          area: row[0],
          tsID: row[1],
          tsstatus: tsstatus,
          latitude: row[3],
          longitude: row[4],
          fieldNotes: row[5],
          officeNotes: row[6],
        );
        testStations.add(testStation);
      }
      return testStations;
    }
  }

  /// Shows an error dialog with the given [message].
  ///
  /// This method displays an [AlertDialog] with the title "Error" and the provided [message].
  /// The dialog contains an "OK" button that dismisses the dialog when pressed.
  void _showErrorDialog(BuildContext context, String message) {
    // Show error dialog
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        // Show the alert dialog
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to notify the user about missing location data for test stations.
  ///
  /// This method displays an [AlertDialog] with a title and content that lists the test stations
  /// missing coordinates. The user is presented with two options: "Sort Anyway" and "Cancel".
  /// If the user chooses "Sort Anyway", the [tsNotifier] is used to sort the test stations by location
  /// using the [LocationService], and the dialog is dismissed. If the user chooses "Cancel", the dialog
  /// is simply dismissed.
  ///
  /// Parameters:
  /// - [context]: The [BuildContext] used to show the dialog.
  /// - [stations]: A list of [TestStation] objects representing the test stations with missing coordinates.
  /// - [tsNotifier]: An instance of [TSNotifier] used to sort the test stations by location.
  void _notifyMissingLocations(BuildContext context, List<TestStation> stations, TSNotifier tsNotifier) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Missing Location Data',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Test Stations missing coordinates:\n${stations.map((e) => '${e.area}-${e.tsID}').join('\n')}',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Sort Anyway'),
              onPressed: () {
                LocationService locationService = LocationService();
                tsNotifier.sortTestStationsByLocation(context, tsNotifier);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a bottom sheet dialog with sort options for test stations.
  ///
  /// The [context] parameter is the build context.
  /// The [tsNotifier] parameter is the notifier for test stations.
  void _showSortOptionsDialog(BuildContext context, TSNotifier tsNotifier) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext modalContext) {
        return Container(
          padding: EdgeInsets.all(8.0),
          child: Wrap(
            children: <Widget>[
              ListTile(
                title: const Text("By Area A-Z"),
                onTap: () {
                  tsNotifier.sortTestStationsAlphabeticallyAZ(context, tsNotifier, SortOption.area);
                  // Navigator.of(context).pop(); // Close the bottom sheet
                },
              ),
              ListTile(
                title: const Text("By Test Station ID A-Z"),
                onTap: () {
                  tsNotifier.sortTestStationsAlphabeticallyAZ(context, tsNotifier, SortOption.tsID);
                  //   Navigator.of(context).pop(); // Close the bottom sheet
                },
              ),
              ListTile(
                title: const Text("By Status"),
                onTap: () {
                  tsNotifier.sortTestStationsByStatus(context, tsNotifier);
                  //   Navigator.of(context).pop(); // Close the bottom sheet
                },
              ),
              ListTile(
                title: const Text("By Location - Nearest to Farthest"),
                onTap: () {
                  var missingLocationStations =
                      tsNotifier.testStations.where((station) => station.latitude == 0.0 || station.longitude == 0.0).toList();

                  if (missingLocationStations.isNotEmpty) {
                    _notifyMissingLocations(context, missingLocationStations, tsNotifier);
                  } else {
                    // If no missing locations, proceed to sort
                    tsNotifier.sortTestStationsByLocation(context, tsNotifier);
                    //  LocationService locationService = LocationService();
                    //  tsNotifier.sortTestStationsByLocation(context, tsNotifier, locationService);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _validateInput(String input) {
    return RegExp(r'^[a-zA-Z0-9_-]*$').hasMatch(input);
  }

  /// This method builds the widget for the test station page.
  /// It displays a scaffold with a bottom navigation bar that contains buttons for filtering, adding, and viewing the test stations.
  /// The build method retrieves the test stations from the TSNotifier provider and initializes the necessary controllers for the text fields.
  /// It also defines a function to show an edit dialog for a selected test station.
  /// The scaffold's bottom navigation bar contains an IconButton for filtering the test stations and an IconButton for adding a new test station.
  /// The IconButton for filtering opens a dialog to select sorting options.
  /// The IconButton for adding opens a dialog to enter the details of a new test station.
  /// The IconButton for viewing the test stations on a map is only enabled if there are test stations available.
  @override
  Widget build(BuildContext context) {
    // Build method
//    final testStations = Provider.of<TSNotifier>(context) // Retrieve the test stations from the provider
//        .testStations;
    final tsNotifier = Provider.of<TSNotifier>(context);

    void showEditDialog(BuildContext context, int index) {
      // Show edit dialog
      final TestStation existingTestStation = tsNotifier.testStations[index];

      final TextEditingController areaController = TextEditingController(text: existingTestStation.area);

      final TextEditingController tsIDController = TextEditingController(text: existingTestStation.tsID);

      final TextEditingController latitudeController = TextEditingController(text: existingTestStation.latitude.toString());

      final TextEditingController longitudeController = TextEditingController(text: existingTestStation.longitude.toString());

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          // Show the alert dialog to edit the test station
          title: Text('Edit Test Station Details'),
          content: SingleChildScrollView(
            child: Column(
              // Column to hold the text fields
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: areaController, decoration: InputDecoration(labelText: 'Pipeline/Service/Area')),
                TextField(controller: tsIDController, decoration: InputDecoration(labelText: 'Test Station ID')),
                TextField(controller: latitudeController, decoration: InputDecoration(labelText: 'Latitude')),
                TextField(controller: longitudeController, decoration: InputDecoration(labelText: 'Longitude')),
              ],
            ),
          ),
          actions: [
            TextButton(
                // Text button to cancel the edit
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                // On press to update the test station
                String area = areaController.text;
                String tsID = tsIDController.text;
                double? latitude = double.tryParse(latitudeController.text);
                double? longitude = double.tryParse(longitudeController.text);

                context.read<TSNotifier>().updateTestStation(
                      // Update the test station
                      existingTestStation,
                      area,
                      tsID,
                      existingTestStation.tsstatus,
                      existingTestStation.fieldNotes,
                      existingTestStation.plTestLeadReadings,
                      existingTestStation.permRefReadings,
                      existingTestStation.anodeReadings,
                      existingTestStation.shuntReadings,
                      existingTestStation.riserReadings,
                      existingTestStation.foreignReadings,
                      existingTestStation.testLeadReadings,
                      existingTestStation.couponReadings,
                      existingTestStation.bondReadings,
                      existingTestStation.isolationReadings,
                      latitude: latitude,
                      longitude: longitude,
                      context: context,
                    );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      // Scaffold to hold the appbar, body and bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        // Bottom app bar to hold the add test station button
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 43, 92),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  color: const Color.fromARGB(255, 247, 143, 30),
                  icon: const Icon(Icons.filter_alt),
                  onPressed: () {
                    TSNotifier tsNotifier = Provider.of<TSNotifier>(context, listen: false);
                    _showSortOptionsDialog(context, tsNotifier);
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 43, 92), // Same color as the map button
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  color: const Color.fromARGB(255, 247, 143, 30),
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // On press to show the dialog to add a test station
                    final TextEditingController areaController = TextEditingController();
                    final TextEditingController tsIDController = TextEditingController();
                    final TextEditingController latitudeController = TextEditingController();
                    final TextEditingController longitudeController = TextEditingController();

                    showDialog<void>(
                      // Show the dialog to add a test station
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Enter Details'),
                        content: SingleChildScrollView(
                          child: Column(
                            // Column to hold the text fields
                            children: [
                              TextField(
                                controller: areaController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  labelText: 'Pipeline/Service/Area',
                                  errorText: _validateInput(areaController.text) ? null : "Invalid input. Only alphanumeric, _, and - are allowed.",
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9_-]*$')),
                                ],
                                onChanged: (value) {
                                  // Trigger a UI rebuild on change to update the errorText based on the latest input
                                  setState(() {});
                                },
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: tsIDController,
                                decoration: InputDecoration(
                                  labelText: 'Test Station ID',
                                  errorText: _validateInput(tsIDController.text) ? null : "Invalid input. Only alphanumeric, _, and - are allowed.",
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9_-]+$')),
                                ],
                                onChanged: (value) {
                                  // Trigger a UI rebuild on change to update the errorText based on the latest input
                                  setState(() {});
                                },
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: latitudeController,
                                decoration: InputDecoration(labelText: 'Latitude'),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: longitudeController,
                                decoration: InputDecoration(labelText: 'Longitude'),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                child: Text('Import CSV'),
                                onPressed: () {
                                  importCsv(context);
                                  // Future.delayed(Duration duration());
                                  // Navigator.of(context).pop();
                                },
                              ),
                              //  TextButton(
                              SizedBox(
                                width: 50.w,
                                height: 50.h,
                                child: FloatingActionButton(
                                  // Text button to cancel the add test station
                                  //  child: Text('Cancel'),
                                  backgroundColor: const Color.fromARGB(255, 0, 43, 92),
                                  child: Icon(Icons.block, color: Colors.red),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              //  TextButton(
                              SizedBox(
                                width: 50.w,
                                height: 50.h,
                                child: FloatingActionButton(
                                  // Text button to add the test station
                                  // child: Text('Add'),
                                  backgroundColor: const Color.fromARGB(255, 0, 43, 92),
                                  onPressed: () {
                                    if (areaController.text.isEmpty || tsIDController.text.isEmpty) {
                                      _showErrorDialog(context, 'Pipeline/Service/Area and Test Station ID are required!');
                                      return;
                                    }
                                    final enteredArea = areaController.text;
                                    final enteredtsID = tsIDController.text;
                                    const enteredtsStatus = 'Unknown';
                                    final enteredLatitude = double.tryParse(latitudeController.text) ?? 00.000000;
                                    final enteredLongitude = double.tryParse(longitudeController.text) ?? 00.000000;

                                    final projectID = Provider.of<ProjectModel>(context, listen: false).id;

                                    context.read<TSNotifier>().addTestStation(
                                          // Add the test station
                                          enteredArea,
                                          enteredtsID,
                                          enteredtsStatus,
                                          enteredLatitude,
                                          enteredLongitude,
                                          projectID,
                                        );
                                    Navigator.of(context).pop();
                                  },
                                  // Text button to add the test station
                                  // child: Text('Add'),
                                  child: Icon(Icons.check, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 43, 92),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  color: const Color.fromARGB(255, 247, 143, 30),
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    final tsNotifier = Provider.of<TSNotifier>(context, listen: false);
                    final projectID = Provider.of<ProjectModel>(context, listen: false).id;
                    final testStations = tsNotifier.testStations;

                    if (tsNotifier.testStations.isNotEmpty) {
                      MapView.navigateToMapView(
                        context,
                        projectID,
                        testStations: testStations,
                      );
/*
                    if (tsNotifier.testStations.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MapView(testStations: tsNotifier.testStations),
                        ),
                      );
*/
                    } else {
                      _showErrorDialog(context, 'No test stations to show');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Color(0xFFE0E8F0),

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.0), // Set height of the AppBar
        child: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Color.fromARGB(255, 0, 43, 92),
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('Test Stations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              )),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                // Icon to share the CSV
                IconData(0xf016a, fontFamily: 'MaterialIcons'),
                size: 24,
                color: Colors.white,
              ),
              onPressed: () {
                Provider.of<TSNotifier>(context, listen: false).createCSV(
                  context,
                );
              },
              tooltip: 'Share', // Tooltip will be shown on long press
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const GPSStatusBar(),
          //    const InternalGPSStatusBar(),
          //  ),
          Expanded(
            child: Consumer<TSNotifier>(
              builder: (context, tsNotifier, child) {
                if (!tsNotifier.isGpsConnected) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('GPS Not Connected'),
                        ElevatedButton(
                          onPressed: () => tsNotifier.initializeGps(),
                          child: const Text('Connect GPS'),
                        ),
                      ],
                    ),
                  );
                }

                // Get current GPS coordinates from last known good location
                final currentGpsData = tsNotifier.currentGpsLocation;
                final currentLat = currentGpsData?['latitude'] as double?;
                final currentLon = currentGpsData?['longitude'] as double?;

                return ListView.builder(
                    padding: EdgeInsets.all(10.w),
                    itemCount: tsNotifier.testStations.length,
                    itemBuilder: (context, index) {
                      TestStation testStation = tsNotifier.testStations[index];

                      final stationLat = testStation.latitude ?? 0.0;
                      final stationLon = testStation.longitude ?? 0.0;

                      bool isValidLocation = currentLat != null && currentLon != null && stationLat != 0.0 && stationLon != 0.0;

                      double distanceInMeters = isValidLocation
                          ? tsNotifier.calculateDistance(
                              currentLat!,
                              currentLon!,
                              stationLat,
                              stationLon,
                            )
                          : 0.0;

                      String direction = isValidLocation
                          ? tsNotifier.calculateBearing(
                              currentLat!,
                              currentLon!,
                              stationLat,
                              stationLon,
                            )
                          : 'Unknown';

                      String distanceDisplay = isValidLocation ? '${distanceInMeters.toStringAsFixed(2)} m' : 'Unknown';

                      return GestureDetector(
                          onTap: () {
                            tsNotifier.currentTestStation = testStation;
                            Navigator.push(
                                // Navigate to the details page
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestStationDetailsPage(
                                    testStation: testStation,
                                    ontsStatusChanged: (
                                      id,
                                      projectID,
                                      area,
                                      tsstatus,
                                      fieldNotes,
                                      officeNotes,
                                      plTestLeadReading,
                                      permRefReading,
                                      anodeReading,
                                      shuntReading,
                                      riserReading,
                                      foreignReading,
                                      testLeadReading,
                                      couponReading,
                                      bondReading,
                                      isolationReading,
                                    ) {
                                      Provider.of<TSNotifier>(context, listen: false).updateTestStationStatus(
                                        testStation,
                                        tsstatus,
                                        context,
                                      );
                                    },
                                  ),
                                ));
                          },
                          onLongPress: () {
                            // Long press to show options
                            showDialog(
                              // Show the dialog
                              context: context,
                              builder: (context) => SimpleDialog(
                                title: Center(
                                  child: Text(
                                    'Options for ${testStation.tsID}',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 43, 92),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24.sp,
                                    ),
                                  ),
                                ),
                                children: <Widget>[
                                  Divider(
                                    color: Colors.grey,
                                    thickness: 1,
                                  ),
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        SimpleDialogOption(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                            showEditDialog(context, index); // Trigger the edit dialog
                                          },
                                          child: Center(
                                            child: const Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: Color.fromARGB(255, 0, 43, 92),
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          color: Colors.grey,
                                          thickness: 1,
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () {
                                            int tsIDToDelete = tsNotifier.testStations[index].id!; // Retrieve the serviceTag
                                            Provider.of<TSNotifier>(context, listen: false).deleteTestStation(tsIDToDelete, context);
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                          child: Center(
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          color: Colors.grey,
                                          thickness: 1,
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog
                                          },
                                          child: Center(
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Color.fromARGB(255, 0, 43, 92),
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.grey,
                                    thickness: 1,
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Text(
                                          ' ${tsNotifier.testStations[index].area} - ${tsNotifier.testStations[index].tsID}',
                                          style: TextStyle(
                                            color: Color.fromARGB(255, 0, 43, 92),
                                            fontSize: 24.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 5), // Adjust height as needed
                                      Text(
                                        isValidLocation ? '$direction $distanceDisplay' : 'Location Unknown',
                                        style: TextStyle(
                                          color: Color.fromARGB(255, 0, 43, 92),
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    right: 0,
                                    child: Consumer<TSNotifier>(
                                      builder: (context, tsNotifier, child) {
                                        return Container(
                                          width: 10, // Adjust width as needed
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5.0),
                                            color: testStation.gettsStatusColor(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ));
                    });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/*
  String _generateKMLData(List<TestStation> testStations) {
    String kmlData = '';
    kmlData += '<?xml version="1.0" encoding="UTF-8"?>';
    kmlData +=
        '<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">';
    kmlData += '<Document>';
    kmlData += '<name>Test Stations</name>';
    kmlData += '<Style id="tsStyle">';
    kmlData += '<IconStyle>';
    kmlData += '<Icon>';
    kmlData +=
        '<href>https://raw.githubusercontent.com/Asset-Inspections/asset-inspections/main/assets/images/TSIcon.png</href>';
    kmlData += '</Icon>';
    kmlData += '</IconStyle>';
    kmlData += '</Style>';
    for (int i = 0; i < testStations.length; i++) {
      kmlData += '<Placemark>';
      kmlData += '<name>${testStations[i].tsID}</name>';
      kmlData += '<styleUrl>#tsStyle</styleUrl>';
      kmlData += '<Point>';
      kmlData += '<coordinates>';
      kmlData += '${testStations[i].longitude},${testStations[i].latitude}';
      kmlData += '</coordinates>';
      kmlData += '</Point>';
      kmlData += '</Placemark>';
    }
    kmlData += '</Document>';
    kmlData += '</kml>';
    return kmlData;
  }

  Future<File> _saveKMLToFile(String kmlData) async {
    // Check and request storage permission
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    // Get the Downloads directory path
    // For iOS, you can use `getApplicationDocumentsDirectory` as iOS doesn't have a Downloads folder
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      String newPath = "";
      List<String> folders = directory!.path.split("/");
      for (int x = 1; x < folders.length; x++) {
        String folder = folders[x];
        if (folder != "Android") {
          newPath += "/$folder";
        } else {
          break;
        }
      }
      newPath = "$newPath/Download";
      directory = Directory(newPath);
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    // Create and write the file
    final filePath = '${directory.path}/test_stations.kml';
    final file = File(filePath);
    return file.writeAsString(kmlData);
  }

  void _showGEErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleEarth(
      BuildContext context, List<TestStation> testStations) async {
    String kmlData = _generateKMLData(testStations);

    // Save the KML data to a file
    File kmlFile = await _saveKMLToFile(kmlData); // Corrected this line

    // Now use the file path to create a content URI
    final contentUri = Uri.parse(
        'content://com.acuren523.asset_inspections.fileprovider/${kmlFile.path}');
    const mimeType = 'application/vnd.google-earth.kml+xml';

    // Check if the URI can be launched and then launch it
    if (await canLaunchUrl(contentUri)) {
      await launchUrl(
        contentUri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: WebViewConfiguration(
          headers: <String, String>{'Content-Type': mimeType},
        ),
      );
    } else {
      _showGEErrorDialog(context, 'Could not launch Google Earth');
    }
  }

  void _showGoogleEarthMap(
      BuildContext context, List<TestStation> testStations) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text('Test Stations Map'),
        ),
        body: MapView(testStations: testStations),
      ),
    ));
  }
*/