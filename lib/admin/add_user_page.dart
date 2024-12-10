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

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<AddUserPage> {
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
            'Add User',
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

                    hintText: "Name",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
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

                    hintText: "Email",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
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

                    hintText: "Password",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 15,),
                GestureDetector(
                  onTap: (){
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return AlertDialog(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.zero,
                              insetPadding: EdgeInsets.zero,
                              buttonPadding: EdgeInsets.zero,
                              titlePadding: EdgeInsets.zero,
                              title: Container(
                                // height: MediaQuery.of(context).size.height * 0.8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color: Colors.black,
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Text(
                                          "Preferences",
                                          style: GoogleFonts.poppins(
                                              fontSize: 20.0,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white
                                          ),
                                        ),
                                        SizedBox(height: 10,),
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

                                            hintText: "Phone",
                                            hintStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
                                        DropdownButtonFormField2<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          hint: const Text(
                                            'Default Map',
                                            style: TextStyle(fontSize: 14,color: Colors.grey),
                                          ),
                                          items: defaultmap
                                              .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                              ),
                                            ),
                                          ))
                                              .toList(),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select gender.';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                          },
                                          onSaved: (value) {
                                            selectedValue = value.toString();
                                          },
                                          buttonStyleData: const ButtonStyleData(
                                            padding: EdgeInsets.only(right: 8),
                                          ),
                                          iconStyleData: const IconStyleData(
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ),
                                            iconSize: 24,
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey)
                                            ),
                                          ),
                                          menuItemStyleData: const MenuItemStyleData(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
                                        DropdownButtonFormField2<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          hint: const Text(
                                            'Co-Ordinates Format',
                                            style: TextStyle(fontSize: 14,color: Colors.grey),
                                          ),
                                          items: cordinatesmap
                                              .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                              ),
                                            ),
                                          ))
                                              .toList(),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select gender.';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                          },
                                          onSaved: (value) {
                                            selectedValue = value.toString();
                                          },
                                          buttonStyleData: const ButtonStyleData(
                                            padding: EdgeInsets.only(right: 8),
                                          ),
                                          iconStyleData: const IconStyleData(
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ),
                                            iconSize: 24,
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey)
                                            ),
                                          ),
                                          menuItemStyleData: const MenuItemStyleData(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
                                        DropdownButtonFormField2<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          hint: const Text(
                                            'Speed Unit',
                                            style: TextStyle(fontSize: 14,color: Colors.grey),
                                          ),
                                          items: speedUnit
                                              .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                              ),
                                            ),
                                          ))
                                              .toList(),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select gender.';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                          },
                                          onSaved: (value) {
                                            selectedValue = value.toString();
                                          },
                                          buttonStyleData: const ButtonStyleData(
                                            padding: EdgeInsets.only(right: 8),
                                          ),
                                          iconStyleData: const IconStyleData(
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ),
                                            iconSize: 24,
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey)
                                            ),
                                          ),
                                          menuItemStyleData: const MenuItemStyleData(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
                                        DropdownButtonFormField2<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          hint: const Text(
                                            'Distance Unit',
                                            style: TextStyle(fontSize: 14,color: Colors.grey),
                                          ),
                                          items: distanceUnit
                                              .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                              ),
                                            ),
                                          ))
                                              .toList(),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select gender.';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                          },
                                          onSaved: (value) {
                                            selectedValue = value.toString();
                                          },
                                          buttonStyleData: const ButtonStyleData(
                                            padding: EdgeInsets.only(right: 8),
                                          ),
                                          iconStyleData: const IconStyleData(
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ),
                                            iconSize: 24,
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey)
                                            ),
                                          ),
                                          menuItemStyleData: const MenuItemStyleData(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
                                        DropdownButtonFormField2<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          hint: const Text(
                                            'Altitude Unit',
                                            style: TextStyle(fontSize: 14,color: Colors.grey),
                                          ),
                                          items: altitudeUnit
                                              .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                              ),
                                            ),
                                          ))
                                              .toList(),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select gender.';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                          },
                                          onSaved: (value) {
                                            selectedValue = value.toString();
                                          },
                                          buttonStyleData: const ButtonStyleData(
                                            padding: EdgeInsets.only(right: 8),
                                          ),
                                          iconStyleData: const IconStyleData(
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ),
                                            iconSize: 24,
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey)
                                            ),
                                          ),
                                          menuItemStyleData: const MenuItemStyleData(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
                                        DropdownButtonFormField2<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          hint: const Text(
                                            'Volume Unit',
                                            style: TextStyle(fontSize: 14,color: Colors.grey),
                                          ),
                                          items: volumeUnit
                                              .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                              ),
                                            ),
                                          ))
                                              .toList(),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select gender.';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                          },
                                          onSaved: (value) {
                                            selectedValue = value.toString();
                                          },
                                          buttonStyleData: const ButtonStyleData(
                                            padding: EdgeInsets.only(right: 8),
                                          ),
                                          iconStyleData: const IconStyleData(
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ),
                                            iconSize: 24,
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey)
                                            ),
                                          ),
                                          menuItemStyleData: const MenuItemStyleData(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
                                        DropdownButtonFormField2<String>(
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          hint: const Text(
                                            'Timezone',
                                            style: TextStyle(fontSize: 14,color: Colors.grey),
                                          ),
                                          items: timezoneItems
                                              .map((item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white
                                              ),
                                            ),
                                          ))
                                              .toList(),
                                          validator: (value) {
                                            if (value == null) {
                                              return 'Please select gender.';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                          },
                                          onSaved: (value) {
                                            selectedTimeZoneValue = value.toString();
                                          },
                                          buttonStyleData: const ButtonStyleData(
                                            padding: EdgeInsets.only(right: 8),
                                          ),
                                          iconStyleData: const IconStyleData(
                                            icon: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.grey,
                                            ),
                                            iconSize: 24,
                                          ),
                                          dropdownStyleData: DropdownStyleData(
                                            decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey)
                                            ),
                                          ),
                                          menuItemStyleData: const MenuItemStyleData(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
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

                                            hintText: "POI Layer",
                                            hintStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10,),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _checkbox,
                                              onChanged: (value) {
                                                setState(() {
                                                  _checkbox = !_checkbox;
                                                });
                                              },
                                            ),
                                            Text(
                                              "12-hour Format",
                                              style: GoogleFonts.poppins(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  child:
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width*0.9,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700,),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Preference",
                              style:  TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down,color: Colors.white,size: 35,),
                          ],
                        )
                    ),
                  ),
                ),
                const SizedBox(height: 15,),
                GestureDetector(
                  onTap: (){
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return AlertDialog(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.zero,
                              insetPadding: EdgeInsets.zero,
                              buttonPadding: EdgeInsets.zero,
                              titlePadding: EdgeInsets.zero,
                              title: Container(
                                // height: MediaQuery.of(context).size.height * 0.8,
                                width: MediaQuery.of(context).size.width * 0.9,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color: Colors.black,
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Text(
                                          "Location",
                                          style: GoogleFonts.poppins(
                                              fontSize: 20.0,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white
                                          ),
                                        ),
                                        SizedBox(height: 10,),
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

                                            hintText: "Latitude",
                                            hintStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10,),
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

                                            hintText: "Longitude",
                                            hintStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10,),
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

                                            hintText: "Zoom",
                                            hintStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20,),
                                        Container(
                                          alignment: Alignment.center,
                                          height: 55,
                                          width: MediaQuery.of(context).size.width*0.9,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.blue,),
                                            borderRadius: BorderRadius.circular(5.0),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10),
                                            child:  Text(
                                              "Current Location",
                                              style:  TextStyle(
                                                fontSize: 18,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                ),

                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width*0.9,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700,),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Location",
                              style:  TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down,color: Colors.white,size: 35,),
                          ],
                        )
                    ),
                  ),
                ),
                const SizedBox(height: 15,),
                GestureDetector(
                  onTap: (){
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (BuildContext context, StateSetter setState) {
                            return AlertDialog(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: EdgeInsets.zero,
                              insetPadding: EdgeInsets.zero,
                              buttonPadding: EdgeInsets.zero,
                              titlePadding: EdgeInsets.zero,
                              title: Container(
                                // height: MediaQuery.of(context).size.height * 0.8,
                                width: MediaQuery.of(context).size.width * 0.9,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                  color: Colors.black,
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Text(
                                          "Permissions",
                                          style: GoogleFonts.poppins(
                                              fontSize: 20.0,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Expiration",
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white,
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
                                                padding: EdgeInsets.symmetric(horizontal: 7),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12.0),
                                                  color: Colors.black,
                                                  border: Border.all(color: Colors.grey.shade700),
                                                ),
                                                height: 50,
                                                width: MediaQuery.of(context).size.width * 0.8,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        _formatDate(originalFrom ?? DateTime.now()),
                                                        style: GoogleFonts.poppins(
                                                            color: Colors.white, fontSize: 12),
                                                      ),
                                                      Icon(Icons.calendar_month,color: Colors.white,)
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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

                                            hintText: "Device Limit",
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w400,
                                            ),
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

                                            hintText: "User Limit",
                                            hintStyle: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width*0.8,
                                          height: MediaQuery.of(context).size.width*0.5,
                                          child: ListView(
                                            children: <Widget>[
                                              ListTile(
                                                title:
                                                Text(
                                                  "Disabled",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white
                                                  ),
                                                ),
                                                leading: Checkbox(
                                                  value: _isFootBallText,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      _isFootBallText = value!;
                                                      String selectVal = "FootBall";
                                                      value! ? _list.add(selectVal) : _list.remove(selectVal);
                                                    });
                                                  },
                                                ),
                                              ),
                                              ListTile(
                                                title:         Text(
                                                  "Admin",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white
                                                  ),
                                                ),
                                                leading: Checkbox(
                                                  value: _isBaskeballText,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      _isBaskeballText = value!;
                                                      String selectVal = "Basketball";
                                                      value! ? _list.add(selectVal) : _list.remove(selectVal);
                                                    });
                                                  },
                                                ),
                                              ),
                                              ListTile(
                                                title:        Text(
                                                  "Readonly",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white
                                                  ),
                                                ),
                                                leading: Checkbox(
                                                  value: _isCricketText,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isCricketText = value!;
                                                      String selectVal = "Cricket";
                                                      value! ? _list.add(selectVal) : _list.remove(selectVal);
                                                    });
                                                  },
                                                ),
                                              ),
                                              ListTile(
                                                title:     Text(
                                                  "Device Readonly",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white
                                                  ),
                                                ),
                                                leading: Checkbox(
                                                  value: _isKabaddiText,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isKabaddiText = value!;
                                                      String selectVal = "Kabaddi";
                                                      value! ? _list.add(selectVal) : _list.remove(selectVal);
                                                    });
                                                  },
                                                ),
                                              ),
                                              ListTile(
                                                title:   Text(
                                                  "Limit Commands",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white
                                                  ),
                                                ),
                                                leading: Checkbox(
                                                  value: _isBasketBallText,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isBasketBallText = value!;
                                                      String selectVal = "BasketBall";
                                                      value! ? _list.add(selectVal) : _list.remove(selectVal);
                                                    });
                                                  },
                                                ),
                                              ),
                                              ListTile(
                                                title: Text(
                                                  "Disable Reports",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white
                                                  ),
                                                ),
                                                leading: Checkbox(
                                                  value: _isVolleyBallText,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isVolleyBallText = value!;
                                                      String selectVal = "VolleyBall";
                                                      value! ? _list.add(selectVal) : _list.remove(selectVal);
                                                    });
                                                  },
                                                ),
                                              ),
                                              ListTile(
                                                title:Text(
                                                  "No Email Change",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white
                                                  ),
                                                ),
                                                leading: Checkbox(
                                                  value: _isOtherText,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _isOtherText = value!;
                                                      String selectVal = "Other Games";
                                                      value! ? _list.add(selectVal) : _list.remove(selectVal);
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 15,),

                                      ],
                                    ),
                                  ),
                                ),

                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width*0.9,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700,),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Permissions",
                              style:  TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down,color: Colors.white,size: 35,),
                          ],
                        )
                    ),
                  ),
                ),
                const SizedBox(height: 15,),
                Container(
                  height: 55,
                  width: MediaQuery.of(context).size.width*0.9,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700,),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Attribute",
                            style:  TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,color: Colors.white,size: 35,),
                        ],
                      )
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
