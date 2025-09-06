// ignore_for_file: unused_local_variable, no_leading_underscores_for_local_identifiers, unused_element

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:asset_inspections/Models/project_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

import 'package:asset_inspections/database_helper.dart';

class CustomCamera extends StatefulWidget {
  final int projectID;
  final String projectClient;
  final String projectName;
  final int? stationID;
  final String? stationArea;
  final String? stationTSID;
  final int? rectifierID;
  final String? rectifierArea;
  final String? rectifierServiceTag;

  const CustomCamera({
    super.key,
    required this.projectID,
    required this.projectClient,
    required this.projectName,
    this.stationID,
    this.stationArea,
    this.stationTSID,
    this.rectifierID,
    this.rectifierArea,
    this.rectifierServiceTag,
  });

  static Future<List<String>?> navigateToCustomCamera(BuildContext context,
      int projectID, String projectClient, String projectName,
      {int? stationID,
      String? stationArea,
      String? stationTSID,
      int? rectifierID,
      String? rectifierArea,
      String? rectifierServiceTag}) async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => CustomCamera(
          projectID: projectID,
          projectClient: projectClient,
          projectName: projectName,
          stationID: stationID,
          stationArea: stationArea,
          stationTSID: stationTSID,
          rectifierID: rectifierID,
          rectifierArea: rectifierArea,
          rectifierServiceTag: rectifierServiceTag,
        ),
      ),
    );
    return result;
  }

  @override
  createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCamera>
    with WidgetsBindingObserver {
  List<String> capturedImagePaths = [];
  List<Uint8List> capturedImageBytes = []; // Store all captured images
  Uint8List? _thumbnailImageBytes;
  bool _isFlashVisible = false;
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  double _currentZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  ScreenshotController screenshotController = ScreenshotController();
  String?
      _currentFileName; // Store the current filename for consistent timestamps

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hideSystemUI();
    _initCamera();
  }

  @override
  void dispose() {
    _showSystemUI(); // Restore system UI when leaving camera
    _disposeCamera();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [
        SystemUiOverlay.top,
        SystemUiOverlay.bottom,
      ],
    );
  }

  Future<void> _disposeCamera() async {
    try {
      if (_controller != null) {
        if (_controller!.value.isInitialized) {
          // Add a small delay to allow surfaces to properly detach
          await Future.delayed(const Duration(milliseconds: 100));
          await _controller!.dispose();
        }
        _controller = null;
      }
    } catch (e) {
      // Suppress OpenGL and camera disposal errors - they're harmless
      if (kDebugMode &&
          !e.toString().contains('OpenGL') &&
          !e.toString().contains('libEGL')) {
        if (kDebugMode) {
          print("Error disposing camera: $e");
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    try {
      if (state == AppLifecycleState.inactive) {
        _disposeCamera();
      } else if (state == AppLifecycleState.resumed) {
        _hideSystemUI(); // Re-hide system UI when resuming
        _initializeCameraController(cameraController.description);
      }
    } catch (e) {
      // Suppress lifecycle-related camera errors
      if (kDebugMode &&
          !e.toString().contains('OpenGL') &&
          !e.toString().contains('libEGL')) {
        if (kDebugMode) {
          print("Camera lifecycle error: $e");
        }
      }
    }
  }

  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    try {
      // Dispose existing controller first
      await _disposeCamera();

      _controller = CameraController(
        cameraDescription,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing camera controller: $e");
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras[0],
          ResolutionPreset.max,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        _maxZoomLevel = await _controller!.getMaxZoomLevel();

        // Set initial zoom to a reasonable level for better preview
        await _controller!.setZoomLevel(1.0);

        if (!mounted) return;
        setState(() {});
      }
    } on CameraException catch (e) {
      String title;
      String message;

      switch (e.code) {
        case 'CameraAccessDenied':
          title = "Camera Permission Denied";
          message =
              "This app requires camera access to function. Please allow camera access for this app in your device's settings.";
          break;
        case 'CameraAccessDeniedWithoutPrompt':
          title = "Camera Access Previously Denied";
          message =
              "You have previously denied camera access for this app. Please enable camera access for this app in your device's Settings > Privacy > Camera.";
          break;
        case 'CameraAccessRestricted':
          title = "Camera Access Restricted";
          message =
              "Camera access is restricted and cannot be enabled for this app, possibly due to parental control settings.";
          break;
        default:
          title = "Unexpected Error";
          message =
              "An unexpected error occurred. Please try again or contact support if the problem persists.";
          break;
      }

      _showPermissionErrorDialog(title, message);
    } catch (e) {
      if (kDebugMode) {
        print("An unexpected error occurred: $e");
      }
    }
  }

  Future<void> _saveImagePathToDatabase(String imagePath) async {
    final dbHelper = DatabaseHelper.instance;
    int? stationID = widget.stationID;

    if (stationID != null) {
      var currentTestStation = await dbHelper.queryTestStationBytsID(
          widget.projectID, widget.stationTSID!);
      String currentPicturePath = currentTestStation?['picturePath'] ?? '';

      String updatedPicturePath = currentPicturePath.isEmpty
          ? imagePath
          : '$currentPicturePath,$imagePath';

      await dbHelper.updateTestStationPicture(stationID, updatedPicturePath);
    }
  }

  Future<void> _removeImageFromDatabase(String imagePath) async {
    final dbHelper = DatabaseHelper.instance;
    int? stationID = widget.stationID;

    if (stationID != null) {
      var currentTestStation = await dbHelper.queryTestStationBytsID(
          widget.projectID, widget.stationTSID!);
      String currentPicturePath = currentTestStation?['picturePath'] ?? '';

      List<String> pathList = currentPicturePath.split(',');
      pathList.removeWhere((path) => path.trim() == imagePath.trim());

      String updatedPicturePath = pathList.join(',');
      await dbHelper.updateTestStationPicture(stationID, updatedPicturePath);
    }
  }

  void _captureImageWithOverlay() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      // Generate filename before capture
      String currentFileName = _generateFileName();

      setState(() {
        _currentFileName = currentFileName;
        _isFlashVisible = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));

      final imageFile = await screenshotController.capture();
      if (imageFile != null) {
        setState(() {
          _thumbnailImageBytes = imageFile;
          _isFlashVisible = true;
          _currentFileName = null; // Hide overlay after capture
        });

        // Use the stored filename instead of the null _currentFileName
        final imageInfo = await _saveImageToFile(imageFile, currentFileName);
        await _saveImagePathToDatabase(imageInfo['path']!);

        setState(() {
          _isFlashVisible = false;
          capturedImagePaths.add(imageInfo['path']!);
          capturedImageBytes.add(imageFile);
        });

        if (kDebugMode) {
          print("Image captured: ${imageInfo['name']}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error capturing image: $e");
      }
      setState(() {
        _isFlashVisible = false;
        _currentFileName = null;
      });
    }
  }

  Future<void> _deleteImage(int index) async {
    if (index >= 0 && index < capturedImagePaths.length) {
      String pathToDelete = capturedImagePaths[index];

      // Remove from database
      await _removeImageFromDatabase(pathToDelete);

      // Delete physical file
      try {
        Directory? directory = await getExternalStorageDirectory();
        String newPath = '';
        List<String> folders = directory!.path.split('/');
        for (int x = 1; x < folders.length; x++) {
          String folder = folders[x];
          if (folder != "Android") {
            newPath += "/$folder";
          } else {
            break;
          }
        }
        newPath = "$newPath/Download/$pathToDelete";

        File fileToDelete = File(newPath);
        if (await fileToDelete.exists()) {
          await fileToDelete.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error deleting physical file: $e");
        }
      }

      // Remove from local lists
      setState(() {
        capturedImagePaths.removeAt(index);
        capturedImageBytes.removeAt(index);

        // Update thumbnail to show the last captured image, or null if no images
        if (capturedImageBytes.isNotEmpty) {
          _thumbnailImageBytes = capturedImageBytes.last;
        } else {
          _thumbnailImageBytes = null;
        }
      });

      if (kDebugMode) {
        print("Image deleted: $pathToDelete");
      }
    }
  }

  Future<Map<String, String>> _saveImageToFile(
      Uint8List imageBytes, String fileName) async {
    Directory? directory;
    try {
      directory = await getExternalStorageDirectory();
      String newPath = '';
      List<String> folders = directory!.path.split('/');
      for (int x = 1; x < folders.length; x++) {
        String folder = folders[x];
        if (folder != "Android") {
          newPath += "/$folder";
        } else {
          break;
        }
      }
      newPath =
          "$newPath/Download/${widget.projectClient}_${widget.projectName}";
      directory = Directory(newPath);
    } catch (e) {
      directory = await getApplicationDocumentsDirectory();
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageBytes);

    // Create relative path for database storage
    String relativePath =
        "${widget.projectClient}_${widget.projectName}/$fileName";

    return {
      'path': relativePath, // Store relative path in database
      'name': fileName,
      'fullPath': file.path // Keep full path for reference if needed
    };
  }

  String _generateFileName() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    String timestamp = formatter.format(DateTime.now());

    if (widget.stationID != null) {
      return "${widget.stationID}_$timestamp.png";
    } else {
      return "${widget.rectifierServiceTag}_$timestamp.png";
    }
  }

  void _showPermissionErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextOverlay() {
    // Only show overlay when capturing (when _currentFileName is set)
    if (_currentFileName == null) {
      return const SizedBox.shrink();
    }

    String displayText = _currentFileName!.replaceAll('.png', '');

    return Positioned(
      bottom: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _cameraWithOverlay() {
    // Calculate the screen aspect ratio
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return GestureDetector(
      onScaleUpdate: (ScaleUpdateDetails details) {
        _onScaleUpdate(details);
      },
      child: Stack(
        children: [
          // Full screen camera preview with proper aspect ratio handling
          Container(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          _buildTextOverlay(),
          Positioned.fill(
            child: _buildFlashAnimation(),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashAnimation() {
    return AnimatedOpacity(
      opacity: _isFlashVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 50),
      child: Container(
        color: Colors.white,
      ),
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    const double sensitivityFactor = 0.05;
    final double scaleDelta = details.scale - 1;

    double newZoomLevel = _currentZoomLevel + (scaleDelta * sensitivityFactor);
    newZoomLevel = newZoomLevel.clamp(1.0, _maxZoomLevel);

    if ((newZoomLevel - _currentZoomLevel).abs() > 0.01) {
      setState(() {
        _currentZoomLevel = newZoomLevel;
      });
      _controller?.setZoomLevel(_currentZoomLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        try {
          // Restore system UI before navigation
          _showSystemUI();

          // Dispose camera properly before navigation
          WidgetsBinding.instance.removeObserver(this);
          await _disposeCamera();

          if (context.mounted) {
            Navigator.of(context).pop(result);
          }
        } catch (e) {
          // Ensure navigation happens even if disposal fails
          if (context.mounted) {
            Navigator.of(context).pop(result);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0.01.sh),
          child: AppBar(backgroundColor: Colors.black),
        ),
        body: Column(
          children: [
            Expanded(
              child: Screenshot(
                controller: screenshotController,
                child: _controller == null || !_controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : ClipRect(child: _cameraWithOverlay()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_thumbnailImageBytes != null)
                    SizedBox(
                      height: 90,
                      width: 65,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DisplayCapturedImagesScreen(
                                imageBytesList: capturedImageBytes,
                                imagePaths: capturedImagePaths,
                                onDeleteImage: _deleteImage,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Image.memory(
                              _thumbnailImageBytes!,
                              width: 65,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                            if (capturedImageBytes.length > 1)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${capturedImageBytes.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      height: 90,
                      width: 65,
                    ),
                  FloatingActionButton(
                    heroTag: "capture_button", // Unique hero tag
                    backgroundColor: Colors.black,
                    onPressed: _captureImageWithOverlay,
                    tooltip: 'Capture Image',
                    child: Icon(
                      Icons.camera,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: "back_button", // Unique hero tag
                    backgroundColor: Colors.black,
                    onPressed: () async {
                      try {
                        // Restore system UI before navigation
                        _showSystemUI();

                        // Properly dispose camera before navigating back
                        WidgetsBinding.instance.removeObserver(this);
                        await _disposeCamera();
                        if (context.mounted) {
                          Navigator.of(context).pop(capturedImagePaths);
                        }
                      } catch (e) {
                        // Ensure navigation happens even if disposal fails
                        if (context.mounted) {
                          Navigator.of(context).pop(capturedImagePaths);
                        }
                      }
                    },
                    tooltip: 'Back',
                    child: Icon(
                      Icons.arrow_back,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayCapturedImagesScreen extends StatefulWidget {
  final List<Uint8List> imageBytesList;
  final List<String> imagePaths;
  final Function(int) onDeleteImage;

  const DisplayCapturedImagesScreen({
    super.key,
    required this.imageBytesList,
    required this.imagePaths,
    required this.onDeleteImage,
  });

  @override
  createState() => _DisplayCapturedImagesScreenState();
}

class _DisplayCapturedImagesScreenState
    extends State<DisplayCapturedImagesScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                widget.onDeleteImage(_currentIndex);

                // Navigate back if no more images
                if (widget.imageBytesList.length <= 1) {
                  Navigator.of(context).pop();
                } else {
                  // Adjust current index if necessary
                  if (_currentIndex >= widget.imageBytesList.length - 1) {
                    setState(() {
                      _currentIndex = widget.imageBytesList.length - 2;
                    });
                    _pageController.animateToPage(
                      _currentIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageBytesList.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('No Images'),
        ),
        body: Center(
          child: Text(
            'No images to display',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
            'Photo ${_currentIndex + 1} of ${widget.imageBytesList.length}'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
            tooltip: 'Delete Image',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageBytesList.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: false,
            boundaryMargin: EdgeInsets.all(20.sp),
            minScale: 0.5,
            maxScale: 4,
            child: Image.memory(
              widget.imageBytesList[index],
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
