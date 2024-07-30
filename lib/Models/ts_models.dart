//import 'package:asset_inspections/Models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Represents a test station.
class TestStation {
  int? id;
  int projectID;
  String? area;
  String tsID;
  String tsstatus;
  double? latitude;
  double? longitude;
  String? officeNotes;
  String? fieldNotes;
  String? picturePath;
  List<PLTestLeadReading>? plTestLeadReadings;
  List<PermRefReading>? permRefReadings;
  List<AnodeReading>? anodeReadings;
  List<ShuntReading>? shuntReadings;
  List<RiserReading>? riserReadings;
  List<ForeignReading>? foreignReadings;
  List<TestLeadReading>? testLeadReadings;
  List<CouponReading>? couponReadings;
  List<BondReading>? bondReadings;
  List<IsolationReading>? isolationReadings;

  static final Map<int, TestStation> _cache = {};

  /// Creates a new instance of [TestStation].
  TestStation({
    this.id,
    required this.projectID,
    required this.area,
    required this.tsID,
    required this.tsstatus,
    this.latitude,
    this.longitude,
    this.officeNotes,
    this.fieldNotes,
    this.picturePath,
    this.plTestLeadReadings,
    this.permRefReadings,
    this.anodeReadings,
    this.shuntReadings,
    this.riserReadings,
    this.foreignReadings,
    this.testLeadReadings,
    this.couponReadings,
    this.bondReadings,
    this.isolationReadings,
  });

  /// Creates a new instance of [TestStation] from a map.
  factory TestStation.fromMap(Map<String, dynamic> map) {
/*    
    List<PLTestLeadReading>? plTestLeadReadings;
    if (map['plTestLeadReadings'] != null) {
      var readingList = List.from(map['plTestLeadReadings']);
      plTestLeadReadings = readingList.map((readingMap) {
        return PLTestLeadReading.fromMap(readingMap);
      }).toList();
    }

    List<PermRefReading>? permRefReadings;
    if (map['permRefReadings'] != null) {
      var readingList = List.from(map['permRefReadings']);
      permRefReadings = readingList.map((readingMap) {
        return PermRefReading.fromMap(readingMap);
      }).toList();
    }

    List<AnodeReading>? anodeReadings;
    if (map['anodeReadings'] != null) {
      var readingList = List.from(map['anodeReadings']);
      anodeReadings = readingList.map((readingMap) {
        return AnodeReading.fromMap(readingMap);
      }).toList();
    }

    List<ShuntReading>? shuntReadings;
    if (map['shuntReadings'] != null) {
      var readingList = List.from(map['shuntReadings']);
      shuntReadings = readingList.map((readingMap) {
        return ShuntReading.fromMap(readingMap);
      }).toList();
    }

    List<RiserReading>? riserReadings;
    if (map['riserReadings'] != null) {
      var readingList = List.from(map['riserReadings']);
      riserReadings = readingList.map((readingMap) {
        return RiserReading.fromMap(readingMap);
      }).toList();
    }

    List<ForeignReading>? foreignReadings;
    if (map['foreignReadings'] != null) {
      var readingList = List.from(map['foreignReadings']);
      foreignReadings = readingList.map((readingMap) {
        return ForeignReading.fromMap(readingMap);
      }).toList();
    }

    List<TestLeadReading>? testLeadReadings;
    if (map['testLeadReadings'] != null) {
      var readingList = List.from(map['testLeadReadings']);
      testLeadReadings = readingList.map((readingMap) {
        return TestLeadReading.fromMap(readingMap);
      }).toList();
    }

    List<CouponReading>? couponReadings;
    if (map['couponReadings'] != null) {
      var readingList = List.from(map['couponReadings']);
      couponReadings = readingList.map((readingMap) {
        return CouponReading.fromMap(readingMap);
      }).toList();
    }

    List<BondReading>? bondReadings;
    if (map['bondReadings'] != null) {
      var readingList = List.from(map['bondReadings']);
      bondReadings = readingList.map((readingMap) {
        return BondReading.fromMap(readingMap);
      }).toList();
    }

    List<IsolationReading>? isolationReadings;
    if (map['isolationReadings'] != null) {
      var readingList = List.from(map['isolationReadings']);
      isolationReadings = readingList.map((readingMap) {
        return IsolationReading.fromMap(readingMap);
      }).toList();
    }
*/
    return _cache.putIfAbsent(
        map['id'] as int,
        () => TestStation(
              id: map['id'] as int,
              projectID: map['projectID'] as int,
              area: map['area'] as String?,
              tsID: map['tsID'] as String,
              tsstatus: map['status'] as String,
              latitude: map['latitude'] as double?,
              longitude: map['longitude'] as double?,
              officeNotes: map['officeNotes'] as String?,
              fieldNotes: map['fieldNotes'] as String?,
              picturePath: map['picturePath'] as String?,
              plTestLeadReadings: null,
              permRefReadings: null,
              anodeReadings: null,
              shuntReadings: null,
              riserReadings: null,
              foreignReadings: null,
              testLeadReadings: null,
              couponReadings: null,
              bondReadings: null,
              isolationReadings: null,

/*
              plTestLeadReadings: plTestLeadReadings,
              permRefReadings: permRefReadings,
              anodeReadings: anodeReadings,
              shuntReadings: shuntReadings,
              riserReadings: riserReadings,
              foreignReadings: foreignReadings,
              testLeadReadings: testLeadReadings,
              couponReadings: couponReadings,
              bondReadings: bondReadings,
              isolationReadings: isolationReadings,
*/
            ));
  }

