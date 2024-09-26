//import 'package:asset_inspections/Common_Widgets/acvolts_mm_button.dart';
import 'package:flutter/material.dart';

import 'package:asset_inspections/Common_Widgets/custom_radio.dart';
import 'package:asset_inspections/Common_Widgets/textfield_dropdown.dart';
import 'package:asset_inspections/Common_Widgets/volts_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:asset_inspections/Common_Widgets/bottomsheet_livegraph.dart';
import 'package:asset_inspections/Common_Widgets/custom_textfield.dart';
//import 'package:asset_inspections/Common_Widgets/dcvolts_button_cycled.dart';
import 'package:asset_inspections/Common_Widgets/dcvolts_mm_button.dart';
import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart';
//import 'package:asset_inspections/Test_Station/ts_notifier.dart';
import 'package:asset_inspections/database_helper.dart';

/// This is an abstract base container class that extends [StatefulWidget].
/// It provides common properties and methods for containers used in test stations.
///
/// The [BaseContainer] class takes a generic type parameter [T] and requires a list of [readings],
/// an optional [onReadingUpdated] callback function, a [currentTestStation] object,
/// and a [scaffoldMessengerKey] of type [GlobalKey<ScaffoldMessengerState>].
///
/// Subclasses of [BaseContainer] should override the [createState] method to return
/// an instance of [BaseContainerState].

abstract class BaseContainer<T> extends StatefulWidget {
  final List<T> readings;
  final ValueChanged<T>? onReadingUpdated;
  final TestStation currentTestStation;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Function(Widget)? onDelete;

  const BaseContainer({
    super.key,
    required this.readings,
    this.onReadingUpdated,
    required this.currentTestStation,
    required this.scaffoldMessengerKey,
    this.onDelete,
  });

  @override
  BaseContainerState createState();
}

//* Generic class to be used for all containers. This class defines the common functionality for all containers
//* All containers will extend this class and all widgets will be defined below
/// This is the abstract base class for container states.
/// It extends the State class and provides common variables and methods for all Test Station containers.
/// Containers are used in Test Station details pages.
abstract class BaseContainerState<T extends BaseContainer> extends State<T> {
  // Common variables for all containers
  int? id;
  int? projectID;
  int? orderIndex;
  TestStation? currentTestStation;
  TestStation testStation = TestStation(
    id: 0,
    projectID: 0,
    area: '',
    tsID: '',
    tsstatus: '',
  );

  //* Common variables for containers with ON and OFF readings
  bool isTimerActiveON = false;
  bool isTimerActiveOFF = false;
  bool isTimerActiveAC = false;
  bool userEditedOn = false;
  bool userEditedOff = false;
  bool userEditedAC = false;
  DateTime? initialVoltsONDate;
  DateTime? initialVoltsOFFDate;
  DateTime? initialvoltsACDate;
  bool showGraph = false;

  int? _passOrFail;

  //* Common variables for containers with Current readings
  bool userEditedCurrent = false;
  DateTime? initialCurrentDate;

  //* Common variables for containers with Wire Color & Lug Number dropdowns
  String? selectedWireColor;
  String? lastSavedWireColor;
  int? selectedLugNumber;
  int? lastSavedLugNumber;
  List<String> wireColors = [
    "Black",
    "Green",
    "White",
    "Yellow",
    "Red",
    "Light Blue",
    "Dark Blue",
    "White w/ Red",
    "White w/ Black",
    "Black w/ Red",
    "Green w/ Yellow"
  ];
  Map<String, List<Color>> colorMap = {
    "Black": [Colors.black],
    "Green": [Colors.green],
    "White": [Colors.white],
    "Yellow": [Colors.yellow],
    "Red": [Colors.red],
    "Light Blue": [Colors.lightBlue],
    "Dark Blue": [Colors.blue[800]!],
    "White w/ Red": [Colors.white, Colors.red],
    "White w/ Black": [Colors.white, Colors.black],
    "Black w/ Red": [Colors.black, Colors.red],
    "Green w/ Yellow": [Colors.green, Colors.yellow],
  };

// Method to create a color display widget
  Widget colorDisplay(String colorKey) {
    List<Color> colors = colorMap[colorKey]!;
    return Row(
      children: colors
          .map((color) => Expanded(
                child: Container(
                  color: color,
                  height: 12,
                ),
              ))
          .toList(),
    );
  }

  //* Common variables for containers with Shunt calculations
  List<String> fullNamesList = [];
  String? selectedSideA;
  String? selectedSideB;
  bool userEditedVoltageDrop = false;
  bool userEditedCalculated = false;
  DateTime? initialVoltageDropDate;
  DateTime? initialCalculatedDate;

  TextEditingController nameController = TextEditingController();

  TextEditingController? labelController;
  TextEditingController? acController;
  TextEditingController? onController;
  TextEditingController? offController;

  TextEditingController? currentController;
  TextEditingController? pipeDiameterController;

  TextEditingController? ratioMVController;
  TextEditingController? ratioAmpsController;
  TextEditingController? factorController;
  TextEditingController? vDropController;
  TextEditingController? calculatedController;

  FocusNode nameFocusNode = FocusNode();
  FocusNode? labelFocusNode;
  FocusNode? acFocusNode;
  FocusNode? onFocusNode;
  FocusNode? offFocusNode;

  FocusNode? currentFocusNode;
  FocusNode? pipeDiameterFocusNode;

  FocusNode? wireColorNode;
  FocusNode? lugNumberNode;

  FocusNode? ratioMVFocusNode;
  FocusNode? ratioAmpsFocusNode;
  FocusNode? factorFocusNode;
  FocusNode? vDropFocusNode;
  FocusNode? calculatedFocusNode;

  // Getter for the container name
  String get containerName;

  @override
  void initState() {
    super.initState();

    initializeControllers();
    initializeFocusNodes();
    // initializeWireColorAndLugNumber();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeAsyncData();
    });
  }

  void deleteContainer();

