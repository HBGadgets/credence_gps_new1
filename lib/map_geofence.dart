
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:credence/provider/notification_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  await dotenv.load();
  runApp(const MapScreen(carID: 0));
}

class Geofence {
  final int id;
  final String name;
  final String? area;

  Geofence({
    required this.id,
    required this.name,
    required this.area,
  });
}

class MapScreen extends StatefulWidget {
  final int carID;

  const MapScreen({super.key, required this.carID});
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  Geofence? selectedGeofence;
  List<Geofence> geofences = [];
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool isLoading = true;
  String? lastNotifiedEvent;

  @override
  void initState() {
    super.initState();
    _fetchGeofences();
    EventNotification();
  }

  Future<void> _fetchGeofences() async {
    final String geofenceApi = dotenv.env['GEOFENCE_API']!;
    final String apiUrl = "$geofenceApi?deviceId=${widget.carID}";
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      try {
        final response = await http.get(
          // Uri.parse(apiUrl),
          Uri.parse(geofenceApi),
          headers: {'Cookie': sessionCookies},);
        if (response.statusCode == 200) {
          setState(() {
            isLoading = false;
          });
          final List<dynamic> jsonResponse = json.decode(response.body);
          for (var geoJson in jsonResponse) {
            final id = geoJson['id'];
            final name = geoJson['name'];
            final area = geoJson['area'];
            final geofence = Geofence(
              name: name,
              area: area,
              id: id,
            );
            geofences.add(geofence);
          }
          setState(() {
            geofences = geofences;
          });
        } else {
        }
      } catch (error) {
      }
    } else {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(8.0),
          ),
          child: AppBar(
            backgroundColor: Colors.black,
            elevation: 10,
            leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade700.withOpacity(0.5),
                      width: 1.0,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              "Geofence List",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: Colors.white,
          size: 50,
        ),
      )
          : ListView.builder(
        itemCount: geofences.length,
        itemBuilder: (context, index) {
          Geofence geofence = geofences[index];
          return Padding(
            padding: const EdgeInsets.all(3.0),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: InkWell(
                      onTap: () {
                        if (geofence.area != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GeofenceMap(
                                coordinates: geofence.area!,
                                name: geofences[index].name,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        color: Colors.grey.shade800,
                        child: Row(
                          children: [
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: Image.asset(
                                "assets/geofence_stop.png",
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "My Geofence: ${geofence.name}",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(
                  color: Colors.grey,
                  height: 1,
                  thickness: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> EventNotification() async {
    final String notificationApi = dotenv.env['NOTIFICATION_API']!;
    const String carDetailsApiUrl = "http://103.174.103.78:8085/alarm.ajax.php";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        // Uri.parse(carDetailsApiUrl),
        Uri.parse(notificationApi),
        headers: {
          'Cookie': sessionCookies,
        },
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          final latestEvent = jsonResponse.first;
          final eventMessage = '${latestEvent['c']}  ${latestEvent['a']}';
          final headerMessage = '${latestEvent['c']}';
          if (lastNotifiedEvent != eventMessage) {
            showNotification(eventMessage, headerMessage);
            lastNotifiedEvent = eventMessage;
          }
        }
      } else {
      }
    } else {
      Fluttertoast.showToast(
        msg: "Login again",
        toastLength: Toast.LENGTH_SHORT,
      );
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

    await flutterLocalNotificationsPlugin.show(
      0,
      header,
      message,
      platformChannelSpecifics,
      payload: 'item x',
    );
    Provider.of<NotificationProvider>(context, listen: false)
        .setNewNotification('New Event', message);
  }
}
class GeofenceMap extends StatefulWidget {
  final String coordinates;
  final String? name;

  const GeofenceMap({super.key, required this.coordinates, this.name});

  @override
  _GeofenceMapState createState() => _GeofenceMapState();
}

class _GeofenceMapState extends State<GeofenceMap> {
  late GoogleMapController mapController;
  final List<LatLng> polylineCoordinates = [];
  final Set<Marker> markers = {};
  late LatLng initialPosition;
  LatLng? midpoint;
  MapType currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    parseCoordinates();
    if (polylineCoordinates.isNotEmpty) {
      initialPosition = polylineCoordinates.first;
      midpoint = calculateMidpoint();
      if (midpoint != null && widget.name != null) {
        markers.add(Marker(
          markerId: const MarkerId('midpoint'),
          position: midpoint!,
          infoWindow: InfoWindow(title: widget.name),
        ));
      }
    } else {
      initialPosition = const LatLng(0, 0); // Default position
    }
  }

  void _onMapTypeSelected(MapType selectedMapType) {
    setState(() {
      currentMapType = selectedMapType;
    });
  }

  void parseCoordinates() {
    final regex = RegExp(r"(-?\d+\.\d+)[\s,]+(-?\d+\.\d+)");
    final matches = regex.allMatches(widget.coordinates);
    for (final match in matches) {
      if (match.groupCount >= 2) {
        final lat = double.parse(match.group(1)!);
        final lng = double.parse(match.group(2)!);
        final position = LatLng(lat, lng);
        polylineCoordinates.add(position);
        // markers.add(Marker(
        //   markerId: MarkerId(position.toString()),
        //   position: position,
        //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        // ));
      }
    }
  }

  LatLng? calculateMidpoint() {
    if (polylineCoordinates.isEmpty) return null;

    double totalLat = 0;
    double totalLng = 0;

    for (var coord in polylineCoordinates) {
      totalLat += coord.latitude;
      totalLng += coord.longitude;
    }

    return LatLng(totalLat / polylineCoordinates.length, totalLng / polylineCoordinates.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: currentMapType,
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 18.0,
            ),
            markers: markers,
            polylines: {
              Polyline(
                polylineId: const PolylineId('geofence_polyline'),
                color: Colors.amber.shade800,
                width: 1,
                points: polylineCoordinates,
              ),
            },
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    offset: Offset(2, 0),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<MapType>(
                icon: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.settings,
                    size: 15,
                    color: Colors.white,
                  ),
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
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MapType.satellite,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Satellite',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MapType.terrain,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terrain',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MapType.hybrid,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hybrid',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

