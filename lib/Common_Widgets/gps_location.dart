import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:location/location.dart';

/// This file contains the [LocationService] class and the [LocationButton] widget.
///
/// The [LocationService] class provides a method to retrieve the current location using the [Location] package.
/// The [getCurrentLocation] method returns a [LocationData] object representing the latitude and longitude of the current location.
///
/// The [LocationButton] widget displays a button with a GPS icon. When pressed, it fetches the current location using the [LocationService],
/// updates the [locationData] string, and calls the [onLocationFetched] callback with the latitude and longitude of the fetched location.
/// The [locationData] string is displayed below the button and shows the current location or an error message if the location fetch fails.
///
/// Example usage:
/// ```dart
/// //ADD THIS TO THE TOP OF THE FILE TO USE THE LOCATION SERVICE
/// final locationService = LocationService();
/// final currentLocation = await locationService.getCurrentLocation();
///
/// ElevatedButton(
///  onPressed: () async {
///    final currentLocation = await locationService.getCurrentLocation();
///    if (currentLocation != null) {
///      setState(() {
///        latitude = currentLocation.latitude!;
///        longitude = currentLocation.longitude!;
///      });
///    }
///  },
///  child: Text('Get Location'),
/// ),
/// ```

class LocationService {
  final Location _location = Location();

  Future<LocationData?> getCurrentLocation() async {
    try {
      return await _location.getLocation();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }
}

class LocationButton extends StatefulWidget {
  final Function(double, double) onLocationFetched;
  final double? latitude;
  final double? longitude;

  const LocationButton({
    super.key,
    required this.onLocationFetched,
    required this.latitude,
    required this.longitude,
  });

  @override
  createState() => _LocationButtonState();
}

class _LocationButtonState extends State<LocationButton> {
  final LocationService _locationService = LocationService();
  late String locationData;

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null &&
        widget.longitude != null &&
        widget.latitude! >= -90 &&
        widget.latitude! <= 90 &&
        widget.longitude! >= -180 &&
        widget.longitude! <= 180) {
      locationData = '${widget.latitude}, ${widget.longitude}';
    } else if (widget.latitude == null || widget.longitude == null) {
      locationData = 'No location data available. Press button to get location.';
    } else {
      locationData = 'Invalid location data. Press button to update.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            Icons.gps_fixed,
            color: Colors.lightBlue,
            size: 40.sp,
          ),
          onPressed: () async {
            final location = await _locationService.getCurrentLocation();
            if (location != null) {
              setState(() {
                locationData = '${location.latitude}, ${location.longitude}';
              });
              widget.onLocationFetched(location.latitude!, location.longitude!);
            } else {
              setState(() {
                locationData = 'Failed to fetch location';
              });
            }
          },
        ),
      ],
    );
  }
}

//ADD THIS TO THE TOP OF THE FILE TO USE THE LOCATION SERVICE
/*
final locationService = LocationService();
final currentLocation = await locationService.getCurrentLocation();

if (currentLocation != null) {
  print('Latitude: ${currentLocation.latitude}, Longitude: ${currentLocation.longitude}');
}*/

//HOW TO USE
/*
ElevatedButton(
  onPressed: () async {
    final currentLocation = await locationService.getCurrentLocation();
    if (currentLocation != null) {
      setState(() {
        latitude = currentLocation.latitude!;
        longitude = currentLocation.longitude!;
      });
    }
  },
  child: Text('Get Location'),
),
*/
