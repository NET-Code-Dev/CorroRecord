// ignore_for_file: file_names, prefer_final_fields, avoid_print, prefer_const_declarations, unnecessary_brace_in_string_interps, unnecessary_cast, prefer_interpolation_to_compose_strings, unused_element, use_build_context_synchronously, prefer_const_constructors

// Dart imports
import 'dart:io';

import 'package:asset_inspections/Common_Widgets/gps_location.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Models/project_model.dart'; // Import the ProjectModel class
import '../Models/rectifier_models.dart'; // Import the Rectifier classes
import '../database_helper.dart'; // Import the DatabaseHelper class

class RectifierNotifier extends ChangeNotifier {
  final ProjectModel projectModel;
  late Rectifier _currentRectifier;
  late List<Rectifier> _rectifiers;
  final ValueNotifier<double> calculatedCurrentNotifier = ValueNotifier<double>(0);

  RectifierNotifier(this.projectModel) {
    _initializeRectifiers();
    loadRectifiersFromDatabase;
  }

  // Initializes default rectifiers
  _initializeRectifiers() {
    _rectifiers = [];
  }

  // Getter for the rectifiers list
  List<Rectifier> get rectifiers => _rectifiers;
  // Getter for the current rectifier
  Rectifier? get currentRectifier => _currentRectifier;

  // Load rectifiers from the database
  Future<void> loadRectifiersFromDatabase(int projectID, String serviceTag) async {
    final dbHelper = DatabaseHelper.instance;
    final rows = await dbHelper.queryRectifiersByProjectID(projectID);

    _rectifiers.clear();
    for (var row in rows) {
      Rectifier rectifier = Rectifier.fromMap(row);
      _rectifiers.add(rectifier);
    }

    notifyListeners();
  }

  // Set the current rectifier and notify listeners
  Future<void> setCurrentRectifierByServiceTag(String serviceTag, BuildContext context) async {
    final projectName = Provider.of<ProjectModel>(context, listen: false).fullProjectName;
    final dbHelper = DatabaseHelper.instance;
    final rectifierData = await dbHelper.queryRectifierByServiceTag(projectName, serviceTag);
    if (rectifierData != null) {
      _currentRectifier = Rectifier.fromMap(rectifierData);
      notifyListeners();
    }
  }

  // Fetch all rectifiers from the database
  Future<void> fetchRectifiers(BuildContext context) async {
    final dbHelper = DatabaseHelper.instance;
    final rows = await dbHelper.queryRectifiersByProjectID(projectModel.id);
    _rectifiers = rows.map((e) => Rectifier.fromMap(e)).toList();
    notifyListeners();
  }

  void updateRectifierStatus(Rectifier rectifier, String newStatus, BuildContext context) async {
    final projectName = Provider.of<ProjectModel>(context, listen: false).fullProjectName;
    final dbHelper = DatabaseHelper.instance;

    int index = _rectifiers.indexWhere((existingRectifier) => existingRectifier.serviceTag == rectifier.serviceTag);

    if (index != -1) {
      _rectifiers[index].status = newStatus;
      await dbHelper.updateRectifier(projectName, _rectifiers[index].toMap());
      notifyListeners();
    }
  }

  // Update a particular rectifier's properties
  void updateRectifier(Rectifier rectifier, String? newArea, String newServiceTag, String? newUse, String newStatus, double? newMaxVoltage,
      double? newMaxAmps, RectifierReadings? newReadings, TapReadings? newTapReadings, RectifierInspection? newInspections,
      {double? latitude, double? longitude, required BuildContext context}) async {
    final projectName = Provider.of<ProjectModel>(context, listen: false).fullProjectName;
    final dbHelper = DatabaseHelper.instance;

    int index = _rectifiers.indexWhere((existingRectifier) => existingRectifier.serviceTag == rectifier.serviceTag);

    if (index != -1) {
      _rectifiers[index].area = newArea ?? _rectifiers[index].area;
      _rectifiers[index].serviceTag = newServiceTag;
      _rectifiers[index].use = newUse ?? _rectifiers[index].use;
      _rectifiers[index].status = newStatus;
      _rectifiers[index].maxVoltage = newMaxVoltage ?? _rectifiers[index].maxVoltage;
      _rectifiers[index].maxAmps = newMaxAmps ?? _rectifiers[index].maxAmps;
      _rectifiers[index].latitude = latitude ?? _rectifiers[index].latitude;
      _rectifiers[index].longitude = longitude ?? _rectifiers[index].longitude;
      _rectifiers[index].readings = newReadings ?? _rectifiers[index].readings;
      _rectifiers[index].tapReadings = newTapReadings ?? _rectifiers[index].tapReadings;
      _rectifiers[index].inspection = newInspections ?? _rectifiers[index].inspection;

      await dbHelper.updateRectifier(projectName, _rectifiers[index].toMap());
      notifyListeners();
    }
  }

