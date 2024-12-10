import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DriverScreen extends StatefulWidget {
  final int carId;
  final String carNumber;

  const DriverScreen({super.key, required this.carId, required this.carNumber});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final storage = const FlutterSecureStorage();
  String driver_name = '';
  String phone_no = '';
  String driver_address = '';
  String License_no = '';
  String work_id = '0';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriver();
  }

  Future<void> _fetchDriver() async {
    final String driverApi = dotenv.env['DRIVER_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(driverApi),
          headers: {'Cookie': sessionCookies},
        );

        if (response.statusCode == 200) {
          setState(() {
            isLoading = false;
          });

          final List<dynamic> driverDetailsJson = json.decode(response.body);
          if (driverDetailsJson.isNotEmpty) {
            for (var driver in driverDetailsJson) {
              // Access each field in the driver object
              final String driverName = driver['name'] ?? 'N/A';
              final String uniqueId = driver['uniqueId'] ?? 'N/A';
              final Map<String, dynamic> attributes = driver['attributes'] ?? {};
              final String phone = attributes['phone']?.toString() ?? 'N/A';
              final String address = attributes['add']?.toString() ?? 'N/A';
              final String license = attributes['License']?.toString() ?? 'N/A';
              setState(() {
                driver_name = driverName;
                phone_no = phone;
                driver_address = address;
                License_no = license;
                work_id = uniqueId;
              });
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          elevation: 0.1,
          backgroundColor: Colors.black,
          title: Text(
            "Driver Details",
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
          ),
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios_new_outlined,
                color: Colors.white),
          ),
        ),
        body: isLoading
            ? Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.black,
              size: 50,
            ))
            :
        Center(
          child: SingleChildScrollView(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12,top: 70,right: 12,bottom: 10),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.8, // Adjust the height as needed
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Colors.grey.shade700),
                        color: Colors.grey.shade900,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(0, 1), // changes position of shadow
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 10,
                  right: 10,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15,top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.07,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  driver_name,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "License",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.07,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  License_no,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Phone",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.07,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  phone_no,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Work Id",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.07,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.work_history,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  work_id,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Vehicle No.",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.07,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.numbers,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.carNumber,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Address",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.07,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15.0),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_pin,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  driver_address,
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Add some space to account for floating elements
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  left: 10,
                  right: 10,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey.shade300,
                    child: Image.asset("assets/user_image.png"),
                  ),
                ),

              ],
            ),
          ),
        )
    );
  }
}

class UpperCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
        size.width / 2, size.height + 20, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
