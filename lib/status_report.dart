import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'histoy_screen.dart';
import 'package:permission_handler/permission_handler.dart';

String sumDurationStrings(List<String> durationStrings) {
  Duration totalDuration = Duration.zero;

  for (String durationString in durationStrings) {
    List<String> parts = durationString.split(':');
    if (parts.length == 3) {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);

      totalDuration +=
          Duration(hours: hours, minutes: minutes, seconds: seconds);
    }
  }

  int totalSeconds = totalDuration.inSeconds;
  return secondsToHhMm(totalSeconds);
}

String secondsToHhMm(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  return '$hours:${minutes.toString().padLeft(2, '0')}';
}

class DateAndTimePickerDialog extends StatefulWidget {
  final String title;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final Function(DateTime) onDateTimeSelected;

  const DateAndTimePickerDialog({
    super.key,
    required this.title,
    required this.initialDate,
    required this.onDateTimeSelected,
    required DateTime lastDate, this.firstDate,
  });

  @override
  _DateAndTimePickerDialogState createState() =>
      _DateAndTimePickerDialogState();
}

class _DateAndTimePickerDialogState extends State<DateAndTimePickerDialog> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
    selectedTime = TimeOfDay.fromDateTime(selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select ${widget.title} Date and Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Date'),
            subtitle: Text(
              '${selectedDate.toLocal()}'.split(' ')[0],
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 14)),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null && pickedDate != selectedDate) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
          ),
          ListTile(
            title: const Text('Time'),
            subtitle: Text(
              selectedTime.format(context),
            ),
            onTap: () async {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: selectedTime,
              );

              if (pickedTime != null && pickedTime != selectedTime) {
                setState(() {
                  selectedTime = pickedTime;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            DateTime selectedDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            // Call the callback with the selected date and time
            widget.onDateTimeSelected(selectedDateTime);

            Navigator.of(context).pop(selectedDateTime);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

// travel summary

class TravelSummary extends StatefulWidget {
  final String carNumber;
  final int carID;
  final String imagePath;

  const TravelSummary({
    super.key,
    required this.carNumber,
    required this.carID,
    required this.imagePath,
  });

  @override
  State<TravelSummary> createState() => _TravelSummaryState();
}

class _TravelSummaryState extends State<TravelSummary> {
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  List<Map<String, dynamic>> carData = [];
  List<String> startAddress = [];
  List<String> end_Address = [];
  String totalIdle = '';
  String totalRunningTime = "0.0";
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late DateTime? originalFrom;
  late DateTime? originalTo;
  String finishAddress = '';
  String beginAddress = '';
  LatLng carLocation = const LatLng(0, 0);
  String carAddress = "";
  Map<int, String> carAddresses = {};
  double odometerValue = 0.0;
  double todayodometerValue = 0.0; // Declare it here
  List<LatLng> polylinePoints = [];
  double carSpeed = 0;
  double MaximumSpeed = 0.0;
  double AverageSpeed = 0.0;
  String totalDistance = '';
  String totalDuration = '';
  final String tripApi = dotenv.env['TRIP_API']!;
  final String summaryApi = dotenv.env['SUMMARY_API']!;

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
    originalFrom = DateTime.now().subtract(const Duration(days: 7));
    originalTo = DateTime.now();
    fetchSummaryLog();
    Future.delayed(const Duration(milliseconds: 500), () {
      _showCustomDialog();
    });
  }

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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                // height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.7,
                child: Padding(
                  padding: const EdgeInsets.only(left: 1, right: 1, top: 1),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 40,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.black,
                        child: Text(
                          widget.carNumber,
                          style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "From date",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectDate('From', context);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              height: 40,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(originalFrom!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Image.asset("assets/cal.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "To date",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectDate('To', context);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              height: 40,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(originalTo!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Image.asset("assets/cal.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
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
                            onPressed: () {
                              fetchTripLog();
                              Navigator.of(context).pop();
                            },
                            child: Text('Submit',
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
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> fetchTripLog() async {
    final String carDetailsApiUrl =
        "$tripApi?deviceId=${widget.carID}&from=${_formatDateTime(_fromDate)}Z&to=${_formatDateTime(_toDate)}Z";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(carDetailsApiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          double totalDistance = 0.0; // Initialize total distance
          int runningTime = 0;
          double MaxSpeed = 0.0;
          double averageSpeed = 0.0;
          double? maxSpeed;

          for (final carItem in jsonResponse) {
            final double distance =
                carItem['distance'] / 1000; // Get the distance from each trip
            totalDistance += distance; // Sum up the distances

            final String startTimeStr = carItem['startTime'];
            final String endTimeStr = carItem['endTime'];
            final DateTime startTime = DateTime.parse(startTimeStr);
            final DateTime endTime = DateTime.parse(endTimeStr);
            final int durationInHours = endTime.difference(startTime).inHours;
            runningTime += durationInHours;

// Iterate through carItem data to find the highest maxSpeed

            final double? currentMaxSpeed = carItem['maxSpeed'] as double?;
            if (currentMaxSpeed != null) {
              if (maxSpeed == null || currentMaxSpeed > maxSpeed) {
                maxSpeed = currentMaxSpeed;
              }
            }

            MaxSpeed == maxSpeed;
            final double avgspeed = carItem['averageSpeed'];
            averageSpeed += avgspeed;
          }

          setState(() {
            odometerValue = totalDistance.roundToDouble();
            totalRunningTime = runningTime.toString();
            MaximumSpeed = maxSpeed!.roundToDouble();
            AverageSpeed = averageSpeed.roundToDouble();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No Data Found"),
        ));
      }
    } else {}
  }

  Future<void> fetchSummaryLog() async {
    // final String carDetailsApiUrl =
    //     "$summaryApi?deviceId=${widget.carID}&from=${_formatDateTime(_fromDate)}Z&to=${_formatDateTime(_toDate)}Z";
    final String carDetailsApiUrl =
        "$summaryApi?deviceId=${widget.carID}&from=${_formatDateTime(_fromDate)}Z&to=${_formatDateTime(_toDate)}Z";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(carDetailsApiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );
      print("report000 ${response.statusCode}");
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          double totalDistance = 0.0; // Initialize total distance
          int runningTime = 0;
          double MaxSpeed = 0.0;
          double averageSpeed = 0.0;
          double? maxSpeed;
          for (final carItem in jsonResponse) {
            final double distance =
                carItem['distance'] / 1000; // Get the distance from each trip
            totalDistance += distance; // Sum up the distances
            final String startTimeStr = carItem['startTime'];
            final String endTimeStr = carItem['endTime'];
            final DateTime startTime = DateTime.parse(startTimeStr);
            final DateTime endTime = DateTime.parse(endTimeStr);
            final int durationInHours = endTime.difference(startTime).inHours;
            runningTime += durationInHours;

            final double? currentMaxSpeed = carItem['maxSpeed'] as double?;
            if (currentMaxSpeed != null) {
              if (maxSpeed == null || currentMaxSpeed > maxSpeed) {
                maxSpeed = currentMaxSpeed;
              }
            }

            MaxSpeed == maxSpeed;
            final double avgspeed = carItem['averageSpeed'];
            averageSpeed += avgspeed;
          }

          setState(() {
            odometerValue = totalDistance.roundToDouble();
            totalRunningTime = runningTime.toString();
            MaximumSpeed = maxSpeed!.roundToDouble();
            AverageSpeed = averageSpeed.roundToDouble();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No Data Found"),
        ));
      }
    } else {}
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return "${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
      }
    } catch (e) {}
    return "Address not found";
  }

  Future<void> endAddress(
      String sessionCookies, double end_latitude, double end_longitude) async {
    const addressApiUrl = 'http://103.174.103.78:8085/CRT/address.ajax.php';
    final addressUrl = '$addressApiUrl?lat=$end_latitude&lng=$end_longitude';

    try {
      final addressResponse = await http.get(
        Uri.parse(addressUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (addressResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        String end_address = addressData['addr'];
        setState(() {
          end_Address.add(end_address);
          finishAddress = end_address;
        });
      } else {}
    } catch (error) {}
  }

  void _selectDate(String title, BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDateTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DateAndTimePickerDialog(
          title: title,
          initialDate: title == 'From' ? _fromDate : _toDate,
          lastDate: currentDate,
          onDateTimeSelected: (dateTime) async {
            // Store the original selected date and time
            DateTime originalDateTime = dateTime;
            DateTime utcDateTime = dateTime.toUtc();
            utcDateTime =
                utcDateTime.subtract(const Duration(hours: 5, minutes: 30));
            String formattedDateTime =
            DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(utcDateTime);
            setState(() {
              if (title == 'From') {
                _fromDate = utcDateTime;
                setState(() {
                  originalFrom = originalDateTime;
                });
              } else {
                _toDate = utcDateTime;
                originalTo =
                    originalDateTime; // Store the original selected to date and time
              }
            });
            fetchTripLog();
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime.toLocal());
    } else {
      return ''; // You may want to handle this case based on your requirements
    }
  }

  String _formatDate(DateTime date) {
    String formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
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
                "${widget.carNumber}  Report",
                style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        body: Column(children: [
          // Header with vehicle name and odometer
          // List of cards with key-value pair
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "From date",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            _selectDate('From', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.grey.shade400,
                                border:
                                Border.all(color: Colors.grey.shade200)),
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(originalFrom!),
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 12),
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset("assets/cal.png"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "To date",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            _selectDate('To', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.grey.shade400,
                                border:
                                Border.all(color: Colors.grey.shade200)),
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(originalTo!),
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 12),
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset("assets/cal.png"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              isLoading
                  ? Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.white,
                    size: 50,
                  ))
                  : GestureDetector(
                  onTap: () {
                    _showSlider(context);
                  },
                  child: Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.only(
                              left: 2, right: 2, bottom: 8, top: 2),
                          width: MediaQuery.of(context).size.width * 0.94,
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
                            color: Colors.grey.shade400,
                          ),
                          child: Column(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                height: MediaQuery.of(context).size.height *
                                    0.08,
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(0,
                                          1), // changes position of shadow
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(
                                      5.0), // Adjust the value as needed
                                  color: Colors.black,
                                ),
                                child: Text(
                                  widget.carNumber,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Row(
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      widget.imagePath,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Column(
                                    children: [
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      SizedBox(
                                        height: 20,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width *
                                            0.6,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.timer_sharp,
                                              color: Colors.yellow.shade900,
                                              size: 14,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              "Running Hours :  ",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              "$totalRunningTime Hrs",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      SizedBox(
                                        height: 20,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width *
                                            0.6,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.speed,
                                              color: Colors.yellow.shade900,
                                              size: 14,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              "Maximum Speed :  ",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              "$MaximumSpeed KM/Hr",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      SizedBox(
                                        height: 20,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width *
                                            0.6,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.speed,
                                              color: Colors.yellow.shade900,
                                              size: 14,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              "Total Distance :  ",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              "$odometerValue KM",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      SizedBox(
                                        height: 20,
                                        width: MediaQuery.of(context)
                                            .size
                                            .width *
                                            0.6,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.speed,
                                              color: Colors.yellow.shade900,
                                              size: 14,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              "Average Speed :  ",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              "$AverageSpeed KM",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )),
                    ],
                  )),
            ],
          ),
        ]));
  }

  void _showSlider(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return HistoryScreen(
                        fromDate: _fromDate!,
                        toDate: _toDate!,
                        carID: widget.carID,
                        carNumber: widget.carNumber,
                      );
                    },
                  ),
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height *
                    0.15, // Adjust the height as needed
                width: MediaQuery.of(context).size.width * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Add your slider widget here
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.shade200),
                            child: const Icon(
                              Icons.history,
                              size: 28,
                              color: Colors.green,
                            )),
                        const Text(
                          'Show History',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // Add your slider widget here
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TripLogs(
                          carID: widget.carID,
                          fromDate: _formatDateTime(_fromDate),
                          toDate: _formatDateTime(_toDate),
                        )));
              },
              child: Container(
                height: MediaQuery.of(context).size.height *
                    0.15, // Adjust the height as needed
                width: MediaQuery.of(context).size.width * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Add your slider widget here
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade200),
                            child: const Icon(
                              Icons.route,
                              size: 28,
                              color: Colors.blue,
                            )),
                        const Text(
                          'Trip Report',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // Add your slider widget here
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildKeyValueRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$key:',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon) {
    return Card(
      color: Colors.blueGrey.shade900,
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.grey),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class DistanceReport extends StatefulWidget {
  final String carNumber;
  final int carID;
  final String imagePath;

  const DistanceReport({
    super.key,
    required this.carNumber,
    required this.carID,
    required this.imagePath,
  });

  @override
  State<DistanceReport> createState() => _DistanceReportState();
}

class _DistanceReportState extends State<DistanceReport> {
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  List<Map<String, dynamic>> carData = [];
  List<String> startAddress = [];
  List<String> end_Address = [];

  String totalIdle = '';
  String totalRunningTime = "0.0";
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late DateTime? originalFrom;
  late DateTime? originalTo;
  String finishAddress = '';
  String beginAddress = '';
  LatLng carLocation = const LatLng(0, 0);
  String carAddress = "";
  Map<int, String> carAddresses = {};
  double odometerValue = 0.0;
  double todayodometerValue = 0.0; // Declare it here
  MapType _currentMapType = MapType.normal;
  List<LatLng> polylinePoints = [];
  double carSpeed = 0;
  double MaximumSpeed = 0.0;
  double AverageSpeed = 0.0;
  String totalDistance = '';
  String totalDuration = '';
  final String tripApi = dotenv.env['TRIP_API']!;
  final String summaryApi = dotenv.env['SUMMARY_API']!;

  double todaysDistanceReport = 0.0;

  @override
  void initState() {
    super.initState();
    // travelSummary();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
    originalFrom = DateTime.now().subtract(const Duration(days: 7));
    originalTo = DateTime.now();
    fetchTripLog();
    // fetchSummaryLog();
    Future.delayed(const Duration(milliseconds: 500), () {
      _showCustomDialog();
    });
  }

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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                // height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.7,
                child: Padding(
                  padding: const EdgeInsets.only(left: 1, right: 1, top: 1),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 40,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.black,
                        child: Text(
                          widget.carNumber,
                          style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "From date",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectDateDistance('From', context);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              height: 40,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(originalFrom!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Image.asset("assets/cal.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "To date",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectDateDistance('To', context);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              height: 40,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(originalTo!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Image.asset("assets/cal.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
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
                            onPressed: () {
                              fetchTripLog();
                              Navigator.of(context).pop();
                            },
                            //return true when click on "Yes"
                            child: Text('Submit',
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
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> tripLogs = [];

  Future<void> fetchTripLog() async {
    final String carDetailsApiUrl =
        "$tripApi?deviceId=${widget.carID}&from=${_formatDateTime(_fromDate)}Z&to=${_formatDateTime(_toDate)}Z";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(carDetailsApiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });

        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          // Group by date and calculate total distance
          Map<String, Map<String, dynamic>> groupedData = {};

          for (var item in jsonResponse) {
            // Parse the end time to get the correct date
            final DateTime endTime = DateTime.parse(item['endTime']).toLocal();
            final String date = DateFormat('dd-MM-yyyy').format(endTime);

            final double distance =
                (item['distance'] ?? 0) / 1000; // Convert to kilometers

            if (groupedData.containsKey(date)) {
              groupedData[date]!['totalDistance'] += distance;
              groupedData[date]!['trips'].add(item);
            } else {
              groupedData[date] = {
                'totalDistance': distance,
                'trips': [item],
              };
            }
          }

          // Convert the map to a list of maps for the ListView.builder and PDF generation
          tripLogs = groupedData.entries.map((entry) {
            return {
              'date': entry.key,
              'totalDistance': entry.value['totalDistance'],
              'trips': entry.value['trips'],
            };
          }).toList();

          setState(() {
            // Use tripLogs in the ListView.builder
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("No Data Found"),
        ));
      }
    } else {}
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return "${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
      }
    } catch (e) {}
    return "Address not found";
  }

  Future<void> endAddress(
      String sessionCookies, double end_latitude, double end_longitude) async {
    const addressApiUrl = 'http://103.174.103.78:8085/CRT/address.ajax.php';
    final addressUrl = '$addressApiUrl?lat=$end_latitude&lng=$end_longitude';

    try {
      final addressResponse = await http.get(
        Uri.parse(addressUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (addressResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        String end_address = addressData['addr'];
        setState(() {
          end_Address.add(end_address);
          finishAddress = end_address;
        });
      } else {}
    } catch (error) {}
  }

  void _selectDateDistance(String title, BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDateTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DateAndTimePickerDialog(
          title: title,
          initialDate: title == 'From' ? _fromDate : _toDate,
          lastDate: currentDate,
          onDateTimeSelected: (dateTime) async {
            // For 'To' date, set time to 23:59:59 to include the entire day
            if (title == 'To') {
              dateTime = DateTime(
                dateTime.year,
                dateTime.month,
                dateTime.day,
                23,
                59,
                59,
              );
            }

            setState(() {
              if (title == 'From') {
                _fromDate = dateTime;
                originalFrom =
                    dateTime; // Store the original selected from date and time
              } else {
                _toDate = dateTime;
                originalTo =
                    dateTime; // Store the original selected to date and time
              }
            });
            fetchTripLog();
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime.toUtc());
    } else {
      return '';
    }
  }

  String _formatDate(DateTime date) {
    // Format the DateTime object
    String formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return formattedDate;
  }

  Future<void> _generateTravellSummaryPdf(BuildContext context) async {
    final pdf = pw.Document();

    if (tripLogs == null || tripLogs.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Text(
              'No Data Here',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      );
    } else {
      Map<String, double> groupedDistance = {};
      for (var log in tripLogs) {
        final String date = log['date'];
        final double totalDistance = log['totalDistance'];

        if (groupedDistance.containsKey(date)) {
          groupedDistance[date] = (groupedDistance[date] ?? 0) + totalDistance;
        } else {
          groupedDistance[date] = totalDistance;
        }
      }

      const int itemsPerPage = 20;
      int itemCount = groupedDistance.length;

      // Loop to handle multiple pages
      for (int page = 0; page * itemsPerPage < itemCount; page++) {
        pdf.addPage(
          pw.Page(
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                // Display headers
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey,
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text(
                        'Trip Summary',
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),

                // Display the Trip Details in a table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey, width: 1),
                  columnWidths: {
                    0: const pw.FractionColumnWidth(0.5),
                    1: const pw.FractionColumnWidth(0.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(
                              left: 20, right: 8, top: 8, bottom: 8),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(
                              left: 20, right: 8, top: 8, bottom: 8),
                          child: pw.Text(
                            'Total Distance',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (var i = page * itemsPerPage;
                    i < (page + 1) * itemsPerPage && i < itemCount;
                    i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(
                                left: 20, right: 8, top: 8, bottom: 8),
                            child: pw.Text(
                              groupedDistance.keys.elementAt(i),
                              style: const pw.TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(
                                left: 20, right: 8, top: 8, bottom: 8),
                            child: pw.Text(
                              '${groupedDistance.values.elementAt(i).toStringAsFixed(2)} km',
                              style: const pw.TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/TravelSummary.pdf');
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravellSummaryPDFViewerScreen(file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 10,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
              ),
              // onPressed: () => _generateInvoicePdf(context),
              onPressed: () async {
                // await _fetchStatusLogAndUpdateQuery();
                fetchTripLog();
                _generateTravellSummaryPdf(
                    context); // Generate PDF with fetched data
              },
            ),
          ],
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
                "${widget.carNumber}  Report",
                style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "From date",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            // _selectDate('From', context);
                            _selectDateDistance('From', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.grey.shade400,
                                border:
                                Border.all(color: Colors.grey.shade200)),
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(originalFrom!),
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 12),
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset("assets/cal.png"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "To date",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            // _selectDate('To', context);
                            _selectDateDistance('To', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.grey.shade400,
                                border:
                                Border.all(color: Colors.grey.shade200)),
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(originalTo!),
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 12),
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset("assets/cal.png"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              isLoading
                  ? Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.white,
                    size: 50,
                  ))
                  :Container()
            ],
          ),
        ));
  }

  void _showSlider(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return HistoryScreen(
                        fromDate: _fromDate!,
                        toDate: _toDate!,
                        carID: widget.carID,
                        carNumber: widget.carNumber,
                      );
                    },
                  ),
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height *
                    0.15, // Adjust the height as needed
                width: MediaQuery.of(context).size.width * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Add your slider widget here
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.shade200),
                            child: const Icon(
                              Icons.history,
                              size: 28,
                              color: Colors.green,
                            )),
                        const Text(
                          'Show History',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // Add your slider widget here
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TripLogs(
                          carID: widget.carID,
                          fromDate: _formatDateTime(_fromDate),
                          toDate: _formatDateTime(_toDate),
                        )));
              },
              child: Container(
                height: MediaQuery.of(context).size.height *
                    0.15, // Adjust the height as needed
                width: MediaQuery.of(context).size.width * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Add your slider widget here
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade200),
                            child: const Icon(
                              Icons.route,
                              size: 28,
                              color: Colors.blue,
                            )),
                        const Text(
                          'Trip Report',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // Add your slider widget here
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildKeyValueRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$key:',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon) {
    return Card(
      color: Colors.blueGrey.shade900,
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.grey),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class TripLogs extends StatefulWidget {
  final int carID;
  final String fromDate;
  final String toDate;

  const TripLogs(
      {super.key,
        required this.fromDate,
        required this.toDate,
        required this.carID});

  @override
  _TripLogsState createState() => _TripLogsState();
}

class _TripLogsState extends State<TripLogs> {
  List<Map<String, dynamic>> tripData = []; // Store trip data here
  final storage = const FlutterSecureStorage();
  final String tripApi = dotenv.env['TRIP_API']!;
  bool isLoading = true;
  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int pageSize = 20;


  @override
  void initState() {
    super.initState();
    fetchTripLog();
  }


  Future<void> fetchTripLog() async {
    DateTime fromDateTime = DateTime.parse(widget.fromDate);
    DateTime toDateTime = DateTime.parse(widget.toDate);

    // Subtract 5 hours and 30 minutes
    fromDateTime = fromDateTime.subtract(const Duration(hours: 5, minutes: 30));
    toDateTime = toDateTime.subtract(const Duration(hours: 5, minutes: 30));

    // Convert back to the required format (ISO8601 in this case, with 'Z' suffix)
    String fromAdjusted =
        '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(fromDateTime)}Z';
    String toAdjusted =
        '${DateFormat("yyyy-MM-ddTHH:mm:ss").format(toDateTime)}Z';
    final apiUrl =
        '$tripApi?deviceId=${widget.carID}&from=$fromAdjusted&to=$toAdjusted';
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        print("tripstatus${response.statusCode}");
        setState(() {
          isLoading = false;
          tripData = List<Map<String, dynamic>>.from(json.decode(response.body));
        });

        // for (var trip in tripData) {
        //   final startLat = double.parse(trip['startLat'].toStringAsFixed(2));
        //   final startLon = double.parse(trip['startLon'].toStringAsFixed(2));
        //   final endLat = double.parse(trip['endLat'].toStringAsFixed(2));
        //   final endLon = double.parse(trip['endLon'].toStringAsFixed(2));
        //
        //   if (startLat != null &&
        //       startLon != null &&
        //       endLat != null &&
        //       endLon != null) {
        //     final List<Placemark> startPlacemarks =
        //         await placemarkFromCoordinates(startLat, startLon);
        //     final List<Placemark> endPlacemarks =
        //         await placemarkFromCoordinates(endLat, endLon);
        //
        //     if (startPlacemarks.isNotEmpty) {
        //       final String startAddress =
        //           "${startPlacemarks[0].name ?? ''}, ${startPlacemarks[0].locality ?? ''},  ${startPlacemarks[0].administrativeArea ?? ''}, ${startPlacemarks[0].country ?? ''}";
        //     setState(() {
        //       trip['startAddress'] = startAddress;
        //     });
        //
        //     }
        //
        //     if (endPlacemarks.isNotEmpty) {
        //       final String endAddress =
        //           "${endPlacemarks[0].name ?? ''}, ${endPlacemarks[0].locality ?? ''}, ${endPlacemarks[0].administrativeArea ?? ''}, ${endPlacemarks[0].country ?? ''}";
        //       setState(() {
        //         trip['endAddress'] = endAddress;
        //       });
        //     }
        //   }else{
        //     trip['startAddress'] = "Loading address...";
        //     trip['endAddress'] = "Loading address...";
        //   }
        // }
        List<Future<void>> reverseGeocodingTasks = [];

        for (var trip in tripData) {
          final startLat = double.parse(trip['startLat'].toStringAsFixed(2));
          final startLon = double.parse(trip['startLon'].toStringAsFixed(2));
          final endLat = double.parse(trip['endLat'].toStringAsFixed(2));
          final endLon = double.parse(trip['endLon'].toStringAsFixed(2));
          reverseGeocodingTasks.add(
              getAddressFromCoordinates(startLat, startLon).then((startAddress) {
                setState(() {
                  trip['startAddress'] = startAddress;
                });
              })
          );

          reverseGeocodingTasks.add(
              getAddressFromCoordinates(endLat, endLon).then((endAddress) {
                setState(() {
                  trip['endAddress'] = endAddress;
                });
              })
          );
        }

// Wait for all geocoding tasks to finish
        await Future.wait(reverseGeocodingTasks);

      } else {
        throw Exception('Failed to load trips');
      }
    }
  }


  Map<String, String> addressCache = {};


  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    String key = "$lat,$lon";
    if (addressCache.containsKey(key)) {
      return addressCache[key]!;
    }

    final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      final String address =
          "${placemarks[0].name ?? ''}, ${placemarks[0].locality ?? ''},  ${placemarks[0].administrativeArea ?? ''}, ${placemarks[0].country ?? ''}";
      addressCache[key] = address;
      return address;
    }
    return "Unknown Address";
  }


  void openGoogleMaps(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) async {
    String url =
        'https://www.google.com/maps/dir/?api=1&origin=$startLatitude,$startLongitude&destination=$endLatitude,$endLongitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }


  Future<void> _generateTravellSummaryPdf(BuildContext context) async {
    final pdf = pw.Document();
    if (tripData == null || tripData.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Text(
              'No Data Here',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      );
    } else {
      const int itemsPerPage = 20; // Number of items per page
      int itemCount = tripData.length;
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      for (int page = 0; page * itemsPerPage < itemCount; page++) {
        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(10),
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey,
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text(
                        'Trip Summary',
                        style: pw.TextStyle(
                            fontSize: 22,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),

                // Display the Trip Details as a list
                for (var i = page * itemsPerPage;
                i < (page + 1) * itemsPerPage && i < itemCount;
                i++)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Container(
                      padding: const pw.EdgeInsets.only(
                          left: 20, right: 20, bottom: 10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8.0),
                        border: pw.Border.all(color: PdfColors.grey),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.black,
                              borderRadius: pw.BorderRadius.circular(7.0),
                            ),
                            child: pw.Row(
                              mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'From:',
                                      style: const pw.TextStyle(
                                          fontSize: 14, color: PdfColors.white),
                                    ),
                                    pw.Text(
                                      dateFormat.format(DateTime.parse(
                                          tripData[i]['startTime'] ??
                                              '0000-00-00T00:00:00Z')),
                                      style: pw.TextStyle(
                                          fontSize: 14,
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold),
                                    ),
                                  ],
                                ),
                                pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'To:',
                                      style: const pw.TextStyle(
                                          fontSize: 14, color: PdfColors.white),
                                    ),
                                    pw.Text(
                                      dateFormat.format(DateTime.parse(
                                          tripData[i]['endTime'] ??
                                              '0000-00-00T00:00:00Z')),
                                      style: pw.TextStyle(
                                          fontSize: 14,
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Total Duration',
                                      style: pw.TextStyle(
                                          fontSize: 13,
                                          fontWeight: pw.FontWeight.normal)),
                                  pw.Text(
                                      "${((tripData[i]['duration'] ?? 0) / 60000).toStringAsFixed(2)} hr",
                                      style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold)),
                                ],
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Total Distance',
                                      style: const pw.TextStyle(fontSize: 13)),
                                  pw.Text(
                                      '${((tripData[i]['distance'] ?? 0) / 1000).toStringAsFixed(2)} km',
                                      style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Avg. Speed',
                                      style: const pw.TextStyle(fontSize: 13)),
                                  pw.Text(
                                    '${tripData[i]['averageSpeed']?.toStringAsFixed(2) ?? 'N/A'} Kmph',
                                    style: pw.TextStyle(
                                        fontSize: 14,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Max. Speed',
                                      style: const pw.TextStyle(fontSize: 13)),
                                  pw.Text(
                                    '${tripData[i]['maxSpeed']?.toStringAsFixed(2) ?? 'N/A'} Kmph',
                                    style: pw.TextStyle(
                                        fontSize: 14,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            children: [
                              pw.Container(
                                height: 10,
                                width: 10,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.green,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.Text(
                                ' ${tripData[i]['startAddress'] ?? 'N/A'}',
                                style: const pw.TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            children: [
                              pw.Container(
                                height: 10,
                                width: 10,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.red,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.Text(
                                ' ${tripData[i]['endAddress'] ?? 'N/A'}',
                                style: const pw.TextStyle(fontSize: 14),
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
        );
      }
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/TravelSummary.pdf');
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravellSummaryPDFViewerScreen(file.path),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            'Trip Logs',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
          ),
          leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.white,
              )),

          actions: [
            IconButton(
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
              ),
              onPressed: () async {
                fetchTripLog();
                _generateTravellSummaryPdf(context);
                // Generate PDF with fetched data
              },
            ),
          ],
        ),
        body: isLoading
            ? Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.white,
              size: 50,
            ))
            : tripData.isNotEmpty
            ? ListView.builder(
          itemCount: tripData.length,
          itemBuilder: (context, index) {
            final trip = tripData[index];
            final startTimeStr = trip['startTime'];
            DateTime parsedStartTime = DateTime.parse(startTimeStr);
            parsedStartTime = parsedStartTime
                .add(const Duration(hours: 11, minutes: 00));
            final formattedStartTime =
            DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(parsedStartTime);
            final displayStartTime = formattedStartTime ?? "N/A";
            final endTimeStr = trip['endTime'];
            DateTime parsedEndTime = DateTime.parse(endTimeStr);
            parsedEndTime = parsedEndTime
                .add(const Duration(hours: 11, minutes: 00));
            final formattedEndTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(parsedEndTime);
            final displayEndTime = formattedEndTime ?? "N/A";
            final DateTime startTime = DateTime.parse(startTimeStr);
            final DateTime endTime = DateTime.parse(endTimeStr);
            final Duration duration = endTime.difference(startTime);
            final int hours = duration.inHours;
            final int minutes = duration.inMinutes.remainder(60);
            // Replace with actual calculation based on trip data
            final maxSpeed = trip['maxSpeed'].roundToDouble();

            final startOdometer =
                trip['startOdometer'] / 1000.roundToDouble();
            final endOdometer =
                trip['endOdometer'] / 1000.roundToDouble();
            final totalDistance =
            (endOdometer - startOdometer).toStringAsFixed(2);
            final averageSpeed = trip['averageSpeed'].roundToDouble();

            final startAddress = trip['startAddress'];
            final finishAddress = trip['endAddress'];
            return tripData.isEmpty
                ? const Center(
                child: Text(
                  "No Trip Logs",
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ))
                : GestureDetector(
                onTap: () {
                  openGoogleMaps(
                      trip['startLat'],
                      trip['startLon'],
                      trip['endLat'],
                      trip['endLon']);
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 0, right: 5, bottom: 8, top: 0),
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 5, right: 5, bottom: 8, top: 0),
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
                      color: Colors.grey.shade400,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 5,
                              right: 5,
                              bottom: 8,
                              top: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            alignment: Alignment.center,
                            // height: MediaQuery.of(context).size.height * 0.08,
                            width:
                            MediaQuery.of(context).size.width,
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
                              borderRadius: BorderRadius.circular(
                                  5.0), // Adjust the value as needed
                              color: Colors.black,
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceEvenly,
                                  children: [
                                    Text(
                                      "From :",
                                      style: GoogleFonts.poppins(
                                          color: Colors
                                              .grey.shade400,
                                          fontSize: 11,
                                          fontWeight:
                                          FontWeight.w400),
                                    ),
                                    Text(
                                      displayStartTime,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w400),
                                    ),
                                  ],
                                ),
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white,
                                ),
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceEvenly,
                                  children: [
                                    Text(
                                      "To :",
                                      style: GoogleFonts.poppins(
                                          color: Colors
                                              .grey.shade400,
                                          fontSize: 11,
                                          fontWeight:
                                          FontWeight.w400),
                                    ),
                                    Text(
                                      displayEndTime,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_sharp,
                                        color:
                                        Colors.red.shade800,
                                        size: 25,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            "Total Duration",
                                            style: GoogleFonts
                                                .poppins(
                                                color: Colors
                                                    .black,
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          Text(
                                            "${hours}h ${minutes}m",
                                            style: GoogleFonts
                                                .poppins(
                                                color: Colors
                                                    .black,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.social_distance,
                                        color:
                                        Colors.red.shade800,
                                        size: 25,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            "Total Distance",
                                            style: GoogleFonts
                                                .poppins(
                                                color: Colors
                                                    .black,
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          Text(
                                            "$totalDistance Km",
                                            style: GoogleFonts
                                                .poppins(
                                                color: Colors
                                                    .black,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed_rounded,
                                        color:
                                        Colors.red.shade800,
                                        size: 25,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            "Max. Speed",
                                            style: GoogleFonts
                                                .poppins(
                                                color: Colors
                                                    .black,
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          Text(
                                            "$maxSpeed km/h",
                                            style: GoogleFonts
                                                .poppins(
                                                color: Colors
                                                    .black,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed_rounded,
                                        color:
                                        Colors.red.shade800,
                                        size: 25,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            "Average Speed",
                                            style: GoogleFonts
                                                .poppins(
                                                color: Colors
                                                    .black,
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          Text(
                                            "$averageSpeed km/h",
                                            style: GoogleFonts
                                                .poppins(
                                                color: Colors
                                                    .black,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 13,
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset(
                                        "assets/start.png"),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Expanded(
                                    child: Text(
                                      startAddress.toString(),
                                      maxLines: 2,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 13,
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset(
                                        "assets/finish.png"),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Expanded(
                                    child: Text(
                                      finishAddress.toString(),
                                      maxLines: 2,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ));
          },
        )
            : const Center(
            child: Text(
              "No Trip Logs",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ))
    );
  }
}


class StatusLog extends StatefulWidget {
  final String carNumber;
  final int carID;

  const StatusLog({
    super.key,
    required this.carNumber,
    required this.carID,
  });

  @override
  State<StatusLog> createState() => StatusLogState();
}

class StatusLogState extends State<StatusLog> {
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  List<Map<String, dynamic>> carData = [];
  List<String> startAddress = [];
  List<String> end_Address = [];
  String totalDistance = '';
  String totalDuration = '';
  String totalIdle = '';
  String totalDrivingTime = "00:00:00";
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late DateTime? originalFrom;
  late DateTime? originalTo;
  String finishAddress = '';
  String beginAddress = '';

  List<LatLng> polylinePoints = [];
  double carSpeed = 0;
  double MaximumSpeed = 0.0;
  double AverageSpeed = 0.0;
  double odometerValue = 0.0;
  double todayodometerValue = 0.0; // Declare it here
  String totalRunningTime = "0.0";
  List<dynamic> tripData = []; // Store trip data here
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
    originalFrom = DateTime.now().subtract(const Duration(days: 7));
    originalTo = DateTime.now();
    _fetchStatusLogAndUpdateQuery();
    _fetchGeofences().then((_) {
      _fetchStatusLogAndUpdateQuery();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _showCustomDialog();
    });
  }

  void _showCustomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.zero,
          insetPadding: EdgeInsets.zero,
          buttonPadding: EdgeInsets.zero,
          titlePadding: EdgeInsets.zero,
          title: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDatePicker("From date", _fromDate!,
                              (context, newDate) {
                            setState(() {
                              _fromDate =
                                  newDate; // Update the state with the new date
                            });
                          }),
                      _buildDatePicker("To date", _toDate!, (context, newDate) {
                        setState(() {
                          _toDate =
                              newDate; // Update the state with the new date
                        });
                      }),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Select Options',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildCheckboxOptions(),
                ),
                ElevatedButton(
                  onPressed: () {
                    _fetchStatusLogAndUpdateQuery();
                    Navigator.pop(context);
                  },
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCheckboxOptions() {
    return [
      _buildCheckboxOption(
          "Ignition On", "ignitionOn", Icons.power, Colors.green),
      _buildCheckboxOption(
          "Ignition Off", "ignitionOff", Icons.power, Colors.red),
      _buildCheckboxOption(
          "Over Speed", "overSpeed", Icons.speed, Colors.orange),
      _buildCheckboxOption("Device Moving", "deviceMoving",
          Icons.nights_stay_outlined, Colors.yellow),
      _buildCheckboxOption("Geofence Entered", "geofenceEnter",
          Icons.location_pin, Colors.green.shade500),
      _buildCheckboxOption(
          "Geofence Exited", "geofenceExit", Icons.location_pin, Colors.red),
    ];
  }

  final Set<String> _selectedOptions = {};

  Widget _buildCheckboxOption(
      String title, String value, IconData icon, Color color) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return CheckboxListTile(
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.black)),
            ],
          ),
          value: _selectedOptions.contains(value),
          onChanged: (bool? newValue) {
            setState(() {
              if (newValue == true) {
                _selectedOptions.add(value);
              } else {
                _selectedOptions.remove(value);
              }
            });
          },
        );
      },
    );
  }
  Widget _buildDatePicker(
      String label, DateTime date, Function(BuildContext, DateTime) onTap) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        void _handleDateChange(DateTime newDate) {
          setState(() {
            date = newDate;
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () async {
                DateTime? newDate = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );

                if (newDate != null && newDate != date) {
                  _handleDateChange(newDate);
                  onTap(context,
                      newDate); // Pass the selected date to the callback
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                height: 40,
                width: MediaQuery.of(context).size.width * 0.38,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(date),
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset("assets/cal.png")),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// Example of a date formatting function
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Map<int, String> geofenceMap = {};

  Future<void> _fetchGeofences() async {
    final String geofenceApi = dotenv.env['GEOFENCE_API']!;
    final String apiUrl = "$geofenceApi?deviceId=${widget.carID}";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Cookie': sessionCookies},
        );
        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          for (var geoJson in jsonResponse) {
            final int id = geoJson['id'];
            final String name = geoJson['name'];
            geofenceMap[id] = name;
          }
        } else {}
      } catch (error) {}
    } else {}
  }

  Future<void> _fetchStatusLogAndUpdateQuery() async {
    final String eventApi = dotenv.env['NOTIFICATION_API']!;
    String types =
    _selectedOptions.isEmpty ? 'allEvents' : _selectedOptions.join(',');

    final String carDetailsApiUrl =
        "$eventApi?deviceId=${widget.carID}&from=${_formatDateTime(_fromDate)}Z&to=${_formatDateTime(_toDate)}Z&type=$types";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(carDetailsApiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          setState(() {
            tripData = jsonResponse;
            isLoading = false;
          });
          for (var event in jsonResponse) {
            if (event['geofenceId'] != null) {
              final int geofenceId = event['geofenceId'];
              final String? geofenceName = geofenceMap[geofenceId];
              if (geofenceName == null) {}
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("No Data Found"),
          ));
        }
      }
    } else {}
  }

// Map to store geofence IDs and names

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return "${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
      }
    } catch (e) {}
    return "Address not found";
  }

  Future<void> endAddress(
      String sessionCookies, double end_latitude, double end_longitude) async {
    const addressApiUrl = 'http://103.174.103.78:8085/CRT/address.ajax.php';
    final addressUrl = '$addressApiUrl?lat=$end_latitude&lng=$end_longitude';

    try {
      final addressResponse = await http.get(
        Uri.parse(addressUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (addressResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        String end_address = addressData['addr'];
        // Add the address to the list
        setState(() {
          end_Address.add(end_address);
          finishAddress = end_address;
        });
      } else {}
    } catch (error) {}
  }

  void _selectDate(String title, BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDateTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DateAndTimePickerDialog(
          title: title,
          initialDate: title == 'From' ? _fromDate : _toDate,
          lastDate: currentDate,
          onDateTimeSelected: (dateTime) async {
            // Store the original selected date and time
            DateTime originalDateTime = dateTime;

            // Convert the selected dateTime to UTC
            DateTime utcDateTime = dateTime.toUtc();
            // Adjust the time zone difference, assuming it's IST (-5:30)
            utcDateTime =
                utcDateTime.subtract(const Duration(hours: 5, minutes: 30));

            // Format the UTC datetime to include 'T' and 'Z'
            String formattedDateTime =
            DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(utcDateTime);

            setState(() {
              if (title == 'From') {
                _fromDate = utcDateTime;
                originalFrom =
                    originalDateTime; // Store the original selected from date and time
              } else {
                _toDate = utcDateTime;
                originalTo =
                    originalDateTime; // Store the original selected to date and time
              }
            });
            setState(() {
              _fetchStatusLogAndUpdateQuery();
            });
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime.toLocal());
    } else {
      return ''; // You may want to handle this case based on your requirements
    }
  }

  Future<void> _generateInvoicePdf(BuildContext context) async {
    if (tripData == null || tripData.isEmpty) {
      return;
    } else {}

    final pdf = pw.Document();
    const int itemsPerPage = 20; // Adjust the number of items per page
    int itemCount = tripData.length;
    for (int page = 0; page * itemsPerPage < itemCount; page++) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              // Display headers
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey,
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColors.black,
                      width: 1,
                    ),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: <pw.Widget>[
                    pw.Text(
                      'Notification',
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Date',
                      style: pw.TextStyle(
                          fontSize: 25, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // Display the Event Time and Notification Type as a list
              for (var i = page * itemsPerPage;
              i < (page + 1) * itemsPerPage && i < itemCount;
              i++)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Display the notification type
                        pw.Text(
                          tripData[i]['type'] ??
                              'N/A', // Handle potential null values
                          style: const pw.TextStyle(fontSize: 16),
                        ),
                        // Parse and display the event time in local time
                        pw.Text(
                          DateFormat('yyyy-MM-dd HH:mm:ss').format(
                            DateTime.parse(tripData[i]['eventTime'] ?? '').add(
                              const Duration(hours: 5, minutes: 30),
                            ),
                          ),
                          style: const pw.TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5), // Add a SizedBox with height 5
                    if (i < (page + 1) * itemsPerPage - 1 && i < itemCount - 1)
                      pw.Divider(
                          thickness:
                          0.5), // Add a Divider if it's not the last item
                  ],
                ),
            ],
          ),
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Status Report.pdf');
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusPDFViewerScreen(file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 10,
          actions: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined,
                      color: Colors.white, size: 17),
                  onPressed: () {
                    _showCustomDialog();
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                  ),
                  // onPressed: () => _generateInvoicePdf(context),
                  onPressed: () async {
                    await _fetchStatusLogAndUpdateQuery(); // Fetch data
                    _generateInvoicePdf(
                        context); // Generate PDF with fetched data
                  },
                ),
              ],
            ),
          ],
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
                "${widget.carNumber}  ",
                style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        body: Column(children: [
          Expanded(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "From date",
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          GestureDetector(
                            onTap: () {
                              _selectDate('From', context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: Colors.grey.shade400,
                                  border: Border.all(color: Colors.grey.shade200)),
                              height: 40,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(_fromDate!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Image.asset("assets/cal.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "To date",
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          GestureDetector(
                            onTap: () {
                              _selectDate('To', context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: Colors.grey.shade400,
                                  border: Border.all(color: Colors.grey.shade200)),
                              height: 40,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(_toDate!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Image.asset("assets/cal.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                isLoading
                    ? Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.white,
                      size: 50,
                    ))
                    : Expanded(
                  child: ListView.builder(
                    itemCount: tripData.length,
                    itemBuilder: (BuildContext context, int index) {
                      dynamic trip = tripData[index];
                      String eventTime = trip['eventTime'];
                      DateTime parsedEventTime = DateTime.parse(eventTime);
                      parsedEventTime = parsedEventTime
                          .add(const Duration(hours: 5, minutes: 30));
                      String formattedEventTime =
                      DateFormat('yyyy-MM-dd HH:mm:ss')
                          .format(parsedEventTime);
                      int? geofenceId = trip['geofenceId'];
                      String? geofenceName = geofenceMap[geofenceId] ?? "N/A";
                      return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                              padding: const EdgeInsets.only(
                                  left: 0, right: 0, bottom: 8, top: 0),
                              width: MediaQuery.of(context).size.width * 0.8,
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
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                    color: Colors
                                        .grey), // Adjust the value as needed
                                color: Colors.grey.shade400,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    height: 25,
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 1,
                                          blurRadius: 1,
                                          offset: const Offset(0,
                                              1), // changes position of shadow
                                        ),
                                      ],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ), // Adjust the value as needed
                                      color: Colors.black,
                                    ),
                                    child: Text(
                                      formattedEventTime ?? "N/A",
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 25,
                                    width: MediaQuery.of(context).size.width,
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          "Event time :  ",
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600),
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          formattedEventTime ?? "N/A",
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: MediaQuery.of(context).size.width,
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          "Notification :  ",
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600),
                                          textAlign: TextAlign.center,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              trip['type'],
                                              style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: Colors.black,
                                                  fontWeight:
                                                  FontWeight.w500),
                                              textAlign: TextAlign.center,
                                            ),
                                            // trip['type'] == "geofenceEnter" ?
                                            // Icon(Icons.location_pin, color: Colors.green.shade500)
                                            // :   trip['type'] == "geofenceExit" ?
                                            // Icon(Icons.location_pin, color: Colors.red.shade500)
                                            //     : trip['type'] == "deviceMoving" ?
                                            // Icon(Icons.nights_stay_outlined, color: Colors.yellow)
                                            //     : trip['type'] == "deviceOverspeed" ?
                                            // Icon(Icons.speed, color: Colors.orange)
                                            //     : trip['type'] == "ignitionOff" ?
                                            // Icon(Icons.power, color: Colors.red)
                                            //     : trip['type'] == "ignitionOn" ?
                                            // Icon(Icons.power, color: Colors.green)
                                            //
                                            //     : Icon(Icons.error, color: Colors.green.shade500)
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // SizedBox(
                                  //   height: 20,
                                  //   width: MediaQuery.of(context).size.width,
                                  //   child: Row(
                                  //     children: [
                                  //       const SizedBox(
                                  //         width: 5,
                                  //       ),
                                  //       Text(
                                  //         "Geofence :  ",
                                  //         style: GoogleFonts.poppins(
                                  //             fontSize: 12,
                                  //             color: Colors.black,
                                  //             fontWeight: FontWeight.w600),
                                  //         textAlign: TextAlign.center,
                                  //       ),
                                  //       Text(
                                  //         geofenceName,
                                  //         style: GoogleFonts.poppins(
                                  //             fontSize: 10,
                                  //             color: Colors.black,
                                  //             fontWeight: FontWeight.w500),
                                  //         textAlign: TextAlign.center,
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              )));
                    },
                  ),
                ),
              ]))
        ]));
  }
}

