enum PokitProMode {
  idle, // 0
  dcVoltage, // 1
  acVoltage, // 2
  dcCurrent, // 3
  acCurrent, // 4
  resistance, // 5
  diode, // 6
  continuity, // 7
  temperature, // 8
  dsoMode, // 9
  dataloggerMode, // 10
}

enum PokitProStatus {
  autoRangeOff, //voltage, current and resistance modes only
  autoRangeOn, //voltage, current and resistance modes only
  error, //all modes
  noContinuity, //continuity mode only
  continuity, //continuity mode only
  ok, //temperature and diode modes only
}

// Enum representing the 'Capacitance Range' supported by the Pokit Pro.
enum CapacitanceRangeEnum {
  mf_100nF, // < Up to 100nF
  mf_10uF, // < Up to 10μF
  mf_1mF, // < Up to 1mF
  auto, // < auto range
}

// Class representing the 'Capacitance Range' settings.
class CapacitanceRange {
  // Method to return a Range as a 'uint8' as a convenience for writing to the Pokit Pro
  static int capacitanceRangeSetValue(CapacitanceRangeEnum range) {
    switch (range) {
      case CapacitanceRangeEnum.mf_100nF:
        return 0;
      case CapacitanceRangeEnum.mf_10uF:
        return 1;
      case CapacitanceRangeEnum.mf_1mF:
        return 2;
      case CapacitanceRangeEnum.auto:
        return 255;
      default:
        return -1;
    }
  }

  // Method to get the maximum value for a given capacitance range enum value.
  static dynamic capacitanceRangeMaxValue(CapacitanceRangeEnum range) {
    switch (range) {
      case CapacitanceRangeEnum.mf_100nF:
        return 100;
      case CapacitanceRangeEnum.mf_10uF:
        return 10;
      case CapacitanceRangeEnum.mf_1mF:
        return 1;
      case CapacitanceRangeEnum.auto:
        return 'Auto';
      default:
        return null;
    }
  }

  // Method to convert a capacitance range enum value to its string representation.
  static String capacitanceRangeToString(CapacitanceRangeEnum range) {
    switch (range) {
      case CapacitanceRangeEnum.mf_100nF:
        return "100nF";
      case CapacitanceRangeEnum.mf_10uF:
        return "10uF";
      case CapacitanceRangeEnum.mf_1mF:
        return "1mF";
      case CapacitanceRangeEnum.auto:
        return "Auto";
      default:
        return "Unknown";
    }
  }

  // Method to get the index of a capacitance range enum value from its string representation.
  static int? capacitanceRangeFromString(String range) {
    switch (range) {
      case "100nF":
        return CapacitanceRangeEnum.mf_100nF.index;
      case "10uF":
        return CapacitanceRangeEnum.mf_10uF.index;
      case "1mF":
        return CapacitanceRangeEnum.mf_1mF.index;
      case "Auto":
        return CapacitanceRangeEnum.auto.index;
      default:
        return null;
    }
  }
}

// Enum representing the 'Voltage Range' supported by the Pokit Pro.
enum VoltageRangeEnum {
  v_250mV, // < Up to 250mV
  v_2V, // < Up to 2V
  v_10V, // < Up to 10V
  v_30V, // < Up to 30V
  v_60V, // < Up to 60V
  v_125V, // < Up to 125V
  v_400V, // < Up to 400V
  v_600V, // < Up to 600V
  auto, // < auto range
}

// Class representing the 'Voltage Range' settings.
class VoltageRange {
  // Method to set the value of the voltage range based on the enum value.
  static int voltageRangeSetValue(VoltageRangeEnum range) {
    switch (range) {
      case VoltageRangeEnum.v_250mV:
        return 0;
      case VoltageRangeEnum.v_2V:
        return 1;
      case VoltageRangeEnum.v_10V:
        return 2;
      case VoltageRangeEnum.v_30V:
        return 3;
      case VoltageRangeEnum.v_60V:
        return 4;
      case VoltageRangeEnum.v_125V:
        return 5;
      case VoltageRangeEnum.v_400V:
        return 6;
      case VoltageRangeEnum.v_600V:
        return 7;
      case VoltageRangeEnum.auto:
        return 255;
      default:
        return -1;
    }
  }

  // Method to get the maximum value for a given voltage range enum value.
  static dynamic voltageRangeMaxValue(VoltageRangeEnum range) {
    switch (range) {
      case VoltageRangeEnum.v_250mV:
        return 250;
      case VoltageRangeEnum.v_2V:
        return 2000;
      case VoltageRangeEnum.v_10V:
        return 10000;
      case VoltageRangeEnum.v_30V:
        return 30000;
      case VoltageRangeEnum.v_60V:
        return 60000;
      case VoltageRangeEnum.v_125V:
        return 125000;
      case VoltageRangeEnum.v_400V:
        return 400000;
      case VoltageRangeEnum.v_600V:
        return 600000;
      case VoltageRangeEnum.auto:
        return 'Auto';
      default:
        return null;
    }
  }

