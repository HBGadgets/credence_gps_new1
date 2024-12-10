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
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:url_launcher/url_launcher.dart';
import 'model/car_location.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.dark(),
  home: const LiveMap(
    carNumber: '',
    carID: 0,
    lastUpdate: '',
    todaysKm: '',
    MovingTime: '',
    StopTime: '',
  ),
));

class LiveMap extends StatefulWidget {
  final String carNumber;
  final int carID;
  final String lastUpdate;
  final String todaysKm;
  final String MovingTime;
  final String StopTime;

  const LiveMap(
      {super.key,
        required this.carNumber,
        required this.carID,
        required this.lastUpdate,
        required this.todaysKm,
        required this.MovingTime,
        required this.StopTime});
  @override
  _LiveMapState createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
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
  String? carAddress;
  Map<int, String> carAddresses = {};
  double odometerValue = 0.0;
  double todayodometerValue = 0.0; // Declare it here
  MapType _currentMapType = MapType.normal;
  List<LatLng> polylinePoints = [];
  double lat = 0.0;
  double long = 0.0;
  double zoomLevel = 16.0;
  bool isLoading = true;
  bool dataFetched = false;

  // _LiveMapState() {
  //   _timer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
  //     fetchLiveMap();
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer t) {
      fetchLiveMap();
    });
    // _LiveMapState();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  Future<void> fetchLiveMap() async {
    final String deviceApi = dotenv.env['DEVICE_API']!;
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
                  final deviceDetailsJson =
                  json.decode(deviceDetailsResponse.body);
                  final String vehicleType = deviceDetailsJson['category'] ??
                      'car'; // Default to 'car'
                  final String status =
                  getStatus(speed, ignition); // Get status of the car
                  loadCustomIcon(vehicleType: vehicleType, status: status);
                  if (latitude > 0 && longitude > 0) {
                    final convertedLocation = LatLng(latitude, longitude);
                    final address = await getAddress(latitude, longitude);
                    carAddresses[carIds] = address;
                    polylinePoints.add(convertedLocation);
                    carRotation = rotationAngle;
                    carLocation = convertedLocation;
                    carAddress = address ?? "";
                    carSpeed = speed.roundToDouble();
                    todayodometerValue = todayDistance.roundToDouble();
                    odometerValue = totalDistance.roundToDouble();
                    lat = latitude;
                    long = longitude;
                    setState(() {
                      isLoading = false;
                    });

                    final addressProvider =
                    Provider.of<AddressProvider>(context, listen: false);
                    addressProvider.updateAddress(address);
                    final carLocationProvider =
                    Provider.of<CarLocationProvider>(context,
                        listen: false);
                    final carLocationData = CarLocation(
                      latitude: latitude,
                      longitude: longitude,
                      rotationAngle: rotationAngle,
                      timestamp: DateTime.now(),
                    );
                    carLocationProvider.addLocation(carLocationData);
                    dataFetched = true;
                  }
                }
              }
            }
            if (!dataFetched) {
              setState(() {
                isLoading = false;
                carLocation =
                const LatLng(21.1296, 79.0990); // Default location
              });
            }
          } else {}
        } else {}
      } catch (e) {
        // Handle exceptions
      }
    } else {
      // Handle the case where sessionCookies is null
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
      customIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(30, 30)),
        iconPath,
      );
    } catch (e) {}
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return " ${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}";
      }
    } catch (e) {}
    return "Updating address...";
  }

  MapType currentMapType = MapType.normal;
  void _onMapTypeSelected(MapType selectedMapType) {
    setState(() {
      currentMapType = selectedMapType;
    });
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
    String currentDateTime =
    DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
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
                color: Colors.black, fontSize: 17, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            // currentDateTime,
            // "Last Update :${widget.lastUpdate}",
            widget.lastUpdate,
            style: GoogleFonts.poppins(
                color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
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
              mapType: currentMapType,
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
            top: 20,
            left: 10,
            child: Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    offset: Offset(2, 0),
                    blurRadius: 3,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: PopupMenuButton<MapType>(
                icon: const Icon(
                  Icons.settings,
                  size: 13,
                  color: Colors.white,
                ),
                color: Colors.black,
                onSelected: _onMapTypeSelected,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: MapType.normal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Normal',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade300,
                              fontWeight: FontWeight.w500,
                              fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MapType.satellite,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Satellite',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontWeight: FontWeight.w500,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MapType.terrain,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Terrain',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontWeight: FontWeight.w500,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MapType.hybrid,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hybrid',
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontWeight: FontWeight.w500,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20.0,
            right: 10.0,
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
                    setState(() {
                      zoomLevel--;
                      moveCameraToCarLocation();
                    });
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
          if (!isCardVisible)
            Positioned(
                bottom: 0,
                right: 6,
                left: 6,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset:
                        const Offset(0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: Colors.grey.shade300,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: GestureDetector(
                              onTap: () {
                                openGoogleMaps(lat, long);
                              },
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                                children: [
                                  const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 15,
                                  ),
                                  Expanded(
                                    child: Text(
                                      carAddress?.replaceFirst(
                                          RegExp(r'^, ,\s*'), '') ??
                                          "Address Not Found",
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      openGoogleMaps(lat, long);
                                    },
                                    child: Container(
                                      height: 30,
                                      width: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            50.0), // Adjust the value as needed
                                        color: Colors.white,
                                        image: const DecorationImage(
                                            image:
                                            AssetImage('assets/arrow.png'),
                                            fit: BoxFit
                                                .fitHeight // Replace with your image path
                                        ), // Example background color
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: SfRadialGauge(
                                      axes: <RadialAxis>[
                                        RadialAxis(
                                          minimum: 0,
                                          maximum: 180,
                                          interval: 20,
                                          axisLabelStyle: const GaugeTextStyle(
                                              fontSize: 5,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500),
                                          majorTickStyle: const MajorTickStyle(
                                            length: 7,
                                            thickness: 0.6,
                                            color: Colors.black,
                                          ),
                                          minorTicksPerInterval: 2,
                                          minorTickStyle: const MinorTickStyle(
                                            length: 3,
                                            thickness: 0.6,
                                            color: Colors.green,
                                          ),
                                          axisLineStyle: const AxisLineStyle(
                                            thickness: 4,
                                            color: Colors.grey,
                                          ),
                                          pointers: <GaugePointer>[
                                            NeedlePointer(
                                              value: carSpeed,
                                              needleColor: Colors.red.shade700,
                                              needleLength: 0.5,
                                              needleStartWidth: 0.5,
                                              needleEndWidth: 2,
                                              knobStyle: const KnobStyle(
                                                knobRadius: 0.08,
                                                sizeUnit: GaugeSizeUnit.factor,
                                                color: Colors.black,
                                                borderColor: Colors.red,
                                                borderWidth: 0.02,
                                              ),
                                              tailStyle: const TailStyle(
                                                length: 0.2,
                                                width: 3,
                                                color: Colors.red,
                                                borderWidth: 0.02,
                                                borderColor: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "$carSpeed Km/hr",
                                    style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  height: 15,
                                  width: 60,
                                  color: Colors.grey.shade600,
                                  child: Text(
                                    "Speed",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Column(
                                  children: [
                                    SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: Image.asset("assets/speed.png")),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "$odometerValue",
                                        style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(
                                      "Total distance",
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Column(
                                  children: [
                                    SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: Image.asset(
                                            "assets/clock_time.png")),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "${widget.MovingTime} hr",
                                        style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      'Moving Time',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Column(
                                  children: [
                                    SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: Image.asset(
                                            "assets/kilometer.png")),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        "${widget.todaysKm} Km",
                                        style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      'Today Km',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Column(
                                  children: [
                                    SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: Image.asset(
                                            "assets/clock_time.png")),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: widget.StopTime == ""
                                          ? Text(
                                        "0.0 hr",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                          : Text(
                                        "${widget.StopTime} hr",
                                        style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                      'Stop Time',
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )),
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
