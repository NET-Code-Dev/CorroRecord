import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

//HOW TO USE

/*
CustomTextField(
  controller: _yourController,
  focusNode: _yourFocusNode,
  hintText: RichText(
    text: TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: [
        TextSpan(text: 'Part 1', style: TextStyle(fontSize: 16)),
        TextSpan(text: ' Part 2', style: TextStyle(fontSize: 12)),
      ],
    ),
  ),
  keyboardType: TextInputType.text,
  textAlign: TextAlign.start,
  width: 200,
  height: 50,
)
*/

/// A custom text field widget.
///
/// This widget provides a customizable text field with various properties such as controller,
/// focus node, style, hint text, keyboard type, max lines, text alignment, width, and height.
/// It also supports responsive sizing based on the device's screen width.
///
///Example usage:
/// ```dart
/// CustomTextField(
///  controller: _yourController,
///  focusNode: _yourFocusNode,
///  hintText: RichText(
///    text: TextSpan(
///      style: DefaultTextStyle.of(context).style,
///      children: [
///        TextSpan(text: 'Part 1', style: TextStyle(fontSize: 16)),
///        TextSpan(text: ' Part 2', style: TextStyle(fontSize: 12)),
///      ],
///    ),
///  ),
///  keyboardType: TextInputType.text,
///  textAlign: TextAlign.start,
///  width: 200,
///  height: 50,
/// )
/// ```
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final Widget hintText;
  final TextInputType keyboardType;
  final int? maxLines;
  final TextAlign textAlign;
  final double width;
  final double height;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.style,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.maxLines,
    this.textAlign = TextAlign.start,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width * MediaQuery.of(context).size.width / 414.0,
      height: height * MediaQuery.of(context).size.width / 414.0,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            style: style,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textAlign: textAlign,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(10, 3, 10, 3) * MediaQuery.of(context).size.width / 414.0,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: const Color.fromARGB(255, 67, 197, 228), width: 1.5.w),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: const Color.fromARGB(255, 13, 125, 253), width: 1.5.w),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5.w),
              ),
              // Removed hintText from here
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w), // Adjust padding as needed
            child: hintText,
          ),
        ],
      ),
    );
  }
}