  // Method to convert a voltage range enum value to its string representation.
  static String voltageRangeToString(VoltageRangeEnum range) {
    switch (range) {
      case VoltageRangeEnum.v_250mV:
        return "250mV";
      case VoltageRangeEnum.v_2V:
        return "2V";
      case VoltageRangeEnum.v_10V:
        return "10V";
      case VoltageRangeEnum.v_30V:
        return "30V";
      case VoltageRangeEnum.v_60V:
        return "60V";
      case VoltageRangeEnum.v_125V:
        return "125V";
      case VoltageRangeEnum.v_400V:
        return "400V";
      case VoltageRangeEnum.v_600V:
        return "600V";
      case VoltageRangeEnum.auto:
        return "Auto";
      default:
        return "Unknown";
    }
  }

  // Method to get the index of a voltage range enum value from its string representation.
  static int? voltageRangeFromString(String range) {
    switch (range) {
      case "250mV":
        return VoltageRangeEnum.v_250mV.index;
      case "2V":
        return VoltageRangeEnum.v_2V.index;
      case "10V":
        return VoltageRangeEnum.v_10V.index;
      case "30V":
        return VoltageRangeEnum.v_30V.index;
      case "60V":
        return VoltageRangeEnum.v_60V.index;
      case "125V":
        return VoltageRangeEnum.v_125V.index;
      case "400V":
        return VoltageRangeEnum.v_400V.index;
      case "600V":
        return VoltageRangeEnum.v_600V.index;
      case "Auto":
        return VoltageRangeEnum.auto.index;
      default:
        return null;
    }
  }
}

// Enum representing the 'Current Range' supported by the Pokit Pro.
enum CurrentRangeEnum {
  a_500uA, // < Up to 5µA
  a_2mA, // < Up to 2mA
  a_10mA, // < Up to 10mA
  a_125mA, // < Up to 125mA
  a_300mA, // < Up to 300mA
  a_3A, // < Up to 3A
  a_10A, // < Up to 10A
  auto, // < auto range
}

// Class representing the 'Current Range' settings.
class CurrentRange {
  // Method to get the value of a current range enum.
  static int currentRangeSetValue(CurrentRangeEnum range) {
    switch (range) {
      case CurrentRangeEnum.a_500uA:
        return 0;
      case CurrentRangeEnum.a_2mA:
        return 1;
      case CurrentRangeEnum.a_10mA:
        return 2;
      case CurrentRangeEnum.a_125mA:
        return 3;
      case CurrentRangeEnum.a_300mA:
        return 4;
      case CurrentRangeEnum.a_3A:
        return 5;
      case CurrentRangeEnum.a_10A:
        return 6;
      case CurrentRangeEnum.auto:
        return 255;
      default:
        return -1;
    }
  }

  // Method to get the maximum value of a current range enum.
  static dynamic currentRangeMaxValue(CurrentRangeEnum range) {
    switch (range) {
      case CurrentRangeEnum.a_500uA:
        return 500;
      case CurrentRangeEnum.a_2mA:
        return 2000;
      case CurrentRangeEnum.a_10mA:
        return 10000;
      case CurrentRangeEnum.a_125mA:
        return 125000;
      case CurrentRangeEnum.a_300mA:
        return 300000;
      case CurrentRangeEnum.a_3A:
        return 3000000;
      case CurrentRangeEnum.a_10A:
        return 10000000;
      case CurrentRangeEnum.auto:
        return 'Auto';
      default:
        return null;
    }
  }

  // Method to convert a current range enum value to its string representation.
  static String currentRangeToString(CurrentRangeEnum range) {
    switch (range) {
      case CurrentRangeEnum.a_500uA:
        return "500uA";
      case CurrentRangeEnum.a_2mA:
        return "2mA";
      case CurrentRangeEnum.a_10mA:
        return "10mA";
      case CurrentRangeEnum.a_125mA:
        return "125mA";
      case CurrentRangeEnum.a_300mA:
        return "300mA";
      case CurrentRangeEnum.a_3A:
        return "3A";
      case CurrentRangeEnum.a_10A:
        return "10A";
      case CurrentRangeEnum.auto:
        return "Auto";
      default:
        return "Unknown";
    }
  }

  // Method to get the index of a current range enum value from its string representation.
  static int? currentRangeFromString(String range) {
    switch (range) {
      case "500uA":
        return CurrentRangeEnum.a_500uA.index;
      case "2mA":
        return CurrentRangeEnum.a_2mA.index;
      case "10mA":
        return CurrentRangeEnum.a_10mA.index;
      case "125mA":
        return CurrentRangeEnum.a_125mA.index;
      case "300mA":
        return CurrentRangeEnum.a_300mA.index;
      case "3A":
        return CurrentRangeEnum.a_3A.index;
      case "10A":
        return CurrentRangeEnum.a_10A.index;
      case "Auto":
        return CurrentRangeEnum.auto.index;
      default:
        return null;
    }
  }
}

