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
import 'add_group_page.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<GroupPage> {
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
                      return const AddGroupPage();
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
            'Groups',
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
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 10),
                      alignment: Alignment.centerLeft,
                      height: 45,
                      width: MediaQuery.of(context).size.width*0.54,
                      color: Colors.grey.shade700,
                      child: Text(
                        'Name',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 16
                        ),
                      ),
                    ),
                    SizedBox(width: 5,),
                    Container(
                      padding: EdgeInsets.only(left: 10),
                      alignment: Alignment.centerLeft,
                      height: 45,
                      width: MediaQuery.of(context).size.width*0.34,
                      color: Colors.grey.shade700,
                      child:  Text(
                        'Action',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 16
                        ),
                      ),
                    ),
                  ],
                ),

                ListView.builder(
                  shrinkWrap: true,  // Added this
                  physics: const NeverScrollableScrollPhysics(),  // Disables the inner scroll to avoid conflicts
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.only(left: 10),
                            alignment: Alignment.centerLeft,
                            width: MediaQuery.of(context).size.width*0.54,
                           height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0.0),
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Text(
                              'Hansatravels',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  fontSize: 15
                              ),
                            ),

                          ),
                          SizedBox(width: 5,),
                          Container(
                            padding: EdgeInsets.only(left: 10),
                            alignment: Alignment.centerLeft,
                            width: MediaQuery.of(context).size.width*0.34,
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0.0),
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.edit,color: Colors.black,),
                                Icon(Icons.delete,color: Colors.black,),
                              ],
                            ),

                          ),
                        ],
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