  /// Gets the full project name.
  get fullProjectName => null;

  /// Converts the [TestStation] instance to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectID': projectID,
      'area': area,
      'tsID': tsID,
      'status': tsstatus,
      'latitude': latitude,
      'longitude': longitude,
      'officeNotes': officeNotes,
      'fieldNotes': fieldNotes,
      'picturePath': picturePath,
    };
  }

  /// Creates a copy of the [TestStation] instance with updated properties.
  TestStation copyWith({
    required int id,
    required int projectID,
    String? area,
    String? tsID,
    String? status,
    double? latitude,
    double? longitude,
    String? officeNotes,
    String? fieldNotes,
    String? picturePath,
    PLTestLeadReading? plTestLeadReadings,
    PermRefReading? permRefReadings,
    AnodeReading? anodeReadings,
    ShuntReading? shuntReadings,
    RiserReading? riserReadings,
    ForeignReading? foreignReadings,
    TestLeadReading? testLeadReadings,
    CouponReading? couponReadings,
    BondReading? bondReadings,
    IsolationReading? isolationReadings,
  }) {
    return TestStation(
      id: id,
      projectID: projectID,
      area: area ?? this.area,
      tsID: tsID ?? this.tsID,
      tsstatus: status ?? tsstatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      officeNotes: officeNotes ?? this.officeNotes,
      fieldNotes: fieldNotes ?? this.fieldNotes,
      picturePath: picturePath ?? this.picturePath,
    );
  }

  /// Gets the color associated with the test station status.
  Color gettsStatusColor() {
    switch (tsstatus) {
      case 'Pass':
        return Colors.green;
      case 'Attention':
        return Colors.yellow;
      case 'Issue':
        return Colors.red;
      case 'Unchecked':
        return Colors.grey;
      default:
        return Colors.grey; // Default color if status is unknown
    }
  }

  /// Updates the test station status.
  void updateTSStatus(String newTSStatus) {
    tsstatus = newTSStatus;
  }
}

DateTime? _parseDateTime(String? dateTimeString) {
  if (dateTimeString == null || dateTimeString.isEmpty) {
    return null;
  }
  try {
    return DateTime.parse(dateTimeString);
  } catch (e) {
    // Handle or log the error as appropriate
    return null;
  }
}

