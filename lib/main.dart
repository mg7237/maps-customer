import 'package:flutter/material.dart';
import 'package:customer/map.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:customer/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:customer/alert_dialog.dart';

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
  bool logintoFirebase = false;
  int tripId = 9992889;
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
    setState(() {});
  }

  void loginToFirebase() async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    AuthResult result = await _firebaseAuth.signInWithEmailAndPassword(
        email: 'customer@lokesh.com', password: "Password1234");
    FirebaseUser user = result.user;
    firebaseUID = user.uid;
    logintoFirebase = true;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    checkPermission();
    loginToFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: (gotPermissions && logintoFirebase)
          ? MapScreen(tripId: tripId)
          : TempPage(),
    );
  }
}

class TempPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Awaiting async jobs to complete"),
        ),
      ),
    );
  }
}
