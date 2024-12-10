import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login_screen.dart';

class DevicesProvider with ChangeNotifier {
  List<dynamic> _devices = [];
  bool _isLoading = false;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  List<dynamic> get devices => _devices;
  bool get isLoading => _isLoading;

  Future<void> fetchDevices(BuildContext context) async {
    final String deviceApi = dotenv.env['DEVICE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      _isLoading = true;
      notifyListeners();

      try {
        final response = await http.get(
          Uri.parse(deviceApi),
          headers: {'Cookie': sessionCookies},
        );

        if (response.statusCode == 200) {
          List<dynamic> fetchedDevices = json.decode(response.body);
          _devices.addAll(fetchedDevices);
          notifyListeners();
        } else {
          _handleError(context);
        }
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Error fetching devices. Please try again.",
          toastLength: Toast.LENGTH_SHORT,
        );
      } finally {
        _isLoading = false; // Stop loading
        notifyListeners();
      }
    } else {
      Fluttertoast.showToast(
        msg: "Session Expired. Redirecting to login.",
        toastLength: Toast.LENGTH_SHORT,
      );
      await storage.delete(key: "sessionCookies");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _handleError(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Failed to fetch devices. Please login again.",
      toastLength: Toast.LENGTH_SHORT,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }
}




