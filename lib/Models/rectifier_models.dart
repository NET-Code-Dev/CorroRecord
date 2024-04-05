import 'package:flutter/material.dart';

/// Represents a rectifier device.
class Rectifier {
  int projectID;
  String? area;
  String serviceTag;
  String? use;
  String status;
  double? maxVoltage;
  double? maxAmps;
  double? latitude;
  double? longitude;
  RectifierReadings? readings;
  TapReadings? tapReadings;
  RectifierInspection? inspection;

  static final Map<String, Rectifier> _cache = {};

  /// Constructs a [Rectifier] object.
  Rectifier({
    required this.projectID,
    required this.area,
    required this.serviceTag,
    this.use,
    required this.status,
    required this.maxVoltage,
    required this.maxAmps,
    required this.latitude,
    required this.longitude,
    this.readings,
    this.tapReadings,
    this.inspection,
  });

  /// Constructs a [Rectifier] object from a map.
  factory Rectifier.fromMap(Map<String, dynamic> map) {
    if (_cache.containsKey(map['serviceTag'])) {
      Rectifier cachedInstance = _cache[map['serviceTag']]!;
      // Update the properties of the cached instance
      cachedInstance.projectID = map['projectID'] as int;
      cachedInstance.area = map['area'] as String?;
      cachedInstance.serviceTag = map['serviceTag'] as String;
      cachedInstance.use = map['use'] as String?;
      cachedInstance.status = map['status'] as String;
      cachedInstance.maxVoltage = map['maxVoltage'] as double?;
      cachedInstance.maxAmps = map['maxAmps'] as double?;
      cachedInstance.latitude = map['latitude'] as double?;
      cachedInstance.longitude = map['longitude'] as double?;
      cachedInstance.readings = RectifierReadings(
        panelMeterVoltage: map['panelMeterVoltage'] as double?,
        multimeterVoltage: map['multimeterVoltage'] as double?,
        voltageReadingComments: map['voltageReadingComments'] as String?,
        panelMeterAmps: map['panelMeterAmps'] as double?,
        ammeterAmps: map['ammeterAmps'] as double?,
        currentReadingComments: map['currentReadingComments'] as String?,
        currentRatio: map['currentRatio'] as double?,
        voltageRatio: map['voltageRatio'] as double?,
        voltageDrop: map['voltageDrop'] as double?,
        calculatedCurrent: map['calculatedCurrent'] as double?,
      );
      cachedInstance.tapReadings = TapReadings(
        courseTapSettingFound: map['courseTapSettingFound'] as String?,
        mediumTapSettingFound: map['mediumTapSettingFound'] as String?,
        fineTapSettingFound: map['fineTapSettingFound'] as String?,
      );
      cachedInstance.inspection = RectifierInspection(
        reason: (map['reason'] as String?),
        deviceDamage: (map['deviceDamage'] as int?),
        deviceDamageFindings: (map['deviceDamageFindings'] as String?),
        deviceDamageComments: (map['deviceDamageComments'] as String?),
        polarityCondition: (map['polarityCondition'] as int?),
        oilLevel: (map['oilLevel'] as int?),
        oilLevelFindings: (map['oilLevelFindings'] as String?),
        oilLevelComments: (map['oilLevelComments'] as String?),
        circuitBreakers: (map['circuitBreakers'] as int?),
        circuitBreakersComments: (map['circuitBreakersComments'] as String?),
        fusesWiring: (map['fusesWiring'] as int?),
        fusesWiringComments: (map['fusesWiringComments'] as String?),
        lightningArrestors: (map['lightningArrestors'] as int?),
        lightningArrestorsComments: (map['lightningArrestorsComments'] as String?),
        ventScreens: (map['ventScreens'] as int?),
        ventScreensComments: (map['ventScreensComments'] as String?),
        breathers: (map['breathers'] as int?),
        breathersComments: (map['breathersComments'] as String?),
        removeObstructions: (map['removeObstructions'] as int?),
        removeObstructionsComments: (map['removeObstructionsComments'] as String?),
        cleaned: (map['cleaned'] as int?),
        cleanedComments: (map['cleanedComments'] as String?),
        tightened: (map['tightened'] as int?),
        tightenedComments: (map['tightenedComments'] as String?),
        polarityConditionComments: (map['polarityConditionComments'] as String?),
      );

      return cachedInstance;
    } else {
      Rectifier newInstance = Rectifier(
        projectID: map['projectID'] as int,
        area: map['area'] as String?,
        serviceTag: map['serviceTag'] as String,
        use: map['use'] as String?,
        status: map['status'] as String,
        maxVoltage: map['maxVoltage'] as double?,
        maxAmps: map['maxAmps'] as double?,
        latitude: map['latitude'] as double?,
        longitude: map['longitude'] as double?,
        readings: RectifierReadings(
          panelMeterVoltage: map['panelMeterVoltage'] as double?,
          multimeterVoltage: map['multimeterVoltage'] as double?,
          voltageReadingComments: map['voltageReadingComments'] as String?,
          panelMeterAmps: map['panelMeterAmps'] as double?,
          ammeterAmps: map['ammeterAmps'] as double?,
          currentReadingComments: map['currentReadingComments'] as String?,
          currentRatio: map['currentRatio'] as double?,
          voltageRatio: map['voltageRatio'] as double?,
          voltageDrop: map['voltageDrop'] as double?,
          calculatedCurrent: map['calculatedCurrent'] as double?,
        ),
        tapReadings: TapReadings(
          courseTapSettingFound: map['courseTapSettingFound'] as String?,
          mediumTapSettingFound: map['mediumTapSettingFound'] as String?,
          fineTapSettingFound: map['fineTapSettingFound'] as String?,
        ),
        inspection: RectifierInspection(
          reason: (map['reason'] as String?),
          deviceDamage: (map['deviceDamage'] as int?),
          deviceDamageFindings: (map['deviceDamageFindings'] as String?),
          deviceDamageComments: (map['deviceDamageComments'] as String?),
          polarityCondition: (map['polarityCondition'] as int?),
          oilLevel: (map['oilLevel'] as int?),
          oilLevelFindings: (map['oilLevelFindings'] as String?),
          oilLevelComments: (map['oilLevelComments'] as String?),
          circuitBreakers: (map['circuitBreakers'] as int?),
          circuitBreakersComments: (map['circuitBreakersComments'] as String?),
          fusesWiring: (map['fusesWiring'] as int?),
          fusesWiringComments: (map['fusesWiringComments'] as String?),
          lightningArrestors: (map['lightningArrestors'] as int?),
          lightningArrestorsComments: (map['lightningArrestorsComments'] as String?),
          ventScreens: (map['ventScreens'] as int?),
          ventScreensComments: (map['ventScreensComments'] as String?),
          breathers: (map['breathers'] as int?),
          breathersComments: (map['breathersComments'] as String?),
          removeObstructions: (map['removeObstructions'] as int?),
          removeObstructionsComments: (map['removeObstructionsComments'] as String?),
          cleaned: (map['cleaned'] as int?),
          cleanedComments: (map['cleanedComments'] as String?),
          tightened: (map['tightened'] as int?),
          tightenedComments: (map['tightenedComments'] as String?),
          polarityConditionComments: (map['polarityConditionComments'] as String?),
        ),
      );

      _cache[map['serviceTag']] = newInstance;
      return newInstance;
    }
  }