  double computeCurrent({
    required String currentRatioStr,
    required String voltageRatioStr,
    required String voltageDropStr,
  }) {
    try {
      double currentRatio = currentRatioStr.isEmpty ? 0.0 : double.parse(currentRatioStr);
      double voltageRatio = voltageRatioStr.isEmpty ? 0.0 : double.parse(voltageRatioStr);
      double voltageDrop = voltageDropStr.isEmpty ? 0.0 : double.parse(voltageDropStr);

      if (currentRatio != 0.0 && voltageRatio != 0.0 && voltageDrop != 0.0) {
        double result = currentRatio / voltageRatio * voltageDrop;
        calculatedCurrentNotifier.value = result; // Update the ValueNotifier
        return result;
      }
    } catch (e) {
      print('Error parsing values: $e');
    }
    return 0.0;
  }

  RectifierReadings updateReadings({
    required String panelMeterVoltageStr,
    required String multimeterVoltageStr,
    required String voltageReadingCommentsStr,
    required String panelMeterAmpsStr,
    required String ammeterAmpsStr,
    required String currentReadingCommentsStr,
    required String currentRatioStr,
    required String voltageRatioStr,
    required String voltageDropStr,
  }) {
    double calculatedCurrent = computeCurrent(
      currentRatioStr: currentRatioStr,
      voltageRatioStr: voltageRatioStr,
      voltageDropStr: voltageDropStr,
    );

    final newReadings = RectifierReadings(
      panelMeterVoltage: double.tryParse(panelMeterVoltageStr) ?? 0.0,
      multimeterVoltage: double.tryParse(multimeterVoltageStr) ?? 0.0,
      voltageReadingComments: (voltageReadingCommentsStr),
      panelMeterAmps: double.tryParse(panelMeterAmpsStr) ?? 0.0,
      ammeterAmps: double.tryParse(ammeterAmpsStr) ?? 0.0,
      currentReadingComments: (currentReadingCommentsStr),
      currentRatio: double.tryParse(currentRatioStr) ?? 0.0,
      voltageRatio: double.tryParse(voltageRatioStr) ?? 0.0,
      voltageDrop: double.tryParse(voltageDropStr) ?? 0.0,
      calculatedCurrent: calculatedCurrent,
    );

    return newReadings;
  }

  TapReadings updateTapReadings({
    required String courseTapSettingStr,
    required String mediumTapSettingStr,
    required String fineTapSettingStr,
  }) {
    final newTapReadings = TapReadings(
      courseTapSettingFound: (courseTapSettingStr),
      mediumTapSettingFound: (mediumTapSettingStr),
      fineTapSettingFound: (fineTapSettingStr),
    );

    return newTapReadings;
  }

