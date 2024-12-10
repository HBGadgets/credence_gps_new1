import 'dart:convert';
import 'dart:io';
import 'package:credence/all_vehicle_live.dart';
import 'package:credence/change_password.dart';
import 'package:credence/edit_profile.dart';
import 'package:credence/help_screen.dart';
import 'package:credence/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final String username;
  // final String phone;
  final int userId;

  const ProfileScreen({Key? key, required this.username, required this.userId})
      : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storage = const FlutterSecureStorage();
  String MyName = "";
  String phone = "";

  File? _image;
  final List<IconData> cardIcons = [
    Icons.home,
    Icons.map,
    Icons.help,
    Icons.person_2_outlined,
  ];

  final List<Color> iconColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
  ];

  int selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    userData();
  }


  // Function to open the image picker and set the selected image
  Future<void> _getImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);

      // Save the image to a more persistent location
      final appDir = await getApplicationDocumentsDirectory();
      const imageName = "selected_image.jpg";
      final imageFileSaved = await imageFile.copy('${appDir.path}/$imageName');

      setState(() {
        _image = imageFileSaved;
      });
    }
  }

  int _selectedIndex = 1;

  bool isGridMode = true; // Initially, set to grid mode

  void toggleGridMode() {
    setState(() {
      isGridMode = !isGridMode;
    });
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog(
      //show confirm dialogue
      //the return value will be from "Yes" or "No" options
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.grey.shade300,
            title:  Text('Logout',
              style: GoogleFonts.poppins(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black
              ),),
            content:  Text('Are you sure you want to Logout?',
              style: GoogleFonts.poppins(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black
              ),),
            actions: [
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
                child: Text('No',
                    style: GoogleFonts.poppins(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white
                    )),
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
                onPressed: () {
                  _performLogout(context);
                },
                //return true when click on "Yes"
                child: Text('Yes',
                    style: GoogleFonts.poppins(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white
                    )),
              ),
            ],
          ),
    );
  }

// Create a function to perform the logout actions.
  void _performLogout(BuildContext context) async {
    // Clear session data (e.g., session cookies).
    const storage = FlutterSecureStorage();
    await storage.delete(key: "sessionCookies");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
    Fluttertoast.showToast(
      msg: "Logout Successful",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> userData() async {
    final String userApi = dotenv.env['USERS_API']!;
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

        // Extract id from response body
        final int userId = responseData['id'];
        String name = responseData['name'];
        phone = responseData['phone'];


        setState(() {
          MyName = name;
        });
      } else {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Center(
                  child: Column(
                    children: [
                      ClipOval(
                          child: _image == null
                              ? Image.asset("assets/user_image.png")
                              : Image.file(_image!, fit: BoxFit.cover)),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1,
                          child: Image.asset("assets/logo_t.png")),
                      Padding(
                        padding:
                        const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                        child: Text(
                          // Use a conditional expression to show the username if logged in
                          'Welcome, ${widget.username}',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 12),
                        ),
                      ),
                      Text(
                        MyName,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15),
                      ),
                      SizedBox(
                        height: 5.h,
                      ),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditProfile(
                                      userId: widget.userId,
                                      myName: widget.username,
                                      phone: phone,
                                    )));
                          },
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                buildMenuItem(
                                  "Update Profile",
                                  "assets/new_update_profile.png",
                                      () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => EditProfile(
                                              userId: widget.userId,
                                              phone: phone,
                                              myName: widget.username,
                                            )));
                                  },
                                ),
                                buildMenuItem(
                                  "License",
                                  "assets/new_license_img.png",
                                      () {
                                    launch(
                                        "https://parivahan.gov.in/rcdlstatus/?pur_cd=101");
                                  },
                                ),
                                buildMenuItem(
                                  "Check RC",
                                  "assets/new_rc_img.png",
                                      () {
                                    launch(
                                        "https://vahan.parivahan.gov.in/vahanservice/vahan/ui/appl_status/form_Know_Appl_Status.xhtml");
                                  },
                                ),
                                buildMenuItem(
                                  "Change Password",
                                  "assets/new_password_img.png",
                                      () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                            const ChangePassword()));
                                  },
                                ),
                                buildMenuItem(
                                  "Exit",
                                  "assets/new_logout_img.png",
                                      () {
                                    showLogoutDialog(context);
                                  },
                                ),
                                buildMenuItem(
                                  "Help and Support",
                                  "assets/new_help_support.png",
                                      () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                            const HelpScreen()));
                                  },
                                ),
                                buildMenuItem(
                                  "All Vehicles",
                                  "assets/new_all_vehicles.png",
                                      () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                            const AllVehicleLive()));
                                  },
                                ),
                              ],
                            ),
                          ))
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Clear session data
}

Widget buildMenuItem(String title, String imagePath, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 10.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.transparent,
          width: 1.0, // Adjust the border width as needed.
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            SizedBox(
              width: 6.w,
            ),
            SizedBox(
              width: 20,
              height: 20,
              child: Image.asset(imagePath),
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.white),
            ),
            const Spacer(), // Spacing to push the icon to the right.
            const SizedBox(
              child: Icon(
                Icons.chevron_right,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
