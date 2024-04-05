import 'package:asset_inspections/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

enum MapPosition { topLeft, topCenter, topRight, bottomLeft, bottomCenter, bottomRight }

class CameraSettings extends ChangeNotifier {
  int? id;
  bool _isMapOverlayVisible;
  MapPosition? _mapPosition;
  MapPosition? _dataPosition;
  String _mapType;
  double _mapOpacity;
  double _mapSize;
  double _mapScale;
  bool _isDataOverlayVisible;
  String _selectedFontStyle;
  String _selectedFontColor;
  double _selectedFontSize;
  String _selectedDateFormat;
  String _selectedLocationFormat;
  List<String> _dataDisplayOrder = ['date', 'address'];

  CameraSettings({
    this.id,
    bool isMapOverlayVisible = true,
    MapPosition? mapPosition = MapPosition.bottomLeft,
    MapPosition? dataPosition = MapPosition.bottomRight,
    String mapType = 'Normal',
    double mapOpacity = 1.0,
    double mapSize = 150.0,
    double mapScale = 14.0,
    bool isDataOverlayVisible = true,
    String selectedFontStyle = 'Normal',
    String selectedFontColor = 'Black',
    double selectedFontSize = 12.0,
    String selectedDateFormat = 'yyyy-MM-dd',
    String selectedLocationFormat = 'Country',
    List<String> dataDisplayOrder = const ['date', 'address'],
  })  : _isMapOverlayVisible = isMapOverlayVisible,
        _mapPosition = mapPosition,
        _dataPosition = dataPosition,
        _mapType = mapType,
        _mapOpacity = mapOpacity,
        _mapSize = mapSize,
        _mapScale = mapScale,
        _isDataOverlayVisible = isDataOverlayVisible,
        _selectedFontStyle = selectedFontStyle,
        _selectedFontColor = selectedFontColor,
        _selectedFontSize = selectedFontSize,
        _selectedDateFormat = selectedDateFormat,
        _selectedLocationFormat = selectedLocationFormat,
        _dataDisplayOrder = dataDisplayOrder;

  // Getters
  bool get isMapOverlayVisible => _isMapOverlayVisible;
  MapPosition? get mapPosition => _mapPosition;
  MapPosition? get dataPosition => _dataPosition;
  String get mapType => _mapType;
  double get mapOpacity => _mapOpacity;
  double get mapSize => _mapSize;
  double get mapScale => _mapScale;
  bool get isDataOverlayVisible => _isDataOverlayVisible;
  String get selectedFontStyle => _selectedFontStyle;
  String get selectedFontColor => _selectedFontColor;
  double get selectedFontSize => _selectedFontSize;
  String get selectedDateFormat => _selectedDateFormat;
  String get selectedLocationFormat => _selectedLocationFormat;
  List<String> get dataDisplayOrder => _dataDisplayOrder;

