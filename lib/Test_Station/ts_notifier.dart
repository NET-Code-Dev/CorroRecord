// ignore_for_file: use_build_context_synchronously, file_names, avoid_print, unrelated_type_equality_checks

import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
//import 'package:sqflite/sqflite.dart';

import 'package:asset_inspections/Models/project_model.dart';
import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Common_Widgets/gps_location.dart';

import '../database_helper.dart';

enum SortOption { area, tsID }

class TSNotifier extends ChangeNotifier {
  final ProjectModel projectModel;
  late TestStation _currentTestStation;
  late List<TestStation> _testStations = [];
  LocationData? currentUserLocation;
  int? _lastProjectIdLoaded;

  /// Initializes the [TSNotifier] with the given [projectModel].
  /// It also initializes the test stations and loads them from the database.
  /// The [projectModel] should have an ID field.
  @override
  TSNotifier(this.projectModel) {
    _initializeTestStations();
    loadTestStationsFromDatabase(projectModel.id);
  }

  /// Initializes the test stations list.
  void _initializeTestStations() {
    _testStations = [];
  }

  /// Returns the list of test stations.
  List<TestStation> get testStations => _testStations;

  /// Returns the current test station.
  TestStation get currentTestStation => _currentTestStation;

  /// Sets the current test station and notifies the listeners.
  set currentTestStation(TestStation station) {
    _currentTestStation = station;
    notifyListeners();
  }

  void clearTestStationsList() {
    print('Clearing Test Stations list: ${_testStations.length}');
    _testStations.clear();
    notifyListeners();
    print('Cleared Test Stations list: ${_testStations.length}');
  }

  /// Loads the test stations from the database based on the project ID and test station ID.
  ///
  /// Parameters:
  /// - projectID: The ID of the project.
  /// - testStationID: The ID of the test station.

  Future<void> loadTestStationsFromDatabase(int projectID) async {
    if (_lastProjectIdLoaded == projectID) {
      print('Attempt to load test stations for project $projectID again. Ignoring.');
      return;
    }
    _lastProjectIdLoaded = projectID;
    clearTestStationsList();
    print('Loading Test Stations...');
    final dbHelper = DatabaseHelper.instance;
    final rows = await dbHelper.queryTestStationsByProjectID(projectID);
    for (var row in rows) {
      TestStation testStation = TestStation.fromMap(row);

      bool isDuplicate = _testStations.any((existingTestStation) => existingTestStation.id == testStation.id);

      if (!isDuplicate) {
        // Fetch different types of readings for this TestStation
        final plTestLeadRows = await dbHelper.queryReadingsByTestStationID('PLTestLeadContainers', testStation.id);
        final permRefRows = await dbHelper.queryReadingsByTestStationID('PermRefContainers', testStation.id);
        final anodeRows = await dbHelper.queryReadingsByTestStationID('AnodeContainers', testStation.id);
        final shuntRows = await dbHelper.queryReadingsByTestStationID('ShuntContainers', testStation.id);
        final riserRows = await dbHelper.queryReadingsByTestStationID('RiserContainers', testStation.id);
        final foreignRows = await dbHelper.queryReadingsByTestStationID('ForeignContainers', testStation.id);
        final testLeadRows = await dbHelper.queryReadingsByTestStationID('TestLeadContainers', testStation.id);
        final couponRows = await dbHelper.queryReadingsByTestStationID('CouponContainers', testStation.id);
        final bondRows = await dbHelper.queryReadingsByTestStationID('BondContainers', testStation.id);
        final isolationRows = await dbHelper.queryReadingsByTestStationID('IsolationContainers', testStation.id);

        // Convert the rows to the respective reading objects
        List<PLTestLeadReading> plTestLeadReadings = plTestLeadRows.map((row) => PLTestLeadReading.fromMap(row)).toList();
        List<PermRefReading> permRefReadings = permRefRows.map((row) => PermRefReading.fromMap(row)).toList();
        List<AnodeReading> anodeReadings = anodeRows.map((row) => AnodeReading.fromMap(row)).toList();
        List<ShuntReading> shuntReadings = shuntRows.map((row) => ShuntReading.fromMap(row)).toList();
        List<RiserReading> riserReadings = riserRows.map((row) => RiserReading.fromMap(row)).toList();
        List<ForeignReading> foreignReadings = foreignRows.map((row) => ForeignReading.fromMap(row)).toList();
        List<TestLeadReading> testLeadReadings = testLeadRows.map((row) => TestLeadReading.fromMap(row)).toList();
        List<CouponReading> couponReadings = couponRows.map((row) => CouponReading.fromMap(row)).toList();
        List<BondReading> bondReadings = bondRows.map((row) => BondReading.fromMap(row)).toList();
        List<IsolationReading> isolationReadings = isolationRows.map((row) => IsolationReading.fromMap(row)).toList();

        // Assign the readings to the TestStation
        testStation.plTestLeadReadings = plTestLeadReadings;
        testStation.permRefReadings = permRefReadings;
        testStation.anodeReadings = anodeReadings;
        testStation.shuntReadings = shuntReadings;
        testStation.riserReadings = riserReadings;
        testStation.foreignReadings = foreignReadings;
        testStation.testLeadReadings = testLeadReadings;
        testStation.couponReadings = couponReadings;
        testStation.bondReadings = bondReadings;
        testStation.isolationReadings = isolationReadings;

        _testStations.add(testStation);
        print('Test Stations $projectID');
      }
    }
    notifyListeners();
    print('Loaded Test Stations: ${_testStations.length}');
  }

