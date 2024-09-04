// ignore_for_file: unused_local_variable, no_leading_underscores_for_local_identifiers, unused_element

import 'dart:async';
import 'dart:io';
//import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
//import 'package:path/path.dart' as path;

import 'package:asset_inspections/Models/project_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import 'package:asset_inspections/Models/camera_model.dart';
import 'package:asset_inspections/database_helper.dart';

class CustomCamera extends StatefulWidget {
  final cameraSettings = DatabaseHelper.instance.getCameraSettings();
  final int projectID;
  final String projectClient;
  final String projectName;
  final int? stationID;
  final String? stationArea;
  final String? stationTSID;
  final int? rectifierID;
  final String? rectifierArea;
  final String? rectifierServiceTag;

  CustomCamera({
    super.key,
    required this.projectID,
    required this.projectClient,
    required this.projectName,
    this.stationID,
    this.stationArea,
    this.stationTSID,
    this.rectifierID,
    this.rectifierArea,
    this.rectifierServiceTag,
  });

  static void navigateToCustomCamera(BuildContext context, int projectID, String projectClient, String projectName,
      {int? stationID, String? stationArea, String? stationTSID, int? rectifierID, String? rectifierArea, String? rectifierServiceTag}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomCamera(
          projectID: projectID,
          projectClient: projectClient,
          projectName: projectName,
          stationID: stationID,
          stationArea: stationArea,
          stationTSID: stationTSID,
          rectifierID: rectifierID,
          rectifierArea: rectifierArea,
          rectifierServiceTag: rectifierServiceTag,
        ),
      ),
    );
  }

  @override
  createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCamera> with WidgetsBindingObserver {
//  final GlobalKey _imageKey = GlobalKey();
  Uint8List? _thumbnailImageBytes;
  bool _isFlashVisible = false;
  // String _imagePath = '';
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  double _currentZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  ScreenshotController screenshotController = ScreenshotController();
  // Location data variables
  final Location _location = Location(); // Define the Location instance
  StreamSubscription<LocationData>? _locationSubscription;
  late GoogleMapController _mapController;

  // Google Maps Overlay variables
  Set<Marker> _markers = {};
  double latitude = 0;
  double longitude = 0;
  // bool _isMapOverlayVisible = false;
  final CameraPosition _initialCameraPosition = const CameraPosition(
      target: LatLng(0.0, 0.0), // Default position, update with actual location
      zoom: 14);
  CameraPosition _currentCameraPosition = const CameraPosition(
      target: LatLng(0.0, 0.0), // Default position, update with actual location
      zoom: 14);
  MapPosition? mapPosition = MapPosition.bottomLeft;
  MapPosition? dataPosition = MapPosition.topLeft;
  static String formatEnumValue(String enumValue) {
    return enumValue
        .replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (Match match) => ' ${match.group(0)!.toUpperCase()}')
        .split(' ')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  // Use a getter for mapPositionOptions to access the static method
  List<String> get mapPositionOptions => MapPosition.values.map((position) => formatEnumValue(position.toString().split('.').last)).toList();

  Location location = Location();
  LocationData? _locationData;
  // ignore: unused_field
  String _currentAddress = '';
  geocoding.Placemark _currentPlacemark = const geocoding.Placemark();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsSequentially();
    //  _initCamera();
    final cameraSettings = Provider.of<CameraSettings>(context, listen: false);
    cameraSettings.loadCameraSettingsFromDatabase();
    //  _startLocationStream();
    //  getCurrentLocation();
    //  _fetchAndSetCurrentPlacemark();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  //*********************************************************
  Future<void> _requestPermissionsSequentially() async {
    // Request location permission first
    PermissionStatus locationPermission = await _requestLocationPermission();
    if (locationPermission == PermissionStatus.granted) {
      // Only proceed with camera initialization if location permission is granted
      await _initCamera();
      _startLocationStream();
      getCurrentLocation();
      _fetchAndSetCurrentPlacemark();
    } else {
      _showPermissionErrorDialog('Location Permission Denied',
          'This app requires location access to function. Please allow location access for this app in your device settings.');
    }
  }

  Future<PermissionStatus> _requestLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return PermissionStatus.denied;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
    }
    return permissionGranted;
  }

  //*********************************************************

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the CameraController
      _initializeCameraController(cameraController.description);
    }
  }

  Future<void> _initializeCameraController(CameraDescription cameraDescription) async {
    _controller = CameraController(cameraDescription, ResolutionPreset.max);
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras[0], ResolutionPreset.max);
        await _controller!.initialize();
        _maxZoomLevel = await _controller!.getMaxZoomLevel(); // Correctly awaiting the Future
        if (!mounted) return;
        setState(() {});
      }
    } on CameraException catch (e) {
      String title;
      String message;

      switch (e.code) {
        case 'CameraAccessDenied':
          title = "Camera Permission Denied";
          message = "This app requires camera access to function. Please allow camera access for this app in your device's settings.";
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          title = "Camera Access Previously Denied";
          message =
              "You have previously denied camera access for this app. Please enable camera access for this app in your device's Settings > Privacy > Camera.";
          break;
        case 'CameraAccessRestricted':
          title = "Camera Access Restricted";
          message = "Camera access is restricted and cannot be enabled for this app, possibly due to parental control settings.";
          break;
        // Handle other cases as before
        default:
          title = "Unexpected Error";
          message = "An unexpected error occurred. Please try again or contact support if the problem persists.";
          break;
      }

      _showPermissionErrorDialog(title, message);
    } catch (e) {
      // Handle any non-CameraException errors.
      if (kDebugMode) {
        print("An unexpected error occurred: $e");
      }
      // Consider showing a generic error dialog or logging the error as appropriate.
    }
  }

  void _startLocationStream() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Check for location permissions
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Adjust location settings for better accuracy
    _location.changeSettings(
      accuracy: LocationAccuracy.high, // Use high accuracy
      distanceFilter: 1, // Trigger updates every 10 meters
      //  interval: 100, // Update interval in milliseconds
    );

    // Listen for location changes
    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      _updateMapLocation(currentLocation);
    });
  }

  void _updateMapLocation(LocationData currentLocation) {
    final settings = Provider.of<CameraSettings>(context, listen: false);
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
          zoom: settings.mapScale,
        ),
      ),
    );
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: LatLng(currentLocation.latitude!, currentLocation.longitude!),
          //  infoWindow: InfoWindow(title: "Current Location"),
        ),
      };
    });
  }

  void _updateMapZoomInstantly(double zoomLevel) {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentCameraPosition.target, // Use the last known position
          zoom: zoomLevel,
        ),
      ),
    );
  }

  MapType _getMapType(String mapTypeString) {
    switch (mapTypeString) {
      case 'normal':
        return MapType.normal;
      case 'satellite':
        return MapType.satellite;
      case 'terrain':
        return MapType.terrain;
      case 'hybrid':
        return MapType.hybrid;
      default:
        return MapType.normal; // Default to 'normal' if no match is found
    }
  }

  void _captureImageWithOverlay() async {
    final imageFile = await screenshotController.capture();
    if (imageFile != null) {
      setState(() {
        _thumbnailImageBytes = imageFile;
        _isFlashVisible = true;
      });
      final imageInfo = await _saveImageToFile(imageFile);
      _saveImagePathToDatabase(imageInfo['path']!, imageInfo['name']!);

      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _isFlashVisible = false;
        });
      });
    }
  }

  Future<void> _saveImagePathToDatabase(String imagePath, String fileName) async {
    final dbHelper = DatabaseHelper.instance;
    int? stationID = widget.stationID;

    if (stationID != null) {
      await dbHelper.updateTestStationPicture(stationID, imagePath);
    }
  }

