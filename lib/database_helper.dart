// ignore_for_file: prefer_const_declarations, non_constant_identifier_names, avoid_print
// ignore: import_of_legacy_library_into_null_safe

// To Pull Database from Device:
// adb -d shell "run-as com.acuren523.asset_inspections cat /data/data/com.acuren523.asset_inspections/databases/project_database1.db" > /Users/darrell/Desktop/Project_Database.db

// ignore: import_of_legacy_library_into_null_safe

// To Pull Database from Device:
// adb -d shell "run-as com.acuren523.asset_inspections cat /data/data/com.acuren523.asset_inspections/databases/project_database1.db" > /Users/darrell/Desktop/Project_Database.db

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as pth;
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:sqflite/sqflite.dart';

import 'package:asset_inspections/Models/camera_model.dart';

import 'Models/project_model.dart';
import 'Models/ts_models.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Single constant for the projectNames column for Rectifiers and TestStatoins tables
  static final columnProjectNameID = 'projectID';

  // Single constant for the TestStations ID (in the database) column for the Containers tables
  static final columnStationID = 'stationID';

  //Single constant for the TestStations ID (user defined) column for the Containers tables
  static final columnTestStationID = 'testStationID';

  // Dynamic rectifier table based on fullProjectName
  String rectifierTableName() => 'Rectifiers';
  // Rectifier Table Columns (static constants)
  static final columnId = 'id';
  static final columnArea = 'area';
  static final columnServiceTag = 'serviceTag';
  static final columnStatus = 'status';
  static final columnUse = 'use';
  static final columnMaxVoltage = 'maxVoltage';
  static final columnMaxAmps = 'maxAmps';
  static final columnLatitude = 'latitude';
  static final columnLongitude = 'longitude';
  static final columnPanelMeterVoltage = 'panelMeterVoltage';
  static final columnMultimeterVoltage = 'multimeterVoltage';
  static final columnVoltageReadingComments = 'voltageReadingComments';
  static final columnPanelMeterAmps = 'panelMeterAmps';
  static final columnAmmeterAmps = 'ammeterAmps';
  static final columnCurrentReadingComments = 'currentReadingComments';
  static final columnCurrentRatio = 'currentRatio';
  static final columnVoltageRatio = 'voltageRatio';
  static final columnVoltageDrop = 'voltageDrop';
  static final columnCalculatedCurrent = 'calculatedCurrent';
  static final columnCourseTapSettingFound = 'courseTapSettingFound';
  static final columnMediumTapSettingFound = 'mediumTapSettingFound';
  static final columnFineTapSettingFound = 'fineTapSettingFound';
  static final columnReason = 'reason';
  static final columnOilLevel = 'oilLevel';
  static final columnOilLevelComments = 'oilLevelComments';
  static final columnOilLevelFindings = 'oilLevelFindings';
  static final columnDeviceDamage = 'deviceDamage';
  static final columnDeviceDamageComments = 'deviceDamageComments';
  static final columnDeviceDamageFindings = 'deviceDamageFindings';
  static final columnPolarityCondition = 'polarityCondition';
  static final columnPolarityConditionComments = 'polarityConditionComments';
  static final columnCircuitBreakers = 'circuitBreakers';
  static final columnCircuitBreakersComments = 'circuitBreakersComments';
  static final columnFusesWiring = 'fusesWiring';
  static final columnFusesWiringComments = 'fusesWiringComments';
  static final columnLightningArrestors = 'lightningArrestors';
  static final columnLightningArrestorsComments = 'lightningArrestorsComments';
  static final columnVentScreens = 'ventScreens';
  static final columnVentScreensComments = 'ventScreensComments';
  static final columnBreathers = 'breathers';
  static final columnBreathersComments = 'breathersComments';
  static final columnRemoveObstructions = 'removeObstructions';
  static final columnRemoveObstructionsComments = 'removeObstructionsComments';
  static final columnCleaned = 'cleaned';
  static final columnCleanedComments = 'cleanedComments';
  static final columnTightened = 'tightened';
  static final columnTightenedComments = 'tightenedComments';
  static final columnRectifierPicturePath = 'picturePath';

  String teststationTableName() => 'TestStations';
  // TestStation Table Columns (static constants)
  static final columnID = 'id';
  static final columnTSArea = 'area';
  static final columnTsID = 'tsID';
  static final columnTSStatus = 'status';
  static final columnTSLatitude = 'latitude';
  static final columnTSLongitude = 'longitude';
  static final columnTestStationPicturePath = 'picturePath';

  String defaultnamesTableName() => 'DefaultNames';
  // DefaultNames Table Columns (static constants)
  static final columnDefaultNameID = 'id';
  static final columnDefaultNameType = 'type';
  static final columnDefaultNameName = 'name';

  // Dynamic PLTestLeadContainers table based on TestStation ID
  String plTestLeadContainers() => 'PLTestLeadContainers';
  // PLTestLeadContainers Table Columns (static constants)
  static final columnPLTestLeadContainerID = 'id';
  static final columnPLTestLeadContainerTSid = 'stationID';
  static final columnPLTestLeadContainerName = 'name';
  static final columnPLTestLeadContainerVoltsON = 'voltsON';
  static final columnPLTestLeadContainerVoltsON_Date = 'voltsON_Date';
  static final columnPLTestLeadContainerVoltsOFF = 'voltsOFF';
  static final columnPLTestLeadContainerVoltsOFF_Date = 'voltsOFF_Date';
  static final columnPLTestLeadContainerorder_index = 'order_index';

  // Dynamic PermRefContainers table based on TestStation ID
  String permRefContainers() => 'PermRefContainers';
  // PermRefContainers Table Columns (static constants)
  static final columnPermRefContainerID = 'id';
  static final columnPermRefContainerTSid = 'stationID';
  static final columnPermRefContainerName = 'name';
  static final columnPermRefContainerVoltsON = 'voltsON';
  static final columnPermRefContainerVoltsON_Date = 'voltsON_Date';
  static final columnPermRefContainerVoltsOFF = 'voltsOFF';
  static final columnPermRefContainerVoltsOFF_Date = 'voltsOFF_Date';
  static final columnPermRefContainerType = 'type';
  static final columnPermRefContainerOrderIndex = 'order_index';

  // Dynamic AnodeContainers table based on TestStation ID
  String anodeContainers() => 'AnodeContainers';
  // AnodeContainers Table Columns (static constants)
  static final columnAnodeContainerID = 'id';
  static final columnAnodeContainerTSid = 'stationID';
  static final columnAnodeContainerName = 'name';
  static final columnAnodeContainerVoltsON = 'voltsON';
  static final columnAnodeContainerVoltsON_Date = 'voltsON_Date';
  static final columnAnodeContainerVoltsOFF = 'voltsOFF';
  static final columnAnodeContainerVoltsOFF_Date = 'voltsOFF_Date';
  static final columnAnodeContainerCurrent = 'current';
  static final columnAnodeContainerCurrent_Date = 'current_Date';
  static final columnAnodeContainerOrderIndex = 'order_index';

  // Dynamic TestLeadContainers table based on TestStation ID
  String testLeadContainers() => 'TestLeadContainers';
  // TestLeadContainers Table Columns (static constants)
  static final columnTestLeadContainerID = 'id';
  static final columnTestLeadContainerTSid = 'stationID';
  static final columnTestLeadContainerName = 'name';
  static final columnTestLeadContainerVoltsON = 'voltsON';
  static final columnTestLeadContainerVoltsON_Date = 'voltsON_Date';
  static final columnTestLeadContainerVoltsOFF = 'voltsOFF';
  static final columnTestLeadContainerVoltsOFF_Date = 'voltsOFF_Date';
  static final columnTestLeadContainerOrderIndex = 'order_index';

  // Dynamic RiserContainers table based on TestStation ID
  String riserContainers() => 'RiserContainers';
  // RiserContainers Table Columns (static constants)
  static final columnRiserContainerID = 'id';
  static final columnRiserContainerTSid = 'stationID';
  static final columnRiserContainerName = 'name';
  static final columnRiserContainerVoltsON = 'voltsON';
  static final columnRiserContainerVoltsON_Date = 'voltsON_Date';
  static final columnRiserContainerVoltsOFF = 'voltsOFF';
  static final columnRiserContainerVoltsOFF_Date = 'voltsOFF_Date';
  static final columnRiserContainerOrderIndex = 'order_index';

  // Dynamic ForeignContainers table based on TestStation ID
  String foreignContainers() => 'ForeignContainers';
  // ForeignContainers Table Columns (static constants)
  static final columnForeignContainerID = 'id';
  static final columnForeignContainerTSid = 'stationID';
  static final columnForeignContainerName = 'name';
  static final columnForeignContainerVoltsON = 'voltsON';
  static final columnForeignContainerVoltsON_Date = 'voltsON_Date';
  static final columnForeignContainerVoltsOFF = 'voltsOFF';
  static final columnForeignContainerVoltsOFF_Date = 'voltsOFF_Date';
  static final columnForeignContainerOrderIndex = 'order_index';

  // Dynamic CouponContainers table based on TestStation ID
  String couponContainers() => 'CouponContainers';
  // CouponContainers Table Columns (static constants)
  static final columnCouponContainerID = 'id';
  static final columnCouponContainerTSid = 'stationID';
  static final columnCouponContainerName = 'name';
  static final columnCouponContainerVoltsON = 'voltsON';
  static final columnCouponContainerVoltsON_Date = 'voltsON_Date';
  static final columnCouponContainerVoltsOFF = 'voltsOFF';
  static final columnCouponContainerVoltsOFF_Date = 'voltsOFF_Date';
  static final columnCouponContainerCurrent = 'current';
  static final columnCouponContainerCurrent_Date = 'current_Date';
  static final columnCouponContainerConnectedTo = 'connected_to';
  static final columnCouponContainerCouponType = 'coupon_type';
  static final columnCouponContainerCouponSize = 'coupon_size';
  static final columnCouponContainerOrderIndex = 'order_index';

  // Dynamic ShuntContainers table based on TestStation ID
  String shuntContainers() => 'ShuntContainers';
  // ShuntContainers Table Columns (static constants)
  static final columnShuntContainerID = 'id';
  static final columnShuntContainerTSid = 'stationID';
  static final columnShuntContainerName = 'name';
  static final columnShuntContainerSideA = 'side_a';
  static final columnShuntContainerSideB = 'side_b';
  static final columnShuntContainerRatioMV = 'ratio_mv';
  static final columnShuntContainerRatioCurrent = 'ratio_current';
  static final columnShuntContainerFactor = 'factor';
  static final columnShuntContainerVoltageDrop = 'voltage_drop';
  static final columnShuntContainerVoltageDrop_Date = 'voltage_drop_Date';
  static final columnShuntContainerCalculated = 'calculated';
  static final columnShuntContainerCalculated_Date = 'calculated_Date';
  static final columnShuntContainerOrderIndex = 'order_index';

  // Dynamic IsoContainers table based on TestStation ID
  String isolationContainers() => 'IsolationContainers';
  // IsoContainers Table Columns (static constants)
  static final columnIsoContainerID = 'id';
  static final columnIsoContainerTSid = 'stationID';
  static final columnIsoContainerName = 'name';
  static final columnIsoContainerSideA = 'side_a';
  static final columnIsoContainerSideB = 'side_b';
  static final columnIsoContainerType = 'iso_type';
  static final columnIsoContainerShorted = 'iso_shorted';
  static final columnIsoContainerShorted_Date = 'iso_shorted_Date';
  static final columnIsoContainerCurrent = 'iso_current';
  static final columnIsoContainerCurrent_Date = 'iso_current_Date';
  static final columnIsoContainerOrderIndex = 'order_index';

  // Dynamic BondContainers table based on TestStation ID
  String bondContainers() => 'BondContainers';
  // BondContainers Table Columns (static constants)
  static final columnBondContainerID = 'id';
  static final columnBondContainerTSid = 'stationID';
  static final columnBondContainerName = 'name';
  static final columnBondContainerSideA = 'side_a';
  static final columnBondContainerSideB = 'side_b';
  static final columnBondContainerCurrent = 'current';
  static final columnBondContainerCurrent_Date = 'current_Date';
  static final columnBondContainerOrderIndex = 'order_index';

  // Private constructor
  DatabaseHelper._privateConstructor();

  /// Returns the database instance asynchronously.
  /// If the database instance is null, it initializes the database using [_initDatabase] method.
  /// Returns the initialized database instance.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  static const String databaseName = 'project_database1.db';

  /// Initializes the database by creating or opening it.
  /// Returns a Future that completes with the initialized database.
  /// Throws a [MissingPluginException] if the required plugin is missing.
  /// Throws a [DatabaseException] if there is an error with the database.
  Future<Database> _initDatabase() async {
    String path = pth.join(await getDatabasesPath(), databaseName);
    try {
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) {
          enableForeignKeys(db);
        },
      );
    } on MissingPluginException catch (e) {
      print('MissingPluginException: ${e.message}');
      rethrow;
    } on DatabaseException catch (e) {
      print('DatabaseException: $e');
      rethrow;
    }
  }

  /// Enables foreign key constraints in the specified [db].
  void enableForeignKeys(Database db) {
    db.execute('PRAGMA foreign_keys = ON');
  }

  /// Executes the necessary operations when creating the database.
  ///
  /// This method is called when the database is being created or upgraded to a new version.
  /// It creates the project names table in the database.
  ///
  /// Parameters:
  /// - db: The database instance.
  /// - version: The new version of the database.
  ///
  /// Returns: A future that completes when the operations are finished.
  Future<void> _onCreate(Database db, int version) async {
    await _createProjectNamesTable(db);
  }

  /// Creates the projectNames table in the database if it does not already exist.
  ///
  /// The table has the following columns:
  /// - id: INTEGER (Primary Key)
  /// - client: TEXT (Not Null)
  /// - projectName: TEXT (Not Null)
  /// - tech: TEXT (Not Null)
  /// - createDate: TEXT (Not Null)
  /// - fullName: TEXT (Not Null)
  /// - lastLoaded: TIMESTAMP (Default: CURRENT_TIMESTAMP)
  ///
  /// Parameters:
  /// - db: The database instance to execute the SQL query on.
  ///
  /// Returns:
  /// - A Future that completes when the table is created.
  Future<void> _createProjectNamesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projectNames (
        id INTEGER PRIMARY KEY,
        client TEXT NOT NULL,
        projectName TEXT NOT NULL,
        tech TEXT NOT NULL,
        createDate TEXT NOT NULL,
        fullName TEXT NOT NULL,
        lastLoaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
  }

  /// Creates the necessary tables for the project in the database.
  /// This method executes SQL queries to create tables for Rectifiers, DefaultNames, and TestStations.
  /// It also creates tables for referenced tables such as PermRefContainers, AnodeContainers, PLTestLeadContainers, etc.
  /// Each table has its own set of columns and foreign key references.
  /// Additionally, triggers are created to update the corresponding test station ID in the referenced tables when the test station ID is updated in the TestStations table.
  Future<void> createTablesForProject() async {
    Database db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Rectifiers (
        id INTEGER PRIMARY KEY,
        $columnProjectNameID INTEGER,
        area TEXT,
        serviceTag TEXT NOT NULL,
        status TEXT,
        use TEXT,
        maxVoltage REAL,
        maxAmps REAL,
        latitude REAL,
        longitude REAL,
        panelMeterVoltage REAL,
        multimeterVoltage REAL,
        voltageReadingComments TEXT,
        panelMeterAmps REAL,
        ammeterAmps REAL,
        currentReadingComments TEXT,
        currentRatio REAL,
        voltageRatio REAL,
        voltageDrop REAL,
        calculatedCurrent REAL,
        courseTapSettingFound TEXT,
        mediumTapSettingFound TEXT,
        fineTapSettingFound TEXT,
        reason TEXT,
        oilLevel INTEGER,
        oilLevelComments TEXT,
        oilLevelFindings TEXT,
        deviceDamage INTEGER,
        deviceDamageComments TEXT,
        deviceDamageFindings TEXT,
        polarityCondition INTEGER,
        polarityConditionComments TEXT,
        circuitBreakers INTEGER,
        circuitBreakersComments TEXT,
        fusesWiring INTEGER,
        fusesWiringComments TEXT,
        lightningArrestors INTEGER,
        lightningArrestorsComments TEXT,
        ventScreens INTEGER,
        ventScreensComments TEXT,
        breathers INTEGER,
        breathersComments TEXT,
        removeObstructions INTEGER,
        removeObstructionsComments TEXT,
        cleaned INTEGER,
        cleanedComments TEXT,
        tightened INTEGER,
        tightenedComments TEXT,
        picturePath TEXT,
        FOREIGN KEY ($columnProjectNameID) REFERENCES projectNames (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS DefaultNames (
        id INTEGER PRIMARY KEY,
        $columnProjectNameID INTEGER,
        type TEXT,
        name TEXT,
        FOREIGN KEY ($columnProjectNameID) REFERENCES projectNames (id)
      )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS TestStations (
        id INTEGER PRIMARY KEY,
        $columnProjectNameID INTEGER,
        area TEXT,
        tsID TEXT,
        status TEXT,
        latitude REAL,
        longitude REAL,
        officeNotes TEXT,
        fieldNotes TEXT,
        picturePath TEXT,
        FOREIGN KEY ($columnProjectNameID) REFERENCES projectNames (id) ON DELETE CASCADE
      )
    ''');

    // List of table names that reference TestStations
    List<String> referencedTables = [
      'PermRefContainers',
      'AnodeContainers',
      'PLTestLeadContainers',
      'TestLeadContainers',
      'RiserContainers',
      'ForeignContainers',
      'CouponContainers',
      'ShuntContainers',
      'IsolationContainers',
      'BondContainers'
    ];

    // Define the table creation queries for each table
    Map<String, String> tableCreationQueries = {
      'AnodeContainers': '''
      CREATE TABLE IF NOT EXISTS AnodeContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        voltsON REAL,
        voltsON_Date TEXT,
        voltsOFF REAL,
        voltsOFF_Date TEXT,
        current REAL,
        current_Date TEXT,
        waveForm TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'BondContainers': '''
      CREATE TABLE IF NOT EXISTS BondContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        side_a TEXT,
        side_b TEXT,
        current REAL,
        current_Date TEXT,
        waveForm TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'CouponContainers': '''
      CREATE TABLE IF NOT EXISTS CouponContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        voltsON REAL,
        voltsON_Date TEXT,
        voltsOFF REAL,
        voltsOFF_Date TEXT,
        current REAL,
        current_Date TEXT,
        connected_to TEXT,
        type TEXT,
        coupon_size TEXT,
        waveForm TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'ForeignContainers': '''
      CREATE TABLE IF NOT EXISTS ForeignContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        voltsON REAL,
        voltsON_Date TEXT,
        voltsOFF REAL,
        voltsOFF_Date TEXT,
        waveForm TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'IsolationContainers': '''
      CREATE TABLE IF NOT EXISTS IsolationContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        side_a TEXT,
        side_b TEXT,
        type TEXT,
        status TEXT,
        status_Date TEXT,
        current REAL,
        current_Date TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'PermRefContainers': '''
      CREATE TABLE IF NOT EXISTS PermRefContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        type TEXT,
        voltsON REAL,
        voltsON_Date TEXT,
        voltsOFF REAL,
        voltsOFF_Date TEXT,
        waveForm TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'PLTestLeadContainers': '''
      CREATE TABLE IF NOT EXISTS PLTestLeadContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        voltsON REAL,
        voltsON_Date TEXT,
        voltsOFF REAL,
        voltsOFF_Date TEXT,
        waveForm TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'RiserContainers': '''
      CREATE TABLE IF NOT EXISTS RiserContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        voltsON REAL,
        voltsON_Date TEXT,
        voltsOFF REAL,
        voltsOFF_Date TEXT,
        pipe_Diameter REAL,
        waveForm TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'ShuntContainers': '''
      CREATE TABLE IF NOT EXISTS ShuntContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,

        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        side_a TEXT,
        side_b TEXT,
        ratio_mv REAL,
        ratio_current REAL,
        factor REAL,
        voltage_drop REAL,
        voltage_drop_Date TEXT,
        calculated REAL,
        calculated_Date TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
      'TestLeadContainers': '''
      CREATE TABLE IF NOT EXISTS TestLeadContainers (
        id INTEGER PRIMARY KEY,
        $columnStationID INTEGER,
        $columnTestStationID TEXT,
        order_index INTEGER,
        name TEXT,
        label TEXT,
        voltsAC REAL,
        voltsACDate TEXT,
        voltsON REAL,
        voltsON_Date TEXT,
        voltsOFF REAL,
        voltsOFF_Date TEXT,
        waveForm TEXT,

          FOREIGN KEY (stationID) REFERENCES TestStations (id) ON DELETE CASCADE
      )
    ''',
    };

    // Create each table and its trigger
    for (String tableName in referencedTables) {
      // Create the table
      await db.execute(tableCreationQueries[tableName]!);

      // Create the trigger for this table
      await db.execute('''
      CREATE TRIGGER IF NOT EXISTS update_${tableName}_tsID
      AFTER UPDATE OF tsID ON TestStations
      FOR EACH ROW
      BEGIN
        UPDATE $tableName
        SET $columnTestStationID = NEW.tsID
        WHERE $columnTestStationID = OLD.tsID;
      END;
    ''');
    }
  }

  Future<void> createTableForCameraSettings() async {
    Database db = await database;
    await db.execute('''
    CREATE TABLE IF NOT EXISTS CameraSettings (
      id INTEGER PRIMARY KEY,
      isMapOverlayVisible INTEGER NOT NULL,
      mapPosition INTEGER,
      dataPosition INTEGER,
      mapType TEXT NOT NULL,
      mapOpacity REAL NOT NULL,
      mapSize REAL NOT NULL,
      mapScale REAL NOT NULL,
      isDataOverlayVisible INTEGER NOT NULL,
      selectedFontStyle TEXT NOT NULL,
      selectedFontColor TEXT NOT NULL,
      selectedFontSize REAL NOT NULL,
      selectedDateFormat TEXT NOT NULL,
      selectedLocationFormat TEXT NOT NULL,
      dataDisplayOrder TEXT
    )
  ''');
  }

  Future<void> requestStoragePermission() async {
    permission_handler.PermissionStatus status = await permission_handler.Permission.storage.status;
    if (!status.isGranted) {
      await permission_handler.Permission.storage.request();
    }
  }

  Future<void> copyDatabaseToDownloads() async {
    // Check storage permission
    await requestStoragePermission();

    // Get the current database path
    String currentPath = pth.join(await getDatabasesPath(), 'project_database1.db');

    // Get the Downloads directory path
    Directory downloadsDirectory = Directory('/storage/emulated/0/Download');
    String downloadsPath = pth.join(downloadsDirectory.path, 'project_database1.db');

    // Ensure the Downloads directory exists
    if (!downloadsDirectory.existsSync()) {
      downloadsDirectory.createSync(recursive: true);
    }

    // Copy the file from the current location to the Downloads directory
    try {
      File newFile = await File(currentPath).copy(downloadsPath);
      print('Database copied to Downloads: ${newFile.path}');
    } catch (e) {
      print('Failed to copy database: $e');
    }
  }

  /// Retrieves the latest project from the 'projectNames' table in the database.
  /// Returns a [Project] object representing the latest project, or null if no project is found.
  Future<Project?> getLatestProject() async {
    final db = await database;
    final result = await db.query(
      'projectNames',
      orderBy: 'lastLoaded DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Project.fromMap(result.first);
    } else {
      return null;
    }
  }

  /// Inserts a project name into the database.
  ///
  /// Returns the ID of the inserted project name.
  /// Throws an exception if the insertion fails.
  Future<int> insertProjectName(Map<String, dynamic> projectData) async {
    final db = await database;

    try {
      int id = await db.insert('projectNames', projectData);
      return int.parse(id.toString());
    } catch (e) {
      throw Exception('Failed to insert project name: $e');
    }
  }

  /// Retrieves the project name from the 'projectNames' table in the database
  /// based on the given [id].
  ///
  /// Returns a [Map<String, dynamic>] containing the project name if found,
  /// otherwise returns null.
  Future<Map<String, dynamic>?> getProjectNameById(int id) async {
    // Open the database connection.
    final db = await database;
    // Execute a query to retrieve the project name with the given id.
    final result = await db.query(
      'projectNames',
      // The 'where' and 'whereArgs' parameters ensure that only the desired row is returned
      where: 'id = ?',
      whereArgs: [id],
      limit: 1, // The 'limit' parameter ensures that at most one row is returned.
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> updateTestStationPicture(int stationID, String picturePath) async {
    final db = await database;
    await db.update(
      'TestStations',
      {'picturePath': picturePath},
      where: 'id = ?',
      whereArgs: [stationID],
    );
  }

  /// Retrieves the project ID from the database based on the given [projectID].
  /// Returns the project ID as an [int] if found, otherwise returns null.
  Future<int?> getProjectID(int projectID) async {
    final db = await database;
    final projects = await db.query(
      'projectNames',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [projectID],
    );
    return projects.isNotEmpty ? projects.first['id'] as int? : null;
  }

  /// Fetches a list of [Project] objects from the 'projectNames' table in the database.
  /// Returns a [Future] that resolves to a list of [Project] objects.
  /// Each [Project] object contains the following properties:
  /// - id: The ID of the project (int).
  /// - client: The client name (String).
  /// - projectName: The project name (String).
  /// - tech: The name of the technician (String).
  /// - createDate: The creation date of the project (String).
  Future<List<Project>> fetchProjectNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('projectNames');
    return maps.map((map) {
      return Project(
        id: map['id'] as int? ?? 0,
        client: map['client'] as String? ?? 'Default Client',
        projectName: map['projectName'] as String? ?? 'Default Project Name',
        tech: map['tech'] as String? ?? 'Default Tech',
        createDate: map['createDate'] as String? ?? 'Default Date',
      );
    }).toList();
  }

  /// Updates the last loaded date and time for a specific project in the database.
  ///
  /// The [projectId] parameter specifies the ID of the project to update.
  /// The [formattedDateTime] parameter specifies the formatted date and time to set as the last loaded value.
  ///
  /// Throws an [Exception] if no rows are updated during the transaction.
  /// Throws an [Exception] if the update operation fails.
  Future<void> updateLastLoaded(int projectId, String formattedDateTime) async {
    final db = await openDatabase(databaseName);

    const tableName = 'projectNames';
    const idColumn = 'id';
    const lastLoadedColumn = 'lastLoaded';

    try {
      await db.transaction((txn) async {
        final updateCount = await txn.rawUpdate(
          'UPDATE $tableName SET $lastLoadedColumn = ? WHERE $idColumn = ?',
          [formattedDateTime, projectId],
        );

        if (updateCount == 0) {
          throw Exception('No rows updated');
        }
      });
    } catch (e) {
      throw Exception('Failed to update lastLoaded: $e');
    }
  }

  /// Deletes a project name from the database.
  ///
  /// The [fullProjectName] parameter specifies the full name of the project to be deleted.
  /// This function deletes the project name from the 'projectNames' table in the database.
  /// If an error occurs during the deletion process, the error is caught and logged.
  Future<void> deleteProjectName(String fullProjectName) async {
    final db = await database;
    try {
      await db.delete('projectNames', where: 'fullName = ?', whereArgs: [fullProjectName]);
    } catch (e) {
      // Handle exceptions, e.g. by logging or rethrowing.
      print('Error deleting project name: $e');
    }
  }

  Future<int> deleteReading(String tableName, int stationID, int orderIndex) async {
    if (kDebugMode) {
      print('Deleting reading from $tableName where stationID=$stationID and orderIndex=$orderIndex');
    }

    Database db = await database;
    int deletedRows = await db.delete(
      tableName,
      where: 'stationID = ? AND order_index = ?',
      whereArgs: [stationID, orderIndex],
    );

    if (kDebugMode) {
      print('Deleted $deletedRows rows from $tableName');
    }

    return deletedRows;
  }

  // TODO: Add cascade deletion for when a project is deleted, it deletes all tables that reference it
  // {fullProjectName}rectifiers naming convention isn't used anymore.
  Future<void> dropProjectTables(String fullProjectName) async {
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS ${fullProjectName}rectifiers');
  }

  /// Queries the rectifier table in the database for a specific service tag.
  ///
  /// Returns a map containing the first row of the query result if it is not empty,
  /// otherwise returns null.
  ///
  /// Parameters:
  /// - fullProjectName: The full name of the project.
  /// - serviceTag: The service tag to search for.
  ///
  /// Returns:
  /// A map containing the first row of the query result if it is not empty,
  /// otherwise returns null.
  Future<Map<String, dynamic>?> queryRectifierByServiceTag(String fullProjectName, String serviceTag) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      rectifierTableName(),
      where: 'serviceTag = ?',
      whereArgs: [serviceTag],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Queries the test station by project ID and test station ID.
  ///
  /// Returns a map containing the first row of the query result, or null if no rows are found.
  ///
  /// Parameters:
  /// - projectID: The ID of the project.
  /// - tsID: The ID of the test station.
  ///
  /// Returns:
  /// A map containing the first row of the query result, or null if no rows are found.
  Future<Map<String, dynamic>?> queryTestStationBytsID(int projectID, String tsID) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      teststationTableName(),
      where: 'tsID = ?',
      whereArgs: [tsID],
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Updates a rectifier in the database.
  ///
  /// The [fullProjectName] parameter specifies the full name of the project.
  /// The [row] parameter is a map containing the updated values for the rectifier.
  /// The rectifier is identified by its service tag.
  ///
  /// Returns a Future that completes with the number of rows affected by the update operation.
  Future<int> updateRectifier(String fullProjectName, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(rectifierTableName(), row, where: 'serviceTag = ?', whereArgs: [row['serviceTag']]);
  }

  /// Updates the test station in the database with the given [row] data.
  /// The [fullProjectName] parameter is used to identify the project.
  /// The [row] parameter is a map containing the updated data for the test station.
  /// The method serializes the reading lists to JSON strings before updating the database.
  /// Returns the number of rows affected by the update operation.
  Future<int> updateTestStation(String fullProjectName, Map<String, dynamic> row) async {
    final db = await database;

    // Serialize the reading lists to JSON strings before updating the database.
    if (row['plTestLeadReadings'] != null) {
      List<Map<String, dynamic>> plTestLeadReadingsMapList =
          (row['plTestLeadReadings'] as List<PLTestLeadReading>).map((reading) => reading.toMap()).toList();
      row['plTestLeadReadings'] = jsonEncode(plTestLeadReadingsMapList);
    }

    if (row['permRefReadings'] != null) {
      List<Map<String, dynamic>> permRefReadingsMapList = (row['permRefReadings'] as List<PermRefReading>).map((reading) => reading.toMap()).toList();
      row['permRefReadings'] = jsonEncode(permRefReadingsMapList);
    }

    if (row['isoReadings'] != null) {
      List<Map<String, dynamic>> isoReadingsMapList = (row['isoReadings'] as List<IsolationReading>).map((reading) => reading.toMap()).toList();
      row['isoReadings'] = jsonEncode(isoReadingsMapList);
    }

    if (row['bondReadings'] != null) {
      List<Map<String, dynamic>> bondReadingsMapList = (row['bondReadings'] as List<BondReading>).map((reading) => reading.toMap()).toList();
      row['bondReadings'] = jsonEncode(bondReadingsMapList);
    }

    if (row['anodeReadings'] != null) {
      List<Map<String, dynamic>> anodeReadingsMapList = (row['anodeReadings'] as List<AnodeReading>).map((reading) => reading.toMap()).toList();
      row['anodeReadings'] = jsonEncode(anodeReadingsMapList);
    }

    if (row['testLeadReadings'] != null) {
      List<Map<String, dynamic>> testLeadReadingsMapList =
          (row['testLeadReadings'] as List<TestLeadReading>).map((reading) => reading.toMap()).toList();
      row['testLeadReadings'] = jsonEncode(testLeadReadingsMapList);
    }

    if (row['riserReadings'] != null) {
      List<Map<String, dynamic>> riserReadingsMapList = (row['riserReadings'] as List<RiserReading>).map((reading) => reading.toMap()).toList();
      row['riserReadings'] = jsonEncode(riserReadingsMapList);
    }

    if (row['foreignReadings'] != null) {
      List<Map<String, dynamic>> foreignReadingsMapList = (row['foreignReadings'] as List<ForeignReading>).map((reading) => reading.toMap()).toList();
      row['foreignReadings'] = jsonEncode(foreignReadingsMapList);
    }

    if (row['couponReadings'] != null) {
      List<Map<String, dynamic>> couponReadingsMapList = (row['couponReadings'] as List<CouponReading>).map((reading) => reading.toMap()).toList();
      row['couponReadings'] = jsonEncode(couponReadingsMapList);
    }

    if (row['shuntReadings'] != null) {
      List<Map<String, dynamic>> shuntReadingsMapList = (row['shuntReadings'] as List<ShuntReading>).map((reading) => reading.toMap()).toList();
      row['shuntReadings'] = jsonEncode(shuntReadingsMapList);
    }

    return await db.update(
      teststationTableName(),
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  /// Deletes a rectifier from the database.
  ///
  /// The [fullProjectName] parameter specifies the full name of the project.
  /// The [serviceTag] parameter specifies the service tag of the rectifier to be deleted.
  ///
  /// Returns a [Future] that completes with the number of rows affected by the deletion.
  Future<int> deleteRectifier(String fullProjectName, String serviceTag) async {
    final db = await database;
    return await db.delete(rectifierTableName(), where: 'serviceTag = ?', whereArgs: [serviceTag]);
  }

  /// Deletes a test station from the database.
  ///
  /// [fullProjectName] - The full name of the project.
  /// [id] - The ID of the test station to delete.
  ///
  /// Returns the number of rows affected.
  Future<int> deleteTestStation(String fullProjectName, int id) async {
    final db = await database;
    return await db.delete(teststationTableName(), where: 'id = ?', whereArgs: [id]);
  }

  /// Inserts a rectifier into the database.
  ///
  /// [row] - A map containing the rectifier data.
  ///
  /// Returns the ID of the inserted rectifier.
  Future<int> insertRectifier(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('Rectifiers', row);
  }

  Future<void> insertMultipleRectifiers(List<Map<String, dynamic>> rows) async {
    final db = await database;

    await db.transaction((txn) async {
      for (var row in rows) {
        await txn.insert('Rectifiers', row);
      }
    });
  }

  /// Inserts a test station into the database.
  ///
  /// [row] - A map containing the test station data.
  ///
  /// Returns the ID of the inserted test station.
  Future<int> insertTestStation(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('TestStations', row);
  }

  /// Inserts multiple test stations into the database using a CSV import.
  ///
  /// [rows] - A list of maps, where each map contains the data for a test station.
  Future<void> insertMultipleTestStations(List<Map<String, dynamic>> rows) async {
    final db = await database;

    await db.transaction((txn) async {
      for (var row in rows) {
        await txn.insert('TestStations', row);
      }
    });
  }

  /// Queries the list of rectifiers for a specific project.
  ///
  /// [projectID] - The ID of the project.
  ///
  /// Returns a list of maps, where each map represents a rectifier.
  Future<List<Map<String, dynamic>>> queryRectifiersByProjectID(int projectID) async {
    final db = await database;
    return await db.query('Rectifiers', where: '$columnProjectNameID = ?', whereArgs: [projectID]);
  }

  /// Queries the list of test stations for a specific project.
  ///
  /// [projectID] - The ID of the project.
  ///
  /// Returns a list of maps, where each map represents a test station.
  Future<List<Map<String, dynamic>>> queryTestStationsByProjectID(int projectID) async {
    final db = await database;
    return await db.query('TestStations', where: '$columnProjectNameID = ?', whereArgs: [projectID]);
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = await database;
    db.close();
  }

  /// Inserts or updates a reading in the specified table of the database.
  ///
  /// The [stationID] parameter represents the ID of the station associated with the reading.
  /// The [readingMap] parameter is a map containing the data of the reading to be inserted or updated.
  /// The [tableName] parameter specifies the name of the table in which the reading should be inserted or updated.
  ///
  /// Returns the ID of the inserted or updated reading if successful, or -1 if the update operation fails.
  Future<int> insertOrUpdateReading(int? stationID, Map<String, dynamic> readingMap, String tableName) async {
    final db = await database;
    final int? orderIndex = readingMap['order_index'];

    List<Map<String, dynamic>> existingRows = await db.query(
      tableName,
      where: 'stationID = ? AND order_index = ?',
      whereArgs: [stationID, orderIndex],
    );

    if (existingRows.isNotEmpty) {
      var updatedRecord = Map<String, dynamic>.from(existingRows.first)..addAll(readingMap);
      int updateCount = await db.update(
        tableName,
        updatedRecord,
        where: 'id = ?',
        whereArgs: [existingRows.first['id']],
      );

      if (updateCount == 0) {
        return -1;
      }

      return existingRows.first['id'];
    } else {
      int newId = await db.insert(tableName, readingMap);
      return newId;
    }
  }

  Future<int> insertOrUpdateFieldNotes(int? id, Map<String, dynamic> readingMap) async {
    final db = await database;

    List<Map<String, dynamic>> existingRows = await db.query(
      'TestStations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingRows.isNotEmpty) {
      var updatedRecord = Map<String, dynamic>.from(existingRows.first)..addAll(readingMap);
      int updateCount = await db.update(
        'TestStations',
        updatedRecord,
        where: 'id = ?',
        whereArgs: [existingRows.first['id']],
      );

      if (updateCount == 0) {
        return -1;
      }

      return existingRows.first['id'];
    } else {
      int newId = await db.insert('TestStations', readingMap);
      return newId;
    }
  }

  Future<Map<String, dynamic>?> getFieldNotes(int id) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'TestStations',
      where: 'id = ?',
      whereArgs: [id],
      columns: ['fieldNotes'],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Fetches the names associated with a specific test station ID for different tables in the database.
  ///
  /// The [testStationID] parameter specifies the ID of the test station.
  ///
  /// Returns a [Future] that completes with a [List] of [String] containing the names.
  Future<List<String>> fetchNamesForShunt(String testStationID) async {
    final Database db = await database;

    List<String> names = [];

    // Query each table and add names to the list
    List<String> tables = ['AnodeContainers', 'PLTestLeadContainers', 'TestLeadContainers'];
    for (String table in tables) {
      final List<Map<String, dynamic>> maps = await db.query(
        table,
        columns: ['name'],
        where: 'testStationID = ?',
        whereArgs: [testStationID],
      );

      for (var map in maps) {
        names.add(map['name'] as String);
      }
    }

    // Close the database if necessary
    // await db.close();

    return names;
  }

  Future<List<String>> fetchNamesForLabel() async {
    final Database db = await database;
    Set<String> namesSet = {};
    List<String> tables = [
      'PermRefContainers',
      'AnodeContainers',
      'PLTestLeadContainers',
      'TestLeadContainers',
      'RiserContainers',
      'ForeignContainers',
      'CouponContainers',
      'ShuntContainers',
      'IsolationContainers',
      'BondContainers'
    ];

    for (String table in tables) {
      try {
        final List<Map<String, dynamic>> maps = await db.query(
          table,
          columns: ['label'],
        );

        for (var map in maps) {
          namesSet.add(map['label'] as String);
        }
      } catch (e) {
        print('Error querying table $table: $e');
      }
    }

    return namesSet.toList();
  }

  /// Queries the readings from the specified table by test station ID.
  ///
  /// Returns a list of maps representing the queried readings.
  /// Each map contains the column names as keys and the corresponding values as values.
  /// The readings are filtered based on the provided test station ID.
  ///
  /// - [tableName]: The name of the table to query.
  /// - [id]: The test station ID to filter the readings.
  ///
  /// Returns a future that completes with a list of maps representing the queried readings.
  Future<List<Map<String, dynamic>>> queryReadingsByTestStationID(String tableName, int? id) async {
    Database db = await database;
    return await db.query(tableName, where: 'stationID = ?', whereArgs: [id]);
  }

  //Camera Settings methods
  Future<void> insertCameraSettings(CameraSettings cameraSettings) async {
    final db = await database;
    await db.insert(
      'CameraSettings',
      cameraSettings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CameraSettings?> getCameraSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('CameraSettings');
    if (maps.isNotEmpty) {
      return CameraSettings.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCameraSettings(Map<String, dynamic> settingsMap) async {
    final db = await database;
    // Update the single existing settings row. This assumes there's always one row.
    return await db.update(
      'CameraSettings',
      settingsMap,
      // No where clause needed if only one row is present in the table
    );
  }
}