  RectifierInspection updateInspection({
    required String oilLevelStr,
    required String oilLevelFindingsStr,
    required String oilLevelCommentsStr,
    required String deviceDamageStr,
    required String deviceDamageFindingsStr,
    required String deviceDamageCommentsStr,
    required String circuitBreakersStr,
    required String circuitBreakersCommentsStr,
    required String fusesWiringStr,
    required String fusesWiringCommentsStr,
    required String lightningArrestorsStr,
    required String lightningArrestorsCommentsStr,
    required String ventScreensStr,
    required String ventScreensCommentsStr,
    required String breathersStr,
    required String breathersCommentsStr,
    required String removeObstructionsStr,
    required String removeObstructionsCommentsStr,
    required String cleanedStr,
    required String cleanedCommentsStr,
    required String tightenedStr,
    required String tightenedCommentsStr,
  }) {
    final newInspection = RectifierInspection(
      oilLevel: int.tryParse(oilLevelStr),
      oilLevelFindings: (oilLevelFindingsStr),
      oilLevelComments: (oilLevelCommentsStr),
      deviceDamage: (int.tryParse(deviceDamageStr)),
      deviceDamageFindings: (deviceDamageFindingsStr),
      deviceDamageComments: (deviceDamageCommentsStr),
      circuitBreakers: int.tryParse(circuitBreakersStr),
      circuitBreakersComments: (circuitBreakersCommentsStr),
      fusesWiring: int.tryParse(fusesWiringStr),
      fusesWiringComments: (fusesWiringCommentsStr),
      lightningArrestors: int.tryParse(lightningArrestorsStr),
      lightningArrestorsComments: (lightningArrestorsCommentsStr),
      ventScreens: int.tryParse(ventScreensStr),
      ventScreensComments: (ventScreensCommentsStr),
      breathers: int.tryParse(breathersStr),
      breathersComments: (breathersCommentsStr),
      removeObstructions: int.tryParse(removeObstructionsStr),
      removeObstructionsComments: (removeObstructionsCommentsStr),
      cleaned: int.tryParse(cleanedStr),
      cleanedComments: (cleanedCommentsStr),
      tightened: int.tryParse(tightenedStr),
      tightenedComments: (tightenedCommentsStr),
      polarityCondition: null,
      polarityConditionComments: '',
      reason: '',
    );

    return newInspection;
  }

  Future<void> addRectifier(String area, String serviceTag, String use, String status, double? maxVoltage, double? maxAmps, double? latitude,
      double? longitude, int projectID) async {
    final dbHelper = DatabaseHelper.instance;

    Rectifier newRectifier = Rectifier(
      projectID: projectID,
      area: area,
      serviceTag: serviceTag,
      use: use,
      status: 'Unchecked',
      maxVoltage: maxVoltage,
      maxAmps: maxAmps,
      latitude: latitude,
      longitude: longitude,
      readings: RectifierReadings(
        panelMeterVoltage: 0,
        multimeterVoltage: 0,
        voltageReadingComments: '',
        panelMeterAmps: 0,
        ammeterAmps: 0,
        currentReadingComments: '',
        currentRatio: 0,
        voltageRatio: 0,
        voltageDrop: 0,
        calculatedCurrent: 0,
      ),
      tapReadings: TapReadings(
        courseTapSettingFound: '',
        mediumTapSettingFound: '',
        fineTapSettingFound: '',
      ),
      inspection: RectifierInspection(
        reason: '',
        oilLevel: null,
        oilLevelComments: '',
        oilLevelFindings: '',
        deviceDamage: null,
        deviceDamageComments: '',
        deviceDamageFindings: '',
        polarityCondition: null,
        polarityConditionComments: '',
        circuitBreakers: null,
        circuitBreakersComments: '',
        fusesWiring: null,
        fusesWiringComments: '',
        lightningArrestors: null,
        lightningArrestorsComments: '',
        ventScreens: null,
        ventScreensComments: '',
        breathers: null,
        breathersComments: '',
        removeObstructions: null,
        removeObstructionsComments: '',
        cleaned: null,
        cleanedComments: '',
        tightened: null,
        tightenedComments: '',
      ),
    );

    try {
      int insertedId = await dbHelper.insertRectifier(
        newRectifier.toMap(),
      );

      print('Inserted ID: $insertedId');

      if (insertedId > 0) {
        _rectifiers.add(newRectifier);
        notifyListeners();
      } else {
        print('Insertion failed: ID is non-positive');
        // Consider adding more user feedback here
      }
    } catch (e) {
      print('Error inserting TestStation: $e');
      // Consider logging additional data if needed
      // Provide user feedback regarding the error
    }
  }

  Future<void> addRectifiers(List<Rectifier> rectifiers, int projectID) async {
    final dbHelper = DatabaseHelper.instance;

    List<Map<String, dynamic>> rectifiersMaps = [];
    for (Rectifier rectifier in rectifiers) {
      rectifiersMaps.add({
        'projectID': projectID,
        'area': rectifier.area ?? '',
        'serviceTag': rectifier.serviceTag,
        'status': rectifier.status,
        'use': rectifier.use ?? '',
        'maxVoltage': rectifier.maxVoltage ?? 0.00,
        'maxAmps': rectifier.maxAmps ?? 0.00,
        'latitude': rectifier.latitude ?? 0.000000,
        'longitude': rectifier.longitude ?? 0.000000,
      });
    }

    try {
      await dbHelper.insertMultipleRectifiers(rectifiersMaps);
      await loadRectifiersFromDatabase(projectID, 'serviceTag');
      notifyListeners();
    } catch (e) {
      print('Error inserting TestStation: $e');
      // Consider logging additional data if needed
      // Provide user feedback regarding the error
    }
  }

