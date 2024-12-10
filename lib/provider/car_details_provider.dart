import 'package:flutter/material.dart';

class CarDetailsProvider with ChangeNotifier {
  List<dynamic>? _carDetails;

  List<dynamic>? get carDetails => _carDetails;

  void updateCarDetails(List<dynamic> details) {
    _carDetails = details;
    notifyListeners();

  }
}