  // Setters
  set isMapOverlayVisible(bool value) {
    if (_isMapOverlayVisible != value) {
      _isMapOverlayVisible = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set mapPosition(MapPosition? value) {
    if (_mapPosition != value) {
      _mapPosition = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set dataPosition(MapPosition? value) {
    if (_dataPosition != value) {
      _dataPosition = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set mapType(String value) {
    if (_mapType != value) {
      _mapType = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set mapOpacity(double value) {
    if (_mapOpacity != value) {
      _mapOpacity = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set mapSize(double value) {
    if (_mapSize != value) {
      _mapSize = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set mapScale(double value) {
    if (_mapScale != value) {
      _mapScale = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set isDataOverlayVisible(bool value) {
    if (_isDataOverlayVisible != value) {
      _isDataOverlayVisible = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set selectedFontStyle(String value) {
    if (_selectedFontStyle != value) {
      _selectedFontStyle = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set selectedFontColor(String value) {
    if (_selectedFontColor != value) {
      _selectedFontColor = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set selectedFontSize(double value) {
    if (_selectedFontSize != value) {
      _selectedFontSize = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set selectedDateFormat(String value) {
    if (_selectedDateFormat != value) {
      _selectedDateFormat = value;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set selectedLocationFormat(String newValue) {
    if (_selectedLocationFormat != newValue) {
      _selectedLocationFormat = newValue;
      notifyListeners();
      updateCameraSettingsToDatabase();
    }
  }

  set displayOrder(List<String> newOrder) {
    _dataDisplayOrder = newOrder;
    notifyListeners();
    updateCameraSettingsToDatabase();
  }

  // Method to update the map position
  void updateMapPosition(MapPosition? position) {
    _mapPosition = position;
    notifyListeners();
  }

  // Method to update the data position
  void updateDataPosition(MapPosition? position) {
    _dataPosition = position;
    notifyListeners();
  }

  // Method to update the map type
  void updateMapType(String type) {
    _mapType = type;
    notifyListeners();
  }

  // Method to update the map opacity
  void updateMapOpacity(double opacity) {
    _mapOpacity = opacity;
    notifyListeners();
  }

  // Method to update the map size
  void updateMapSize(double size) {
    _mapSize = size;
    notifyListeners();
  }

  // Method to update the map scale
  void updateMapScale(double scale) {
    _mapScale = scale;
    notifyListeners();
  }

  // Method to update the font style
  void updateFontStyle(String style) {
    _selectedFontStyle = style;
    notifyListeners();
  }

  // Method to update the font color
  void updateFontColor(String color) {
    _selectedFontColor = color;
    notifyListeners();
  }

  // Method to update the font size
  void updateFontSize(double size) {
    _selectedFontSize = size;
    notifyListeners();
  }

  // Method to update the date format
  void updateDateFormat(String format) {
    _selectedDateFormat = format;
    notifyListeners();
  }

  // Method to update the location format
  void updateLocationFormat(String format) {
    _selectedLocationFormat = format;
    notifyListeners();
  }

  // Method to update the map overlay visibility
  void updateMapOverlayVisibility(bool value) {
    _isMapOverlayVisible = value;
    notifyListeners();
  }

  // Method to update the data overlay visibility
  void updateDataOverlayVisibility(bool value) {
    _isDataOverlayVisible = value;
    notifyListeners();
  }

  void updateDisplayOrder(List<String> newOrder) {
    _dataDisplayOrder = newOrder;
    notifyListeners(); // Notify any listening widgets to rebuild
    updateCameraSettingsToDatabase(); // Save the new order to the database, if applicable
  }

  static final List<String> mapTypeOptions = ['Normal', 'Satellite', 'Terrain', 'Hybrid'];
  static final List<Map<String, dynamic>> fontStyleOptions = [
    {'style': 'Normal', 'weight': FontWeight.normal, 'fontStyle': FontStyle.normal},
    {'style': 'Bold', 'weight': FontWeight.bold, 'fontStyle': FontStyle.normal},
    {'style': 'Italic', 'weight': FontWeight.normal, 'fontStyle': FontStyle.italic},
  ];
  static final List<String> fontColors = ['Black', 'White', 'Red', 'Green', 'Blue'];
  static final List<double> fontSizes = [12.0, 14.0, 16.0, 18.0, 20.0];
  static final List<String> dateFormats = [
    'None',
    'yyyy-MM-dd', // ISO 8601 Date
    'dd-MM-yyyy',
    'MM-dd-yyyy',
    'yyyy/MM/dd',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy.MM.dd',
    'dd.MM.yyyy',
    'MM.dd.yyyy',
    'EEE, MMM d, '
        'yy', // Tue, Jul 4, '23
    'EEEE, MMMM d, yyyy', // Tuesday, July 4, 2023
    'yyyy-MM-dd HH:mm:ss', // 24-hour format
    'yyyy-MM-dd hh:mm:ss a', // 12-hour format with AM/PM
    'yyyy-MM-dd HH:mm:ss.SSS', // With milliseconds
    'yyyy-MM-dd HH:mm:ss Z', // With timezone offset
    'yyyy-MM-dd HH:mm:ss zzzz', // With timezone name
    'HH:mm:ss', // Only time in 24-hour format
    'hh:mm:ss a', // Only time in 12-hour format with AM/PM
    'HH:mm', // 24-hour format without seconds
    'hh:mm a', // 12-hour format without seconds
    'MMM d, y', // Jul 4, 2023
    'MMMM d, y', // July 4, 2023
    'MMM dd, yyyy HH:mm', // Jul 04, 2023 15:00
    'dd/MM/yy HH:mm:ss', // 04/07/23 15:00:00
    'EEE, d MMM yyyy HH:mm:ss Z', // RFC 822 - Tue, 4 Jul 2023 15:00:00 -0700
    'yyyy-MM-dd'
        'T'
        'HH:mm:ss'
        'Z'
        '', // ISO 8601 Date and time in UTC - 2023-07-04T15:00:00Z
  ];

  static final List<String> locationFormats = [
    'None',
    'Country',
    'State',
    'County',
    'City',
    'Road Name',
    'Building Number, Street Name',
    'Building Number',
    'Street Address, City, State, Zip',
    'Street Address, City, County, Zip, Country',
    'Street Name, City, County, Zip',
    'City, County, Zip, Country',
    'Street Address, City',
    'Street Address, City, County',
  ];

  // Method to convert AppSettings to Map<String, dynamic> for database operations
  Map<String, dynamic> toMap() {
    return {
      'isMapOverlayVisible': isMapOverlayVisible ? 1 : 0, // SQLite doesn't have boolean type
      'mapPosition': mapPosition?.index,
      'dataPosition': dataPosition?.index,
      'mapType': mapType,
      'mapOpacity': mapOpacity,
      'mapSize': mapSize,
      'mapScale': mapScale,
      'isDataOverlayVisible': isDataOverlayVisible ? 1 : 0,
      'selectedFontStyle': selectedFontStyle,
      'selectedFontColor': selectedFontColor,
      'selectedFontSize': selectedFontSize,
      'selectedDateFormat': selectedDateFormat,
      'selectedLocationFormat': selectedLocationFormat,
      'dataDisplayOrder': json.encode(_dataDisplayOrder),
    };
  }

  // Method to create an AppSettings object from a Map<String, dynamic>
  static CameraSettings fromMap(Map<String, dynamic> map) {
    // This assumes 'dataDisplayOrder' is a JSON-encoded string of a list
    List<String> decodedOrder = [];
    try {
      decodedOrder = List<String>.from(json.decode(map['dataDisplayOrder']));
    } catch (e) {
      if (kDebugMode) {
        print("Error decoding dataDisplayOrder: $e");
      }
      // Handle or log error as appropriate
    }
    return CameraSettings(
      isMapOverlayVisible: map['isMapOverlayVisible'] == 1,
      mapPosition: MapPosition.values[map['mapPosition']],
      dataPosition: MapPosition.values[map['dataPosition']],
      mapType: map['mapType'],
      mapOpacity: map['mapOpacity'],
      mapSize: map['mapSize'],
      mapScale: map['mapScale'],
      isDataOverlayVisible: map['isDataOverlayVisible'] == 1,
      selectedFontStyle: map['selectedFontStyle'],
      selectedFontColor: map['selectedFontColor'],
      selectedFontSize: map['selectedFontSize'],
      selectedDateFormat: map['selectedDateFormat'],
      selectedLocationFormat: map['selectedLocationFormat'],
      dataDisplayOrder: decodedOrder,
    );
  }

  Future<void> loadCameraSettingsFromDatabase() async {
    // Implement loading logic here
    var loadedSettings = await DatabaseHelper.instance.getCameraSettings();
    if (loadedSettings != null) {
      _isMapOverlayVisible = loadedSettings.isMapOverlayVisible;
      _mapPosition = loadedSettings.mapPosition;
      _dataPosition = loadedSettings.dataPosition;
      _mapType = loadedSettings.mapType;
      _mapOpacity = loadedSettings.mapOpacity;
      _mapSize = loadedSettings.mapSize;
      _mapScale = loadedSettings.mapScale;
      _isDataOverlayVisible = loadedSettings.isDataOverlayVisible;
      _selectedFontStyle = loadedSettings.selectedFontStyle;
      _selectedFontColor = loadedSettings.selectedFontColor;
      _selectedFontSize = loadedSettings.selectedFontSize;
      _selectedDateFormat = loadedSettings.selectedDateFormat;
      _selectedLocationFormat = loadedSettings.selectedLocationFormat;
      _dataDisplayOrder = loadedSettings.dataDisplayOrder;
      notifyListeners(); // Notify listeners about the updated settings
    }
  }

  Future<void> updateCameraSettingsToDatabase() async {
    var cameraSettings = toMap();
    await DatabaseHelper.instance.updateCameraSettings(cameraSettings);
  }
}
