import 'package:credence/feedback.dart';
import 'package:credence/help_screen.dart';
import 'package:credence/invite_friend.dart';
import 'package:credence/privacy_policy.dart';
import 'package:credence/rate_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

//sdcsdcesdfcwesdfcesdcsdcesdc
import 'all_vehicle_live.dart';
import 'change_password.dart';
import 'edit_profile.dart';
import 'login_screen.dart';
import 'new_dashboard.dart';

class AboutUs extends StatefulWidget {
  final String myName;
  final String? phone;
  final int userId;

  const AboutUs(
      {super.key, required this.myName, this.phone, required this.userId});

  @override
  State<AboutUs> createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
  final int _selecteditem = 5;
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

  void _performLogout(BuildContext context) async {
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

  int _currentPage = 0;

  final List<String> aboutPoints = [
    "We at Credence are a team of experts at the intersection of the tech and support services. We’re driven by a singular passion and purpose, to help our clients with GPS Tracking solutions. We are passionate about understanding the needs and requirements of our clients and provide them with the required tools and resources. For business growth and personal security",
    "To make Safety and security accessible to all at affordable cost. Credence helps navigating your bussiness towords impecceble operation with a vision to bring a digital revolution combined with safty and security of your loved once.",
    "Proudly helping india to diversify industries in the market and ensuring safty for your loved once.We do care safety and security for your family.",
  ];
  final List<String> title = [
    "About Us",
    "Mission",
    "Vision",
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
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
                  Scaffold.of(context).openDrawer(); // Open the side menu bar
                },
              ),
            ),
          ),
          drawer: Drawer(
            backgroundColor: Colors.grey.shade300,
            child: ListView(
              children: <Widget>[
                GestureDetector(
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
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                              GestureDetector(
                                  child: const Icon(
                                    Icons.arrow_forward_ios_sharp,
                                    color: Colors.black,
                                  )),
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
                            color: Colors.black,
                          )),
                      title: Text(
                        'Home',
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
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
                      ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
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
                      ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: _selecteditem == 5
                          ? Colors.grey.shade500.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                        leading: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset(
                              "assets/about_image.png",
                              color:
                              _selecteditem == 5 ? Colors.white : Colors.black,
                            )),
                        title: Text(
                          'About Us',
                          style: GoogleFonts.poppins(
                              color:
                              _selecteditem == 5 ? Colors.white : Colors.black,
                              fontSize: 12),
                        ),
                        onTap: () {
                          // Handle About Us tap
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AboutUs(
                                      myName: widget.myName,
                                      userId: widget.userId)));
                        }
                      // Handle About Us tap

                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 3
                      ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: _selecteditem == 3
                          ? Colors.grey.shade500.withOpacity(0.5)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        // Handle Invite Friend tap
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Invite(
                                    myName: widget.myName, userId: widget.userId)));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 9
                      ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
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
                      ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        launch("https://parivahan.gov.in/rcdlstatus/?pur_cd=101");
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 7
                      ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
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
                      ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: _selecteditem == 6
                          ? Colors.grey.shade500.withOpacity(0.5)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        // Handle About Us tap
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PrivacyPolicy(
                                    myName: widget.myName, userId: widget.userId)));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 1
                      ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: _selecteditem == 1
                          ? Colors.grey.shade500.withOpacity(0.5)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
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
                      ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
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
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/feedback_image.png",
                          )),
                      title: Text(
                        'Feedback',
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FeedBack(
                                  myName: widget.myName,
                                  userId: widget.userId,
                                )));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 4
                      ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: _selecteditem == 4
                          ? Colors.grey.shade500.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            "assets/rate_app.png",
                            color: _selecteditem == 4 ? Colors.white : Colors.black,
                          )),
                      title: Text(
                        'Rate the App',
                        style: GoogleFonts.poppins(
                            color: _selecteditem == 4 ? Colors.white : Colors.black,
                            fontSize: 12),
                      ),
                      onTap: () {
                        // Handle Rate the App tap
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Rate(
                                    myName: widget.myName, userId: widget.userId)));
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: _selecteditem == 10
                      ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
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
                      ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
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
                        style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
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
            child: Column(children: [
              Image.asset("assets/about_us.png"),
              SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.4, // Adjust the height of the header
                child: PageView.builder(
                  itemCount: aboutPoints.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              title[index],
                              style: GoogleFonts.poppins(
                                  fontSize: 20.0, // Customize the font size
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white // Customize the font weight
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              aboutPoints[index],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 13.0, // Customize the font size
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white // Customize the font weight
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  aboutPoints.length,
                      (index) => buildPageIndicator(index),
                ),
              ),
              SizedBox(
                height: 350,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 50,
                    ),
                    SizedBox(
                      height: 300,
                      child: Column(
                        children: [
                          Text(
                            "Contact Details",
                            style: GoogleFonts.poppins(
                                fontSize: 20.0, // Customize the font size
                                fontWeight: FontWeight.w600,
                                color: Colors.white // Customize the font weight
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 15,
                                ),
                                const Icon(
                                  FontAwesomeIcons.phone,
                                  size: 18,
                                  color: CupertinoColors.white,
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                    onTap: () {
                                      launch("tel:+917000423338");
                                    },
                                    child: Text(
                                      "+9170004 23338",
                                      style: GoogleFonts.poppins(
                                          fontSize: 14.0, // Customize the font size
                                          fontWeight: FontWeight.w500,
                                          color: CupertinoColors
                                              .activeBlue // Customize the font weight
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                            child: Row(
                              children: [
                                const SizedBox(width: 14),
                                const Icon(
                                  Icons.email_outlined,
                                  color: CupertinoColors.white,
                                ),
                                const SizedBox(
                                  width: 15,
                                ),
                                GestureDetector(
                                    onTap: () {
                                      _launchEmail();
                                    },
                                    child: Text(
                                      "sales@credencetracker.com",
                                      style: GoogleFonts.poppins(
                                          fontSize: 14.0, // Customize the font size
                                          fontWeight: FontWeight.w500,
                                          color: CupertinoColors
                                              .activeBlue // Customize the font weight
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 20),
                              const Icon(
                                FontAwesomeIcons.locationArrow,
                                color: CupertinoColors.destructiveRed,
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Text(
                                "Block no 07, Krida Square",
                                style: GoogleFonts.poppins(
                                    fontSize: 13.0, // Customize the font size
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors
                                        .white // Customize the font weight
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          Text(
                            " Chandan Nagar Nagpur, Maharashtra 440024",
                            style: GoogleFonts.poppins(
                                fontSize: 13.0, // Customize the font size
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors
                                    .white // Customize the font weight
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              _launchGoogleMaps(); // Function to open Google Maps
                            },
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.18,
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: Image.asset(
                                "assets/address_map.PNG",
                                fit: BoxFit.fill,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10), // Add some spacing
              Text(
                "Follow us on Social Media:",
                style: GoogleFonts.poppins(
                    fontSize: 20.0, // Customize the font size
                    fontWeight: FontWeight.w600,
                    color: Colors.white // Customize the font weight
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          launch(
                              "https://instagram.com/credence_trackers?igshid=NzZhOTFlYzFmZQ==");
                        },
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            const Icon(
                              FontAwesomeIcons.instagram,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              "Instagram",
                              style: GoogleFonts.poppins(
                                  fontSize: 10.0, // Customize the font size
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white // Customize the font weight
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          launch(
                              "https://www.facebook.com/p/Credence-Tracker-100071838708642/");
                        },
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            const Icon(
                              FontAwesomeIcons.facebook,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              "Facebook",
                              style: GoogleFonts.poppins(
                                  fontSize: 10.0, // Customize the font size
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white // Customize the font weight
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // launch("http://103.174.103.78:8085/CRT/login.php/");
                          launch("http://104.251.212.84/login");
                        },
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            const Icon(
                              FontAwesomeIcons.wikipediaW,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 15),
                            Text(
                              "Website",
                              style: GoogleFonts.poppins(
                                  fontSize: 10.0, // Customize the font size
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white // Customize the font weight
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ));
  }

  Widget buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _launchEmail() async {
    const String googleMapsUrl =
        "https://mail.google.com/mail/u/0/#inbox?compose=CllgCJZZQKqVXkdRhWMRmTlxnNMDNLTNxBnqRqdWDWJktbzsZChpNlLFmPbTGRGnKkwfqzRnVdV"; // Replace with your specific URL
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw "Could not launch Google Maps";
    }
  }

  void _launchGoogleMaps() async {
    const String googleMapsUrl =
        "https://www.google.com/maps/place/Krida+Square/@21.129796,79.1026131,17z/data=!3m1!4b1!4m6!3m5!1s0x3bd4c0ac15ca864d:0x22189c0e19940c91!8m2!3d21.129791!4d79.105188!16s%2Fg%2F11qnfwb7cf?entry=ttu"; // Replace with your specific URL
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw "Could not launch Google Maps";
    }
  }

  void main() {
    runApp(AboutUs(
      myName: widget.myName,
      userId: 0,
    ));
  }
}
