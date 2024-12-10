import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'dart:convert';
import 'latlong_tween.dart';
import 'live_map_screen.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class DayCount extends StatefulWidget {
  final int carID;
  final String carNumber;
  final String? address;
  final String? todaysKm;

  const DayCount({
    super.key,
    required this.carID,
    required this.carNumber,
    this.address,
    this.todaysKm,
  });

  @override
  _DayCountState createState() => _DayCountState();
}

class _DayCountState extends State<DayCount> {
  DateTime? _fromDate;
  // DateTime _fromDate = DateTime.now();
  DateTime? _toDate;
  final DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now().subtract(const Duration(days: 14));

  @override
  void initState() {
    super.initState();
    _focusedDay = _selectedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(8.0),
          ),
          child: AppBar(
            backgroundColor: Colors.black,
            elevation: 0.1,
            leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(
                        bottom: BorderSide(
                      color:
                          Colors.grey.shade700.withOpacity(0.5), // Border color
                      width: 1.0,
                    )),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_outlined,
                    color: Colors.white,
                  ),
                )),
            title: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                    bottom: BorderSide(
                  color: Colors.grey.shade700.withOpacity(0.5), // Border color
                  width: 1.0,
                )),
              ),
              child: ListTile(
                title: Text(
                  "${widget.carNumber} History",
                  style: GoogleFonts.robotoSlab(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0,
              backgroundColor: Colors.grey.shade300,
              child: contentBox(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.37,
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 5, right: 5),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  alignment: Alignment.center,
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.carNumber,
                    style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "From : ",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 12),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: SizedBox(
                      height: 40,
                      width: MediaQuery.of(context).size.width * 0.47,
                      child: CardSelection(
                        title: 'From',
                        date: _fromDate,
                        onDateSelected: (title) {
                          _selectDate(title, context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "To :",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 12),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: SizedBox(
                      height: 40,
                      width: MediaQuery.of(context).size.width * 0.473,
                      child: CardSelection(
                        title: 'To',
                        date: _toDate,
                        onDateSelected: (title) {
                          _selectDate(title, context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      _navigateToHistoryScreen();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      width: 100,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        "Confirm",
                        style: GoogleFonts.poppins(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 40,
                      width: 100,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueGrey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ));
  }

  // void _selectDate(String title, BuildContext context) async {
  //   DateTime? selectedDate = await showDatePicker(
  //     context: context,
  //     initialDate: title == 'From' ? DateTime.now() : _toDate,
  //     firstDate: DateTime(2000),
  //     lastDate: DateTime(2100),
  //   );
  //   if (selectedDate != null) {
  //     TimeOfDay initialTime = title == 'From'
  //         // ? const TimeOfDay(hour: 0, minute: 0) // 12:00 AM for "From"
  //         ? TimeOfDay.now()
  //         : TimeOfDay.now();
  //
  //     TimeOfDay? selectedTime = await showTimePicker(
  //       context: context,
  //       initialTime: initialTime,
  //     );
  //
  //     if (selectedTime != null) {
  //       DateTime selectedDateTime = DateTime(
  //         selectedDate.year,
  //         selectedDate.month,
  //         selectedDate.day,
  //         selectedTime.hour,
  //         selectedTime.minute,
  //       );
  //       DateTime utcDateTime = selectedDateTime.toUtc();
  //       utcDateTime = utcDateTime.subtract(const Duration(hours: 5, minutes: 30));
  //
  //       String formattedDateTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(utcDateTime);
  //       setState(() {
  //         if (title == 'From') {
  //           _fromDate = utcDateTime;
  //         } else {
  //           _toDate = utcDateTime;
  //         }
  //       });
  //     }
  //   }
  // }

  void _selectDate(String title, BuildContext context) async {
    DateTime currentDate = DateTime.now(); // Current date

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate:
          title == 'From' ? DateTime.now() : (_toDate ?? DateTime.now()),
      firstDate:
          title == 'From' ? DateTime(2000) : (_fromDate ?? DateTime(2000)),
      lastDate: currentDate, // Disable future dates
    );

    if (selectedDate != null) {
      TimeOfDay initialTime = title == 'From'
          ? const TimeOfDay(hour: 0, minute: 0) // 12:00 AM for "From"
          : TimeOfDay.now();

      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        String formattedDateTime =
            DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(selectedDateTime);

        setState(() {
          if (title == 'From') {
            _fromDate = selectedDateTime; // Set selected "From" date and time
          } else {
            _toDate = selectedDateTime; // Set selected "To" date and time
          }
        });
      }
    }
  }

  void _navigateToHistoryScreen() {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade900,
        elevation: 10,
        content: Text(
          "Please select both From and To dates",
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 11),
        ),
      ));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return HistoryScreen(
            fromDate: _fromDate!,
            toDate: _toDate!,
            carID: widget.carID,
            carNumber: widget.carNumber,
            address: widget.address,
            todaysKm: widget.todaysKm,
          );
        },
      ),
    );
  }
}

class CardSelection extends StatelessWidget {
  final String title;
  final DateTime? date;
  final ValueChanged<String> onDateSelected;