/// Represents a PLTestLeadReading object.
class PLTestLeadReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final String? waveForm;

  /// Constructs a PLTestLeadReading object.
  ///
  /// [id] - The ID of the reading.
  /// [stationID] - The ID of the station.
  /// [testStationID] - The ID of the test station.
  /// [name] - The name of the reading.
  /// [voltsON] - The voltage when turned on.
  /// [voltsONDate] - The date and time when the voltage was turned on.
  /// [voltsOFF] - The voltage when turned off.
  /// [voltsOFFDate] - The date and time when the voltage was turned off.
  /// [orderIndex] - The order index of the reading.
  PLTestLeadReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label = '',
    this.voltsAC,
    this.voltsACDate,
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.waveForm,
    required this.orderIndex,
  });

  /// Gets the formatted voltage when turned on.
  String get formattedVoltsON {
    if (voltsON != null) {
      final formatter = NumberFormat("0.000"); // Format to 3 decimal places
      return formatter.format(voltsON);
    }
    return '';
  }

  /// Gets the formatted voltage when turned off.
  String get formattedVoltsOFF {
    if (voltsOFF != null) {
      final formatter = NumberFormat("0.000"); // Format to 3 decimal places
      return formatter.format(voltsOFF);
    }
    return '';
  }

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  String get formattedWaveForm => waveForm ?? '';

  String get acVolts => voltsAC != null ? voltsAC.toString() : '';

  // String get formattedWaveForm {
  //   return waveForm?.join(';') ?? '';
  // }

  /// Converts the PLTestLeadReading object to a map.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'waveForm': waveForm, // This is a list of wave form data
      'order_index': orderIndex,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Creates a new PLTestLeadReading object from a map.
  factory PLTestLeadReading.fromMap(Map<String, dynamic> map) {
    return PLTestLeadReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'] ?? '',
      label: map['label'] ?? '',
      voltsAC: map['voltsAC'],
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      waveForm: map['waveForm'] ?? '',
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a reading of a permanent reference in an asset inspection.
class PermRefReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final String? type;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final String? waveForm;

  /// Constructs a [PermRefReading] object.
  ///
  /// The [id] is the unique identifier of the reading.
  /// The [stationID] is the identifier of the station where the reading was taken.
  /// The [testStationID] is the identifier of the test station.
  /// The [name] is the name of the reading.
  /// The [voltsON] is the voltage when the reading is turned on.
  /// The [voltsONDate] is the date and time when the reading is turned on.
  /// The [voltsOFF] is the voltage when the reading is turned off.
  /// The [voltsOFFDate] is the date and time when the reading is turned off.
  /// The [type] is the type of the reading.
  /// The [orderIndex] is the order index of the reading.

  PermRefReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label,
    this.voltsAC,
    this.voltsACDate,
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.waveForm,
    this.type,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedVoltsON {
    if (voltsON != null) {
      final formatter = NumberFormat("0.000");
      return formatter.format(voltsON);
    }
    return '';
  }

  String get formattedVoltsOFF {
    if (voltsOFF != null) {
      final formatter = NumberFormat("0.000");
      return formatter.format(voltsOFF);
    }
    return '';
  }

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  String get formattedWaveForm => waveForm ?? '';

  /// Converts the [PermRefReading] object to a map.
  ///
  /// Returns a map representation of the [PermRefReading] object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'waveForm': waveForm,
      'type': type,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Constructs a [PermRefReading] object from a map.
  ///
  /// The [map] is a map representation of the [PermRefReading] object.
  factory PermRefReading.fromMap(Map<String, dynamic> map) {
    return PermRefReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'] ?? '',
      label: map['label'] ?? '',
      voltsAC: map['voltsAC'],
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      waveForm: map['waveForm'] ?? '',
      type: map['type'] ?? '',
      orderIndex: map['order_index'],
    );
  }
}

