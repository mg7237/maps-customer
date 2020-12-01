import 'package:customer/model.dart';
import 'package:flutter/material.dart';
import 'package:customer/map.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:customer/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer/alert_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool gotPermissions = false;
  bool logintoFirebase = true;
  bool tripStarted = false;
  int tripId = 25;
  LatLng driverLatLng;
  LatLng targetLatLng;
  // hardcoded, this should come to app via Flutter background process so that it is synchronized between Driver and Client apps

  String firebaseUID;

  void checkPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isUndetermined || status.isRestricted) {
      if (await Permission.locationWhenInUse.request().isGranted) {
        // Either the permission was already granted before or the user just granted it.
        gotPermissions = true;
        print("Permission Granted");
      } else {
        AlertDialogs(
            message: "Permission denied, cannot use this app",
            title: "Permission denied");
        print("Permission denied");
      }
    }

    if (await Permission.locationWhenInUse.serviceStatus.isEnabled) {
      // Use location.
      gotPermissions = true;
      print("Status enabled");
    } else {
      AlertDialogs(
          message:
              "Location service status is not enabled, please enable and ty again",
          title: "Location Status Off");
    }
    gotPermissions = true;
    setState(() {});
  }

  // void loginToFirebase() async {
  //   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  //   AuthResult result = await _firebaseAuth.signInWithEmailAndPassword(
  //       email: 'customer@lokesh.com', password: "Password1234");
  //   FirebaseUser user = result.user;
  //   firebaseUID = user.uid;
  //   logintoFirebase = true;
  //   setState(() {});
  // }

  void getDriverLocation() {
    final dbRefDriverLocation =
        FirebaseDatabase.instance.reference().child("driver_location");

    Query _driverLocationQuery =
        dbRefDriverLocation.orderByChild("tripId").equalTo(tripId);

    _driverLocationQuery.onChildAdded.listen((event) {
      DriverLocation _driverPosition =
          DriverLocation.fromSnapshot(event.snapshot);
      driverLatLng = LatLng(_driverPosition.lat, _driverPosition.long);
      targetLatLng =
          LatLng(_driverPosition.targetLat, _driverPosition.targetLong);
      if (targetLatLng != null) {
        tripStarted = true;
        setState(() {});
      }
    });
  }

  void doAsynTasks() async {
    await checkPermission();
    //await loginToFirebase();
    getDriverLocation();
  }

  @override
  void initState() {
    super.initState();
    doAsynTasks();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: (gotPermissions && logintoFirebase && tripStarted)
          ? MapScreen(
              tripId: tripId,
              driverLocation: driverLatLng,
              targetLatLng: targetLatLng)
          : TempPage(tripId),
    );
  }
}

class TempPage extends StatelessWidget {
  final tripId;
  TempPage(this.tripId);
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Awaiting $tripId trip to start"),
        ),
      ),
    );
  }
}