//idle report

class IdleReport extends StatefulWidget {
  final String carNumber;
  final int carID;

  const IdleReport({
    required this.carNumber,
    required this.carID,
  });

  @override
  State<IdleReport> createState() => IdleReportState();
}

class IdleReportState extends State<IdleReport> {
  final storage = const FlutterSecureStorage();
  bool isLoading = false;
  List<Map<String, dynamic>> carData = [];
  List<String> startAddress = [];
  List<String> end_Address = [];
  String totalDistance = '';
  String totalDuration = '';
  String totalIdle = '';
  String totalDrivingTime = "00:00:00";
  late DateTime? _fromDate;
  late DateTime? _toDate;
  String finishAddress = '';
  String beginAddress = '';
  bool _ignitionOn = false;
  bool _ignitionOff = false;
  bool _overSpeed = false;
  bool _idle = false;
  bool _acOn = false;

  @override
  void initState() {
    super.initState();
    // travelSummary();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();

    setState(() {
      isLoading = true;
    });
    _showDateTimePickerDialog();
  }

  // Method to show the custom dialog
  void _showCustomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Container(
            child: Text(
              'Select Options',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: Row(
                  children: [
                    const Icon(Icons.power, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      'Ignition On',
                      style: GoogleFonts.poppins(color: Colors.white),
                    )
                  ],
                ),
                value: _ignitionOn,
                onChanged: (value) {
                  setState(() {
                    _ignitionOn = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: Row(
                  children: [
                    const Icon(Icons.power, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                      'Ignition Off',
                      style: GoogleFonts.poppins(color: Colors.white),
                    )
                  ],
                ),
                value: _ignitionOff,
                onChanged: (value) {
                  setState(() {
                    _ignitionOff = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.orange),
                    const SizedBox(width: 10),
                    Text(
                      'Over Speed',
                      style: GoogleFonts.poppins(color: Colors.white),
                    )
                  ],
                ),
                value: _overSpeed,
                onChanged: (value) {
                  setState(() {
                    _overSpeed = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: Row(
                  children: [
                    const Icon(Icons.nights_stay_outlined,
                        color: Colors.yellow),
                    const SizedBox(width: 10),
                    Text(
                      'Moving',
                      style: GoogleFonts.poppins(color: Colors.white),
                    )
                  ],
                ),
                value: _idle,
                onChanged: (value) {
                  setState(() {
                    _idle = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDateTimePickerDialog() async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDateTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DateAndTimePickerDialog(
          title: 'From',
          initialDate: _fromDate,
          lastDate: currentDate,
          onDateTimeSelected: (dateTime) {
            setState(() {
              _fromDate = dateTime;
            });
            // travelSummary();
          },
        );
      },
    );

    if (selectedDateTime != null) {
      setState(() {
        _fromDate = selectedDateTime;
      });
    }
  }

  Future<void> getAddress(String sessionCookies, double start_latitude,
      double start_longitude) async {
    const addressApiUrl = 'http://103.174.103.78:8085/CRT/address.ajax.php';
    final addressUrl =
        '$addressApiUrl?lat=$start_latitude&lng=$start_longitude';

    try {
      final addressResponse = await http.get(
        Uri.parse(addressUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (addressResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        String address = addressData['addr'];
        // Add the address to the list
        setState(() {
          startAddress.add(address);
          beginAddress = address;
        });
      } else {}
    } catch (error) {}
  }

  Future<void> endAddress(
      String sessionCookies, double end_latitude, double end_longitude) async {
    const addressApiUrl = 'http://103.174.103.78:8085/CRT/address.ajax.php';
    final addressUrl = '$addressApiUrl?lat=$end_latitude&lng=$end_longitude';

    try {
      final addressResponse = await http.get(
        Uri.parse(addressUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (addressResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        String end_address = addressData['addr'];
        // Add the address to the list
        setState(() {
          end_Address.add(end_address);
          finishAddress = end_address;
        });
      } else {}
    } catch (error) {}
  }

  void _selectDate(String title, BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDateTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey, // Set the dialog background color here
          child: DateAndTimePickerDialog(
            title: title,
            initialDate: title == 'From' ? _fromDate : _toDate,
            lastDate: currentDate,
            onDateTimeSelected: (dateTime) {
              setState(() {
                if (title == 'From') {
                  _fromDate = dateTime;
                } else {
                  _toDate = dateTime;
                }
              });
            },
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dateTime.toLocal());
    } else {
      return ''; // You may want to handle this case based on your requirements
    }
  }

  String _formatDate(DateTime date) {
    // Format the DateTime object
    String formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blueGrey.shade900,
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: Colors.blueGrey.shade900,
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
              'Vehicle Name: ${widget.carNumber}',
              style: GoogleFonts.robotoSlab(fontSize: 16, color: Colors.white),
            ),
          ),
          actions: [
            GestureDetector(
                onTap: () {
                  _showCustomDialog();
                },
                child: const Icon(
                  Icons.filter_alt_outlined,
                  color: Colors.white,
                ))
          ],
        ),
        body: Column(children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _selectDate('From', context);
                        },
                        child: Column(
                          children: [
                            Text(
                              "From Date",
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 18),
                            ),
                            Text(
                              _formatDate(_fromDate!),
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 40,
                      ),
                      GestureDetector(
                        onTap: () {
                          _selectDate('To', context);
                        },
                        child: Column(
                          children: [
                            Text(
                              "To Date",
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 18),
                            ),
                            Text(
                              _formatDate(_toDate!),
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                isLoading
                    ? Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.white,
                      size: 50,
                    ))
                    : Expanded(
                  child: ListView.builder(
                    itemCount: 5, // Number of trips
                    itemBuilder: (context, index) {
                      // Replace these values with actual trip data
                      String totalDuration = '2H 30M';
                      double maxSpeed = 120.0;
                      double totalDistance = 150.0;
                      double averageSpeed = 60.0;
                      String startAddress = 'Start Address $index';
                      String finishAddress = 'Finish Address $index';

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                height: 30,
                                alignment: Alignment.center,
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 88.0),
                                      child: Text(
                                        "Trip ${index + 1}",
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 18),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "170 km",
                                        style: GoogleFonts.poppins(
                                            color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Total Duration: $totalDuration',
                                            style: GoogleFonts.poppins(
                                                color: Colors.blue)),
                                        Text('Max Speed: $maxSpeed km/h',
                                            style: GoogleFonts.poppins(
                                                color: Colors.indigo)),
                                      ],
                                    ),
                                    const SizedBox(
                                        width:
                                        20), // Add spacing between columns
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Total Distance: $totalDistance km',
                                            style: GoogleFonts.poppins(
                                                color: Colors.orange)),
                                        Text(
                                            'Average Speed: $averageSpeed km/h',
                                            style: GoogleFonts.poppins(
                                                color: Colors.green)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text('Start Address: $startAddress',
                                  style: GoogleFonts.poppins(
                                      color: Colors.green)),
                              Text('Finish Address: $finishAddress',
                                  style: GoogleFonts.poppins(
                                      color: Colors.red)),
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
        ]));
  }
}

// stop detailed report

class StopReport extends StatefulWidget {
  final String carNumber;
  final int carID;
  final String imagePath;

  const StopReport({
    required this.carNumber,
    required this.carID,
    required this.imagePath,
  });

  @override
  State<StopReport> createState() => StopReportState();
}

class StopReportState extends State<StopReport> {
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  List<Map<String, dynamic>> carData = [];
  List<String> startAddress = [];
  List<String> end_Address = [];
  String totalDistance = '';
  String totalDuration = '';
  String totalIdle = '';
  int totalStopTime = 0;
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late DateTime? originalFrom;
  late DateTime? originalTo;
  String finishAddress = '';
  String beginAddress = '';
  LatLng carLocation = const LatLng(0, 0);
  String carAddress = "";
  Map<int, String> carAddresses = {};
  double odometerValue = 0.0;
  double todayodometerValue = 0.0; // Declare it here
  List<LatLng> polylinePoints = [];
  double carSpeed = 0;
  double MaximumSpeed = 0.0;
  double AverageSpeed = 0.0;
  int totalEngineHour = 0;

  @override
  void initState() {
    super.initState();
    // travelSummary();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
    originalFrom = DateTime.now().subtract(const Duration(days: 7));
    originalTo = DateTime.now();
    fetchStopLog();
    Future.delayed(const Duration(milliseconds: 500), () {
      _showCustomDialog();
    });
  }

  // void _showCustomDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor:
  //             Colors.white, // Set the grey color for the entire dialog
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //         contentPadding: EdgeInsets.zero,
  //         insetPadding: EdgeInsets.zero,
  //         buttonPadding: EdgeInsets.zero,
  //         titlePadding: EdgeInsets.zero,
  //         title: Container(
  //           decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(5.0),
  //               color: Colors.white,
  //               border: Border.all(color: Colors.grey.shade400)),
  //           height: MediaQuery.of(context).size.height * 0.3,
  //           width: MediaQuery.of(context).size.width * 0.7,
  //           child: Padding(
  //             padding: const EdgeInsets.only(left: 1, right: 1, top: 1),
  //             child: Column(
  //               children: [
  //                 Container(
  //                   alignment: Alignment.center,
  //                   height: 40,
  //                   width: MediaQuery.of(context).size.width,
  //                   color: Colors.black,
  //                   child: Text(
  //                     widget.carNumber,
  //                     style: GoogleFonts.robotoSlab(
  //                         color: Colors.white,
  //                         fontSize: 17,
  //                         fontWeight: FontWeight.w500),
  //                   ),
  //                 ),
  //                 const SizedBox(
  //                   height: 15,
  //                 ),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       "From date",
  //                       style: GoogleFonts.poppins(
  //                           color: Colors.black,
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(
  //                       height: 5,
  //                     ),
  //                     GestureDetector(
  //                       onTap: () {
  //                         _selectDate('From', context);
  //                       },
  //                       child: Container(
  //                         decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(5.0),
  //                             color: Colors.white,
  //                             border: Border.all(color: Colors.grey.shade400)),
  //                         height: 40,
  //                         width: MediaQuery.of(context).size.width * 0.45,
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(4.0),
  //                           child: Row(
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               Text(
  //                                 _formatDate(originalFrom!),
  //                                 style: GoogleFonts.poppins(
  //                                     color: Colors.black, fontSize: 12),
  //                               ),
  //                               SizedBox(
  //                                 height: 20,
  //                                 width: 20,
  //                                 child: Image.asset("assets/cal.png"),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     )
  //                   ],
  //                 ),
  //                 const SizedBox(
  //                   height: 10,
  //                 ),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       "To date",
  //                       style: GoogleFonts.poppins(
  //                           color: Colors.black,
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.w400),
  //                     ),
  //                     const SizedBox(
  //                       height: 5,
  //                     ),
  //                     GestureDetector(
  //                       onTap: () {
  //                         _selectDate('To', context);
  //                       },
  //                       child: Container(
  //                         decoration: BoxDecoration(
  //                             borderRadius: BorderRadius.circular(5.0),
  //                             color: Colors.white,
  //                             border: Border.all(color: Colors.grey.shade400)),
  //                         height: 40,
  //                         width: MediaQuery.of(context).size.width * 0.45,
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(4.0),
  //                           child: Row(
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               Text(
  //                                 _formatDate(originalTo!),
  //                                 style: GoogleFonts.poppins(
  //                                     color: Colors.black, fontSize: 12),
  //                               ),
  //                               SizedBox(
  //                                 height: 20,
  //                                 width: 20,
  //                                 child: Image.asset("assets/cal.png"),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     )
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                // height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.7,
                child: Padding(
                  padding: const EdgeInsets.only(left: 1, right: 1, top: 1),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 40,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.black,
                        child: Text(
                          widget.carNumber,
                          style: GoogleFonts.robotoSlab(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "From date",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectDate('From', context);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              height: 40,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(originalFrom!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Image.asset("assets/cal.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "To date",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectDate('To', context);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              height: 40,
                              width: MediaQuery.of(context).size.width * 0.45,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(originalTo!),
                                      style: GoogleFonts.poppins(
                                          color: Colors.black, fontSize: 12),
                                    ),
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Image.asset("assets/cal.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
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
                            onPressed: () {
                              fetchStopLog();
                              Navigator.of(context).pop();
                            },
                            child: Text('Submit',
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
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> fetchStopLog() async {
    final String stopApi = dotenv.env['STOP_API']!;
    final String carDetailsApiUrl =
        "$stopApi?deviceId=${widget.carID}&from=${_formatDateTime(_fromDate)}Z&to=${_formatDateTime(_toDate)}Z";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(carDetailsApiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        final List<dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          int runningTime = 0;
          int engineperiod = 0;
          double MaxSpeed = 0.0;
          double averageSpeed = 0.0;
          for (final carItem in jsonResponse) {
            final int engineDuration =
            carItem['engineHours']; // Get the distance from each trip
            engineperiod += engineDuration; // Sum up the distances
            final String startTimeStr = carItem['startTime'];
            final String endTimeStr = carItem['endTime'];
            final DateTime startTime = DateTime.parse(startTimeStr);
            final DateTime endTime = DateTime.parse(endTimeStr);
            final int durationInHours = carItem['duration'];
            runningTime += durationInHours;
            final double maxSpeed = carItem['maxSpeed'];
            MaxSpeed += maxSpeed;
            final double avgspeed = carItem['averageSpeed'];
            averageSpeed += avgspeed;
          }

          setState(() {
            totalEngineHour = engineperiod;
            totalStopTime = runningTime;
            MaximumSpeed = MaxSpeed.roundToDouble();
            AverageSpeed = averageSpeed.roundToDouble();
          });
        }
      }
    } else {}
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return "${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}";
      }
    } catch (e) {}
    return "Address not found";
  }

  Future<void> endAddress(
      String sessionCookies, double end_latitude, double end_longitude) async {
    const addressApiUrl = 'http://103.174.103.78:8085/CRT/address.ajax.php';
    final addressUrl = '$addressApiUrl?lat=$end_latitude&lng=$end_longitude';

    try {
      final addressResponse = await http.get(
        Uri.parse(addressUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (addressResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        String end_address = addressData['addr'];
        // Add the address to the list
        setState(() {
          end_Address.add(end_address);
          finishAddress = end_address;
        });
      } else {}
    } catch (error) {}
  }

  void _selectDate(String title, BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDateTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DateAndTimePickerDialog(
          title: title,
          initialDate: title == 'From' ? _fromDate : _toDate,
          lastDate: currentDate,
          onDateTimeSelected: (dateTime) async {
            // Store the original selected date and time
            DateTime originalDateTime = dateTime;

            // Convert the selected dateTime to UTC
            DateTime utcDateTime = dateTime.toUtc();
            // Adjust the time zone difference, assuming it's IST (-5:30)
            utcDateTime =
                utcDateTime.subtract(const Duration(hours: 5, minutes: 30));

            // Format the UTC datetime to include 'T' and 'Z'
            String formattedDateTime =
            DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(utcDateTime);

            setState(() {
              if (title == 'From') {
                _fromDate = utcDateTime;
                originalFrom =
                    originalDateTime; // Store the original selected from date and time
              } else {
                _toDate = utcDateTime;
                originalTo =
                    originalDateTime; // Store the original selected to date and time
              }
            });
            fetchStopLog();
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime.toLocal());
    } else {
      return ''; // You may want to handle this case based on your requirements
    }
  }

  String _formatDate(DateTime date) {
    // Format the DateTime object
    String formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
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
                "${widget.carNumber}  Report",
                style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        body: Column(children: [
          // Header with vehicle name and odometer

          // List of cards with key-value pairs
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "From date",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            _selectDate('From', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.grey.shade400,
                                border:
                                Border.all(color: Colors.grey.shade200)),
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(_fromDate!),
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 12),
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset("assets/cal.png"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "To date",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            _selectDate('To', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: Colors.grey.shade400,
                                border:
                                Border.all(color: Colors.grey.shade200)),
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(_toDate!),
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 12),
                                  ),
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset("assets/cal.png"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              isLoading
                  ? Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.white,
                    size: 50,
                  ))
                  : GestureDetector(
                onTap: () {
                  _showSlider(context);
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                            padding: const EdgeInsets.only(
                                left: 2, right: 2, bottom: 8, top: 2),
                            width:
                            MediaQuery.of(context).size.width * 0.94,
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
                              color: Colors.grey.shade400,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  height:
                                  MediaQuery.of(context).size.height *
                                      0.08,
                                  width:
                                  MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                        Colors.grey.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 1,
                                        offset: const Offset(0,
                                            1), // changes position of shadow
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(
                                        5.0), // Adjust the value as needed
                                    color: Colors.black,
                                  ),
                                  child: Text(
                                    widget.carNumber,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Row(
                                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.asset(
                                        widget.imagePath,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      children: [
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        SizedBox(
                                          height: 20,
                                          width: MediaQuery.of(context)
                                              .size
                                              .width *
                                              0.6,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.timer_sharp,
                                                color: Colors
                                                    .yellow.shade900,
                                                size: 14,
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                "Duration :  ",
                                                style:
                                                GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color:
                                                    Colors.black,
                                                    fontWeight:
                                                    FontWeight
                                                        .w500),
                                                textAlign:
                                                TextAlign.center,
                                              ),
                                              Text(
                                                "${(totalStopTime / 3600000).toStringAsFixed(2)} Hrs",
                                                style:
                                                GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color:
                                                    Colors.black,
                                                    fontWeight:
                                                    FontWeight
                                                        .w500),
                                                textAlign:
                                                TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          height: 20,
                                          width: MediaQuery.of(context)
                                              .size
                                              .width *
                                              0.6,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.speed,
                                                color: Colors
                                                    .yellow.shade900,
                                                size: 14,
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                "Maximum Speed :  ",
                                                style:
                                                GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color:
                                                    Colors.black,
                                                    fontWeight:
                                                    FontWeight
                                                        .w500),
                                                textAlign:
                                                TextAlign.center,
                                              ),
                                              Text(
                                                "$MaximumSpeed Km/Hr",
                                                style:
                                                GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color:
                                                    Colors.black,
                                                    fontWeight:
                                                    FontWeight
                                                        .w500),
                                                textAlign:
                                                TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          height: 20,
                                          width: MediaQuery.of(context)
                                              .size
                                              .width *
                                              0.6,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.speed,
                                                color: Colors
                                                    .yellow.shade900,
                                                size: 14,
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                "Engine :  ",
                                                style:
                                                GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color:
                                                    Colors.black,
                                                    fontWeight:
                                                    FontWeight
                                                        .w500),
                                                textAlign:
                                                TextAlign.center,
                                              ),
                                              Text(
                                                "${(totalEngineHour / 3600000).toStringAsFixed(2)} Hrs",
                                                style:
                                                GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color:
                                                    Colors.black,
                                                    fontWeight:
                                                    FontWeight
                                                        .w500),
                                                textAlign:
                                                TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          height: 20,
                                          width: MediaQuery.of(context)
                                              .size
                                              .width *
                                              0.6,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.speed,
                                                color: Colors
                                                    .yellow.shade900,
                                                size: 14,
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ),
                                              Text(
                                                "Average Speed :  ",
                                                style:
                                                GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    color:
                                                    Colors.black,
                                                    fontWeight:
                                                    FontWeight
                                                        .w500),
                                                textAlign:
                                                TextAlign.center,
                                              ),
                                              Text(
                                                "$AverageSpeed Km/Hr",
                                                style:
                                                GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color:
                                                    Colors.black,
                                                    fontWeight:
                                                    FontWeight
                                                        .w500),
                                                textAlign:
                                                TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ]));
  }

  void _showSlider(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StopLogs(
                      carID: widget.carID,
                      fromDate: _formatDateTime(_fromDate),
                      toDate: _formatDateTime(_toDate),
                    )));
          },
          child: Container(
            height: MediaQuery.of(context).size.height *
                0.15, // Adjust the height as needed
            width: MediaQuery.of(context).size.width * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Add your slider widget here
                const SizedBox(height: 10),
                Column(
                  children: [
                    Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade200),
                        child: const Icon(
                          Icons.route,
                          size: 28,
                          color: Colors.blue,
                        )),
                    const Text(
                      'Stop Report',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Add your slider widget here
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildKeyValueRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$key:',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String subtitle, IconData icon) {
    return Card(
      color: Colors.blueGrey.shade900,
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.grey),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class StopLogs extends StatefulWidget {
  final int carID;
  final String fromDate;
  final String toDate;

  const StopLogs(
      {super.key,
        required this.fromDate,
        required this.toDate,
        required this.carID});

  @override
  _StopLogsState createState() => _StopLogsState();
}

class _StopLogsState extends State<StopLogs> {
  List<Map<String, dynamic>> tripData = []; // Store trip data here
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchTripLog(); // Fetch trip data when the widget is initialized
  }

  String startAddress = "";
  Future<void> fetchTripLog() async {
    final String stopApi = dotenv.env['STOP_API']!;

    DateTime fromDateTime = DateTime.parse(widget.fromDate);
    DateTime toDateTime = DateTime.parse(widget.toDate);
    fromDateTime = fromDateTime.subtract(const Duration(hours: 5, minutes: 30));
    toDateTime = toDateTime.subtract(const Duration(hours: 5, minutes: 30));
    String fromAdjusted =
        DateFormat("yyyy-MM-ddTHH:mm:ss").format(fromDateTime) + 'Z';
    String toAdjusted =
        DateFormat("yyyy-MM-ddTHH:mm:ss").format(toDateTime) + 'Z';

    final apiUrl =
        '$stopApi?deviceId=${widget.carID}&from=$fromAdjusted&to=$toAdjusted';

    // final apiUrl = '$stopApi?deviceId=${widget.carID}&from=${widget.fromDate}Z&to=${widget.toDate}Z';
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Cookie': sessionCookies, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> rawTripData =
        List<Map<String, dynamic>>.from(json.decode(response.body));
        List<Map<String, dynamic>> updatedTripData = [];

        for (var trip in rawTripData) {
          final double lat = double.parse(trip['latitude'].toString());
          final double lon = double.parse(trip['longitude'].toString());

          final address = await _getAddressFromCoordinates(lat, lon);

          updatedTripData.add({
            ...trip,
            'address': address,
          });
        }
        tripData = updatedTripData;
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load trips');
      }
    }
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    final List<Placemark> placemarks =
    await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      final Placemark placemark = placemarks[0];
      return "${placemark.name ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}";
    }
    return 'Unknown address';
  }

  String addressNew = "";
  Future<void> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      // Perform reverse geocoding
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latitude, longitude);
      Placemark placemark = placemarks[0];
      addressNew =
      "${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
    } catch (e) {}
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

  Future<void> _generateTravellSummaryPdf(BuildContext context) async {
    final pdf = pw.Document();
    if (tripData == null || tripData.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Text(
              'No Data Here',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      );
    } else {
      const int itemsPerPage = 20;
      int itemCount = tripData.length;
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      for (int page = 0; page * itemsPerPage < itemCount; page++) {
        pdf.addPage(
          pw.Page(
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                // Display headers
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey,
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text(
                        'Trip Summary',
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Date',
                        style: pw.TextStyle(
                            fontSize: 25, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),

                // Display the Trip Details as a list
                for (var i = page * itemsPerPage;
                i < (page + 1) * itemsPerPage && i < itemCount;
                i++)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Container(
                      padding: const pw.EdgeInsets.only(
                          left: 20, right: 20, bottom: 10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8.0),
                        border: pw.Border.all(color: PdfColors.grey),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.black,
                              borderRadius: pw.BorderRadius.circular(7.0),
                            ),
                            child: pw.Row(
                              mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'From:',
                                      style: const pw.TextStyle(
                                          fontSize: 14, color: PdfColors.white),
                                    ),
                                    pw.Text(
                                      dateFormat.format(DateTime.parse(
                                          tripData[i]['startTime'] ??
                                              '0000-00-00T00:00:00Z')),
                                      style: pw.TextStyle(
                                          fontSize: 14,
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold),
                                    ),
                                  ],
                                ),
                                pw.Column(
                                  crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'To:',
                                      style: const pw.TextStyle(
                                          fontSize: 14, color: PdfColors.white),
                                    ),
                                    pw.Text(
                                      dateFormat.format(DateTime.parse(
                                          tripData[i]['endTime'] ??
                                              '0000-00-00T00:00:00Z')),
                                      style: pw.TextStyle(
                                          fontSize: 14,
                                          color: PdfColors.white,
                                          fontWeight: pw.FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Total Duration',
                                      style: pw.TextStyle(
                                          fontSize: 13,
                                          fontWeight: pw.FontWeight.normal)),
                                  pw.Text(
                                      "${((tripData[i]['duration'] ?? 0) / 6000000).toStringAsFixed(2)} hr",
                                      // '${tripData[i]['duration'] ?? 'N/A'}ms',
                                      style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold)),
                                ],
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Total Distance',
                                      style: const pw.TextStyle(fontSize: 13)),
                                  pw.Text(
                                      '${((tripData[i]['distance'] ?? 0) / 1000).toStringAsFixed(2)} km',
                                      style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Avg. Speed',
                                      style: const pw.TextStyle(fontSize: 13)),
                                  pw.Text(
                                    '${tripData[i]['averageSpeed']?.toStringAsFixed(2) ?? 'N/A'} Kmph',
                                    style: pw.TextStyle(
                                        fontSize: 14,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Max. Speed',
                                      style: const pw.TextStyle(fontSize: 13)),
                                  pw.Text(
                                    ' ${tripData[i]['maxSpeed']?.toStringAsFixed(2) ?? 'N/A'} Kmph',
                                    style: pw.TextStyle(
                                        fontSize: 14,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            children: [
                              pw.Container(
                                height: 10,
                                width: 10,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.green,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                addressNew,
                                style: const pw.TextStyle(fontSize: 14),
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
        );
      }
    }

    // Save the PDF to a file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/TravelSummary.pdf');
    await file.writeAsBytes(await pdf.save());

    // Navigate to the PDF viewer screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravellSummaryPDFViewerScreen(file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            'Stop Logs',
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
              ),
              // onPressed: () => _generateInvoicePdf(context),
              onPressed: () async {
                // await _fetchStatusLogAndUpdateQuery();
                fetchTripLog();
                _generateTravellSummaryPdf(
                    context); // Generate PDF with fetched data
              },
            ),
          ],
          leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.white,
              )),
        ),
        body: isLoading
        // tripData.isEmpty
            ? Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.white,
              size: 50,
            ))
            : tripData.isNotEmpty
            ? ListView.builder(
          itemCount: tripData.length,
          itemBuilder: (context, index) {
            // Extract trip data
            final trip = tripData[index];
            final startTimeStr = trip['startTime'];
            DateTime parsedStartTime = DateTime.parse(startTimeStr);
            parsedStartTime = parsedStartTime
                .add(const Duration(hours: 11, minutes: 00));
            final formattedStartTime =
            DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(parsedStartTime);
            final displayStartTime = formattedStartTime ?? "N/A";

            final endTimeStr = trip['endTime'];
            DateTime parsedEndTime = DateTime.parse(endTimeStr);
            parsedEndTime = parsedEndTime
                .add(const Duration(hours: 11, minutes: 00));
            final formattedEndTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                .format(parsedEndTime);
            final displayEndTime = formattedEndTime ?? "N/A";
            final DateTime startTime = DateTime.parse(startTimeStr);
            final DateTime endTime = DateTime.parse(endTimeStr);
            final double duration = trip['duration'] / 3600000;

            // Replace with actual calculation based on trip data
            final maxSpeed = trip['maxSpeed'].roundToDouble();
            final startOdometer =
                trip['startOdometer'] / 1000.roundToDouble();
            final endOdometer =
                trip['endOdometer'] / 1000.roundToDouble();
            final totalDistance =
            (endOdometer - startOdometer).toStringAsFixed(2);
            final averageSpeed = trip['averageSpeed'].roundToDouble();
            // final startAddress = trip['address'] ?? "";
            final lat = trip['latitude'];
            final long = trip['longitude'];
            getAddressFromLatLng(lat, long);
            return GestureDetector(
                onTap: () {
                  openGoogleMaps(trip['latitude'], trip['longitude']);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 5, right: 5, bottom: 8, top: 2),
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
                      color: Colors.grey.shade400,
                    ),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          height: MediaQuery.of(context).size.height *
                              0.08,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 1,
                                offset: const Offset(0,
                                    1), // changes position of shadow
                              ),
                            ],
                            borderRadius: BorderRadius.circular(
                                5.0), // Adjust the value as needed
                            color: Colors.black,
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment:
                            CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "From :",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  Text(
                                    displayStartTime,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white,
                              ),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "To :",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  Text(
                                    displayEndTime,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 5),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_sharp,
                                        color: Colors.red.shade800,
                                        size: 25,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Duration",
                                            style:
                                            GoogleFonts.poppins(
                                                color:
                                                Colors.black,
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          Text(
                                            "${duration.toStringAsFixed(2)}hrs ",
                                            style:
                                            GoogleFonts.poppins(
                                                color:
                                                Colors.black,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.social_distance,
                                        color: Colors.red.shade800,
                                        size: 25,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Distance",
                                            style:
                                            GoogleFonts.poppins(
                                                color:
                                                Colors.black,
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          Text(
                                            "$totalDistance Km",
                                            style:
                                            GoogleFonts.poppins(
                                                color:
                                                Colors.black,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed_rounded,
                                        color: Colors.red.shade800,
                                        size: 25,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Max. Speed",
                                            style:
                                            GoogleFonts.poppins(
                                                color:
                                                Colors.black,
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          Text(
                                            "$maxSpeed km/h",
                                            style:
                                            GoogleFonts.poppins(
                                                color:
                                                Colors.black,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed_rounded,
                                        color: Colors.red.shade800,
                                        size: 25,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                        MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Average Speed",
                                            style:
                                            GoogleFonts.poppins(
                                                color:
                                                Colors.black,
                                                fontSize: 11,
                                                fontWeight:
                                                FontWeight
                                                    .w400),
                                          ),
                                          Text(
                                            "$averageSpeed km/h",
                                            style:
                                            GoogleFonts.poppins(
                                                color:
                                                Colors.black,
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight
                                                    .w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 13,
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Image.asset(
                                        "assets/start.png"),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Expanded(
                                    child: Text(
                                      trip['address'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ));
          },
        )
            : const Center(
            child: Text(
              "No Stop Logs Found",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            )));
  }
}

//vehicle Analysis

class VehicleAnalysis extends StatefulWidget {
  final String carNumber;
  final int carID;

  const VehicleAnalysis({
    required this.carNumber,
    required this.carID,
  });

  @override
  State<VehicleAnalysis> createState() => VehicleAnalysisState();
}

class VehicleAnalysisState extends State<VehicleAnalysis> {
  final storage = const FlutterSecureStorage();
  bool isLoading = false;
  List<Map<String, dynamic>> carData = [];
  List<String> startAddress = [];
  List<String> end_Address = [];
  String totalDistance = '';
  String totalDuration = '';
  String totalIdle = '';
  String totalDrivingTime = "00:00:00";
  late DateTime? _fromDate;
  late DateTime? _toDate;
  String finishAddress = '';
  String beginAddress = '';
  bool _ignitionOn = false;
  bool _ignitionOff = false;
  bool _overSpeed = false;
  bool _idle = false;
  bool _acOn = false;

  @override
  void initState() {
    super.initState();
    // travelSummary();
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();

    setState(() {
      isLoading = true;
    });
    _showDateTimePickerDialog();
  }

  // Method to show the custom dialog
  void _showCustomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey.shade900,
          title: Text(
            'Select Options',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: Row(
                  children: [
                    const Icon(Icons.power, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      'Ignition On',
                      style: GoogleFonts.poppins(color: Colors.white),
                    )
                  ],
                ),
                value: _ignitionOn,
                onChanged: (value) {
                  setState(() {
                    _ignitionOn = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: Row(
                  children: [
                    const Icon(Icons.power, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                      'Ignition Off',
                      style: GoogleFonts.poppins(color: Colors.white),
                    )
                  ],
                ),
                value: _ignitionOff,
                onChanged: (value) {
                  setState(() {
                    _ignitionOff = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.orange),
                    const SizedBox(width: 10),
                    Text(
                      'Over Speed',
                      style: GoogleFonts.poppins(color: Colors.white),
                    )
                  ],
                ),
                value: _overSpeed,
                onChanged: (value) {
                  setState(() {
                    _overSpeed = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: Row(
                  children: [
                    const Icon(Icons.nights_stay_outlined,
                        color: Colors.yellow),
                    const SizedBox(width: 10),
                    Text(
                      'Idle',
                      style: GoogleFonts.poppins(color: Colors.white),
                    )
                  ],
                ),
                value: _idle,
                onChanged: (value) {
                  setState(() {
                    _idle = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDateTimePickerDialog() async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDateTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DateAndTimePickerDialog(
          title: 'From',
          initialDate: _fromDate,
          lastDate: currentDate,
          onDateTimeSelected: (dateTime) {
            setState(() {
              _fromDate = dateTime;
            });
            // travelSummary();
          },
        );
      },
    );

    if (selectedDateTime != null) {
      setState(() {
        _fromDate = selectedDateTime;
      });
    }
  }

  Future<void> getAddress(String sessionCookies, double start_latitude,
      double start_longitude) async {
    const addressApiUrl = 'http://103.174.103.78:8085/CRT/address.ajax.php';
    final addressUrl =
        '$addressApiUrl?lat=$start_latitude&lng=$start_longitude';

    try {
      final addressResponse = await http.get(
        Uri.parse(addressUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (addressResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        String address = addressData['addr'];
        // Add the address to the list
        setState(() {
          startAddress.add(address);
          beginAddress = address;
        });
      } else {}
    } catch (error) {}
  }

  Future<void> endAddress(
      String sessionCookies, double end_latitude, double end_longitude) async {
    const addressApiUrl = 'http://103.174.103.78:8085/CRT/address.ajax.php';
    final addressUrl = '$addressApiUrl?lat=$end_latitude&lng=$end_longitude';

    try {
      final addressResponse = await http.get(
        Uri.parse(addressUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (addressResponse.statusCode == 200) {
        final addressData = json.decode(addressResponse.body);
        String end_address = addressData['addr'];
        // Add the address to the list
        setState(() {
          end_Address.add(end_address);
          finishAddress = end_address;
        });
      } else {}
    } catch (error) {}
  }

  void _selectDate(String title, BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDateTime = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return DateAndTimePickerDialog(
          title: title,
          lastDate: currentDate,
          initialDate: title == 'From' ? _fromDate : _toDate,
          onDateTimeSelected: (dateTime) {
            // Call travelSummary function with the selected date and time
            setState(() {
              if (title == 'From') {
                _fromDate = dateTime;
              } else {
                _toDate = dateTime;
              }
            });
            // travelSummary();
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime != null) {
      return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dateTime.toLocal());
    } else {
      return ''; // You may want to handle this case based on your requirements
    }
  }

  String _formatDate(DateTime date) {
    // Format the DateTime object
    String formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: Colors.blueGrey.shade900,
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
              // 'Vehicle Name: ${widget.carNumber}',
              widget.carNumber,
              style: GoogleFonts.robotoSlab(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
          ),
          actions: [
            GestureDetector(
                onTap: () {
                  _showCustomDialog();
                },
                child: const Icon(
                  Icons.filter_alt_outlined,
                  color: Colors.white,
                ))
          ],
        ),
        body: Center(
          child: Text(
            "Coming Soon ...",
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ));
  }
}

//vehicle maintenance

class VehicleMaintenance extends StatefulWidget {
  final String carNumber;
  final int carID;

  const VehicleMaintenance({
    required this.carNumber,
    required this.carID,
  });

  @override
  State<VehicleMaintenance> createState() => VehicleMaintenanceState();
}

class VehicleMaintenanceState extends State<VehicleMaintenance> {
  double _totalExpenses = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
                      color: Colors.grey.shade700.withOpacity(0.5), // Border color
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
              widget.carNumber,
              style: GoogleFonts.robotoSlab(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      //   AppBar(
      //   title: const Text('Vehicle Maintenance'),
      // ),
      body: Center(
          child: Text(
            "Coming Soon ...",
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          )),
    );
  }
}

class MaintenanceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  MaintenanceCard(
      {super.key,
        required this.title,
        required this.icon,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
//Vehicle INvoice

class VehicleInvoice extends StatefulWidget {
  final String carNumber;
  final int carID;

  const VehicleInvoice({
    super.key,
    required this.carNumber,
    required this.carID,
  });

  @override
  State<VehicleInvoice> createState() => VehicleInvoiceState();
}

class VehicleInvoiceState extends State<VehicleInvoice> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerAddressController =
  TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController =
  TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _hsnController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  double _subtotal = 0;
  double _totalwithdiscount = 0;
  int invoice_no = 1000;

  void _calculateSubtotal() {
    setState(() {
      int quantity = int.tryParse(_quantityController.text) ?? 0;
      double gstPercent = double.tryParse(_gstController.text) ?? 0;
      double unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
      double discount = double.tryParse(_discountController.text) ?? 0;
      _subtotal = (unitPrice + (unitPrice * gstPercent / 100)) * quantity;
      _totalwithdiscount = _subtotal - (_subtotal * discount / 100);
    });
  }

  Future<void> _generateInvoicePdf(BuildContext context) async {
    invoice_no++;
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Column(children: <pw.Widget>[
                    pw.Text(
                      'From:',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(_customerNameController.text),
                    pw.Text(_customerAddressController.text),
                  ]),
                  pw.Text("Invoice ", style: const pw.TextStyle(fontSize: 20)),
                ]),
            pw.SizedBox(height: 20),
            pw.Divider(
              thickness: 5,
            ),
            pw.SizedBox(height: 20),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: <pw.Widget>[
                  pw.Column(children: <pw.Widget>[
                    pw.Text(
                      'To:',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(_companyNameController.text),
                    pw.Text(_companyAddressController.text),
                  ]),
                  pw.Column(children: <pw.Widget>[
                    pw.Text(
                      'Invoice No: $invoice_no',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Date : ${_formatDate(_selectedDate)}'),
                  ]),
                ]),
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(width: 1, color: PdfColors.black),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                color: PdfColors.grey200,
              ),
              cellHeight: 30,
              headerHeight: 40,
              cellPadding: const pw.EdgeInsets.all(5),
              headerStyle:
              pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 14),
              headers: [
                'Item Name',
                'Quantity',
                'Unit Price',
                'HSN Code',
                'GST'
              ],
              data: [
                [
                  _itemNameController.text,
                  _quantityController.text,
                  _unitPriceController.text,
                  _hsnController.text,
                  _gstController.text
                ],
              ],
            ),
            pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(
                        "Amount:${_subtotal}0",
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "Discount:${_discountController.text} %",
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "Total Amount:${_totalwithdiscount}0",
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                    ])),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice.pdf');
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(file.path),
      ),
    );
  }

  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  String _formatDate(DateTime date) {
    // Format the DateTime object
    String formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      color: Colors.grey.shade700.withOpacity(0.5), // Border color
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
              "Invoice",
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500),
            ),
            //   actions: [
            //     IconButton(
            //       icon: const Icon(Icons.picture_as_pdf),
            //       onPressed: () => _generateInvoicePdf(context),
            //     ),
            //   ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white,
            ),
            onPressed: () => _generateInvoicePdf(context),
          ),
        ],
      ),
      // AppBar(
      //   title: const Text('Invoice Form'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.picture_as_pdf),
      //       onPressed: () => _generateInvoicePdf(context),
      //     ),
      //   ],
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'From:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            // Container(
            //   height: 100,
            //   width: MediaQuery.of(context).size.width,
            //   decoration: BoxDecoration(
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.grey.withOpacity(0.5),
            //         spreadRadius: 1,
            //         blurRadius: 1,
            //         offset: const Offset(
            //             0, 1), // changes position of shadow
            //       ),
            //     ],
            //     borderRadius: BorderRadius.circular(
            //         5.0), // Adjust the value as needed
            //     color: Colors.white,
            //   ),
            //   child:const SizedBox(
            //     height: 40.0, // Adjust the height as needed
            //     width: 150.0, // Adjust the width as needed
            //     child: TextField(
            //       // controller: _controller,
            //       decoration: InputDecoration(
            //         labelText: 'Label Text',
            //         hintText: 'Hint Text',
            //         border: OutlineInputBorder(
            //           borderSide: BorderSide(color: Colors.grey),
            //         ),
            //         focusedBorder: OutlineInputBorder(
            //           borderSide: BorderSide(color: Colors.grey),
            //         ),
            //         enabledBorder: OutlineInputBorder(
            //           borderSide: BorderSide(color: Colors.grey),
            //         ),
            //         contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0), // Adjust the padding to change the height
            //       ),
            //     ),
            //   ),
            // ),

            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            TextField(
              controller: _customerAddressController,
              decoration: const InputDecoration(labelText: 'Customer Address'),
            ),
            const SizedBox(height: 20),
            const Text(
              'To:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
            ),
            TextField(
              controller: _companyAddressController,
              decoration: const InputDecoration(labelText: 'Company Address'),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Details:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
              ],
            ),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: InputDecoration(
                labelText: 'Date',
                hintText: _formatDate(_selectedDate),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateSubtotal(),
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: _gstController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateSubtotal(),
              decoration: const InputDecoration(labelText: 'Gst'),
            ),
            TextField(
              controller: _hsnController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateSubtotal(),
              decoration: const InputDecoration(labelText: 'HSN Code'),
            ),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateSubtotal(),
              decoration: const InputDecoration(labelText: 'Discount'),
            ),
            TextField(
              controller: _unitPriceController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calculateSubtotal(),
              decoration: const InputDecoration(labelText: 'Unit Price'),
            ),
            const SizedBox(height: 20),
            Text(
              'Subtotal: ₹ $_subtotal',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String path;

  const PDFViewerScreen(this.path, {super.key});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            // onPressed: () => _sharePdf(context),
            onPressed: () {
              try {
                Share.shareFiles([widget.path]);
              } catch (e) {}
            },
          ),
        ],
      ),
      body: Center(
        child: PDFViewer(path: widget.path),
      ),
    );
  }

  void _sharePdf(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    Share.shareFiles([widget.path],
        text: 'Share Invoice PDF',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }
}

