import 'package:credence/admin/saved_command_page.dart';
import 'package:credence/admin/server_page.dart';
import 'package:credence/admin/user_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_page.dart';
import 'devices_page.dart';
import 'drivers_page.dart';
import 'geofences_page.dart';
import 'group_page.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<AdminScreen> {

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 40,left: 20,right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome",
                style: GoogleFonts.poppins(
                    fontSize: 35.0, // Customize the font size
                    fontWeight: FontWeight.w500,
                    color: Colors
                        .white
                ),
              ),
              const SizedBox(height: 20,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const AccountPage();
                      },
                    ),
                  );
                },
                child:
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(
                            0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                       Icon(Icons.account_circle,color: Colors.white,size: 35,),
                        Text(
                          "Account",
                          style: GoogleFonts.poppins(
                              fontSize: 20.0, // Customize the font size
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white
                          ),

                        ),
                        Icon(Icons.keyboard_double_arrow_right,color: Colors.white,size: 30,),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const DevicesPage();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(
                            0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.on_device_training_sharp,color: Colors.white,size: 35,),
                        Text(
                          "Device",
                          style: GoogleFonts.poppins(
                              fontSize: 20.0, // Customize the font size
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white
                          ),

                        ),
                        Icon(Icons.keyboard_double_arrow_right,color: Colors.white,size: 30,),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const GroupPage();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(
                            0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.group,color: Colors.white,size: 35,),
                        Text(
                          "Group",
                          style: GoogleFonts.poppins(
                              fontSize: 20.0, // Customize the font size
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white
                          ),

                        ),
                        Icon(Icons.keyboard_double_arrow_right,color: Colors.white,size: 30,),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const GeofencePage();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(
                            0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.pin_drop,color: Colors.white,size: 35,),
                        Text(
                          "Geofence",
                          style: GoogleFonts.poppins(
                              fontSize: 20.0, // Customize the font size
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white
                          ),

                        ),
                        Icon(Icons.keyboard_double_arrow_right,color: Colors.white,size: 30,),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const UserPage();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(
                            0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.account_circle,color: Colors.white,size: 35,),
                        Text(
                          "User",
                          style: GoogleFonts.poppins(
                              fontSize: 20.0, // Customize the font size
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white
                          ),

                        ),
                        Icon(Icons.keyboard_double_arrow_right,color: Colors.white,size: 30,),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const DriversPage();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(
                            0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.drive_eta,color: Colors.white,size: 35,),
                        Text(
                          "Driver",
                          style: GoogleFonts.poppins(
                              fontSize: 20.0, // Customize the font size
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white
                          ),

                        ),
                        Icon(Icons.keyboard_double_arrow_right,color: Colors.white,size: 30,),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const ServerPage();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(
                            0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.data_saver_on,color: Colors.white,size: 35,),
                        Text(
                          "Server",
                          style: GoogleFonts.poppins(
                              fontSize: 20.0, // Customize the font size
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white
                          ),

                        ),
                        Icon(Icons.keyboard_double_arrow_right,color: Colors.white,size: 30,),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const SavedCommandPage();
                      },
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(
                            0, 1), // changes position of shadow
                      ),
                    ],
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.keyboard_command_key,color: Colors.white,size: 35,),
                        Text(
                          "Saved Command",
                          style: GoogleFonts.poppins(
                              fontSize: 20.0, // Customize the font size
                              fontWeight: FontWeight.w500,
                              color: Colors
                                  .white
                          ),

                        ),
                        Icon(Icons.keyboard_double_arrow_right,color: Colors.white,size: 30,),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      )
    );
  }
}
