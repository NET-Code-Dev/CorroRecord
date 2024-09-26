import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;

  const FullScreenImageViewer({super.key, required this.imagePaths});

  @override
  createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Photo ${_currentIndex + 1} of ${widget.imagePaths.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagePaths.length,
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
            child: Image.file(
              File(widget.imagePaths[index]),
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
