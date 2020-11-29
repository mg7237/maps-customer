import 'package:firebase_database/firebase_database.dart';

class DriverLocation {
  String key;
  int tripId;
  double lat;
  double long;

  DriverLocation({this.tripId, this.lat, this.long});

  DriverLocation.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        tripId = snapshot.value["tripId"],
        lat = snapshot.value["lat"],
        long = snapshot.value["long"];

  toJson() {
    return {
      "tripId": tripId,
      "lat": lat,
      "long": long,
    };
  }
}

class ActiveDriver {
  String key;
  String status; // Use enum, currently hardcoded to Completed or Started
  int tripId;

  ActiveDriver({this.tripId, this.status});

  ActiveDriver.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        status = snapshot.value["status"],
        tripId = snapshot.value["tripId"];

  toJson() {
    return {"tripID": tripId, "status": status};
  }
}
