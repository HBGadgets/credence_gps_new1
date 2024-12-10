import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import '../model/trip_model.dart';

class TripLogProvider with ChangeNotifier {
  final storage = const FlutterSecureStorage();
  List<TripLog> _tripLogs = [];

  List<TripLog> get tripLogs => _tripLogs;

  // Future<void> fetchData() async {
  //   if (mounted) {
  //     setState(() {
  //       isLoading = true;
  //     });
  //   }
  //
  //   try {
  //     final deviceFuture = devicesListApi();
  //     final positionFuture = positionsListApi();
  //     final results = await Future.wait([deviceFuture, positionFuture]);
  //     if (mounted) {
  //       setState(() {
  //         devicesList = results[0];
  //         positionsList = results[1];
  //         filteredDevicesList = devicesList;
  //         searchController.addListener(_filterDevicess);
  //         _updateCounts();
  //         isLoading = false;
  //       });
  //       for (final device in filteredDevicesList) {
  //         await fetchTripLog(device['id']);  // Fetch trip log for each device
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   }
  // }
  Future<List<dynamic>> positionsListApi() async {
    final String liveApi = dotenv.env['LIVE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(liveApi),
          headers: {'Cookie': sessionCookies},
        );
        if (response.statusCode == 200) {
          print("statuscode00000 ${response.statusCode }");
          final List<dynamic> jsonResponse = json.decode(response.body);
          for (var item in jsonResponse) {
            if (item is Map<String, dynamic> && item.containsKey('deviceId')) {
              int deviceId = item['deviceId'] ?? 0;
              fetchTripLog(deviceId); // Fetch and sum distance for this device
            }
          }
          return jsonResponse;
        } else {
          print('Error fetching positions list');
        }
      } catch (error) {
        print('Error: $error');
      }
    }
    return [];
  }

  Future<void> fetchTripLog(int deviceId) async {
    final String tripApi = dotenv.env["TRIP_API"]!;
    DateTime currentDate = DateTime.now();
    String newDate = DateFormat("yyyy-MM-dd").format(currentDate);
    DateTime yesterday = currentDate.subtract(const Duration(days: 1));
    String yesterDayDate = DateFormat("yyyy-MM-dd").format(yesterday);
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final String carDetailsApiUrl =
          "$tripApi?deviceId=$deviceId&from=${yesterDayDate}T18:30:00.000Z&to=${newDate}T18:28:59.999Z";

      final response = await http.get(
        Uri.parse(carDetailsApiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        double todaysDistForDevice = 0.0;

        if (jsonResponse.isNotEmpty) {
          for (final carItem in jsonResponse) {
            todaysDistForDevice += carItem['distance'] / 1000; // Distance in KM
          }

          TripLog tripLog = TripLog(deviceId: deviceId, distance: todaysDistForDevice);
          _tripLogs.add(tripLog);
          print("todaysDistForDevice000 $_tripLogs");

          notifyListeners();
          print("todaysDistForDevice000 ${tripLog.distance}");
        }
      } else {
        print('Error fetching trip log for device $deviceId');
      }
    }
  }
}






class TripLogReportProvider with ChangeNotifier {
  List<Map<String, dynamic>> tripData = [];
  bool isLoading = true;
  final String tripApi = dotenv.env['TRIP_API']!;

  Future<void> fetchTripReportLog( int carID, String fromDate, String toDate, String sessionCookies) async {
    DateTime fromDateTime = DateTime.parse(fromDate);
    DateTime toDateTime = DateTime.parse(toDate);

    fromDateTime = fromDateTime.subtract(const Duration(hours: 5, minutes: 30));
    toDateTime = toDateTime.subtract(const Duration(hours: 5, minutes: 30));

    String fromAdjusted = '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(fromDateTime)}Z';
    String toAdjusted = '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(toDateTime)}Z';

    final apiUrl = '$tripApi?deviceId=$carID&from=$fromAdjusted&to=$toAdjusted';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        tripData = List<Map<String, dynamic>>.from(json.decode(response.body));
        await _processGeocoding();
      } else {
        throw Exception('Failed to load trips');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      isLoading = false;
      notifyListeners(); // Notify UI when data is loaded
    }
  }

  Future<void> _processGeocoding() async {
    List<Future<void>> reverseGeocodingTasks = [];

    for (var trip in tripData) {
      final startLat = double.parse(trip['startLat'].toStringAsFixed(2));
      final startLon = double.parse(trip['startLon'].toStringAsFixed(2));
      final endLat = double.parse(trip['endLat'].toStringAsFixed(2));
      final endLon = double.parse(trip['endLon'].toStringAsFixed(2));

      reverseGeocodingTasks.add(
          getAddressFromCoordinates(startLat, startLon).then((startAddress) {
            trip['startAddress'] = startAddress;
            notifyListeners(); // Notify when each address is updated
          })
      );

      reverseGeocodingTasks.add(
          getAddressFromCoordinates(endLat, endLon).then((endAddress) {
            trip['endAddress'] = endAddress;
            notifyListeners(); // Notify when each address is updated
          })
      );
    }

    await Future.wait(reverseGeocodingTasks);
  }

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    return "Sample Address"; // Placeholder
  }
}

