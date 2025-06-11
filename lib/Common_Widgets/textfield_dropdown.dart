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
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
    widget.controller?.addListener(_onTextChanged);
    _loadSuggestions();
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    widget.controller?.removeListener(_onTextChanged);
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode!.hasFocus) {
      _showDropdown();
    } else {
      // Add a small delay to allow for item selection
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _hideDropdown();
        }
      });
    }
  }

  void _onTextChanged() {
    final text = widget.controller?.text.toLowerCase() ?? '';
    setState(() {
      _filteredSuggestions = _suggestions
          .where((suggestion) =>
              suggestion.toLowerCase().contains(text) &&
              suggestion.toLowerCase() != 'create new')
          .toList();

      // Always add "Create New" option at the end
      _filteredSuggestions.add('Create New');
    });

    if (_showSuggestions) {
      _updateOverlay();
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> names =
          await widget.fetchNamesForLabel(widget.testStationID);
      setState(() {
        _suggestions = ['structure-port', 'structure-perm', ...names];
        _filteredSuggestions = List.from(_suggestions);
        _filteredSuggestions.add('Create New');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = ['structure-port', 'structure-perm'];
        _filteredSuggestions = List.from(_suggestions);
        _filteredSuggestions.add('Create New');
        _isLoading = false;
      });
    }
  }

  void _showDropdown() {
    if (_overlayEntry != null) return;

    setState(() {
      _showSuggestions = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    setState(() {
      _showSuggestions = false;
    });
    _hideOverlay();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 2.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _filteredSuggestions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No suggestions found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filteredSuggestions.length,
                          separatorBuilder: (context, index) {
                            final suggestion = _filteredSuggestions[index];
                            return suggestion == 'Create New'
                                ? Divider(
                                    color: Colors.grey.shade400,
                                    height: 1,
                                    thickness: 1,
                                  )
                                : const SizedBox.shrink();
                          },
                          itemBuilder: (context, index) {
                            final suggestion = _filteredSuggestions[index];
                            final isCreateNew = suggestion == 'Create New';

                            return InkWell(
                              onTap: () => _onSuggestionSelected(suggestion),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        suggestion,
                                        style: TextStyle(
                                          fontWeight: isCreateNew
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isCreateNew
                                              ? Colors.blue
                                              : Colors.black,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ),
                                    if (!isCreateNew &&
                                        !['structure-port', 'structure-perm']
                                            .contains(suggestion))
                                      GestureDetector(
                                        onTap: () =>
                                            _showDeleteConfirmation(suggestion),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 16.sp,
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                    if (!isCreateNew &&
                                        !['structure-port', 'structure-perm']
                                            .contains(suggestion))
                                      SizedBox(width: 8.w),
                                    if (!isCreateNew)
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditDialog(suggestion),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 16.sp,
                                          color: Colors.blue.shade400,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSuggestionSelected(String suggestion) {
    if (suggestion == 'Create New') {
      _showCreateNewDialog();
    } else {
      widget.controller?.text = suggestion;
      widget.focusNode?.unfocus();
      _hideDropdown();
    }
  }

  void _showCreateNewDialog() {
    final TextEditingController newLabelController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Label'),
          content: TextField(
            controller: newLabelController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Label Name',
              hintText: 'Enter new label name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newLabel = newLabelController.text.trim();
                if (newLabel.isNotEmpty && !_suggestions.contains(newLabel)) {
                  setState(() {
                    _suggestions.add(newLabel);
                    _filteredSuggestions = List.from(_suggestions);
                    _filteredSuggestions.add('Create New');
                  });
                  widget.controller?.text = newLabel;
                  // TODO: Save the new label to your database here
                  _saveNewLabel(newLabel);
                }
                Navigator.of(context).pop();
                widget.focusNode?.unfocus();
                _hideDropdown();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String currentLabel) {
    final TextEditingController editController =
        TextEditingController(text: currentLabel);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Label'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Label Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final editedLabel = editController.text.trim();
                if (editedLabel.isNotEmpty && editedLabel != currentLabel) {
                  setState(() {
                    final index = _suggestions.indexOf(currentLabel);
                    if (index != -1) {
                      _suggestions[index] = editedLabel;
                      _filteredSuggestions = List.from(_suggestions);
                      _filteredSuggestions.add('Create New');
                    }
                  });

                  // Update the current field if it matches the edited label
                  if (widget.controller?.text == currentLabel) {
                    widget.controller?.text = editedLabel;
                  }

                  // TODO: Update the label in your database here
                  _updateLabel(currentLabel, editedLabel);
                }
                Navigator.of(context).pop();
                _updateOverlay();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String label) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Label'),
          content: Text('Are you sure you want to delete "$label"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _suggestions.remove(label);
                  _filteredSuggestions = List.from(_suggestions);
                  _filteredSuggestions.add('Create New');
                });

                // Clear the field if it contains the deleted label
                if (widget.controller?.text == label) {
                  widget.controller?.clear();
                }

                // TODO: Delete the label from your database here
                _deleteLabel(label);

                Navigator.of(context).pop();
                _updateOverlay();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // TODO: Implement these methods to interact with your database
  Future<void> _saveNewLabel(String label) async {
    // Add your database save logic here
    print('Saving new label: $label');
  }

  Future<void> _updateLabel(String oldLabel, String newLabel) async {
    // Add your database update logic here
    print('Updating label from $oldLabel to $newLabel');
  }

  Future<void> _deleteLabel(String label) async {
    // Add your database delete logic here
    print('Deleting label: $label');
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: 170.w,
        height: 40.h,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            suffixIcon: Icon(
              _showSuggestions ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
          ),
        ),
      ),
    );
  }
}

/*
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
*/
