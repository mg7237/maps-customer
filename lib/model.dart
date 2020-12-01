import 'package:firebase_database/firebase_database.dart';

class DriverLocation {
  String key;
  int tripId;
  double lat;
  double long;
  double targetLat;
  double targetLong;

  DriverLocation(
      {this.tripId,
      this.lat,
      this.long,
      this.targetLat,
      this.targetLong,
      this.key});

  DriverLocation.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        tripId = snapshot.value["tripId"],
        lat = snapshot.value["lat"],
        long = snapshot.value["long"],
        targetLat = snapshot.value["targetLat"],
        targetLong = snapshot.value["targetLong"];

  toJson() {
    return {
      "tripId": tripId,
      "lat": lat,
      "long": long,
      "targetLat": targetLat,
      "targetLong": targetLong,
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
