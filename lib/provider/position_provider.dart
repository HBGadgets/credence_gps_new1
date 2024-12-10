import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login_screen.dart';

class PositionsProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<dynamic> _positions = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<dynamic> get positions => _positions;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPositions(BuildContext context) async {
    const storage = FlutterSecureStorage();
    _isLoading = true;
    notifyListeners();

    final String liveApi = dotenv.env['LIVE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(liveApi),
          headers: {'Cookie': sessionCookies},
        );

        if (response.statusCode == 200) {
          _positions = json.decode(response.body);
        } else {
          _handleError(context);
        }
      } catch (error) {
        _errorMessage = error.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      Fluttertoast.showToast(
        msg: "Session expired, redirecting to login...",
        toastLength: Toast.LENGTH_SHORT,
      );
      await storage.delete(key: "sessionCookies");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );

      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleError(BuildContext context) {
    _errorMessage = "Failed to fetch positions";
    notifyListeners();
  }
}


class DevicePositionProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();

  List<dynamic> _devices = [];
  bool _isLoading = false;

  List<dynamic> get devices => _devices;
  bool get isLoading => _isLoading;

  Future<void> fetchDevicesList(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final String deviceApi = dotenv.env['DEVICE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(deviceApi),
          headers: {'Cookie': sessionCookies},
        );

        if (response.statusCode == 200) {
          _devices = json.decode(response.body);
          print("_devices $_devices");
          notifyListeners();
        } else {
          _devices = [];
        }
      } catch (error) {
        _devices = [];
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
    _isLoading = false;
    notifyListeners();
  }
}


class FetchDataProvider with ChangeNotifier {
  final DevicePositionProvider devicePositionProvider;
  final PositionsProvider positionsProvider;

  FetchDataProvider({
    required this.devicePositionProvider,
    required this.positionsProvider,
  });

  List<dynamic> get devicesList => devicePositionProvider.devices;
  List<dynamic> get positionsList => positionsProvider.positions;
  List<dynamic> filteredDevicesList = [];
  bool isLoading = false;
  final searchController = TextEditingController();

  Future<void> fetchData(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        devicePositionProvider.fetchDevicesList(context),
        positionsProvider.fetchPositions(context),
      ]);

      filteredDevicesList = devicesList;
      // searchController.addListener(() => _filterDevices());
      // _updateCounts();
      await Future.wait(filteredDevicesList.map((device) async {

      }));
    } catch (e) {
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

}

