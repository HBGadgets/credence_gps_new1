import 'package:credence/provider/car_address_provider.dart';
import 'package:credence/provider/car_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

import 'model/car_location.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  home: const LiveVehicle(
    carNumber: '',
    carID: 0,
    lastUpdate: '',
    todaysKm: '',
    MovingTime: '',
    StopTime: '',
  ),
));

class LiveVehicle extends StatefulWidget {
  final String carNumber;
  final int carID;
  final String lastUpdate;
  final String todaysKm;
  final String MovingTime;
  final String StopTime;

  const LiveVehicle(
      {super.key,
        required this.carNumber,
        required this.carID,
        required this.lastUpdate,
        required this.todaysKm,
        required this.MovingTime,
        required this.StopTime});
  @override
  _LiveVehicleState createState() => _LiveVehicleState();
}

class _LiveVehicleState extends State<LiveVehicle> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final storage = const FlutterSecureStorage();
  late GoogleMapController mapController;
  LatLng carLocation = const LatLng(0, 0);
  late Timer _timer;
  double carSpeed = 0;
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
  double odometerValue = 0.0;
  double todayodometerValue = 0.0; // Declare it here
  MapType _currentMapType = MapType.normal;
  List<LatLng> polylinePoints = [];
  double lat = 0.0;
  double long = 0.0;
  double zoomLevel = 16.0;
  bool isLoading = true;

  _LiveVehicleState() {
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
      fetchLiveVehicle();
    });
  }

  @override
  void initState() {
    super.initState();
    _LiveVehicleState();

    // initializeNotifications();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  Future<void> fetchLiveVehicle() async {
    final String deviceApi = dotenv.env['DEVICE_API']!;
    final String carDetailsApiUrl = dotenv.env['LIVE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(carDetailsApiUrl),
          headers: {
            'Cookie': sessionCookies,
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          if (jsonResponse.isNotEmpty) {
            final List<Map<String, dynamic>> carDataList =
            jsonResponse.cast<Map<String, dynamic>>();

            for (final carItem in carDataList) {
              final int deviceId =
              carItem['deviceId']; // Get the deviceId from the response
              if (deviceId == widget.carID) {
                // Check if deviceId matches the carID
                final double latitude = carItem['latitude'].toDouble();
                final double longitude = carItem['longitude'].toDouble();
                final double rotationAngle = carItem['course'].toDouble();
                final int carIds = carItem['id'];
                final bool ignition =
                    carItem['attributes']['ignition'] ?? false;
                final double speed = carItem['speed'] * 1.852;
                final todayDistance = carItem['attributes']['distance'] ?? 0.0;
                final totalDistance =
                    carItem['attributes']['totalDistance'] / 1000 ?? 0.0;
                final deviceDetailsResponse = await http.get(
                  Uri.parse("$deviceApi/$deviceId"),
                  headers: {'Cookie': sessionCookies},
                );

                if (deviceDetailsResponse.statusCode == 200) {
                  // Parse the response and extract vehicle type and name
                  final deviceDetailsJson =
                  json.decode(deviceDetailsResponse.body);
                  final String vehicleType = deviceDetailsJson['category'] ??
                      'car'; // Default to 'car'
                  final String status =
                  getStatus(speed, ignition); // Get status of the car

                  // Call loadCustomIcon with vehicleType and status
                  loadCustomIcon(vehicleType: vehicleType, status: status);
                }

                if (latitude > 0 && longitude > 0) {
                  final convertedLocation = LatLng(latitude, longitude);
                  final address = await getAddress(latitude, longitude);

                  setState(() {
                    carAddresses[carIds] = address;
                    polylinePoints.add(convertedLocation);
                    carRotation = rotationAngle;
                    carLocation = convertedLocation;
                    carAddress = address;
                    carSpeed = speed.roundToDouble();
                    todayodometerValue = todayDistance.roundToDouble();
                    odometerValue = totalDistance.roundToDouble();
                    lat = latitude;
                    long = longitude;
                    isLoading = false;
                  });

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
                    carLocation = const LatLng(0, 0);
                  });
                }
              }
            }
          } else {
          }
        } else {
        }
      } catch (e) {
      }
    } else {
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
            imagePath = 'ssets/car_rt.png';
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
      customIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(30, 30)),
        iconPath,
      );
    } catch (e) {
    }
    setState(() {});
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return "${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
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

  void moveCameraToCarLocation() {
    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: carLocation,
          zoom: zoomLevel,
        ),
      ));
    }
  }

  double extractTodayOdometerValue(String odometerInfo) {
    final regex = RegExp(r'24H odometer: ([\d.]+)km');
    final match = regex.firstMatch(odometerInfo);
    if (match != null) {
      final odometerString = match.group(1);
      if (odometerString != null) {
        final double? odometerValue = double.tryParse(odometerString);
        if (odometerValue != null) {
          return odometerValue;
        }
      }
    }
    return 0.0; // Default value if not found or parsing error.
  }

  double extractOdometerValue(String odometerInfo) {
    final regex = RegExp(r'Odometer: ([\d.]+)km');
    final match = regex.firstMatch(odometerInfo);
    if (match != null) {
      final odometerString = match.group(1);
      if (odometerString != null) {
        final double? odometerValue = double.tryParse(odometerString);
        if (odometerValue != null) {
          return odometerValue;
        }
      }
    }
    return 0.0; // Default value if not found or parsing error.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.1,
        backgroundColor: Colors.white,
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
            '${widget.carNumber} ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            "Latest Update : ${widget.lastUpdate}",
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 12),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (carLocation != null)
          // Inside the build method, modify the GoogleMap widget
            isLoading
                ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.black,
                  size: 50,
                ))
                : GoogleMap(
              mapType: _currentMapType,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                moveCameraToCarLocation();
              },
              initialCameraPosition: CameraPosition(
                target: carLocation,
                zoom: zoomLevel,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("car"),
                  position: carLocation,
                  icon: customIcon,
                  rotation: carRotation,
                  onTap: () {
                    setState(() {
                      isCardVisible = !isCardVisible;
                    });
                  },
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId("carPath"),
                  points: polylinePoints,
                  color: Colors.blue,
                  width: 3,
                ),
              },
            ),
          Positioned(
            top: 66.0,
            right: 16.0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      zoomLevel++;
                      moveCameraToCarLocation();
                    });
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.05,
                    width: MediaQuery.of(context).size.width * 0.07,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5E5E5E),
                            Color(0xFF3E3E3E),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      boxShadow: [
                        const BoxShadow(
                          color: Colors.black,
                          offset: Offset(2, 0),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.grey[900]!,
                          offset: const Offset(-4, -4),
                          blurRadius: 6,
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
                const SizedBox(
                  height: 10,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      zoomLevel--;
                      moveCameraToCarLocation();
                    });
                  },
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.05,
                    width: MediaQuery.of(context).size.width * 0.07,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5E5E5E),
                            Color(0xFF3E3E3E),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      boxShadow: [
                        const BoxShadow(
                          color: Colors.black,
                          offset: Offset(2, 0),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.grey[900]!,
                          offset: const Offset(-4, -4),
                          blurRadius: 6,
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


          if (isCardVisible)
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 80,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  _showMapTypeMenu(context);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.layers,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMapTypeMenu(BuildContext context) {
    // Get the position of the center-right of the screen
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset centerRight =
    Offset(overlay.size.width, overlay.size.height / 2);

    // Show the menu as a small card at the center-right of the screen
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        centerRight.dx - 100.0, // Adjust the horizontal position
        centerRight.dy - 100.0, // Adjust the vertical position
        centerRight.dx,
        centerRight.dy + 100.0, // Adjust the height of the card
      ),
      items: [
        PopupMenuItem(
          child: _buildMapTypeItem(MapType.normal, Icons.map),
        ),
        PopupMenuItem(
          child: _buildMapTypeItem(MapType.satellite, Icons.satellite),
        ),
        PopupMenuItem(
          child: _buildMapTypeItem(MapType.terrain, Icons.terrain),
        ),
        // Add more items as needed
      ],
    );
  }

  Widget _buildMapTypeItem(MapType mapType, IconData icon) {
    return GestureDetector(
      onTap: () {
        _changeMapType(mapType);
        Navigator.pop(context); // Close the bottom sheet
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8.0),
          Text(
            mapType == MapType.normal
                ? 'Normal'
                : mapType == MapType.satellite
                ? 'Satellite'
                : 'Traffic',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _changeMapType(MapType mapType) {
    setState(() {
      _currentMapType = mapType;
    });
    // Add any additional logic you need when the map type changes
  }

  void openGoogleMaps(double latitude, double longitude) async {
    String url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class NoDataScreen extends StatelessWidget {
  const NoDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.grey,
      body: Center(
        child: Text(
          'No Data Available',
          style: TextStyle(color: Colors.white, fontSize: 18.0),
        ),
      ),
    );
  }
}

String getStatus(double speed, bool ignition) {
  if (!ignition) {
    return 'Stopped';
  } else {
    if (speed <= 10.0) {
      return 'Idle';
    } else {
      return 'Running';
    }
  }
}