/// Represents an anode reading.
class AnodeReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final double? current;
  final DateTime? currentDate;
  final String? wireColor;
  final int? lugNumber;
  final String? anodeMaterial;
  final String? waveForm;

  /// Creates a new instance of [AnodeReading].
  ///
  /// [id] is the ID of the reading.
  /// [stationID] is the ID of the station.
  /// [testStationID] is the ID of the test station.
  /// [name] is the name of the reading.
  /// [voltsON] is the voltage when turned on.
  /// [voltsONDate] is the date and time when the voltage was turned on.
  /// [voltsOFF] is the voltage when turned off.
  /// [voltsOFFDate] is the date and time when the voltage was turned off.
  /// [current] is the current reading.
  /// [currentDate] is the date and time when the current was measured.
  /// [orderIndex] is the index of the reading in the order.
  AnodeReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label,
    this.voltsAC,
    this.voltsACDate,
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.wireColor,
    this.lugNumber,
    this.waveForm,
    this.current,
    this.currentDate,
    this.anodeMaterial,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedVoltsON {
    if (voltsON != null) {
      final formatter = NumberFormat("0.000");
      return formatter.format(voltsON);
    }
    return '';
  }

  String get formattedVoltsOFF {
    if (voltsOFF != null) {
      final formatter = NumberFormat("0.000");
      return formatter.format(voltsOFF);
    }
    return '';
  }

  String get formattedCurrent {
    if (current != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(current);
    }
    return '';
  }

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  String get formattedWaveForm => waveForm ?? '';

  /// Converts the [AnodeReading] object to a map.
  ///
  /// Returns a map representation of the [AnodeReading] object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'wireColor': wireColor,
      'lugNumber': lugNumber,
      'waveForm': waveForm,
      'current': current,
      'current_Date': currentDate,
      'anode_Material': anodeMaterial,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Creates a new [AnodeReading] object from a map.
  ///
  /// [map] is the map representation of the [AnodeReading] object.
  factory AnodeReading.fromMap(Map<String, dynamic> map) {
    return AnodeReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'] as String,
      label: map['label'] as String?,
      voltsAC: (map['voltsAC'] as num?)?.toDouble(),
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      voltsON: (map['voltsON'] as num?)?.toDouble(),
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: (map['voltsOFF'] as num?)?.toDouble(),
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      wireColor: map['wireColor'] as String?,
      lugNumber: map['lugNumber'] as int?,
      waveForm: map['waveForm'] as String?,
      current: (map['current'] as num?)?.toDouble(),
      currentDate: _parseDateTime(map['current_Date']),
      anodeMaterial: map['anode_Material'] as String?,
      orderIndex: map['order_index'] as int,
    );
  }
}