  /// Sets the current test station based on the service tag.
  ///
  /// Retrieves the test station data from the database using the provided project ID and test station ID.
  /// If the test station data is found, it updates the [_currentTestStation] variable with the retrieved data
  /// and notifies the listeners.
  ///
  /// Parameters:
  /// - projectID: The ID of the project.
  /// - id: The ID of the test station.
  /// - tsID: The ID of the test station.
  /// - context: The build context.
  ///
  /// Returns: A [Future] that completes when the operation is done.
  Future<void> setCurrentTestStationByServiceTag(int projectID, int id, String tsID, BuildContext context) async {
    final dbHelper = DatabaseHelper.instance;
    final tsData = await dbHelper.queryTestStationBytsID(projectID, tsID);
    if (tsData != null) {
      _currentTestStation = TestStation.fromMap(tsData);
      notifyListeners();
    }
  }

  /// Fetches the test stations for the given project ID.
  ///
  /// Retrieves the test station data from the database using the provided project ID.
  /// It updates the [_testStations] list with the retrieved data and notifies the listeners.
  ///
  /// Parameters:
  /// - context: The build context.
  /// - projectID: The ID of the project.
  ///
  /// Returns: A [Future] that completes when the operation is done.
  Future<void> fetchTestStation(BuildContext context, int projectID) async {
    final dbHelper = DatabaseHelper.instance;
    final rows = await dbHelper.queryTestStationsByProjectID(projectID);
    _testStations = rows.map((e) => TestStation.fromMap(e)).toList();
    notifyListeners();
  }

  /// Updates the status of a test station.
  ///
  /// Updates the [tsstatus] property of the provided [testStation] with the [newTSStatus].
  /// It retrieves the project name from the [ProjectModel] using the [context].
  /// It then updates the test station in the database and notifies the listeners.
  ///
  /// Parameters:
  /// - testStation: The test station to update.
  /// - newTSStatus: The new status of the test station.
  /// - context: The build context.
  ///
  /// Returns: A [Future] that completes when the operation is done.
  void updateTestStationStatus(TestStation testStation, String newTSStatus, BuildContext context) async {
    final projectName = Provider.of<ProjectModel>(context, listen: false).fullProjectName;
    final dbHelper = DatabaseHelper.instance;

    int index = _testStations.indexWhere((existingTestStation) => existingTestStation.id == testStation.id);

    if (index != -1) {
      _testStations[index].tsstatus = newTSStatus;
      await dbHelper.updateTestStation(projectName, _testStations[index].toMap());
      notifyListeners();
    }
  }