  Future<void> deleteRectifier(String serviceTag, BuildContext context) async {
    final projectName = Provider.of<ProjectModel>(context, listen: false).fullProjectName;
    final dbHelper = DatabaseHelper.instance;

    // Delete the rectifier from the database
    await dbHelper.deleteRectifier(projectName, serviceTag);

    // Remove the rectifier from the _rectifiers list
    _rectifiers.removeWhere((r) => r.serviceTag == serviceTag);
    notifyListeners();
  }

  // Check storage permission
  Future<void> checkPermission() async {
    if (await permission_handler.Permission.storage.request().isGranted) {
      print("Permission granted");
    }
  }

  Future<void> requestStoragePermission() async {
    permission_handler.PermissionStatus status = await permission_handler.Permission.storage.status;
    if (!status.isGranted) {
      await permission_handler.Permission.storage.request();
    }
  }

  // Create a CSV from provided data and filename
  Future<void> createCSV(BuildContext context) async {
    print('createCSV called');

    await requestStoragePermission();

    // Convert the rectifiers into a 2D list
    List<List<Object?>> rectifierData = rectifiers.map((rectifier) {
      return [
        rectifier.area,
        rectifier.serviceTag,
        rectifier.use,
        rectifier.status,
        rectifier.maxVoltage,
        rectifier.maxAmps,
        rectifier.latitude,
        rectifier.longitude,
        rectifier.readings?.panelMeterVoltage,
        rectifier.readings?.multimeterVoltage,
        rectifier.readings?.voltageReadingComments,
        rectifier.readings?.panelMeterAmps,
        rectifier.readings?.ammeterAmps,
        rectifier.readings?.currentReadingComments,
        rectifier.readings?.currentRatio,
        rectifier.readings?.voltageRatio,
        rectifier.readings?.voltageDrop,
        rectifier.readings?.calculatedCurrent,
        rectifier.tapReadings?.courseTapSettingFound,
        rectifier.tapReadings?.mediumTapSettingFound,
        rectifier.tapReadings?.fineTapSettingFound,
        rectifier.inspection?.oilLevel,
        rectifier.inspection?.oilLevelFindings,
        rectifier.inspection?.oilLevelComments,
        rectifier.inspection?.deviceDamage,
        rectifier.inspection?.deviceDamageFindings,
        rectifier.inspection?.deviceDamageComments,
        rectifier.inspection?.circuitBreakers,
        rectifier.inspection?.circuitBreakersComments,
        rectifier.inspection?.fusesWiring,
        rectifier.inspection?.fusesWiringComments,
        rectifier.inspection?.lightningArrestors,
        rectifier.inspection?.lightningArrestorsComments,
        rectifier.inspection?.ventScreens,
        rectifier.inspection?.ventScreensComments,
        rectifier.inspection?.breathers,
        rectifier.inspection?.breathersComments,
        rectifier.inspection?.removeObstructions,
        rectifier.inspection?.removeObstructionsComments,
        rectifier.inspection?.cleaned,
        rectifier.inspection?.cleanedComments,
        rectifier.inspection?.tightened,
        rectifier.inspection?.tightenedComments,
      ];
    }).toList();

    // Insert the headers at the beginning of the list
    rectifierData.insert(0, [
      'Area',
      'Service Tag',
      'Use',
      'Status',
      'Max Voltage',
      'Max Amps',
      'Latitude',
      'Longitude',
      'Panel Meter Voltage',
      'Multimeter Voltage',
      'Voltage Reading Comments',
      'Panel Meter Amps',
      'Ammeter Amps',
      'Current Reading Comments',
      'Shunt Current Ratio',
      'Shunt Voltage Ratio',
      'Measured Voltage Drop',
      'Calculated Shunt Current',
      'Course Tap Setting',
      'Medium Tap Setting',
      'Fine Tap Setting',
      'Oil Level',
      'Oil Level Findings',
      'Oil Level Comments',
      'Rectifier Damage/Insects/Animals',
      'Rectifier Damage/Insects/Animals Findings',
      'Rectifier Damage/Insects/Animals Comments',
      'Circuit Breakers',
      'Circuit Breakers Comments',
      'Fuses/Wiring ',
      'Fuses/Wiring Comments',
      'Lightning Arrestors',
      'Lightning Arrestors Comments',
      'Vent Screens',
      'Vent Screens Comments',
      'Breathers',
      'Breathers Comments',
      'Removal of Obstructions',
      'Removal of Obstructions Comments',
      'Cleaned',
      'Cleaned Comments',
      'Tightened',
      'Tightened Comments',
    ]);

    String csvData = const ListToCsvConverter().convert(rectifierData);

    // Save or share the CSV file
    try {
      File? file = await saveOrShareCSV(csvData, context);
      if (file != null) {
        print('CSV file saved or shared at ${file.path}');

        // Provide feedback using a snackbar
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV file saved or shared successfully!')));
      }
    } catch (e) {
      print('Failed to save or share file: $e');

      // Provide feedback using a snackbar in case of error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save or share CSV file.')));
    }
  }