/*
  void initializeWireColorAndLugNumber() {
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      wireColorNode.addListener(_handleWireColorFocusChange);
      lugNumberNode.addListener(_handleLugNumberFocusChange);

      // Initialize selectedWireColor
      if (widget.readings.isNotEmpty && widget.readings[0].wireColor != null) {
        selectedWireColor = widget.readings[0].wireColor;
      }
      // Initialize selectedLugNumber
      if (widget.readings.isNotEmpty && widget.readings[0].lugNumber != null) {
        selectedLugNumber = widget.readings[0].lugNumber;
      }
    }
  }
*/
  /// Initializes the asynchronous data for the abstract base container.
  /// - Assigns the value of `widget.currentTestStation` to the `currentTestStation` variable.
  /// - Sets the value of the [nameController] based on the first reading's name in the [widget.readings] list, or an empty string if the list is empty.
  /// - Sets the [orderIndex] based on the first reading's orderIndex in the widget's readings list, if it is not empty.
  /// - Checks if the container is 'ShuntContainers' and loads data if it is.
  void initializeAsyncData() async {
    // Assigns the value of `widget.currentTestStation` to the `currentTestStation` variable.
    currentTestStation = widget.currentTestStation;

    // Sets the value of the [nameController] based on the first reading's name in the [widget.readings] list, or an empty string if the list is empty.
    nameController.text = widget.readings.isNotEmpty ? widget.readings[0].name : '';

    // Set the orderIndex based on the first reading's orderIndex in the widget's readings list, if it is not empty
    if (widget.readings.isNotEmpty) {
      setState(() {
        orderIndex = widget.readings[0].orderIndex;
      });
    }

    // Check if the container is 'ShuntContainers' and load data if it is
    if (containerName == 'ShuntContainers') {
      await loadShuntNames();
    }

    if (containerName == 'IsolationContainers') {
      _passOrFail = widget.readings.isNotEmpty ? widget.readings[0].shorted : 0;
    }
  }

  /// Initializes the text editing controllers based on the container name.
  ///
  /// If the container name is 'PLTestLeadContainers', 'TestLeadContainers', 'ForeignContainers',
  /// 'RiserContainers', 'PermRefContainers', 'AnodeContainers', or 'CouponContainers',
  /// the [onController] and [offController] are initialized with the corresponding values from the [widget.readings].
  /// The [initialVoltsONDate] and [initialVoltsOFFDate] are set to the corresponding values from the [widget.readings].
  ///
  /// If the container name is 'ShuntContainers', the [ratioMVController], [ratioAmpsController], [factorController],
  /// [vDropController], [calculatedController] are initialized with the corresponding values from the [widget.readings].
  /// The [initialVoltageDropDate] and [initialCalculatedDate] are set to the corresponding values from the [widget.readings].
  ///
  /// Finally, the [setUpControllers] method is called to perform additional setup.
  void initializeControllers() {
    labelController = TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].label != null ? widget.readings[0].label : '');

    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'ShuntContainers' ||
        containerName == 'IsolationContainers' ||
        containerName == 'BondContainers' ||
        containerName == 'CouponContainers') {
      acController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].voltsAC != null ? widget.readings[0].formattedvoltsAC : '');
      initialvoltsACDate = widget.readings.isNotEmpty && widget.readings[0].voltsACDate != null ? widget.readings[0].voltsACDate : null;
    }

    // Initialize Containers with ON and OFF readings
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      onController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].voltsON != null ? widget.readings[0].formattedVoltsON : '');
      offController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].voltsOFF != null ? widget.readings[0].formattedVoltsOFF : '');
      initialVoltsONDate = widget.readings.isNotEmpty && widget.readings[0].voltsONDate != null ? widget.readings[0].voltsONDate : null;
      initialVoltsOFFDate = widget.readings.isNotEmpty && widget.readings[0].voltsOFFDate != null ? widget.readings[0].voltsOFFDate : null;
    }

    // Initialize the controllers for ShuntContainers
    if (containerName == 'ShuntContainers') {
      ratioMVController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].ratioMV != null ? widget.readings[0].formattedratioMV : '');
      ratioAmpsController = TextEditingController(
          text: widget.readings.isNotEmpty && widget.readings[0].ratioAMPS != null ? widget.readings[0].formattedratioAMPS : '');
      factorController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].factor != null ? widget.readings[0].formattedfactor : '');
      vDropController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].vDrop != null ? widget.readings[0].formattedvDrop : '');
      calculatedController = TextEditingController(
          text: widget.readings.isNotEmpty && widget.readings[0].calculated != null ? widget.readings[0].formattedcalculated : '');
      initialVoltageDropDate = widget.readings.isNotEmpty && widget.readings[0].vDropDate != null ? widget.readings[0].vDropDate : null;
      initialCalculatedDate = widget.readings.isNotEmpty && widget.readings[0].calculatedDate != null ? widget.readings[0].calculatedDate : null;
    }

    // Initialize Containers with Current readings
    if (containerName == 'AnodeContainers' || containerName == 'IsolationContainers') {
      currentController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].current != null ? widget.readings[0].formattedCurrent : '');
      initialCurrentDate = widget.readings.isNotEmpty && widget.readings[0].currentDate != null ? widget.readings[0].currentDate : null;
    }

    // Iniialize Containers with Pipe Diameters
    if (containerName == 'RiserContainers') {
      pipeDiameterController = TextEditingController(
          text: widget.readings.isNotEmpty && widget.readings[0].pipeDiameter != null ? widget.readings[0].formattedPipeDiameter : '');
    }
    setUpControllers();
  }

  /// Sets up the controllers and listeners for the abstract base container.
  ///
  /// This method sets up controller listeners for ON and OFF readings, as well as
  /// controller listeners for Shunt calculations. For certain container names,
  /// the [onController] and [offController] listeners are added to track user edits.
  /// For the 'ShuntContainers' container name, additional listeners for [ratioMVController],
  /// [ratioAmpsController], [factorController], [vDropController], and [calculatedController]
  /// are added to update calculated values and track user edits.
  void setUpControllers() {
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'ShuntContainers' ||
        containerName == 'IsolationContainers' ||
        containerName == 'BondContainers' ||
        containerName == 'CouponContainers') {
      acController?.addListener(() {
        userEditedAC = true;
      });
    }
    // Setup controller listeners for ON and OFF readings
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      onController?.addListener(() {
        userEditedOn = true;
      });
      offController?.addListener(() {
        userEditedOff = true;
      });
    }

    // Setup controller listeners for Shunt calculations
    if (containerName == 'ShuntContainers') {
      ratioMVController?.addListener(() {
        updateFactor();
      });
      ratioAmpsController?.addListener(() {
        updateFactor();
      });
      factorController?.addListener(() {
        updateCalculated();
      });
      vDropController?.addListener(() {
        userEditedVoltageDrop = true;
        updateCalculated();
      });
      calculatedController?.addListener(() {
        userEditedCalculated = true;
        updateCalculated();
      });
    }

    // Setup controller listeners for Current readings
    if (containerName == 'AnodeContainers') {
      currentController?.addListener(() {
        userEditedCurrent = true;
      });
    }

    // Setup controller listeners for Pipe Diameters
    if (containerName == 'RiserContainers') {
      pipeDiameterController?.addListener(() {
        userEditedCurrent = true;
      });
    }
  }

  /// Initializes the focus nodes based on the container type.
  /// If the container name is [PLTestLeadContainers], [TestLeadContainers],
  /// [ForeignContainers], [RiserContainers], [PermRefContainers],
  /// [AnodeContainers], or [CouponContainers], it creates [onFocusNode] and offFocusNode.
  /// If the container name is [ShuntContainers], it creates ratioMVFocusNode,
  /// ratioAmpsFocusNode, factorFocusNode, vDropFocusNode, and calculatedFocusNode.
  /// Finally, it calls setUpFocusNodes().
  void initializeFocusNodes() {
    labelFocusNode = FocusNode();

    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'ShuntContainers' ||
        containerName == 'IsolationContainers' ||
        containerName == 'BondContainers' ||
        containerName == 'CouponContainers') {
      acFocusNode = FocusNode();
    }

    // Initialize focus nodes for containers with ON and OFF readings
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      onFocusNode = FocusNode();
      offFocusNode = FocusNode();
    }

    // Initialize focus nodes for ShuntContainers
    if (containerName == 'ShuntContainers') {
      ratioMVFocusNode = FocusNode();
      ratioAmpsFocusNode = FocusNode();
      factorFocusNode = FocusNode();
      vDropFocusNode = FocusNode();
      calculatedFocusNode = FocusNode();
    }

    //Initialize foucus nodes for containers with Current readings
    if (containerName == 'AnodeContainers' || containerName == 'IsolationContainers') {
      currentFocusNode = FocusNode();
    }