  /// Converts the [Rectifier] object to a map.
  Map<String, dynamic> toMap() {
    return {
      'projectID': projectID,
      'area': area,
      'serviceTag': serviceTag,
      'use': use,
      'status': status,
      'maxVoltage': maxVoltage,
      'maxAmps': maxAmps,
      'latitude': latitude,
      'longitude': longitude,
      // Flattening the readings object
      'panelMeterVoltage': readings?.panelMeterVoltage,
      'multimeterVoltage': readings?.multimeterVoltage,
      'voltageReadingComments': readings?.voltageReadingComments,
      'panelMeterAmps': readings?.panelMeterAmps,
      'ammeterAmps': readings?.ammeterAmps,
      'currentReadingComments': readings?.currentReadingComments,
      'currentRatio': readings?.currentRatio,
      'voltageRatio': readings?.voltageRatio,
      'voltageDrop': readings?.voltageDrop,
      'calculatedCurrent': readings?.calculatedCurrent,
      // Flattening the tapReadings object
      'courseTapSettingFound': tapReadings?.courseTapSettingFound,
      'mediumTapSettingFound': tapReadings?.mediumTapSettingFound,
      'fineTapSettingFound': tapReadings?.fineTapSettingFound,
      // Flattening the inspection object
      'reason': inspection?.reason,
      'oilLevel': inspection?.oilLevel,
      'oilLevelComments': inspection?.oilLevelComments,
      'oilLevelFindings': inspection?.oilLevelFindings,
      'deviceDamage': inspection?.deviceDamage,
      'deviceDamageComments': inspection?.deviceDamageComments,
      'deviceDamageFindings': inspection?.deviceDamageFindings,
      'polarityCondition': inspection?.polarityCondition,
      'polarityConditionComments': inspection?.polarityConditionComments,
      'circuitBreakers': inspection?.circuitBreakers,
      'circuitBreakersComments': inspection?.circuitBreakersComments,
      'fusesWiring': inspection?.fusesWiring,
      'fusesWiringComments': inspection?.fusesWiringComments,
      'lightningArrestors': inspection?.lightningArrestors,
      'lightningArrestorsComments': inspection?.lightningArrestorsComments,
      'ventScreens': inspection?.ventScreens,
      'ventScreensComments': inspection?.ventScreensComments,
      'breathers': inspection?.breathers,
      'breathersComments': inspection?.breathersComments,
      'removeObstructions': inspection?.removeObstructions,
      'removeObstructionsComments': inspection?.removeObstructionsComments,
      'cleaned': inspection?.cleaned,
      'cleanedComments': inspection?.cleanedComments,
      'tightened': inspection?.tightened,
      'tightenedComments': inspection?.tightenedComments,
    };
  }

