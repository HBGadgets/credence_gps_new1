import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../status_report.dart';

class AddSavedCommandPage extends StatefulWidget {
  const AddSavedCommandPage({super.key});

  @override
  State<AddSavedCommandPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<AddSavedCommandPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String? selectedValue;
  bool _checkbox = false;

  List<String> timezoneItems = [];
  String? selectedTimeZoneValue;
  late DateTime? _fromDate;
  late DateTime? _toDate;
  DateTime? originalFrom;
  late DateTime? originalTo;
  List<String> _list = [];
  bool? _isFootBallText = false;
  bool? _isCricketText = false;
  bool? _isVolleyBallText = false;
  bool? _isKabaddiText = false;
  bool? _isBaskeballText = false;
  bool? _isBasketBallText = false;
  bool? _isOtherText = false;

  @override
  void initState() {
    _fromDate = DateTime.now().subtract(const Duration(days: 7));
    _toDate = DateTime.now();
    _fetchTimezone();
    super.initState();
  }
  final List<String> genderItems = [
    'Male',
    'Female',
  ];
  final List<String> defaultmap = [
    'LocationIQ Streets',
    'LocationIQ Dark',
    'OpenStreetsMap',
    'OpenTopoMap',
    'Carto Basemaps',
    'Google Road',
    'Google Satellite',
    'Google Hybrid',
    'AutoNavi',
    'Ordnance Survey',
  ];
  final List<String> cordinatesmap = [
    'Decimal Degrees',
    'Degrees Decimal Minutes',
    'Degrees Decimal Seconds',
  ];
  final List<String> speedUnit = [
    'kn',
    'km/h',
    'mph',
  ];
  final List<String> distanceUnit = [
    'km',
    'mi',
    'nmi',
  ];
  final List<String> altitudeUnit = [
    'm',
    'ft'
  ];
  final List<String> volumeUnit = [
    'Liter',
    'U.S. Gallon',
    'imp. Gallon'
  ];


  Future<void> _fetchTimezone() async {
    final String timezoneApi = dotenv.env['TIMEZONE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(timezoneApi),
          headers: {'Cookie': sessionCookies},
        );
        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          setState(() {
            timezoneItems = jsonResponse.cast<String>(); // Casting to List<String>
          });
        } else {
        }
      } catch (error) {
      }
    } else {
    }
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
          },
        );
      },
    );
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
          elevation: 0.1,
          backgroundColor: Colors.black,
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
            'Add Saved Command',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: 40,left: 20,right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700,),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Required',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15,),
                      TextField(
                        style:TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade700,
                            ),
                          ),

                          hintText: "Description",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15,),


                    ],
                  ),
                ),



                const SizedBox(height: 20,),
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
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel',
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
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: (){},
                      child: Text('Submit',
                          style: GoogleFonts.poppins(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
    );
  }
}