  const CardSelection({
    super.key,
    required this.title,
    required this.date,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onDateSelected(title);
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Select Date',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                  size: 18,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final int carID;
  final String carNumber;
  final String? address;
  final String? todaysKm;
  final DateTime fromDate;
  final DateTime toDate;

  const HistoryScreen({
    Key? key,
    required this.carID,
    required this.fromDate,
    required this.toDate,
    this.address,
    this.todaysKm,
    required this.carNumber,
  }) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  GoogleMapController? mapController;
  List<LatLng> playbackPoints = [];
  String t2Value = '';
  String t1Value = '';
  double movingKm = 0.0;
  String carAddress = '';
  LatLng carLocation = const LatLng(20.5937, 78.9629);
  double carRotation = 0.0;
  Map<int, String> carAddresses = {};
  double animationSpeed = 1.0; // Initial animation speed
  late AnimationController _animationController;
  bool isAnimating = false;
  Tween<LatLng>? latLngTween;
  Animation<LatLng>? animation;
  String currentTime = '';
  bool isPaused = false;
  String stopTime = '';
  double carSpeed = 0.0;
  double odometerValue = 0.0;
  final storage = const FlutterSecureStorage();
  bool isLoading = true; // Declare _timer at the class level
  final Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylinePoints = [];

  final Completer<void> _cameraAnimationCompleter = Completer<void>();
  List<LatLng> LocationList = [];
  String ignition = "";
  final double _animationSpeed = 20.0;
  double initialLatitude = 0.0;
  double initialLongitude = 0.0;
  double finalLatitude = 0.0;
  double finalLongitude = 0.0;
  LatLng initialPosition = const LatLng(20.5937,
      78.9629); // Define initialPosition at the class level with a default value

  late BitmapDescriptor customIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  List<LatLng> locationList = [];
  int pausedIndex = 0; // Initialize with 0
  late BitmapDescriptor customStartIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

  late BitmapDescriptor customFinishIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

  // late BitmapDescriptor customArrowIcon;

  double zoomLevel = 12.0;
  bool _isUserInteracting = false; // Initial zoom level
  bool isTapped1X = false;
  bool isTapped2X = false;
  bool isTapped3X = false;
  double totalDistance = 0.0; // Initialize total distance
  final String historyApi = dotenv.env['LIVE_API']!;
  BitmapDescriptor? busIcon;
  BitmapDescriptor? arrow;
  double playbackPosition = 0.0; // Represents the current playback position
  double playbackRange = 100.0;

  double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180.0;
    final lon1 = start.longitude * pi / 180.0;
    final lat2 = end.latitude * pi / 180.0;
    final lon2 = end.longitude * pi / 180.0;

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x) * 180.0 / pi;
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  int startIndex = 0;
  late LatLngTween _latLngTween;
  late Animation<LatLng> _animation;
  List<Map<String, dynamic>> locationArrowDetails = [];
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _loadArrowMarkers();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    fetchCarDetails(pauseOrResumeCallback, currentIndex);
    DayCount(
      carID: widget.carID,
      carNumber: '',
    );
    _tabController = TabController(length: 3, vsync: this);
    fetchStopLog();
    fetchTripLog();
    fetchAddresses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Set<Marker> markers = {};
  List<LatLng> ignitionChangeLocations = [];
  List<LatLng> alternateIgnitionChangeLocations = [];
  List<LatLng> highSpeedLocationListNew = [];
  List<IgnitionChangeDetail> ignitionChangeDetails = [];
  List<StopDetails> stopDetails = [];

  List<LatLng> interpolate(LatLng start, LatLng end, int steps) {
    final List<LatLng> points = [];
    for (int i = 0; i <= steps; i++) {
      double t = i / steps;
      double lat = start.latitude * (1 - t) + end.latitude * t;
      double lng = start.longitude * (1 - t) + end.longitude * t;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  Set<Marker> directionMarkers = {};
  List<bool> ignitionList = [];
  int currentIndex = 0;
  bool showCustomInfoWindow = false;
  List<String> idList = [];
  List<LatLng> locationStop = [];
  Set<Marker> stopMarkers = {};
  List<Map<String, dynamic>> rawTripData = [];
  List<String> newAddresses = [];
  List<StopMarker> markersData = [];
  DateTime? previousEndTime;
  DateTime? previousStartTime;
  double? previousStartOdometer;
  bool isCollapsed = true;


  Future<void> fetchStopLog() async {
    DateTime adjustedFromDate = widget.fromDate.subtract(Duration(hours: 5, minutes: 30));
    DateTime adjustedToDate = widget.toDate.subtract(Duration(hours: 5, minutes: 30));

    print("Adjusted from time: ${_formatDateTime(adjustedFromDate)}");
    print("Adjusted to time: ${_formatDateTime(adjustedToDate)}");


    final String stopApi = dotenv.env['STOP_API']!;
    final String apiUrl =
        "$stopApi?deviceId=${widget.carID}&from=${_formatDateTime(adjustedFromDate)}Z&to=${_formatDateTime(adjustedToDate)}Z";
    // final apiUrl =
    //     '$stopApi?deviceId=${widget.carID}&from=${_formatDateTime(widget.fromDate)}Z&to=${_formatDateTime(widget.toDate)}Z';
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        rawTripData =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        List<LatLng> newLocationStop = [];
        List<String> newIdList = [];
        double? totalOdometerDifference;
        for (var trip in rawTripData) {
          final double lat = double.parse(trip['latitude'].toString());
          final double lon = double.parse(trip['longitude'].toString());
          if (lat != null && lon != null) {
            final LatLng locationStop = LatLng(lat, lon);
            final DateTime startTime = DateTime.parse(trip['startTime']);
            final DateTime startTimeNew =
                previousStartTime ?? DateTime.parse(trip['startTime']);
            final DateTime endTime = DateTime.parse(trip['endTime']);
            final Duration duration = endTime.difference(startTime);
            final double distance = double.parse(trip['distance'].toString());
            final double averageSpeed =
                double.parse(trip['averageSpeed'].toString());
            final double maxSpeed = double.parse(trip['maxSpeed'].toString());
            final double spentFuel = double.parse(trip['spentFuel'].toString());
            final double startOdometer =
                double.parse(trip['startOdometer'].toString());
            final double endOdometer =
                double.parse(trip['endOdometer'].toString());
            final String deviceId = trip['deviceId'].toString();
            final String deviceName = trip['deviceName'].toString();
            final String positionId = trip['positionId'].toString();
            final String engineHours = trip['engineHours'].toString();
            Duration? timeBetween;

            double? odometerDifference;
            double? odometerDifferenceInKm;
            double? totalOdometerDifferenceInKm;
            if (previousStartOdometer != null) {
              odometerDifference = endOdometer - previousStartOdometer!;
              odometerDifferenceInKm = odometerDifference / 1000;
            } else {}

            if (previousEndTime != null) {
              timeBetween = startTime.difference(endTime);
            } else {}

            if (rawTripData.isNotEmpty) {
              final double firstStartOdometer =
                  double.parse(rawTripData.first['startOdometer'].toString());
              final double lastEndOdometer =
                  double.parse(rawTripData.last['endOdometer'].toString());
              totalOdometerDifference = lastEndOdometer - firstStartOdometer;
              totalOdometerDifferenceInKm = totalOdometerDifference / 1000;
            }

            stopDetails.add(StopDetails(
              startTime: startTime,
              startTimeNew: startTimeNew,
              endTime: endTime,
              duration: duration,
              distance: distance,
              averageSpeed: averageSpeed,
              maxSpeed: maxSpeed,
              spentFuel: spentFuel,
              startOdometer: startOdometer,
              endOdometer: endOdometer,
              deviceId: deviceId,
              deviceName: deviceName,
              positionId: positionId,
              location: locationStop,
              engineHours: engineHours,
              timeBetween: timeBetween,
              odometerDifference: odometerDifferenceInKm,
              totalOdomterDifference: totalOdometerDifferenceInKm,
            ));
            previousStartOdometer = startOdometer;
            previousEndTime = endTime;
            previousStartTime = DateTime.parse(trip['startTime']);
          }
          final addressNew = await getAddressStop(lat, lon);
          newAddresses.add(addressNew);
          final DateTime startTime = DateTime.parse(trip['startTime']);
          final DateTime endTime = DateTime.parse(trip['endTime']);
          final Duration difference = endTime.difference(startTime);
          final double distance = double.parse(trip['distance'].toString());
          final double averageSpeed =
              double.parse(trip['averageSpeed'].toString());

          newLocationStop.add(LatLng(lat, lon));
          newIdList.add(trip['id'].toString());

          // Other processing if needed

          markersData.add(StopMarker(
            position: LatLng(lat, lon),
            id: trip['id'].toString(),
            address: addressNew,
            startTime: startTime,
            endTime: endTime,
            distance: distance,
            averageSpeed: averageSpeed,
          ));
        }

        setState(() {
          locationStop = newLocationStop;
          idList = newIdList;
        });
      } else {
        throw Exception('Failed to load trips');
      }
    }
  }

  List<Map<String, dynamic>> tripData = [];

  Future<void> fetchTripLog() async {
    DateTime adjustedFromDate = widget.fromDate.subtract(Duration(hours: 5, minutes: 30));
    DateTime adjustedToDate = widget.toDate.subtract(Duration(hours: 5, minutes: 30));

    print("Adjusted from time: ${_formatDateTime(adjustedFromDate)}");
    print("Adjusted to time: ${_formatDateTime(adjustedToDate)}");



    try {
      final String tripApi = dotenv.env["TRIP_API"]!;
      final String apiUrl =
          "$tripApi?deviceId=${widget.carID}&from=${_formatDateTime(adjustedFromDate)}Z&to=${_formatDateTime(adjustedToDate)}Z";
      // final apiUrl =
      //     '$tripApi?deviceId=${widget.carID}&from=${_formatDateTime(widget.fromDate)}Z&to=${_formatDateTime(widget.toDate)}Z';
      final String? sessionCookies = await storage.read(key: "sessionCookies");

      if (sessionCookies != null) {
        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
        );

        if (response.statusCode == 200) {
          setState(() {
            isLoading = false;
            tripData =
                List<Map<String, dynamic>>.from(json.decode(response.body));
          });

          for (var trip in tripData) {
            final startLat = double.tryParse(trip['startLat'].toString());
            final startLon = double.tryParse(trip['startLon'].toString());
            final endLat = double.tryParse(trip['endLat'].toString());
            final endLon = double.tryParse(trip['endLon'].toString());

            if (startLat != null &&
                startLon != null &&
                endLat != null &&
                endLon != null) {
              final List<Placemark> startPlacemarks =
                  await placemarkFromCoordinates(startLat, startLon);
              final List<Placemark> endPlacemarks =
                  await placemarkFromCoordinates(endLat, endLon);

              if (startPlacemarks.isNotEmpty) {
                final String startAddress =
                    "${startPlacemarks[0].name ?? ''}, ${startPlacemarks[0].locality ?? ''}, ${startPlacemarks[0].administrativeArea ?? ''}, ${startPlacemarks[0].country ?? ''}";
                trip['startAddress'] = startAddress;
              }

              if (endPlacemarks.isNotEmpty) {
                final String endAddress =
                    "${endPlacemarks[0].name ?? ''}, ${endPlacemarks[0].locality ?? ''}, ${endPlacemarks[0].administrativeArea ?? ''}, ${endPlacemarks[0].country ?? ''}";
                trip['endAddress'] = endAddress;
              }
            }
          }
        } else {
          throw Exception('Failed to load trips: ${response.statusCode}');
        }
      } else {
        print('Error: Session cookies are null.');
      }
    } catch (e) {
      // Handle any exceptions that occur
      print('Exception occurred: $e');
      setState(() {
        isLoading = false; // Stop loading if an error occurs
      });
    }
  }


