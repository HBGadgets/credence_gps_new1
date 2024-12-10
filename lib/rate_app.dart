import 'package:credence/about_us.dart';
import 'package:credence/dashboard_screen.dart';
import 'package:credence/feedback.dart';
import 'package:credence/help_screen.dart';
import 'package:credence/invite_friend.dart';
import 'package:credence/privacy_policy.dart';
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

class Rate extends StatefulWidget {
  final String myName;
  final String? phone;
  final int userId;

  const Rate({super.key, required this.myName,  this.phone, required this.userId});

  @override
  State<Rate> createState() => _RateState();
}

class _RateState extends State<Rate> {
  double _rating = 3.5;
  String feedbackText = '';
  final int _selecteditem = 4;
  bool isGridMode = true;
  void toggleGridMode() {
    setState(() {
      isGridMode = !isGridMode;
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    Scaffold.of(context).openDrawer(); // Open the side menu bar
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
              GestureDetector(
                // onTap: () {
                //   Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //           builder: (context) => ProfileScreen(
                //               username: widget.myName,
                //               userId: widget.userId)));
                // },
                child: Container(
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
                              child: Image.asset("assets/credence_white.png",
                                fit: BoxFit.fill,
                              )),
                        ),
                        // CircleAvatar(
                        //   backgroundColor: Colors.transparent,
                        //   radius: 60.0,
                        //   child: Image.asset("assets/logo_t.png"),
                        // ),
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
                                // onTap: () {
                                //   Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //           builder: (context) => ProfileScreen(
                                //               username: widget.myName,
                                //               userId: widget.userId)));
                                // },
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
                              builder: (context) =>
                              const AllVehicleLive()));
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
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 12),
                    ),
                    onTap: () {
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
                    onTap: ()  {
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
                        )
                    ),
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
                    ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
                    : const EdgeInsets.symmetric(horizontal: 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
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
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 12),
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
                          color:
                          _selecteditem == 4 ? Colors.white : Colors.black,
                        )),
                    title: Text(
                      'Rate the App',
                      style: GoogleFonts.poppins(
                          color:
                          _selecteditem == 4 ? Colors.white : Colors.black,
                          fontSize: 12),
                    ),
                    onTap: () {
                      Rate(myName: widget.myName, userId: widget.userId);
                      // Handle Rate the App tap
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
                              builder: (context) =>
                              const ChangePassword()));
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
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30, top: 15),
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.height * 0.3,
                  child: Image.asset("assets/good_rating.png")),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              "Rate an App",
              style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "I appreciate the effort put into this app. It has some great features and potential. However, there are a few areas where I believe it could be even better with some enhancements. Overall, it's a promising app.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AdvancedRatingBar(
                  rating: _rating,
                  onRatingChanged: (newRating) {
                    setState(() {
                      _rating = newRating;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Rating: $_rating",
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          side: const BorderSide(color: Colors.black),
                        ),
                        backgroundColor: Colors.grey.shade300,
                      ),
                      onPressed: () {},
                      child: Text(
                        "Rate",
                        style: GoogleFonts.poppins(
                            fontSize: 12.0, // Customize the font size
                            fontWeight: FontWeight.w500,
                            color: Colors.black // Customize the font weight
                        ),
                      )),
                )
              ],
            ),
          ]),
        ),
        /*Padding(
                  padding: const EdgeInsets.all(8.0),

                  child: ElevatedButton(
                    onPressed: () {
                      // Handle the button tap, e.g., open a chat screen
                      // Replace this with your chat functionality
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Send'),
                            content: Text('give feedback'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue, // Button color
                      onPrimary: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Adjust the button's border radius
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Chat with Us',
                        style: TextStyle(
                            fontSize: 18.0), // Customize the button text style
                      ),
                    ),
                  ),
                ),*/ /*Padding(
                  padding: const EdgeInsets.all(8.0),

                  child: ElevatedButton(
                    onPressed: () {
                      // Handle the button tap, e.g., open a chat screen
                      // Replace this with your chat functionality
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Send'),
                            content: Text('give feedback'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue, // Button color
                      onPrimary: Colors.white, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Adjust the button's border radius
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Chat with Us',
                        style: TextStyle(
                            fontSize: 18.0), // Customize the button text style
                      ),
                    ),
                  ),
                ),*/
      ),
    );
  }
}

class AdvancedRatingBar extends StatefulWidget {
  final double rating;
  final int starCount;
  final IconData filledIconData;
  final IconData halfFilledIconData;
  final IconData emptyIconData;
  final Color color;
  final double size;
  final Function(double) onRatingChanged;

  AdvancedRatingBar({
    required this.rating,
    this.starCount = 5,
    this.filledIconData = Icons.star,
    this.halfFilledIconData = Icons.star_half,
    this.emptyIconData = Icons.star_border,
    this.color = Colors.amber,
    this.size = 30,
    required this.onRatingChanged,
  });

  @override
  _AdvancedRatingBarState createState() => _AdvancedRatingBarState();
}

class _AdvancedRatingBarState extends State<AdvancedRatingBar> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5.0,
      children: List.generate(widget.starCount, (index) {
        Icon icon;
        if (index < widget.rating) {
          icon = Icon(
            widget.filledIconData,
            color: widget.color,
            size: widget.size,
          );
        } else if (index < widget.rating + 0.5 &&
            index < widget.starCount - 1) {
          icon = Icon(
            widget.halfFilledIconData,
            color: widget.color,
            size: widget.size,
          );
        } else {
          icon = Icon(
            widget.emptyIconData,
            color: widget.color,
            size: widget.size,
          );
        }
        return GestureDetector(
          onTap: () {
            double newRating = index + 1.0;
            if (index < widget.rating) {
              newRating -= 0.5;
            }
            widget.onRatingChanged(newRating);
          },
          child: icon,
        );
      }),
    );
  }
}
