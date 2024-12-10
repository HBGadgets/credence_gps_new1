import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'add_device_page.dart';
import 'add_driver_page.dart';
import 'add_group_page.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<DriversPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();


  @override
  void initState() {
    super.initState();
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
          actions: [
            GestureDetector(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const AddDriverPage();
                    },
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade800
                  ),
                  child: Icon(Icons.add,color: Colors.white,),
                ),
              ),
            )
          ],
          title: Text(
            'Drivers',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body:  SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                ListView.builder(
                  shrinkWrap: true,  // Added this
                  physics: const NeverScrollableScrollPhysics(),  // Disables the inner scroll to avoid conflicts
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child:   Container(
                        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20),
                        alignment: Alignment.centerLeft,

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Name",
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800
                                  ),
                                ),
                                Container(
                                  height: 30,
                                  width: MediaQuery.of(context).size.width*0.6,
                                  padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),

                                ),

                              ],
                            ),
                            SizedBox(height: 10,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  "Identifier",
                                  style: GoogleFonts.poppins(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800
                                  ),
                                ),
                                Container(
                                  height: 30,
                                  width: MediaQuery.of(context).size.width*0.6,
                                  padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),

                                ),

                              ],
                            ),
                            SizedBox(height: 10,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(),
                                Row(
                                  children: [
                                    Icon(Icons.edit,color: Colors.black,),
                                    SizedBox(width: 5,),
                                    Icon(Icons.delete,color: Colors.black,)
                                  ],
                                ),
                              ],
                            )


                          ],
                        ),

                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        )

    );
  }
}
