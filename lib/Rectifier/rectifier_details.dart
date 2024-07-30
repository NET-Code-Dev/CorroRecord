// ignore_for_file: override_on_non_overriding_member, library_private_types_in_public_api, prefer_const_constructors_in_immutables, use_key_in_widget_constructors, prefer_const_constructors, non_constant_identifier_names, sort_child_properties_last, avoid_types_as_parameter_names, avoid_print, prefer_const_literals_to_create_immutables

import 'package:asset_inspections/mainpage_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:asset_inspections/Common_Widgets/custom_radio.dart';
import 'package:asset_inspections/Common_Widgets/custom_textfield.dart';
import 'package:asset_inspections/Common_Widgets/gps_location.dart';
import 'package:asset_inspections/main.dart';

import '../Models/rectifier_models.dart'; // Import the Rectifier classes
import 'rec_changeNotifier.dart'; // Import the RectifierNotifier

class RectifierDetailsPage extends StatefulWidget {
  final Rectifier rectifier;
  final Function(String, RectifierReadings, TapReadings, RectifierInspection) onStatusChanged;

  RectifierDetailsPage({required this.rectifier, required this.onStatusChanged});

  @override
  _RectifierDetailsPageState createState() => _RectifierDetailsPageState();
}

class _RectifierDetailsPageState extends State<RectifierDetailsPage> {
  final FocusNode _panelMeterVoltageFocusNode = FocusNode();
  final FocusNode _multimeterVoltageFocusNode = FocusNode();
  final FocusNode _voltageReadingCommentsFocusNode = FocusNode();
  final FocusNode _panelMeterCurrentFocusNode = FocusNode();
  final FocusNode _ammeterCurrentFocusNode = FocusNode();
  final FocusNode _currentReadingCommentsFocusNode = FocusNode();
  final FocusNode _currentRatioFocusNode = FocusNode();
  final FocusNode _voltageRatioFocusNode = FocusNode();
  final FocusNode _voltageDropFocusNode = FocusNode();
  final FocusNode _courseTapFocusNode = FocusNode();
  final FocusNode _mediumTapFocusNode = FocusNode();
  final FocusNode _fineTapFocusNode = FocusNode();
  final FocusNode _oilLevelFindingsFocusNode = FocusNode();
  final FocusNode _oilLevelCommentsFocusNode = FocusNode();
  final FocusNode _deviceDamageFindingsFocusNode = FocusNode();
  final FocusNode _deviceDamageCommentsFocusNode = FocusNode();
  final FocusNode _circuitBreakersCommentsFocusNode = FocusNode();
  final FocusNode _fusesWiringCommentsFocusNode = FocusNode();
  final FocusNode _lightningArrestorsCommentsFocusNode = FocusNode();
  final FocusNode _ventScreensCommentsFocusNode = FocusNode();
  final FocusNode _breathersCommentsFocusNode = FocusNode();
  final FocusNode _removeObstructionsCommentsFocusNode = FocusNode();
  final FocusNode _cleanedCommentsFocusNode = FocusNode();
  final FocusNode _tightenedCommentsFocusNode = FocusNode();
  final FocusNode _polarityConditionCommentsFocusNode = FocusNode();
  final FocusNode locationFocusNode = FocusNode();

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _panelMeterVoltageController = TextEditingController();
  final TextEditingController _multimeterVoltageController = TextEditingController();
  final TextEditingController _voltageReadingCommentsController = TextEditingController();
  final TextEditingController _panelMeterCurrentController = TextEditingController();
  final TextEditingController _ammeterCurrentController = TextEditingController();
  final TextEditingController _currentReadingCommentsController = TextEditingController();
  final TextEditingController _currentRatioController = TextEditingController();
  final TextEditingController _voltageRatioController = TextEditingController();
  final TextEditingController _voltageDropController = TextEditingController();
  final TextEditingController _courseTapController = TextEditingController();
  final TextEditingController _mediumTapController = TextEditingController();
  final TextEditingController _fineTapController = TextEditingController();
  final TextEditingController _oilLevelFindingsController = TextEditingController();
  final TextEditingController _oilLevelCommentsController = TextEditingController();
  final TextEditingController _deviceDamageFindingsController = TextEditingController();
  final TextEditingController _deviceDamageCommentsController = TextEditingController();
  final TextEditingController _circuitBreakersCommentsController = TextEditingController();
  final TextEditingController _fusesWiringCommentsController = TextEditingController();
  final TextEditingController _lightningArrestorsCommentsController = TextEditingController();
  final TextEditingController _ventScreensCommentsController = TextEditingController();
  final TextEditingController _breathersCommentsController = TextEditingController();
  final TextEditingController _removeObstructionsCommentsController = TextEditingController();
  final TextEditingController _cleanedCommentsController = TextEditingController();
  final TextEditingController _tightenedCommentsController = TextEditingController();
  final TextEditingController _polarityConditionCommentsController = TextEditingController();
  int? _oilLevel;
  int? _deviceDamage;
  int? _circuitBreakers;
  int? _fusesWiring;
  int? _lightningArrestors;
  int? _ventScreens;
  int? _breathers;
  int? _removeObstructions;
  int? _cleaned;
  int? _tightened;
  int? _polarityCondition;
  double? latitude;
  double? longitude;