/*
  void _captureImageWithOverlay() async {
    final imageFile = await screenshotController.capture();
    if (imageFile != null) {
      setState(() {
        _thumbnailImageBytes = imageFile;
        _isFlashVisible = true; // Trigger the flash animation
      });
      final fileName = await _saveImageToFile(imageFile);
      // _saveImagePathToDatabase(fileName);

      // Hide the flash animation after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _isFlashVisible = false;
        });
      });
    }
  }
*/
/*
  Future<void> _saveImagePathToDatabase(String imagePath) async {
    final databasePath = await getDatabasesPath();
    final db = await openDatabase(path.join(databasePath, 'your_database.db'));

    await db.insert(
      'your_table',
      {'image_path': imagePath},
    //  conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
*/
  // Future<String> _saveImageToFile(Uint8List imageBytes) async {
  Future<Map<String, String>> _saveImageToFile(Uint8List imageBytes) async {
    Directory? directory;
    try {
      directory = await getExternalStorageDirectory();
      String newPath = '';
      List<String> folders = directory!.path.split('/');
      for (int x = 1; x < folders.length; x++) {
        String folder = folders[x];
        if (folder != "Android") {
          newPath += "/$folder";
        } else {
          break;
        }
      }
      newPath = "$newPath/Download/${widget.projectClient}_${widget.projectName}";
      directory = Directory(newPath);
    } catch (e) {
      directory = await getApplicationDocumentsDirectory(); // Fallback for iOS and errors
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Using a filesystem-friendly date format
    final DateFormat formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    String fileName;
    if (widget.stationID != null) {
      fileName = "${formatter.format(DateTime.now())}_${widget.stationArea}-${widget.stationTSID}.png";
    } else {
      fileName = "${formatter.format(DateTime.now())}_${widget.rectifierArea}_${widget.rectifierServiceTag}.png";
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    //return file.path;
    return {'path': file.path, 'name': fileName};
  }

  void _saveCapturedImage(Uint8List? imageFile) {
    if (imageFile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayCapturedImageScreen(imageBytes: imageFile),
        ),
      );
    }
  }

  // Finding enum from string value
  void setMapPositionFromString(String positionString) {
    final settings = Provider.of<CameraSettings>(context, listen: false);
    String enumString = positionString.replaceAll(' ', '');
    enumString = 'MapPosition.${enumString[0].toLowerCase()}${enumString.substring(1)}';

    settings.mapPosition = MapPosition.values.firstWhere(
      (position) => position.toString() == enumString,
      orElse: () => MapPosition.bottomLeft,
    );
  }

  void setDataPositionFromString(String positionString) {
    final settings = Provider.of<CameraSettings>(context, listen: false);
    String enumString = positionString.replaceAll(' ', '');
    enumString = 'MapPosition.${enumString[0].toLowerCase()}${enumString.substring(1)}';

    settings.dataPosition = MapPosition.values.firstWhere(
      (position) => position.toString() == enumString,
      orElse: () => MapPosition.topLeft,
    );
  }

  void _showPermissionErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog() {
    final settings = Provider.of<CameraSettings>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('Overlay Settings')),
          content: StatefulBuilder(
            // Use StatefulBuilder to manage local state within the dialog
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text('Show Map'),
                        const Spacer(),
                        Switch(
                            value: settings.isMapOverlayVisible,
                            onChanged: (value) {
                              setState(() {
                                // This updates the local dialog UI
                                settings.isMapOverlayVisible = value;
                                // Ensure Default position is set when toggled on
                                if (value) {
                                  settings.mapPosition ??= MapPosition.bottomLeft; // Default position when toggled ON
                                }
                              });
                              //  settings.updateMapOverlayVisibility(value);
                              settings.updateCameraSettingsToDatabase();
                            }),
                        IconButton(
                          icon: Icon(
                            Icons.open_in_new,
                            size: 16.sp,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showMapOptionsDialog();
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text('Location Data'),
                        const Spacer(),
                        Switch(
                          value: settings.isDataOverlayVisible,
                          onChanged: (value) {
                            setState(() {
                              settings.isDataOverlayVisible = value;
                              if (value) {
                                settings.dataPosition ??= MapPosition.topLeft; // Default position when toggled ON
                              }
                            });
                            settings.updateDataOverlayVisibility(value);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.open_in_new,
                            size: 16.sp,
                            color: Colors.blue,
                          ),

                          onPressed: () {
                            Navigator.of(context).pop();
                            _showDataOptionsDialog();
                          },
                          // child: const Text("Settings..."),
                        ),
                      ],
                    ),
                    // Add more options as needed
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showMapOptionsDialog() {
    final settings = Provider.of<CameraSettings>(context, listen: false);
    // Temporary state for dialog
    //String tempMapType = _mapType;
    // double tempMapOpacity = _mapOpacity;
    // double tempMapSize = _mapSize;
    // double tempMapScale = _mapScale;
    String tempMapType = settings.mapType;
    double tempMapOpacity = settings.mapOpacity;
    double tempMapSize = settings.mapSize;
    double tempMapScale = settings.mapScale;
    if (kDebugMode) {
      print('Map Positions: ${settings.mapPosition}');
      print('Map Type: ${settings.mapType}');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // This allows the dialog itself to be rebuilt
          builder: (context, setState) {
            return AlertDialog(
              title: const Center(child: Text('Map Settings')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Map Position'),
                        DropdownButton<MapPosition>(
                          value: settings.mapPosition,
                          onChanged: (MapPosition? newPosition) {
                            setState(() {
                              settings.mapPosition = newPosition;
                            });
                            settings.updateMapPosition(newPosition);
                            settings.updateCameraSettingsToDatabase();
                          },
                          items: MapPosition.values.map<DropdownMenuItem<MapPosition>>((MapPosition value) {
                            return DropdownMenuItem<MapPosition>(
                              value: value,
                              child: Text(formatEnumValue(value.toString().split('.').last)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Map Type'),
                        DropdownButton<String>(
                          value: settings.mapType, // Ensure this exactly matches one of the options below.
                          onChanged: (String? newValue) {
                            setState(() {
                              settings.mapType = newValue!;
                            });
                            settings.updateMapType(newValue!);
                          },
                          items: <String>['Normal', 'Satellite', 'Terrain', 'Hybrid'].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value.toLowerCase(), // This ensures the values are all lowercase
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Map Opacity'),
                      ],
                    ),
                    Slider(
                      value: settings.mapOpacity,
                      min: 0,
                      max: 1,
                      divisions: 10,
                      //   label: tempMapOpacity.toString(),
                      onChanged: (double value) {
                        setState(() {
                          // This now refers to the StatefulBuilder's setState
                          tempMapOpacity = value;
                        });
                        settings.updateMapOpacity(value);
                      },
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Map Size'),
                      ],
                    ),
                    Slider(
                      value: settings.mapSize,
                      min: 25,
                      max: 250,
                      divisions: 15,
                      label: tempMapSize.toString(),
                      onChanged: (double value) {
                        setState(() {
                          tempMapSize = value;
                        });
                        settings.updateMapSize(value);
                      },
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Map Zoom'),
                      ],
                    ),
                    Slider(
                      value: tempMapScale,
                      min: 1,
                      max: 25,
                      divisions: 24,
                      label: tempMapScale.toString(),
                      onChanged: (double value) {
                        setState(() {
                          tempMapScale = value;
                          //  _updateMapSettings(tempMapType, tempMapOpacity, tempMapSize, tempMapScale);
                        });
                        _updateMapZoomInstantly(value);
                        settings.updateMapScale(value);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    settings.updateCameraSettingsToDatabase();
                    // Update the main state once dialog is popped
                    //  _updateMapSettings(tempMapType, tempMapOpacity, tempMapSize, tempMapScale);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMapOverlay() {
    final settings = Provider.of<CameraSettings>(context, listen: false);
    return Opacity(
      opacity: settings.mapOpacity,
      // ignore: sized_box_for_whitespace
      child: Container(
        //  color: Colors.transparent,
        width: settings.mapSize,
        height: settings.mapSize,
        child: GoogleMap(
          zoomControlsEnabled: false,
          zoomGesturesEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,

          initialCameraPosition: _initialCameraPosition,
          mapType: _getMapType(settings.mapType), // Use the method to get the MapType enum
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          onCameraMove: (CameraPosition position) {
            _currentCameraPosition = position;
          },
        ),
      ),
    );
  }

  void _showDataOptionsDialog() {
    final settings = Provider.of<CameraSettings>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            TextStyle textStyle = TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              //  fontStyle:
            );
            return AlertDialog(
              title: const Center(child: Text('Location Data Settings')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Data Position:', style: textStyle),
                        DropdownButton<MapPosition>(
                          value: settings.dataPosition,
                          onChanged: (MapPosition? newPosition) {
                            setState(() {
                              settings.dataPosition = newPosition;
                            });
                            settings.updateDataPosition(newPosition);
                          },
                          items: MapPosition.values.map<DropdownMenuItem<MapPosition>>((MapPosition value) {
                            return DropdownMenuItem<MapPosition>(
                              value: value,
                              child: Text(formatEnumValue(value.toString().split('.').last)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Font Style:', style: textStyle),
                        DropdownButton<String>(
                          value: settings.selectedFontStyle,
                          onChanged: (String? newValue) {
                            setState(() {
                              settings.selectedFontStyle = newValue!;
                              settings.updateFontStyle(newValue);
                              //  settings.updateCameraSettingsToDatabase();
                            });
                            //  settings.updateCameraSettingsToDatabase();
                            settings.updateFontStyle(newValue!);
                          },
                          items: CameraSettings.fontStyleOptions.map<DropdownMenuItem<String>>((Map<String, dynamic> style) {
                            return DropdownMenuItem<String>(
                              value: style['style'].toLowerCase(),
                              child: Text(style['style']),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Font Color:', style: textStyle),
                        DropdownButton<String>(
                          value: settings.selectedFontColor,
                          onChanged: (String? newValue) {
                            setState(() {
                              settings.selectedFontColor = newValue!;
                              settings.updateFontColor(newValue);
                            });
                            settings.updateFontColor(newValue!);
                          },
                          items: CameraSettings.fontColors.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value.toLowerCase(),
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Font Size:', style: textStyle),
                        DropdownButton<String>(
                          value: settings.selectedFontSize.toString(),
                          onChanged: (String? newValue) {
                            setState(() {
                              settings.selectedFontSize = double.parse(newValue!);
                            });
                          },
                          items: CameraSettings.fontSizes.map<DropdownMenuItem<String>>((double value) {
                            return DropdownMenuItem<String>(
                              value: value.toString(),
                              child: Text(value.toString()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date:', style: textStyle),
                        DropdownButton<String>(
                          value: settings.selectedDateFormat,
                          onChanged: (String? newValue) {
                            setState(() {
                              settings.selectedDateFormat = newValue!;
                            });
                          },
                          items: CameraSettings.dateFormats.map<DropdownMenuItem<String>>((String value) {
                            // Format the current date according to the format string
                            String formattedDate = DateFormat(value).format(DateTime.now());
                            return DropdownMenuItem<String>(
                              value: value,
                              // Show the formatted current date instead of the format string
                              child: Text(formattedDate),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h), // Add some spacing (optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Location:', style: textStyle),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        DropdownButton<String>(
                          value: settings.selectedLocationFormat,
                          onChanged: (String? newValue) {
                            setState(() {
                              settings.selectedLocationFormat = newValue!;
                            });
                          },
                          items: CameraSettings.locationFormats.map<DropdownMenuItem<String>>((String value) {
                            String address = formatAddress(_currentPlacemark, value);
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(address), // Or use an example address if available
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks.first;
        // Construct the address string as needed
        String address = "${place.locality}, ${place.subAdministrativeArea}, ${place.country}";
        return address;
      }
      return "No address available";
    } catch (e) {
      return "Failed to get address: $e";
    }
  }

  void getCurrentLocation() async {
    _locationData = await location.getLocation();
    displayLocationAddress(); // Optionally, immediately display the address
  }

  void _fetchAndSetCurrentPlacemark() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();

    // Now use the geocoding package to get placemark data
    List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
      locationData.latitude!,
      locationData.longitude!,
    );

    if (placemarks.isNotEmpty) {
      setState(() {
        _currentPlacemark = placemarks.first;
      });
    }
  }

  void displayLocationAddress() async {
    if (_locationData != null) {
      // Assuming getAddressFromLatLng is correctly implemented
      String address = await getAddressFromLatLng(_locationData!.latitude!, _locationData!.longitude!);
      setState(() {
        _currentAddress = address;
      });
    }
  }

  String formatAddress(geocoding.Placemark place, String format) {
    switch (format) {
      case 'None':
        return 'None';
      case 'Country':
        return "${place.country}";
      case 'State':
        return "${place.administrativeArea}";
      case 'County':
        return "${place.subAdministrativeArea}";
      case 'City':
        return "${place.locality}";
      case 'Road Name':
        return "${place.thoroughfare}";
      case 'Building Number, Street Name':
        return "${place.subThoroughfare}, ${place.thoroughfare}";
      case 'Building Number':
        return "${place.subThoroughfare}";
      case 'Street Address, City, State, Zip':
        return "${place.street},\n${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
      case 'Street Address, City, County, Zip, Country':
        return "${place.street},\n${place.locality}, ${place.subAdministrativeArea}, ${place.postalCode},\n${place.country}";
      case 'Street Name, City, County, Zip':
        return "${place.thoroughfare},\n${place.locality}, ${place.subAdministrativeArea}, ${place.postalCode}";
      case 'City, County, Zip, Country':
        return "${place.locality}, ${place.subAdministrativeArea}, ${place.postalCode},\n${place.country}";
      case 'Street Address, City':
        return "${place.street},\n${place.locality}";
      case 'Street Address, City, County':
        return "${place.street},\n${place.locality}, ${place.subAdministrativeArea}";
      default:
        return "Format not supported";
    }
  }

  Widget _buildDataOverlay() {
    var projectModel = Provider.of<ProjectModel>(context, listen: false);
    String projectClient = projectModel.client;

    return Consumer<CameraSettings>(
      builder: (context, settings, child) {
        // The rest of your method remains the same
        String formattedDate = DateFormat(settings.selectedDateFormat).format(DateTime.now());
        Color fontColor = settings.selectedFontColor == 'black'
            ? Colors.black
            : settings.selectedFontColor == 'white'
                ? Colors.white
                : settings.selectedFontColor == 'red'
                    ? Colors.red
                    : settings.selectedFontColor == 'green'
                        ? Colors.green
                        : Colors.blue;
        double fontSize = settings.selectedFontSize;
        String selectedFormatDescription = settings.selectedLocationFormat;

        TextStyle textStyle = TextStyle(
          color: fontColor,
          fontSize: fontSize,
          fontWeight: settings.selectedFontStyle.contains('Bold') ? FontWeight.bold : FontWeight.normal,
          fontStyle: settings.selectedFontStyle.contains('Italic') ? FontStyle.italic : FontStyle.normal,
        );

        return Opacity(
          opacity: settings.mapOpacity,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(projectClient, style: textStyle),
                Text(widget.projectName, style: textStyle),
                Text('${widget.stationArea}-${widget.stationTSID}', style: textStyle),
                if (formattedDate != 'None') Text(formattedDate, style: textStyle),
                if (selectedFormatDescription != 'None') Text(formatAddress(_currentPlacemark, selectedFormatDescription), style: textStyle),
                // Your other text widgets based on settings
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cameraWithOverlay() {
    return Consumer<CameraSettings>(
      builder: (context, settings, child) {
        return GestureDetector(
          onScaleUpdate: (ScaleUpdateDetails details) {
            _onScaleUpdate(details);
          },
          child: Stack(
            children: [
              CameraPreview(_controller!), // Camera preview
              if (settings.isMapOverlayVisible)
                Positioned(
                  top: settings.mapPosition == MapPosition.topLeft ||
                          settings.mapPosition == MapPosition.topCenter ||
                          settings.mapPosition == MapPosition.topRight
                      ? 15
                      : null,
                  bottom: settings.mapPosition == MapPosition.bottomLeft ||
                          settings.mapPosition == MapPosition.bottomCenter ||
                          settings.mapPosition == MapPosition.bottomRight
                      ? 15
                      : null,
                  left: (settings.mapPosition == MapPosition.topCenter || settings.mapPosition == MapPosition.bottomCenter)
                      ? 0
                      : (settings.mapPosition == MapPosition.topLeft || settings.mapPosition == MapPosition.bottomLeft ? 15 : null),
                  right: (settings.mapPosition == MapPosition.topCenter || settings.mapPosition == MapPosition.bottomCenter)
                      ? 0
                      : (settings.mapPosition == MapPosition.topRight || settings.mapPosition == MapPosition.bottomRight ? 15 : null),
                  child: Align(
                    alignment: _getMapAlignment(settings.mapPosition), // Pass settings.mapPosition to the method
                    child: _buildMapOverlay(),
                  ),
                ),
              if (settings.isDataOverlayVisible)
                Positioned(
                  top: settings.dataPosition == MapPosition.topLeft ||
                          settings.dataPosition == MapPosition.topCenter ||
                          settings.dataPosition == MapPosition.topRight
                      ? 15
                      : null,
                  bottom: settings.dataPosition == MapPosition.bottomLeft ||
                          settings.dataPosition == MapPosition.bottomCenter ||
                          settings.dataPosition == MapPosition.bottomRight
                      ? 15
                      : null,
                  left: (settings.dataPosition == MapPosition.topCenter || settings.dataPosition == MapPosition.bottomCenter)
                      ? 0
                      : (settings.dataPosition == MapPosition.topLeft || settings.dataPosition == MapPosition.bottomLeft ? 15 : null),
                  right: (settings.dataPosition == MapPosition.topCenter || settings.dataPosition == MapPosition.bottomCenter)
                      ? 0
                      : (settings.dataPosition == MapPosition.topRight || settings.dataPosition == MapPosition.bottomRight ? 15 : null),
                  child: Align(
                    alignment: _getMapAlignment(settings.dataPosition), // Pass settings.dataPosition to the method
                    child: _buildDataOverlay(),
                  ),
                ),
              Positioned.fill(
                child: _buildFlashAnimation(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashAnimation() {
    return AnimatedOpacity(
      opacity: _isFlashVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 50), // Fast fade in
      child: Container(
        color: Colors.white,
      ),
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    const double sensitivityFactor = 0.05; // Adjust this value for sensitivity
    final double scaleDelta = details.scale - 1;

    // Calculate new zoom level based on the gesture's scale change and sensitivity
    double newZoomLevel = _currentZoomLevel + (scaleDelta * sensitivityFactor);
    newZoomLevel = newZoomLevel.clamp(1.0, _maxZoomLevel); // Ensure within valid range

    // Update zoom level if the change is significant
    if ((newZoomLevel - _currentZoomLevel).abs() > 0.01) {
      // Adjust threshold as needed
      setState(() {
        _currentZoomLevel = newZoomLevel;
      });
      _controller?.setZoomLevel(_currentZoomLevel);
    }
  }

  Alignment _getMapAlignment(MapPosition? position) {
    final settings = Provider.of<CameraSettings>(context, listen: false);
    switch (settings.mapPosition) {
      case MapPosition.topLeft:
        return Alignment.topLeft;
      case MapPosition.topCenter:
        return Alignment.topCenter;
      case MapPosition.topRight:
        return Alignment.topRight;
      case MapPosition.bottomLeft:
        return Alignment.bottomLeft;
      case MapPosition.bottomCenter:
        return Alignment.bottomCenter;
      case MapPosition.bottomRight:
        return Alignment.bottomRight;
      default:
        return Alignment.center; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure camera controller is initialized
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        WidgetsBinding.instance.removeObserver(this);
        await _controller?.dispose();
        await _locationSubscription?.cancel();
        _mapController.dispose();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0.01.sh),
          child: AppBar(backgroundColor: Colors.black),
        ),
        body: Column(
          children: [
            Expanded(
              child: Screenshot(
                controller: screenshotController,
                child: _controller == null || !_controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : _cameraWithOverlay(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_thumbnailImageBytes != null)
                    SizedBox(
                      height: 75,
                      width: 75,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DisplayCapturedImageScreen(imageBytes: _thumbnailImageBytes!),
                            ),
                          );
                        },
                        child: Image.memory(
                          _thumbnailImageBytes!,
                          width: 40, // Thumbnail size
                          height: 40,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      height: 75,
                      width: 75, // Ensures the layout doesn't shift if the thumbnail isn't displayed
                    ),
                  FloatingActionButton(
                    backgroundColor: Colors.black,
                    onPressed: _captureImageWithOverlay,
                    tooltip: 'Capture Image',
                    child: Icon(
                      Icons.camera,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.black,
                    onPressed: _showOptionsDialog, //_toggleOverlay,
                    tooltip: 'Toggle Overlay',
                    child: Icon(
                      Icons.settings_outlined,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
enum MapPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}
*/
class DisplayCapturedImageScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const DisplayCapturedImageScreen({super.key, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      //  appBar: AppBar(title: Text("Captured Image")),
      body: Center(
        child: Image.memory(imageBytes),
      ),
    );
  }
}