/// Represents a shunt reading.
class ShuntReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final String? sideA;
  final String? sideB;
  final double? ratioMV;
  final double? ratioAMPS;
  final double? factor;
  final double? vDrop;
  final DateTime? vDropDate;
  final double? calculated;
  final DateTime? calculatedDate;

  /// Creates a new instance of [ShuntReading].
  ///
  /// The [id] is the unique identifier of the shunt reading.
  /// The [stationID] is the identifier of the station.
  /// The [testStationID] is the identifier of the test station.
  /// The [name] is the name of the shunt reading.
  /// The [sideA] is the value of side A.
  /// The [sideB] is the value of side B.
  /// The [ratioMV] is the ratio in millivolts.
  /// The [ratioAMPS] is the ratio in amps.
  /// The [factor] is the factor value.
  /// The [vDrop] is the voltage drop value.
  /// The [vDropDate] is the date of the voltage drop.
  /// The [calculated] is the calculated value.
  /// The [calculatedDate] is the date of the calculated value.
  /// The [orderIndex] is the index of the shunt reading in the order.

  ShuntReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label,
    this.voltsAC,
    this.voltsACDate,
    this.sideA,
    this.sideB,
    this.ratioMV,
    this.ratioAMPS,
    this.factor,
    this.vDrop,
    this.vDropDate,
    this.calculated,
    this.calculatedDate,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedratioMV => ratioMV != null ? _formatVoltage(ratioMV!) : '';

  String get formattedratioAMPS => ratioAMPS != null ? _formatVoltage(ratioAMPS!) : '';

  String get formattedfactor => factor != null ? _formatVoltage(factor!) : '';

  String get formattedvDrop => vDrop != null ? _formatVoltage(vDrop!) : '';

  String get formattedcalculated => calculated != null ? _formatVoltage(calculated!) : '';
  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  // Helper method to format voltage values
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [ShuntReading] object to a map.
  ///
  /// Returns a map representation of the [ShuntReading] object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'side_a': sideA,
      'side_b': sideB,
      'ratio_mv': ratioMV,
      'ratio_current': ratioAMPS,
      'factor': factor,
      'voltage_drop': vDrop,
      'voltage_drop_date': vDropDate,
      'calculated': calculated,
      'calculated_date': calculatedDate,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Creates a [ShuntReading] object from a map.
  ///
  /// The [map] is a map representation of the [ShuntReading] object.
  factory ShuntReading.fromMap(Map<String, dynamic> map) {
    return ShuntReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'],
      label: map['label'],
      voltsAC: map['voltsAC'],
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      sideA: map['side_a'],
      sideB: map['side_b'],
      ratioMV: map['ratio_mv'],
      ratioAMPS: map['ratio_current'],
      factor: map['factor'],
      vDrop: map['voltage_drop'],
      vDropDate: _parseDateTime(map['voltage_drop_date']),
      calculated: map['calculated'],
      calculatedDate: _parseDateTime(map['calculated_date']),
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a reading for a riser.
class RiserReading {
  final int? id;
  final int? stationID;
  final String testStationID;
  final String name;
  final String? label;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final int? pipeDiameter;
  final String? waveForm;
  final int orderIndex;

  RiserReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label,
    this.voltsAC,
    this.voltsACDate,
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.pipeDiameter,
    this.waveForm,
    required this.orderIndex,
  });

  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  String get formattedWaveForm => waveForm ?? '';

  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate?.toIso8601String(),
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate?.toIso8601String(),
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate?.toIso8601String(),
      'pipe_Diameter': pipeDiameter,
      'waveForm': waveForm,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory RiserReading.fromMap(Map<String, dynamic> map) {
    return RiserReading(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      stationID: map['stationID'] is int ? map['stationID'] : int.tryParse(map['stationID'].toString()),
      testStationID: map['testStationID'].toString(),
      name: map['name'].toString(),
      label: map['label']?.toString(),
      voltsAC: map['voltsAC'] is double ? map['voltsAC'] : double.tryParse(map['voltsAC'].toString()),
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      voltsON: map['voltsON'] is double ? map['voltsON'] : double.tryParse(map['voltsON'].toString()),
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'] is double ? map['voltsOFF'] : double.tryParse(map['voltsOFF'].toString()),
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      pipeDiameter: map['pipe_Diameter'] is int ? map['pipe_Diameter'] : int.tryParse(map['pipe_Diameter'].toString()),
      waveForm: map['waveForm']?.toString(),
      orderIndex: map['order_index'] is int ? map['order_index'] : int.parse(map['order_index'].toString()),
    );
  }

  static DateTime? _parseDateTime(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    return null;
  }
}

