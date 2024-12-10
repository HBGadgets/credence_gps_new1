import 'package:flutter/material.dart';

import '../model/car_location.dart';
class CarLocationProvider extends ChangeNotifier {
  List<CarLocation> carLocations = [];

  void addLocation(CarLocation location) {
    carLocations.add(location);
    notifyListeners();
  }

// Add any additional methods you may need for managing the location history.
}
