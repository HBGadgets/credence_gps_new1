import 'package:flutter/material.dart';
class AddressProvider with ChangeNotifier {
  String _address = "";

  String get address => _address;

  void updateAddress(String newAddress) {
    _address = newAddress;
    notifyListeners();
  }
}