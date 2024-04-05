// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'dart:math';

import 'package:asset_inspections/Models/rectifier_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:asset_inspections/Models/project_model.dart';
import 'package:asset_inspections/Models/ts_models.dart';

//import 'package:path/path.dart';

class MapView extends StatefulWidget {
  final int projectID;
  final List<TestStation>? testStations;
  final List<Rectifier>? rectifiers;

  const MapView({
    Key? key,
    required this.projectID,
    this.testStations,
    this.rectifiers,
  }) : super(key: key);

  static void navigateToMapView(BuildContext context, int projectID, {List<TestStation>? testStations, List<Rectifier>? rectifiers}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapView(
          projectID: projectID,
          testStations: testStations,
          rectifiers: rectifiers,
        ),
      ),
    );
  }

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Project? selectedProjectName;
  GoogleMapController? mapController;
  final Map<MarkerId, Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  MapType _currentMapType = MapType.satellite;

  bool _colorModeEnabled = false;
  bool _isCsvChecked = false;
  bool _isKmlChecked = false;

  String get hintText {
    if (widget.testStations != null && widget.testStations!.isNotEmpty) {
      return "Test Station ID";
    } else if (widget.rectifiers != null && widget.rectifiers!.isNotEmpty) {
      return "Rectifier Service Tag";
    } else {
      return "Enter ID"; // Default or fallback hint text
    }
  }

  String get title {
    if (widget.testStations != null && widget.testStations!.isNotEmpty) {
      return "Test Stations";
    } else if (widget.rectifiers != null && widget.rectifiers!.isNotEmpty) {
      return "Rectifiers";
    } else {
      return "Map"; // Default or fallback title
    }
  }

  @override
  void initState() {
    super.initState();
//    WidgetsBinding.instance.addPostFrameCallback((_) {
//      _initializeMarkers().then((_) {
//        _fitMarkers();
//      });
//    });
  }

  Future<void> _fitMarkers() async {
    if (_markers.isNotEmpty && mapController != null) {
      var minLat = double.infinity;
      var maxLat = double.negativeInfinity;
      var minLong = double.infinity;
      var maxLong = double.negativeInfinity;

      _markers.values.forEach((marker) {
        minLat = min(minLat, marker.position.latitude);
        maxLat = max(maxLat, marker.position.latitude);
        minLong = min(minLong, marker.position.longitude);
        maxLong = max(maxLong, marker.position.longitude);
      });

      // Only attempt to fit markers if valid coordinates exist
      if (minLat < double.infinity && maxLat > double.negativeInfinity && minLong < double.infinity && maxLong > double.negativeInfinity) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLong),
              northeast: LatLng(maxLat, maxLong),
            ),
            50, // Consider adjusting padding as needed
          ),
        );
      }
    }
  }

  /// Shows a dialog with export options.
  ///
  /// This method displays an [AlertDialog] with checkboxes for selecting export options such as CSV, KML, and URL.
  /// The state of the checkboxes is managed using [StatefulBuilder].
  /// The user can select the desired export options and then either cancel or export the data.
  /// If the user chooses to export the data, the [_exportData] method is called.
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(// Use StatefulBuilder to manage dialog's state
            builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Export Options',
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  CheckboxListTile(
                    title: const Text("CSV"),
                    value: _isCsvChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCsvChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("KML"),
                    value: _isKmlChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        _isKmlChecked = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Export'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _exportData();
                    },
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }

  /// Requests storage permission and exports data in CSV and KML formats.
  ///
  /// This method first checks if the storage permission is granted. If not, it requests the permission.
  /// After obtaining the permission, it exports the data in CSV format if the `_isCsvChecked` flag is true,
  /// and in KML format if the `_isKmlChecked` flag is true.
  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  /// Exports data in CSV and KML formats.
  ///
  /// This method first requests the storage permission by calling `_requestStoragePermission()`.
  /// Then, it exports the data in CSV format if the `_isCsvChecked` flag is true,
  /// and in KML format if the `_isKmlChecked` flag is true.
  void _exportData() async {
    await _requestStoragePermission();

    List<XFile> filesToShare = [];

    if (_isCsvChecked) {
      var csvFile = await _exportToCsv();
      if (csvFile != null) filesToShare.add(csvFile);
    }
    if (_isKmlChecked) {
      var kmlFile = await _exportToKml();
      if (kmlFile != null) filesToShare.add(kmlFile);
    }

    if (filesToShare.isNotEmpty) {
      Share.shareXFiles(filesToShare);
    }
  }

  String _generateFileName(String fileType) {
    final projectModel = Provider.of<ProjectModel>(context, listen: false);
    final client = projectModel.client.replaceAll(' ', '_'); // Replace spaces with underscores
    final project = projectModel.projectName.replaceAll(' ', '_'); // Replace spaces with underscores
    final date = DateTime.now().toString().split(' ')[0]; // Format: yyyy-MM-dd
    final type = (widget.testStations != null && widget.testStations!.isNotEmpty) ? "Test_Stations" : "Rectifiers";

    // Generate file name in the format: yyyy-MM-dd_client_project_type.fileType
    return "${date}_${client}_${project}_$type.$fileType";
  }

  /// Exports the markers on the map to a KML file.
  /// The KML file contains the coordinates and properties of each marker.
  /// The KML file is saved in the application documents directory as "markers.kml".
  /// The markers are represented as Placemark elements in the KML file.
  /// Each Placemark element contains the marker's name, style, and coordinates.
  /// The marker's name is the value of its markerId.
  /// The marker's style is determined by its status, which is retrieved from the markerId.
  /// The marker's coordinates are the longitude and latitude of its position.
  /// After the KML file is created, it is shared using the ShareX plugin.
  Future<XFile?> _exportToKml() async {
    String kmlData = '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<kml xmlns="http://www.opengis.net/kml/2.2">\n'
        '<Document>\n';

    for (var marker in _markers.values) {
      TestStation? station = getStatusFromMarkerId(marker.markerId);
      String pushpinUrl = _getPushpinUrl(station?.tsstatus ?? 'Unknown');

      kmlData += '<Placemark>\n'
          '<name>${marker.markerId.value}</name>\n'
          '<Style>\n'
          '<IconStyle>\n'
          '<Icon>\n'
          '<href>$pushpinUrl</href>\n'
          '</Icon>\n'
          '</IconStyle>\n'
          '</Style>\n'
          '<Point>\n'
          '<coordinates>${marker.position.longitude},${marker.position.latitude}</coordinates>\n'
          '</Point>\n'
          '</Placemark>\n';
    }

    kmlData += '</Document>\n</kml>';

    //  final projectModel = Provider.of<ProjectModel>(context, listen: false);
    //  final client = projectModel.client;
    //  final project = projectModel.projectName;
    //  final date = DateTime.now().toString().split(' ')[0];
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName('kml');
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(kmlData);

    return XFile(file.path); // Return the file instead of sharing it directly
  }

  /// Retrieves the [TestStation] object associated with the given [markerId].
  ///
  /// It searches for a [TestStation] in the [widget.testStations] list that has a matching [tsID] and [area] with the [markerId] value.
  /// If a matching [TestStation] is found, it is returned. Otherwise, it returns null.
  ///
  /// Returns:
  ///   - The matching [TestStation] object if found.
  ///   - Null if no matching [TestStation] is found.
  TestStation? getStatusFromMarkerId(MarkerId markerId) {
    var matchingStation = widget.testStations?.firstWhere(
      (station) => '${station.area} ${station.tsID}' == markerId.value,
    );

    return matchingStation;
  }

  Rectifier? getRectifierFromMarkerId(MarkerId markerId) {
    var matchingRectifier = widget.rectifiers?.firstWhere(
      (rectifier) => '${rectifier.area} ${rectifier.serviceTag}' == markerId.value,
    );

    return matchingRectifier;
  }

  /// Exports the test station data to a CSV file.
  /// The CSV file contains the test station ID, latitude, longitude, and status.
  /// Each test station is represented by a marker on the map.
  /// The marker's ID is used to retrieve the corresponding test station's status.
  /// The CSV data is written to a file named "markers.csv" in the application documents directory.
  /// Finally, the file is shared using the ShareXFiles plugin.
  Future<XFile?> _exportToCsv() async {
    String csvData = 'Test Station ID, Latitude, Longitude, Status\n';
    for (var marker in _markers.values) {
      TestStation? station = getStatusFromMarkerId(marker.markerId);
      String status = station?.tsstatus ?? 'Unknown';
      csvData += '${marker.markerId.value}, ${marker.position.latitude}, ${marker.position.longitude}, $status\n';
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName('csv');
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    return XFile(file.path); // Return the file instead of sharing it directly
  }

  /// Initializes the markers on the map based on the test stations provided.
  /// Clears the existing markers and creates new markers for each test station.
  /// Each marker represents a test station and includes information such as area, test station ID, latitude, and longitude.
  /// The marker color is determined based on the test station status and the color mode enabled.
  /// If the color mode is enabled, the marker color is determined using the [_getMarkerColor] method.
  /// If the color mode is disabled, the marker color is set to BitmapDescriptor.hueRed.
  /// The marker is added to the [_markers] map with the marker ID as the key.
  ///
  /// Returns: A [Future] that completes when the markers are initialized.
  Future<void> _initializeMarkers() async {
    _markers.clear();
    List<String> skippedLocations = []; // List to store identifiers of skipped locations

    widget.testStations?.forEach((station) {
      // Check for null or (0.0, 0.0) as invalid coordinates
      if (station.latitude == null || station.longitude == null || (station.latitude == 0.0 && station.longitude == 0.0)) {
        skippedLocations.add('${station.area} ${station.tsID}'); // Add to skipped list
        return; // Skip this iteration, don't create a marker
      }

      final markerId = MarkerId('${station.area} ${station.tsID}');
      final marker = Marker(
        markerId: markerId,
        infoWindow: InfoWindow(
          title: '${station.area} ${station.tsID}',
          snippet: 'Latitude: ${station.latitude}, Longitude: ${station.longitude}',
        ),
        position: LatLng(station.latitude!, station.longitude!),
        icon: BitmapDescriptor.defaultMarker,
      );
      _markers[markerId] = marker;
    });

    // Assuming widget.rectifiers is defined and follows a similar structure to testStations
    widget.rectifiers?.forEach((rectifier) {
      // Check for null or (0.0, 0.0) as invalid coordinates
      if (rectifier.latitude == null || rectifier.longitude == null || (rectifier.latitude == 0.0 && rectifier.longitude == 0.0)) {
        skippedLocations.add('${rectifier.area} ${rectifier.serviceTag}'); // Add to skipped list
        return; // Skip this iteration
      }

      final markerId = MarkerId('${rectifier.area} ${rectifier.serviceTag}');
      final marker = Marker(
        markerId: markerId,
        infoWindow: InfoWindow(
          title: '${rectifier.area} ${rectifier.serviceTag}',
          snippet: 'Latitude: ${rectifier.latitude}, Longitude: ${rectifier.longitude}',
        ),
        position: LatLng(rectifier.latitude!, rectifier.longitude!),
        icon: BitmapDescriptor.defaultMarker,
      );
      _markers[markerId] = marker;
      //  print('All Markers: $_markers');
      //  print('Single Marker: $marker');
    });
    if (kDebugMode) {
      if (kDebugMode) {
        print('All Markers: $_markers');
      }
    }
    if (skippedLocations.isNotEmpty) {
      _showSkippedLocationsDialog(skippedLocations); // Inform the user
    }
  }

  void _showSkippedLocationsDialog(List<String> skippedLocations) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Some Locations Not Displayed"),
            content: SingleChildScrollView(
              child: ListBody(
                children: skippedLocations.map((location) => Text(location)).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  /// Returns the URL of a pushpin image based on the given status.
  ///
  /// The [status] parameter represents the status of the pushpin and can have the following values:
  /// - 'Pass': Returns the URL for a green pushpin image.
  /// - 'Attention': Returns the URL for a yellow pushpin image.
  /// - 'Issue': Returns the URL for a red pushpin image.
  /// - 'Unchecked': Returns the URL for a white pushpin image.
  ///
  /// If the [status] is not one of the above values, the function returns the URL for a white pushpin image.
  String _getPushpinUrl(String status) {
    switch (status) {
      case 'Pass':
        return 'https://maps.google.com/mapfiles/kml/pushpin/grn-pushpin.png';
      case 'Attention':
        return 'https://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png';
      case 'Issue':
        return 'https://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png';
      case 'Unchecked':
      //  return 'https://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png';
      default:
        return 'https://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png';
    }
  }

  /// Returns the marker color based on the given status.
  ///
  /// The [status] parameter represents the status of the marker.
  /// Possible values for [status] are:
  /// - 'Pass': Returns the green marker color.
  /// - 'Attention': Returns the yellow marker color.
  /// - 'Issue': Returns the red marker color.
  /// - 'Unchecked': Returns the azure marker color.
  /// If the [status] is not one of the above values, the default red marker color is returned.
  double _getMarkerColor(String status) {
    switch (status) {
      case 'Pass':
        return BitmapDescriptor.hueGreen;
      case 'Attention':
        return BitmapDescriptor.hueYellow;
      case 'Issue':
        return BitmapDescriptor.hueRed;
      case 'Unchecked':
        return BitmapDescriptor.hueAzure;
      default:
        return BitmapDescriptor.hueRed; // Default color
    }
  }

  /// Toggles the color mode and updates the markers on the map.
  void _toggleColorMode() {
    setState(() {
      _colorModeEnabled = !_colorModeEnabled;
      _initializeMarkers();
    });
  }

  /// Callback function when the map is created.
  ///
  /// [controller] The GoogleMapController instance.
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitMarkers();
    _showInfoWindows(); // Now safe to call
  }

  /// Shows info windows for all markers on the map.
  Future<void> _showInfoWindows() async {
    if (mapController != null) {
      for (var markerId in _markers.keys) {
        await mapController!.showMarkerInfoWindow(markerId);
      }
    }
  }

  /// Moves the camera to the marker associated with the provided search ID.
  ///
  /// The search ID is obtained from the [_searchController] text field.
  /// It searches for the marker ID in the [_markers] map and if found,
  /// animates the camera to the marker's position and shows its info window.
  ///
  /// If the marker is not found or the [mapController] is null, no action is taken.
  void _moveToSearch() async {
    String searchId = _searchController.text.toLowerCase();
    MarkerId? foundMarkerId;

    // Search for a marker ID that contains the search text
    for (var markerId in _markers.keys) {
      if (markerId.value.toLowerCase().contains(searchId)) {
        foundMarkerId = markerId;
        break; // Break after finding the first match
      }
    }

    // Move to the marker if found
    if (foundMarkerId != null && mapController != null) {
      final Marker marker = _markers[foundMarkerId]!;
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: marker.position,
            zoom: 15.0, // Adjust zoom level as needed
          ),
        ),
      );
      await mapController!.showMarkerInfoWindow(foundMarkerId);
    } else {
      // Consider providing feedback if no marker is found
    }
  }

  /// Cycles through the map types and updates the current map type.
  void _cycleMapType() {
    setState(() {
      // Cycle through the map types
      _currentMapType = MapType.values[(MapType.values.indexOf(_currentMapType) + 1) % MapType.values.length];
    });
  }

  /// Builds the map view screen.
  ///
  /// This method returns a [Scaffold] widget that contains a [GoogleMap] widget
  /// along with other UI elements such as a search bar, map type toggle button,
  /// color mode toggle button, and export button.
  ///
  /// The [GoogleMap] widget is initialized with markers based on the test stations
  /// provided in the `widget.testStations` list. The initial camera position is set
  /// to the latitude and longitude of the first test station in the list.
  ///
  /// The UI elements are positioned using the [Positioned] widget and adjusted
  /// based on the device's screen size and padding.
  ///
  /// The UI elements have various functionalities such as searching for test stations,
  /// toggling between different map types, toggling color modes, and exporting the map.
  ///
  /// The UI is wrapped in a [FutureBuilder] widget to handle the asynchronous
  /// initialization of the markers. While the markers are being initialized,
  /// a circular progress indicator is displayed. Once the markers are initialized,
  /// the map view along with the UI elements is displayed.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeMarkers().then((_) {
          _fitMarkers();
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  mapType: _currentMapType,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(widget.testStations?[0].latitude ?? 00.000000, widget.testStations?[0].longitude ?? 00.000000),
                    zoom: 11.0,
                  ),
                  markers: Set<Marker>.of(_markers.values),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 30, // Adjust the position as needed
                  left: MediaQuery.of(context).size.width * 0.1, // For horizontal padding
                  right: MediaQuery.of(context).size.width * 0.1,
                  child: Container(
                    // padding: EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(150, 255, 255, 255),
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
                    child: TextField(
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      controller: _searchController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                        prefixIcon: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.asset(
                              'assets/images/corrorecordicon.png',
                              height: 15,
                              width: 45,
                              alignment: AlignmentDirectional.centerStart,
                            )),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _moveToSearch,
                        ),
                      ),
                      onSubmitted: (value) {
                        _moveToSearch();
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 120, // Adjust the position as needed
                  right: MediaQuery.of(context).size.width * 0.05, // For horizontal padding
                  child: Container(
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
                      icon: const Icon(Icons.layers),
                      onPressed: _cycleMapType,
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 180, // Adjust the position as needed
                  right: MediaQuery.of(context).size.width * 0.05, // For horizontal padding
                  child: Container(
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
                      icon: const Icon(Icons.palette),
                      onPressed: _toggleColorMode,
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 240, // Adjust the position as needed
                  right: MediaQuery.of(context).size.width * 0.05, // For horizontal padding
                  child: Container(
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
                      icon: const Icon(Icons.share),
                      onPressed: _showExportDialog,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
