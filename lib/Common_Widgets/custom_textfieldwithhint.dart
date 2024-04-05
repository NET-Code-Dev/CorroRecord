import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

//HOW TO USE

/*
CustomTextFieldWithHint(
  controller: _ratioMVController,
  focusNode: _ratioMVFocusNode,
  keyboardType: TextInputType.number,
  hintText: 'mV',
  width: 140.w,
  height: 35.h,
),
*/

/// A custom text field widget with a hint text.
///
/// This widget provides a text field with a hint text and customizable properties such as controller,
/// focus node, keyboard type, width, and height.
///
/// Example usage:
/// ```dart
/// CustomTextFieldWithHint(
///   controller: myController,
///   focusNode: myFocusNode,
///   keyboardType: TextInputType.text,
///   hintText: 'Enter your name',
///   width: 200,
///   height: 50,
/// )
/// ```
class CustomTextFieldWithHint extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType keyboardType;
  final String hintText;
  final double width;
  final double height;

  const CustomTextFieldWithHint({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.keyboardType,
    required this.hintText,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(focusNode);
      },
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textAlign: TextAlign.left,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
            style: TextStyle(
              height: height / 24.sp, // Adjust the height accordingly
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              hintText,
              style: const TextStyle(
                color: Colors.grey, // Hint text color
              ),
            ),
          ),
        ],
      ),
    );
  }
}
