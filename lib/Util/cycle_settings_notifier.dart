//import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

/// A model class that represents the cycle settings.
///
/// This class is responsible for managing the selected cycle and radio values.
/// It notifies listeners when the selected cycle or radio is updated, triggering widget rebuilds.
class CycleSettingsModel with ChangeNotifier {
  String? _selectedCycle;
  int? _selectedRadio;

  String? get selectedCycle => _selectedCycle;
  int? get selectedRadio => _selectedRadio;

  /// Sets the selected cycle value.
  ///
  /// The [cycle] parameter represents the new selected cycle value.
  /// This method updates the [_selectedCycle] property and notifies listeners to rebuild widgets.
  void setSelectedCycle(String? cycle) {
    _selectedCycle = cycle;
    notifyListeners(); // Notify widgets to rebuild
  }

  /// Sets the selected radio value.
  ///
  /// The [radio] parameter represents the new selected radio value.
  /// This method updates the [_selectedRadio] property and notifies listeners to rebuild widgets.
  void setSelectedRadio(int? radio) {
    _selectedRadio = radio;
    notifyListeners(); // Notify widgets to rebuild
  }
}
