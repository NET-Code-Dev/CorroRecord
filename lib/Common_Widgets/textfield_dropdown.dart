import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LabelTextField extends StatefulWidget {
  final String testStationID;
  final Future<List<String>> Function(String) fetchNamesForLabel;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const LabelTextField({
    super.key,
    required this.testStationID,
    required this.fetchNamesForLabel,
    required this.controller,
    required this.focusNode,
  });

  @override
  createState() => _LabelTextFieldState();
}

class _LabelTextFieldState extends State<LabelTextField> {
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
    _loadSuggestions();
  }

  void _onFocusChange() {
    if (widget.focusNode!.hasFocus) {
      setState(() {
        _showSuggestions = true;
      });
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  Future<void> _loadSuggestions() async {
    List<String> names = await widget.fetchNamesForLabel(widget.testStationID);
    setState(() {
      _suggestions = ['structure-port', 'structure-perm', ...names, 'Create New'];
    });
  }

  void _onSuggestionSelected(String suggestion) {
    if (suggestion == 'Create New') {
      widget.controller?.clear();
      widget.focusNode?.requestFocus();
      setState(() {
        _showSuggestions = false;
      });
    } else {
      widget.controller?.text = suggestion;
      widget.focusNode?.unfocus();
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showSuggestions)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
              color: Colors.white,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final isCreateNew = suggestion == 'Create New';

                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        suggestion,
                        style: isCreateNew
                            ? const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              )
                            : const TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                      ),
                      onTap: () => _onSuggestionSelected(suggestion),
                    ),
                    if (isCreateNew)
                      const Divider(
                        color: Colors.grey,
                        height: 1,
                        thickness: 2.5,
                      ),
                  ],
                );
              },
            ),
          ),
        SizedBox(
          width: 170.w, // Adjust the width as needed
          height: 40.h, // Adjust the height as needed
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            decoration: InputDecoration(
              // labelText: 'Label',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
            ),
          ),
        ),
      ],
    );
  }
}
