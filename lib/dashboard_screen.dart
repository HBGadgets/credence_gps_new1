import 'dart:math';
import 'package:credence/about_us.dart';
import 'package:credence/data_screen.dart';
import 'package:credence/feedback.dart';
import 'package:credence/help_screen.dart';
import 'package:credence/invite_friend.dart';
import 'package:credence/privacy_policy.dart';
import 'package:credence/provider/car_address_provider.dart';
import 'package:credence/provider/notification_provider.dart';
import 'package:credence/rate_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/io.dart';
import 'admin/admin_page.dart';
import 'all_vehicle_live.dart';
import 'change_password.dart';
import 'edit_profile.dart';
import 'login_screen.dart';


class Dashboard extends StatefulWidget {
  final int userId;

  const Dashboard({super.key, required this.userId});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class CarDetails {
  DateTime lastUpdate;
  double latitude;
  double longitude;
  double odometer;
  double odometerValueN;
  double? mileage;
  String carAddress;
  int id;
  Map<String, dynamic> attributes;
  int deviceId;
  double speed;
  bool valid;
  bool ignition;
  String vehicleType;
  String vehicleName;
  int battery;
  String status;
  final int groupId;
  final int positionId;

  CarDetails({
    required this.lastUpdate,
    required this.latitude,
    required this.longitude,
    required this.odometer,
    this.mileage,
    required this.carAddress,
    required this.attributes,
    required this.id,
    required this.deviceId,
    required this.speed,
    required this.valid,
    required this.ignition,
    required this.vehicleType,
    required this.vehicleName,
    required this.battery,
    required this.status,
    required this.groupId,
    required this.positionId,
    this.odometerValueN = 0.0,
  });
  factory CarDetails.fromJson(Map<String, dynamic> json) {
    return CarDetails(
      id: json['id'],
      attributes: json['attributes'],
      deviceId: json['deviceId'],
      valid: json['valid'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      speed: json['speed'],
      // lastUpdate: DateTime.parse(json['fixTime']),
      lastUpdate: DateTime.parse(json['lastUpdate']),
      odometer: json['attributes']['totalDistance'] / 1000,
      mileage: json['attributes']['MILEAGE'],
      carAddress: '',
      ignition: json['attributes']['ignition'],
      vehicleType: json['category'] ?? "default",
      vehicleName: json['name'] ?? "default,",
      battery: json['attributes']['batteryLevel'],
      status: json['status'],
      groupId : json['groupId'],
      positionId: json['positionId'],
    );
  }
}

class _DashboardState extends State<Dashboard> {
  String currentDate = '';
  late Timer _timer;
  Map<String, dynamic>? carDetails;
  final storage = const FlutterSecureStorage();
  final TextEditingController usernameController = TextEditingController();
  String carAddress = "";
  late GoogleMapController mapController;
  LatLng carLocation = const LatLng(0, 0);
  late BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool showIdle = false;
  bool showStop = false;
  bool showRunning = false;
  bool showOverSpeed = false;
  bool showActive = false;
  bool showInactive = false;

  bool showAllCars = true;
  TextEditingController searchController = TextEditingController();
  List<CarDetails> carDetailsList = [];
  bool isSearchActive = false;
  List<Map<String, dynamic>> EventsDataList = [];
  List<int> deviceIds = [];
  String totalRunningTime = "0.0";
  String MyName = '';
  String? phone = '';
  String todaysDistance = '';
  final ScrollController _scrollController = ScrollController();
  int _currentMax = 5;
  final String deviceApi = dotenv.env['DEVICE_API']!;
  final String positionsApi = dotenv.env['LIVE_API']!;
  final String NotificationApi = dotenv.env['NOTIFICATION_API']!;
  int ID = 0;
  double mileage = 0.0;
  double fuelUsed = 0.0;

  Map<String, int> carCounts = {
    'All': 0,
    'Idle': 0,
    'Stop': 0,
    'Running': 0,
    'OverSpeed': 0,
    'Active': 0,
    'Inactive': 0,
  };

  final List<IconData> cardIcons = [
    Icons.home,
    Icons.map,
    Icons.help,
    Icons.person_2_outlined,
  ];

  final List<Color> iconColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
  ];

  int selectedIndex = 0;


  @override
  void initState() {
    fetchCarDetails();
    super.initState();
    groupListApi();
    _scrollController.addListener(_scrollListener);
    updateCurrentDate();
    userData();
    _startAutoRefresh();
  }
  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      fetchCarDetails();
    });
  }

  List<double> distances = [];
  List<double> totalDistances = [];
  List<String> addressList = [];
  List<Map<String, dynamic>> distancesList = [];
  Map<int, double> distancesMap = {};
  Map<int, double> totalDistancesMap = {};
  double odometerValueN = 0.0;


  Future<void> fetchCarDetails() async {
    try {
      final String? sessionCookies = await storage.read(key: "sessionCookies");
      if (sessionCookies != null) {
        await fetchDeviceList(sessionCookies);  // Separate the first API call
        connectWebSocket(sessionCookies);       // Handle WebSocket connection separately
      } else {
        _handleSessionExpired();                // Handle session expiration
      }
    } catch (e) {
      // Handle the error
      print(e.toString());
    }
  }

  Future<void> fetchDeviceList(String sessionCookies) async {
    final deviceListResponse = await http.get(
      Uri.parse(deviceApi),
      headers: {'Cookie': sessionCookies},
    );

    if (deviceListResponse.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      final List<dynamic> deviceList = json.decode(deviceListResponse.body);
      carDetailsList = [];
      for (var deviceData in deviceList) {
        int deviceId = deviceData['id'] ?? 0;
        int groupIdDevices = deviceData['groupId'] ?? 0;
        String vehicleName = deviceData['name'] ?? "car";
        String vehicleType = deviceData['category'] ?? "car";
        String status = deviceData['status'] ?? "online";
        int positionId = deviceData['positionId'] ?? 0;
        String lastUpdateNew = deviceData['lastUpdate'] ?? "";
        DateTime dateUpdate;
        try {
          dateUpdate = DateTime.parse(lastUpdateNew);
        } catch (e) {
          dateUpdate = DateTime(0);
        }

        Map<String, dynamic> attributes = {
          "status": 70,
          "ignition": true,
          "charge": true,
          "blocked": false,
          "batteryLevel": 100,
          "rssi": 4,
          "distance": distancesMap[deviceId] ?? 0.0,
          "totalDistance": totalDistancesMap[deviceId] ?? 0.0,
          "motion": false,
          "sat": 15,
          "hours": 161159000,
        };

        // Add the device details to carDetailsList
        carDetailsList.add(
          CarDetails(
            mileage: mileage,
            lastUpdate: dateUpdate,
            latitude: 0.0,
            longitude: 0.0,
            odometer: 0.0,
            carAddress: "Unknown",
            attributes: attributes,
            id: deviceId,
            deviceId: deviceId,
            speed: 0.0,
            valid: false,
            ignition: false,
            vehicleType: vehicleType,
            vehicleName: vehicleName,
            battery: 0,
            status: status,
            groupId: groupIdDevices,
            positionId: positionId,
          ),
        );
      }
    } else {
      _handleSessionExpired();
    }
  }

  Future<void> fetchPositionDetails(int deviceId, String sessionCookies) async {
    final deviceDetailsResponse = await http.get(
      Uri.parse("$deviceApi/$deviceId"),
      headers: {'Cookie': sessionCookies},
    );

    if (deviceDetailsResponse.statusCode == 200) {
      final deviceDetailsJson = json.decode(deviceDetailsResponse.body);
      int groupIdDevices = deviceDetailsJson['groupId'] ?? 0;
      String vehicleName = deviceDetailsJson['name'];
      String vehicleType = deviceDetailsJson['category'] ?? "";
      String status = deviceDetailsJson['status'];
      int positionId = deviceDetailsJson['positionId'];
      String dateUpdateString = deviceDetailsJson['lastUpdate'] ?? "00/00/0000";
      DateTime dateUpdate;

      try {
        dateUpdate = DateTime.parse(dateUpdateString);
      } catch (e) {
        dateUpdate = DateTime(0);
      }

      final existingCarIndex =
      carDetailsList.indexWhere((car) => car.vehicleName == vehicleName);
      if (existingCarIndex != -1) {
        setState(() {
          carDetailsList[existingCarIndex] = CarDetails(
            mileage: mileage,
            lastUpdate: dateUpdate,
            latitude: 0.0,
            longitude: 0.0,
            odometer: 0.0,
            carAddress: "Unknown",
            attributes: {}, // Add correct attributes here
            id: deviceId,
            deviceId: deviceId,
            speed: 0.0,
            valid: false,
            ignition: false,
            vehicleType: vehicleType,
            vehicleName: vehicleName,
            battery: 0,
            status: status,
            groupId: groupIdDevices,
            positionId: positionId,
          );
        });
      }
    }else{
        _handleSessionExpired();
    }
  }

  void connectWebSocket(String sessionCookies) {
    final String webSocketUrl = dotenv.env['WEB_SOCKET']!;
    final channel = IOWebSocketChannel.connect(
      webSocketUrl,
      headers: {'Cookie': sessionCookies},
    );

    channel.stream.listen((dynamic message) async {
      final Map<String, dynamic> data = json.decode(message);
      if (data.containsKey('positions')) {
        final List<Map<String, dynamic>> positions =
        List<Map<String, dynamic>>.from(data['positions']);
        for (var positionData in positions) {
          int deviceId = positionData['deviceId'] ?? 0;

          double latitude = positionData['latitude'] ?? 0.0;
          double longitude = positionData['longitude'] ?? 0.0;
          String address = await getAddress(latitude, longitude);
          double speed = positionData['speed'] ?? 0.0;
          await _fetchGeofences(latitude, longitude, deviceId, speed);
          fetchTripLog(deviceId);
          fetchSummaryLog(deviceId);
          await fetchPositionDetails(deviceId, sessionCookies);
        }
      }
    });
  }

  void _handleSessionExpired() async {
    Fluttertoast.showToast(
      msg: "Session expired, redirecting to login...",
      toastLength: Toast.LENGTH_SHORT,
    );
    await storage.delete(key: "sessionCookies");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }


  Future<void> fetchTripLog(int deviceId) async {
    final String tripApi = dotenv.env["TRIP_API"]!;
    DateTime currentDate = DateTime.now();
    String newDate = DateFormat("yyyy-MM-dd").format(currentDate);
    DateTime yesterday = currentDate.subtract(const Duration(days: 1));

    // Format yesterday's date
    String yesterDayDate = DateFormat("yyyy-MM-dd").format(yesterday);

    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final String carDetailsApiUrl =
          "$tripApi?deviceId=${deviceId}&from=${yesterDayDate}T18:30:00.000Z&to=${newDate}T18:28:59.999Z";
      final response = await http.get(
        Uri.parse(carDetailsApiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          double totalDistance = 0.0; // Initialize total distance
          for (final carItem in jsonResponse) {
            totalDistance += carItem['distance'] / 1000; // Convert to kilometers
          }

          setState(() {
            final carIndex = carDetailsList.indexWhere((car) => car.deviceId == deviceId);
            if (carIndex != -1) {
              carDetailsList[carIndex].odometerValueN = totalDistance; // Set total distance
            }
          });
        }
      } else {
      }
    }
  }


  Future<void> fetchSummaryLog(int deviceId) async {
    final String summaryApi = dotenv.env["SUMMARY_API"]!;
    DateTime currentDate = DateTime.now();
    String newDate = DateFormat("yyyy-MM-dd").format(currentDate);
    DateTime yesterday = currentDate.subtract(const Duration(days: 1));

    // Format yesterday's date
    String yesterDayDate = DateFormat("yyyy-MM-dd").format(yesterday);

    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final String carDetailsApiUrl =
          "$summaryApi?deviceId=${deviceId}&from=${yesterDayDate}T18:30:00.000Z&to=${newDate}T18:28:59.999Z";
      final response = await http.get(
        Uri.parse(carDetailsApiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
      print("response000 $jsonResponse");
      } else {
      }
    }
  }




  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Reached the bottom of the list
      setState(() {
        // Increase the maximum index to display by adding 5
        _currentMax += 5;
        // Ensure _currentMax does not exceed the total number of devices
        _currentMax = min(_currentMax, carDetailsList.length);
      });
    }
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog(
      //show confirm dialogue
      //the return value will be from "Yes" or "No" options
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade300,
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
              fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        content: Text(
          'Are you sure you want to Logout?',
          style: GoogleFonts.poppins(
              fontSize: 13.0, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
                side: const BorderSide(color: Colors.black),
              ),
              backgroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No',
                style: GoogleFonts.poppins(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
                side: const BorderSide(color: Colors.black),
              ),
              backgroundColor: Colors.black,
            ),
            onPressed: () {
              _performLogout(context);
            },
            //return true when click on "Yes"
            child: Text('Yes',
                style: GoogleFonts.poppins(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context) async {
    // Clear session data (e.g., session cookies).
    const storage = FlutterSecureStorage();
    await storage.delete(key: "sessionCookies");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
    Fluttertoast.showToast(
      msg: "Logout Successful",
      toastLength: Toast.LENGTH_SHORT,
    );
  }
  List<CarDetails> unfilteredCarDetailsList = [];
  List<String> notifiedEvents = [];

  Future<void> EventNotification(List<int> deviceIds) async {
    DateTime currentDate = DateTime.now();
    String newDate = DateFormat("yyyy-MM-dd").format(currentDate);
    DateTime yesterday = currentDate.subtract(const Duration(days: 1));

    String yesterDayDate = DateFormat("yyyy-MM-dd").format(yesterday);

    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      for (int deviceId in List<int>.from(deviceIds)) {
        final String apiUrl =
            "$NotificationApi?deviceId=$deviceId&from=${yesterDayDate}T18:30:00.000Z&to=${newDate}T18:28:59.999Z&type=allEvents";
        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {
            'Cookie': sessionCookies,
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          if (jsonResponse.isNotEmpty) {
            final latestEvent = jsonResponse.last;
            final String eventType = latestEvent['type'];
            String eventTime = latestEvent['eventTime'];
            final int deviceId = latestEvent['deviceId'];
            final int geofenceId = latestEvent[
                'geofenceId'];

            final geofenceapiUrl = dotenv.env['GEOFENCE_API']!;

            final geofenceResponse = await http.get(
              Uri.parse(geofenceapiUrl),
              headers: {
                'Cookie': sessionCookies,
              },
            );
            final geoResponse = json.decode(geofenceResponse.body);

            final deviceApiUrl = "$deviceApi/$deviceId";

            final deviceResponse = await http.get(
              Uri.parse(deviceApiUrl),
              headers: {
                'Cookie': sessionCookies,
              },
            );
            final device = json.decode(deviceResponse.body);
            final deviceName = device['name'];

            // Convert event time to Indian local time by adding 5 hours and 30 minutes
            DateTime indianEventTime = DateTime.parse(eventTime)
                .add(const Duration(hours: 5, minutes: 30));
            String indianFormattedEventTime =
                DateFormat('yyyy-MM-dd HH:mm:ss').format(indianEventTime);

            // Construct event message
            String eventMessage =
                '$eventType occurred at $indianFormattedEventTime';

            // If geofenceId is not zero, get the geofence name from the response
            if (geofenceId != 0) {
              for (var geofence in geoResponse) {
                if (geofence['id'] == geofenceId) {
                  String geofenceName = geofence['name'];
                  eventMessage += ' in $geofenceName';
                  break;
                }
              }
            }

            // Check if the event occurred within the last half hour
            DateTime eventDateTime = DateTime.parse(eventTime);
            if (currentDate.difference(eventDateTime).inMinutes <= 2) {
              // Check if the latest event has already been notified
              if (!notifiedEvents.contains(eventMessage)) {
                // Show the notification
                showNotification(eventMessage, '$deviceName');
                // Update the list of notified events
                notifiedEvents.add(eventMessage);
              }
            }
          }
        } else {
          // Handle error if the request is not successful
        }
      }
    }
  }

  void showNotification(String message, String header) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Cancel any previously scheduled notifications
    await flutterLocalNotificationsPlugin.cancelAll();

    // Define the big text style for the notification
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      message,
      htmlFormatBigText: true,
      contentTitle: header,
    );

    // Define the notification details with the big text style
    AndroidNotificationDetails androidPlatformChannelSpecificsBigText =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation,
    );

    // Create a notification details object with the big text style
    NotificationDetails platformChannelSpecificsBigText =
        NotificationDetails(android: androidPlatformChannelSpecificsBigText);

    // Show the new notification with big text style
    flutterLocalNotificationsPlugin.show(
      0,
      header,
      message,
      platformChannelSpecificsBigText,
      payload: 'item x',
    );

    // Update the notification provider
    Provider.of<NotificationProvider>(context, listen: false)
        .setNewNotification('New Event', message);
  }

  Map<PolylineId, Polyline> _polylines = {};
  String? _etaText;
  Map<LatLng, String> geofencePointsWithNames = {};
  Map<CircleId, Circle> _circles = {};

  Future<void> _fetchGeofences(double latitude, double longitude, int deviceId, double speed) async {
    final String geofenceApi = dotenv.env['GEOFENCE_API']!;
    final String apiUrl = "$geofenceApi?deviceId=${deviceId}";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Cookie': sessionCookies},
        );
        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          List<LatLng> allGeofencePoints = [];
          geofencePointsWithNames.clear(); // Clear previous data
          for (var geoJson in jsonResponse) {
            final String area = geoJson['area'];
            final String name = geoJson['name']; // Assuming 'name' is a field in the response
            final List<LatLng> geofencePoints = parsePolygon(area);
            allGeofencePoints.addAll(geofencePoints);
            for (var point in geofencePoints) {
              geofencePointsWithNames[point] = name;
            }
            _addPolyline(geofencePoints);
            _addCircles(geofencePoints);
            LatLng currentLocation = LatLng(latitude, longitude);
            LatLng? nearestGeofence = _findNearestGeofence(currentLocation, geofencePoints);
            if (nearestGeofence != null) {
              double distance = _calculateDistance(currentLocation, nearestGeofence);
              double averageSpeed = speed;
              Duration eta = _calculateETA(distance, averageSpeed);
              String etaFormatted = eta.toString().split('.').first.padLeft(8, "0");
              setState(() {
                _etaText = etaFormatted;
              });
              String nearestGeofenceName = geofencePointsWithNames[nearestGeofence] ?? 'Unknown';
            } else {
              setState(() {
                _etaText = '00:00:00';
              });
            }
          }
        } else {
        }
      } catch (error) {
      }
    } else {
    }
  }
  LatLng? _findNearestGeofence(LatLng currentLocation, List<LatLng> geofencePoints) {
    double minDistance = double.infinity;
    LatLng? nearestPoint;

    for (var point in geofencePoints) {
      double distance = _calculateDistance(currentLocation, point);
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = point;
      }
    }

    return nearestPoint;
  }
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }
  void _addPolyline(List<LatLng> geofencePoints) {
    final PolylineId polylineId = PolylineId('geofence_polyline_${geofencePoints.hashCode}');
    final Polyline polyline = Polyline(
      polylineId: polylineId,
      color: Colors.blue,
      points: geofencePoints,
      width: 3,
    );

    setState(() {
      _polylines[polylineId] = polyline;
    });
  }
  void _addCircles(List<LatLng> geofencePoints) {
    for (var point in geofencePoints) {
      final CircleId circleId = CircleId('circle_${point.latitude}_${point.longitude}');

      final Circle circle = Circle(
        circleId: circleId,
        center: point,
        radius: 10, // Adjust radius as needed
        strokeColor: Colors.red,
        fillColor: Colors.red.withOpacity(0.5),
        strokeWidth: 1,
      );

      setState(() {
        _circles[circleId] = circle;
      });
    }
  }
  List<LatLng> parsePolygon(String area) {
    final trimmedArea = area.replaceAll(RegExp(r'(POLYGON \(\(|\)\))'), '')
        .replaceAll(RegExp(r'(LINESTRING \(|\))'), '');
    final coordinatePairs = trimmedArea.split(',');
    return coordinatePairs.map((pair) {
      final coords = pair.trim().split(' ');
      final lat = double.parse(coords[0]);
      final lng = double.parse(coords[1]);
      return LatLng(lat, lng);
    }).toList();
  }
  Duration _calculateETA(double distanceInMeters, double speedInMetersPerSecond) {
    double timeInSeconds = distanceInMeters / speedInMetersPerSecond;
    return Duration(seconds: timeInSeconds.toInt());
  }


  // Function to handle search
  void handleSearch(String value) {
    setState(() {
      searchController.text = value;
    });
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        // return "${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
        return "${placemark.street} ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}";
      }
    } catch (e) {
    }
    return "Address not found";
  }

  Future<LatLng> convertCoordinates(double x, double y) async {
    final double latitude = y / 1000000;
    final double longitude = x / 1000000;
    return LatLng(latitude, longitude);
  }

  void updateCurrentDate() {
    final now = DateTime.now();
    final formattedDate = DateFormat('E/dd-MMM/yyyy').format(now);
    setState(() {
      currentDate = formattedDate;
    });
  }

  bool isLoading = true;
  final int _selecteditem = 0;
  bool isGridMode = true; // Initially, set to grid mode


  Future<void> userData() async {
    final String userApi = dotenv.env['USERS_API']!;
    final String apiUrl = "$userApi/${widget.userId}";
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );
      if (response.statusCode == 200) {
        // Parse response body JSON
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Extract id from response body
        int userId = responseData['id'];
        String name = responseData['name'];
        phone = responseData['phone'];

        setState(() {
          MyName = name;
          ID = userId;
        });
      } else {
      }
    }
  }

  List<String> groupNames = [];
  Set<String> selectedNames = {};
  Set<int> selectedGroupId = {};
  List<Map<String, dynamic>> groupDetails = []; // List to store ID and Name pairs

  Future<void> groupListApi() async {
    final String groupListApiurl = dotenv.env['GROUP_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(groupListApiurl),
          headers: {
            'Cookie': sessionCookies,
          },
        ).timeout(const Duration(seconds: 30)); // Set timeout duration here

        if (response.statusCode == 200) {
          final List<dynamic> responseData = json.decode(response.body);
          groupDetails.clear(); // Clear previous data if any
          for (var item in responseData) {
            final int id = item['id'];
            final String name = item['name'];
            groupDetails.add({
              'id': id,
              'name': name,
            });
          }
        } else {
        }
      } on TimeoutException catch (_) {
      } on http.ClientException catch (e) {
      } catch (e) {
      }
    }
  }
  List<int> selectedGroupIds = [];
  void _showCustomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.zero,
              insetPadding: EdgeInsets.zero,
              buttonPadding: EdgeInsets.zero,
              titlePadding: EdgeInsets.zero,
              title: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child:
                groupDetails.isNotEmpty ?
                Column(
                  children: [
                    groupDetails.isNotEmpty ?
                    Expanded(
                      child:
                      ListView.builder(
                        itemCount: groupDetails.length,
                        itemBuilder: (context, index) {
                          final id = groupDetails[index]['id'];
                          final name = groupDetails[index]['name'];
                          return CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                            activeColor: Colors.green,
                            title: Text(name,style: GoogleFonts.poppins(
                                fontSize: 13.0, // Customize the font size
                                fontWeight: selectedNames.contains(name) ? FontWeight.w700:  FontWeight.w500,
                              color:  Colors.black, // Customize the font weight
                            ),),
                            value: selectedNames.contains(name),
                            onChanged: (bool? isChecked) {
                              setState(() {
                                if (isChecked == true) {
                                  selectedNames.add(name);
                                  selectedGroupIds.add(id);
                                } else {
                                  selectedNames.remove(name);
                                  selectedGroupIds.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ) :


                    const SizedBox(height: 10,),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                                side: const BorderSide(color: Colors.black),
                              ),
                              backgroundColor: Colors.black,
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white
                                )),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                                side: const BorderSide(color: Colors.black),
                              ),
                              backgroundColor: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                              filterCarDetails(); // Call to filter car details
                            },
                            child: Text('OK',
                                style: GoogleFonts.poppins(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white
                                )),
                          ),

                        ],
                      ),
                    ),
                  ],
                ) :

                Center(
                  child: Text("No Groups Found!",
                      style: GoogleFonts.poppins(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.black
                      )),
                ),
              ),
            );
          },
        );
      },
    );
  }


  void filterCarDetails() {
    setState(() {
      carDetailsList = unfilteredCarDetailsList.where((car) {
        return selectedGroupIds.contains(car.groupId);
      }).toList();

      // Debugging
      for (var car in carDetailsList) {
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
    // Cancel the timer when the widget is disposed
  }
  @override
  Widget build(BuildContext context) {
    String imagePath = 'assets/car-green.png';
    final addressProvider = Provider.of<AddressProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Sizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8.0),
                ),
                child: AppBar(
                  elevation: 0.0,
                  backgroundColor: Colors.grey.shade300,
                  title: isSearchActive
                      ? SizedBox(
                          width: screenWidth * 0.7,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search vehicle',
                                fillColor: Colors.white,
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.black,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 28.0),
                              child: Text(
                                "Dashboard",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: Image.asset(
                        'assets/menu_black.png',
                        width:
                            24.0, // Adjust the width and height according to your needs
                        height: 22.0,
                      ),
                      onPressed: () {
                        Scaffold.of(context)
                            .openDrawer(); // Open the side menu bar
                      },
                    ),
                  ),
                  actions: [
                    // Toggle between search and notification icons based on isSearchActive
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _showCustomDialog();
                          },
                          icon: const Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isSearchActive = !isSearchActive;
                            });
                          },
                          icon: Icon(
                            isSearchActive ? Icons.close : Icons.search,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            drawer: Drawer(
              backgroundColor: Colors.grey.shade300,
              child:
              ListView(
                children: <Widget>[
                  GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                                height: 70,
                                width: 250,
                                child: Image.asset(
                                  "assets/credence_white.png",
                                  fit: BoxFit.fill,
                                )),
                          ),
                          const SizedBox(height: 10.0), // Spacer
                          GestureDetector(
                            // onTap: (){
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) {
                            //         return const AdminScreen();
                            //       },
                            //     ),
                            //   );
                            // },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        MyName,
                                        style: GoogleFonts.poppins(
                                            fontSize: 18.0, // Customize the font size
                                            fontWeight: FontWeight.w500,
                                            color: Colors
                                                .black // Customize the font weight
                                            ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_sharp,
                                        color: Colors.black,
                                        size: 17,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 0
                        ? const EdgeInsets.symmetric(horizontal: 0.0)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        color: _selecteditem == 0
                            ? Colors.grey.shade500.withOpacity(0.5)
                            : Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 15,
                            width: 15,
                            child: Image.asset(
                              "assets/home_new.png",
                              color: _selecteditem == 0
                                  ? Colors.white
                                  : Colors.black,
                            )),
                        title: Text(
                          'Home',
                          style: GoogleFonts.poppins(
                              color: _selecteditem == 0
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Dashboard(
                                        userId: ID,
                                      )));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 11
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/black_vehicles.png",
                            )),
                        // const Icon(Icons.help),
                        title: Text(
                          "All Vehicles",
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AllVehicleLive()));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 4
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/about_image.png",
                            )),
                        // const Icon(Icons.info),
                        title: Text(
                          'About Us',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          // Handle About Us tap
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AboutUs(
                                      myName: MyName,
                                      phone: phone,
                                      userId: widget.userId)));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 2
                        ? const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/invite_image.png",
                            )),
                        // const Icon(Icons.person_add),
                        title: Text(
                          'Invite Friend',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          // Handle Invite Friend tap
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Invite(
                                      myName: MyName,
                                      phone: phone,
                                      userId: widget.userId)));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 9
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/black_rc.png",
                            )),
                        // const Icon(Icons.help),
                        title: Text(
                          'Check RC',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          launch(
                              "https://vahan.parivahan.gov.in/vahanservice/vahan/ui/appl_status/form_Know_Appl_Status.xhtml");
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 8
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/black_license.png",
                            )),
                        // const Icon(Icons.help),
                        title: Text(
                          'License',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          launch(
                              "https://parivahan.gov.in/rcdlstatus/?pur_cd=101");
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 7
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/black_profile.png",
                            )),
                        // const Icon(Icons.help),
                        title: Text(
                          'Update Profile',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EditProfile(
                                        userId: widget.userId,
                                        phone: phone ?? "",
                                        myName: MyName,
                                      )));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 5
                        ? const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/privacy_image.png",
                            )),
                        // const Icon(Icons.policy),
                        title: Text(
                          'Privacy',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PrivacyPolicy(
                                      myName: MyName,
                                      phone: phone,
                                      userId: widget.userId)));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 6
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/help_image.png",
                            )),
                        // const Icon(Icons.help),
                        title: Text(
                          'Help',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HelpScreen()));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 1
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/feedback_image.png",
                            )),
                        // const Icon(Icons.feedback),
                        title: Text(
                          'Feedback',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FeedBack(
                                      myName: MyName,
                                      phone: phone,
                                      userId: widget.userId)));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 3
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/rate_app.png",
                            )),
                        // const Icon(Icons.star),
                        title: Text(
                          'Rate the App',
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Rate(
                                      myName: MyName,
                                      phone: phone,
                                      userId: widget.userId)));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 10
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/black_password.png",
                            )),
                        // const Icon(Icons.help),
                        title: Text(
                          "Change Password",
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePassword()));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: _selecteditem == 12
                        ? const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 10)
                        : const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.transparent,
                      ),
                      child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/black_logout.png",
                            )),
                        // const Icon(Icons.help),
                        title: Text(
                          "Exit",
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontSize: 12),
                        ),
                        onTap: () {
                          showLogoutDialog(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            body: Stack(children: [
              Column(
                children: [
                  // Filter bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 10, left: 10, right: 10, bottom: 5),
                      child:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(
                            width: 10,
                          ),
                          //ALL
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (!showAllCars) {
                                  showAllCars = true;
                                  showIdle = false;
                                  showStop = false;
                                  showRunning = false;
                                  showOverSpeed = false;
                                  showActive = false;
                                  showInactive = false;
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              height: 50,
                              width: 70,
                              child: Column(
                                children: [
                                  Text(
                                      '${getCarCount(carDetailsList, "All", "acc",)}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20)),
                                  Text('All',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showAllCars = false;
                                showIdle = false;
                                showStop = false;
                                showRunning = true;
                                showOverSpeed = false;
                                showActive = false;
                                showInactive = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(18.0),

                              ),
                              height: 50,
                              width: 70,
                              child: Column(
                                children: [
                                  Text(
                                      '${getCarCount(carDetailsList, "Running", "acc")}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20)),
                                  Text('Running',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                          //YELLOW


                          const SizedBox(
                            width: 10,
                          ),
                          //RED
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showAllCars = false;
                                showIdle = false;
                                showStop = true;
                                showRunning = false;
                                showOverSpeed = false;
                                showActive = false;
                                showInactive = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(18.0),

                              ),
                              height: 50,
                              width: 70,
                              child: Column(
                                children: [
                                  Text(
                                      '${getCarCount(carDetailsList, "Stopped", "acc")}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20)),
                                  Text('Stop',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),
                          //GREEN
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showAllCars = false;
                                showIdle = true;
                                showStop = false;
                                showRunning = false;
                                showOverSpeed = false;
                                showActive = false;
                                showInactive = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade700,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(18.0),

                              ),
                              height: 50,
                              width: 70,
                              child: Column(
                                children: [
                                  Text(
                                      '${getCarCount(carDetailsList, "Idle", "acc")}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20)),
                                  Text('Idle',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),
                          //ORANGE
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showAllCars = false;
                                showIdle = false;
                                showStop = false;
                                showRunning = false;
                                showOverSpeed = false;
                                showActive = true;
                                showInactive = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade700,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(18.0),

                              ),
                              height: 50,
                              width: 80,
                              child: Column(
                                children: [
                                  Text(
                                      '${getCarCount(carDetailsList, "Active", "acc")}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20)),
                                  Text('Online',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),


                          const SizedBox(
                            width: 10,
                          ),
                          //ONLINE
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showAllCars = false;
                                showIdle = false;
                                showStop = false;
                                showRunning = false;
                                showOverSpeed = true;
                                showActive = false;
                                showInactive = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange.shade700,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(18.0),

                              ),
                              height: 50,
                              width: 80,
                              child: Column(
                                children: [
                                  Text(
                                      '${getCarCount(carDetailsList, "OverSpeed", "acc")}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20)),
                                  Text('OverSpeed',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          //INACTIVE
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showAllCars = false;
                                showIdle = false;
                                showStop = false;
                                showRunning = false;
                                showOverSpeed = false;
                                showActive = false;
                                showInactive = true;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(18.0),
                                color: Colors.black,
                              ),
                              height: 50,
                              width: 80,
                              child: Column(
                                children: [
                                  Text(
                                      '${getCarCount(carDetailsList, "Inactive", "acc")}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20)),
                                  Text('Inactive',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 8)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  isLoading
                      ? Center(
                          child: LoadingAnimationWidget.threeArchedCircle(
                          color: Colors.white,
                          size: 50,
                        ))
                      : Flexible(
                    child:
                    ListView.builder(
                      itemCount: carDetailsList.length,
                      itemBuilder: (context, index) {
                        final carDetail = carDetailsList[index];
                        final odometerValueN = carDetail.odometerValueN ?? 0.0;
                        final totalDistanceS = carDetail.attributes['totalDistance'] ?? 0.0;
                        final kmDistance = totalDistanceS/1000;
                        final distance = carDetail.attributes['distance'] ?? 0.0;
                        final kmTodaysDistance = distance/1000;
                        final mileageN = carDetail.mileage ?? 0.0;
                        // final fuel = odometerValueN/mileageN;
                        final fuel = (mileageN != 0) ? (odometerValueN / mileageN) : 0.0;
                        final formattedDistance =
                        (totalDistanceS / 1000)
                            .toStringAsFixed(2);
                        final address = carDetail.carAddress ??
                            'Address not available';
                        DateTime lastUpdates = DateTime.parse(carDetail.lastUpdate.toString());
                        DateTime addLastUpdate = lastUpdates.add(
                            const Duration(hours: 5, minutes: 30));
                        String formattedDates =
                        DateFormat('dd/MM/yyyy HH:mm:ss')
                            .format(addLastUpdate);
                        if (!searchCar(carDetail.vehicleName,
                            searchController.text)) {
                          return const SizedBox();
                        }
                        if (!shouldShowCar(carDetail)) {
                          return const SizedBox();
                        }
                        final ignition =
                            carDetail.attributes['ignition'] ?? false;
                        Color textColor = carDetail.battery < 20
                            ? Colors.red
                            : Colors.green;
                        DateTime todayStart = DateTime.now();
                        todayStart = DateTime(todayStart.year, todayStart.month, todayStart.day, 0, 0, 0);
                        bool wasIgnitionToday = (ignition && lastUpdates.isAfter(todayStart)) || (ignition && DateTime.now().isAfter(todayStart));
                        String displayDate = wasIgnitionToday
                            ? DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())
                            : formattedDates;
                        final status =
                        getStatus(carDetail.speed, ignition,carDetail.status,);
                        final lastUpdate =
                            carDetail.lastUpdate.toString() ?? 'N/A';
                        DateTime lastUpdateTime =
                        DateTime.parse(lastUpdate);
                        lastUpdateTime = lastUpdateTime.add(
                            const Duration(hours: 5, minutes: 30));
                        final updatedTime = DateFormat('dd/MM/yy HH:mm:ss')
                            .format(lastUpdateTime);
                        String imagePath = 'assets/walk.png';
                        String imagePath2 = 'assets/walk.png';
                        Color carColor = Colors.grey;
                        switch (carDetail.vehicleType) {
                          case 'motorcycle':
                            switch (status) {
                              case 'Idle':
                                imagePath =
                                'assets/bike_yellow_img.png';
                                imagePath2 = 'assets/bike-yellow.png';
                                carColor = Colors.yellow;
                                break;
                              case 'Running':
                                imagePath =
                                'assets/bike_green_img.png';
                                imagePath2 = 'assets/bike-green.png';
                                carColor = Colors.green;
                                break;
                              case 'Stopped':
                                imagePath = 'assets/bike_red_img.png';
                                imagePath2 = 'assets/bike-red.png';
                                carColor = Colors.red;
                                break;
                              default:
                                imagePath =
                                'assets/bike_grey_img.png'; // Set default image path
                                imagePath2 = 'assets/bike-yellow.png';
                                carColor =
                                    Colors.grey; // Set default color
                                break;
                            }
                            break;
                          case 'car':
                            switch (status) {
                              case 'Idle':
                                imagePath =
                                'assets/car_yellow_img.png';
                                imagePath2 = 'assets/car-yellow2.png';
                                carColor = Colors.yellow;
                                break;
                              case 'Running':
                                imagePath =
                                'assets/car_green_img.png';
                                imagePath2 = 'assets/car-green2.png';
                                carColor = Colors.green;
                                break;
                              case 'Stopped':
                                imagePath = 'assets/car_red_img.png';
                                imagePath2 = 'assets/car-red2.png';
                                carColor = Colors.red;
                                break;
                              default:
                                imagePath =
                                'assets/car_grey_img.png'; // Set default image path
                                imagePath2 = 'assets/car-red2.png';
                                carColor =
                                    Colors.grey; // Set default color
                                break;
                            }
                            break;
                          case 'bus':
                            switch (status) {
                              case 'Idle':
                                imagePath =
                                'assets/bus_yellow_img.png';
                                imagePath2 = 'assets/bus-yellow2.png';
                                carColor = Colors.yellow;
                                break;
                              case 'Running':
                                imagePath =
                                'assets/bus_green_img.png';
                                imagePath2 = 'assets/bus-green2.png';
                                carColor = Colors.green;
                                break;
                              case 'Stopped':
                                imagePath = 'assets/bus_red_img.png';
                                imagePath2 = 'assets/bus-red2.png';

                                carColor = Colors.red;
                                break;
                              default:
                                imagePath =
                                'assets/bus_grey_img.png'; // Set default image path
                                imagePath2 = 'assets/bus-yellow2.png';

                                carColor =
                                    Colors.grey; // Set default color
                                break;
                            }
                            break;
                          case 'tractor':
                            switch (status) {
                              case 'Idle':
                                imagePath =
                                'assets/tractor_yellow_new.png';
                                imagePath2 =
                                'assets/truck-yellow2.png';

                                carColor = Colors.yellow;
                                break;
                              case 'Running':
                                imagePath =
                                'assets/tractor_green.png';
                                imagePath2 =
                                'assets/truck-green2.png';
                                carColor = Colors.green;
                                break;
                              case 'Stopped':
                                imagePath = 'assets/tractor_red.png';
                                imagePath2 = 'assets/truck-red2.png';
                                carColor = Colors.red;
                                break;
                              default:
                                imagePath =
                                'assets/tractor_grey.png'; // Set default image path
                                imagePath2 = 'assets/truck-red2.png';
                                carColor =
                                    Colors.grey; // Set default color
                                break;
                            }
                            break;
                          case 'truck':
                            switch (status) {
                              case 'Idle':
                                imagePath =
                                'assets/truck_yellow_img.png';
                                imagePath2 =
                                'assets/truck-yellow2.png';
                                carColor = Colors.yellow;
                                break;
                              case 'Running':
                                imagePath =
                                'assets/truck_green_img.png';
                                imagePath2 =
                                'assets/truck-green2.png';
                                carColor = Colors.green;
                                break;
                              case 'Stopped':
                                imagePath =
                                'assets/truck_red_img.png';
                                imagePath2 = 'assets/truck-red2.png';
                                carColor = Colors.red;
                                break;
                              default:
                                imagePath =
                                'assets/truck_grey_img.png'; // Set default image path
                                imagePath2 = 'assets/truck-red2.png';

                                carColor =
                                    Colors.grey; // Set default color
                                break;
                            }
                        }
                        return
                          GestureDetector(

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DataScreen(
                                      carNumber: carDetail.vehicleName.toString(),
                                      fuel: fuel.toInt(),
                                      // fuel: 0,
                                      // lastUpdate: updatedTime,
                                      lastUpdate: displayDate,
                                      // lastUpdate: formattedDates,
                                      Odometer: carDetail.odometer
                                          .roundToDouble()
                                          .toString(),
                                      battery: carDetail.battery,
                                      Engine: ignition,
                                      stopMatch: "stop.toString()",
                                      id: carDetail.deviceId,
                                      carSpeed: carDetail.speed,
                                      status: carDetail.valid,
                                      driver: 'N/A ',
                                      address: carDetail.carAddress,
                                      todayDistance: 0,
                                      imagePath: imagePath,
                                      imagePath2: imagePath2),
                                ),
                              );

                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child:
                                  Container(
                                    padding:
                                    const EdgeInsets.only(top: 0),
                                    width: MediaQuery.of(context)
                                        .size
                                        .width *
                                        0.97,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey
                                              .withOpacity(0.5),
                                          spreadRadius: 1,
                                          blurRadius: 1,
                                          offset: const Offset(0,
                                              1), // changes position of shadow
                                        ),
                                      ],
                                      borderRadius:
                                      BorderRadius.circular(8.0),
                                      color: Colors.white,
                                    ),
                                    child:
                                    Column(
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                              .size
                                              .height *
                                              0.04,
                                          child: Container(
                                              color: Colors.black,
                                              child: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    flex: 2,
                                                    child: Container(
                                                      decoration:
                                                      const BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius
                                                            .only(
                                                          topRight: Radius
                                                              .circular(
                                                              15),
                                                          topLeft: Radius
                                                              .circular(
                                                              8),
                                                        ),
                                                        color: Colors.white,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .all(
                                                                5.0),
                                                            child: Text(
                                                              "${carDetail.battery}%",
                                                              style: GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .green,
                                                                  fontSize:
                                                                  13),
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .gps_fixed_outlined,
                                                            size: 15.0,
                                                            color: carDetail.valid ==
                                                                true
                                                                ? Colors
                                                                .green
                                                                : Colors
                                                                .black,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  Flexible(
                                                    flex: 3,
                                                    child: Container(
                                                      color: Colors.black,
                                                      child: Container(
                                                        decoration:
                                                        const BoxDecoration(
                                                          borderRadius: BorderRadius.only(
                                                              bottomLeft:
                                                              Radius.circular(
                                                                  15),
                                                              bottomRight:
                                                              Radius.circular(
                                                                  15)),
                                                          color: Colors
                                                              .black,
                                                        ),
                                                        child:
                                                        Text(
                                                          carDetail
                                                              .vehicleName,
                                                          style: GoogleFonts
                                                              .sansita(
                                                            fontSize:
                                                            15,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold,
                                                            color: Colors
                                                                .white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Flexible(
                                                    flex: 2,
                                                    child: Container(
                                                      decoration:
                                                      const BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius
                                                            .only(
                                                          topLeft: Radius
                                                              .circular(
                                                              15),
                                                          topRight: Radius
                                                              .circular(
                                                              8),
                                                        ),
                                                        color: Colors
                                                            .white,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .all(
                                                                6.0),
                                                            child: Icon(
                                                              Icons
                                                                  .signal_cellular_alt_outlined,
                                                              size:
                                                              18.0,
                                                              color: carDetail.valid ==
                                                                  true
                                                                  ? Colors
                                                                  .green
                                                                  : Colors
                                                                  .black,
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons.key,
                                                            size: 18.0,
                                                            color: (carDetail.speed ==
                                                                0 &&
                                                                ignition ==
                                                                    true)
                                                                ? Colors
                                                                .yellow
                                                                : (carDetail.speed > 0 &&
                                                                ignition == true)
                                                                ? Colors.green
                                                                : Colors.red,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                          ),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.only(left: 0,top: 10,bottom: 0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(left: 10),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    SizedBox(
                                                      height:80,
                                                      width:150,
                                                      child: Center(
                                                        child: Image.asset(
                                                          imagePath,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 45,

                                                              child: Text(
                                                                "Spent Fuel",
                                                                style: GoogleFonts.poppins(
                                                                    color: Colors.grey.shade700,
                                                                    fontSize: 8,
                                                                    fontWeight: FontWeight.w500),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 5,),
                                                            Container(
                                                              height: 5,
                                                              width: 5,
                                                              color: Colors.green,
                                                            ),
                                                            const SizedBox(width: 5,),
                                                            SizedBox(
                                                              width: 45,
                                                              child: Text(
                                                                // " ${fuel.toStringAsFixed(2)}",
                                                                " ${fuel.toStringAsFixed(2)}",
                                                                style: GoogleFonts.poppins(
                                                                    color: Colors.black,
                                                                    fontSize: 8,
                                                                    fontWeight: FontWeight.w600),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 5,),

                                                        Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 45,
                                                              child: Text(
                                                                "ETA",
                                                                style: GoogleFonts.poppins(
                                                                    color: Colors.grey.shade700,
                                                                    fontSize:
                                                                    8,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 5,),
                                                            Container(
                                                              height: 5,
                                                              width: 5,
                                                              color: Colors.red,
                                                            ),
                                                            const SizedBox(width: 5,),
                                                            SizedBox(
                                                              width: 45,

                                                              child: Text(
                                                                _etaText ?? "00:00:00",
                                                                style: GoogleFonts.poppins(
                                                                    color: Colors.black,
                                                                    fontSize: 8,
                                                                    fontWeight: FontWeight.w600),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 5,),
                                                        Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 45,

                                                              child:Text(
                                                                "Driver",
                                                                style: GoogleFonts.poppins(
                                                                    color: Colors.grey.shade700,
                                                                    fontSize:
                                                                    8,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 5,),
                                                            Container(
                                                              height: 5,
                                                              width: 5,
                                                              color: Colors.purple,
                                                            ),
                                                            const SizedBox(width: 5,),
                                                            SizedBox(
                                                              width: 45,
                                                              child: Text(
                                                                "Unknown",
                                                                style: GoogleFonts.poppins(
                                                                    color: Colors.black,
                                                                    fontSize: 8,
                                                                    fontWeight: FontWeight.w600),
                                                              ),
                                                            ),
                                                          ],
                                                        ),

                                                      ],
                                                    )
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 10),
                                                child: Text(
                                                  carDetail.vehicleName,
                                                  style:
                                                  GoogleFonts.sansita(
                                                    fontSize: 14,
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 10),
                                                child: Text(
                                                  address,
                                                  style:
                                                  GoogleFonts.poppins(
                                                      color: Colors
                                                          .grey
                                                          .shade700,
                                                      fontSize: 12,
                                                      fontWeight:
                                                      FontWeight
                                                          .w500),
                                                ),
                                              ),
                                              const SizedBox(height: 5,),
                                              Container(
                                                decoration:
                                                BoxDecoration(
                                                  color: Colors.grey.shade300,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.shade300
                                                          .withOpacity(
                                                          0.5),
                                                      spreadRadius: 1,
                                                      blurRadius: 3,
                                                      offset: const Offset(
                                                          0,
                                                          1), // changes position of shadow
                                                    ),
                                                  ],
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 10,right: 10,bottom: 7,top: 3),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            "Last Update",
                                                            style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .grey,
                                                                fontSize:
                                                                10,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                          ),
                                                          const SizedBox(
                                                            height: 0,
                                                          ),
                                                          SizedBox(
                                                            width: MediaQuery.of(
                                                                context)
                                                                .size
                                                                .width *
                                                                0.2,
                                                            child:
                                                            Text(
                                                              displayDate,
                                                              style: GoogleFonts.poppins(
                                                                  color: Colors.black,
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.w600),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            "Today's Km",
                                                            style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .grey,
                                                                fontSize:
                                                                10,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                          ),
                                                          SizedBox(
                                                            width: MediaQuery.of(
                                                                context)
                                                                .size
                                                                .width *
                                                                0.2,
                                                            child: Text(
                                                              '${odometerValueN.toStringAsFixed(2)}\n km',
                                                              style: GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize:
                                                                  9,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            "Total Km",
                                                            style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .grey,
                                                                fontSize:
                                                                10,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                          ),
                                                          Text(
                                                            // formattedDistance,
                                                            "$formattedDistance \nKm",
                                                            //   " ${todaysDistance.toStringAsFixed(2)}\n km",
                                                            style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .black,
                                                                fontSize:
                                                                9,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                          ),
                                                        ],
                                                      ),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            "Speed",
                                                            style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .grey,
                                                                fontSize:
                                                                10,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                          ),
                                                          Text(
                                                            "${carDetail.speed.roundToDouble()} \nKm/hr",
                                                            // "${carDetail.mileage?.roundToDouble()} \nKm/hr",
                                                            style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .black,
                                                                fontSize:
                                                                9,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                          ),
                                                        ],
                                                      ),

                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                      },
                    ),

                  )
                ],
              ),
            ]),
          ),
        ),
      );
    });
  }

  int getCarCount(List<CarDetails> carItems, String status, String acc) {
    int count = 0;
    for (var carItem in carItems) {
      final speed = carItem.speed;
      final ignition = carItem.ignition ?? false;
      final valid = carItem.status;
      final lastUpdate = carItem.lastUpdate;
      final positionId = carItem.positionId;
      switch (status) {
        case 'All':
          count++;
          break;
        case 'Idle':
          if (speed <= 2.0 && ignition && valid != 'offline') count++;
          break;
        case 'Running':
          if (speed >= 2.0 && ignition && valid != 'offline') count++;
          break;
        case 'OverSpeed':
          if (speed >= 60.0 && ignition && valid != 'offline') count++;
          break;
        case 'Stopped':
          if (speed <= 1.0 && !ignition && valid != 'offline') count++;
          break;
        case 'Active':
          if (valid == 'online' || valid == 'unknown') count++;
          break;
        case 'Inactive':
          // if (positionId == 0 && valid == 'offline') count++;
          if (valid == 'offline') count++;
          // if (lastUpdate == '0000-01-01 00:00:00.000') count++;
          break;
        default:
          break;
      }
    }
    return count;
  }

  bool shouldShowCar(CarDetails carItem) {
    final attributes = carItem.attributes;
    final speed = carItem.speed;
    final ignition = attributes['ignition'] ?? false;
    final valid = carItem.status;
    final positionId = carItem.positionId;
    if (showAllCars) {
      return true; // Show all cars
    } else if (showIdle && speed <= 2.0 && ignition  && valid != 'offline') {
      return true; // Show idle cars
    } else if (showStop && speed <= 1.0 && !ignition && valid != 'offline') {
      return true; // Show stopped cars
    } else if (showRunning && speed > 2.0 && ignition  && valid != 'offline') {
      return true; // Show running cars
    } else if (showOverSpeed && speed >= 60.0  && valid != 'offline') {
      return true; // Show cars with speed over 60
    } else if (showActive && valid == 'online') {
      return true; // Show active cars
    // } else if (showInactive && valid == 'offline') {
    } else if (showInactive && positionId == 0 && valid == 'offline') {
      return true; // Show inactive cars
    }
    return false;
  }

  String _formatDate(String rawDate) {
    try {
      DateTime dateTime = DateTime.parse(rawDate);
      String formattedDateTime =
          DateFormat('dd-MM-yy HH:mm:ss').format(dateTime);
      return formattedDateTime;
    } catch (e) {
      return rawDate; // Return the raw date if parsing fails
    }
  }
}

bool searchCar(String? carName, String searchTerm) {
  if (carName == null || searchTerm.isEmpty) {
    return true; // If the car name is null or the search term is empty, consider it a match
  }
  return carName.toLowerCase().contains(searchTerm.toLowerCase());
}

String getStatus(double speed, bool ignition, String status) {
  if (speed <= 1.0 && !ignition && status != "offline" ) {
    return 'Stopped';
  } else {
    if (speed <= 2.0 && ignition && status != "offline" ) {
      return 'Idle';
    } else if(speed >= 2.0 && ignition && status != "offline" ){
      return 'Running';
    }else {
      return 'Inactive';
    }
  }
}
