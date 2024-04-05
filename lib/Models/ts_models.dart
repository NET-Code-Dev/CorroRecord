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
    List<PLTestLeadReading>? readings;
    if (map['plTestLeadReadings'] != null) {
      var readingList = List.from(map['plTestLeadReadings']);
      readings = readingList.map((readingMap) {
        return PLTestLeadReading.fromMap(readingMap);
      }).toList();
    }

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
              plTestLeadReadings: readings,
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
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final int orderIndex;

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
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
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

  /// Converts the PLTestLeadReading object to a map.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
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
      name: map['name'],
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a reading of a permanent reference in an asset inspection.
class PermRefReading {
  final int? id;
  final int? stationID;
  final String testStationID;
  final String name;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final String? type;
  final int orderIndex;

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
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.type,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';

  // Helper method to format voltage values
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [PermRefReading] object to a map.
  ///
  /// Returns a map representation of the [PermRefReading] object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
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
      name: map['name'],
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      type: map['type'],
      orderIndex: map['order_index'],
    );
  }
}

/// Represents an anode reading.
class AnodeReading {
  final int? id;
  final int? stationID;
  final String testStationID;
  final String name;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final double? current;
  final DateTime? currentDate;
  final int orderIndex;

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
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.current,
    this.currentDate,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';
  String get formattedCurrent => current != null ? _formatVoltage(current!) : '';

  // Helper method to format voltage values
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [AnodeReading] object to a map.
  ///
  /// Returns a map representation of the [AnodeReading] object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'current': current,
      'current_Date': currentDate,
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
      voltsON: (map['voltsON'] as num?)?.toDouble(),
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: (map['voltsOFF'] as num?)?.toDouble(),
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      current: (map['current'] as num?)?.toDouble(),
      currentDate: _parseDateTime(map['current_Date']),
      orderIndex: map['order_index'] as int,
    );
  }
}

/// Represents a shunt reading.
class ShuntReading {
  final int? id;
  final int? stationID;
  final String testStationID;
  final String name;
  final String? sideA;
  final String? sideB;
  final double? ratioMV;
  final double? ratioAMPS;
  final double? factor;
  final double? vDrop;
  final DateTime? vDropDate;
  final double? calculated;
  final DateTime? calculatedDate;
  final int orderIndex;

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
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final int orderIndex;

  /// Constructs a new instance of [RiserReading].
  ///
  /// [id] is the unique identifier for the reading.
  /// [stationID] is the identifier of the station associated with the reading.
  /// [testStationID] is the identifier of the test station associated with the reading.
  /// [name] is the name of the reading.
  /// [voltsON] is the voltage when the reading is turned on.
  /// [voltsONDate] is the date and time when the reading is turned on.
  /// [voltsOFF] is the voltage when the reading is turned off.
  /// [voltsOFFDate] is the date and time when the reading is turned off.
  /// [orderIndex] is the index used for ordering the readings.
  RiserReading({
    this.id,
    this.stationID,
    required this.testStationID,
    required this.name,
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';

  // Helper method to format voltage values
  String _formatVoltage(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  /// Converts the [RiserReading] object to a map.
  ///
  /// Returns a map representation of the [RiserReading] object.
  Map<String, dynamic> toMap() {
    var map = {
      'stationID': stationID,
      'testStationID': testStationID,
      'name': name,
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'order_index': orderIndex,
    };
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Constructs a [RiserReading] object from a map.
  ///
  /// [map] is the map representation of the [RiserReading] object.
  factory RiserReading.fromMap(Map<String, dynamic> map) {
    return RiserReading(
      id: map['id'] as int,
      stationID: map['stationID'] as int,
      testStationID: map['testStationID'].toString(),
      name: map['name'],
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a foreign reading.
class ForeignReading {
  final int? id;
  final int? stationID;
  final String testStationID;
  final String name;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final int orderIndex;

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
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    required this.orderIndex,
  });

  /// Gets the formatted voltage when turned on.
  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';

  /// Gets the formatted voltage when turned off.
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';

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
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
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
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a test lead reading.
class TestLeadReading {
  final int? id;
  final int? stationID;
  final String testStationID;
  final String name;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final int orderIndex;

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
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    required this.orderIndex,
  });

  // Custom getters for formatted voltages
  String get formattedVoltsON => voltsON != null ? _formatVoltage(voltsON!) : '';
  String get formattedVoltsOFF => voltsOFF != null ? _formatVoltage(voltsOFF!) : '';

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
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
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
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      orderIndex: map['order_index'],
    );
  }
}

/// Represents a coupon reading.
class CouponReading {
  final int? id;
  final int? stationID;
  final String testStationID;
  final String name;
  final double? voltsON;
  final DateTime? voltsONDate;
  final double? voltsOFF;
  final DateTime? voltsOFFDate;
  final double? current;
  final DateTime? currentDate;
  final String? connectedTo;
  final String? type;
  final double? size;
  final int orderIndex;

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
    this.voltsON,
    this.voltsONDate,
    this.voltsOFF,
    this.voltsOFFDate,
    this.current,
    this.currentDate,
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
      'voltsON': voltsON,
      'voltsON_Date': voltsONDate,
      'voltsOFF': voltsOFF,
      'voltsOFF_Date': voltsOFFDate,
      'current': current,
      'current_Date': currentDate,
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
      voltsON: map['voltsON'],
      voltsONDate: _parseDateTime(map['voltsON_Date']),
      voltsOFF: map['voltsOFF'],
      voltsOFFDate: _parseDateTime(map['voltsOFF_Date']),
      current: map['current'],
      currentDate: _parseDateTime(map['current_Date']),
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
  final String testStationID;
  final String name;
  final String? sideA;
  final String? sideB;
  final double? current;
  final DateTime? currentDate;
  final int orderIndex;

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
    this.sideA,
    this.sideB,
    this.current,
    this.currentDate,
    required this.orderIndex,
  });

  /// Gets the formatted current value.
  ///
  /// Returns an empty string if [current] is null.
  String get formattedCurrent => current != null ? _formatVoltage(current!) : '';

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
      'side_a': sideA,
      'side_b': sideB,
      'current': current,
      'current_Date': currentDate,
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
      sideA: map['side_a'],
      sideB: map['side_b'],
      current: map['current'],
      currentDate: _parseDateTime(map['current_Date']),
      orderIndex: map['order_index'],
    );
  }
}

/// Represents an isolation reading.
class IsolationReading {
  final int? id;
  final int? stationID;
  final String testStationID;
  final String name;
  final String? sideA;
  final String? sideB;
  final String? type;
  final String? shorted;
  final DateTime? shortedDate;
  final double? current;
  final DateTime? currentDate;
  final int orderIndex;

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