  Future<void> fetchAddresses() async {
    for (var trip in tripData) {
      final startLat = trip['startLat'];
      final startLon = trip['startLon'];
      final endLat = trip['endLat'];
      final endLon = trip['endLon'];
      try {
        List<Placemark> startPlacemarks =
            await placemarkFromCoordinates(startLat, startLon);
        List<Placemark> endPlacemarks =
            await placemarkFromCoordinates(endLat, endLon);
        setState(() {
          trip['startAddress'] = formatAddress(startPlacemarks.first);
          trip['endAddress'] = formatAddress(endPlacemarks.first);
        });
      } catch (e) {}
    }
  }

  String formatAddress(Placemark placemark) {
    return "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
  }

  Future<void> fetchCarDetails(
      void Function(bool) pauseOrResumeCallback, int startIndex) async {
    try {
      List<LatLng> locationList = [];

      List<LatLng> interpolatedLocationList = [];
      List<LatLng> ignitionOffLocations = [];

      // DateTime fromDateTime = DateTime.parse(widget.fromDate);
      // DateTime toDateTime = DateTime.parse(widget.toDate);
      // fromDateTime = fromDateTime.subtract(const Duration(hours: 5, minutes: 30));
      // toDateTime = toDateTime.subtract(const Duration(hours: 5, minutes: 30));
      // String fromAdjusted = DateFormat("yyyy-MM-ddTHH:mm:ss").format(fromDateTime) + 'Z';
      // String toAdjusted = DateFormat("yyyy-MM-ddTHH:mm:ss").format(toDateTime) + 'Z';

      print("fromtime000 ${_formatDateTime(widget.fromDate)}");
      print("fromtime000 ${_formatDateTime(widget.toDate)}");


      DateTime adjustedFromDate = widget.fromDate.add(Duration(hours: 5, minutes: 30));
      DateTime adjustedToDate = widget.toDate.add(Duration(hours: 5, minutes: 30));

// Print the adjusted times
      print("Adjusted from time: ${_formatDateTime(adjustedFromDate)}");
      print("Adjusted to time: ${_formatDateTime(adjustedToDate)}");

      final String carDetailsApiUrl =
          "$historyApi?deviceId=${widget.carID}&from=${_formatDateTime(adjustedFromDate)}Z&to=${_formatDateTime(adjustedToDate)}Z";

      print("carDetailsApiUrl ${carDetailsApiUrl}");

      // final String carDetailsApiUrl =
      //     "$historyApi?deviceId=${widget.carID}&from=${_formatDateTime(widget.fromDate)}Z&to=${_formatDateTime(widget.toDate)}Z";

      final String? sessionCookies = await storage.read(key: "sessionCookies");
      if (sessionCookies != null) {
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
              final latitude = carItem['latitude'] as double?;
              final longitude = carItem['longitude'] as double?;
              final speed = carItem['speed'] as double?;

              if (latitude != null && longitude != null) {
                // Create a LatLng object for the location
                final location = LatLng(latitude, longitude);

                // Check if the speed is more than 5 km/h
                if (speed != null && speed > 5.0) {
                  final locationS = LatLng(latitude, longitude);

                  locationList.add(locationS);
                }

                // Optionally add all locations to locationList
              }
            }

            for (int i = 0; i < locationList.length - 1; i++) {
              interpolatedLocationList.addAll(
                  interpolate(locationList[i], locationList[i + 1], 10));
            }

            // Add polyline to _polylines
            _polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: locationList,
              // color: Colors.green,
              color: Colors.blue,
              width: 4,
            ));
            startIcon();
            finishIcon();
            bool previousIgnitionState = false;
            for (final carItem in carDataList) {
              if (isPaused) {
                pauseOrResumeCallback(true);
                return;
              }
              initialLatitude = jsonResponse[0]['latitude'] as double;
              initialLongitude = jsonResponse[0]['longitude'] as double;
              finalLatitude = jsonResponse.last['latitude'] as double;
              finalLongitude = jsonResponse.last['longitude'] as double;
              initialPosition = LatLng(initialLatitude, initialLongitude);
              final latitude = carItem['latitude'] as double?;
              final longitude = carItem['longitude'] as double?;
              final rotationAngle = carItem['course'] as double?;
              final newSpeed = carItem['speed'] * 1.852;
              final odometer =
                  (carItem['attributes']?['odometer'] ?? 0) / 1000.0;
              final bool ignition = carItem['attributes']['ignition'] ?? false;
              final newTime = carItem['fixTime'].toString();
              // final newTime = carItem['deviceTime'].toString();
              final lastUpdate = newTime;

              final String status = getStatus(newSpeed, ignition);

              for (int i = 1; i < carDataList.length; i++) {
                final double currentOdometer =
                    (carDataList[i]['attributes']?['odometer'] ?? 0) / 1000.0;
                final double previousOdometer =
                    (carDataList[i - 1]['attributes']?['odometer'] ?? 0) /
                        1000.0;
                if (currentOdometer != 0 && previousOdometer != 0) {
                  final double distance = currentOdometer - previousOdometer;
                  totalDistance += distance;
                }
              }

              DateTime lastUpdateTime = DateTime.parse(lastUpdate);


              final dateFormatter = DateFormat('dd/MM/yyyy');
              final timeFormatter = DateFormat('HH:mm:ss');

              final date = dateFormatter.format(lastUpdateTime);
              final time = timeFormatter.format(lastUpdateTime);

              final updatedTime = "$date\n$time";

              final carIds =
                  carItem['id']; // Assuming 'id' is used to identify the car
              final attributes = carItem['attributes'] as Map<String, dynamic>?;

              // Check if latitude and longitude are not null
              if (latitude != null && longitude != null) {
                // Add LatLng to locationList
                locationList.add(LatLng(latitude, longitude));

                if (locationList.isNotEmpty) {
                  setState(() {
                    initialPosition = LatLng(initialLatitude, initialLongitude);
                  });
                }
                setState(() {
                  locationList = locationList;
                });
                moveCarAndCameraToLocations(locationList);
                // await _animateMarkerMovement(locationList);
                if (attributes != null) {
                  final bool ignition = attributes['ignition'] ?? false;
                  // ignitionList.add(ignition);

                  if (previousIgnitionState == true && ignition == false) {
                    ignitionChangeLocations.add(LatLng(latitude, longitude));
                  }
                  previousIgnitionState = ignition;

                  // Update other states and UI accordingly
                  final convertedLocation = LatLng(latitude, longitude);

                  if (ignition == true) {
                    ignitionOffLocations.add(convertedLocation);
                    carLocation =
                        convertedLocation; // Add location to the list when ignition is off
                  }

                  // Assuming you have a function to get address asynchronously
                  final address = await getAddress(latitude, longitude);

                  // loadCustomIconNew(vehicleType: "car",status: status); //
                  // animateMarkerMovement(carLocation, convertedLocation);
                  setState(() {
                    carAddress = address;
                    carRotation = rotationAngle ?? 0.0;
                    carLocation = convertedLocation;
                    carSpeed = newSpeed.roundToDouble();
                    currentTime = updatedTime;
                    movingKm = totalDistance / 1000.roundToDouble();
                    isLoading = false;
                  });

                  loadCustomIcon();
                  await Future.delayed(
                      Duration(milliseconds: (1000 ~/ animationSpeed)));

                  // Add location to polylinePoints
                  polylinePoints.add(convertedLocation);
                } else {}
              } else {}
            }
            ignitionList = carDataList.map<bool>((carItem) {
              final attributes = carItem['attributes'] as Map<String, dynamic>?;
              return attributes != null && attributes['ignition'] ?? false;
            }).toList();
            for (int i = 1; i < carDataList.length; i++) {
              if (ignitionList[i - 1] == true && ignitionList[i] == false) {
                final latitude = carDataList[i]['latitude'] as double?;
                final longitude = carDataList[i]['longitude'] as double?;
                final speed = carDataList[i]['speed'] as double?;
                final deviceTime =
                    DateTime.parse(carDataList[i]['deviceTime'] as String);
                if (latitude != null && longitude != null) {
                  final LatLng location = LatLng(latitude, longitude);
                  ignitionChangeDetails.add(IgnitionChangeDetail(
                    location: location,
                    speed: speed ?? 0.0,
                    deviceTime: deviceTime,
                  ));
                }
              }
            }
            for (int i = 0; i < ignitionList.length; i++) {
              final latitude = carDataList[i]['latitude'] as double?;
              final longitude = carDataList[i]['longitude'] as double?;
              final speed = carDataList[i]['speed'] as double?;
              final deviceTimeArrow =
                  DateTime.parse(carDataList[i]['deviceTime'] as String);
              final address = await getAddress(latitude!, longitude!);
              // if (latitude != null && longitude != null) {
              //   final LatLng location = LatLng(latitude, longitude);
              //   alternateIgnitionChangeLocations.add(location);
              //   if (speed != null && speed > 5.0) {
              //     highSpeedLocationListNew.add(location); // Add to high-speed list
              //   }
              // }
              if (latitude != null &&
                  longitude != null &&
                  speed != null &&
                  speed > 5.0) {
                final LatLng location = LatLng(latitude, longitude);
                highSpeedLocationListNew.add(location);
                locationArrowDetails.add({
                  'speed': speed,
                  'deviceTime': deviceTimeArrow,
                  'address': address,
                });
              }
            }
            // for (final carItem in carDataList) {
            //   final latitude = carItem['latitude'] as double?;
            //   final longitude = carItem['longitude'] as double?;
            //   if (latitude != null && longitude != null) {
            //     locationList.add(LatLng(latitude, longitude));
            //   }
            // }