/// Represents a foreign reading.
class ForeignReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final String? waveForm;

  /// Constructs a [ForeignReading] object.
  ///
  /// [id] is the ID of the reading.
  /// [stationID] is the ID of the station.
  /// [testStationID] is the ID of the test station.
  /// [name] is the name of the reading.
  /// [voltsON] is the voltage when turned on.
  /// [voltsONDate] is the date and time when turned on.
  /// [voltsOFF] is the voltage when turned off.
  /// [voltsOFFDate] is the date and time when turned off.
  /// [orderIndex] is the order index of the reading.
  ForeignReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label,
    this.voltsAC,
    this.voltsACDate,
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.waveForm,
    required this.orderIndex,
  });

  /// Gets the formatted voltage when turned on.
  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';

  /// Gets the formatted voltage when turned off.
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';

  String get formattedWaveForm => waveForm ?? '';

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  /// Formats the voltage value.
  ///
  /// [value] is the voltage value to format.
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [ForeignReading] object to a map.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'waveForm': waveForm,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Creates a [ForeignReading] object from a map.
  ///
  /// [map] is the map containing the object data.
  factory ForeignReading.fromMap(Map<String, dynamic> map) {
    return ForeignReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'],
      label: map['label'],
      voltsAC: map['voltsAC'],
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      waveForm: map['waveForm'],
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a test lead reading.
class TestLeadReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final String? fieldLabel;
  final String? waveForm;

  /// Constructs a [TestLeadReading] object.
  ///
  /// The [id] is the unique identifier of the reading.
  /// The [stationID] is the identifier of the station.
  /// The [testStationID] is the identifier of the test station.
  /// The [name] is the name of the reading.
  /// The [voltsON] is the voltage when the lead is ON.
  /// The [voltsONDate] is the date and time when the lead is ON.
  /// The [voltsOFF] is the voltage when the lead is OFF.
  /// The [voltsOFFDate] is the date and time when the lead is OFF.
  /// The [orderIndex] is the index used for ordering readings.
  TestLeadReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label,
    this.voltsAC,
    this.voltsACDate,
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.fieldLabel,
    this.waveForm,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';

  String get formattedWaveForm => waveForm ?? '';

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  // Helper method to format voltage values
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [TestLeadReading] object to a map.
  ///
  /// Returns a map representation of the object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'fieldLabel': fieldLabel,
      'waveForm': waveForm,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Constructs a [TestLeadReading] object from a map.
  ///
  /// The [map] is a map representation of the object.
  factory TestLeadReading.fromMap(Map<String, dynamic> map) {
    return TestLeadReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'],
      label: map['label'],
      voltsAC: map['voltsAC'],
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      fieldLabel: map['fieldLabel'],
      waveForm: map['waveForm'],
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a coupon reading.
class CouponReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final double? current;
  final DateTime? currentDate;
  final String? connectedTo;
  final String? type;
  final double? size;
  final String? waveForm;

  /// Creates a new instance of [CouponReading].
  ///
  /// The [id] is the unique identifier of the coupon reading.
  /// The [stationID] is the identifier of the station.
  /// The [testStationID] is the identifier of the test station.
  /// The [name] is the name of the coupon reading.
  /// The [voltsON] is the voltage when the coupon is ON.
  /// The [voltsONDate] is the date and time when the coupon is ON.
  /// The [voltsOFF] is the voltage when the coupon is OFF.
  /// The [voltsOFFDate] is the date and time when the coupon is OFF.
  /// The [current] is the current of the coupon.
  /// The [currentDate] is the date and time when the current is measured.
  /// The [connectedTo] is the connection information of the coupon.
  /// The [type] is the type of the coupon.
  /// The [size] is the size of the coupon.
  /// The [orderIndex] is the index of the coupon reading in the order.

  CouponReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label,
    this.voltsAC,
    this.voltsACDate,
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.current,
    this.currentDate,
    this.waveForm,
    this.connectedTo,
    this.type,
    this.size,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';
  String get formattedCurrent => current != null ? _formatVoltage(current!) : '';
  String get formattedSize => size != null ? _formatVoltage(size!) : '';
  String get formattedWaveForm => waveForm ?? '';

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  // Helper method to format voltage values
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [CouponReading] object to a map.
  ///
  /// Returns a map representation of the [CouponReading] object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'current': current,
      'current_Date': currentDate,
      'waveForm': waveForm,
      'connected_to': connectedTo,
      'coupon_type': type,
      'coupon_size': size,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Creates a [CouponReading] object from a map.
  ///
  /// The [map] should contain the necessary properties to create a [CouponReading] object.
  factory CouponReading.fromMap(Map<String, dynamic> map) {
    return CouponReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'],
      label: map['label'],
      voltsAC: map['voltsAC'],
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      current: map['current'],
      currentDate: _parseDateTime(map['current_Date']),
      waveForm: map['waveForm'],
      connectedTo: map['connected_to'],
      type: map['coupon_type'],
      size: map['coupon_size'],
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a bond reading.
class BondReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final String? sideA;
  final String? sideB;
  final double? current;
  final DateTime? currentDate;
  final String? waveForm;

  /// Constructs a [BondReading] object.
  ///
  /// [id] is the unique identifier of the bond reading.
  /// [stationID] is the identifier of the station.
  /// [testStationID] is the identifier of the test station.
  /// [name] is the name of the bond reading.
  /// [sideA] is the value of side A.
  /// [sideB] is the value of side B.
  /// [current] is the current value.
  /// [currentDate] is the date and time of the current reading.
  /// [orderIndex] is the index of the bond reading in the order.
  BondReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.label,
    this.voltsAC,
    this.voltsACDate,
    this.sideA,
    this.sideB,
    this.current,
    this.currentDate,
    this.waveForm,
    required this.orderIndex,
  });

  /// Gets the formatted current value.
  ///
  /// Returns an empty string if [current] is null.
  String get formattedCurrent => current != null ? _formatVoltage(current!) : '';

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  String get formattedWaveForm => waveForm ?? '';

  /// Formats the voltage value.
  ///
  /// If [value] is an integer, returns the integer as a string.
  /// Otherwise, returns the value with 2 decimal places.
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [BondReading] object to a map.
  ///
  /// Returns a map representation of the object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'side_a': sideA,
      'side_b': sideB,
      'current': current,
      'current_Date': currentDate,
      'waveForm': waveForm,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Creates a [BondReading] object from a map.
  ///
  /// [map] is the map representation of the object.
  factory BondReading.fromMap(Map<String, dynamic> map) {
    return BondReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'],
      label: map['label'],
      voltsAC: map['voltsAC'],
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      sideA: map['side_a'],
      sideB: map['side_b'],
      current: map['current'],
      currentDate: _parseDateTime(map['current_Date']),
      waveForm: map['waveForm'],
      orderIndex: map['order_index'],
    );
  }
}

