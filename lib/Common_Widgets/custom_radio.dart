import 'package:flutter/material.dart';

//HOW TO USE
/*
CustomRadio(
  groupValue: _oilLevel,
  value: 'pass',
  onChanged: (value) {
    setState(() {
      _oilLevel = value;
    });
  },
)
*/

/// A custom radio button widget.
///
/// This widget represents a custom radio button that can be used in a group of radio buttons.
/// It allows the user to select a single option from a group of options.
///
/// The [groupValue] parameter represents the currently selected value in the group.
/// The [value] parameter represents the value of this radio button.
/// The [onChanged] parameter is a callback function that is called when the radio button is selected.
///
/// The [activeColor] parameter represents the color of the radio button when it is selected.
/// The [inactiveBorderColor] parameter represents the color of the radio button's border when it is not selected.
///
/// Example usage:
/// ```dart
/// CustomRadio(
///   groupValue: selectedValue,
///   value: 1,
///   onChanged: (value) {
///     setState(() {
///       selectedValue = value;
///     });
///   },
/// )
/// ```
class CustomRadio extends StatelessWidget {
  final int? groupValue;
  final int value;
  final ValueChanged<int?> onChanged;

  final Color activeColor = const Color.fromARGB(255, 247, 143, 30);
  final Color inactiveBorderColor = Colors.grey;

  const CustomRadio({
    super.key,
    required this.groupValue,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = groupValue == value;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? activeColor : inactiveBorderColor,
            width: isSelected ? 2 : 1,
          ),
          color: Colors.white,
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
