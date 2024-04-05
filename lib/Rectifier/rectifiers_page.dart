// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_key_in_widget_constructors, prefer_const_constructors_in_immutables, unnecessary_brace_in_string_interps, avoid_print, prefer_const_declarations, sized_box_for_whitespace, no_leading_underscores_for_local_identifiers
//import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'dart:convert';
import 'dart:io';

import 'package:asset_inspections/Common_Widgets/gps_location.dart';
import 'package:asset_inspections/Common_Widgets/mapview.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:asset_inspections/Models/project_model.dart';
import 'package:asset_inspections/Models/rectifier_models.dart';

import 'rec_changeNotifier.dart'; // Import the RectifierNotifier
import 'rectifier_details.dart'; // Import the RectifiersPage

class RectifiersPage extends StatelessWidget {
  Future<void> importCsv(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String filePath = result.files.single.path!;
      // ignore: use_build_context_synchronously
      int projectID = Provider.of<ProjectModel>(context, listen: false).id;
      // ignore: use_build_context_synchronously
      RectifierNotifier rectifierNotifier = Provider.of<RectifierNotifier>(context, listen: false);
      List<Rectifier> rectifiers = await parseCsvFromPath(filePath, projectID);
      await rectifierNotifier.addRectifiers(rectifiers, projectID);
    } else {}
  }

  Future<List<Rectifier>> parseCsvFromPath(String filePath, int projectID) async {
    final csvFile = File(filePath).openRead();
    List<List<dynamic>> rowsAsListOfValues = await csvFile.transform(utf8.decoder).transform(CsvToListConverter()).toList();

    List<Rectifier> rectifiers = [];
    for (var i = 1; i < rowsAsListOfValues.length; i++) {
      var row = rowsAsListOfValues[i];
      String status = row[2].toString().isEmpty ? 'Unchecked' : row[2];
      Rectifier rectifier = Rectifier(
        projectID: projectID,
        area: row[0],
        serviceTag: row[1],
        status: status,
        use: row[3],
        maxVoltage: double.tryParse(row[4].toString()) ?? 0.0, // Corrected line
        maxAmps: double.tryParse(row[5].toString()) ?? 0.0, // Corrected line
        latitude: double.tryParse(row[6].toString()) ?? 0.0, // Added conversion for consistency
        longitude: double.tryParse(row[7].toString()) ?? 0.0, // Added conversion for consistency
      );
      rectifiers.add(rectifier);
    }

    return rectifiers;
  }

  void _notifyMissingLocations(BuildContext context, List<Rectifier> rectifiers, RectifierNotifier rectifierNotifier) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Missing Location Data',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Test Stations missing coordinates:\n${rectifiers.map((e) => '${e.area}-${e.serviceTag}').join('\n')}',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Sort Anyway'),
              onPressed: () {
                LocationService locationService = LocationService();
                rectifierNotifier.sortRectifiersByLocation(context, rectifierNotifier, locationService);
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

  void _showSortOptionsDialog(BuildContext context, RectifierNotifier rectifierNotifier) {
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
                  rectifierNotifier.sortRectifiersAlphabeticallyAZ(context, rectifierNotifier, RectifierSortOption.area);
                },
              ),
              ListTile(
                title: const Text("By Test Station ID A-Z"),
                onTap: () {
                  rectifierNotifier.sortRectifiersAlphabeticallyAZ(context, rectifierNotifier, RectifierSortOption.serviceTag);
                },
              ),
              ListTile(
                title: const Text("By Status"),
                onTap: () {
                  rectifierNotifier.sortRectifiersByStatus(context, rectifierNotifier);
                },
              ),
              ListTile(
                title: const Text("By Location - Nearest to Farthest"),
                onTap: () {
                  var missingLocationStations =
                      rectifierNotifier.rectifiers.where((station) => station.latitude == 0.0 || station.longitude == 0.0).toList();

                  if (missingLocationStations.isNotEmpty) {
                    _notifyMissingLocations(context, missingLocationStations, rectifierNotifier);
                  } else {
                    LocationService locationService = LocationService();
                    rectifierNotifier.sortRectifiersByLocation(context, rectifierNotifier, locationService);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rectifierNotifier = Provider.of<RectifierNotifier>(context, listen: false);
    final rectifiers = rectifierNotifier.rectifiers; // Accessing rectifiers from provider

    void showEditDialog(BuildContext context, int index) {
      final Rectifier existingRectifier = rectifiers[index];

      final TextEditingController areaController = TextEditingController(text: existingRectifier.area);
      final TextEditingController serviceTagController = TextEditingController(text: existingRectifier.serviceTag);
      final TextEditingController useController = TextEditingController(text: existingRectifier.use);
      final TextEditingController maxVoltageController = TextEditingController(text: existingRectifier.maxVoltage.toString());
      final TextEditingController maxAmpsController = TextEditingController(text: existingRectifier.maxAmps.toString());
      final TextEditingController latitudeController = TextEditingController(text: existingRectifier.latitude.toString());
      final TextEditingController longitudeController = TextEditingController(text: existingRectifier.longitude.toString());

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Edit Rectifier Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: areaController, decoration: InputDecoration(labelText: 'Pipeline/Service/Area')),
                TextField(controller: serviceTagController, decoration: InputDecoration(labelText: 'Service Tag')),
                TextField(controller: useController, decoration: InputDecoration(labelText: 'Use')),
                TextField(controller: maxVoltageController, decoration: InputDecoration(labelText: 'Max Voltage')),
                TextField(controller: maxAmpsController, decoration: InputDecoration(labelText: 'Max Amps')),
                TextField(controller: latitudeController, decoration: InputDecoration(labelText: 'Latitude')),
                TextField(controller: longitudeController, decoration: InputDecoration(labelText: 'Longitude')),
              ],
            ),
          ),
          actions: [
            TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                // Extracting values from the TextControllers
                String area = areaController.text;
                String serviceTag = serviceTagController.text;
                String use = useController.text;
                double? maxVoltage = double.tryParse(maxVoltageController.text);
                double? maxAmps = double.tryParse(maxAmpsController.text);
                double? latitude = double.tryParse(latitudeController.text);
                double? longitude = double.tryParse(longitudeController.text);

                // Call the updateRectifier method with the extracted values
                context.read<RectifierNotifier>().updateRectifier(
                      existingRectifier,
                      area,
                      serviceTag,
                      use,
                      existingRectifier.status, // Assuming status is not being edited in this dialog
                      maxVoltage,
                      maxAmps,
                      existingRectifier.readings, // Assuming readings are not being edited in this dialog
                      existingRectifier.tapReadings, // Assuming tapReadings are not being edited in this dialog
                      existingRectifier.inspection, // Assuming inspection is not being edited in this dialog
                      latitude: latitude,
                      longitude: longitude,
                      context: context,
                    );

                // Close the dialog
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }

    void _showErrorDialog(BuildContext context, String message) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
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

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.white, // Color.fromARGB(255, 0, 43, 92),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                    RectifierNotifier rectifierNotifier = Provider.of<RectifierNotifier>(context, listen: false);
                    _showSortOptionsDialog(context, rectifierNotifier);
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
                    final TextEditingController areaController = TextEditingController();
                    final TextEditingController serviceTagController = TextEditingController();
                    final TextEditingController useController = TextEditingController();
                    final TextEditingController maxVoltageController = TextEditingController();
                    final TextEditingController maxAmpsController = TextEditingController();
                    final TextEditingController latitudeController = TextEditingController();
                    final TextEditingController longitudeController = TextEditingController();

                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Enter Details'),
                        content: SingleChildScrollView(
                          // Wrap with SingleChildScrollView to prevent overflow
                          child: Column(
                            children: [
                              TextField(
                                controller: areaController,
                                autofocus: true,
                                decoration: InputDecoration(labelText: 'Pipeline/Service/Area'),
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: serviceTagController,
                                decoration: InputDecoration(labelText: 'Rectifier Service Tag'),
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: useController,
                                decoration: InputDecoration(labelText: 'Use'),
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: maxVoltageController,
                                decoration: InputDecoration(labelText: 'Max Voltage'),
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: 10),
                              TextField(
                                controller: maxAmpsController,
                                decoration: InputDecoration(labelText: 'Max Amps'),
                                keyboardType: TextInputType.number,
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
                          TextButton(
                            onPressed: () {
                              importCsv(context);
                            },
                            child: Text('Import CSV'),
                          ),
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: Text('Add'),
                            onPressed: () {
                              // Check if the required fields are empty
                              if (areaController.text.isEmpty || serviceTagController.text.isEmpty) {
                                _showErrorDialog(context, 'Pipeline/Service/Area and Rectifier Service Tag are required!');
                                return; // Do not proceed further
                              }

                              // Extract all the entered values
                              final enteredArea = areaController.text;
                              final enteredServiceTag = serviceTagController.text;
                              final enteredUse = useController.text;
                              final enteredStatus = 'Unchecked';
                              final enteredMaxVoltage = double.tryParse(maxVoltageController.text);
                              final enteredMaxAmps = double.tryParse(maxAmpsController.text); // Default to 0 if parsing fails
                              final enteredLatitude = double.tryParse(latitudeController.text) ?? 00.000000;
                              final enteredLongitude = double.tryParse(longitudeController.text) ?? 00.000000;
                              final projectID = Provider.of<ProjectModel>(context, listen: false).id;

                              // Use the extracted values as needed
                              context.read<RectifierNotifier>().addRectifier(
                                  enteredArea,
                                  enteredServiceTag,
                                  enteredUse,
                                  enteredStatus,
                                  enteredMaxVoltage,
                                  enteredMaxAmps,
                                  enteredLatitude,
                                  enteredLongitude,
                                  projectID); // Modify this method based on your actual implementation

                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  // child: Text('Add Rectifier')
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
                    final rectifierNotifier = Provider.of<RectifierNotifier>(context, listen: false);
                    final projectID = Provider.of<ProjectModel>(context, listen: false).id;
                    final rectifiers = rectifierNotifier.rectifiers;

                    if (rectifierNotifier.rectifiers.isNotEmpty) {
                      MapView.navigateToMapView(
                        context,
                        projectID,
                        rectifiers: rectifiers,
                      );

/*
                    if (rectifierNotifier.rectifiers.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MapView(rectifiers: rectifierNotifier.rectifiers),
                        ),
                      );
*/
                    } else {
                      _showErrorDialog(context, 'No Rectifiers to show');
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
          backgroundColor: Color.fromARGB(255, 0, 43, 92),
          iconTheme: IconThemeData(color: Colors.white),
          title: Text('Rectifiers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              )),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                IconData(0xf016a, fontFamily: 'MaterialIcons'),
                size: 24, // Adjust size as per your need
              ),
              onPressed: () {
                Provider.of<RectifierNotifier>(context, listen: false).createCSV(context);
              },
              tooltip: 'Share', // Tooltip will be shown on long press
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: rectifiers.length,
        itemBuilder: (context, index) {
          Rectifier rectifier = rectifierNotifier.rectifiers[index];
          //      Rectifier rectifier = rectifiers[index];
/*
          double distanceInFeet = rectifierNotifier.calculateDistance(
            rectifierNotifier.currentUserLocation,
            rectifier.latitude,
            rectifier.longitude,
          );

          String direction = rectifierNotifier.calculateBearing(
            rectifierNotifier.currentUserLocation?.latitude ?? 0.0,
            rectifierNotifier.currentUserLocation?.longitude ?? 0.0,
            rectifier.latitude ?? 0.0,
            rectifier.longitude ?? 0.0,
          );
*/

          return GestureDetector(
            onTap: () {
              Provider.of<RectifierNotifier>(context, listen: false).rectifiers[index];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RectifierDetailsPage(
                      rectifier: rectifiers[index],
                      onStatusChanged: (status, readings, tapReadings, inspection) => Provider.of<RectifierNotifier>(context, listen: false)),
                ),
              );
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Center(
                    child: Text(
                      'Options for ${rectifiers[index].serviceTag}',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 43, 92),
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
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
                              String serviceTagToDelete = rectifiers[index].serviceTag; // Retrieve the serviceTag
                              Provider.of<RectifierNotifier>(context, listen: false).deleteRectifier(serviceTagToDelete, context);
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
                  color: Colors.white, // White container background
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            ' ${rectifiers[index].area} - ${rectifiers[index].serviceTag}',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 43, 92),
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 5.0),
                        Text(' Output Voltage: ${rectifier.readings?.multimeterVoltage} VDC',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 43, 92),
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            )),
                        SizedBox(height: 5.0),
                        Text(' Output Current: ${rectifier.readings?.calculatedCurrent} A',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 43, 92),
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            )),
                        SizedBox(height: 5.0),
                        Text(
                            ' Tap Settings: ${rectifiers[index].tapReadings?.courseTapSettingFound} ${rectifiers[index].tapReadings?.mediumTapSettingFound} ${rectifiers[index].tapReadings?.fineTapSettingFound}',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 43, 92),
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: Consumer<RectifierNotifier>(
                        builder: (context, rectifierNotifier, child) {
                          return Container(
                            width: 10.0, // Width of the status rectangle
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              color: rectifier.getStatusColor(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
