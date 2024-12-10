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
import 'package:geocoding/geocoding.dart';

class AllVehicleLive extends StatefulWidget {
  const AllVehicleLive({Key? key}) : super(key: key);

  @override
  State<AllVehicleLive> createState() => _AllVehicleLiveState();
}

class _AllVehicleLiveState extends State<AllVehicleLive> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final storage = const FlutterSecureStorage();
  late GoogleMapController mapController;
  LatLng carLocation = const LatLng(21.87848484, 79.11644640);
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
  List<Marker> markers = [];
  bool isLoading = true;
  _liveMapState() {
    fetchLiveMap();
  }

  @override
  void initState() {
    super.initState();
    _liveMapState();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  Future<void> fetchLiveMap() async {
    final String? carDetailsApiUrl = dotenv.env['LIVE_API'];
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(carDetailsApiUrl!),
          headers: {
            'Cookie': sessionCookies,
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          if (jsonResponse.isNotEmpty) {
            final devicesResponse = await http.get(
              Uri.parse(dotenv.env['DEVICE_API']!),
              headers: {'Cookie': sessionCookies},
            );

            if (devicesResponse.statusCode == 200) {
              final List<dynamic> devicesJson =
              json.decode(devicesResponse.body);

              // Create a map to store device id -> vehicle category mapping
              final Map<int, String> deviceCategoryMap = {};

              // Fill deviceCategoryMap with device id and category
              for (final deviceItem in devicesJson) {
                final int deviceId = deviceItem['id'];
                final String category =
                    deviceItem['category'] ?? 'car'; // Default to 'car'
                deviceCategoryMap[deviceId] = category;
              }

              // Loop through vehicles from positions API and create markers
              for (final carItem in jsonResponse) {
                final double latitude = carItem['latitude'].toDouble();
                final double longitude = carItem['longitude'].toDouble();
                final int deviceId = carItem['deviceId'];
                final double speed = carItem['speed'] * 1.852;
                final bool ignition =
                    carItem['attributes']['ignition'] ?? false;

                final String vehicleType = deviceCategoryMap[deviceId] ?? 'car';
                final String vehicleName = devicesJson.firstWhere(
                        (device) => device['id'] == deviceId,
                    orElse: () => {})['name'] ??
                    'Unknown Vehicle';
                final String Address = await getAddress(latitude, longitude);

                markers.add(
                  Marker(
                    markerId: MarkerId(carItem['id'].toString()),
                    position: LatLng(latitude, longitude),
                    infoWindow:
                    InfoWindow(title: vehicleName, snippet: Address),
                    icon: await loadCustomIcon(
                        vehicleType: vehicleType,
                        status: getStatus(speed, ignition)),
                    rotation: carItem['course'].toDouble(),
                    onTap: () {
                      setState(() {
                        // Handle marker tap if needed
                        isCardVisible = true;
                      });
                    },
                  ),
                );
              }
              setState(() {
                isLoading = false;
              });
            } else {

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

  Future<BitmapDescriptor> loadCustomIcon(
      {String vehicleType = '', String status = ''}) async {
    String imagePath = ""; // Default icon path

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
        imagePath = ''; // Default icon path
        break;
    }

    final String iconPath = imagePath;

    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(30, 30)),
        iconPath,
      );
    } catch (e) {
      return BitmapDescriptor
          .defaultMarker; // Return default marker if icon loading fails
    }
  }

  Future<LatLng> convertCoordinates(double x, double y) async {
    final double latitude = y / 1000000;
    final double longitude = x / 1000000;
    return LatLng(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.1,
        backgroundColor: Colors.blueGrey.shade900,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          'All Vehicles',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: Colors.black,
          size: 50,
        ),
      )
          : Stack(
        children: [
          if (carLocation != null)
          // Inside the build method, modify the GoogleMap widget
            GoogleMap(
              mapType: _currentMapType,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                mapController.setMapStyle('''
                    [
                      {
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "featureType": "administrative.locality",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#263c3f"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#6b9a76"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#38414e"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#212a37"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#9ca5b3"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#1f2835"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#f3d19c"
                          }
                        ]
                      },
                      {
                        "featureType": "transit",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#2f3948"
                          }
                        ]
                      },
                      {
                        "featureType": "transit.station",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#515c6d"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      }
                    ]
                ''');
              },
              initialCameraPosition: CameraPosition(
                target: carLocation,
                zoom: 8,
              ),
              markers: Set<Marker>.of(markers),
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
  }
}

class NoDataScreen extends StatelessWidget {
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