  Future<String> getDownloadsDirectoryPath() async {
    Directory downloadsDirectory;

    // For Android:
    if (Platform.isAndroid) {
      downloadsDirectory = Directory('/storage/emulated/0/Download');
    } else {
      // For iOS, there isn't a user-accessible file system, so you'd typically share the file instead
      throw Exception('Unsupported platform');
    }

    return downloadsDirectory.path;
  }

  Future<File?> saveOrShareCSV(String csvData, BuildContext context) async {
    try {
      final directoryPath = await getDownloadsDirectoryPath();
      print("Directory Path: $directoryPath");

      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      DateTime now = DateTime.now();
      String formattedDate = "${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}";
      File file = File('$directoryPath/rectifiers_$formattedDate.csv');
      print("Attempting to save to: ${file.path}");

      await file.create();
      await file.writeAsString(csvData, mode: FileMode.write);
      print("File successfully written to: ${file.path}");

      bool shouldShare = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Share File?'),
                content: Text('Do you want to share the CSV file?'),
                actions: [
                  TextButton(
                    child: Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: Text('Yes'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          ) ??
          false;

      if (shouldShare) {
        Share.shareXFiles([XFile(file.path)], subject: 'Rectifiers CSV Data', text: 'Here is the exported rectifiers data.');
      }

      return file;
    } catch (e) {
      print("Error saving or sharing CSV: $e");
      return null;
    }
  }

  void sortRectifiersAlphabeticallyAZ(BuildContext context, RectifierNotifier rectifierNotifier, RectifierSortOption rectifierSortOption) {
    if (rectifierSortOption == RectifierSortOption.area) {
      rectifierNotifier.rectifiers.sort((a, b) => a.area?.compareTo(b.area ?? '') ?? 0);
    } else if (rectifierSortOption == RectifierSortOption.serviceTag) {
      rectifierNotifier.rectifiers.sort((a, b) => a.serviceTag.compareTo(b.serviceTag));
    }

    rectifierNotifier.notifyListeners(); // Notify listeners to update the UI
    Navigator.of(context).pop(); // Close the dialog
  }

  void sortRectifiersByLocation(BuildContext context, RectifierNotifier rectifierNotifier, LocationService locationService) async {
    LocationData? userLocation = await locationService.getCurrentLocation();
    if (userLocation == null) {
      // Handle the case where user location is not available
      return;
    }
  }

  void sortRectifiersByStatus(BuildContext context, RectifierNotifier rectifierNotifier) {
    const statusOrder = {'Pass': 1, 'Attention': 2, 'Issue': 3, 'Unchecked': 4};
    rectifierNotifier.rectifiers.sort((a, b) {
      // Fallback for statuses not in the map
      final int aStatus = statusOrder[a.status] ?? 5;
      final int bStatus = statusOrder[b.status] ?? 5;
      return aStatus.compareTo(bStatus);
    });
    rectifierNotifier.notifyListeners(); // Notify listeners to update the UI
    Navigator.of(context).pop(); // Close the dialog
  }
}

enum RectifierSortOption {
  area,
  serviceTag,
}
