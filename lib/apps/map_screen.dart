import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart'; // For clipboard functionality

import 'LocationController.dart';

class MapScreen extends StatelessWidget {
  final LocationController locationController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Location Tracker')),
      body: Obx(() {
        if (locationController.currentPosition.value == null) {
          return Center(child: CircularProgressIndicator());
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: locationController.currentPosition.value!,
            zoom: 14,
          ),
          markers: Set<Marker>.of(locationController.markers.values),
          polylines: Set<Polyline>.of(locationController.polylines.values),
          onMapCreated: (controller) {
            locationController.mapController = controller;
            locationController.updateMarkers();
          },
        );
      }),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _zoomToUserLocation(locationController.mapController);
            },
            tooltip: 'Zoom to My Location',
            child: Icon(Icons.location_searching),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              _shareLocationUrl(context, locationController);
            },
            tooltip: 'Copy Location URL',
            child: Icon(Icons.share),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              _requestTrackingUrl(context);
            },
            tooltip: 'Track Another User',
            child: Icon(Icons.track_changes),
          ),
        ],
      ),
    );
  }

  void _zoomToUserLocation(GoogleMapController mapController) {
    final position = locationController.currentPosition.value;
    if (position != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 16,
        ),
      ));
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('Error: Unable to retrieve your location.')),
      );
    }
  }

  void _shareLocationUrl(BuildContext context, LocationController locationController) async {
    final lat = locationController.currentPosition.value?.latitude;
    final lng = locationController.currentPosition.value?.longitude;

    if (lat != null && lng != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      await Clipboard.setData(ClipboardData(text: url));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location URL Copied')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to retrieve location.')),
      );
    }
  }

  void _requestTrackingUrl(BuildContext context) async {
    TextEditingController urlController = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Location URL'),
          content: TextField(
            controller: urlController,
            decoration: InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _trackUser(urlController.text);
                Navigator.of(context).pop();
              },
              child: Text('Track'),
            ),
          ],
        );
      },
    );
  }

  void _trackUser(String url) {
    // Extract latitude and longitude from the URL
    RegExp regExp = RegExp(r'query=(-?\d+\.\d+),(-?\d+\.\d+)');
    Match? match = regExp.firstMatch(url);
    if (match != null) {
      double lat = double.parse(match.group(1)!);
      double lng = double.parse(match.group(2)!);
      LatLng otherUserLocation = LatLng(lat, lng);

      // Update polyline
      locationController.addPolyline(otherUserLocation);
    } else {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('Invalid URL. Please enter a valid maps URL.')),
      );
    }
  }
}