  /// Updates the test station with the specified parameters.
  ///
  /// - The [testStation] parameter is the test station to be updated.
  /// - The [newArea] parameter is the new area of the test station.
  /// - The [newtsID] parameter is the new ID of the test station.
  /// - The [newStatus] parameter is the new status of the test station.
  /// - The [newPLTestLeadReading] parameter is a list of new PL test lead readings.
  /// - The [newPermRefReading] parameter is a list of new perm ref readings.
  /// - The [newAnodeReading] parameter is a list of new anode readings.
  /// - The [newShuntReading] parameter is a list of new shunt readings.
  /// - The [newRiserReading] parameter is a list of new riser readings.
  /// - The [newForeignReading] parameter is a list of new foreign readings.
  /// - The [newTestLeadReading] parameter is a list of new test lead readings.
  /// - The [newCouponReading] parameter is a list of new coupon readings.
  /// - The [newBondReading] parameter is a list of new bond readings.
  /// - The [newIsolationReading] parameter is a list of new isolation readings.
  /// - The [latitude] parameter is the new latitude of the test station.
  /// - The [longitude] parameter is the new longitude of the test station.
  /// - The [context] parameter is the build context.
  ///
  /// This method updates the specified test station with the new values for the area, ID, status, latitude, longitude,
  /// and readings. It also updates the test station in the database and notifies the listeners.
  void updateTestStation(
    TestStation testStation,
    String? newArea,
    String newtsID,
    String newStatus,
    List<PLTestLeadReading>? newPLTestLeadReading,
    List<PermRefReading>? newPermRefReading,
    List<AnodeReading>? newAnodeReading,
    List<ShuntReading>? newShuntReading,
    List<RiserReading>? newRiserReading,
    List<ForeignReading>? newForeignReading,
    List<TestLeadReading>? newTestLeadReading,
    List<CouponReading>? newCouponReading,
    List<BondReading>? newBondReading,
    List<IsolationReading>? newIsolationReading, {
    double? latitude,
    double? longitude,
    required BuildContext context,
  }) async {
    final projectName = Provider.of<ProjectModel>(context, listen: false).fullProjectName;
    final dbHelper = DatabaseHelper.instance;

    int index = _testStations.indexWhere((existingTestStation) => existingTestStation.id == testStation.id);

    if (index != -1) {
      _testStations[index].area = newArea ?? _testStations[index].area;
      _testStations[index].tsID = newtsID;
      _testStations[index].tsstatus = newStatus;
      _testStations[index].latitude = latitude ?? _testStations[index].latitude;
      _testStations[index].longitude = longitude ?? _testStations[index].longitude;

      // Add the new readings to the existing lists of readings.
      if (newPLTestLeadReading != null) {
        _testStations[index].plTestLeadReadings?.addAll(newPLTestLeadReading);
      }
      if (newPermRefReading != null) {
        _testStations[index].permRefReadings?.addAll(newPermRefReading);
      }
      if (newAnodeReading != null) {
        _testStations[index].anodeReadings?.addAll(newAnodeReading);
      }
      if (newShuntReading != null) {
        _testStations[index].shuntReadings?.addAll(newShuntReading);
      }
      if (newRiserReading != null) {
        _testStations[index].riserReadings?.addAll(newRiserReading);
      }
      if (newForeignReading != null) {
        _testStations[index].foreignReadings?.addAll(newForeignReading);
      }
      if (newTestLeadReading != null) {
        _testStations[index].testLeadReadings?.addAll(newTestLeadReading);
      }
      if (newCouponReading != null) {
        _testStations[index].couponReadings?.addAll(newCouponReading);
      }
      if (newBondReading != null) {
        _testStations[index].bondReadings?.addAll(newBondReading);
      }
      if (newIsolationReading != null) {
        _testStations[index].isolationReadings?.addAll(newIsolationReading);
      }
      await dbHelper.updateTestStation(projectName, _testStations[index].toMap());
      notifyListeners();
    }
  }

  /// Adds a new test station to the database.
  ///
  /// - The [area] parameter specifies the area of the test station.
  /// - The [tsID] parameter specifies the ID of the test station.
  /// - The [tsstatus] parameter specifies the status of the test station.
  /// - The [latitude] parameter specifies the latitude of the test station.
  /// - The [longitude] parameter specifies the longitude of the test station.
  /// - The [projectID] parameter specifies the ID of the project.
  ///
  /// Throws an exception if an error occurs during the insertion process.
  /// Prints the inserted ID if the insertion is successful.
  /// Loads the test stations from the database and notifies the listeners.
  /// Prints an error message if the insertion fails.
  /// Prints an error message if an error occurs during the insertion process.
  Future<void> addTestStation(
    String area,
    String tsID,
    String tsstatus,
    double? latitude,
    double? longitude,
    int projectID,
  ) async {
    final dbHelper = DatabaseHelper.instance;

    TestStation newTestStation = TestStation(
      projectID: projectID,
      area: area,
      tsID: tsID,
      tsstatus: tsstatus,
      latitude: latitude ?? 0.000000,
      longitude: longitude ?? 0.000000,
    );

    try {
      int insertedId = await dbHelper.insertTestStation(
        newTestStation.toMap(),
      );

      print('Inserted ID: $insertedId');

      if (insertedId > 0) {
        newTestStation.id = insertedId;
        // Instead of loading all test stations from the database,
        // directly add the new test station to the list.
        _testStations.add(newTestStation);
        notifyListeners();
      }
    } catch (e) {
      print('Error inserting TestStation: $e');
      // Consider logging additional data if needed
      // Provide user feedback regarding the error
    }
    // loadTestStationsFromDatabase(projectID);
  }

