// ignore_for_file: unused_local_variable, unnecessary_type_check, sized_box_for_whitespace

import 'dart:io';

import 'package:asset_inspections/Common_Widgets/custom_camera.dart';
//import 'package:asset_inspections/GPS/digital_compass.dart';
import 'package:asset_inspections/GPS/gps_ble_service.dart';
import 'package:asset_inspections/Models/project_model.dart';
import 'package:asset_inspections/Test_Station/TS_Containers/abstract_base_container.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:marquee/marquee.dart';

import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/database_helper.dart';
import 'package:asset_inspections/main.dart';

//import '../Common_Widgets/gps_location.dart';
import '../Common_Widgets/image_viewer.dart';
import '../GPS/gps_fix_view.dart';
import '../GPS/gps_status_bar.dart';
import 'TS_Containers/new_anode.dart';
import 'TS_Containers/new_bond.dart';
import 'TS_Containers/new_coupon.dart';
import 'TS_Containers/new_foreign.dart';
import 'TS_Containers/new_isolation.dart';
import 'TS_Containers/new_permrefcell.dart';
import 'TS_Containers/new_pltestlead.dart';
import 'TS_Containers/new_riser.dart';
import 'TS_Containers/new_shunt.dart';
import 'TS_Containers/new_testlead.dart';
import 'ts_notifier.dart';

/// A page that displays the details of a test station.
///
/// This page requires a [TestStation] object to display the details of the test station.
/// It also requires a callback function [ontsStatusChanged] that will be called when the status of the test station changes.
class TestStationDetailsPage extends StatefulWidget {
  final TestStation testStation;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final Function(
      int id,
      int projectID,
      String area,
      String tsID,
      String? officeNotes,
      String fieldNotes,
      PLTestLeadReading pltestleadreading,
      PermRefReading permrefreading,
      AnodeReading anodereading,
      ShuntReading shuntreading,
      RiserReading riserreading,
      ForeignReading foreignreading,
      TestLeadReading testleadreading,
      CouponReading couponreading,
      BondReading bondreading,
      IsolationReading isolationreading) ontsStatusChanged;

  const TestStationDetailsPage(
      {super.key,
      required this.testStation,
      this.scaffoldMessengerKey,
      required this.ontsStatusChanged});

  @override
  createState() => _TestStationDetailsPageState();
}

/// The state class for the TestStationDetailsPage widget.
///
/// This class manages the state of the TestStationDetailsPage widget,
/// including the test station information, scaffold messenger key,
/// state initialization flag, focus node for the location field,
/// database helper and database instances, project name, latitude
/// and longitude values, current test station status index, and
/// lists of reading containers.
class _TestStationDetailsPageState extends State<TestStationDetailsPage> {
  GpsBleService? gpsService;
  TestStation? testStation;
  TestStation? currentTestStation;
  List<String> picturePaths = [];
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _stateInitialized = false;
  final FocusNode tslocationFocusNode = FocusNode();
  late DatabaseHelper dbHelper;
  late Database db;
  late String projectName;

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _officeNotesController = TextEditingController();
  final TextEditingController _fieldNotesController = TextEditingController();

  FocusNode? fieldNotesFocusNode;

  double? latitude;
  double? longitude;

  String? officeNotes;
  String? fieldNotes;

  final List<String> tsstatuses = ['Unchecked', 'Pass', 'Attention', 'Issue'];
  int currentTSStatusIndex = 0;

  final List<Widget> _readingContainers =
      []; //used to store manually added reading containers
  final List<Widget> _loadedContainers =
      []; //is used to store reading containers loaded from a database

  /// Adds a focus listener to the given [focusNode].
  /// When the focus is lost, this method will call [_updatePLTestLeadReading] and [_updateTSValues].
  void _addFocusListener(FocusNode focusNode) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        // _updatePLTestLeadReading();

