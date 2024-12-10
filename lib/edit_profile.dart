import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class EditProfile extends StatefulWidget {
  final int userId;
  final String myName;
  final String phone;

  const EditProfile(
      {super.key,
        required this.userId,
        required this.myName,
        required this.phone});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File? _image;
  String myName = '';
  final storage = const FlutterSecureStorage();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  final String userApi = dotenv.env['USERS_API']!;

  @override
  void initState() {
    super.initState();
    setState(() {
      nameController.text = widget.myName;
      phoneNumberController.text = widget.phone;
    });
  }

  Future<void> _getImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> userData() async {
    final String apiUrl = "$userApi/${widget.userId}";
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );

      if (response.statusCode == 200) {
        // Parse response body JSON
        final Map<String, dynamic> responseData = json.decode(response.body);
        responseData['name'] = nameController.text;
        responseData['phone'] = phoneNumberController.text;
        await _updateUserData(responseData);
      } else {
      }
    }
  }

  Future<void> _updateUserData(Map<String, dynamic> userData) async {
    final String apiUrl = "$userApi/${widget.userId}";
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Cookie': sessionCookies,
          'Content-Type': 'application/json',
        },
        body: json.encode(userData),
      );
      if (response.statusCode == 200) {
      } else {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.1,
          backgroundColor: Colors.black,
          title: Text(
            "Edit Profile",
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
        backgroundColor: Colors.black,
        body: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.5,
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
                          offset:
                          const Offset(0, 1), // changes position of shadow
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
                    padding: const EdgeInsets.only(left: 15, right: 15),
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
                        const SizedBox(
                          height: 5,
                        ),
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
                                const SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.7,
                                  child: TextField(
                                    controller: nameController,
                                    style: const TextStyle(
                                        color: Colors
                                            .white), // Set text color to white
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your name',
                                      hintStyle: TextStyle(
                                          color: Colors
                                              .grey), // Set the hint text color to white
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          "Phone",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
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
                                  Icons.call,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width:
                                  MediaQuery.of(context).size.width * 0.7,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    controller: phoneNumberController,
                                    style: const TextStyle(
                                        color: Colors
                                            .white), // Set text color to white
                                    decoration: const InputDecoration(
                                        hintText: 'Enter your phone number',
                                        hintStyle:
                                        TextStyle(color: Colors.grey)),
                                  ),
                                ),



                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: (){
                            userData();
                          },
                          child: Container(
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.07,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(15.0),
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                            child: Text(
                              "Update",
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),

                      ],
                    ),
                  )),
              // Positioned(
              //   top: -50,
              //   left: 10,
              //   right: 10,
              //   child: CircleAvatar(
              //     radius: 55,
              //     backgroundColor: Colors.grey.shade300,
              //     child: ImageFiltered(
              //       imageFilter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
              //       child: _image == null
              //           ? Center(child: Image.asset("assets/logo_t.png"))
              //           : Image.file(_image!, fit: BoxFit.cover),
              //       // Image.asset("assets/user_image.png"),
              //     ),
              //   ),
              // ),
              // Positioned(
              //   top: 15,
              //   right: 110,
              //   child: GestureDetector(
              //     onTap: () {
              //       // _getImage(); // Call a function to open the image picker
              //     },
              //     child: const CircleAvatar(
              //       radius: 20,
              //       backgroundColor: Colors.orange,
              //       child: Icon(
              //         Icons.camera_alt_outlined,
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

}