  /// Adds a list of [TestStation] objects to the database.
  ///
  /// The [testStations] parameter is a list of [TestStation] objects to be added.
  /// The [projectID] parameter is the ID of the project associated with the test stations.
  ///
  /// Each [TestStation] object is converted into a map and added to the database using the [DatabaseHelper] instance.
  /// The map contains the following fields:
  /// - 'projectID': The ID of the project.
  /// - 'area': The area of the test station. If not provided, it defaults to an empty string.
  /// - 'tsID': The ID of the test station.
  /// - 'status': The status of the test station.
  /// - 'latitude': The latitude of the test station. If not provided, it defaults to 0.000000.
  /// - 'longitude': The longitude of the test station. If not provided, it defaults to 0.000000.
  ///
  /// After adding the test stations to the database, the [loadTestStationsFromDatabase] method is called to reload the test stations from the database.
  /// Finally, the [notifyListeners] method is called to notify any listeners of changes to the test stations.
  ///
  /// If an error occurs during the process, it is caught and handled appropriately.

  Future<void> addTestStations(List<TestStation> testStations, int projectID) async {
    final dbHelper = DatabaseHelper.instance;

    List<Map<String, dynamic>> testStationMaps = [];
    for (TestStation testStation in testStations) {
      testStationMaps.add({
        // Assuming these are the correct field names for your database schema
        'projectID': projectID,
        'area': testStation.area ?? '',
        'tsID': testStation.tsID,
        'status': testStation.tsstatus,
        'latitude': testStation.latitude ?? 0.000000,
        'longitude': testStation.longitude ?? 0.000000,
      });
    }

    try {
      await dbHelper.insertMultipleTestStations(testStationMaps);

      await loadTestStationsFromDatabase(projectID);
      notifyListeners();
    } catch (e) {
      // Handle the error, perhaps log it or show a user-friendly message
    }
  }

  /// Deletes a test station with the specified [id] from the database and updates the UI.
  ///
  /// The [context] parameter is used to access the [ProjectModel] and retrieve the full project name.
  /// The test station is deleted from the database using the [DatabaseHelper] instance.
  /// After deleting the test station, it is also removed from the [_testStations] list.
  /// The updated test stations are then loaded from the database and the UI is notified of the changes.
  Future<void> deleteTestStation(int id, BuildContext context) async {
    final projectName = Provider.of<ProjectModel>(context, listen: false).fullProjectName;
    final dbHelper = DatabaseHelper.instance;

    // Delete the test station from the database
    await dbHelper.deleteTestStation(projectName, id);

    // Remove the test station from the _test stations list
    _testStations.removeWhere((r) => r.tsID == id);

    await loadTestStationsFromDatabase(projectModel.id);
    notifyListeners();
  }

  /// Sorts the test stations alphabetically based on the specified [sortOption].
  ///
  /// If [sortOption] is [SortOption.area], the test stations will be sorted based on their area.
  /// If [sortOption] is [SortOption.tsID], the test stations will be sorted based on their tsID.
  ///
  /// After sorting, the [tsNotifier] will notify its listeners to update the UI.
  /// The [context] is used to access the current BuildContext.
  /// Finally, the dialog will be closed using Navigator.of(context).pop().
  void sortTestStationsAlphabeticallyAZ(BuildContext context, TSNotifier tsNotifier, SortOption sortOption) {
    if (sortOption == SortOption.area) {
      tsNotifier.testStations.sort((a, b) => a.area?.compareTo(b.area ?? '') ?? 0);
    } else if (sortOption == SortOption.tsID) {
      tsNotifier.testStations.sort((a, b) => a.tsID.compareTo(b.tsID));
    }

    tsNotifier.notifyListeners(); // Notify listeners to update the UI
    Navigator.of(context).pop(); // Close the dialog
  }

  /// Sorts the test stations in [tsNotifier] by their status.
  ///
  /// The test stations are sorted based on the following status order:
  /// - 'Pass': 1
  /// - 'Attention': 2
  /// - 'Issue': 3
  /// - 'Unchecked': 4
  ///
  /// If a test station's status is not in the above list, it is assigned a fallback value of 5.
  ///
  /// After sorting, the listeners are notified to update the UI, and the dialog is closed.
  ///
  /// Parameters:
  /// - [context]: The build context.
  /// - [tsNotifier]: The TSNotifier object containing the test stations.
  void sortTestStationsByStatus(BuildContext context, TSNotifier tsNotifier) {
    const statusOrder = {'Pass': 1, 'Attention': 2, 'Issue': 3, 'Unchecked': 4};
    tsNotifier.testStations.sort((a, b) {
      // Fallback for statuses not in the map
      final int aStatus = statusOrder[a.tsstatus] ?? 5;
      final int bStatus = statusOrder[b.tsstatus] ?? 5;
      return aStatus.compareTo(bStatus);
    });
    tsNotifier.notifyListeners(); // Notify listeners to update the UI
    Navigator.of(context).pop(); // Close the dialog
  }

