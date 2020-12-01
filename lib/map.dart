import 'package:flutter/material.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:customer/constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:customer/model.dart';
import 'package:customer/alert_dialog.dart';

class MapScreen extends StatefulWidget {
  final int tripId;
  final LatLng driverLocation;
  final LatLng targetLatLng;

  MapScreen({this.tripId, this.driverLocation, this.targetLatLng});
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double CAMERA_ZOOM = 18;
  static const double CAMERA_TILT = 0;
  static const double CAMERA_BEARING = 0;
  String status;

  final dbRefActiveDriver =
      FirebaseDatabase.instance.reference().child("active_driver");
  final dbRefDriverLocation =
      FirebaseDatabase.instance.reference().child("driver_location");
  int tripId;
  LatLng destLocation;
  LatLng driverLatLng;

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
// for my drawn routes on the map
  Map<PolylineId, Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints;
// for my custom marker pins
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;

// a reference to the destination location
  LocationData destinationLocation;
// wrapper around the location API
  Location location;
  String uid;
  ActiveDriver activeDriver;
  String activeDriverKey;
  String driverLocationKey;
  DriverLocation _driverPosition;

  void _startAsyncJobs() async {
    // Create new entry for trip start
    try {
      // create an instance of Location
      location = new Location();
      location.changeSettings(
          accuracy: LocationAccuracy.navigation, interval: 2000);

      // End target location hard coding

      polylinePoints = PolylinePoints();

      // subscribe to changes in the user's location
      // by "listening" to the location's onLocationChanged event

      Query _activeDriver =
          dbRefActiveDriver.orderByChild("tripId").equalTo(tripId);

      _activeDriver.onChildChanged.listen((event) {
        ActiveDriver newDriver = ActiveDriver.fromSnapshot(event.snapshot);
        if (newDriver.status == "COMPLETED") {
          status = "Delivery Complete";
          setState(() {});
        }
      });

      Query _driverLocationQuery =
          dbRefDriverLocation.orderByChild("tripId").equalTo(tripId);

      _driverLocationQuery.onChildAdded.listen((event) {
        _driverPosition = DriverLocation.fromSnapshot(event.snapshot);
        driverLatLng = LatLng(_driverPosition.lat, _driverPosition.long);
        updatePinOnMap();
      });

      // set custom marker pins
      setSourceAndDestinationIcons();
    } catch (e) {
      AlertDialogs alertDialogs =
          AlertDialogs(title: "Exception", message: "${e.toString()}");
      alertDialogs.asyncAckAlert(context);
    }
  }

  @override
  void initState() {
    super.initState();
    driverLatLng = widget.driverLocation;
    destLocation = widget.targetLatLng;
    destinationLocation = LocationData.fromMap({
      "latitude": destLocation.latitude,
      "longitude": destLocation.longitude,
    });
    // Create trip id
    tripId = widget.tripId;
    status = "Trip Started - $tripId";
    _startAsyncJobs();
  }

  void setSourceAndDestinationIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'assets/driving_pin.png');

    destinationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        'assets/destination_map_marker.png');
  }

  void showPinsOnMap() async {
    // get a LatLng for the source location
    // from the LocationData currentLocation object

    if (driverLatLng == null || destLocation == null) {
      await new Future.delayed(const Duration(seconds: 1));
    }
    var pinPosition = driverLatLng;

    // add the initial source location pin
    _markers.add(Marker(
        markerId: MarkerId('sourcePin'),
        position: pinPosition,
        icon: sourceIcon));
    // destination pin
    _markers.add(Marker(
        markerId: MarkerId('destPin'),
        position: destLocation,
        icon: destinationIcon));
    // set the route lines on the map from source to destination
    // for more info follow this tutorial
    setPolylines();
  }

  void setPolylines() async {
    polylineCoordinates = [];
    if (driverLatLng != null && destLocation != null) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          k_googleAPIKey,
          PointLatLng(driverLatLng.latitude, driverLatLng.longitude),
          PointLatLng(destLocation.latitude, destLocation.longitude),
          travelMode: TravelMode.driving);
      if (result.points.isNotEmpty) {
        result.points.forEach((PointLatLng point) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        });
        if (!this.mounted) {
          return;
        }
        setState(() {
          PolylineId id = PolylineId("poly");
          Polyline polyline = Polyline(
              polylineId: id, color: Colors.red, points: polylineCoordinates);
          _polylines[id] = polyline;
          // _polylines.add(Polyline(
          //     width: 5, // set the width of the polylines
          //     polylineId: PolylineId('poly'),
          //     color: Color(0xff287ac6),
          //     points: polylineCoordinates));
        });
      }
    }
  }

  void updatePinOnMap() async {
    // create a new CameraPosition instance
    // every time the location changes, so the camera
    // follows the pin as it moves with an animation
    // CameraPosition cPosition = CameraPosition(
    //   zoom: CAMERA_ZOOM,
    //   tilt: CAMERA_TILT,
    //   bearing: CAMERA_BEARING,
    //   target: LatLng(driverLatLng.latitude, driverLatLng.longitude),
    // );
    // final GoogleMapController controller = await _controller.future;

    if (!this.mounted) {
      return;
    }

    // do this inside the setState() so Flutter gets notified
    // that a widget update is due

    setState(() {
      //controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
      // updated driver position

      // the trick is to remove the marker (by id)
      // and add it again at the updated location
      _markers.removeWhere((m) => m.markerId.value == 'sourcePin');
      _markers.add(Marker(
          markerId: MarkerId('sourcePin'),
          position: driverLatLng, // updated position
          icon: sourceIcon));
    });
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition;
    if (driverLatLng != null) {
      initialCameraPosition = CameraPosition(
          target: LatLng(driverLatLng.latitude, driverLatLng.longitude),
          zoom: CAMERA_ZOOM,
          tilt: CAMERA_TILT,
          bearing: CAMERA_BEARING);
    }
    return Scaffold(
      appBar: AppBar(title: Text(status)),
      body: Stack(
        children: <Widget>[
          GoogleMap(
              myLocationEnabled: true,
              compassEnabled: true,
              tiltGesturesEnabled: true,
              markers: _markers,
              scrollGesturesEnabled: true,
              polylines: Set<Polyline>.of(_polylines.values),
              mapType: MapType.normal,
              initialCameraPosition: initialCameraPosition,
              onTap: (latLong) {
                _markers.removeWhere((m) => m.markerId.value == 'destPin');
                _markers.add(Marker(
                    markerId: MarkerId('destPin'),
                    position: latLong, // updated position
                    icon: destinationIcon));
                destLocation = LatLng(destinationLocation.latitude,
                    destinationLocation.longitude);
                setPolylines();
              },
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                // my map has completed being created;
                // i'm ready to show the pins on the map
                showPinsOnMap();
              })
        ],
      ),
    );
  }
}