// Enum representing the 'Resistance Range' supported by the Pokit Pro.
enum ResistanceRangeEnum {
  ohm_30, // < Up to 30Ω
  ohm_75, // < Up to 75Ω
  ohm_400, // < Up to 400Ω
  ohm_5K, // < Up to 5KΩ
  ohm_10K, // < Up to 10KΩ
  ohm_15K, // < Up to 15KΩ
  ohm_40K, // < Up to 40KΩ
  ohm_500K, // < Up to 500KΩ
  ohm_700K, // < Up to 700KΩ
  ohm_1M, // < Up to 1MΩ
  ohm_3M, // < Up to 3MΩ
  auto, // < auto range
}

// Class representing the 'Resistance Range' settings.
class ResistanceRange {
  // Method to get the value associated with a resistance range enum.
  static int resistanceRangeSetValue(ResistanceRangeEnum range) {
    switch (range) {
      case ResistanceRangeEnum.ohm_30:
        return 0;
      case ResistanceRangeEnum.ohm_75:
        return 1;
      case ResistanceRangeEnum.ohm_400:
        return 2;
      case ResistanceRangeEnum.ohm_5K:
        return 3;
      case ResistanceRangeEnum.ohm_10K:
        return 4;
      case ResistanceRangeEnum.ohm_15K:
        return 5;
      case ResistanceRangeEnum.ohm_40K:
        return 6;
      case ResistanceRangeEnum.ohm_500K:
        return 7;
      case ResistanceRangeEnum.ohm_700K:
        return 8;
      case ResistanceRangeEnum.ohm_1M:
        return 9;
      case ResistanceRangeEnum.ohm_3M:
        return 10;
      case ResistanceRangeEnum.auto:
        return 255;
      default:
        return -1;
    }
  }

  // Method to get the maximum value of a resistance range enum.
  static dynamic resistanceRangeMaxValue(ResistanceRangeEnum range) {
    switch (range) {
      case ResistanceRangeEnum.ohm_30:
        return 30;
      case ResistanceRangeEnum.ohm_75:
        return 75;
      case ResistanceRangeEnum.ohm_400:
        return 400;
      case ResistanceRangeEnum.ohm_5K:
        return 5000;
      case ResistanceRangeEnum.ohm_10K:
        return 10000;
      case ResistanceRangeEnum.ohm_15K:
        return 15000;
      case ResistanceRangeEnum.ohm_40K:
        return 40000;
      case ResistanceRangeEnum.ohm_500K:
        return 500000;
      case ResistanceRangeEnum.ohm_700K:
        return 700000;
      case ResistanceRangeEnum.ohm_1M:
        return 1000000;
      case ResistanceRangeEnum.ohm_3M:
        return 3000000;
      case ResistanceRangeEnum.auto:
        return 'Auto';
      default:
        return null;
    }
  }

  // Method to convert a resistance range enum value to its string representation.
  static String resistanceRangeToString(ResistanceRangeEnum range) {
    switch (range) {
      case ResistanceRangeEnum.ohm_30:
        return "30Ω";
      case ResistanceRangeEnum.ohm_75:
        return "75Ω";
      case ResistanceRangeEnum.ohm_400:
        return "400Ω";
      case ResistanceRangeEnum.ohm_5K:
        return "5KΩ";
      case ResistanceRangeEnum.ohm_10K:
        return "10KΩ";
      case ResistanceRangeEnum.ohm_15K:
        return "15KΩ";
      case ResistanceRangeEnum.ohm_40K:
        return "40KΩ";
      case ResistanceRangeEnum.ohm_500K:
        return "500KΩ";
      case ResistanceRangeEnum.ohm_700K:
        return "700KΩ";
      case ResistanceRangeEnum.ohm_1M:
        return "1MΩ";
      case ResistanceRangeEnum.ohm_3M:
        return "3MΩ";
      case ResistanceRangeEnum.auto:
        return "Auto";
      default:
        return "Unknown";
    }
  }

  // Method to get the index of a resistance range enum value from its string representation.
  static int? resistanceRangeFromString(String range) {
    switch (range) {
      case "30":
        return ResistanceRangeEnum.ohm_30.index;
      case "75":
        return ResistanceRangeEnum.ohm_75.index;
      case "400":
        return ResistanceRangeEnum.ohm_400.index;
      case "5K":
        return ResistanceRangeEnum.ohm_5K.index;
      case "10K":
        return ResistanceRangeEnum.ohm_10K.index;
      case "15K":
        return ResistanceRangeEnum.ohm_15K.index;
      case "40K":
        return ResistanceRangeEnum.ohm_40K.index;
      case "500K":
        return ResistanceRangeEnum.ohm_500K.index;
      case "700K":
        return ResistanceRangeEnum.ohm_700K.index;
      case "1M":
        return ResistanceRangeEnum.ohm_1M.index;
      case "3M":
        return ResistanceRangeEnum.ohm_3M.index;
      case "Auto":
        return ResistanceRangeEnum.auto.index;
      default:
        return null;
    }
  }

  static ResistanceRangeEnum? getEnumFromValue(int value) {
    if (value == 255) {
      return ResistanceRangeEnum.auto;
    } else if (value >= 0 && value <= 10) {
      // Assuming 10 is the last valid index before 'auto'
      return ResistanceRangeEnum.values[value];
    } else {
      return null; // or handle as error
    }
  }
}
