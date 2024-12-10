import 'package:credence/about_us.dart';
import 'package:credence/dashboard_screen.dart';
import 'package:credence/help_screen.dart';
import 'package:credence/invite_friend.dart';
import 'package:credence/privacy_policy.dart';
import 'package:credence/rate_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'all_vehicle_live.dart';
import 'change_password.dart';
import 'edit_profile.dart';
import 'login_screen.dart';
import 'new_dashboard.dart';

class FeedBack extends StatefulWidget {
  final String myName;
  final String? phone;
  final int userId;

  const FeedBack(
      {super.key, required this.myName, this.phone, required this.userId});

  @override
  State<FeedBack> createState() => _FeedBackState();
}

class _FeedBackState extends State<FeedBack> {
  String feedbackText = '';
  final int _selecteditem = 2;
  bool isGridMode = true; // Initially, set to grid mode

  void toggleGridMode() {
    setState(() {
      isGridMode = !isGridMode;
    });
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade300,
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
              fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        content: Text(
          'Are you sure you want to Logout?',
          style: GoogleFonts.poppins(
              fontSize: 13.0, fontWeight: FontWeight.w500, color: Colors.black),
        ),
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
            onPressed: () {
              _performLogout(context);
            },
            child: Text('Yes',
                style: GoogleFonts.poppins(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8.0),
              ),
              child: AppBar(
                elevation: 0.0,
                backgroundColor: Colors.black,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Image.asset(
                      'assets/menu_imggg.png',
                      width:
                      24.0, // Adjust the width and height according to your needs
                      height: 24.0,
                    ),
                    onPressed: () {
                      Scaffold.of(context)
                          .openDrawer(); // Open the side menu bar
                    },
                  ),
                ),
              ),
            ),
          ),
          drawer: Drawer(
            backgroundColor: Colors.grey.shade300,
            child: ListView(
              children: <Widget>[
                Container(
                  decoration: const BoxDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              height: 70,
                              width: 250,
                              child: Image.asset(
                                "assets/credence_white.png",
                                fit: BoxFit.fill,
                              )),
                        ),
                        const SizedBox(height: 10.0), // Spacer
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.myName,
                                style: GoogleFonts.poppins(
                                    fontSize: 18.0, // Customize the font size
                                    fontWeight: FontWeight.w500,
                                    color: Colors
                                        .black // Customize the font weight
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_sharp,
                                color: Colors.black,
                                size: 17,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 0
                      ? const EdgeInsets.symmetric(horizontal: 0.0)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: _selecteditem == 0
                          ? Colors.grey.shade500.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 15,
                          width: 15,
                          child: Image.asset(
                            "assets/home_new.png",
                            color: _selecteditem == 0
                                ? Colors.white
                                : Colors.black,
                          )),
                      title: Text(
                        'Home',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DevicesListScreen(
                                  userId: widget.userId,
                                )));
                        // Handle Home tap
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 11
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/black_vehicles.png",
                          )),
                      // const Icon(Icons.help),
                      title: Text(
                        "All Vehicles",
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AllVehicleLive()));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 5
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _selecteditem == 5
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/about_image.png",
                          )),
                      title: Text(
                        'About Us',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        // Handle About Us tap
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AboutUs(
                                    myName: widget.myName,
                                    userId: widget.userId)));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 3
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _selecteditem == 3
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/invite_image.png",
                          )),
                      title: Text(
                        'Invite Friend',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        // Handle Invite Friend tap
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Invite(
                                    myName: widget.myName,
                                    userId: widget.userId)));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 9
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/black_rc.png",
                          )),
                      // const Icon(Icons.help),
                      title: Text(
                        'Check RC',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        launch(
                            "https://vahan.parivahan.gov.in/vahanservice/vahan/ui/appl_status/form_Know_Appl_Status.xhtml");
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 8
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/black_license.png",
                          )),
                      // const Icon(Icons.help),
                      title: Text(
                        'License',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        launch(
                            "https://parivahan.gov.in/rcdlstatus/?pur_cd=101");
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 7
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/black_profile.png",
                          )),
                      // const Icon(Icons.help),
                      title: Text(
                        'Update Profile',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditProfile(
                                  userId: widget.userId,
                                  phone: widget.phone.toString(),
                                  myName: widget.myName,
                                )));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 6
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _selecteditem == 6
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/privacy_image.png",
                          )),
                      title: Text(
                        'Privacy',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        // Handle About Us tap
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PrivacyPolicy(
                                    myName: widget.myName,
                                    userId: widget.userId)));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 1
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _selecteditem == 1
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/help_image.png",
                          )),
                      title: Text(
                        'Help',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HelpScreen()));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 2
                      ? const EdgeInsets.symmetric(
                      horizontal: 0.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: _selecteditem == 2
                          ? Colors.grey.shade500.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 15,
                          width: 15,
                          child: Image.asset(
                            "assets/feedback_image.png",
                            color: _selecteditem == 2
                                ? Colors.white
                                : Colors.black,
                          )),
                      // Icon(
                      //   Icons.feedback,
                      //   color: _selecteditem == 2 ? Colors.white : Colors.black,
                      // ),
                      title: Text(
                        'Feedback',
                        style: GoogleFonts.poppins(
                            color: _selecteditem == 2
                                ? Colors.white
                                : Colors.black,
                            fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FeedBack(
                                    myName: widget.myName,
                                    userId: widget.userId)));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 4
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: _selecteditem == 4
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/rate_app.png",
                          )),
                      title: Text(
                        'Rate the App',
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        // Handle Rate the App tap
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Rate(
                                    myName: widget.myName,
                                    userId: widget.userId)));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 10
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/black_password.png",
                          )),
                      // const Icon(Icons.help),
                      title: Text(
                        "Change Password",
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ChangePassword()));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 12
                      ? const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/black_logout.png",
                          )),
                      // const Icon(Icons.help),
                      title: Text(
                        "Exit",
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        showLogoutDialog(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.2,
                    width: MediaQuery.of(context).size.height * 0.15,
                    child: Container(
                        decoration: const BoxDecoration(
                          // color: Colors.grey.shade300,
                            shape: BoxShape.circle),
                        child: Image.asset("assets/feedback_newone.png"))),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Image.asset("assets/five_star_rating.png")),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.grey.shade300,
                    elevation: 5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          height: 150,
                          width: 350,
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            onChanged: (text) {
                              setState(() {
                                feedbackText = text;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Write your feedback here...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: const BorderSide(color: Colors.black),
                            ),
                            backgroundColor: Colors.grey.shade300,
                          ),
                          onPressed: () {
                          },
                          child: Text(
                            'Submit Feedback',
                            style: GoogleFonts.poppins(
                                fontSize: 12.0, // Customize the font size
                                fontWeight: FontWeight.w500,
                                color: Colors.black // Customize the font weight
                            ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
