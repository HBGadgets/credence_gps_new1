import 'package:flutter/foundation.dart';
import '../model/car_location.dart';

class CarLocationProviderNew extends ChangeNotifier {
  Map<int, CarLocation?> _carLocations = {};
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  Map<int, CarLocation?> get carLocations => _carLocations;

  void updateCarLocation(int carId, CarLocation location) {
    _carLocations[carId] = location;
    notifyListeners();
  }

  void resetCarLocation() {
    _carLocations = {};
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