  /// Sorts the test stations by location.
  ///
  /// This method takes in the [context], [tsNotifier], and [locationService] as parameters.
  /// It retrieves the current user location using the [locationService] and sorts the test stations
  /// in [tsNotifier] based on their distance from the user's location.
  /// The test stations are sorted in ascending order, with the closest station first.
  /// After sorting, it notifies the listeners in [tsNotifier] and pops the current screen from the [context].
  void sortTestStationsByLocation(BuildContext context, TSNotifier tsNotifier, LocationService locationService) async {
    LocationData? userLocation = await locationService.getCurrentLocation();
    if (userLocation == null) {
      return;
    }

    currentUserLocation = userLocation;

    tsNotifier.testStations.sort((a, b) {
      if ((a.latitude == 0.0 && a.longitude == 0.0) || (b.latitude == 0.0 && b.longitude == 0.0)) {
        // Handle sorting when one or both stations have 0.0, 0.0 coordinates
        if (a.latitude == 0.0 && a.longitude == 0.0 && b.latitude == 0.0 && b.longitude == 0.0) {
          return 0; // Both are "Unknown", so they are considered equal
        }
        if (a.latitude == 0.0 && a.longitude == 0.0) {
          return 1; // a is "Unknown", so it should be sorted as greater than b
        }
        return -1; // b is "Unknown", so a should be sorted as less than b
      }

      // Regular distance calculation for stations with valid coordinates
      final distanceA = calculateDistance(userLocation, a.latitude, a.longitude);
      final distanceB = calculateDistance(userLocation, b.latitude, b.longitude);
      return distanceA.compareTo(distanceB);
    });

    tsNotifier.notifyListeners();
    Navigator.of(context).pop();
  }

  /// Calculates the distance between the user's location and a given latitude and longitude.
  /// Returns the distance in meters.
  /// If any of the parameters are null, returns double.infinity to indicate an invalid distance.
  double calculateDistance(LocationData? userLocation, double? latitude, double? longitude) {
    if (userLocation == null || latitude == null || longitude == null) {
      return double.infinity; // Return a large number to indicate an invalid distance
    }

    const double radiusOfEarthInKm = 6371.0; // Earth's radius in kilometers
    double lat1 = userLocation.latitude ?? 0.000000;
    double lon1 = userLocation.longitude ?? 0.000000;
    double lat2 = latitude;
    double lon2 = longitude;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) + cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distanceInKilometers = radiusOfEarthInKm * c;