  final List<String> statuses = ['Pass', 'Attention', 'Issue', 'Unchecked'];
  int currentStatusIndex = 0;

  void _addFocusListener(FocusNode focusNode) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _updateValues();
      }
    });
  }

  void _addTextControllerListener(TextEditingController controller) {
    controller.addListener(calculateCurrent);
  }

  void _setupTextController(TextEditingController controller, String value, void Function()? listener) {
    controller.text = value;
    if (listener != null) {
      controller.addListener(listener);
    }
  }

  @override
  void initState() {
    super.initState();
    _setupTextController(_latitudeController, widget.rectifier.latitude.toString(), () {
      latitude = double.tryParse(_latitudeController.text);
    });

    _setupTextController(_longitudeController, widget.rectifier.longitude.toString(), () {
      longitude = double.tryParse(_longitudeController.text);
    });

    _setupTextController(_multimeterVoltageController, widget.rectifier.readings!.multimeterVoltage.toString(), () {
      _updateValues();
    });
    _setupTextController(_panelMeterVoltageController, widget.rectifier.readings!.panelMeterVoltage.toString(), () {
      _updateValues();
    });
    _setupTextController(_voltageReadingCommentsController, widget.rectifier.readings!.voltageReadingComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_ammeterCurrentController, widget.rectifier.readings!.ammeterAmps.toString(), () {
      _updateValues();
    });
    _setupTextController(_panelMeterCurrentController, widget.rectifier.readings!.panelMeterAmps.toString(), () {
      _updateValues();
    });
    _setupTextController(_currentReadingCommentsController, widget.rectifier.readings!.currentReadingComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_courseTapController, widget.rectifier.tapReadings!.courseTapSettingFound.toString(), () {
      _updateValues();
    });
    _setupTextController(_mediumTapController, widget.rectifier.tapReadings!.mediumTapSettingFound.toString(), () {
      _updateValues();
    });
    _setupTextController(_fineTapController, widget.rectifier.tapReadings!.fineTapSettingFound.toString(), () {
      _updateValues();
    });
    _setupTextController(_oilLevelFindingsController, widget.rectifier.inspection!.oilLevelFindings.toString(), () {
      _updateValues();
    });
    _setupTextController(_oilLevelCommentsController, widget.rectifier.inspection!.oilLevelComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_deviceDamageFindingsController, widget.rectifier.inspection!.deviceDamageFindings.toString(), () {
      _updateValues();
    });
    _setupTextController(_deviceDamageCommentsController, widget.rectifier.inspection!.deviceDamageComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_circuitBreakersCommentsController, widget.rectifier.inspection!.circuitBreakersComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_fusesWiringCommentsController, widget.rectifier.inspection!.fusesWiringComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_lightningArrestorsCommentsController, widget.rectifier.inspection!.lightningArrestorsComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_ventScreensCommentsController, widget.rectifier.inspection!.ventScreensComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_breathersCommentsController, widget.rectifier.inspection!.breathersComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_removeObstructionsCommentsController, widget.rectifier.inspection!.removeObstructionsComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_cleanedCommentsController, widget.rectifier.inspection!.cleanedComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_tightenedCommentsController, widget.rectifier.inspection!.tightenedComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_polarityConditionCommentsController, widget.rectifier.inspection!.polarityConditionComments.toString(), () {
      _updateValues();
    });
    _setupTextController(_currentRatioController, widget.rectifier.readings!.currentRatio.toString(), () {
      _updateValues();
    });

    _setupTextController(_voltageDropController, widget.rectifier.readings!.voltageDrop.toString(), () {
      _updateValues();
    });

    _setupTextController(_voltageRatioController, widget.rectifier.readings!.voltageRatio.toString(), () {
      _updateValues();
    });

    _oilLevel = widget.rectifier.inspection?.oilLevel;
    _deviceDamage = widget.rectifier.inspection?.deviceDamage;
    _circuitBreakers = widget.rectifier.inspection?.circuitBreakers;
    _fusesWiring = widget.rectifier.inspection?.fusesWiring;
    _lightningArrestors = widget.rectifier.inspection?.lightningArrestors;
    _ventScreens = widget.rectifier.inspection?.ventScreens;
    _breathers = widget.rectifier.inspection?.breathers;
    _removeObstructions = widget.rectifier.inspection?.removeObstructions;
    _cleaned = widget.rectifier.inspection?.cleaned;
    _tightened = widget.rectifier.inspection?.tightened;
    _polarityCondition = widget.rectifier.inspection?.polarityCondition;

    _addFocusListener(_currentRatioFocusNode);
    _addFocusListener(_voltageRatioFocusNode);
    _addFocusListener(_voltageDropFocusNode);
    _addFocusListener(_multimeterVoltageFocusNode);
    _addFocusListener(_panelMeterVoltageFocusNode);
    _addFocusListener(_voltageReadingCommentsFocusNode);
    _addFocusListener(_panelMeterCurrentFocusNode);
    _addFocusListener(_ammeterCurrentFocusNode);
    _addFocusListener(_currentReadingCommentsFocusNode);
    _addFocusListener(_courseTapFocusNode);
    _addFocusListener(_mediumTapFocusNode);
    _addFocusListener(_fineTapFocusNode);
    _addFocusListener(_oilLevelFindingsFocusNode);
    _addFocusListener(_oilLevelCommentsFocusNode);
    _addFocusListener(_deviceDamageFindingsFocusNode);
    _addFocusListener(_deviceDamageCommentsFocusNode);
    _addFocusListener(_circuitBreakersCommentsFocusNode);
    _addFocusListener(_fusesWiringCommentsFocusNode);
    _addFocusListener(_lightningArrestorsCommentsFocusNode);
    _addFocusListener(_ventScreensCommentsFocusNode);
    _addFocusListener(_breathersCommentsFocusNode);
    _addFocusListener(_removeObstructionsCommentsFocusNode);
    _addFocusListener(_cleanedCommentsFocusNode);
    _addFocusListener(_tightenedCommentsFocusNode);
    _addFocusListener(_polarityConditionCommentsFocusNode);
    _addFocusListener(locationFocusNode);

    _addTextControllerListener(_currentRatioController);
    _addTextControllerListener(_voltageRatioController);
    _addTextControllerListener(_voltageDropController);

    currentStatusIndex = statuses.indexOf(widget.rectifier.status);
    calculateCurrent();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _panelMeterVoltageController.dispose();
    _multimeterVoltageController.dispose();
    _panelMeterCurrentController.dispose();
    _ammeterCurrentController.dispose();
    _currentRatioController.dispose();
    _voltageRatioController.dispose();
    _voltageDropController.dispose();
    _multimeterVoltageFocusNode.dispose();
    _panelMeterVoltageFocusNode.dispose();
    _panelMeterCurrentFocusNode.dispose();
    _ammeterCurrentFocusNode.dispose();
    _currentRatioFocusNode.dispose();
    _voltageRatioFocusNode.dispose();
    _voltageDropFocusNode.dispose();
    _courseTapController.dispose();
    _mediumTapController.dispose();
    _fineTapController.dispose();
    _courseTapFocusNode.dispose();
    _mediumTapFocusNode.dispose();
    _fineTapFocusNode.dispose();
    _oilLevelFindingsFocusNode.dispose();
    _oilLevelCommentsFocusNode.dispose();
    _deviceDamageFindingsFocusNode.dispose();
    _deviceDamageCommentsFocusNode.dispose();
    _circuitBreakersCommentsFocusNode.dispose();
    _fusesWiringCommentsFocusNode.dispose();
    _lightningArrestorsCommentsFocusNode.dispose();
    _ventScreensCommentsFocusNode.dispose();
    _breathersCommentsFocusNode.dispose();
    _removeObstructionsCommentsFocusNode.dispose();
    _cleanedCommentsFocusNode.dispose();
    _tightenedCommentsFocusNode.dispose();
    _polarityConditionCommentsFocusNode.dispose();
    locationFocusNode.dispose();
    _voltageReadingCommentsFocusNode.dispose();
    super.dispose();
  }

  String get currentStatus => statuses[currentStatusIndex];

  void calculateCurrent() {
    var rectifierDetailsProvider = Provider.of<RectifierNotifier>(context, listen: false);
    rectifierDetailsProvider.computeCurrent(
      currentRatioStr: _currentRatioController.text,
      voltageRatioStr: _voltageRatioController.text,
      voltageDropStr: _voltageDropController.text,
    );
  }

  void _updateValues() {
    // Get the provider
    var rectifierDetailsProvider = Provider.of<RectifierNotifier>(context, listen: false);

    // Call updateReadings from the provider and get the newReadings
    RectifierReadings newReadings = rectifierDetailsProvider.updateReadings(
      panelMeterVoltageStr: _panelMeterVoltageController.text,
      multimeterVoltageStr: _multimeterVoltageController.text,
      voltageReadingCommentsStr: _voltageReadingCommentsController.text,
      panelMeterAmpsStr: _panelMeterCurrentController.text,
      ammeterAmpsStr: _ammeterCurrentController.text,
      currentReadingCommentsStr: _currentReadingCommentsController.text,
      currentRatioStr: _currentRatioController.text,
      voltageRatioStr: _voltageRatioController.text,
      voltageDropStr: _voltageDropController.text,
    );

    final newTapReadings = TapReadings(
      courseTapSettingFound: _courseTapController.text,
      mediumTapSettingFound: _mediumTapController.text,
      fineTapSettingFound: _fineTapController.text,
    );

    // Gathering values from the new widgets
    final newInspection = RectifierInspection(
      reason: '',
      deviceDamage: _deviceDamage,
      deviceDamageFindings: _deviceDamageFindingsController.text,
      deviceDamageComments: _deviceDamageCommentsController.text,
      oilLevel: _oilLevel,
      oilLevelFindings: _oilLevelFindingsController.text,
      oilLevelComments: _oilLevelCommentsController.text,
      circuitBreakers: _circuitBreakers,
      circuitBreakersComments: _circuitBreakersCommentsController.text,
      fusesWiring: _fusesWiring,
      fusesWiringComments: _fusesWiringCommentsController.text,
      lightningArrestors: _lightningArrestors,
      lightningArrestorsComments: _lightningArrestorsCommentsController.text,
      ventScreens: _ventScreens,
      ventScreensComments: _ventScreensCommentsController.text,
      breathers: _breathers,
      breathersComments: _breathersCommentsController.text,
      removeObstructions: _removeObstructions,
      removeObstructionsComments: _removeObstructionsCommentsController.text,
      cleaned: _cleaned,
      cleanedComments: _cleanedCommentsController.text,
      tightened: _tightened,
      tightenedComments: _tightenedCommentsController.text,
      polarityCondition: _polarityCondition,
      polarityConditionComments: _polarityConditionCommentsController.text,
    );

    rectifierDetailsProvider.updateRectifier(widget.rectifier, widget.rectifier.area, widget.rectifier.serviceTag, widget.rectifier.use,
        widget.rectifier.status, widget.rectifier.maxVoltage, widget.rectifier.maxAmps, newReadings, newTapReadings, newInspection,
        latitude: latitude, longitude: longitude, context: context);
    widget.onStatusChanged(widget.rectifier.status, newReadings, newTapReadings, newInspection);
  }

  void _toggleStatus() async {
    setState(() {
      currentStatusIndex = (currentStatusIndex + 1) % statuses.length;
    });

    String newStatus = statuses[currentStatusIndex];
    Provider.of<RectifierNotifier>(context, listen: false).updateRectifierStatus(widget.rectifier, newStatus, context);

    await Future.delayed(Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40.h),
        child: AppBar(
          backgroundColor: Color.fromARGB(255, 0, 43, 92),
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            'Rectifier Inspection',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.home),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.w), // Using ScreenUtil
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildRectifierDetailsContainer(),
              SizedBox(height: 10.h), // Using ScreenUtil
              _buildVoltageContainer(),
              SizedBox(height: 10.h),
              _buildCurrentContainer(),
              SizedBox(height: 10.h),
              _buildShuntContainer(),
              SizedBox(height: 10.h),
              _buildTapReadingsContainer(),
              SizedBox(height: 10.h),
              _buildOilLevelContainer(),
              SizedBox(height: 10.h),
              _buildDeviceConditionContainer(),
              SizedBox(height: 10.h),
              _buildProtectiveDevicesContainer(),
              SizedBox(height: 10.h),
              _buildCleaningContainer(),
              SizedBox(height: 10.h),
              _buildCurrentConnectionsContainer(),
              // Add more containers here...
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRectifierDetailsContainer() {
    return Consumer<RectifierNotifier>(
      builder: (context, rectifierNotifier, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w), // Using ScreenUtil
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 0, 43, 92),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    // Makes the text take up the remaining space
                    child: Text(
                      ' ${widget.rectifier.area}: ${widget.rectifier.serviceTag} ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w), // Spacer between text and button
                  Container(
                    width: 100.w, // Using ScreenUtil
                    height: 30.h, // Using ScreenUtil
                    decoration: BoxDecoration(
                      color: widget.rectifier.getStatusColor(),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: ElevatedButton(
                      onPressed: _toggleStatus,
                      child: Text(' $currentStatus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.rectifier.getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                'Max Outputs: ${widget.rectifier.maxVoltage} V/ ${widget.rectifier.maxAmps} A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              //  SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('${widget.rectifier.latitude}, ${widget.rectifier.longitude}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      )),
                  SizedBox(width: 50.w),
                  LocationButton(
                    onLocationFetched: (latitude, longitude) {
                      Provider.of<RectifierNotifier>(context, listen: false).updateRectifier(
                          widget.rectifier,
                          widget.rectifier.area,
                          widget.rectifier.serviceTag,
                          widget.rectifier.use,
                          widget.rectifier.status,
                          widget.rectifier.maxVoltage,
                          widget.rectifier.maxAmps,
                          widget.rectifier.readings,
                          widget.rectifier.tapReadings,
                          widget.rectifier.inspection,
                          latitude: latitude,
                          longitude: longitude,
                          context: context);
                      setState(() {
                        widget.rectifier.latitude = latitude;
                        widget.rectifier.longitude = longitude;
                      });
                    },
                    latitude: widget.rectifier.latitude,
                    longitude: widget.rectifier.longitude,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoltageContainer() {
    SizedBox(height: 10.h);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.0.w), // Using ScreenUtil
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Voltage Readings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp, // Using ScreenUtil
                fontWeight: FontWeight.bold,
              )),
          Divider(
            color: Colors.grey,
            thickness: 2,
          ),
          SizedBox(height: 10.h), // Using ScreenUtil
          Row(
            children: [
              Text('Panel Meter Reading: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp, // Using ScreenUtil
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.w), // Using ScreenUtil
              Spacer(),
              SizedBox(
                  child: CustomTextField(
                controller: _panelMeterVoltageController,
                focusNode: _panelMeterVoltageFocusNode,
                hintText: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: const [
                      TextSpan(text: 'V DC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                width: 170.w,
                height: 35.h,
              )),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Text('Multimeter Reading: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.w),
              Spacer(),
              SizedBox(
                  child: CustomTextField(
                controller: _multimeterVoltageController,
                focusNode: _multimeterVoltageFocusNode,
                hintText: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: const [
                      TextSpan(text: 'V DC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                width: 170.w,
                height: 35.h,
              )),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Text('Comments: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.h),
              Expanded(
                child: SizedBox(
                    child: CustomTextField(
                  controller: _voltageReadingCommentsController,
                  focusNode: _voltageReadingCommentsFocusNode,
                  hintText: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: const [],
                    ),
                  ),
                  keyboardType: TextInputType.multiline,
                  textAlign: TextAlign.left,
                  width: 110.w,
                  height: 35.h,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentContainer() {
    SizedBox(height: 10.h);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Current Readings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              )),
          Divider(
            color: Colors.grey,
            thickness: 2,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text('Panel Meter Reading: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.w),
              Spacer(),
              SizedBox(
                  child: CustomTextField(
                controller: _panelMeterCurrentController,
                focusNode: _panelMeterCurrentFocusNode,
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
                width: 170.w,
                height: 35.h,
              )),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Text('Ammeter Reading: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.w),
              Spacer(),
              SizedBox(
                  child: CustomTextField(
                controller: _ammeterCurrentController,
                focusNode: _ammeterCurrentFocusNode,
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
                width: 170.w,
                height: 35.h,
              )),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Text('Comments: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.w),
              Expanded(
                child: SizedBox(
                    child: CustomTextField(
                  controller: _currentReadingCommentsController,
                  focusNode: _currentReadingCommentsFocusNode,
                  hintText: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: const [],
                    ),
                  ),
                  keyboardType: TextInputType.multiline,
                  textAlign: TextAlign.left,
                  width: 110.w,
                  height: 35.h,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShuntContainer() {
    return Consumer<RectifierNotifier>(
      builder: (context, rectifierNotifier, child) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 0, 43, 92),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Shunt Reading',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  )),
              Divider(
                color: Colors.grey,
                thickness: 2,
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shunt Ratio:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                      SizedBox(height: 30.h),
                      Text('Voltage Drop:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _currentRatioController,
                        focusNode: _currentRatioFocusNode,
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
                        width: 110.w,
                        height: 35.h,
                      ),
                      SizedBox(height: 20.h),
                      CustomTextField(
                        controller: _voltageDropController,
                        focusNode: _voltageDropFocusNode,
                        hintText: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: const [
                              TextSpan(text: 'mV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.left,
                        width: 110.w,
                        height: 35.h,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _voltageRatioController,
                        focusNode: _voltageRatioFocusNode,
                        hintText: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: const [
                              TextSpan(text: 'mV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.left,
                        width: 110.w,
                        height: 35.h,
                      ),
                      SizedBox(height: 25.h),
                      ValueListenableBuilder(
                        // Listener for Voltage Drop
                        valueListenable: rectifierNotifier.calculatedCurrentNotifier,
                        builder: (context, value, child) {
                          return Text(
                            '${value.toStringAsFixed(2)}  A',
                            style: TextStyle(
                              color: Color.fromARGB(255, 247, 143, 30),
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTapReadingsContainer() {
    SizedBox(height: 10.h);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Tap Readings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              )),
          Divider(
            color: Colors.grey,
            thickness: 2,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text('C:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.w),
              SizedBox(
                  width: 70.w,
                  height: 35.h,
                  child: CustomTextField(
                    controller: _courseTapController,
                    focusNode: _courseTapFocusNode,
                    hintText: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: const [],
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    width: 110.w,
                    height: 35.h,
                  )),
              Spacer(),
              Text('M:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.w),
              SizedBox(
                  width: 70.w,
                  height: 35.h,
                  child: CustomTextField(
                    controller: _mediumTapController,
                    focusNode: _mediumTapFocusNode,
                    hintText: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: const [],
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    width: 110.w,
                    height: 35.h,
                  )),
              Spacer(),

              SizedBox(height: 10.h),
              //   child: [
              Text('F:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 10.w),
              //   Spacer(),
              SizedBox(
                  width: 70.w,
                  height: 35.h,
                  child: CustomTextField(
                    controller: _fineTapController,
                    focusNode: _fineTapFocusNode,
                    hintText: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: const [],
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    width: 110.w,
                    height: 35.h,
                  )),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOilLevelContainer() {
    SizedBox(height: 10.h);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Oil Level/Condition',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              )),
          Divider(
            color: Colors.grey,
            thickness: 2,
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('   If Oil Level <25% of fill, it' 's a fail:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomRadio(
                groupValue: _oilLevel,
                value: 1,
                onChanged: (value) {
                  setState(() {
                    _oilLevel = value;
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
                groupValue: _oilLevel,
                value: 2,
                onChanged: (value) {
                  setState(() {
                    _oilLevel = value;
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
          SizedBox(height: 10.h),
          Row(
            children: [
              Text('  Findings:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          SizedBox(height: 5.h),
          SizedBox(
              width: 300.w,
              height: 40.h,
              child: TextField(
                controller: _oilLevelFindingsController,
                focusNode: _oilLevelFindingsFocusNode,
                style: TextStyle(
                  // color: Colors.white,
                  fontSize: 16.sp,
                  // fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Note color/smell/condition of oil.',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              )),
          SizedBox(height: 15.h),
          Row(
            children: [
              Text('  Comments:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          SizedBox(height: 5.h),
          SizedBox(
              width: 300.w,
              height: 40.h,
              child: CustomTextField(
                controller: _oilLevelCommentsController,
                focusNode: _oilLevelCommentsFocusNode,
                hintText: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: const [],
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                width: 110.w,
                height: 35.h,
              )),
        ],
      ),
    );
  }

  Widget _buildDeviceConditionContainer() {
    SizedBox(height: 10.h);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Device Condition',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              )),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Confirm no damage to device and free of insects/animals:',
                    softWrap: true,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomRadio(
                groupValue: _deviceDamage,
                value: 1,
                onChanged: (value) {
                  setState(() {
                    _deviceDamage = value;
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
                groupValue: _deviceDamage,
                value: 2,
                onChanged: (value) {
                  setState(() {
                    _deviceDamage = value;
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
          SizedBox(height: 15.h),
          Row(
            children: [
              Text('  Findings:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
              child: CustomTextField(
            controller: _deviceDamageFindingsController,
            focusNode: _deviceDamageFindingsFocusNode,
            hintText: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: const [],
              ),
            ),
            keyboardType: TextInputType.multiline,
            textAlign: TextAlign.left,
            width: 110.w,
            height: 35.h,
          )),
          SizedBox(height: 5.h),
          SizedBox(
              child: CustomTextField(
            controller: _deviceDamageCommentsController,
            focusNode: _deviceDamageCommentsFocusNode,
            hintText: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: const [],
              ),
            ),
            keyboardType: TextInputType.multiline,
            textAlign: TextAlign.left,
            width: 110.w,
            height: 35.h,
          )),
        ],
      ),
    );
  }

  Widget _buildProtectiveDevicesContainer() {
    SizedBox(height: 10.h);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Protective Devices',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              )),
          Divider(
            color: Colors.grey,
            thickness: 2,
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    'Confirm all protective devices are present and in good condition:',
                    softWrap: true,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10), // Add some padding inside the container
            decoration: BoxDecoration(
              border: Border.all(
                  color: Color.fromARGB(255, 67, 197, 228), // Set border color
                  width: 2.0.w),
              borderRadius: BorderRadius.circular(8.0), // Add rounded corners
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text('Circuit Breakers:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    CustomRadio(
                      groupValue: _circuitBreakers,
                      value: 1,
                      onChanged: (value) {
                        setState(() {
                          _circuitBreakers = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 60.w),
                    CustomRadio(
                      groupValue: _circuitBreakers,
                      value: 2,
                      onChanged: (value) {
                        setState(() {
                          _circuitBreakers = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('Not OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text('Comments:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    //     ],
                    //    ),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: CustomTextField(
                      controller: _circuitBreakersCommentsController,
                      focusNode: _circuitBreakersCommentsFocusNode,
                      hintText: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: const [],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      width: 110.w,
                      height: 35.h,
                    )),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10), // Add some padding inside the container
            decoration: BoxDecoration(
              border: Border.all(
                  color: Color.fromARGB(255, 67, 197, 228), // Set border color
                  width: 2.w),
              borderRadius: BorderRadius.circular(8.0), // Add rounded corners
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text('Fuses/Wiring:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    CustomRadio(
                      groupValue: _fusesWiring,
                      value: 1,
                      onChanged: (value) {
                        setState(() {
                          _fusesWiring = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 60.w),
                    CustomRadio(
                      groupValue: _fusesWiring,
                      value: 2,
                      onChanged: (value) {
                        setState(() {
                          _fusesWiring = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('Not OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text('Comments:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: CustomTextField(
                      controller: _fusesWiringCommentsController,
                      focusNode: _fusesWiringCommentsFocusNode,
                      hintText: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: const [],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      width: 110.w,
                      height: 35.h,
                    )),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10), // Add some padding inside the container
            decoration: BoxDecoration(
              border: Border.all(
                  color: Color.fromARGB(255, 67, 197, 228), // Set border color
                  width: 2.w // Set border width
                  ),
              borderRadius: BorderRadius.circular(8.0), // Add rounded corners
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text('Arrestors:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    CustomRadio(
                      groupValue: _lightningArrestors,
                      value: 1,
                      onChanged: (value) {
                        setState(() {
                          _lightningArrestors = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 60.w),
                    CustomRadio(
                      groupValue: _lightningArrestors,
                      value: 2,
                      onChanged: (value) {
                        setState(() {
                          _lightningArrestors = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('Not OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text('Comments:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: CustomTextField(
                      controller: _lightningArrestorsCommentsController,
                      focusNode: _lightningArrestorsCommentsFocusNode,
                      hintText: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: const [],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      width: 110.w,
                      height: 35.h,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleaningContainer() {
    SizedBox(height: 10.h);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Cleaning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              )),
          Divider(
            color: Colors.grey,
            thickness: 2,
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text('Confirm all vent screens, breathers, and rectifier cabinet are clean and free from obstructions:',
                      softWrap: true,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10), // Add some padding inside the container
            decoration: BoxDecoration(
              border: Border.all(
                  color: Color.fromARGB(255, 67, 197, 228), // Set border color
                  width: 2.w // Set border width
                  ),
              borderRadius: BorderRadius.circular(8.0), // Add rounded corners
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text('Vent Screens:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    CustomRadio(
                      groupValue: _ventScreens,
                      value: 1,
                      onChanged: (value) {
                        setState(() {
                          _ventScreens = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 60.w),
                    CustomRadio(
                      groupValue: _ventScreens,
                      value: 2,
                      onChanged: (value) {
                        setState(() {
                          _ventScreens = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('Not OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text('Comments:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    //     ],
                    //    ),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: CustomTextField(
                      controller: _ventScreensCommentsController,
                      focusNode: _ventScreensCommentsFocusNode,
                      hintText: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: const [],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      width: 110.w,
                      height: 35.h,
                    )),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10), // Add some padding inside the container
            decoration: BoxDecoration(
              border: Border.all(
                  color: Color.fromARGB(255, 67, 197, 228), // Set border color
                  width: 2.w // Set border width
                  ),
              borderRadius: BorderRadius.circular(8.0), // Add rounded corners
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text('Breathers:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    CustomRadio(
                      groupValue: _breathers,
                      value: 1,
                      onChanged: (value) {
                        setState(() {
                          _breathers = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 60.w),
                    CustomRadio(
                      groupValue: _breathers,
                      value: 2,
                      onChanged: (value) {
                        setState(() {
                          _breathers = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('Not OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text('Comments:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: CustomTextField(
                      controller: _breathersCommentsController,
                      focusNode: _breathersCommentsFocusNode,
                      hintText: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: const [],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      width: 110.w,
                      height: 35.h,
                    )),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10), // Add some padding inside the container
            decoration: BoxDecoration(
              border: Border.all(
                  color: Color.fromARGB(255, 67, 197, 228), // Set border color
                  width: 2.w // Set border width
                  ),
              borderRadius: BorderRadius.circular(8.0), // Add rounded corners
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text('Obstructions:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    CustomRadio(
                      groupValue: _removeObstructions,
                      value: 1,
                      onChanged: (value) {
                        setState(() {
                          _removeObstructions = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 60.w),
                    CustomRadio(
                      groupValue: _removeObstructions,
                      value: 2,
                      onChanged: (value) {
                        setState(() {
                          _removeObstructions = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('Not OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text('Comments:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: CustomTextField(
                      controller: _removeObstructionsCommentsController,
                      focusNode: _removeObstructionsCommentsFocusNode,
                      hintText: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: const [],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      width: 110.w,
                      height: 35.h,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConnectionsContainer() {
    SizedBox(height: 10.h);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 0, 43, 92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Current-Carrying Connections',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              )),
          Divider(
            color: Colors.grey,
            thickness: 2,
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text('Confirm all current-carry connections are clean and tight:',
                      softWrap: true,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10), // Add some padding inside the container
            decoration: BoxDecoration(
              border: Border.all(
                  color: Color.fromARGB(255, 67, 197, 228), // Set border color
                  width: 2.w // Set border width
                  ),
              borderRadius: BorderRadius.circular(8.0), // Add rounded corners
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text('Cleaned:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    CustomRadio(
                      groupValue: _cleaned,
                      value: 1,
                      onChanged: (value) {
                        setState(() {
                          _cleaned = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 60.w),
                    CustomRadio(
                      groupValue: _cleaned,
                      value: 2,
                      onChanged: (value) {
                        setState(() {
                          _cleaned = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('No',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text('Comments:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    //     ],
                    //    ),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: CustomTextField(
                      controller: _cleanedCommentsController,
                      focusNode: _cleanedCommentsFocusNode,
                      hintText: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: const [],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      width: 110.w,
                      height: 35.h,
                    )),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
            decoration: BoxDecoration(
              border: Border.all(color: Color.fromARGB(255, 67, 197, 228), width: 2.w),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 120.w,
                      child: Text('Tightened:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    CustomRadio(
                      groupValue: _tightened,
                      value: 1,
                      onChanged: (value) {
                        setState(() {
                          _tightened = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 60.w),
                    CustomRadio(
                      groupValue: _tightened,
                      value: 2,
                      onChanged: (value) {
                        setState(() {
                          _tightened = value;
                        });
                      },
                    ),
                    SizedBox(width: 10.w),
                    Text('No',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text('Comments:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        )),
                    SizedBox(width: 10.w),
                    Expanded(
                        child: CustomTextField(
                      controller: _tightenedCommentsController,
                      focusNode: _tightenedCommentsFocusNode,
                      hintText: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: const [],
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      width: 110.w,
                      height: 35.h,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