            if (carDataList.length > 1) {
              final double lastTotalDistance =
                  carDataList.last['attributes']['totalDistance'];
              final double secondLastTotalDistance =
                  carDataList[carDataList.length - 2]['attributes']
                      ['totalDistance'];
              final double lastSectionDistance =
                  lastTotalDistance - secondLastTotalDistance;
            }
          }
        }
      }

      locationList.forEach((location) {});
    } catch (e) {}
  }

  Future<void> loadCustomIcon(
      {String vehicleType = 'car', String status = 'Idle'}) async {
    String imagePath = "assets/cr_y.png"; // Default icon path
    switch (vehicleType) {
      case 'motorcycle':
        switch (status) {
          case 'Idle':
            imagePath = 'aassets/bike_yt.png';
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
          targetWidth: 50); // Resize the icon (adjust targetWidth)
      ui.FrameInfo frameInfo = await codec.getNextFrame();

      ByteData? resizedData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List resizedBytes = resizedData!.buffer.asUint8List();

      customIcon = BitmapDescriptor.fromBytes(resizedBytes);
    } catch (e) {
      print(e.toString());
    }

    //
    // try {
    //   customIcon = await BitmapDescriptor.fromAssetImage(
    //     const ImageConfiguration(size: Size(40, 40)),
    //     iconPath,
    //   );
    // } catch (e) {
    // }
    // setState(() {});
  }

  void animateMarkerMovement(LatLng oldPosition, LatLng newPosition) {
    _latLngTween = LatLngTween(begin: oldPosition, end: newPosition);
    _animation = _latLngTween.animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    )?..addListener(() {
        setState(() {
          carLocation = _animation.value;
        });
      });
    _animationController.forward(from: 0.0);
  }

  Future<void> startIcon() async {
    String imagePath = "assets/start.png"; // Provide a default value
    final String startPath = imagePath;
    try {
      ByteData data = await rootBundle.load(imagePath);
      Uint8List imageData = data.buffer.asUint8List();
      ui.Codec codec = await ui.instantiateImageCodec(imageData,
          targetWidth: 80); // Resize the icon (adjust targetWidth)
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      ByteData? resizedData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List resizedBytes = resizedData!.buffer.asUint8List();
      customStartIcon = BitmapDescriptor.fromBytes(resizedBytes);
    } catch (e) {
      print(e.toString());
    }
    // try {
    //   customStartIcon = await BitmapDescriptor.fromAssetImage(
    //     const ImageConfiguration(
    //         size: Size(50, 50)), // Adjust the size accordingly
    //     startPath,
    //   );
    //
    //   if (customStartIcon == null) {
    //   } else {
    //     setState(
    //             () {}); // Trigger a rebuild only if the icon is successfully loaded
    //   }
    // } catch (e) {
    // }
  }

  Future<void> finishIcon() async {
    String imagePath = "assets/finish.png"; // Provide a default value
    final String finishPath = imagePath;
    try {
      ByteData data = await rootBundle.load(imagePath);
      Uint8List imageData = data.buffer.asUint8List();
      ui.Codec codec = await ui.instantiateImageCodec(imageData,
          targetWidth: 80); // Resize the icon (adjust targetWidth)
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      ByteData? resizedData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List resizedBytes = resizedData!.buffer.asUint8List();
      customFinishIcon = BitmapDescriptor.fromBytes(resizedBytes);
    } catch (e) {
      print(e.toString());
    }
    // try {
    //   customFinishIcon = await BitmapDescriptor.fromAssetImage(
    //     const ImageConfiguration(
    //         size: Size(50, 50)), // Adjust the size accordingly
    //     finishPath,
    //   );
    //
    //   if (customFinishIcon == null) {
    //   } else {
    //     setState(() {
    //       customFinishIcon = customFinishIcon;
    //     });
    //   }
    // } catch (e) {
    // }
  }

  void extractOdometerAndSValues(dynamic items) {
    if (items != null && items is List) {
      for (var item in items) {
        String description = item['e'] ?? '';

        // Use regex to extract odometer and s values
        RegExp odometerRegExp = RegExp(r'Odometer: (\d+\.\d+)km');
        RegExp sRegExp = RegExp(r'Speed: (\d+)');

        Match? odometerMatch = odometerRegExp.firstMatch(description);
        Match? sMatch = sRegExp.firstMatch(description);

        if (odometerMatch != null) {
          odometerValue = double.parse(odometerMatch.group(1)!);
        }

        if (sMatch != null) {
          int sValue = int.parse(sMatch.group(1)!);
        }
      }
    }
  }

  Future<String> getAddressFromLocation(LatLng location) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
    } catch (e) {}
    return 'Address not found';
  }

  Future<String> getAddressStop(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return " ${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}";
      }
    } catch (e) {}
    return "Address not found";
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        // return "${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
        return " ${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}";
      }
    } catch (e) {}
    return "Address not found";
  }

  Future<LatLng> convertCoordinates(double x, double y) async {
    final double latitude = y / 1000000;
    final double longitude = x / 1000000;
    return LatLng(latitude, longitude);
  }

  // String _formatDateTime(DateTime? dateTime) {
  //   if (dateTime != null) {
  //     return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime.toLocal());
  //   } else {
  //     return '';
  //   }
  // }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      DateTime adjustedDateTime =
          dateTime.subtract(const Duration(hours: 5, minutes: 30));
      return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS')
          .format(adjustedDateTime.toLocal());
    } else {
      return '';
    }
  }

  String _formatDate(DateTime date) {
    // Format the DateTime object
    String formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return formattedDate;
  }

  void pauseOrResumeCallback(bool isPaused) {
    setState(() {
      this.isPaused = isPaused;
    });
  }

  void pauseOrResumeAnimation() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        pausedIndex = currentIndex;
      } else {
        moveCarAndCameraToLocations(locationList.sublist(pausedIndex));
      }
    });
  }

  void _onCameraMove(CameraPosition position) {
    _isUserInteracting = true;
  }

  void _onCameraIdle() {
    _isUserInteracting = false;
  }

  int currentPositionNN = 0;
  Map<String, dynamic>? storedStateNN;
  Future<void> moveCarAndCameraToLocations(List<LatLng> locationList) async {
    // Focus the camera on the current location
    await mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: carLocation,
        zoom: zoomLevel,
      ),
    ));

    // Delay between animation frames based on animationSpeed
    await Future.delayed(Duration(milliseconds: (1000000 ~/ animationSpeed)));
  }

  // Replay functionality
  Future<void> replayCarHistory() async {
    setState(() {
      fetchCarDetails(pauseOrResumeCallback, currentIndex);
    });
  }

  MapType currentMapType = MapType.normal;
  void _onMapTypeSelected(MapType selectedMapType) {
    setState(() {
      currentMapType = selectedMapType;
    });
  }

  // Future<void> _loadMarkers() async {
  //   final loadedBusIcon = await BitmapDescriptor.fromAssetImage(
  //       const ImageConfiguration(size: Size(1, 1)), // You can adjust the size
  //       'assets/stop_icon_new.png');
  //   setState(() {
  //     busIcon = loadedBusIcon;
  //   });
  // }
  Future<void> _loadMarkers() async {
    String imagePath =
        'assets/stop_icon_new.png'; // Specify your icon path here

    try {
      ByteData data = await rootBundle.load(imagePath);
      Uint8List imageData = data.buffer.asUint8List();
      ui.Codec codec = await ui.instantiateImageCodec(imageData,
          targetWidth: 100); // Adjust the targetWidth for the icon size
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      ByteData? resizedData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List resizedBytes = resizedData!.buffer.asUint8List();
      final resizedIcon = BitmapDescriptor.fromBytes(resizedBytes);
      setState(() {
        busIcon = resizedIcon;
      });
    } catch (e) {
      print('Error resizing icon: $e');
    }
  }

  // Future<void> _loadArrowMarkers() async {
  //   final loadedBusIcon = await BitmapDescriptor.fromAssetImage(
  //       const ImageConfiguration(size: Size(1, 1)), // You can adjust the size
  //       'assets/arrow_greywhite.png');
  //   setState(() {
  //     arrow = loadedBusIcon;
  //   });
  // }
  Future<void> _loadArrowMarkers() async {
    String imagePath =
        'assets/arrow_greywhite.png'; // Specify your icon path here

    try {
      ByteData data = await rootBundle.load(imagePath);
      Uint8List imageData = data.buffer.asUint8List();
      ui.Codec codec = await ui.instantiateImageCodec(imageData,
          targetWidth: 50); // Adjust the targetWidth for the icon size
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      ByteData? resizedData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List resizedBytes = resizedData!.buffer.asUint8List();
      final resizedIcon = BitmapDescriptor.fromBytes(resizedBytes);
      setState(() {
        arrow = resizedIcon;
      });
    } catch (e) {
      print('Error resizing arrow icon: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < highSpeedLocationListNew.length - 1; i++) {
      final start = highSpeedLocationListNew[i];
      final end = highSpeedLocationListNew[i + 1];
      final bearing = calculateBearing(start, end);
      final detail = locationArrowDetails[i];
      final speed = detail['speed'] as double;
      final deviceTime = detail['deviceTime'] as DateTime;
      final address = detail['address'] as String;
      final formattedTime =
          DateFormat('dd/MM/yyyy HH:mm:ss').format(deviceTime);
      directionMarkers.add(
        Marker(
          markerId: MarkerId('direction_$i'),
          position: start,
          icon: arrow ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          rotation: bearing,
          infoWindow: InfoWindow(
            title: '📍 $address',
            snippet: '⏰ $formattedTime, 🚗 ${speed.toStringAsFixed(2)} km/h',
          ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    Set<Marker> stopMarkers = stopDetails
        .asMap()
        .map((index, detail) {
          return MapEntry(
            index,
            Marker(
              markerId: MarkerId(detail.location.toString()),
              position: detail.location,
              icon: busIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: "Stop ${index + 1}",
              ),
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return showSheet(context, detail, stopNumber: index + 1);
                  },
                );
                // showSheet(context, detail, stopNumber: index + 1);
              },
            ),
          );
        })
        .values
        .toSet();

    Marker newStartMarker = Marker(
      markerId: const MarkerId('Start'),
      position: locationList.isNotEmpty
          ? locationList.first
          : LatLng(initialLatitude, initialLongitude),
      icon: customStartIcon, // Your custom start icon
      infoWindow: const InfoWindow(title: 'Start'),
    );

    Marker newFinishMarker = Marker(
      markerId: const MarkerId('finish'),
      position: locationList.isNotEmpty
          ? locationList.last
          : LatLng(finalLatitude, finalLongitude),
      icon: customFinishIcon,
      // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Finish'),
    );

    CameraPosition initialCameraPosition = CameraPosition(
      target: initialPosition ??
          const LatLng(
              0, 0), // Provide a default LatLng if initialPosition is null
      zoom: zoomLevel, // Set your desired zoom level here
    );

    markers = {
      // ...ignitionMarkers,
      ...stopMarkers,
      // ...createTripMarkers(markersData),
      newStartMarker,
      Marker(
        markerId: const MarkerId("car"),
        position: carLocation,
        icon: customIcon,
        rotation: carRotation,
        infoWindow: InfoWindow(
          title: widget.carNumber,
          snippet: 'Speed : ${carSpeed.toString()} km/hr',
        ),
      ),
      newFinishMarker,
      ...directionMarkers,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(8.0),
          ),
          child: AppBar(
            backgroundColor: Colors.black,
            leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.white,
                )),
            title: ListTile(
              title: Text(
                // '${widget.carNumber} History',
                widget.carNumber,
                style: GoogleFonts.robotoSlab(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      body: Stack(children: [
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                mapType: currentMapType,
                polylines: _polylines,
                initialCameraPosition: initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                  moveCarAndCameraToLocations(LocationList);
                  //  _animateMarkerMovement(locationList);
                },
                markers: markers,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: false,
                onCameraMove: (CameraPosition position) {
                  zoomLevel = position.zoom;
                },
                minMaxZoomPreference: const MinMaxZoomPreference(2, 30),
              ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCollapsed ? 30 : 330,
          decoration: BoxDecoration(
            color: isCollapsed ? Colors.transparent : Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey[200]!,
            //     offset: const Offset(-1, -1),
            //     blurRadius: 2,
            //     spreadRadius: 1,
            //   ),
            // ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                Visibility(
                  visible: isCollapsed,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isCollapsed = !isCollapsed;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 55,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(5),
                          topRight: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                          topLeft: Radius.circular(5),
                        ),
                      ),
                      child: const Icon(Icons.arrow_forward_ios,
                          color: Colors.black, size: 18),
                    ),
                  ),
                ),
                if (!isCollapsed)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(
                        5.0,
                      ),
                    ),
                    child: TabBar(
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 5),
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          5.0,
                        ),
                        color: Colors.black,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      // labelStyle: Const.textPrimary.copyWith(fontSize: 14.sp),
                      tabs: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            "Stop Summary",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            "Trip Summary",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isCollapsed = true;
                            });
                            _tabController.animateTo(0); // or any other index
                          },
                          child: const Icon(
                            Icons.cancel,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                Visibility(
                  visible: !isCollapsed,
                  child: Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: stopDetails.length,
                            itemBuilder: (context, index) {
                              final stopDetail = stopDetails[index];
                              // String formattedTime =
                              // DateFormat('yyyy-MM-dd HH:mm:ss').format(stopDetail.startTime);

                              // String formattedEndTime =
                              // DateFormat('yyyy-MM-dd HH:mm:ss').format(stopDetail.endTime);

                              DateTime updatedStartTime = stopDetail.startTime
                                  .add(Duration(hours: 11, minutes: 00));
                              String formattedTime =
                                  DateFormat('yyyy-MM-dd HH:mm:ss')
                                      .format(updatedStartTime);
                              DateTime updatedEndTime = stopDetail.endTime
                                  .add(Duration(hours: 11, minutes: 00));
                              String formattedEndTime =
                                  DateFormat('yyyy-MM-dd HH:mm:ss')
                                      .format(updatedEndTime);

                              return FutureBuilder<String>(
                                future:
                                    getAddressFromLocation(stopDetail.location),
                                builder: (context, snapshot) {
                                  String address =
                                      snapshot.data ?? 'Loading address...';
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isCollapsed = !isCollapsed;
                                        });
                                        mapController?.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: stopDetail.location,
                                              zoom:
                                                  30.0, // Adjust zoom level as needed
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey[300]!,
                                              offset: const Offset(-1, -1),
                                              blurRadius: 2,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Column(
                                                    children: [
                                                      Container(
                                                        height: 20,
                                                        width: 20,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .red.shade500,
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                              color: Colors
                                                                  .red.shade700,
                                                              width: 2),
                                                        ),
                                                        child: Text(
                                                          "${index + 1}",
                                                          style: GoogleFonts
                                                              .poppins(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 10,
                                                        child: VerticalDivider(
                                                          width: 1,
                                                          color: Colors
                                                              .red.shade800,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    "STOP",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    height: 7,
                                                    width: 7,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.green,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Colors.grey[200]!,
                                                          offset: const Offset(
                                                              -1, -1),
                                                          blurRadius: 2,
                                                          spreadRadius: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    formattedTime,
                                                    style: GoogleFonts.poppins(
                                                        color: Colors
                                                            .grey.shade900,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const SizedBox(
                                                    height: 7,
                                                    width: 7,
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      address,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors
                                                            .grey.shade700,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 8,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    height: 7,
                                                    width: 7,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.red,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Colors.grey[200]!,
                                                          offset: const Offset(
                                                              -1, -1),
                                                          blurRadius: 2,
                                                          spreadRadius: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    formattedEndTime,
                                                    style: GoogleFonts.poppins(
                                                        color: Colors
                                                            .grey.shade900,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  const SizedBox(
                                                    height: 7,
                                                    width: 7,
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      address,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors
                                                            .grey.shade700,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 8,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Column(
                                                    children: [
                                                      const Icon(
                                                        Icons.speed,
                                                        color: Colors.red,
                                                        size: 15,
                                                      ),
                                                      Text(
                                                        "Avg.Speed",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      Text(
                                                        stopDetail.averageSpeed
                                                            .toString(),
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Column(
                                                    children: [
                                                      const Icon(
                                                        Icons.speed,
                                                        color: Colors.red,
                                                        size: 15,
                                                      ),
                                                      Text(
                                                        "Max.Speed",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      Text(
                                                        stopDetail.maxSpeed
                                                            .toString(),
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Column(
                                                    children: [
                                                      const Icon(
                                                        Icons.social_distance,
                                                        color: Colors.red,
                                                        size: 15,
                                                      ),
                                                      Text(
                                                        "Distance",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      Text(
                                                        "${(stopDetail.odometerDifference ?? 0.0).toStringAsFixed(2)} Km",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  Column(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .oil_barrel_outlined,
                                                        color: Colors.red,
                                                        size: 15,
                                                      ),
                                                      Text(
                                                        "SpentFuel",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      Text(
                                                        "${stopDetail.spentFuel ?? "00"}",
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.black,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              )
                                              // Rest of the content
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        // Trip Summary Tab
                        Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: tripData.length,
                            itemBuilder: (context, index) {
                              final trip = tripData[index];
                              String? formattedTime;
                              String? formattedEndTime;
                              String? startTimeString = trip['startTime'];

                              // if (startTimeString != null) {
                              //   DateTime startTime = DateTime.parse(startTimeString);
                              //   formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime); // Format the DateTime
                              // }
                              if (startTimeString != null) {
                                DateTime startTime =
                                    DateTime.parse(startTimeString);
                                DateTime updatedStartTime = startTime
                                    .add(Duration(hours: 11, minutes: 00));
                                formattedTime =
                                    DateFormat('yyyy-MM-dd HH:mm:ss')
                                        .format(updatedStartTime);
                              }

                              String? startTimeString1 = trip['endTime'];
                              if (startTimeString != null) {
                                DateTime startTime =
                                    DateTime.parse(startTimeString1 ?? "");
                                DateTime updatedStartTime = startTime
                                    .add(Duration(hours: 11, minutes: 00));
                                formattedEndTime =
                                    DateFormat('yyyy-MM-dd HH:mm:ss')
                                        .format(updatedStartTime);

                                // formattedEndTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime); // Format the DateTime
                              }

                              final duration =
                                  Duration(milliseconds: trip['duration'] ?? 0);
                              final hours =
                                  duration.inHours.toString().padLeft(2, '0');
                              final minutes = (duration.inMinutes % 60)
                                  .toString()
                                  .padLeft(2, '0');
                              final seconds = (duration.inSeconds % 60)
                                  .toString()
                                  .padLeft(2, '0');
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey[300]!,
                                          offset: const Offset(-1, -1),
                                          blurRadius: 2,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                height: 7,
                                                width: 7,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.green,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey[200]!,
                                                      offset:
                                                          const Offset(-1, -1),
                                                      blurRadius: 2,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                formattedTime.toString(),
                                                style: GoogleFonts.poppins(
                                                    color: Colors.grey.shade900,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const SizedBox(
                                                height: 7,
                                                width: 7,
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  trip['startAddress'] ??
                                                      "Fetching address...",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                height: 7,
                                                width: 7,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey[200]!,
                                                      offset:
                                                          const Offset(-1, -1),
                                                      blurRadius: 2,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                formattedEndTime.toString(),
                                                style: GoogleFonts.poppins(
                                                    color: Colors.grey.shade900,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const SizedBox(
                                                height: 7,
                                                width: 7,
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  trip['endAddress'] ??
                                                      "Fetching address...",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey.shade700,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Column(
                                                children: [
                                                  const Icon(
                                                    Icons.speed,
                                                    color: Colors.red,
                                                    size: 15,
                                                  ),
                                                  Text(
                                                    "Avg.Speed",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  Text(
                                                    // stopDetail
                                                    //     .averageSpeed
                                                    //     .toString(),
                                                    // trip['averageSpeed'],
                                                    "${(trip['averageSpeed'] ?? 0.0).toStringAsFixed(2)}",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Column(
                                                children: [
                                                  const Icon(
                                                    Icons.speed,
                                                    color: Colors.red,
                                                    size: 15,
                                                  ),
                                                  Text(
                                                    "Max.Speed",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  Text(
                                                    // "10",
                                                    "${(trip['maxSpeed'] ?? 0.0).toStringAsFixed(2)}",
                                                    // stopDetail.maxSpeed
                                                    //     .toString(),
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Column(
                                                children: [
                                                  const Icon(
                                                    Icons.social_distance,
                                                    color: Colors.red,
                                                    size: 15,
                                                  ),
                                                  Text(
                                                    "Distance",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  Text(
                                                    "${((trip['distance'] ?? 0.0) / 1000).toStringAsFixed(2)} Km",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  )
                                                ],
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Column(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time_outlined,
                                                    color: Colors.red,
                                                    size: 15,
                                                  ),
                                                  Text(
                                                    "Duration",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  Text(
                                                    "$hours:$minutes:$seconds",
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.black,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                          // Rest of the content
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 60.0,
          right: 12.0,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    zoomLevel++;
                    moveCarAndCameraToLocations(locationList);
                  });
                },
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF5E5E5E),
                      Color(0xFF3E3E3E),
                    ], begin: Alignment.centerLeft, end: Alignment.centerRight),
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
                    moveCarAndCameraToLocations(locationList);
                  });
                },
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF5E5E5E),
                      Color(0xFF3E3E3E),
                    ], begin: Alignment.centerLeft, end: Alignment.centerRight),
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
          top: 130,
          right: 10,
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
              color: Colors.white,
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
                            color: Colors.grey.shade900,
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
                              color: Colors.grey.shade900,
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
                              color: Colors.grey.shade900,
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
                              color: Colors.grey.shade900,
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
          top: 1,
          right: 0,
          left: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(2, 0),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.timer_sharp,
                                color: Colors.black,
                              )),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            currentTime,
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.speed),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "${carSpeed.roundToDouble()} km/hr",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.horizontal_distribute_sharp),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "${movingKm.toStringAsFixed(2)} Km",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                          // Column(
                          //   children: [
                          //     Text(
                          //       "${widget.todaysKm.toString()} Km(Total Km)",
                          //       style: GoogleFonts.poppins(
                          //           color: Colors.black,
                          //           fontSize:12,
                          //           fontWeight: FontWeight.w500),
                          //     ),
                          //     Text(
                          //       "${movingKm.toStringAsFixed(2)} Km(Current Km)",
                          //       style: GoogleFonts.poppins(
                          //           color: Colors.black,
                          //           fontSize: 9,
                          //           fontWeight: FontWeight.w500),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          right: -1,
          left: -1,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.09,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(2, 0),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DayCount(
                                  carID: widget.carID,
                                  carNumber: widget.carNumber),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.filter_alt_outlined,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Slider(
                        activeColor: Colors.black,
                        inactiveColor: Colors.black,
                        value: animationSpeed,
                        min: 1.0,
                        max: 100.0,
                        divisions: 19,
                        label: animationSpeed.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            animationSpeed = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8, right: 5, bottom: 8, left: 2),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isPaused = !isPaused;
                          });
                          if (!isPaused) {
                            fetchCarDetails(
                                pauseOrResumeCallback, currentIndex);
                          } else {
                            pauseOrResumeCallback(true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.grey,
                                offset: Offset(2, 0),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            color: isPaused ? Colors.black : Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget showSheet(BuildContext context, StopDetails detail,
      {required int stopNumber}) {
    Future<String> getAddressFromLocation(LatLng location) async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude, location.longitude);
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks[0];
          return "${placemark.street} ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}";
        }
      } catch (e) {}
      return 'Address not found';
    }

    String formatDuration(Duration duration) {
      final int hours = duration.inHours;
      final int minutes = duration.inMinutes % 60;
      final int seconds = duration.inSeconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    String formattedDate = DateFormat('dd/MM/yyyy').format(detail.startTime);
    String formattedEndDate = DateFormat('dd/MM/yyyy').format(detail.endTime);
    String formattedTime = DateFormat('HH:mm:ss').format(detail.startTime);
    String formattedEndTime = DateFormat('HH:mm:ss').format(detail.endTime);
    String formattedDateTime = '$formattedDate\n$formattedTime';
    String formattedDateTimeEnd = '$formattedEndDate\n$formattedEndTime';
    return FutureBuilder<String>(
      future: getAddressFromLocation(detail.location),
      builder: (context, snapshot) {
        String address = snapshot.data ?? 'Loading address...';
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          height: MediaQuery.of(context).size.height * 0.35,
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            height: 30,
                            width: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.red.shade800, width: 2),
                            ),
                            child: Text(
                              stopNumber.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                            child: VerticalDivider(
                              width: 1,
                              color: Colors.red.shade800,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          address,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                            flex: 1,
                            child: SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  Flexible(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 30,
                                        child: Image.asset(
                                            "assets/parking_stop.png"),
                                      )),
                                  Flexible(
                                      flex: 2,
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 50,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              formatDuration(detail.duration ??
                                                  Duration.zero),
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              "Parked Time",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            )),
                        const SizedBox(width: 10),
                        Flexible(
                            flex: 1,
                            child: SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  Flexible(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 30,
                                        child:
                                            Image.asset("assets/kilomtere.png"),
                                      )),
                                  Flexible(
                                      flex: 2,
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 50,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              detail.averageSpeed.toString(),
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              "Avg. Speed",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                            flex: 1,
                            child: SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  Flexible(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 30,
                                        child: Image.asset(
                                            "assets/arrival_time.png"),
                                      )),
                                  Flexible(
                                      flex: 2,
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 50,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              formattedDateTime,
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "Arrival Time",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            )),
                        const SizedBox(width: 10),
                        Flexible(
                            flex: 1,
                            child: SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  Flexible(flex: 1, child: Container()),
                                  Flexible(
                                      flex: 2,
                                      child: SizedBox(
                                        height: 50,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              formattedDateTimeEnd,
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "Departure Time",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                            flex: 1,
                            child: SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  Flexible(
                                      flex: 1,
                                      child: SizedBox(
                                        height: 30,
                                        child: Image.asset(
                                            "assets/new_history_img.png"),
                                      )),
                                  Flexible(
                                      flex: 2,
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 50,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              // "${detail.odometerDifference ?? "00"} Km",
                                              "${(detail.odometerDifference ?? 0.0).toStringAsFixed(2)} Km",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "From last stop",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            )),
                        const SizedBox(width: 10),
                        Flexible(
                            flex: 1,
                            child: SizedBox(
                              height: 50,
                              child: Row(
                                children: [
                                  Flexible(flex: 1, child: Container()),
                                  Flexible(
                                      flex: 2,
                                      child: SizedBox(
                                        height: 50,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              // "${detail.totalOdomterDifference ?? "00"} Km",
                                              "${(detail.totalOdomterDifference ?? 0.0).toStringAsFixed(2)} Km",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "Total Km",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

// Helper function to format date
  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
  }
}

class StopMarker {
  final LatLng position;
  final String id;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final double distance;
  final double averageSpeed;

  StopMarker({
    required this.position,
    required this.id,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.averageSpeed,
  });
}

class StopDetails {
  final DateTime startTime;
  final DateTime startTimeNew;
  final DateTime endTime;
  final Duration duration;
  final double distance;
  final double averageSpeed;
  final double maxSpeed;
  final double spentFuel;
  final double startOdometer;
  final double endOdometer;
  final String deviceId;
  final String deviceName;
  final String positionId;
  final LatLng location;
  final String engineHours;
  final Duration? timeBetween;
  final double? odometerDifference;
  final double? totalOdomterDifference; // Add this line

  StopDetails({
    required this.startTime,
    required this.startTimeNew,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.spentFuel,
    required this.startOdometer,
    required this.endOdometer,
    required this.deviceId,
    required this.deviceName,
    required this.positionId,
    required this.location,
    required this.engineHours,
    this.timeBetween,
    this.odometerDifference,
    this.totalOdomterDifference, // Add this line
  });

  String get formattedStartTime {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(startTime);
  }

  String get formattedEndTime {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(endTime);
  }

  String get formattedDuration {
    return '${duration.inHours} hours, ${duration.inMinutes % 60} minutes';
  }

  String get formattedOdometerDifference {
    return odometerDifference != null
        ? odometerDifference!.toStringAsFixed(2)
        : 'N/A';
  }

  String get formattedTotalOdometerDifference {
    return totalOdomterDifference != null
        ? totalOdomterDifference!.toStringAsFixed(2)
        : 'N/A';
  }
}

class IgnitionChangeDetail {
  final LatLng location;
  final double speed;
  final DateTime deviceTime;

  IgnitionChangeDetail({
    required this.location,
    required this.speed,
    required this.deviceTime,
  });
  String get formattedDeviceTime {
    return DateFormat('dd-MM-yy HH:mm:ss').format(deviceTime);
  }
}
