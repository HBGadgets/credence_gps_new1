import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapProvider extends ChangeNotifier {
  final storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  GoogleMapController? _controller;
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco coordinates
    zoom: 14,
  );
  CameraPosition get initialPosition => _initialPosition;

  Set<Marker> _markers = {};
  Set<Marker> get markers => _markers;

  Future<void> fetchLiveApi() async {
    final String liveApi = dotenv.env['LIVE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(liveApi),
          headers: {'Cookie': sessionCookies},
        );

        if (response.statusCode == 200) {
          _isLoading = false;
          notifyListeners();

          final List<dynamic> jsonResponse = json.decode(response.body);

          if (jsonResponse.isNotEmpty) {
            final List<Map<String, dynamic>> carDataList =
            jsonResponse.cast<Map<String, dynamic>>();

            for (var carData in carDataList) {
              print("ID: ${carData['id']}");
              print("Device ID: ${carData['deviceId']}");
              print("Protocol: ${carData['protocol']}");
              print("Server Time: ${carData['serverTime']}");
              print("Device Time: ${carData['deviceTime']}");
              print("Latitude: ${carData['latitude']}");
              print("Longitude: ${carData['longitude']}");
              print("Speed: ${carData['speed']}");
              print("Course: ${carData['course']}");

              // Print attributes
              final attributes = carData['attributes'];
              print("Ignition: ${attributes['ignition']}");
              print("Battery Level: ${attributes['batteryLevel']}");
              print("Distance: ${attributes['distance']}");
              print("Total Distance: ${attributes['totalDistance']}");
              print("Motion: ${attributes['motion']}");
              print("Status: ${attributes['status']}");

              _markers.add(
                Marker(
                  markerId: MarkerId(carData['id'].toString()),
                  position: LatLng(carData['latitude'], carData['longitude']),
                  infoWindow: InfoWindow(
                    title: "Car ID: ${carData['id']}",
                    snippet: "Speed: ${carData['speed']}, Status: ${attributes['status']}",
                  ),
                ),
              );
            }

            // Notify listeners to update the UI
            notifyListeners();
          }
        } else {
          print("Failed to load data: ${response.statusCode}");
        }
      } catch (error) {
        print("Error fetching data: $error");
      }
    } else {
      print("Session cookies missing.");
    }
  }


  void setController(GoogleMapController controller) {
    _controller = controller;
    notifyListeners();
  }
}
