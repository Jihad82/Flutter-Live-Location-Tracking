import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationController extends GetxController {
  var currentPosition = Rx<LatLng?>(null);
  var markers = <String, Marker>{}.obs;
  var polylines = <String, Polyline>{}.obs; // New observable for polylines
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late GoogleMapController mapController;
  Location _location = Location();

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
    _location.onLocationChanged.listen((LocationData newLocation) {
      currentPosition.value = LatLng(newLocation.latitude!, newLocation.longitude!);
      _updateFirestore(newLocation);
    });
  }

  Future<void> _getCurrentLocation() async {
    LocationData currentLocationData = await _location.getLocation();
    currentPosition.value = LatLng(currentLocationData.latitude!, currentLocationData.longitude!);
    _updateFirestore(currentLocationData);
  }

  void updateLocation() {
    _getCurrentLocation();
  }

  void _updateFirestore(LocationData location) {
    String userId = _auth.currentUser!.uid;
    _firestore.collection('locations').doc(userId).set({
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
    updateMarkers();
  }

  void updateMarkers() {
    markers.clear();
    markers['myLocation'] = Marker(
      markerId: MarkerId('myLocation'),
      position: currentPosition.value ?? LatLng(0, 0),
      infoWindow: InfoWindow(title: 'My Location'),
    );

    getLocationStream().listen((snapshot) {
      for (var doc in snapshot.docs) {
        if (doc.id != _auth.currentUser!.uid) {
          var data = doc.data() as Map<String, dynamic>;
          markers[doc.id] = Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(data['latitude'], data['longitude']),
            infoWindow: InfoWindow(title: 'User: ${doc.id}'),
          );
        }
      }
    });
  }

  Stream<QuerySnapshot> getLocationStream() {
    return _firestore.collection('locations').snapshots();
  }

  // New method to add a polyline
  void addPolyline(LatLng otherUserLocation) {
    final polylineId = 'userTracking';
    polylines[polylineId] = Polyline(
      polylineId: PolylineId(polylineId),
      points: [currentPosition.value!, otherUserLocation], // Create a polyline between users
      color: Colors.red,
      width: 5,
    );
    update(); // Refresh the UI
  }
}