/*
    // Initialize foucus nodes for containers with Wire Color and Lug Number
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      wireColorNode = FocusNode();
      lugNumberNode = FocusNode();
    }

*/
    // Initialize focus nodes for Pipe Diameters
    if (containerName == 'RiserContainers') {
      pipeDiameterFocusNode = FocusNode();
    }

    setUpFocusNodes();
  }

  /// Sets up the focus nodes for the abstract base container.
  void setUpFocusNodes() {
    nameFocusNode.addListener(() {
      if (!nameFocusNode.hasFocus) {
        saveOrUpdateReading(containerName, []);
      }
    });

    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'ShuntContainers' ||
        containerName == 'IsolationContainers' ||
        containerName == 'BondContainers' ||
        containerName == 'CouponContainers') {
      acFocusNode?.addListener(() {
        if (!acFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });

      labelFocusNode?.addListener(() {
        if (!labelFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
    }

    // Only add listeners to onFocusNode and offFocusNode if they are not null
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      onFocusNode?.addListener(() {
        if (!onFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      offFocusNode?.addListener(() {
        if (!offFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      wireColorNode?.addListener(() {
        if (!wireColorNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      lugNumberNode?.addListener(() {
        if (!lugNumberNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
    }

    // Only add listeners to ShuntContainers' focus nodes if they are not null
    if (containerName == 'ShuntContainers') {
      ratioMVFocusNode?.addListener(() {
        if (!ratioMVFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      ratioAmpsFocusNode?.addListener(() {
        if (!ratioAmpsFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      factorFocusNode?.addListener(() {
        if (!factorFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      vDropFocusNode?.addListener(() {
        if (!vDropFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      calculatedFocusNode?.addListener(() {
        if (!calculatedFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
    }

    // Only add listeners to Current focus nodes if they are not null
    if (containerName == 'AnodeContainers' || containerName == 'IsolationContainers') {
      currentFocusNode?.addListener(() {
        if (!currentFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
    }

    // Only add listeners to Pipe Diameter focus nodes if they are not null
    if (containerName == 'RiserContainers') {
      pipeDiameterFocusNode?.addListener(() {
        if (!pipeDiameterFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
    }

    // Only add listeners to Wire Color and Lug Number focus nodes if they are not null
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      wireColorNode?.addListener(() {
        if (!wireColorNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      lugNumberNode?.addListener(() {
        if (!lugNumberNode!.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
    }
  }

/*
  void _handleWireColorFocusChange() {
    if (!wireColorNode.hasFocus) {
      // Trigger function when the dropdown loses focus
      saveOrUpdateReading(containerName, []);
    }
  }

  void _handleLugNumberFocusChange() {
    if (!lugNumberNode.hasFocus) {
      // Trigger function when the dropdown loses focus
      saveOrUpdateReading(containerName, []);
    }
  }
*/
  @override
  void dispose() {
    /*
    nameController.dispose();
    onController?.dispose();
    offController?.dispose();
    ratioMVController?.dispose();
    ratioAmpsController?.dispose();
    factorController?.dispose();
    vDropController?.dispose();
    calculatedController?.dispose();
    nameFocusNode.dispose();
    onFocusNode?.dispose();
    offFocusNode?.dispose();
    ratioMVFocusNode?.dispose();
    ratioAmpsFocusNode?.dispose();
    factorFocusNode?.dispose();
    vDropFocusNode?.dispose();
    calculatedFocusNode?.dispose();
    wireColorNode?.dispose();
    lugNumberNode?.dispose();
    currentController?.dispose();
    currentFocusNode?.dispose();
    pipeDiameterController?.dispose();
    pipeDiameterFocusNode?.dispose();
    */
    super.dispose();
  }

  /// Formats the [dateTime] object into a readable string.
  String? formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      // Format the DateTime object into a readable string
      return DateFormat('yyyy-MM-dd – kk:mm:ss').format(dateTime);
    } else {
      // Return null if the date is null
      return null;
    }
  }

  /// Saves or updates the reading based on the container name.
  ///
  /// The [containerName] parameter specifies the type of container.
  /// The reading is saved or updated based on the container type.
  /// The [containerName] can be one of the following:
  /// - 'PLTestLeadContainers'
  /// - 'TestLeadContainers'
  /// - 'ForeignContainers'
  /// - 'RiserContainers'
  /// - 'PermRefContainers'
  /// - 'AnodeContainers'
  /// - 'CouponContainers'
  /// - 'ShuntContainers'
  ///
  /// The reading information is retrieved from the UI elements and stored in a [readingMap].
  /// The [readingMap] contains the following key-value pairs:
  /// - 'stationID': The ID of the current test station.
  /// - 'testStationID': The ID of the test station.
  /// - 'name': The name of the container.
  /// - 'order_index': The order index of the container.
  ///
  /// For specific container types, additional information is added to the [readingMap].
  /// - For 'PLTestLeadContainers', 'TestLeadContainers', 'ForeignContainers',
  ///   'RiserContainers', 'PermRefContainers', 'AnodeContainers', and 'CouponContainers':
  ///   - 'voltsON': The ON voltage value.
  ///   - 'voltsON_Date': The date and time when the ON voltage value was recorded.
  ///   - 'voltsOFF': The OFF voltage value.
  ///   - 'voltsOFF_Date': The date and time when the OFF voltage value was recorded.
  ///
  /// - For 'ShuntContainers':
  ///   - 'side_a': The value of side A.
  ///   - 'side_b': The value of side B.
  ///   - 'ratio_mv': The ratio in millivolts.
  ///   - 'ratio_current': The ratio in amps.
  ///   - 'factor': The factor value.
  ///   - 'voltage_drop': The voltage drop value.
  ///   - 'voltage_drop_Date': The date and time when the voltage drop value was recorded.
  ///   - 'calculated': The calculated value.
  ///   - 'calculated_Date': The date and time when the calculated value was recorded.
  ///
  /// The reading information is then passed to the [performDbOperation] method
  /// to perform the database operation.
  void saveOrUpdateReading(String containerName, [List<String> waveForm = const []]) {
    int id = widget.currentTestStation.id ?? 0;
    String tsID = widget.currentTestStation.tsID;
    int currentOrderIndex = orderIndex!;

    String? sideAValue = selectedSideA ?? '';
    String? sideBValue = selectedSideB ?? '';

    String currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    var readingMap = {
      'stationID': widget.currentTestStation.id,
      'testStationID': tsID,
      'name': nameController.text,
      'order_index': currentOrderIndex,
    };

    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'ShuntContainers' ||
        containerName == 'IsolationContainers' ||
        containerName == 'BondContainers' ||
        containerName == 'CouponContainers') {
      readingMap['label'] = labelController?.text ?? '';

      if (userEditedAC) {
        readingMap['voltsAC'] = double.tryParse(acController?.text ?? '');
        readingMap['voltsACDate'] = currentTime;
      }
    }

    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      if (waveForm.isNotEmpty) {
        readingMap['waveForm'] = waveForm.join(';');
      }

      if (userEditedAC) {
        readingMap['voltsAC'] = double.tryParse(acController?.text ?? '');
        readingMap['voltsACDate'] = currentTime;
      }
      if (userEditedOn) {
        readingMap['voltsON'] = double.tryParse(onController?.text ?? '');
        readingMap['voltsON_Date'] = currentTime;
      }

      if (userEditedOff) {
        readingMap['voltsOFF'] = double.tryParse(offController?.text ?? '');
        readingMap['voltsOFF_Date'] = currentTime;
      }
/*
      if (selectedWireColor != lastSavedWireColor) {
        lastSavedWireColor = selectedWireColor;
        readingMap['wireColor'] = selectedWireColor;
      }

      if (selectedLugNumber != lastSavedLugNumber) {
        lastSavedLugNumber = selectedLugNumber;
        readingMap['lugNumber'] = selectedLugNumber;
      }
*/
      userEditedAC = false;
      userEditedOn = false;
      userEditedOff = false;
    }

    if (containerName == 'AnodeContainers' || containerName == 'IsolationContainers') {
      if (userEditedCurrent) {
        readingMap['current'] = double.tryParse(currentController?.text ?? '');
        readingMap['current_Date'] = currentTime;
      }
      userEditedCurrent = false;
    }

    if (containerName == 'IsolationContainers') {
      readingMap['iso_condition'] = _passOrFail;
    }

    if (containerName == 'RiserContainers') {
      readingMap['pipe_Diameter'] = double.tryParse(pipeDiameterController?.text ?? '');
    }

    if (containerName == 'ShuntContainers') {
      readingMap['side_a'] = sideAValue;
      readingMap['side_b'] = sideBValue;
      readingMap['ratio_mv'] = double.tryParse(ratioMVController?.text ?? '');
      readingMap['ratio_current'] = double.tryParse(ratioAmpsController?.text ?? '');
      readingMap['factor'] = double.tryParse(factorController?.text ?? '');

      if (userEditedVoltageDrop) {
        readingMap['voltage_drop'] = double.tryParse(vDropController?.text ?? '');
        readingMap['voltage_drop_Date'] = currentTime;
      }

      if (userEditedCalculated) {
        readingMap['calculated'] = double.tryParse(calculatedController?.text ?? '');
        readingMap['calculated_Date'] = currentTime;
      }
      userEditedVoltageDrop = false;
      userEditedCalculated = false;
    }

    performDbOperation(id, tsID, readingMap, containerName);
  }

  /// Performs a database operation to insert or update a reading.
  ///
  /// The [stationID] parameter specifies the ID of the station.
  /// The [tsID] parameter specifies the ID of the test station.
  /// The [readingMap] parameter is a map containing the reading data.
  /// The [containerName] parameter specifies the name of the container.
  ///
  /// This method inserts or updates the reading in the database using the [DatabaseHelper].
  /// If the operation is successful and an ID is returned, a snackbar with the message "Reading Saved!" is shown.
  /// If the operation fails, a snackbar with the message "Failed to Save Reading!" is shown.
  /// If an error occurs during the operation, a snackbar with the error message is shown.
  void performDbOperation(int stationID, String tsID, Map<String, dynamic> readingMap, String containerName) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    await dbHelper.insertOrUpdateReading(stationID, readingMap, containerName).then((insertedId) {
      if (insertedId > 0) {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Reading Saved!')),
        );
      } else {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Failed to Save Reading!')),
        );
      }
    }).catchError((e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    });
  }

  /// Handles the status change of the timer for turning ON.
  ///
  /// This method updates the [isTimerActiveON] state variable with the provided [status].
  void handleTimerStatusChangedON(bool status) {
    Future.delayed(Duration.zero, () {
      setState(() {
        isTimerActiveON = status;
      });
    });
  }

  /// Handles the status change of the timer for turning OFF.
  ///
  /// This method updates the [isTimerActiveOFF] state variable with the provided [status].
  void handleTimerStatusChangedOFF(bool status) {
    Future.delayed(Duration.zero, () {
      setState(() {
        isTimerActiveOFF = status;
      });
    });
  }

  /// Handles the status change of the timer for AC voltage.
  /// This method updates the [isTimerActiveAC] state variable with the provided [status].
  /// The [status] parameter is a boolean value that indicates whether the timer is active.
  void handleTimerStatusChangedAC(bool status) {
    Future.delayed(Duration.zero, () {
      setState(() {
        isTimerActiveAC = status;
      });
    });
  }

  /// Toggles the visibility of the graph.
  ///
  /// This method toggles the value of the [showGraph] state variable.
  void toggleGraph() {
    setState(() {
      showGraph = !showGraph;
    });
  }

  /// Loads data from the database.
  ///
  /// This method retrieves the names of shunts associated with the current test station
  /// and updates the [fullNamesList] state variable.
  Future<void> loadShuntNames() async {
    String testStationID = widget.currentTestStation.tsID;
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<String> names = await dbHelper.fetchNamesForShunt(testStationID);

    if (mounted) {
      setState(() {
        fullNamesList = names;
      });
    }
  }

  Future<List<String>> loadLabels(String testStationID) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<String> labels = await dbHelper.fetchNamesForLabel();
    return labels;
  }

  /// Updates the factor based on the ratio values.
  ///
  /// This method calculates the factor using the ratio values entered in the [ratioMVController]
  /// and [ratioAmpsController] text fields. It updates the [factorController] text field
  /// with the formatted factor value.
  void updateFactor() {
    double? ratioMV = double.tryParse(ratioMVController!.text);
    double? ratioAmps = double.tryParse(ratioAmpsController!.text);

    if (ratioMV != null && ratioAmps != null) {
      double factor = ratioAmps / ratioMV;
      factorController?.text = formatNumbers(factor);
    }
  }

  /// Updates the calculated value based on the entered vDrop and factor.
  /// If both vDrop and factor are valid numbers, the calculated value is updated
  /// by multiplying vDrop with factor. The result is then formatted and set as
  /// the text of the calculatedController. Finally, the data is reloaded.
  Future<void> updateCalculated() async {
    double? vDrop = double.tryParse(vDropController!.text);
    double? factor = double.tryParse(factorController!.text);

    if (vDrop != null && factor != null) {
      double calculated = vDrop * factor;
      calculatedController?.text = formatNumbers(calculated);
    }
    // _saveOrUpdateReading();
    await loadShuntNames();
  }

  /// Formats a given [value] into a string representation.
  /// If the value is an integer, it returns the integer as a string.
  /// If the value is a decimal, it returns the decimal with 2 decimal places as a string.
  String formatNumbers(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Builds the content of the abstract base container widget.
  ///
  /// This method is responsible for constructing the visual representation of the abstract base container.
  /// It takes several optional parameters that allow customization of the container's appearance and content.
  ///
  /// - The [context] parameter is the build context.
  /// - The [onReadingRow] parameter is a widget that represents the on-reading row.
  /// - The [offReadingRow] parameter is a widget that represents the off-reading row.
  /// - The [bottomGraph] parameter is a widget that represents the bottom graph.
  /// - The [sideAtoSideB] parameter is a widget that represents the side A to side B dropdowns.
  /// - The [shuntCalculationRows] parameter is a widget that represents the shunt calculation rows.
  ///
  /// Returns a [Widget] that represents the abstract base container.
  //TODO: Add Location Description field
  @protected
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
    SizedBox(height: 5.h);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 43, 92),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 1.1,
                    child: Text(
                      nameController.text.isEmpty ? 'Default Text' : nameController.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                      ), // Your text style here
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    //  heightFactor: 1.5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.white,
                          iconSize: 18.sp,
                          onPressed: deleteContainer,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Color.fromARGB(255, 247, 143, 30),
                thickness: 1,
              ),
              SizedBox(height: 5.h),
              if (labelRow != null) labelRow, // Include the labelRow if provided
              if (acReadingRow != null) acReadingRow, // Include the acReadingRow if provided
              if (onReadingRow != null) onReadingRow, // Include the onReadingRow if provided
              //SizedBox(height: 10.h),
              if (offReadingRow != null) offReadingRow,

              if (wireColorAndLugNumberRow != null) wireColorAndLugNumberRow, // Include the offReadingRow if provided
              //SizedBox(height: 10.h),
              if (bottomGraph != null) bottomGraph, // Include the bottomGraph if provided
              //SizedBox(height: 10.h),
              if (sideAtoSideB != null) sideAtoSideB, // Include the sideAtoSideBDropdowns if provided
              //SizedBox(height: 10.h),
              if (shuntCalculationRows != null) shuntCalculationRows, // Include the shuntCalculationRows if provided
              if (passFailRow != null) passFailRow,
              if (currentReadingRow != null) currentReadingRow,

              if (pipeDiameterRow != null) pipeDiameterRow,
            ],
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget buildLabelRow(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 5.h),
        Stack(
          children: [
            Row(
              children: [
                Text('Label: ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                const Spacer(),
                SizedBox(
                  width: 170.w,
                  child: LabelTextField(
                    testStationID: widget.currentTestStation.tsID, // Replace with your test station ID
                    fetchNamesForLabel: loadLabels,
                    controller: labelController,
                    focusNode: labelFocusNode,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 5.h),
      ],
    );
  }

  @protected
  Widget buildACReadingRow(BuildContext context) {
    String? formattedvoltsACDate = formatDateTime(initialvoltsACDate);
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          children: [
            Text('AC Volts: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            if (BluetoothManager.instance.pokitProModel != null)
              VoltageButton(
                cycleMode: CycleMode.staticMode,
                selectedMode: Mode.acVoltage,
                multimeterService: Provider.of<MultimeterService>(context, listen: false),
                acController: acController,
                onTimerStatusChanged: handleTimerStatusChangedAC,
                onSaveOrUpdate: saveOrUpdateReading,
                containerName: containerName,
              ),
            /*
              ACvoltsMMButton(
                selectedMode: Mode.acVoltage,
                controller: acController,
                multimeterService: Provider.of<MultimeterService>(context),
                onTimerStatusChanged: handleTimerStatusChangedAC,
                onSaveOrUpdate: saveOrUpdateReading,
                containerName: containerName,
              ),
          */
            const Spacer(),
            SizedBox(
                child: CustomTextField(
              controller: acController,
              focusNode: acFocusNode,
              style: TextStyle(
                color: isTimerActiveAC ? Colors.red : Colors.green,
                fontSize: 22.sp,
                fontStyle: isTimerActiveAC ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.bold,
              ),
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: 'V AC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              width: 160.w,
              height: 40.h,
            )),
          ],
        ),
        if (formattedvoltsACDate != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 160.w,
                height: 15.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.update_sharp,
                      color: Colors.white,
                      size: 11.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      formattedvoltsACDate,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: 12.h),
      ],
    );
  }

  /// Builds the row for the ON reading in the UI of the abstract base container.
  ///
  /// This method returns a [Column] widget that contains a [Row] widget with the OFF label,
  /// a [DCvoltsButtonCycled] widget (if the Pokit Pro model is available), and a [CustomTextField]
  /// widget for entering the ON reading. It also displays the last updated date of the ON reading.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildONReadingRow(BuildContext context) {
    String? formattedVoltsONDate = formatDateTime(initialVoltsONDate);
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          children: [
            Text('ON: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            if (BluetoothManager.instance.pokitProModel != null)
              VoltageButton(
                cycleMode: CycleMode.cycledMode,
                selectedMode: Mode.dcVoltage,
                onController: onController,
                offController: offController,
                multimeterService: Provider.of<MultimeterService>(context, listen: false),
                onTimerStatusChanged: handleTimerStatusChangedON,
                offTimerStatusChanged: handleTimerStatusChangedOFF,
                onSaveOrUpdate: saveOrUpdateReading,
                onButtonPressed: toggleGraph,
                containerName: containerName,
              ),

/*
              DCvoltsButtonCycled(
                onController: onController,
                offController: offController,
                multimeterService: Provider.of<MultimeterService>(context, listen: false),
                onTimerStatusChanged: handleTimerStatusChangedON,
                offTimerStatusChanged: handleTimerStatusChangedOFF,
                onSaveOrUpdate: saveOrUpdateReading,
                onButtonPressed: toggleGraph,
                containerName: containerName,
              ),
              */
            const Spacer(),
            SizedBox(
                child: CustomTextField(
              controller: onController,
              focusNode: onFocusNode,
              style: TextStyle(
                //TODO: Color needs to be moved to only be used when DCVoltsButtonCycled is used
                color: isTimerActiveON ? Colors.red : Colors.green,
                fontSize: 22.sp,
                fontStyle: isTimerActiveON ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.bold,
              ),
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: '-V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextSpan(text: ' CSE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              width: 160.w,
              height: 40.h,
            )),
          ],
        ),
        if (formattedVoltsONDate != null) //SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 160.w,
                height: 15.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(),
                    const Icon(
                      Icons.update_sharp,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      formattedVoltsONDate,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: 5.h),
      ],
    );
  }

  /// Builds a row for displaying the OFF reading in the UI of the abstract base container.
  ///
  /// This method returns a [Column] widget that contains a [Row] widget with the OFF label,
  /// a [DCvoltsMMButton] widget (if the Pokit Pro model is available), and a [CustomTextField]
  /// widget for entering the OFF reading. It also displays the last updated date of the OFF reading.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildOFFReadingRow(BuildContext context) {
    String? formattedVoltsOFFDate = formatDateTime(initialVoltsOFFDate);
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          children: [
            Text('OFF: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            if (BluetoothManager.instance.pokitProModel != null)
              DCvoltsMMButton(
                selectedMode: Mode.dcVoltage, // Adapt based on your needs
                controller: offController,
                multimeterService: Provider.of<MultimeterService>(context, listen: false),
                onTimerStatusChanged: handleTimerStatusChangedOFF,
                onSaveOrUpdate: (String value) {
                  saveOrUpdateReading(value, []);
                },
                containerName: containerName,
              ),
            const Spacer(),
            SizedBox(
                child: CustomTextField(
              controller: offController,
              focusNode: offFocusNode,
              style: TextStyle(
                color: isTimerActiveOFF ? Colors.red : Colors.green,
                fontSize: 22.sp,
                fontStyle: isTimerActiveOFF ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.bold,
              ),
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: '-V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextSpan(text: ' CSE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              width: 160.w,
              height: 40.h,
            )),
          ],
        ),
        if (formattedVoltsOFFDate != null) // SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 160.w,
                height: 15.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.update_sharp,
                      color: Colors.white,
                      size: 11.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      formattedVoltsOFFDate,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget buildCurrentReadingRow(BuildContext context) {
    String? formattedCurrentDate = formatDateTime(initialCurrentDate);
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          children: [
            Text('Current: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            SizedBox(
                child: CustomTextField(
              controller: currentController,
              focusNode: currentFocusNode,
              style: TextStyle(
                color: Colors.black,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: 'A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              width: 160.w,
              height: 40.h,
            )),
          ],
        ),
        if (formattedCurrentDate != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 160.w,
                height: 15.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(),
                    const Icon(
                      Icons.update_sharp,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      formattedCurrentDate,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: 5.h),
      ],
    );
  }

  Widget buildPipeDiameterRow(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          children: [
            Text('Riser Diameter: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            SizedBox(
                child: CustomTextField(
              controller: pipeDiameterController,
              focusNode: pipeDiameterFocusNode,
              style: TextStyle(
                color: Colors.black,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: '"', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              width: 160.w,
              height: 40.h,
            )),
          ],
        ),
        SizedBox(height: 5.h),
      ],
    );
  }

  Widget buildPassFailRow(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadio(
              groupValue: _passOrFail,
              value: 1,
              onChanged: (value) {
                setState(() {
                  _passOrFail = value;
                  saveOrUpdateReading(containerName, []);
                });
              },
            ),
            SizedBox(width: 10.w),
            Text('Pass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(width: 50.w),
            CustomRadio(
              groupValue: _passOrFail,
              value: 2,
              onChanged: (value) {
                setState(() {
                  _passOrFail = value;
                  saveOrUpdateReading(containerName, []);
                });
              },
            ),
            SizedBox(width: 10.w),
            Text('Fail',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        SizedBox(height: 25.h),
      ],
    );
  }

  Widget buildWireColorAndLugNumberRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          // Ensures the dropdown takes up available space and has bounded constraints
          child: Container(
            height: 40.h,
            //  width: 140.w,
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white, // White background color
              borderRadius: BorderRadius.circular(4.0), // Rounded corners
              border: Border.all(color: Colors.grey[300]!), // Grey border
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[200],
                value: selectedWireColor,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedWireColor = newValue;
                  });
                },
                focusNode: wireColorNode,
                style: TextStyle(color: Colors.black, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Wire Color',
                  hintStyle: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    // Minimal border adjustments
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.h), // Reduced padding
                  alignLabelWithHint: true,
                ),
                items: colorMap.keys.map<DropdownMenuItem<String>>((String colorKey) {
                  return DropdownMenuItem<String>(
                    value: colorKey,
                    child: Row(
                      children: [
                        Container(
                          width: 15,
                          height: 15,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.black, width: 1), // Black border
                          ),
                          child: colorDisplay(colorKey),
                        ),
                        Text(colorKey),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          flex: 2,
          child: Container(
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<int>(
                dropdownColor: Colors.grey[200],
                menuMaxHeight: 300.h,
                value: selectedLugNumber,
                onChanged: (value) {
                  setState(() {
                    selectedLugNumber = value;
                  });
                },
                focusNode: lugNumberNode,
                style: TextStyle(color: Colors.black, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Lug Number',
                  hintStyle: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 2.h), // Adjusted padding
                  alignLabelWithHint: true,
                ),
                items: List<int>.generate(15, (int index) => index + 1).map<DropdownMenuItem<int>>((int number) {
                  return DropdownMenuItem<int>(
                    value: number,
                    child: Text(number.toString()),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the bottom graph widget.
  ///
  /// This method returns a widget that displays a bottom graph. If [showGraph] is false,
  /// it returns an empty SizedBox. Otherwise, it returns a Container widget with a
  /// specified height, width, and decoration. The child of the Container is a
  /// BottomSheetLiveGraph widget.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildBottomGraph(BuildContext context) {
    if (!showGraph) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(2.sp),
      height: 350.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const BottomSheetLiveGraph(),
    );
  }

  /// Builds the dropdowns for Side A and Side B selection.
  ///
  /// This method returns a [Column] widget containing the dropdowns for selecting Side A and Side B.
  /// The dropdowns are styled with a filled background, border, and dropdown items.
  /// The selected values for Side A and Side B are stored in [selectedSideA] and [selectedSideB] variables respectively.
  /// The dropdown items are generated from the [fullNamesList] excluding the currently selected value for the other side.
  /// When a dropdown value is changed, the corresponding selected value is updated and the [saveOrUpdateReading] method is called.
  /// The method also displays a text indicating the direction of current travels from Side A to Side B.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildSideAtoSideBDropdowns(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Side A:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(
                  width: 140.w,
                  height: 40.h,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(color: Colors.grey, width: 1.5.w),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: selectedSideA,
                      items: fullNamesList.where((item) => item != selectedSideB).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              )),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSideA = newValue;
                        });
                        saveOrUpdateReading(containerName, []
                            //newValue ?? '', _selectedSideB ?? ''
                            );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 15.h,
                ),
                Icon(Icons.arrow_forward, color: Colors.white, size: 30.sp),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Side B:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(
                  width: 140.w,
                  height: 40.h,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(color: Colors.grey, width: 1.5.w),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: selectedSideB,
                      items: fullNamesList.where((item) => item != selectedSideA).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              )),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSideB = newValue;
                        });
                        saveOrUpdateReading(containerName, []
                            //_selectedSideA ?? '', newValue ?? ''
                            );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              '-Current travels from Side A to Side B-',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
      ],
    );
  }

  /// Builds the rows for shunt calculation in the abstract base container.
  ///
  /// This method returns a [Column] widget that contains the UI elements for shunt calculation.
  /// It includes text fields for entering ratio (in amps and millivolts), factor (in amps per millivolt),
  /// voltage drop (in millivolts), and current (in amps). The UI elements are styled with specific fonts,
  /// colors, and sizes.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildShuntCalculationRows(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Ratio:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            CustomTextField(
              controller: ratioAmpsController,
              focusNode: ratioAmpsFocusNode,
              keyboardType: TextInputType.number,
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: 'A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    //  TextSpan(text: ' CSE', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              width: 120.w,
              height: 40.h,
            ),
            const Spacer(),
            Text(' / ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: ratioMVController,
                  focusNode: ratioMVFocusNode,
                  keyboardType: TextInputType.number,
                  hintText: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: const [
                        TextSpan(text: 'mV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        //  TextSpan(text: ' CSE', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  width: 120.w,
                  height: 40.h,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Factor:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            CustomTextField(
              controller: factorController,
              focusNode: factorFocusNode,
              keyboardType: TextInputType.number,
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: 'A/mV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    //  TextSpan(text: ' CSE', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              width: 240.w,
              height: 40.h,
            ),
            const Spacer(),
          ],
        ),
        SizedBox(height: 15.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voltage Drop:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                CustomTextField(
                  controller: vDropController,
                  focusNode: vDropFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  hintText: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: const [
                        TextSpan(text: 'mV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        // TextSpan(text: ' CSE', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  width: 140.w,
                  height: 40.h,
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Current:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 5.h),
                Text(calculatedController!.text.isEmpty ? '0 A' : "${calculatedController?.text} A",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34.sp,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  /// Builds a column layout with common UI elements and the content returned by [buildContent].
  ///
  /// This method is used to create a base container for test stations.
  /// It returns a [Column] widget with a [Container] as its child, which contains the content returned by [buildContent].
  /// Other common UI elements can be added to the [Column] as children.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: buildContent(context),
          //... other common UI elements
        ),
        //... other common UI elements
      ],
    );
  }
}

//TODO: Convert containers to use Polymorphism from this base abstract class

//TODO: Add Location Description to the TestStation

//? Add a field or dropdown to enter the wire color.
//PLTestLeadContainer (Done)
//TestLeadContainer (Done)
//ForeignContainer (Done) //? Add a field to enter who owns the foreign structure
//RiserContainer //? Add a field to enter the riser diameter
//PermRefContainer //? Add dropdown to select the type of perm ref cell

//TODO: Need to build the different widgets to be used for these containers
//AnodeContainer
//CouponContainer
//ShuntContainer (Done)
//BondContainer
//IsoContainer


/*
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:asset_inspections/Common_Widgets/bottomsheet_livegraph.dart';
import 'package:asset_inspections/Common_Widgets/custom_textfield.dart';
import 'package:asset_inspections/Common_Widgets/dcvolts_button_cycled.dart';
import 'package:asset_inspections/Common_Widgets/dcvolts_mm_button.dart';
import 'package:asset_inspections/Models/ts_models.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/bluetooth_manager_notifier.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart';
//import 'package:asset_inspections/Test_Station/ts_notifier.dart';
import 'package:asset_inspections/database_helper.dart';

/// This is an abstract base container class that extends [StatefulWidget].
/// It provides common properties and methods for containers used in test stations.
///
/// The [BaseContainer] class takes a generic type parameter [T] and requires a list of [readings],
/// an optional [onReadingUpdated] callback function, a [currentTestStation] object,
/// and a [scaffoldMessengerKey] of type [GlobalKey<ScaffoldMessengerState>].
///
/// Subclasses of [BaseContainer] should override the [createState] method to return
/// an instance of [BaseContainerState].

abstract class BaseContainer<T> extends StatefulWidget {
  final List<T> readings;
  final ValueChanged<T>? onReadingUpdated;
  final TestStation currentTestStation;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const BaseContainer({
    Key? key,
    required this.readings,
    this.onReadingUpdated,
    required this.currentTestStation,
    required this.scaffoldMessengerKey,
  }) : super(key: key);

  @override
  BaseContainerState createState();
}

/// Generic class to be used for all containers. This class defines the common functionality for all containers
/// All containers will extend this class and all widgets will be defined below
/// This is the abstract base class for container states.
/// It extends the State class and provides common variables and methods for all Test Station containers.
/// Containers are used in Test Station details pages.
abstract class BaseContainerState<T extends BaseContainer> extends State<T> {
  // Common variables for all containers
  int? id;
  int? orderIndex;
  TestStation? currentTestStation;
  TestStation testStation = TestStation(
    id: 0,
    projectID: 0,
    area: '',
    tsID: '',
    tsstatus: '',
  );

  // Common variables for containers with ON and OFF readings
  bool isTimerActiveON = false;
  bool isTimerActiveOFF = false;
  bool userEditedOn = false;
  bool userEditedOff = false;
  DateTime? initialVoltsONDate;
  DateTime? initialVoltsOFFDate;
  bool showGraph = false;

  /*
  // Common variables for containers with Wire Color & Lug Number dropdowns
  String? selectedWireColor;
  String? lastSavedWireColor;
  int? selectedLugNumber;
  int? lastSavedLugNumber;
  List<String> wireColors = [
    "Black",
    "Green",
    "White",
    "Yellow",
    "Red",
    "Light Blue",
    "Dark Blue",
    "White w/ Red",
    "White w/ Black",
    "Black w/ Red",
    "Green w/ Yellow"
  ];
  Map<String, List<Color>> colorMap = {
    "Black": [Colors.black],
    "Green": [Colors.green],
    "White": [Colors.white],
    "Yellow": [Colors.yellow],
    "Red": [Colors.red],
    "Light Blue": [Colors.lightBlue],
    "Dark Blue": [Colors.blue[800]!],
    "White w/ Red": [Colors.white, Colors.red],
    "White w/ Black": [Colors.white, Colors.black],
    "Black w/ Red": [Colors.black, Colors.red],
    "Green w/ Yellow": [Colors.green, Colors.yellow],
  };

// Method to create a color display widget
  Widget colorDisplay(String colorKey) {
    List<Color> colors = colorMap[colorKey]!;
    return Row(
      children: colors
          .map((color) => Expanded(
                child: Container(
                  color: color,
                  height: 12,
                ),
              ))
          .toList(),
    );
  }
  */

  // Common variables for containers with Shunt calculations
  List<String> fullNamesList = [];
  String? selectedSideA;
  String? selectedSideB;
  bool userEditedVoltageDrop = false;
  bool userEditedCalculated = false;
  DateTime? initialVoltageDropDate;
  DateTime? initialCalculatedDate;

  TextEditingController nameController = TextEditingController();
  TextEditingController? onController;
  TextEditingController? offController;

  TextEditingController? ratioMVController;
  TextEditingController? ratioAmpsController;
  TextEditingController? factorController;
  TextEditingController? vDropController;
  TextEditingController? calculatedController;

  FocusNode nameFocusNode = FocusNode();
  FocusNode? onFocusNode;
  FocusNode? offFocusNode;
//  FocusNode wireColorNode = FocusNode();
//  FocusNode lugNumberNode = FocusNode();

  FocusNode? ratioMVFocusNode;
  FocusNode? ratioAmpsFocusNode;
  FocusNode? factorFocusNode;
  FocusNode? vDropFocusNode;
  FocusNode? calculatedFocusNode;

  // Getter for the container name
  String get containerName;

  @override
  void initState() {
    super.initState();

    initializeControllers();
    initializeFocusNodes();
    // initializeWireColorAndLugNumber();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeAsyncData();
    });
  }

  /*
  void initializeWireColorAndLugNumber() {
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      wireColorNode.addListener(_handleWireColorFocusChange);
      lugNumberNode.addListener(_handleLugNumberFocusChange);

      // Initialize selectedWireColor
      if (widget.readings.isNotEmpty && widget.readings[0].wireColor != null) {
        selectedWireColor = widget.readings[0].wireColor;
      }
      // Initialize selectedLugNumber
      if (widget.readings.isNotEmpty && widget.readings[0].lugNumber != null) {
        selectedLugNumber = widget.readings[0].lugNumber;
      }
    }
  }
  */
  /// Initializes the asynchronous data for the abstract base container.
  /// - Assigns the value of `widget.currentTestStation` to the `currentTestStation` variable.
  /// - Sets the value of the [nameController] based on the first reading's name in the [widget.readings] list, or an empty string if the list is empty.
  /// - Sets the [orderIndex] based on the first reading's orderIndex in the widget's readings list, if it is not empty.
  /// - Checks if the container is 'ShuntContainers' and loads data if it is.
  void initializeAsyncData() async {
    // Assigns the value of `widget.currentTestStation` to the `currentTestStation` variable.
    currentTestStation = widget.currentTestStation;

    // Sets the value of the [nameController] based on the first reading's name in the [widget.readings] list, or an empty string if the list is empty.
    nameController.text = widget.readings.isNotEmpty ? widget.readings[0].name : '';

    // Set the orderIndex based on the first reading's orderIndex in the widget's readings list, if it is not empty
    if (widget.readings.isNotEmpty) {
      setState(() {
        orderIndex = widget.readings[0].orderIndex;
      });
    }

    // Check if the container is 'ShuntContainers' and load data if it is
    if (containerName == 'ShuntContainers') {
      await loadData();
    }
  }

  /// Initializes the text editing controllers based on the container name.
  ///
  /// If the container name is 'PLTestLeadContainers', 'TestLeadContainers', 'ForeignContainers',
  /// 'RiserContainers', 'PermRefContainers', 'AnodeContainers', or 'CouponContainers',
  /// the [onController] and [offController] are initialized with the corresponding values from the [widget.readings].
  /// The [initialVoltsONDate] and [initialVoltsOFFDate] are set to the corresponding values from the [widget.readings].
  ///
  /// If the container name is 'ShuntContainers', the [ratioMVController], [ratioAmpsController], [factorController],
  /// [vDropController], [calculatedController] are initialized with the corresponding values from the [widget.readings].
  /// The [initialVoltageDropDate] and [initialCalculatedDate] are set to the corresponding values from the [widget.readings].
  ///
  /// Finally, the [setUpControllers] method is called to perform additional setup.
  void initializeControllers() {
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      onController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].voltsON != null ? widget.readings[0].formattedVoltsON : '');
      offController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].voltsOFF != null ? widget.readings[0].formattedVoltsOFF : '');
      initialVoltsONDate = widget.readings.isNotEmpty && widget.readings[0].voltsONDate != null ? widget.readings[0].voltsONDate : null;
      initialVoltsOFFDate = widget.readings.isNotEmpty && widget.readings[0].voltsOFFDate != null ? widget.readings[0].voltsOFFDate : null;
    } else if (containerName == 'ShuntContainers') {
      ratioMVController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].ratioMV != null ? widget.readings[0].formattedratioMV : '');
      ratioAmpsController = TextEditingController(
          text: widget.readings.isNotEmpty && widget.readings[0].ratioAMPS != null ? widget.readings[0].formattedratioAMPS : '');
      factorController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].factor != null ? widget.readings[0].formattedfactor : '');
      vDropController =
          TextEditingController(text: widget.readings.isNotEmpty && widget.readings[0].vDrop != null ? widget.readings[0].formattedvDrop : '');
      calculatedController = TextEditingController(
          text: widget.readings.isNotEmpty && widget.readings[0].calculated != null ? widget.readings[0].formattedcalculated : '');
      initialVoltageDropDate = widget.readings.isNotEmpty && widget.readings[0].vDropDate != null ? widget.readings[0].vDropDate : null;
    }
    setUpControllers();
  }

  /// Sets up the controllers and listeners for the abstract base container.
  ///
  /// This method sets up controller listeners for ON and OFF readings, as well as
  /// controller listeners for Shunt calculations. For certain container names,
  /// the [onController] and [offController] listeners are added to track user edits.
  /// For the 'ShuntContainers' container name, additional listeners for [ratioMVController],
  /// [ratioAmpsController], [factorController], [vDropController], and [calculatedController]
  /// are added to update calculated values and track user edits.
  void setUpControllers() {
    // Setup controller listeners for ON and OFF readings
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      onController?.addListener(() {
        userEditedOn = true;
      });
      offController?.addListener(() {
        userEditedOff = true;
      });
    }

    // Setup controller listeners for Shunt calculations
    if (containerName == 'ShuntContainers') {
      ratioMVController?.addListener(() {
        updateFactor();
      });
      ratioAmpsController?.addListener(() {
        updateFactor();
      });
      factorController?.addListener(() {
        updateCalculated();
      });
      vDropController?.addListener(() {
        userEditedVoltageDrop = true;
        updateCalculated();
      });
      calculatedController?.addListener(() {
        userEditedCalculated = true;
        updateCalculated();
      });
    }
  }

  /// Initializes the focus nodes based on the container type.
  /// If the container name is [PLTestLeadContainers], [TestLeadContainers],
  /// [ForeignContainers], [RiserContainers], [PermRefContainers],
  /// [AnodeContainers], or [CouponContainers], it creates [onFocusNode] and offFocusNode.
  /// If the container name is [ShuntContainers], it creates ratioMVFocusNode,
  /// ratioAmpsFocusNode, factorFocusNode, vDropFocusNode, and calculatedFocusNode.
  /// Finally, it calls setUpFocusNodes().
  void initializeFocusNodes() {
    // Initialize focus nodes based on the container type
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      onFocusNode = FocusNode();
      offFocusNode = FocusNode();
//      wireColorNode = FocusNode();
//      lugNumberNode = FocusNode();
    } else if (containerName == 'ShuntContainers') {
      ratioMVFocusNode = FocusNode();
      ratioAmpsFocusNode = FocusNode();
      factorFocusNode = FocusNode();
      vDropFocusNode = FocusNode();
      calculatedFocusNode = FocusNode();
    }
    setUpFocusNodes();
  }

  /// Sets up the focus nodes for the abstract base container.
  void setUpFocusNodes() {
    nameFocusNode.addListener(() {
      if (!nameFocusNode.hasFocus) {
        saveOrUpdateReading(containerName);
      }
    });

    // Only add listeners to onFocusNode and offFocusNode if they are not null
    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
      onFocusNode?.addListener(() {
        if (!onFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName);
        }
      });
      offFocusNode?.addListener(() {
        if (!offFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName);
        }
      });
  /*
      wireColorNode.addListener(() {
        if (!wireColorNode.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
      lugNumberNode.addListener(() {
        if (!lugNumberNode.hasFocus) {
          saveOrUpdateReading(containerName, []);
        }
      });
  */
    }

    // Only add listeners to ShuntContainers' focus nodes if they are not null
    else if (containerName == 'ShuntContainers') {
      ratioMVFocusNode?.addListener(() {
        if (!ratioMVFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName);
        }
      });
      ratioAmpsFocusNode?.addListener(() {
        if (!ratioAmpsFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName);
        }
      });
      factorFocusNode?.addListener(() {
        if (!factorFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName);
        }
      });
      vDropFocusNode?.addListener(() {
        if (!vDropFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName);
        }
      });
      calculatedFocusNode?.addListener(() {
        if (!calculatedFocusNode!.hasFocus) {
          saveOrUpdateReading(containerName);
        }
      });
    }
  }

  /*
  void _handleWireColorFocusChange() {
    if (!wireColorNode.hasFocus) {
      // Trigger function when the dropdown loses focus
      saveOrUpdateReading(containerName, []);
    }
  }

  void _handleLugNumberFocusChange() {
    if (!lugNumberNode.hasFocus) {
      // Trigger function when the dropdown loses focus
      saveOrUpdateReading(containerName, []);
    }
  }
  */
  @override
  void dispose() {
    // Dispose of all the controllers and focus nodes
    nameController.dispose();
    onController?.dispose();
    offController?.dispose();
    ratioMVController?.dispose();
    ratioAmpsController?.dispose();
    factorController?.dispose();
    vDropController?.dispose();
    calculatedController?.dispose();
    nameFocusNode.dispose();
    onFocusNode?.dispose();
    offFocusNode?.dispose();
    ratioMVFocusNode?.dispose();
    ratioAmpsFocusNode?.dispose();
    factorFocusNode?.dispose();
    vDropFocusNode?.dispose();
    calculatedFocusNode?.dispose();
//    wireColorNode.dispose();
//    lugNumberNode.dispose();
    super.dispose();
  }

  /// Formats the [dateTime] object into a readable string.
  String? formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      // Format the DateTime object into a readable string
      return DateFormat('yyyy-MM-dd – kk:mm:ss').format(dateTime);
    } else {
      // Return null if the date is null
      return null;
    }
  }

  /// Saves or updates the reading based on the container name.
  ///
  /// The [containerName] parameter specifies the type of container.
  /// The reading is saved or updated based on the container type.
  /// The [containerName] can be one of the following:
  /// - 'PLTestLeadContainers'
  /// - 'TestLeadContainers'
  /// - 'ForeignContainers'
  /// - 'RiserContainers'
  /// - 'PermRefContainers'
  /// - 'AnodeContainers'
  /// - 'CouponContainers'
  /// - 'ShuntContainers'
  ///
  /// The reading information is retrieved from the UI elements and stored in a [readingMap].
  /// The [readingMap] contains the following key-value pairs:
  /// - 'stationID': The ID of the current test station.
  /// - 'testStationID': The ID of the test station.
  /// - 'name': The name of the container.
  /// - 'order_index': The order index of the container.
  ///
  /// For specific container types, additional information is added to the [readingMap].
  /// - For 'PLTestLeadContainers', 'TestLeadContainers', 'ForeignContainers',
  ///   'RiserContainers', 'PermRefContainers', 'AnodeContainers', and 'CouponContainers':
  ///   - 'voltsON': The ON voltage value.
  ///   - 'voltsON_Date': The date and time when the ON voltage value was recorded.
  ///   - 'voltsOFF': The OFF voltage value.
  ///   - 'voltsOFF_Date': The date and time when the OFF voltage value was recorded.
  ///
  /// - For 'ShuntContainers':
  ///   - 'side_a': The value of side A.
  ///   - 'side_b': The value of side B.
  ///   - 'ratio_mv': The ratio in millivolts.
  ///   - 'ratio_current': The ratio in amps.
  ///   - 'factor': The factor value.
  ///   - 'voltage_drop': The voltage drop value.
  ///   - 'voltage_drop_Date': The date and time when the voltage drop value was recorded.
  ///   - 'calculated': The calculated value.
  ///   - 'calculated_Date': The date and time when the calculated value was recorded.
  ///
  /// The reading information is then passed to the [performDbOperation] method
  /// to perform the database operation.
  void saveOrUpdateReading(
    String containerName,
    /*List<String> waveForm*/
  ) {
    int id = widget.currentTestStation.id ?? 0;
    String tsID = widget.currentTestStation.tsID;
    int currentOrderIndex = orderIndex!;

    String? sideAValue = selectedSideA ?? '';
    String? sideBValue = selectedSideB ?? '';

    String currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    var readingMap = {
      'stationID': widget.currentTestStation.id,
      'testStationID': tsID,
      'name': nameController.text,
      'order_index': currentOrderIndex,
  //      'waveForm': waveForm.join(';'),
    };

    if (containerName == 'PLTestLeadContainers' ||
        containerName == 'TestLeadContainers' ||
        containerName == 'ForeignContainers' ||
        containerName == 'RiserContainers' ||
        containerName == 'PermRefContainers' ||
        containerName == 'AnodeContainers' ||
        containerName == 'CouponContainers') {
  //      readingMap['waveForm'] = waveForm.join(';');
      if (userEditedOn) {
        readingMap['voltsON'] = double.tryParse(onController?.text ?? '');
        readingMap['voltsON_Date'] = currentTime;
      }

      if (userEditedOff) {
        readingMap['voltsOFF'] = double.tryParse(offController?.text ?? '');
        readingMap['voltsOFF_Date'] = currentTime;
      }

  /*
      if (selectedWireColor != lastSavedWireColor) {
        lastSavedWireColor = selectedWireColor;
        readingMap['wireColor'] = selectedWireColor;
      }

      if (selectedLugNumber != lastSavedLugNumber) {
        lastSavedLugNumber = selectedLugNumber;
        readingMap['lugNumber'] = selectedLugNumber;
      }
  */
      userEditedOn = false;
      userEditedOff = false;
    } else if (containerName == 'ShuntContainers') {
      readingMap['side_a'] = sideAValue;
      readingMap['side_b'] = sideBValue;
      readingMap['ratio_mv'] = double.tryParse(ratioMVController?.text ?? '');
      readingMap['ratio_current'] = double.tryParse(ratioAmpsController?.text ?? '');
      readingMap['factor'] = double.tryParse(factorController?.text ?? '');

      if (userEditedVoltageDrop) {
        readingMap['voltage_drop'] = double.tryParse(vDropController?.text ?? '');
        readingMap['voltage_drop_Date'] = currentTime;
      }

      if (userEditedCalculated) {
        readingMap['calculated'] = double.tryParse(calculatedController?.text ?? '');
      }
      userEditedVoltageDrop = false;
    }

    performDbOperation(id, tsID, readingMap, containerName);
  }

  /// Performs a database operation to insert or update a reading.
  ///
  /// The [stationID] parameter specifies the ID of the station.
  /// The [tsID] parameter specifies the ID of the test station.
  /// The [readingMap] parameter is a map containing the reading data.
  /// The [containerName] parameter specifies the name of the container.
  ///
  /// This method inserts or updates the reading in the database using the [DatabaseHelper].
  /// If the operation is successful and an ID is returned, a snackbar with the message "Reading Saved!" is shown.
  /// If the operation fails, a snackbar with the message "Failed to Save Reading!" is shown.
  /// If an error occurs during the operation, a snackbar with the error message is shown.
  void performDbOperation(int stationID, String tsID, Map<String, dynamic> readingMap, String containerName) async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;

    await dbHelper.insertOrUpdateReading(stationID, readingMap, containerName).then((insertedId) {
      if (insertedId > 0) {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Reading Saved!')),
        );
      } else {
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Failed to Save Reading!')),
        );
      }
    }).catchError((e) {
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    });
  }

  /// Handles the status change of the timer for turning ON.
  ///
  /// This method updates the [isTimerActiveON] state variable with the provided [status].
  void handleTimerStatusChangedON(bool status) {
    Future.delayed(Duration.zero, () {
      setState(() {
        isTimerActiveON = status;
      });
    });
  }

  /// Handles the status change of the timer for turning OFF.
  ///
  /// This method updates the [isTimerActiveOFF] state variable with the provided [status].
  void handleTimerStatusChangedOFF(bool status) {
    Future.delayed(Duration.zero, () {
      setState(() {
        isTimerActiveOFF = status;
      });
    });
  }

  /// Toggles the visibility of the graph.
  ///
  /// This method toggles the value of the [showGraph] state variable.
  void toggleGraph() {
    setState(() {
      showGraph = !showGraph;
    });
  }

  /// Loads data from the database.
  ///
  /// This method retrieves the names of shunts associated with the current test station
  /// and updates the [fullNamesList] state variable.
  Future<void> loadData() async {
    String testStationID = widget.currentTestStation.tsID;
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<String> names = await dbHelper.fetchNamesForShunt(testStationID);

    if (mounted) {
      setState(() {
        fullNamesList = names;
      });
    }
  }

  /// Updates the factor based on the ratio values.
  ///
  /// This method calculates the factor using the ratio values entered in the [ratioMVController]
  /// and [ratioAmpsController] text fields. It updates the [factorController] text field
  /// with the formatted factor value.
  void updateFactor() {
    double? ratioMV = double.tryParse(ratioMVController!.text);
    double? ratioAmps = double.tryParse(ratioAmpsController!.text);

    if (ratioMV != null && ratioAmps != null) {
      double factor = ratioAmps / ratioMV;
      factorController?.text = formatNumbers(factor);
    }
  }

  /// Updates the calculated value based on the entered vDrop and factor.
  /// If both vDrop and factor are valid numbers, the calculated value is updated
  /// by multiplying vDrop with factor. The result is then formatted and set as
  /// the text of the calculatedController. Finally, the data is reloaded.
  Future<void> updateCalculated() async {
    double? vDrop = double.tryParse(vDropController!.text);
    double? factor = double.tryParse(factorController!.text);

    if (vDrop != null && factor != null) {
      double calculated = vDrop * factor;
      calculatedController?.text = formatNumbers(calculated);
    }
    // _saveOrUpdateReading();
    await loadData();
  }

  /// Formats a given [value] into a string representation.
  /// If the value is an integer, it returns the integer as a string.
  /// If the value is a decimal, it returns the decimal with 2 decimal places as a string.
  String formatNumbers(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Builds the content of the abstract base container widget.
  ///
  /// This method is responsible for constructing the visual representation of the abstract base container.
  /// It takes several optional parameters that allow customization of the container's appearance and content.
  ///
  /// - The [context] parameter is the build context.
  /// - The [onReadingRow] parameter is a widget that represents the on-reading row.
  /// - The [offReadingRow] parameter is a widget that represents the off-reading row.
  /// - The [bottomGraph] parameter is a widget that represents the bottom graph.
  /// - The [sideAtoSideB] parameter is a widget that represents the side A to side B dropdowns.
  /// - The [shuntCalculationRows] parameter is a widget that represents the shunt calculation rows.
  ///
  /// Returns a [Widget] that represents the abstract base container.
  //TODO: Add Location Description field
  @protected
  Widget buildContent(BuildContext context,
      {Widget? onReadingRow,
      Widget? offReadingRow,
      Widget? wireColorAndLugNumberRow,
      Widget? bottomGraph,
      Widget? sideAtoSideB,
      Widget? shuntCalculationRows}) {
    SizedBox(height: 5.h);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 43, 92),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 1.1,
                    child: Text(
                      nameController.text.isEmpty ? 'Default Text' : nameController.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                      ), // Your text style here
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    //  heightFactor: 1.5,
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      color: Colors.white,
                      iconSize: 18.sp,
                      onPressed: () {
                        nameFocusNode.requestFocus();
                        //TODO: Add functionality to edit/delete/modifiy the container
                        //? Add functionality to add different kinds of readings, such as Native, Connected, Disconnected??
                      },
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Color.fromARGB(255, 247, 143, 30),
                thickness: 1,
              ),
              SizedBox(height: 5.h),
              if (onReadingRow != null) onReadingRow, // Include the onReadingRow if provided
              //SizedBox(height: 10.h),
              if (offReadingRow != null) offReadingRow,

              if (wireColorAndLugNumberRow != null) wireColorAndLugNumberRow, // Include the offReadingRow if provided
              //SizedBox(height: 10.h),
              if (bottomGraph != null) bottomGraph, // Include the bottomGraph if provided
              //SizedBox(height: 10.h),
              if (sideAtoSideB != null) sideAtoSideB, // Include the sideAtoSideBDropdowns if provided
              //SizedBox(height: 10.h),
              if (shuntCalculationRows != null) shuntCalculationRows, // Include the shuntCalculationRows if provided
            ],
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  /// Builds the row for the ON reading in the UI of the abstract base container.
  ///
  /// This method returns a [Column] widget that contains a [Row] widget with the OFF label,
  /// a [DCvoltsButtonCycled] widget (if the Pokit Pro model is available), and a [CustomTextField]
  /// widget for entering the ON reading. It also displays the last updated date of the ON reading.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildONReadingRow(BuildContext context) {
    String? formattedVoltsONDate = formatDateTime(initialVoltsONDate);
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          children: [
            Text('ON: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            if (BluetoothManager.instance.pokitProModel != null)
              DCvoltsButtonCycled(
                onController: onController,
                offController: offController,
                multimeterService: Provider.of<MultimeterService>(context, listen: false),
                onTimerStatusChanged: handleTimerStatusChangedON,
                offTimerStatusChanged: handleTimerStatusChangedOFF,
                onSaveOrUpdate: saveOrUpdateReading,
                onButtonPressed: toggleGraph,
                containerName: containerName,
              ),
            const Spacer(),
            SizedBox(
                child: CustomTextField(
              controller: onController,
              focusNode: onFocusNode,
              style: TextStyle(
                //TODO: Color needs to be moved to only be used when DCVoltsButtonCycled is used
                color: isTimerActiveON ? Colors.red : Colors.green,
                fontSize: 22.sp,
                fontStyle: isTimerActiveON ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.bold,
              ),
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: '-V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextSpan(text: ' CSE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              width: 160.w,
              height: 40.h,
            )),
          ],
        ),
        if (formattedVoltsONDate != null) //SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 160.w,
                height: 15.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(),
                    const Icon(
                      Icons.update_sharp,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      formattedVoltsONDate,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: 5.h),
      ],
    );
  }

  /// Builds a row for displaying the OFF reading in the UI of the abstract base container.
  ///
  /// This method returns a [Column] widget that contains a [Row] widget with the OFF label,
  /// a [DCvoltsMMButton] widget (if the Pokit Pro model is available), and a [CustomTextField]
  /// widget for entering the OFF reading. It also displays the last updated date of the OFF reading.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildOFFReadingRow(BuildContext context) {
    String? formattedVoltsOFFDate = formatDateTime(initialVoltsOFFDate);
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          children: [
            Text('OFF: ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            if (BluetoothManager.instance.pokitProModel != null)
              DCvoltsMMButton(
                selectedMode: Mode.dcVoltage, // Adapt based on your needs
                controller: offController,
                multimeterService: MultimeterService.instance,
                onTimerStatusChanged: handleTimerStatusChangedOFF,
                onSaveOrUpdate: (String value) {
                  saveOrUpdateReading(value);
                },
                containerName: containerName,
              ),
            const Spacer(),
            SizedBox(
                child: CustomTextField(
              controller: offController,
              focusNode: offFocusNode,
              style: TextStyle(
                color: isTimerActiveOFF ? Colors.red : Colors.green,
                fontSize: 22.sp,
                fontStyle: isTimerActiveOFF ? FontStyle.italic : FontStyle.normal,
                fontWeight: FontWeight.bold,
              ),
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: '-V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    TextSpan(text: ' CSE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left,
              width: 160.w,
              height: 40.h,
            )),
          ],
        ),
        if (formattedVoltsOFFDate != null) // SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 160.w,
                height: 15.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.update_sharp,
                      color: Colors.white,
                      size: 11.sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      formattedVoltsOFFDate,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        SizedBox(height: 12.h),
      ],
    );
  }

  /*
  Widget buildWireColorAndLugNumberRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          // Ensures the dropdown takes up available space and has bounded constraints
          child: Container(
            height: 40.h,
            //  width: 140.w,
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white, // White background color
              borderRadius: BorderRadius.circular(4.0), // Rounded corners
              border: Border.all(color: Colors.grey[300]!), // Grey border
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[200],
                value: selectedWireColor,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedWireColor = newValue;
                  });
                },
                focusNode: wireColorNode,
                style: TextStyle(color: Colors.black, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Wire Color',
                  hintStyle: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    // Minimal border adjustments
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 5.h), // Reduced padding
                  alignLabelWithHint: true,
                ),
                items: colorMap.keys.map<DropdownMenuItem<String>>((String colorKey) {
                  return DropdownMenuItem<String>(
                    value: colorKey,
                    child: Row(
                      children: [
                        Container(
                          width: 15,
                          height: 15,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.black, width: 1), // Black border
                          ),
                          child: colorDisplay(colorKey),
                        ),
                        Text(colorKey),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          flex: 2,
          child: Container(
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<int>(
                dropdownColor: Colors.grey[200],
                menuMaxHeight: 300.h,
                value: selectedLugNumber,
                onChanged: (value) {
                  setState(() {
                    selectedLugNumber = value;
                  });
                },
                focusNode: lugNumberNode,
                style: TextStyle(color: Colors.black, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Lug Number',
                  hintStyle: TextStyle(color: Colors.black, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 2.h), // Adjusted padding
                  alignLabelWithHint: true,
                ),
                items: List<int>.generate(15, (int index) => index + 1).map<DropdownMenuItem<int>>((int number) {
                  return DropdownMenuItem<int>(
                    value: number,
                    child: Text(number.toString()),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  */
  /// Builds the bottom graph widget.
  ///
  /// This method returns a widget that displays a bottom graph. If [showGraph] is false,
  /// it returns an empty SizedBox. Otherwise, it returns a Container widget with a
  /// specified height, width, and decoration. The child of the Container is a
  /// BottomSheetLiveGraph widget.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildBottomGraph(BuildContext context) {
    if (!showGraph) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(2.sp),
      height: 350.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const BottomSheetLiveGraph(),
    );
  }

  /// Builds the dropdowns for Side A and Side B selection.
  ///
  /// This method returns a [Column] widget containing the dropdowns for selecting Side A and Side B.
  /// The dropdowns are styled with a filled background, border, and dropdown items.
  /// The selected values for Side A and Side B are stored in [selectedSideA] and [selectedSideB] variables respectively.
  /// The dropdown items are generated from the [fullNamesList] excluding the currently selected value for the other side.
  /// When a dropdown value is changed, the corresponding selected value is updated and the [saveOrUpdateReading] method is called.
  /// The method also displays a text indicating the direction of current travels from Side A to Side B.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildSideAtoSideBDropdowns(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Side A:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(
                  width: 140.w,
                  height: 40.h,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(color: Colors.grey, width: 1.5.w),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: selectedSideA,
                      items: fullNamesList.where((item) => item != selectedSideB).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              )),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSideA = newValue;
                        });
                        saveOrUpdateReading(containerName
                            //newValue ?? '', _selectedSideB ?? ''
                            );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 15.h,
                ),
                Icon(Icons.arrow_forward, color: Colors.white, size: 30.sp),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Side B:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(
                  width: 140.w,
                  height: 40.h,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.fromLTRB(15, 0, 10, 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(color: Colors.grey, width: 1.5.w),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: selectedSideB,
                      items: fullNamesList.where((item) => item != selectedSideA).map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              )),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSideB = newValue;
                        });
                        saveOrUpdateReading(containerName
                            //_selectedSideA ?? '', newValue ?? ''
                            );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              '-Current travels from Side A to Side B-',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
      ],
    );
  }

  /// Builds the rows for shunt calculation in the abstract base container.
  ///
  /// This method returns a [Column] widget that contains the UI elements for shunt calculation.
  /// It includes text fields for entering ratio (in amps and millivolts), factor (in amps per millivolt),
  /// voltage drop (in millivolts), and current (in amps). The UI elements are styled with specific fonts,
  /// colors, and sizes.
  ///
  /// The [context] parameter is the build context.
  @protected
  Widget buildShuntCalculationRows(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Ratio:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            CustomTextField(
              controller: ratioAmpsController,
              focusNode: ratioAmpsFocusNode,
              keyboardType: TextInputType.number,
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: 'A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    //  TextSpan(text: ' CSE', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              width: 120.w,
              height: 40.h,
            ),
            const Spacer(),
            Text(' / ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: ratioMVController,
                  focusNode: ratioMVFocusNode,
                  keyboardType: TextInputType.number,
                  hintText: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: const [
                        TextSpan(text: 'mV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        //  TextSpan(text: ' CSE', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  width: 120.w,
                  height: 40.h,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Factor:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                )),
            const Spacer(),
            CustomTextField(
              controller: factorController,
              focusNode: factorFocusNode,
              keyboardType: TextInputType.number,
              hintText: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: const [
                    TextSpan(text: 'A/mV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    //  TextSpan(text: ' CSE', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              width: 240.w,
              height: 40.h,
            ),
            const Spacer(),
          ],
        ),
        SizedBox(height: 15.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voltage Drop:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                CustomTextField(
                  controller: vDropController,
                  focusNode: vDropFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  hintText: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: const [
                        TextSpan(text: 'mV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        // TextSpan(text: ' CSE', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  width: 140.w,
                  height: 40.h,
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Current:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 5.h),
                Text(calculatedController!.text.isEmpty ? '0 A' : "${calculatedController?.text} A",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34.sp,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  /// Builds a column layout with common UI elements and the content returned by [buildContent].
  ///
  /// This method is used to create a base container for test stations.
  /// It returns a [Column] widget with a [Container] as its child, which contains the content returned by [buildContent].
  /// Other common UI elements can be added to the [Column] as children.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: buildContent(context),
          //... other common UI elements
        ),
        //... other common UI elements
      ],
    );
  }
}
*/
