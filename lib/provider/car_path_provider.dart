import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CarPathProvider extends ChangeNotifier {
  List<LatLng> carPath = [];

  void updateCarPath(List<LatLng> newPath) {
    carPath = newPath;
    notifyListeners();
  }
}