        // _updateTSValues();
      }
    });
  }

  /// Sets up a text controller with an initial value and an optional listener.
  ///
  /// The [controller] is the text controller to be set up.
  /// The [value] is the initial value for the text controller.
  /// The [listener] is an optional callback function that will be called when the text changes.
  void _setupTextController(TextEditingController controller, String value,
      void Function()? listener) {
    controller.text = value;
    if (listener != null) {
      controller.addListener(listener);
    }
  }

  /// Loads containers from the database based on the provided container type, ID, and test station ID.
  ///
  /// The [containerType] parameter specifies the type of container to load.
  /// The [id] parameter specifies the ID of the container.
  /// The [testStationID] parameter specifies the ID of the test station.
  /// The [isAddingNewContainer] parameter indicates whether a new container is being added.
  ///
  /// If [testStationID] is null, the function returns without performing any operations.
  ///
  /// The function queries the database for container data based on the provided [containerType] and [testStationID].
  /// It then initializes the [readings] list as an empty list.
  ///
  /// Depending on the [containerType], the function maps the container data to the corresponding reading type and assigns it to the [readings] list.
  ///
  /// The function dynamically creates container widgets based on the type of readings in the [readings] list.
  /// Each container widget is added to the [newContainers] list.
  ///
  /// For each new container, the function checks if a similar container already exists in the [_readingContainers] list.
  /// If the container does not exist, it is added to the [_readingContainers] list and, if [isAddingNewContainer] is false, to the [_loadedContainers] list.
  Future<void> _loadContainersFromDatabase(
      String containerType, int? stationID, String? testStationID,
      {bool isAddingNewContainer = false}) async {
//    if (kDebugMode) {
//      print('Starting _loadContainersFromDatabase for $containerType with stationID: $stationID');
//    }

    if (stationID == null) {
      // Handle the null case, possibly with an error message
//      if (kDebugMode) {
//        print('stationID is null');
//      }
      return;
    }

    Database db = await DatabaseHelper.instance.database;
    String tableName = _getTableNameForContainerType(containerType);

//    if (kDebugMode) {
//      print('Querying database for $tableName with stationID: $stationID');
//    }

    List<Map<String, dynamic>> containerData = await db.query(
      tableName,
      where: 'stationID = ?',
      whereArgs: [stationID],
      orderBy: 'order_index',
    );

//    if (kDebugMode) {
//      print('Retrieved container data from $tableName: $containerData');
//    }

    // Initialize readings as an empty list
    List<dynamic> readings = [];

//    if (kDebugMode) {
//      print('Processing container data for type $containerType');
//    }

    if (containerType == 'PL Test Lead') {
      readings =
          containerData.map((data) => PLTestLeadReading.fromMap(data)).toList();
    } else if (containerType == 'Perm Ref Cell') {
      readings =
          containerData.map((data) => PermRefReading.fromMap(data)).toList();
    } else if (containerType == 'Anode') {
      readings =
          containerData.map((data) => AnodeReading.fromMap(data)).toList();
    } else if (containerType == 'Shunt') {
      readings =
          containerData.map((data) => ShuntReading.fromMap(data)).toList();
    } else if (containerType == 'Riser') {
      readings =
          containerData.map((data) => RiserReading.fromMap(data)).toList();
    } else if (containerType == 'Foreign') {
      readings =
          containerData.map((data) => ForeignReading.fromMap(data)).toList();
    } else if (containerType == 'Test Lead') {
      readings =
          containerData.map((data) => TestLeadReading.fromMap(data)).toList();
    } else if (containerType == 'Coupon') {
      readings =
          containerData.map((data) => CouponReading.fromMap(data)).toList();
    } else if (containerType == 'Bond') {
      readings =
          containerData.map((data) => BondReading.fromMap(data)).toList();
    } else if (containerType == 'Isolation') {
      readings =
          containerData.map((data) => IsolationReading.fromMap(data)).toList();
    } else {
      throw UnimplementedError(
          'Reading type $containerType not implemented in loadContainersFromDatabase');
    }

//    if (kDebugMode) {
//      print('Mapped readings1: $readings');
//    }

    // Dynamic creation of container widgets based on the type of readings
    List<Widget> newContainers = readings.map<Widget>((reading) {
      if (reading is PLTestLeadReading) {
        return PLTestLeadContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is PermRefReading) {
        return PermRefContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is AnodeReading) {
        return AnodeContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is ShuntReading) {
        return ShuntContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is RiserReading) {
        return RiserContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is ForeignReading) {
        return ForeignContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is TestLeadReading) {
        return TestLeadContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is CouponReading) {
        return CouponContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is BondReading) {
        return BondContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else if (reading is IsolationReading) {
        return IsolationContainer(
          readings: [reading],
          currentTestStation: Provider.of<TSNotifier>(context, listen: false)
              .currentTestStation,
          scaffoldMessengerKey: scaffoldMessengerKey,
        );
      } else {
        throw UnimplementedError('Container type for reading not implemented');
      }
    }).toList();

//    if (kDebugMode) {
//      print('Mapped readings2: $readings');
//    }
//    if (kDebugMode) {
//      print('Created new containers2: $newContainers');
//    }

    for (var newContainer in newContainers) {
      bool containerExists = _readingContainers.any((existingContainer) {
        if (existingContainer is PLTestLeadContainer &&
            newContainer is PLTestLeadContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for PermRefContainer
        if (existingContainer is PermRefContainer &&
            newContainer is PermRefContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for AnodeContainer
        if (existingContainer is AnodeContainer &&
            newContainer is AnodeContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for ShuntContainer
        if (existingContainer is ShuntContainer &&
            newContainer is ShuntContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for RiserContainer
        if (existingContainer is RiserContainer &&
            newContainer is RiserContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for ForeignContainer
        if (existingContainer is ForeignContainer &&
            newContainer is ForeignContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for TestLeadContainer
        if (existingContainer is TestLeadContainer &&
            newContainer is TestLeadContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for CouponContainer
        if (existingContainer is CouponContainer &&
            newContainer is CouponContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for BondContainer
        if (existingContainer is BondContainer &&
            newContainer is BondContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        // Check and cast for IsolationContainer
        if (existingContainer is IsolationContainer &&
            newContainer is IsolationContainer) {
          return existingContainer.readings.any((existingReading) =>
              newContainer.readings.any((newReading) =>
                  existingReading.orderIndex == newReading.orderIndex));
        }

        return false;
      });

//      if (kDebugMode) {
//        print('Checking if container exists...');
//      }

      if (!containerExists) {
//        if (kDebugMode) {
//          print('Container does not exist, adding new container...');
//        }

        setState(() {
          _readingContainers.add(newContainer);
//          if (kDebugMode) {
//            print('Added to _readingContainers: $_readingContainers');
//          }

          if (!isAddingNewContainer) {
            _loadedContainers.add(newContainer);
//            if (kDebugMode) {
//              print('Added to _loadedContainers: $_loadedContainers');
//            }
          } else {
//            if (kDebugMode) {
//              print('Is adding new container, not adding to _loadedContainers.');
//            }
          }
        });

//        if (kDebugMode) {
//          print('setState called to add new container.');
//        }
      } else {
//        if (kDebugMode) {
//          print('Container exists, not adding.');
//        }
      }
    }
  }

  /// Loads containers for all types.
  ///
  /// This method iterates over the container types defined in [containerTypeToTable] and
  /// calls [_loadContainersFromDatabase] to load containers from the database for each type.
  /// The [widget.testStation.id] and [widget.testStation.tsID] are passed as parameters to
  /// [_loadContainersFromDatabase].
  ///
  /// Note: The [_loadContainersFromDatabase] method is responsible for handling errors and logging.
  Future<void> _loadContainersForAllTypes() async {
//    if (kDebugMode) {
//      print('Starting _loadContainersForAllTypes');
//    }

    for (String containerType in containerTypeToTable.keys) {
//      if (kDebugMode) {
//        print('Loading containers for type: $containerType');
//      }
      await _loadContainersFromDatabase(
        containerType,
        widget.testStation.id,
        widget.testStation.tsID,
      );
      // _loadContainersFromDatabase will do its own error handling and logging
    }
  }

  /// Initializes the state of the [TSDetails] widget.
  ///
  /// This method is called when the widget is inserted into the widget tree.
  /// It sets up the initial state of the widget by loading containers for all types,
  /// initializing text controllers for latitude and longitude,
  /// adding a focus listener for the location text field,
  /// and setting the current test station status index.
  @override
  void initState() {
    super.initState();
    //  testStation = Provider.of<TSNotifier>(context, listen: false).currentTestStation;
    testStation = widget.testStation;
    if (testStation?.picturePath != null) {
      picturePaths = testStation!.picturePath!.split(',');
    }

    // Initialize the state only if it hasn't been initialized before.
    if (!_stateInitialized) {
//      if (kDebugMode) {
//       print('initState called for TestStationDetailsPage');
//      }
      _loadContainersForAllTypes();
      _stateInitialized = true; // Set this to true after initialization.
    }

    _setupTextController(
        _latitudeController,
        widget.testStation.latitude?.toString() ??
            '', // defaulting to '0.0' if null
        () {
      latitude = double.tryParse(_latitudeController.text);
    });

    _setupTextController(
        _longitudeController,
        widget.testStation.longitude?.toString() ??
            '', // defaulting to '0.0' if null
        () {
      longitude = double.tryParse(_longitudeController.text);
    });

    _setupTextController(
        _officeNotesController, widget.testStation.officeNotes ?? '', () {
      officeNotes = _officeNotesController.text;
    });

    _addFocusListener(tslocationFocusNode);

    // Load the initial field notes
    _fieldNotesController.text = widget.testStation.fieldNotes ?? '';

    fieldNotesFocusNode = FocusNode();
    fieldNotesFocusNode!.addListener(() {
      if (!fieldNotesFocusNode!.hasFocus) {
        saveFieldNotes();
      }
    });

    // Add this line to load field notes when the page is initialized
    loadFieldNotes();

/*
    _setupTextController(_fieldNotesController, widget.testStation.fieldNotes ?? '', () {
      fieldNotes = _fieldNotesController.text;
    });

    fieldNotesFocusNode = FocusNode();

    fieldNotesFocusNode!.addListener(() {
      if (!fieldNotesFocusNode!.hasFocus) {
        saveOrUpdateFieldNotes();
      }
    });
*/
    currentTSStatusIndex = tsstatuses.indexOf(widget.testStation.tsstatus);
    if (currentTSStatusIndex == -1) {
      // Handle or log error, as tsstatus is not valid
      currentTSStatusIndex = 0; // Or set to a default index
    }
  }

  Future<void> _takePictures() async {
    final projectModel = Provider.of<ProjectModel>(context, listen: false);
    final tsNotifier = Provider.of<TSNotifier>(context, listen: false);

    final List<String>? newPicturePaths =
        await CustomCamera.navigateToCustomCamera(
      context,
      projectModel.id,
      projectModel.client,
      projectModel.projectName,
      stationID: testStation?.id,
      stationArea: testStation?.area,
      stationTSID: testStation?.tsID,
    );

    if (newPicturePaths != null && newPicturePaths.isNotEmpty) {
      setState(() {
        picturePaths.addAll(newPicturePaths);
        testStation?.picturePath = picturePaths.join(',');
      });

      // Update the TestStation in the TSNotifier
      tsNotifier.updateTestStationPicture(
          testStation?.id, testStation?.picturePath!);

      // Show a confirmation to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${newPicturePaths.length} new picture(s) added')),
        );
      }
    }
  }

  //Method to get the full paths of the photos since we only store relative paths
  Future<List<String>> _convertRelativePathsToFullPaths(
      List<String> relativePaths) async {
    List<String> fullPaths = [];

    try {
      Directory? directory = await getExternalStorageDirectory();
      String basePath = '';

      if (directory != null) {
        List<String> folders = directory.path.split('/');
        for (int x = 1; x < folders.length; x++) {
          String folder = folders[x];
          if (folder != "Android") {
            basePath += "/$folder";
          } else {
            break;
          }
        }
        basePath = "$basePath/Download";
      } else {
        // Fallback to application documents directory
        directory = await getApplicationDocumentsDirectory();
        basePath = directory.path;
      }

      for (String relativePath in relativePaths) {
        if (relativePath.isNotEmpty) {
          String fullPath = "$basePath/$relativePath";
          // Verify the file exists before adding it
          if (await File(fullPath).exists()) {
            fullPaths.add(fullPath);
          } else {
            if (kDebugMode) {
              print("File not found: $fullPath");
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error converting relative paths to full paths: $e");
      }
    }

    return fullPaths;
  }

  void _viewPhotos() async {
    if (picturePaths.isNotEmpty) {
      // Convert relative paths to full paths
      List<String> fullPaths =
          await _convertRelativePathsToFullPaths(picturePaths);

      if (!mounted) return;

      if (fullPaths.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(imagePaths: fullPaths),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid photos found')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos available')),
      );
    }
  }

  void saveFieldNotes() {
    int id = widget.testStation.id ?? 0;
    //String tsID = widget.testStation.tsID;

    var readingMap = {
      'id': id,
      //  'tsID': tsID,
      'fieldNotes': _fieldNotesController.text,
    };

    // performDbOperation(id, tsID, readingMap);
    performDbOperation(id, widget.testStation.tsID, readingMap);

    // Update the local testStation object
    widget.testStation.fieldNotes = _fieldNotesController.text;
  }

  void loadFieldNotes() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    int id = widget.testStation.id ?? 0;

    Map<String, dynamic>? loadedData = await dbHelper.getFieldNotes(id);
    if (loadedData != null && loadedData['fieldNotes'] != null) {
      setState(() {
        _fieldNotesController.text = loadedData['fieldNotes'];
      });
    }
  }

/*
  void saveOrUpdateFieldNotes() {
    int id = widget.testStation.id ?? 0;
    String tsID = widget.testStation.tsID;
    //  int currentOrderIndex = widget.testStation.orderIndex!;

    var readingMap = {
      'id': widget.testStation.id,
      'tsID': tsID,
    };

    readingMap['fieldNotes'] = _fieldNotesController.text ?? '';

    performDbOperation(id, tsID, readingMap);
  }
*/

  void performDbOperation(
      int id, String tsID, Map<String, dynamic> readingMap) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    await dbHelper.insertOrUpdateFieldNotes(id, readingMap).then((insertedId) {
      if (insertedId > 0) {
        widget.scaffoldMessengerKey?.currentState?.showSnackBar(
          const SnackBar(content: Text('Reading Saved!')),
        );
      } else {
        widget.scaffoldMessengerKey?.currentState?.showSnackBar(
          const SnackBar(content: Text('Failed to Save Reading!')),
        );
      }
    }).catchError((e) {
      widget.scaffoldMessengerKey?.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    });
  }

  @override
  void dispose() {
    //Save the field notes if they've been modified
    if (_fieldNotesController.text != widget.testStation.fieldNotes) {
      saveFieldNotes();
    }

    _stateInitialized = false;
    _latitudeController.dispose();
    _longitudeController.dispose();
    _officeNotesController.dispose();
    _fieldNotesController.dispose();
    tslocationFocusNode.dispose();
    super.dispose();
  }

  String get currenttsStatus => tsstatuses[currentTSStatusIndex];

  /// Toggles the test station status and updates it in the UI.
  ///
  /// This method updates the current test station status by cycling through the available status options.
  /// It then updates the test station status using the [TSNotifier] provider and triggers a UI update.
  ///
  /// The updated test station status is determined by the [currentTSStatusIndex] and [tsstatuses] list.
  /// The [currentTSStatusIndex] is incremented and wrapped around using the modulo operator to cycle through the available status options.
  /// The new test station status is obtained from the [tsstatuses] list based on the updated [currentTSStatusIndex].
  ///
  /// This method is asynchronous and uses [setState] to trigger a UI update.
  /// It also uses [Provider.of] to access the [TSNotifier] provider and update the test station status.
  ///
  /// Note: This method includes a [Future.delayed] call with a duration of zero to ensure the UI update is scheduled after the current frame.
  void _toggletsStatus() async {
    // Save field notes first if they've been edited
    if (_fieldNotesController.text != widget.testStation.fieldNotes) {
      saveFieldNotes();
      // Update the widget's testStation with the new field notes
      widget.testStation.fieldNotes = _fieldNotesController.text;
    }

    setState(() {
      currentTSStatusIndex =
          (currentTSStatusIndex + 1) % tsstatuses.length; // Cycle through
    });
    String newTSStatus = tsstatuses[currentTSStatusIndex];
    Provider.of<TSNotifier>(context, listen: false)
        .updateTestStationStatus(widget.testStation, newTSStatus, context);

    await Future.delayed(Duration.zero);
  }

  bool _isExpanded = false;

  /// Toggles the expand state of the widget.
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  double _calculateHeight() {
    double baseHeight = 245.h; // Default height
    double expandHeight = _isExpanded ? 80.h : 0;
    // Safely check if officeNotes is not null and not empty
    double notesHeight =
        (widget.testStation.officeNotes?.isNotEmpty ?? false) ? 160.h : 0;

    return baseHeight + expandHeight + notesHeight;
    //  return baseHeight + expandHeight;
  }

  /// A map that maps container types to their corresponding table names.
  ///
  /// The keys of the map represent the container types, while the values represent
  /// the table names associated with each container type.
  Map<String, String> containerTypeToTable = {
    'PL Test Lead': 'PLTestLeadContainers',
    'Perm Ref Cell': 'PermRefContainers',
    'Anode': 'AnodeContainers',
    'Shunt': 'ShuntContainers',
    'Riser': 'RiserContainers',
    'Foreign': 'ForeignContainers',
    'Test Lead': 'TestLeadContainers',
    'Coupon': 'CouponContainers',
    'Bond': 'BondContainers',
    'Isolation': 'IsolationContainers',
  };

  /// Retrieves the table name for a given container type.
  ///
  /// Throws an exception if the provided container type is invalid.
  ///
  /// Returns the corresponding table name for the container type.
  String _getTableNameForContainerType(String containerType) {
    // Ensure the provided containerType is valid
    if (!containerTypeToTable.containsKey(containerType)) {
      throw Exception('Invalid containerType: $containerType');
    }
    // Return the corresponding table name
    return containerTypeToTable[containerType]!;
  }

  /// Shows a dialog to add a reading.
  ///
  /// This method displays an [AlertDialog] with a list of readings to select from.
  /// Each reading is represented by a [ListTile] with a centered title.
  /// When a reading is tapped, the dialog is closed and the selected reading is added to the reading container.
  void _showAddReadingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
              child: Text('Select Reading',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 0, 43, 92),
                  ))),
          content: SizedBox(
            width: 10.w,
            height: 600.h,
            child: SingleChildScrollView(
              child: ListBody(
                children: [
                  ListTile(
                    title: Center(
                        child: Text('PL Test Lead',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('PL Test Lead');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Perm Ref Cell',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Perm Ref Cell');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Anode',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Anode');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Shunt',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Shunt');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Riser',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Riser');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Foreign',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Foreign');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Test Lead',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Test Lead');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Coupon',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Coupon');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Bond',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Bond');
                    },
                  ),
                  ListTile(
                    title: Center(
                        child: Text('Isolation',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 43, 92),
                            ))),
                    onTap: () {
                      Navigator.pop(context);
                      _addReadingContainer('Isolation');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteContainer(String containerName, int orderIndex) async {
//    if (kDebugMode) {
//      print('Deleting container: $containerName, orderIndex: $orderIndex');
//    }

    final dbHelper = DatabaseHelper.instance;
    final tsNotifier = Provider.of<TSNotifier>(context, listen: false);
    final tableName = containerName;

    // Delete from database
    int deletedRows = await dbHelper.deleteReading(
        tableName, widget.testStation.id!, orderIndex);

//    if (kDebugMode) {
//      print('Rows deleted from database: $deletedRows');
//    }

    // Update TSNotifier
    tsNotifier.removeReading(containerName, widget.testStation.id!, orderIndex);

    // Remove from UI
    setState(() {
      _readingContainers.removeWhere((container) {
        if (container is BaseContainer) {
          return container.readings.isNotEmpty &&
              container.readings[0] is dynamic &&
              (container.readings[0] as dynamic).orderIndex == orderIndex;
        }
        return false;
      });
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${containerName.replaceAll('Containers', '')} deleted successfully')),
      );
    }
  }

  void removeContainer(Widget container) {
    setState(() {
      _readingContainers.remove(container);
    });
  }

  /// Adds a reading container based on the reading type and optional data.
  ///
  /// The [readingType] parameter specifies the type of reading container to add.
  /// The [data] parameter is an optional map of data used to initialize the reading container.
  ///
  /// This method updates the state of the widget by adding the appropriate reading container to the [_loadedContainers] list.
  /// It also calls the [tsNotifier.updateReadingInTestStation] method to update the reading in the test station.
  /// Finally, it saves the new container to the database and loads the containers from the database.
  ///
  /// Throws an [UnimplementedError] if the reading type is not supported.
  Future<void> _addReadingContainer(String readingType,
      {Map<String, dynamic>? data}) async {
    //  int stationID = widget.testStation.id ?? 0;

    setState(() {
      final tsNotifier = Provider.of<TSNotifier>(context, listen: false);
      final tsID = tsNotifier.currentTestStation.tsID;
      final stationID = tsNotifier.currentTestStation.id;

      if (readingType == 'PL Test Lead') {
        List<PLTestLeadReading> readings = [];
        if (data != null) {
          readings.add(PLTestLeadReading.fromMap(data));
        }
        _loadedContainers.add(
          PLTestLeadContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<PLTestLeadReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'PLTestLeadContainers',
                  (ts) => ts.plTestLeadReadings as List<dynamic>,
                  (ts, index, reading) =>
                      ts.plTestLeadReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Perm Ref Cell') {
        List<PermRefReading> readings = [];
        if (data != null) {
          readings.add(PermRefReading.fromMap(data));
        }
        _loadedContainers.add(
          PermRefContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<PermRefReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'PermRefContainers',
                  (ts) => ts.permRefReadings as List<dynamic>,
                  (ts, index, reading) => ts.permRefReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Anode') {
        List<AnodeReading> readings = [];
        if (data != null) {
          readings.add(AnodeReading.fromMap(data));
        }
        _loadedContainers.add(
          AnodeContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<AnodeReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'AnodeContainers',
                  (ts) => ts.anodeReadings as List<dynamic>,
                  (ts, index, reading) => ts.anodeReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Shunt') {
        List<ShuntReading> readings = [];
        if (data != null) {
          readings.add(ShuntReading.fromMap(data));
        }
        _loadedContainers.add(
          ShuntContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<ShuntReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'ShuntContainers',
                  (ts) => ts.shuntReadings as List<dynamic>,
                  (ts, index, reading) => ts.shuntReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Riser') {
        List<RiserReading> readings = [];
        if (data != null) {
          readings.add(RiserReading.fromMap(data));
        }
        _loadedContainers.add(
          RiserContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<RiserReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'RiserContainers',
                  (ts) => ts.riserReadings as List<dynamic>,
                  (ts, index, reading) => ts.riserReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Foreign') {
        List<ForeignReading> readings = [];
        if (data != null) {
          readings.add(ForeignReading.fromMap(data));
        }
        _loadedContainers.add(
          ForeignContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<ForeignReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'ForeignContainers',
                  (ts) => ts.foreignReadings as List<dynamic>,
                  (ts, index, reading) => ts.foreignReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Test Lead') {
        List<TestLeadReading> readings = [];
        if (data != null) {
          readings.add(TestLeadReading.fromMap(data));
        }
        _loadedContainers.add(
          TestLeadContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<TestLeadReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'TestLeadContainers',
                  (ts) => ts.testLeadReadings as List<dynamic>,
                  (ts, index, reading) =>
                      ts.testLeadReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Coupon') {
        List<CouponReading> readings = [];
        if (data != null) {
          readings.add(CouponReading.fromMap(data));
        }
        _loadedContainers.add(
          CouponContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<CouponReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'CouponContainers',
                  (ts) => ts.couponReadings as List<dynamic>,
                  (ts, index, reading) => ts.couponReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Bond') {
        List<BondReading> readings = [];
        if (data != null) {
          readings.add(BondReading.fromMap(data));
        }
        _loadedContainers.add(
          BondContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<BondReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'BondContainers',
                  (ts) => ts.bondReadings as List<dynamic>,
                  (ts, index, reading) => ts.bondReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else if (readingType == 'Isolation') {
        List<IsolationReading> readings = [];
        if (data != null) {
          readings.add(IsolationReading.fromMap(data));
        }
        _loadedContainers.add(
          IsolationContainer(
            readings: readings,
            currentTestStation: widget.testStation,
            onReadingUpdated: (updatedReading) {
              tsNotifier.updateReadingInTestStation<IsolationReading>(
                  updatedReading,
                  stationID,
                  tsID,
                  context,
                  'IsolationContainers',
                  (ts) => ts.isolationReadings as List<dynamic>,
                  (ts, index, reading) =>
                      ts.isolationReadings?[index] = reading);
            },
            scaffoldMessengerKey: scaffoldMessengerKey,
          ),
        );
      } else {
        throw UnimplementedError('...');
      }
    });

    await _saveNewContainer(readingType, widget.testStation.id);
    await _loadContainersFromDatabase(
        readingType, widget.testStation.id, widget.testStation.tsID,
        isAddingNewContainer: true);
//    if (kDebugMode) {
//      print('station ID: ${widget.testStation.id}');
//     print('Loaded Containers $_loadedContainers');
//      print('$_readingContainers');
//    }
  }

  /// Saves a new container of the specified [containerType] for the given [stationID] in the database.
  /// The [containerType] determines the table name in the database.
  /// The [stationID] is used to fetch the maximum order_index from the table.
  /// The new container is inserted into the database with an incremented name and order_index.
  /// Returns a [Future] that completes when the container is successfully saved or an error occurs.
  Future<void> _saveNewContainer(String containerType, int? stationID) async {
    try {
      final tableName = _getTableNameForContainerType(containerType);
      // Log the resolved table name

      Database db = await DatabaseHelper.instance.database;

      // Fetch the maximum order_index from the table
      final maxIndexResult = await db.rawQuery(
        'SELECT MAX(order_index) as maxIndex FROM $tableName WHERE stationID = ?',
        [widget.testStation.id],
      );

      final stationID = widget.testStation.id;

      // Calculate the new order_index by adding 100 to the max order_index
      final int newOrderIndex =
          (maxIndexResult.first['maxIndex'] as int? ?? 0) + 100;

      // Calculate the suffix for the name based on the new order_index
      final int nameSuffix = (newOrderIndex / 100).round();

      // Insert the new container into the database with the incremented name and order_index
      await db.insert(
        tableName,
        {
          'stationID': stationID,
          'testStationID': widget.testStation.tsID,
          'order_index': newOrderIndex,
          'name':
              '$containerType$nameSuffix', // e.g., "containerType1" for order_index 100
        },
      );
    } catch (e) {
      // Consider logging the error or handling it appropriately
    }
  }

  Widget _buildPictureSection() {
    return Column(
      children: [
        const Text('Station Pictures',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 43, 92))),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: _takePictures,
                child: Icon(
                  Icons.add_a_photo,
                  size: 30.sp,
                )),
            ElevatedButton(
              onPressed: _viewPhotos,
              child: SizedBox(
                  child: Row(
                children: [
                  const Icon(Icons.photo_library, size: 30),
                  Text(' (${picturePaths.length})'),
                ],
              )),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the widget tree for the TestStationDetails screen.
  ///
  /// This method returns a [Scaffold] widget that displays the details of a test station.
  /// The app bar contains the test station's area and ID, and a home button that navigates
  /// back to the main page. The body of the scaffold contains the test station details
  /// container and a list of reading containers.
  ///
  /// The [context] parameter is the build context.
  ///
  /// Returns the built widget tree.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic pop to ensure save completes
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        // Save field notes if they've been modified
        if (_fieldNotesController.text != widget.testStation.fieldNotes) {
          saveFieldNotes();
          await Future.delayed(
              const Duration(milliseconds: 100)); // Give time for save
        }

        // Now pop the page with the result (if any)
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },

      child: ScaffoldMessenger(
        key: scaffoldMessengerKey,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(50
                .h), // Make sure `45.h` is valid or replace with fixed size like `kToolbarHeight`
            child: AppBar(
              backgroundColor: const Color.fromARGB(255, 0, 43, 92),
              iconTheme: const IconThemeData(color: Colors.white),
              title: SizedBox(
                height: 35.h,
                width: 250.w,
                child: Marquee(
                  text:
                      '${widget.testStation.area} ${widget.testStation.tsID}', // Confirm this data is not empty
                  style: const TextStyle(
                    fontSize:
                        18.0, // Changed from `18.sp` to a fixed size for testing
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textDirection: TextDirection.ltr,
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  blankSpace:
                      200.0, // Increased blank space for better visibility
                  velocity: 50.0, // Speed at which the text scrolls
                  // pauseAfterRound: const Duration(seconds: 3), // Pauses after each complete scroll
                  showFadingOnlyWhenScrolling: true,
                  fadingEdgeStartFraction: 0.1,
                  fadingEdgeEndFraction: 0.1,
                  numberOfRounds: 3,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainPage(key: UniqueKey()),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              const GPSStatusBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildTestStationDetailsContainer(),
                        _buildPictureSection(),
                        if (_readingContainers.isNotEmpty)
                          SizedBox(height: 10.h),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const PageScrollPhysics(),
                          itemCount: _readingContainers.length,
                          itemBuilder: (context, index) =>
                              _readingContainers[index],
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 10.h),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the container for displaying test station details.
  ///
  /// This widget is responsible for rendering the UI elements that show the details of a test station.
  /// It uses the [TSNotifier] consumer to listen for changes in the test station data.
  /// The container includes the test station area and ID, the current test station status,
  /// the GPS coordinates, and buttons for expanding, adding readings, fetching location, and deleting.
  /// The UI elements are styled with appropriate colors and fonts.
  Widget _buildTestStationDetailsContainer() {
    double dynamicHeight = _calculateHeight();
    return ScreenUtilInit(
      designSize: const Size(384, 824),
      child: Consumer<TSNotifier>(
        builder: (context, tsNotifier, child) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                height: dynamicHeight,
                // height: _isExpanded ? null : 140.h,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 43, 92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /*
                        Text(
                          '${widget.testStation.area}: ${widget.testStation.tsID}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        */
                        SelectableText(
                          // Display the GPS coordinates with selectable text
                          '${widget.testStation.latitude}, ${widget.testStation.longitude}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        //  const Spacer(),
                        SizedBox(
                          width: 105.w,
                          height: 35.h,
                          //  decoration: BoxDecoration(
                          //    color: widget.testStation.gettsStatusColor(),
                          //    borderRadius: BorderRadius.circular(10.r),
                          //  ),
                          child: ElevatedButton(
                            // Display the current TS Status, or click to change
                            onPressed: _toggletsStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  widget.testStation.gettsStatusColor(),
                            ),
                            child: Text(
                              ' $currenttsStatus',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.testStation.officeNotes?.isNotEmpty ??
                        false) ...[
                      SizedBox(height: 9.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Office Notes',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 315.w,
                            height: 140.h,
                            //  padding: EdgeInsets.symmetric(horizontal: 8.w),
                            //  decoration: BoxDecoration(
                            //    color: Colors.grey,
                            //    borderRadius: BorderRadius.circular(10.r),
                            //    border: Border.all(color: Colors.white),
                            //  ),
                            child: SingleChildScrollView(
                              child: TextField(
                                controller: _officeNotesController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                                maxLines: null,
                                enabled: false, // make text field not editable
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 9.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Field Notes',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 315.w,
                          height: 70.h,
                          //  padding: EdgeInsets.symmetric(horizontal: 8.w),
                          //  decoration: BoxDecoration(
                          //    color: Colors.white,
                          //    borderRadius: BorderRadius.circular(10.r),
                          //    border: Border.all(color: Colors.white),
                          //  ),
                          child: SingleChildScrollView(
                            child: TextField(
                              controller: _fieldNotesController,
                              focusNode: fieldNotesFocusNode,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              maxLines: null,
                              enabled: true, // make text field not editable
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 9.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            // Show/Hide ADD / GPS / Delete buttons
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                          onPressed: _toggleExpand,
                        ),
                      ],
                    ),
                    if (_isExpanded) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            // Add button
                            icon: Icon(
                              Icons.add_box_outlined,
                              color: Colors.green,
                              size: 40.sp,
                            ),
                            onPressed: () {
                              if (mounted) {
                                _showAddReadingDialog();
                                _toggleExpand();
                              }
                            },
                          ),
/*
                          IconButton(
                              icon: Icon(
                                Icons.add_a_photo_outlined,
                                color: Colors.yellowAccent,
                                size: 40.sp,
                              ),
                              onPressed: () {
                                final projectModel = Provider.of<ProjectModel>(context, listen: false);
                                final projectClient = projectModel.client;
                                final projectName = projectModel.projectName;
                                final tsNotifier = Provider.of<TSNotifier>(context, listen: false);
                                final projectID = tsNotifier.currentTestStation.projectID;
                                final stationID = tsNotifier.currentTestStation.id;
                                final stationArea = tsNotifier.currentTestStation.area;
                                final stationTSID = tsNotifier.currentTestStation.tsID;

                                if (stationID != null) {
                                  //  _showCamera(context, projectID, stationID, stationArea, stationTSID);
                                  CustomCamera.navigateToCustomCamera(
                                    context,
                                    projectID,
                                    projectClient,
                                    projectName,
                                    stationID: tsNotifier.currentTestStation.id,
                                    stationArea: stationArea,
                                    stationTSID: stationTSID,
                                  );
                                } else {
                                  // Handle or log error, as stationID is not valid
                                  if (kDebugMode) {
                                    print('Station ID is not valid.');
                                  }
                                }
                              }),
                              
*/
/*
                          LocationButton(
                            onLocationFetched: (latitude, longitude) {
                              Provider.of<TSNotifier>(context, listen: false).updateTestStation(
                                  widget.testStation,
                                  widget.testStation.area,
                                  widget.testStation.tsID,
                                  widget.testStation.tsstatus,
                                  widget.testStation.fieldNotes,
                                  widget.testStation.plTestLeadReadings,
                                  widget.testStation.permRefReadings,
                                  widget.testStation.anodeReadings,
                                  widget.testStation.shuntReadings,
                                  widget.testStation.riserReadings,
                                  widget.testStation.foreignReadings,
                                  widget.testStation.testLeadReadings,
                                  widget.testStation.couponReadings,
                                  widget.testStation.bondReadings,
                                  widget.testStation.isolationReadings,
                                  latitude: latitude,
                                  longitude: longitude,
                                  context: context);

                              setState(() {
                                widget.testStation.latitude = latitude;
                                widget.testStation.longitude = longitude;
                                _toggleExpand();
                              });
                            },
                            latitude: widget.testStation.latitude,
                            longitude: widget.testStation.longitude,
                          ),
*/
                          IconButton(
                            icon: Icon(
                              Icons.gps_fixed,
                              color: Colors.blue,
                              size: 40.sp,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GpsFixView(
                                    gpsBleService: Provider.of<GpsBleService>(
                                        context,
                                        listen: false),
                                    onCoordinatesUpdated:
                                        _updateTestStationCoordinates,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            // Delete button
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 40.sp,
                            ),
                            onPressed: () {
                              if (_readingContainers.isNotEmpty) {
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateTestStationCoordinates(double latitude, double longitude) {
    // Round to 6 decimal places
    double roundedLatitude = double.parse(latitude.toStringAsFixed(6));
    double roundedLongitude = double.parse(longitude.toStringAsFixed(6));

    Provider.of<TSNotifier>(context, listen: false).updateTestStation(
      widget.testStation,
      widget.testStation.area,
      widget.testStation.tsID,
      widget.testStation.tsstatus,
      widget.testStation.fieldNotes,
      widget.testStation.plTestLeadReadings,
      widget.testStation.permRefReadings,
      widget.testStation.anodeReadings,
      widget.testStation.shuntReadings,
      widget.testStation.riserReadings,
      widget.testStation.foreignReadings,
      widget.testStation.testLeadReadings,
      widget.testStation.couponReadings,
      widget.testStation.bondReadings,
      widget.testStation.isolationReadings,
      latitude: roundedLatitude,
      longitude: roundedLongitude,
      context: context,
    );

    setState(() {
      widget.testStation.latitude = roundedLatitude;
      widget.testStation.longitude = roundedLongitude;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Coordinates updated: $roundedLatitude, $roundedLongitude')),
    );
  }
}

/*
class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          panEnabled: false,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}
*/