    // Convert distance from kilometers to feet
    const double kilometersToMeters = 1000;
    return distanceInKilometers * kilometersToMeters;
  }

  /// Converts degrees to radians.
  ///
  /// Takes a [degrees] value and returns the equivalent value in radians.
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Calculates the bearing between two coordinates using the Haversine formula.
  ///
  /// The bearing is the angle between the direction of an object and a reference direction,
  /// typically true north. This method calculates the bearing in degrees from the first
  /// coordinate to the second coordinate.
  ///
  /// The formula used to calculate the bearing is the Haversine formula, which takes into
  /// account the curvature of the Earth.
  ///
  /// Parameters:
  /// - [lat1]: The latitude of the first coordinate.
  /// - [lon1]: The longitude of the first coordinate.
  /// - [lat2]: The latitude of the second coordinate.
  /// - [lon2]: The longitude of the second coordinate.
  ///
  /// Returns:
  /// - The bearing between the two coordinates as a string. The bearing is represented
  ///   using cardinal directions, such as 'N' for north, 'NE' for northeast, 'E' for east, etc.
  String calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    var dLon = _degreesToRadians(lon2 - lon1);
    var x = sin(dLon) * cos(_degreesToRadians(lat2));
    var y = cos(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) - sin(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * cos(dLon);

    var bearing = atan2(x, y);
    bearing = _radiansToDegrees(bearing);
    bearing = (bearing + 360) % 360; // Normalize to 0-360

    if (bearing >= 0 && bearing < 22.5) {
      return 'N';
    } else if (bearing >= 22.5 && bearing < 67.5) {
      return 'NE';
    } else if (bearing >= 67.5 && bearing < 112.5) {
      return 'E';
    } else if (bearing >= 112.5 && bearing < 157.5) {
      return 'SE';
    } else if (bearing >= 157.5 && bearing < 202.5) {
      return 'S';
    } else if (bearing >= 202.5 && bearing < 247.5) {
      return 'SW';
    } else if (bearing >= 247.5 && bearing < 292.5) {
      return 'W';
    } else if (bearing >= 292.5 && bearing < 337.5) {
      return 'NW';
    } else {
      return 'N'; // Covers 337.5 to 360
    }
  }

  /// Converts radians to degrees.
  ///
  /// Takes a [radians] value and returns the equivalent value in degrees.
  double _radiansToDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  /// Updates the reading in the test station.
  ///
  /// - The [updatedReading] parameter represents the updated reading to be inserted or updated in the database.
  /// - The [stationID] parameter is the ID of the test station.
  /// - The [tsID] parameter is the ID of the test station.
  /// - The [context] parameter is the build context.
  /// - The [tableName] parameter is the name of the table in the database.
  /// - The [getReadings] parameter is a function that retrieves the readings from the test station.
  /// - The [setReading] parameter is a function that sets the reading in the test station.
  ///
  /// Returns a [Future] that completes when the update operation is finished.
  ///
  /// Throws an exception if the update operation fails.
  Future<void> updateReadingInTestStation<T>(T updatedReading, int? stationID, String? tsID, BuildContext context, String tableName,
      List<dynamic> Function(TestStation) getReadings, void Function(TestStation, int, T) setReading) async {
    final dbHelper = DatabaseHelper.instance;
    var readingMap = (updatedReading as dynamic).toMap();
    readingMap['testStationID'] = tsID;

    int updateResult = await dbHelper.insertOrUpdateReading(stationID, readingMap, tableName);

    if (updateResult > 0) {
      int index = _testStations.indexWhere((ts) => ts.tsID == tsID);
      if (index != -1) {
        int readingIndex =
            getReadings(_testStations[index]).indexWhere((reading) => (reading as dynamic).stationID == (updatedReading as dynamic).stationID);
        if (readingIndex != -1) {
          setReading(_testStations[index], readingIndex, updatedReading);
          notifyListeners();
        }
      }
    } else {
      // Handle the failure case
    }
  }

  // Check storage permission
  /// Checks the permission for accessing storage.
  ///
  /// This method requests the permission to access storage and prints "Permission granted"
  Future<void> checkPermission() async {
    if (await permission_handler.Permission.storage.request().isGranted) {
      print("Permission granted");
    }
  }

  /// Requests storage permission.
  ///
  /// This method checks the current status of the storage permission and requests it if it is not granted.
  /// It returns a [Future] that completes when the permission request is finished.
  Future<void> requestStoragePermission() async {
    permission_handler.PermissionStatus status = await permission_handler.Permission.storage.status;
    if (!status.isGranted) {
      await permission_handler.Permission.storage.request();
    }
  }

  /// Creates a CSV file containing the data from the test stations and saves or shares it.
  ///
  /// The function converts the test stations into a 2D list and inserts headers for each column.
  /// It then converts the list to a CSV string using the `ListToCsvConverter` class.
  /// The CSV data is saved or shared using the `saveOrShareCSV` function.
  /// If the file is successfully saved or shared, a snackbar is shown with a success message.
  /// If there is an error during the process, a snackbar is shown with an error message.
  ///
  /// The function requires the [BuildContext] parameter to show the snackbar and request storage permission.
  ///
  /// Throws an [Exception] if the platform is not supported (iOS).
  Future<void> createCSV(BuildContext context) async {
    print('createCSV called');

    await requestStoragePermission();

    // Convert the test stations into a 2D list
    List<List<Object?>> tsData = testStations.map((testStation) {
      var plTestLeadNames = testStation.plTestLeadReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var plTestLeadVoltsON = testStation.plTestLeadReadings?.map((reading) {
            return '(${reading.formattedVoltsON})';
          }).join() ??
          '';

      var plTestLeadVoltsOFF = testStation.plTestLeadReadings?.map((reading) {
            return '(${reading.formattedVoltsOFF})';
          }).join() ??
          '';

      var anodeNames = testStation.anodeReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var anodeVoltsON = testStation.anodeReadings?.map((reading) {
            return '(${reading.formattedVoltsON})';
          }).join() ??
          '';

      var anodeVoltsOFF = testStation.anodeReadings?.map((reading) {
            return '(${reading.formattedVoltsOFF})';
          }).join() ??
          '';

      var anodeCurrent = testStation.anodeReadings?.map((reading) {
            return '(${reading.formattedCurrent})';
          }).join() ??
          '';

      var permRefNames = testStation.permRefReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var permRefType = testStation.permRefReadings?.map((reading) {
            return '(${reading.type})';
          }).join() ??
          '';

      var permRefVoltsON = testStation.permRefReadings?.map((reading) {
            return '(${reading.formattedVoltsON})';
          }).join() ??
          '';

      var permRefVoltsOFF = testStation.permRefReadings?.map((reading) {
            return '(${reading.formattedVoltsOFF})';
          }).join() ??
          '';

      var shuntNames = testStation.shuntReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var shuntSideA = testStation.shuntReadings?.map((reading) {
            return '(${reading.sideA})';
          }).join() ??
          '';

      var shuntSideB = testStation.shuntReadings?.map((reading) {
            return '(${reading.sideB})';
          }).join() ??
          '';

      var shuntMV = testStation.shuntReadings?.map((reading) {
            return '(${reading.formattedratioMV})';
          }).join() ??
          '';

      var shuntAmp = testStation.shuntReadings?.map((reading) {
            return '(${reading.formattedratioAMPS})';
          }).join() ??
          '';

      var shuntFactor = testStation.shuntReadings?.map((reading) {
            return '(${reading.formattedfactor})';
          }).join() ??
          '';

      var shuntVDrop = testStation.shuntReadings?.map((reading) {
            return '(${reading.formattedvDrop})';
          }).join() ??
          '';

      var shuntCalculated = testStation.shuntReadings?.map((reading) {
            return '(${reading.formattedcalculated})';
          }).join() ??
          '';

      var riserNames = testStation.riserReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var riserVoltsON = testStation.riserReadings?.map((reading) {
            return '(${reading.formattedVoltsON})';
          }).join() ??
          '';

      var riserVoltsOFF = testStation.riserReadings?.map((reading) {
            return '(${reading.formattedVoltsOFF})';
          }).join() ??
          '';

      var foreignNames = testStation.foreignReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var foreignVoltsON = testStation.foreignReadings?.map((reading) {
            return '(${reading.formattedVoltsON})';
          }).join() ??
          '';

      var foreignVoltsOFF = testStation.foreignReadings?.map((reading) {
            return '(${reading.formattedVoltsOFF})';
          }).join() ??
          '';

      var testLeadNames = testStation.testLeadReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var testLeadVoltsON = testStation.testLeadReadings?.map((reading) {
            return '(${reading.formattedVoltsON})';
          }).join() ??
          '';

      var testLeadVoltsOFF = testStation.testLeadReadings?.map((reading) {
            return '(${reading.formattedVoltsOFF})';
          }).join() ??
          '';

      var couponNames = testStation.couponReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var couponVoltsON = testStation.couponReadings?.map((reading) {
            return '(${reading.formattedVoltsON})';
          }).join() ??
          '';

      var couponVoltsOFF = testStation.couponReadings?.map((reading) {
            return '(${reading.formattedVoltsOFF})';
          }).join() ??
          '';

      var couponCurrent = testStation.couponReadings?.map((reading) {
            return '(${reading.formattedCurrent})';
          }).join() ??
          '';

      var couponConnection = testStation.couponReadings?.map((reading) {
            return '(${reading.connectedTo})';
          }).join() ??
          '';

      var couponType = testStation.couponReadings?.map((reading) {
            return '(${reading.type})';
          }).join() ??
          '';

      var couponSize = testStation.couponReadings?.map((reading) {
            return '(${reading.size})';
          }).join() ??
          '';

      var bondNames = testStation.bondReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var bondSideA = testStation.bondReadings?.map((reading) {
            return '(${reading.sideA})';
          }).join() ??
          '';

      var bondSideB = testStation.bondReadings?.map((reading) {
            return '(${reading.sideB})';
          }).join() ??
          '';

      var bondCurrent = testStation.bondReadings?.map((reading) {
            return '(${reading.formattedCurrent})';
          }).join() ??
          '';

      var isoNames = testStation.isolationReadings?.map((reading) {
            return '(${reading.name})';
          }).join() ??
          '';

      var isoSideA = testStation.isolationReadings?.map((reading) {
            return '(${reading.sideA})';
          }).join() ??
          '';

      var isoSideB = testStation.isolationReadings?.map((reading) {
            return '(${reading.sideB})';
          }).join() ??
          '';

      var isoType = testStation.isolationReadings?.map((reading) {
            return '(${reading.type})';
          }).join() ??
          '';

      var isoShorted = testStation.isolationReadings?.map((reading) {
            return '(${reading.shorted})';
          }).join() ??
          '';

      var isoCurrent = testStation.isolationReadings?.map((reading) {
            return '(${reading.formattedCurrent})';
          }).join() ??
          '';

      return [
        projectModel.createDate,
        projectModel.client,
        projectModel.projectName,
        projectModel.tech,
        testStation.area,
        testStation.tsID,
        testStation.tsstatus,
        testStation.latitude,
        testStation.longitude,
        plTestLeadNames,
        plTestLeadVoltsON,
        plTestLeadVoltsOFF,
        anodeNames,
        anodeVoltsON,
        anodeVoltsOFF,
        anodeCurrent,
        permRefNames,
        permRefType,
        permRefVoltsON,
        permRefVoltsOFF,
        shuntNames,
        shuntSideA,
        shuntSideB,
        shuntMV,
        shuntAmp,
        shuntFactor,
        shuntVDrop,
        shuntCalculated,
        riserNames,
        riserVoltsON,
        riserVoltsOFF,
        foreignNames,
        foreignVoltsON,
        foreignVoltsOFF,
        testLeadNames,
        testLeadVoltsON,
        testLeadVoltsOFF,
        couponNames,
        couponVoltsON,
        couponVoltsOFF,
        couponCurrent,
        couponConnection,
        couponType,
        couponSize,
        bondNames,
        bondSideA,
        bondSideB,
        bondCurrent,
        isoNames,
        isoSideA,
        isoSideB,
        isoType,
        isoShorted,
        isoCurrent,
      ];
    }).toList();

    tsData.insert(0, [
      'Date Created',
      'Client',
      'Project Name',
      'Tech',
      'Area',
      'TS ID',
      'Status',
      'Latitude',
      'Longitude',
      'PL Test Leads (PL TL)',
      'PL TL ON (V)',
      'PL TL OFF (V)',
      'Anodes (AD)',
      'AD ON (V)',
      'AD OFF (V)',
      'AD Current (A)',
      'Perm Ref Cells (PR)',
      'PR Type',
      'PR ON (V)',
      'PR OFF (V)',
      'Shunts (SH)',
      'SH Side A',
      'SH Side B',
      'SH mV',
      'SH Amps',
      'SH Factor',
      'SH V Drop',
      'SH Calculated',
      'Risers (RI)',
      'RI ON (V)',
      'RI OFF (V)',
      'Foreign Structures (FS)',
      'FS ON (V)',
      'FS OFF (V)',
      'Test Leads (TL)',
      'TL ON (V)',
      'TL OFF (V)',
      'Coupons (CO)',
      'CO ON (V)',
      'CO OFF (V)',
      'CO Current (A)',
      'CO Connection',
      'CO Type',
      'CO Size',
      'Bonds (BO)',
      'BO Side A',
      'BO Side B',
      'BO Current (A)',
      'Isolations (IK)',
      'IK Side A',
      'IK Side B',
      'IK Type',
      'IK Shorted',
      'IK Current (A)',
    ]);

    String csvData = const ListToCsvConverter().convert(tsData);

    // Save or share the CSV file
    try {
      File? file = await saveOrShareCSV(csvData, context);
      if (file != null) {
        print('CSV file saved or shared at ${file.path}');

        // Provide feedback using a snackbar
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV file saved or shared successfully!')));
      }
    } catch (e) {
      print('Failed to save or share file: $e');

      // Provide feedback using a snackbar in case of error
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save or share CSV file.')));
    }
  }

  /// Retrieves the path of the downloads directory.
  ///
  /// On Android, the downloads directory is '/storage/emulated/0/Download'.
  /// On iOS, there isn't a user-accessible file system, so an exception is thrown.
  ///
  /// Returns the path of the downloads directory.
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

  /// Saves or shares the provided CSV data.
  ///
  /// This method takes the [csvData] as a parameter and saves it as a CSV file in the device's downloads directory.
  /// It also provides an option to share the CSV file with other apps.
  ///
  /// The [context] parameter is required to show a dialog asking the user whether they want to share the file or not.
  ///
  /// Returns the [File] object representing the saved CSV file if successful, otherwise returns null.
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
      File file = File('$directoryPath/CP_Inspection_$formattedDate.csv');
      print("Attempting to save to: ${file.path}");

      await file.create();
      await file.writeAsString(csvData, mode: FileMode.write);
      print("File successfully written to: ${file.path}");

      bool shouldShare = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Share File?'),
                content: const Text('Do you want to share the CSV file?'),
                actions: [
                  TextButton(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('Yes'),
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
        Share.shareXFiles([XFile(file.path)], subject: 'CP Inspection CSV Data', text: 'Here is the exported CP Inspection data.');
      }

      return file;
    } catch (e) {
      print("Error saving or sharing CSV: $e");
      return null;
    }
  }
}