  /// Creates a copy of the [Rectifier] object with optional property overrides.
  Rectifier copyWith(
      {String? status,
      RectifierInspection? inspection,
      String? area,
      String? serviceTag,
      String? use,
      double? maxVoltage,
      double? maxAmps,
      double? latitude,
      double? longitude,
      RectifierReadings? readings,
      TapReadings? tapReadings}) {
    return Rectifier(
      projectID: projectID,
      area: area ?? this.area,
      serviceTag: serviceTag ?? this.serviceTag,
      use: use ?? this.use,
      status: status ?? this.status,
      maxVoltage: maxVoltage ?? this.maxVoltage,
      maxAmps: maxAmps ?? this.maxAmps,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      readings: readings ?? this.readings,
      tapReadings: tapReadings ?? this.tapReadings,
      inspection: inspection ?? this.inspection,
    );
  }

  /// Returns the color associated with the status of the rectifier.
  Color getStatusColor() {
    switch (status) {
      case 'Pass':
        return Colors.green;
      case 'Attention':
        return Colors.yellow;
      case 'Issue':
        return Colors.red;
      case 'Unchecked':
      default:
        return Colors.grey; // Default color if status is unknown
    }
  }

  /// Updates the status of the rectifier.
  void updateStatus(String newStatus) {
    status = newStatus;
  }
}

/// Represents the readings of a rectifier.
class RectifierReadings {
  final double? panelMeterVoltage;
  final double? multimeterVoltage;
  final String? voltageReadingComments;
  final double? panelMeterAmps;
  final double? ammeterAmps;
  final String? currentReadingComments;
  final double? currentRatio;
  final double? voltageRatio;
  final double? voltageDrop;
  final double? calculatedCurrent;

  RectifierReadings({
    required this.panelMeterVoltage,
    required this.multimeterVoltage,
    required this.voltageReadingComments,
    required this.panelMeterAmps,
    required this.ammeterAmps,
    required this.currentReadingComments,
    required this.currentRatio,
    required this.voltageRatio,
    required this.voltageDrop,
    required this.calculatedCurrent,
  });
}

/// Represents the tap readings of a rectifier.
class TapReadings {
  /// The course tap setting found.
  final String? courseTapSettingFound;

  /// The medium tap setting found.
  final String? mediumTapSettingFound;

  /// The fine tap setting found.
  final String? fineTapSettingFound;

  /// Creates a new instance of [TapReadings].
  TapReadings({
    required this.courseTapSettingFound,
    required this.mediumTapSettingFound,
    required this.fineTapSettingFound,
  });
}

/// Represents a rectifier inspection.
class RectifierInspection {
  String? reason;
  int? deviceDamage;
  int? polarityCondition;
  int? oilLevel;
  int? circuitBreakers;
  int? fusesWiring;
  int? lightningArrestors;
  int? ventScreens;
  int? breathers;
  int? removeObstructions;
  int? cleaned;
  int? tightened;
  String? oilLevelFindings;
  String? oilLevelComments;
  String? deviceDamageFindings;
  String? deviceDamageComments;
  String? circuitBreakersComments;
  String? fusesWiringComments;
  String? lightningArrestorsComments;
  String? ventScreensComments;
  String? breathersComments;
  String? removeObstructionsComments;
  String? cleanedComments;
  String? tightenedComments;
  String? polarityConditionComments;

  /// Creates a new instance of [RectifierInspection].
  RectifierInspection({
    required this.reason,
    required this.deviceDamage,
    required this.polarityCondition,
    required this.polarityConditionComments,
    required this.oilLevel,
    required this.circuitBreakers,
    required this.fusesWiring,
    required this.lightningArrestors,
    required this.ventScreens,
    required this.breathers,
    required this.removeObstructions,
    required this.cleaned,
    required this.tightened,
    required this.oilLevelFindings,
    required this.oilLevelComments,
    required this.deviceDamageFindings,
    required this.deviceDamageComments,
    required this.circuitBreakersComments,
    required this.fusesWiringComments,
    required this.lightningArrestorsComments,
    required this.ventScreensComments,
    required this.breathersComments,
    required this.removeObstructionsComments,
    required this.cleanedComments,
    required this.tightenedComments,
  });
}
