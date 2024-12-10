import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:credence/share_device.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:credence/dashboard_screen.dart';
import 'package:credence/dateandtime_selection.dart';
import 'package:credence/documnet_locker.dart';
import 'package:credence/driver_screen.dart';
import 'package:credence/histoy_screen.dart';
import 'package:credence/live_map_screen.dart';
import 'package:credence/map_geofence.dart';
import 'package:credence/model/car_location.dart';
import 'package:credence/notification_screen.dart';
import 'package:credence/provider/car_address_provider.dart';
import 'package:credence/provider/car_details_provider.dart';
import 'package:credence/provider/car_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'maintenance_screen.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class DataScreen extends StatefulWidget {
  final String carNumber;
  final String lastUpdate;
  final int id;
  final bool status;
  final int battery;
  final String Odometer;
  final String driver;
  final bool Engine;
  final double carSpeed;
  final String address;
  final String stopMatch;
  final int todayDistance;
  final String imagePath;
  final String imagePath2;
  final int fuel;

  const DataScreen({
    super.key,
    required this.carNumber,
    required this.lastUpdate,
    required this.Odometer,
    required this.battery,
    required this.id,
    required this.Engine,
    required this.status,
    required this.driver,
    required this.carSpeed,
    required this.address,
    required this.stopMatch,
    required this.todayDistance,
    required this.imagePath,
    required this.imagePath2,
    required this.fuel,
  });

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final storage = const FlutterSecureStorage();
  GoogleMapController? mapController;
  LatLng? carLocation = const LatLng(0, 0);
  late Timer _timer;
  double carSpeed = 0.0;
  int carStatus = 0;
  String stopMatchValue = 'N/A';
  String todayMovingValue = 'N/A';
  String todayEngineValue = 'N/A'; // Default value or initial value
  String batteryValue = 'N/A';
  List<LatLng> playbackPoints = [];
  late BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
  double carRotation = 0.0;
  bool isCardVisible = false;
  Map<String, dynamic>? carDetails;
  String carAddress = "";
  Map<int, String> carAddresses = {};
  double? odometerValue = 0.0;
  double todayOdometerValue = 0.0;
  List<LatLng> polylinePoints = [];
  List<CarDetails> carDetailsList = [];
  late double latitude = 0.0;
  late double longitude = 0.0;
  double maximumSpeed = 0.0;
  double averageSpeedData = 0.0;
  String totalDistance = '';
  String totalDuration = '';
  String totalRunningTime = "0.0";
  String StopTime = '';
  String stopTime = '';
  double lat = 0.0;
  double long = 0.0;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  bool isLoading = true;
  String? _selectedOption;
  MapType currentMapType = MapType.normal;
  bool currentValue = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 20000), // Adjust duration as needed
    );
    _animation = Tween<Offset>(
      begin: const Offset(0.0, 10.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));
    _animationController.forward();
    const Duration refreshInterval = Duration(seconds: 1);
    _timer = Timer.periodic(refreshInterval, (Timer timer) {
      fetchLiveMap();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchCarDetails(
      String carDetailsApiUrl, String sessionCookies) async {
    final response = await http.get(
      Uri.parse(carDetailsApiUrl),
      headers: {'Cookie': sessionCookies},
    );

    if (response.statusCode != 200) {
      return [];
    }

    final List<dynamic> jsonResponse = json.decode(response.body);
    if (jsonResponse.isEmpty) {
      return [];
    }

    return jsonResponse.cast<Map<String, dynamic>>();
  }

  Future<Map<int, Map<String, dynamic>>> fetchDeviceDetails(
      List<Map<String, dynamic>> carDataList,
      String deviceApi,
      String sessionCookies) async {
    final deviceDetailsCache = <int, Map<String, dynamic>>{};

    final deviceDetailsFutures = carDataList
        .where((carItem) => carItem['deviceId'] == widget.id)
        .map((carItem) async {
      final deviceId = carItem['deviceId'];
      try {
        final deviceDetailsResponse = await http.get(
          Uri.parse("$deviceApi/$deviceId"),
          headers: {'Cookie': sessionCookies},
        );
        if (deviceDetailsResponse.statusCode == 200) {
          deviceDetailsCache[deviceId] =
              json.decode(deviceDetailsResponse.body);
        } else {}
      } catch (e) {}
    }).toList();

    await Future.wait(deviceDetailsFutures);
    return deviceDetailsCache;
  }

  Future<void> fetchLiveMap() async {
    final String deviceApi = dotenv.env['DEVICE_API']!;
    final String carDetailsApiUrl = dotenv.env['LIVE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      return;
    }
    try {
      final carDataList =
          await fetchCarDetails(carDetailsApiUrl, sessionCookies);
      if (carDataList.isEmpty) {

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
      final deviceDetailsCache =
          await fetchDeviceDetails(carDataList, deviceApi, sessionCookies);
      bool carFound = false;
      final List<Future<void>> tasks = [];
      for (final carItem in carDataList) {
        final int deviceId = carItem['deviceId'];
        if (deviceId == widget.id) {
          carFound = true;
          final double latitude = (carItem['latitude'] ?? 0.0).toDouble();
          final double longitude = (carItem['longitude'] ?? 0.0).toDouble();
          final double rotationAngle = carItem['course'].toDouble();
          final int carId = carItem['id'];
          final bool ignition = carItem['attributes']['ignition'] ?? false;
          final double speed = (carItem['speed'] ?? 0.0) * 1.852;
          // final todayDistance =
          //     (carItem['attributes']['distance'] ?? 0.0).toDouble();
          final deviceDetails = deviceDetailsCache[deviceId];
          final String vehicleType = deviceDetails?['category'] ?? 'car';
          final String status = getStatus(speed, ignition);
          loadCustomIcon(vehicleType: vehicleType, status: status);

          if (latitude > 0 && longitude > 0) {
            final convertedLocation = LatLng(latitude, longitude);
            final address = await getAddress(latitude, longitude);
            carAddresses[carId] = address;
            polylinePoints.add(convertedLocation);
            carRotation = rotationAngle;
            carLocation = convertedLocation;
            carAddress = address;
            carSpeed = speed.roundToDouble();
            // todayOdometerValue = todayDistance.roundToDouble();
            lat = latitude;
            long = longitude;
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }


            moveCameraToCarLocation();
            final addressProvider =
                Provider.of<AddressProvider>(context, listen: false);
            addressProvider.updateAddress(address);

            final carLocationProvider =
                Provider.of<CarLocationProvider>(context, listen: false);
            final carLocationData = CarLocation(
              latitude: latitude,
              longitude: longitude,
              rotationAngle: rotationAngle,
              timestamp: DateTime.now(),
            );
            carLocationProvider.addLocation(carLocationData);
          } else {
            setState(() {
              isLoading = false;
              carLocation = const LatLng(0, 0);
            });
          }
        }
      }

      // Handle case where no car is found
      if (!carFound) {
        setState(() {
          isLoading = false;
          carLocation = const LatLng(21.1296, 79.0990); // Default location
        });
        Fluttertoast.showToast(
            msg: "Device Offline", toastLength: Toast.LENGTH_SHORT);
        Future.delayed(const Duration(seconds: 1), () => Fluttertoast.cancel());
      }
      await Future.wait(tasks);
    } catch (e) {
      print('Error in fetchLiveMap: $e');
    }
  }

  double zoomLevel = 15.0;
  void moveCameraToCarLocation() {
    if (mapController != null && carLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: carLocation ?? const LatLng(0.0, 0.0),
            zoom: zoomLevel,
          ),
        ),
      );
    }
  }

  Future<void> loadCustomIcon(
      {String vehicleType = 'car', String status = 'Idle'}) async {
    String imagePath = "assets/car_top.png"; // Default icon path

    switch (vehicleType) {
      case 'motorcycle':
        switch (status) {
          case 'Idle':
            imagePath = 'assets/bike_yt.png';
            break;
          case 'Running':
            imagePath = 'assets/bike_gt.png';
            break;
          case 'Stopped':
            imagePath = 'assets/bike_rt.png';
            break;
        }
        break;
      case 'car':
        switch (status) {
          case 'Idle':
            imagePath = 'assets/car_yt.png';
            break;
          case 'Running':
            imagePath = 'assets/car_gt.png';
            break;
          case 'Stopped':
            imagePath = 'assets/car_rt.png';
            break;
        }
        break;
      case 'bus':
        switch (status) {
          case 'Idle':
            imagePath = 'assets/bus_yt.png';
            break;
          case 'Running':
            imagePath = 'assets/bus_gt.png';
            break;
          case 'Stopped':
            imagePath = 'assets/bus_rt.png';
            break;
        }
        break;
      case 'truck':
        switch (status) {
          case 'Idle':
            imagePath = 'assets/truck_yt.png';
            break;
          case 'Running':
            imagePath = 'assets/truck_gt.png';
            break;
          case 'Stopped':
            imagePath = 'assets/truck_rt.png';
            break;
        }
        break;
      case 'tractor':
        switch (status) {
          case 'Idle':
            imagePath = 'assets/tractor_yt.png';
            break;
          case 'Running':
            imagePath = 'assets/tractor_gt.png';
            break;
          case 'Stopped':
            imagePath = 'assets/tractor_rt.png';
            break;
        }
        break;
      default:
        imagePath = 'assets/car_top.png'; // Default icon path
        break;
    }

    final String iconPath = imagePath;
    try {
      ByteData data = await rootBundle.load(imagePath);
      Uint8List imageData = data.buffer.asUint8List();

      ui.Codec codec = await ui.instantiateImageCodec(imageData,
          targetWidth: 40);
      ui.FrameInfo frameInfo = await codec.getNextFrame();

      ByteData? resizedData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List resizedBytes = resizedData!.buffer.asUint8List();

      customIcon = BitmapDescriptor.fromBytes(resizedBytes);

    } catch (e) {
      print(e.toString());
    }
    // try {
    //   customIcon = await BitmapDescriptor.fromAssetImage(
    //     const ImageConfiguration(size: Size(10, 10)),
    //     iconPath,
    //   );
    // } catch (e) {}
  }

  String getStatus(double speed, bool ignition) {
    if (!ignition) {
      return 'Stopped';
    } else {
      if (speed <= 2.0) {
        return 'Idle';
      } else {
        return 'Running';
      }
    }
  }

  void openGoogleMaps(String coordinates) async {
    final List<String> latLng = coordinates.split(',');
    final url =
        'https://www.google.com/maps/search/?api=1&query=${latLng[0]},${latLng[1]}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> openUrlWithToken(String expiration) async {
    final apiUrl = dotenv.env['SHARE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    final currentTime = DateTime.now();
    final expirationTime = DateTime.parse(expiration);
    final newExpirationTime =
        _calculateExpirationTime(currentTime, expirationTime);
    final formattedExpiration = newExpirationTime.toUtc().toIso8601String();
    final requestBody = {
      'deviceId': widget.id.toString(),
      'expiration': formattedExpiration,
    };
    if (sessionCookies != null) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cookie': sessionCookies,
          },
          body: requestBody,
        );
        if (response.statusCode == 200) {
          final token = response.body.trim();
          final url = 'http://104.251.216.99:8082?token=$token';
          final encodedUrl = Uri.encodeFull(url); // Encode the complete URL
          final sharedMessage = 'Vehicle No: ${widget.carNumber}\n'
              'Location: ${widget.address}\n'
              'Live Track:\n$encodedUrl';
          Share.share(sharedMessage, subject: 'Shared URL');
        } else {}
      } catch (e) {}
    }
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return "${placemark.street} ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}";
      }
    } catch (e) {}
    return "Updating address...";
  }

  Future<LatLng> convertCoordinates(double x, double y) async {
    final double latitude = y / 1000000;
    final double longitude = x / 1000000;
    return LatLng(latitude, longitude);
  }

  void centerMapOnCar() {
    moveCameraToCarLocation();
  }


  Set<Circle> geofenceCircles = {};
  Polyline geofencePolyline =
      const Polyline(polylineId: PolylineId("geofencePolyline"), points: []);
  String? etaText;
  final Map<PolylineId, Polyline> _polylines = {};
  Map<CircleId, Circle> _circles = {};
  String? _etaText;
  Map<LatLng, String> geofencePointsWithNames = {};


  void _addPolyline(List<LatLng> geofencePoints) {
    final PolylineId polylineId =
        PolylineId('geofence_polyline_${geofencePoints.hashCode}');
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
      final CircleId circleId =
          CircleId('circle_${point.latitude}_${point.longitude}');

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
    final trimmedArea = area
        .replaceAll(RegExp(r'(POLYGON \(\(|\)\))'), '')
        .replaceAll(RegExp(r'(LINESTRING \(|\))'), '');
    final coordinatePairs = trimmedArea.split(',');
    return coordinatePairs.map((pair) {
      final coords = pair.trim().split(' ');
      final lat = double.parse(coords[0]);
      final lng = double.parse(coords[1]);
      return LatLng(lat, lng);
    }).toList();
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }





  final List<IconData> cardIcons = [
    Icons.map,
    Icons.notifications_active_outlined,
    Icons.local_parking_outlined,
    Icons.personal_injury_rounded,
  ];

  final List<String> imagePaths = [
    "assets/history_today_icon.png",
    "assets/report_icon.png",
    "assets/geofence_icon.png",
    "assets/notification_icon.png",
    "assets/parking_icon.png",
    "assets/driver_icon.png",
    "assets/share_icon.png",
    "assets/maintenace_today_icon.png",
    "assets/wallet_icon.png",
    "assets/share_devices.png",
  ];

  final List<Color> cardcolors = [
    Colors.green.shade200,
    Colors.blue.shade200,
    Colors.orange.shade200,
    Colors.red.shade200,
  ];
  final List<Color> iconColors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
  ];
  final List<Text> cardtext = [

    Text(
      "History",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
    Text(
      "Report",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
    Text(
      "Geofence",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
    Text(
      "Notification",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
    Text(
      "Towing",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
    Text(
      "Driver",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
    Text(
      "Share",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
    Text(
      "Maintenance",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 10),
    ),
    Text(
      "My documents",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
    Text(
      "Share device",
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 11),
    ),
  ];
  int selectedIndex = 0;

  DateTime _calculateExpirationTime(
      DateTime currentTime, DateTime expirationTime) {
    // Calculate time difference between current time and expiration time
    final timeDifference = expirationTime.difference(currentTime);

    // Adjust expiration time based on selected option
    if (_selectedOption == '5minutes') {
      return currentTime.add(const Duration(minutes: 5));
    } else if (_selectedOption == '10minutes') {
      return currentTime.add(const Duration(minutes: 10));
    } else if (_selectedOption == '30minutes') {
      return currentTime.add(const Duration(minutes: 30));
    } else if (_selectedOption == 'oneDay') {
      return currentTime.add(const Duration(minutes: 1440));
    } else if (_selectedOption == '15Day') {
      return currentTime.add(const Duration(minutes: 21600));
    } else {
      // Default to the original expiration time if no valid option is selected
      return expirationTime;
    }
  }

  void _showCustomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Select Options',
            style: TextStyle(color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      '5 minutes',
                      style: TextStyle(color: Colors.black),
                    )
                  ],
                ),
                value: '5minutes',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                  });
                  Navigator.pop(context);
                  openUrlWithToken(DateTime.now().toUtc().toIso8601String());
                },
              ),
              RadioListTile(
                title: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      '10 minutes',
                      style: TextStyle(color: Colors.black),
                    )
                  ],
                ),
                value: '10minutes',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                  });
                  Navigator.pop(context);
                  openUrlWithToken(DateTime.now().toUtc().toIso8601String());
                },
              ),
              RadioListTile(
                title: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.orange),
                    SizedBox(width: 10),
                    Text(
                      '30 minutes',
                      style: TextStyle(color: Colors.black),
                    )
                  ],
                ),
                value: '30minutes',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                  });
                  Navigator.pop(context);
                  openUrlWithToken(DateTime.now().toUtc().toIso8601String());
                },
              ),
              RadioListTile(
                title: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.indigo),
                    SizedBox(width: 10),
                    Text(
                      'One Day',
                      style: TextStyle(color: Colors.black),
                    )
                  ],
                ),
                value: 'oneDay',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                  });
                  Navigator.pop(context);
                  openUrlWithToken(DateTime.now().toUtc().toIso8601String());
                },
              ),
              RadioListTile(
                title: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.blue),
                    SizedBox(width: 10),
                    Text(
                      '15 Day',
                      style: TextStyle(color: Colors.black),
                    )
                  ],
                ),
                value: '15Day',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                  });
                  Navigator.pop(context);
                  openUrlWithToken(DateTime.now().toUtc().toIso8601String());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onMapTypeSelected(MapType selectedMapType) {
    setState(() {
      currentMapType = selectedMapType;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentDateTime =
        DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    Color textColor = widget.battery < 20 ? Colors.red : Colors.green;
    return Scaffold(
        // backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8.0),
            ),
            child: AppBar(
              backgroundColor: Colors.grey.shade300,
              leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.black,
                ),
              ),
              title: ListTile(
                title: Text(
                  widget.carNumber,
                  style: GoogleFonts.robotoSlab(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  // currentDateTime,
                  // "Last Update :${widget.lastUpdate}",
                  widget.lastUpdate,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
        body: Consumer<CarDetailsProvider>(
            builder: (context, carDetailsProvider, child) {
          final carDetails = carDetailsProvider.carDetails;
          return Stack(children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Image.asset(widget.imagePath2),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Stack(children: [
                      isLoading
                          ? Center(
                              child: LoadingAnimationWidget.threeArchedCircle(
                              color: Colors.black,
                              size: 50,
                            ))
                          : GoogleMap(
                              mapType: currentMapType,
                              onMapCreated: (GoogleMapController controller) {
                                mapController = controller;
                              },
                              initialCameraPosition: CameraPosition(
                                target: carLocation ?? const LatLng(0.0, 0.0),
                                zoom: zoomLevel,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId("car"),
                                  position:
                                      carLocation ?? const LatLng(0.0, 0.0),
                                  icon: customIcon,
                                  rotation: carRotation,
                                  onTap: () {
                                    setState(() {
                                      isCardVisible = !isCardVisible;
                                    });
                                  },
                                ),
                              },
                              onCameraMove: (CameraPosition position) {
                                zoomLevel = position.zoom;
                              },
                              minMaxZoomPreference:
                                  const MinMaxZoomPreference(2, 30),
                              polylines: {
                                Polyline(
                                  polylineId: const PolylineId("carPath"),
                                  points: polylinePoints,
                                  color: Colors.blue,
                                  width: 5,
                                ),
                                geofencePolyline, // Add the red geofence polyline
                              },
                              circles: geofenceCircles, // Add the circles here
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              compassEnabled: true,
                              mapToolbarEnabled: true,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                            ),
                      Positioned(
                        left: 10,
                        top: 70,
                        child: SizedBox(
                          width: screenHeight * 0.063,
                          child: Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.grey,
                                            offset: Offset(2, 0),
                                            blurRadius: 4,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                        color: widget.status == true
                                            ? Colors.white
                                            : Colors.white,
                                        shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        "${widget.battery}%",
                                        style: GoogleFonts.poppins(
                                            color: textColor, fontSize: 8),
                                      ),
                                    ),
                                  ),
                                  Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              offset: Offset(2, 0),
                                              blurRadius: 4,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                          color: widget.status == true
                                              ? Colors.white
                                              : Colors.white,
                                          shape: BoxShape.circle),
                                      child: Icon(
                                        Icons.gps_fixed_outlined,
                                        size: 15.0,
                                        color: widget.status == true
                                            ? Colors.green
                                            : Colors.grey,
                                      )),
                                  Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              offset: Offset(2, 0),
                                              blurRadius: 4,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                          color: widget.status == true
                                              ? Colors.white
                                              : Colors.white,
                                          shape: BoxShape.circle),
                                      child: Icon(
                                        Icons.signal_cellular_alt_outlined,
                                        size: 15.0,
                                        color: widget.status == true
                                            ? Colors.green
                                            : Colors.grey,
                                      )),
                                  Container(
                                      height: 50,
                                      width: 50,
                                      decoration: const BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey,
                                              offset: Offset(2, 0),
                                              blurRadius: 4,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                          color: Colors.white,
                                          shape: BoxShape.circle),
                                      child: Icon(Icons.key,
                                          size: 15.0,
                                          color: widget.carSpeed == 0 &&
                                                  widget.Engine == true
                                              ? Colors.yellow
                                              : widget.carSpeed > 0 &&
                                                      widget.Engine == true
                                                  ? Colors.green
                                                  : Colors.red)),
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: const BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey,
                                            offset: Offset(2, 0),
                                            blurRadius: 4,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                        color: Colors.white,
                                        shape: BoxShape.circle),
                                    child: PopupMenuButton<MapType>(
                                      padding: EdgeInsets.zero,
                                      icon: const Padding(
                                        padding: EdgeInsets.only(right: 0),
                                        child: Icon(
                                          Icons.settings,
                                          size: 11,
                                          color: Colors.black,
                                        ),
                                      ),
                                      color: Colors.black,
                                      onSelected: _onMapTypeSelected,
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: MapType.normal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Normal',
                                                style: GoogleFonts.poppins(
                                                    color: Colors.grey.shade500,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: MapType.satellite,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Satellite',
                                                  style: GoogleFonts.poppins(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: MapType.terrain,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Terrain',
                                                  style: GoogleFonts.poppins(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: MapType.hybrid,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Hybrid',
                                                  style: GoogleFonts.poppins(
                                                      color:
                                                          Colors.grey.shade500,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 65, // Adjust as needed
                        right: 5, // Adjust as needed
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                mapController?.animateCamera(
                                  CameraUpdate.zoomIn(),
                                );
                              },
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF5E5E5E),
                                        Color(0xFF3E3E3E),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight),
                                  boxShadow: [
                                    const BoxShadow(
                                      color: Colors.grey,
                                      offset: Offset(2, 0),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.grey[500]!,
                                      offset: const Offset(-1, -1),
                                      blurRadius: 2,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                mapController?.animateCamera(
                                  CameraUpdate.zoomOut(),
                                );
                              },
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF5E5E5E),
                                        Color(0xFF3E3E3E),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight),
                                  boxShadow: [
                                    const BoxShadow(
                                      color: Colors.grey,
                                      offset: Offset(2, 0),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.grey[500]!,
                                      offset: const Offset(-1, -1),
                                      blurRadius: 2,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: SingleChildScrollView(
                          // scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(

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
                                  borderRadius: BorderRadius.circular(
                                      5.0), // Adjust the value as needed
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${widget.carSpeed.roundToDouble()} Km/Hr",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      "Speed",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                              Container(

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
                                  borderRadius: BorderRadius.circular(
                                      5.0), // Adjust the value as needed
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${widget.Odometer} km",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      "Odometer",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                              Container(

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
                                  borderRadius: BorderRadius.circular(
                                      5.0), // Adjust the value as needed
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "0.00 km",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      "Today's Km",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
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
                                  borderRadius: BorderRadius.circular(
                                      5.0), // Adjust the value as needed
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$odometerValue km",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      "Last 24h Km",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                              Container(

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
                                  borderRadius: BorderRadius.circular(
                                      5.0), // Adjust the value as needed
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _etaText ?? "00:00:00",
                                        style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        "ETA",
                                        style: GoogleFonts.poppins(
                                            color: Colors.black, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(

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
                                  borderRadius: BorderRadius.circular(
                                      5.0), // Adjust the value as needed
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.fuel.toStringAsFixed(2) ??
                                            "0.00",
                                        style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        "Fuel",
                                        style: GoogleFonts.poppins(
                                            color: Colors.black, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -10,
                        left: 10,
                        right: 10,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
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
                              borderRadius: BorderRadius.circular(
                                  5.0), // Adjust the value as needed
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Text(
                                        carAddress == ""
                                            ? widget.address
                                            : carAddress,
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  Container(
                    alignment: Alignment.bottomCenter,
                    height: MediaQuery.of(context).size.height * 0.32,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 2,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: GridView.builder(
                      shrinkWrap: false,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing:
                                  0.0, // Adjust this value to reduce horizontal spacing
                              mainAxisSpacing: 0.0, //
                              childAspectRatio: 1.4),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _navigateToScreen(index);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: Image.asset(
                                    imagePaths[index],
                                  ),
                                ),
                                cardtext[index],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ]);
        }));
  }

  void _navigateToScreen(int index) {
    switch (index) {
      // case 0:
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //       builder: (context) => LiveMap(
      //           todaysKm: odometerValue.toString(),
      //           MovingTime: totalRunningTime,
      //           StopTime: StopTime,
      //           carNumber: widget.carNumber,
      //           carID: widget.id,
      //           lastUpdate: widget.lastUpdate)),
      // );
      // break;
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DayCount(
              carID: widget.id,
              carNumber: widget.carNumber,
              address: widget.address,
              todaysKm: widget.Odometer,
              // carID: widget.id, historyPath: [], distanceTraveled: 0, engineOnTime: '',
            ),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatusCard(
                carID: widget.id,
                // selectedDay: '',
                carNumber: widget.carNumber,
                lastUpdate: widget.lastUpdate,
                odometer: widget.Odometer,
                imagePath: widget.imagePath,
                address: widget.address),
          ),
        );
        break;
      case 2:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MapScreen(carID: widget.id)));

        break;
      case 3:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NotificationScreen(
                      carID: widget.id,
                      carNumber: widget.carNumber,
                    )));
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/my_google.jpg'), // Replace with your image path
                        fit: BoxFit
                            .cover, // Adjust the fit as per your requirement
                      ),
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 1.0, sigmaY: 1.0), // Adjust the blur intensity
                    child: Container(
                      color: Colors.black.withOpacity(
                          0.3), // Optional: add a slight dark overlay
                    ),
                  ),
                  Center(
                    child: AdvancedConfirmDialog(
                      carId: widget.id,
                      title: 'Enable Towing',
                      message: 'Do you want to enable parking?',
                      carNumber: widget.carNumber,
                      latitude: lat,
                      longitude: long,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverScreen(
              carNumber: widget.carNumber,
              carId: widget.id,
            ),
            // builder: (context) => DriverDetails(),
          ),
        );
        break;
      case 6:
        _showCustomDialog();
        break;
      case 7:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaintenanceScreen(
              carNumber: widget.carNumber,
              carId: widget.id,
            ),
            // builder: (context) => GeofencingRouteMap(),
          ),
        );
        break;
      case 8:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentLockerScreen(
              CarID: widget.id,
            ),
          ),
        );
        break;
      case 9:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShareDevice(
              carID: widget.id,
              deviceName:  widget.carNumber
            ),
          ),
        );
        break;
    }
  }
}

class AdvancedConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final int carId;
  final String carNumber;
  final double latitude;
  final double longitude;

  const AdvancedConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.carId,
    required this.carNumber,
    required this.latitude,
    required this.longitude,
  });

  @override
  _AdvancedConfirmDialogState createState() => _AdvancedConfirmDialogState();
}

class _AdvancedConfirmDialogState extends State<AdvancedConfirmDialog> {
  final storage = const FlutterSecureStorage();
  bool geofenceEnabled = false;
  int geofenceId = 0;

  @override
  void initState() {
    super.initState();
    geofenceEnabled = false;
  }

  Future<void> toggleGeofence() async {
    final apiUrl = dotenv.env['GEOFENCE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      if (!geofenceEnabled) {
        final double lat = widget.latitude;
        final double lon = widget.longitude;
        const double offset =
            0.00001; // Change this offset as needed for square size

        // Define the square points
        final String polygonCoords =
            "POLYGON ((${lat - offset} ${lon - offset}, ${lat + offset} ${lon - offset}, ${lat + offset} ${lon + offset}, ${lat - offset} ${lon + offset}, ${lat - offset} ${lon - offset}))";
        final Map<String, dynamic> data = {
          "area": polygonCoords,
          "name": widget.carNumber
        };
        try {
          final deviceResponse = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Cookie': sessionCookies,
              'Content-Type': 'application/json',
            },
            body: json.encode(data),
          );

          if (deviceResponse.statusCode == 200) {
            final jsonResponse = json.decode(deviceResponse.body);

            final int id = jsonResponse['id'];

            final permissionApiUrl = dotenv.env["PERMISSION_API"]!;
            setState(() {
              geofenceEnabled = true;
              geofenceId = id;
            });
            final Map<String, dynamic> data = {
              "deviceId": "${widget.carId}",
              "geofenceId": id
            };
            final geofenceResponse = await http.post(
              Uri.parse(permissionApiUrl),
              headers: {
                'Cookie': sessionCookies,
                'Content-Type': 'application/json',
              },
              body: json.encode(data),
            );
            final geoResponse = json.decode(geofenceResponse.body);

            setState(() {
              geofenceEnabled = true;
              geofenceId = id;
            });
          } else {}
        } catch (e) {}
      } else {
        final geofenceId1 =
            geofenceId; // Replace with your logic to get the geofence ID
        final deleteApiUrl = "$apiUrl/$geofenceId1";

        try {
          final response = await http.delete(
            Uri.parse(deleteApiUrl),
            headers: {
              'Cookie': sessionCookies,
            },
          );

          if (response.statusCode == 200) {
            setState(() {
              geofenceEnabled = false;
            });
          } else {}
        } catch (e) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentDateTime =
        DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: Colors.grey.shade400,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1), // changes position of shadow
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                          fontSize: 20.0, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      widget.message,
                      style: GoogleFonts.poppins(
                          fontSize: 13.0, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // const Divider(
              //   height: 0,
              //   color: Colors.grey,
              // ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
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
                              color: Colors.red.shade900)),
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
                        toggleGeofence();
                        if (geofenceEnabled) {
                          Navigator.of(context)
                              .pop(); // Dismiss dialog if geofence was disabled
                        }
                      },
                      child: Text(
                        geofenceEnabled ? 'Disable' : 'Enable',
                        style: GoogleFonts.poppins(
                          color: geofenceEnabled ? Colors.red : Colors.green,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
