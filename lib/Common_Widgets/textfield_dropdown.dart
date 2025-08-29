import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:asset_inspections/Models/project_model.dart';
import 'package:asset_inspections/database_helper.dart';

class LabelTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const LabelTextField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  createState() => _LabelTextFieldState();
}

class _LabelTextFieldState extends State<LabelTextField> {
  List<String> _labels = [];
  List<String> _filteredLabels = [];
  bool _showDropdown = false;
  bool _isLoading = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
    widget.controller?.addListener(_onTextChanged);
    _scrollController = ScrollController();
    _loadLabels();
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    widget.controller?.removeListener(_onTextChanged);
    _scrollController?.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode!.hasFocus) {
      _showDropdownMenu();
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _hideDropdown();
        }
      });
    }
  }

  void _onTextChanged() {
    final text = widget.controller?.text.toLowerCase() ?? '';
    setState(() {
      _filteredLabels =
          _labels.where((label) => label.toLowerCase().contains(text)).toList();
    });

    if (_showDropdown) {
      _updateOverlay();
    }
  }

  Future<void> _loadLabels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectID = Provider.of<ProjectModel>(context, listen: false).id;
      final dbHelper = DatabaseHelper.instance;

      List<String> labels = await dbHelper.fetchLabelsForProject(projectID);

      setState(() {
        _labels = labels;
        _filteredLabels = List.from(_labels);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _labels = ['structure-port', 'structure-perm', 'port-perm'];
        _filteredLabels = List.from(_labels);
        _isLoading = false;
      });
    }
  }

  void _showDropdownMenu() {
    if (_overlayEntry != null) return;

    setState(() {
      _showDropdown = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    setState(() {
      _showDropdown = false;
    });
    _hideOverlay();
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _hideOverlay();
      // Reset scroll position when recreating overlay
      _scrollController?.dispose();
      _scrollController = ScrollController();
      _showDropdownMenu();
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    // Calculate available space below the text field
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double availableHeightBelow = screenHeight -
        position.dy -
        size.height -
        bottomPadding -
        20; // 20 for safe margin

    // Calculate available space above the text field
    final double availableHeightAbove = position.dy -
        MediaQuery.of(context).padding.top -
        20; // 20 for safe margin

    // Determine if we should show dropdown above or below
    final bool showAbove = availableHeightBelow < 150.h &&
        availableHeightAbove > availableHeightBelow;

    // Set maximum height based on available space
    final double maxAvailableHeight =
        showAbove ? availableHeightAbove : availableHeightBelow;
    final double maxHeight = maxAvailableHeight > 200.h
        ? 200.h
        : (maxAvailableHeight > 100.h ? maxAvailableHeight : 100.h);

    // Header height for management buttons
    final double headerHeight = 50.h;

    // Calculate content height (ensure it's never negative)
    // final double contentMaxHeight = (maxHeight - headerHeight).clamp(50.h, double.infinity);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: showAbove
              ? Offset(0.0, -maxHeight - 2.0) // Show above
              : Offset(0.0, size.height + 2.0), // Show below
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                minHeight: 100.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Management options header (fixed at top)
                  Container(
                    height: headerHeight,
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        topRight: Radius.circular(8.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildManagementButton(
                          icon: Icons.add,
                          label: 'Add',
                          color: Colors.green,
                          onTap: _showAddDialog,
                        ),
                        _buildManagementButton(
                          icon: Icons.edit,
                          label: 'Edit',
                          color: Colors.blue,
                          onTap: _showEditOptions,
                        ),
                        _buildManagementButton(
                          icon: Icons.more_horiz,
                          label: 'More',
                          color: Colors.orange,
                          onTap: _showMoreOptions,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Scrollable labels list
                  Expanded(
                    child: _isLoading
                        ? Padding(
                            padding: EdgeInsets.all(16.h),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : _filteredLabels.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(16.h),
                                child: const Text(
                                  'No labels found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : _filteredLabels.length > 5
                                ? Scrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding: EdgeInsets.zero,
                                      physics: const ClampingScrollPhysics(),
                                      itemCount: _filteredLabels.length,
                                      itemBuilder: (context, index) {
                                        final label = _filteredLabels[index];
                                        return _buildLabelItem(label);
                                      },
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredLabels.length,
                                    itemBuilder: (context, index) {
                                      final label = _filteredLabels[index];
                                      return _buildLabelItem(label);
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManagementButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: color),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelItem(String label) {
    final isDefault =
        ['structure-port', 'structure-perm', 'port-perm'].contains(label);

    return InkWell(
      onTap: () => _selectLabel(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
                  color: isDefault ? Colors.blue.shade700 : Colors.black,
                ),
              ),
            ),
            if (isDefault)
              Icon(
                Icons.star,
                size: 14.sp,
                color: Colors.amber,
              ),
          ],
        ),
      ),
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Labels',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              ..._labels
                  .where((label) => ![
                        'structure-port',
                        'structure-perm',
                        'port-perm'
                      ].contains(label))
                  .map(
                    (label) => ListTile(
                      title: Text(label),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditDialog(label);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteDialog(label);
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              if (_labels
                  .where((label) => ![
                        'structure-port',
                        'structure-perm',
                        'port-perm'
                      ].contains(label))
                  .isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No custom labels to edit'),
                ),
            ],
          ),
        );
      },
    ).then((_) {
      // Refresh the overlay when the bottom sheet closes
      if (_showDropdown && mounted) {
        _updateOverlay();
      }
    });
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.orange),
                title: const Text('Restore Default Labels'),
                subtitle: const Text('Remove all custom labels'),
                onTap: () {
                  Navigator.pop(context);
                  _showRestoreDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Close'),
                onTap: () {
                  Navigator.pop(context);
                  widget.focusNode?.unfocus();
                  _hideDropdown();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectLabel(String label) {
    widget.controller?.text = label;
    widget.focusNode?.unfocus();
    _hideDropdown();
  }

  void _showAddDialog() {
    final TextEditingController addController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Label'),
          content: TextField(
            controller: addController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Label Name',
              hintText: 'Enter new label name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newLabel = addController.text.trim();
                if (newLabel.isNotEmpty) {
                  Navigator.of(dialogContext).pop(); // Close dialog first

                  final success = await _addLabel(newLabel);
                  if (mounted) {
                    if (success) {
                      await _loadLabels();
                      setState(() {
                        // Force a complete rebuild
                      });
                      widget.controller?.text = newLabel;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Label "$newLabel" added successfully')),
                      );
                      _updateOverlay(); // Rebuild the overlay
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Label "$newLabel" already exists')),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
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
      builder: (BuildContext dialogContext) {
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final editedLabel = editController.text.trim();
                if (editedLabel.isNotEmpty && editedLabel != currentLabel) {
                  Navigator.of(dialogContext).pop(); // Close dialog first

                  final success = await _updateLabel(currentLabel, editedLabel);
                  if (mounted) {
                    if (success) {
                      await _loadLabels();
                      setState(() {
                        // Force a complete rebuild
                      });
                      if (widget.controller?.text == currentLabel) {
                        widget.controller?.text = editedLabel;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Label updated successfully')),
                      );
                      _updateOverlay(); // Rebuild the overlay
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String label) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Label'),
          content: Text('Are you sure you want to delete "$label"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog first

                final success = await _deleteLabel(label);
                if (mounted) {
                  if (success) {
                    await _loadLabels();
                    setState(() {
                      // Force a complete rebuild
                    });
                    if (widget.controller?.text == label) {
                      widget.controller?.clear();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Label "$label" deleted')),
                    );
                    _updateOverlay(); // Rebuild the overlay
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Restore Default Labels'),
          content: const Text(
              'This will remove all custom labels and restore only the default labels:\n\n'
              '• structure-port\n'
              '• structure-perm\n'
              '• port-perm\n\n'
              'Are you sure you want to continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog first

                await _restoreDefaults();
                if (mounted) {
                  await _loadLabels();
                  setState(() {
                    // Force a complete rebuild
                  });
                  widget.controller?.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Default labels restored')),
                  );
                  _updateOverlay(); // Rebuild the overlay
                }
              },
              child:
                  const Text('Restore', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _addLabel(String label) async {
    final projectID = Provider.of<ProjectModel>(context, listen: false).id;
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.addCustomLabel(projectID, label);
  }

  Future<bool> _updateLabel(String oldLabel, String newLabel) async {
    final projectID = Provider.of<ProjectModel>(context, listen: false).id;
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.updateCustomLabel(projectID, oldLabel, newLabel);
  }

  Future<bool> _deleteLabel(String label) async {
    final projectID = Provider.of<ProjectModel>(context, listen: false).id;
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.deleteCustomLabel(projectID, label);
  }

  Future<void> _restoreDefaults() async {
    final projectID = Provider.of<ProjectModel>(context, listen: false).id;
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.restoreDefaultLabels(projectID);
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
              _showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: Colors.grey.shade600,
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
*/

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