class PDFViewer extends StatelessWidget {
  final String path;

  PDFViewer({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PDFView(
        filePath: path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        onRender: (_pages) {},
        onError: (error) {},
        onPageError: (page, error) {},
        onViewCreated: (PDFViewController pdfViewController) {},
      ),
    );
  }
}

//Status PDF //------------------------------------------------------
class StatusPDFViewerScreen extends StatefulWidget {
  final String path;

  const StatusPDFViewerScreen(this.path, {super.key});

  @override
  State<StatusPDFViewerScreen> createState() => _StatusPDFViewerScreenState();
}

class _StatusPDFViewerScreenState extends State<StatusPDFViewerScreen> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            // onPressed: () => _sharePdf(context),
            onPressed: () {
              try {
                Share.shareFiles([widget.path]);
              } catch (e) {}
            },
          ),
        ],
      ),
      body: Center(
        child: StatusPDFViewer(statusPath: widget.path),
      ),
    );
  }

  void _sharePdf(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    Share.shareFiles([widget.path],
        text: 'Share Invoice PDF',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }
}

class StatusPDFViewer extends StatelessWidget {
  final String statusPath;

  StatusPDFViewer({super.key, required this.statusPath});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PDFView(
        filePath: statusPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        onRender: (_pages) {},
        onError: (error) {},
        onPageError: (page, error) {},
        onViewCreated: (PDFViewController pdfViewController) {},
      ),
    );
  }
}

//TravellSummary PDF ///--------------------
class TravellSummaryPDFViewerScreen extends StatefulWidget {
  final String path;

  const TravellSummaryPDFViewerScreen(this.path, {super.key});

  @override
  State<TravellSummaryPDFViewerScreen> createState() =>
      _TravellSummaryPDFViewerScreenState();
}

class _TravellSummaryPDFViewerScreenState
    extends State<TravellSummaryPDFViewerScreen> {
  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            // onPressed: () => _sharePdf(context),
            onPressed: () {
              try {
                Share.shareFiles([widget.path]);
              } catch (e) {}
            },
          ),
        ],
      ),
      body: Center(
        child: TravellSummaryPDFViewer(statusPath: widget.path),
      ),
    );
  }

  void _sharePdf(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    Share.shareFiles([widget.path],
        text: 'Share Invoice PDF',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
  }
}

class TravellSummaryPDFViewer extends StatelessWidget {
  final String statusPath;

  TravellSummaryPDFViewer({super.key, required this.statusPath});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PDFView(
        filePath: statusPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        onRender: (_pages) {},
        onError: (error) {},
        onPageError: (page, error) {},
        onViewCreated: (PDFViewController pdfViewController) {},
      ),
    );
  }
}