/// Represents an isolation reading.
class IsolationReading {
  final int? id;
  final int? stationID;
  final String? testStationID;
  final String name;
  final String? label;
  final int orderIndex;
  final double? voltsAC;
  final DateTime? voltsACDate;
  final String? sideA;
  final String? sideB;
  final String? type;
  final int? shorted;
  final DateTime? shortedDate;
  final double? current;
  final DateTime? currentDate;

  /// Constructs an instance of [IsolationReading].
  ///
  /// [id] is the unique identifier of the reading.
  /// [stationID] is the identifier of the station.
  /// [testStationID] is the identifier of the test station.
  /// [name] is the name of the reading.
  /// [sideA] is the value of side A.
  /// [sideB] is the value of side B.
  /// [type] is the type of isolation.
  /// [shorted] is the shorted status.
  /// [shortedDate] is the date of shorted status.
  /// [current] is the current value.
  /// [currentDate] is the date of the current value.
  /// [orderIndex] is the index of the reading in the order.
  IsolationReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.voltsAC,
    this.voltsACDate,
    this.label,
    this.sideA,
    this.sideB,
    this.type,
    this.shorted,
    this.shortedDate,
    this.current,
    this.currentDate,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedCurrent => current != null ? _formatVoltage(current!) : '';

  String get formattedvoltsAC {
    if (voltsAC != null) {
      final formatter = NumberFormat("0.00");
      return formatter.format(voltsAC);
    }
    return '';
  }

  // Helper method to format voltage values
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [IsolationReading] object to a map.
  ///
  /// Returns a map representation of the object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'label': label,
      'voltsAC': voltsAC,
      'voltsAC_Date': voltsACDate,
      'side_a': sideA,
      'side_b': sideB,
      'iso_type': type,
      'iso_shorted': shorted,
      'iso_shorted_date': shortedDate,
      'iso_current': current,
      'iso_current_date': currentDate,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Constructs an instance of [IsolationReading] from a map.
  ///
  /// [map] is the map representation of the object.
  factory IsolationReading.fromMap(Map<String, dynamic> map) {
    return IsolationReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'],
      label: map['label'],
      voltsAC: map['voltsAC'],
      voltsACDate: _parseDateTime(map['voltsAC_Date']),
      sideA: map['side_a'],
      sideB: map['side_b'],
      type: map['iso_type'],
      shorted: map['iso_shorted'],
      shortedDate: _parseDateTime(map['iso_shorted_date']),
      current: map['iso_current'],
      currentDate: _parseDateTime(map['iso_current_date']),
      orderIndex: map['order_index'],
    );
  }
}
