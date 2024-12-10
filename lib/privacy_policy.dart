import 'package:credence/about_us.dart';
import 'package:credence/dashboard_screen.dart';
import 'package:credence/feedback.dart';
import 'package:credence/help_screen.dart';
import 'package:credence/invite_friend.dart';
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

class PrivacyPolicy extends StatefulWidget {
  final String myName;
  final String? phone;
  final int userId;

  const PrivacyPolicy({super.key, required this.myName,  this.phone, required this.userId});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  String feedbackText = '';

  int _selectedIndex = 0;
  int _selecteditem = 6;
  bool _isSelected = false;

  bool isGridMode = true; // 91603373764670Initially, set to grid mode

  void toggleGridMode() {
    setState(() {
      isGridMode = !isGridMode;
    });
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selecteditem = index;
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
                        //   // Your user profile picture here
                        //   backgroundColor:
                        //       Colors.transparent, // Customize the background color
                        //   radius: 60.0, // Adjust the avatar size as needed
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
                                    color:
                                    Colors.black
                                ),
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
                    leading:SizedBox(
                        height: 15,
                        width: 15,
                        child: Image.asset(
                          "assets/home_new.png",
                          color: Colors.black,
                        )),
                    title:Text('Home',
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 12),
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
                    leading:SizedBox(
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
                    title:  Text(
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
                        ? Colors.grey.shade500.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                  child: ListTile(
                    leading:
                    SizedBox(
                        height: 20,
                        width: 20,
                        child: Image.asset(
                          "assets/privacy_image.png",
                          color: _selecteditem == 6 ? Colors.white : Colors.black,
                        )),
                    title: Text('Privacy',
                        style: GoogleFonts.poppins(
                            color:
                            _selecteditem == 6 ? Colors.white : Colors.black,
                            fontSize: 12
                        )),
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
                    title:  Text('Help',
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 12),),
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
                          color: _selecteditem == 4 ? Colors.white : Colors.black,
                        )),
                    title: Text(
                      'Rate the App',
                      style: GoogleFonts.poppins(
                          color:
                          _selecteditem == 4 ? Colors.white : Colors.black,
                          fontSize: 12),
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
          child: Column(
            children: [
              Image.asset("assets/privacy_policy_image.png"),
              const SizedBox(
                height: 20,
              ),
              Text(
                "Privacy Policy",
                style: GoogleFonts.poppins(
                    fontSize: 20.0, // Customize the font size
                    fontWeight: FontWeight.w600,
                    color: Colors.white // Customize the font weight
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "On this page, We regards your information significant and provide you what information we collect and how we use it to personalize and continually improve your experience.",
                  style: GoogleFonts.poppins(
                      fontSize: 13.0, // Customize the font size
                      fontWeight: FontWeight.w400,
                      color: Colors.white // Customize the font weight
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                width: 300, // Set the width of the container as needed
                padding: const EdgeInsets.all(10.0),
                decoration: const BoxDecoration(),
                child: Column(
                  children: [
                    Text(
                      'Information We Collect',
                      style: GoogleFonts.poppins(
                          fontSize: 20.0, // Customize the font size
                          fontWeight: FontWeight.w500,
                          color: Colors.white // Customize the font weight
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                        height:
                        10.0), // Add some space between heading and paragraph
                    Align(
                      child: Text(
                        'A.   Personal Information. Personal Information is not collected by us as. Personal Information is information that identifies you or another person, such as your first name and last name, your physical addresses, email addresses, telephone, fax, SSN, information which is being stored within your device.',
                        style: GoogleFonts.poppins(
                            fontSize: 13.0, // Customize the font size
                            fontWeight: FontWeight.w400,
                            color: Colors.white // Customize the font weight
                        ),
                      ),
                    ),
                    const SizedBox(
                        height:
                        20.0), // Add some space between heading and paragraph
                    Align(
                      child: Text(
                        "B.   Non-personal Information. Your non-personal information is collected by us when you visit our website. Information you provide. We may collect your information when you communicate with us or you provide us with the information.We are only getting your mobile device Id.How We Use Information.",
                        style: GoogleFonts.poppins(
                            fontSize: 13.0, // Customize the font size
                            fontWeight: FontWeight.w400,
                            color: Colors.white // Customize the font weight
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 300, // Set the width of the container as needed
                padding: const EdgeInsets.all(10.0),
                decoration: const BoxDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How We Use Information',
                      style: GoogleFonts.poppins(
                          fontSize: 20.0, // Customize the font size
                          fontWeight: FontWeight.w400,
                          color: Colors.white // Customize the font weight
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                        height:
                        20.0), // Add some space between heading and paragraph
                    Align(
                      child: Text(
                        "A.   Personal Information. We do not store any of your's personal information and therefore we do not disclose any of your Personal Information.",
                        style: GoogleFonts.poppins(
                            fontSize: 13.0, // Customize the font size
                            fontWeight: FontWeight.w400,
                            color: Colors.white // Customize the font weight
                        ),
                      ),
                    ),
                    const SizedBox(
                        height:
                        20.0), // Add some space between heading and paragraph
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "B.   Non-Personal Information. We neither sell, trade, nor otherwise transfer your information to the outside parties. Your Non-Personal Information is not combined with Personal Information by us(such as combining your name with your unique User Device number).",
                        style: GoogleFonts.poppins(
                            fontSize: 13.0, // Customize the font size
                            fontWeight: FontWeight.w400,
                            color: Colors.white // Customize the font weight
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      "C.   We will use Device Number for updating/deleting GCMkey from our app's database.",
                      style: GoogleFonts.poppins(
                          fontSize: 13.0, // Customize the font size
                          fontWeight: FontWeight.w400,
                          color: Colors.white // Customize the font weight
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      " D.   Legal Reasons We will access, use or disclose your information with other organizations or entities keeping in mind any applicable law, regulation, legal process or enforceable governmental request; detect, prevent, or otherwise fraud, security or technical issues; protect against harm to the rights, property or safety of our company, our users or the public as required or permitted by law",
                      style: GoogleFonts.poppins(
                          fontSize: 13.0, // Customize the font size
                          fontWeight: FontWeight.w400,
                          color: Colors.white // Customize the font weight
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      width: 300, // Set the width of the container as needed
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security',
                            style: GoogleFonts.poppins(
                                fontSize: 20.0, // Customize the font size
                                fontWeight: FontWeight.w400,
                                color: Colors.white // Customize the font weight
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                              height:
                              20.0), // Add some space between heading and paragraph
                          Text(
                            'A.   Our company is very concerned about safeguarding the confidentiality of your information. We do not collect Personal Information, and we employ administrative, physical and electronic measures designed to protect your Non-Personal Information from any kind of unauthorized access and use. ',
                            style: GoogleFonts.poppins(
                                fontSize: 13.0, // Customize the font size
                                fontWeight: FontWeight.w400,
                                color: Colors.white // Customize the font weight
                            ),
                          ),
                          const SizedBox(
                              height:
                              20.0), // Add some space between heading and paragraph
                          Text(
                            "B.   Please be aware that no security measures that we take to protect your information is absolutely guaranteed to avoid unauthorized access or use of your Non-Personal Information which is impenetrable.",
                            style: GoogleFonts.poppins(
                                fontSize: 13.0, // Customize the font size
                                fontWeight: FontWeight.w400,
                                color: Colors.white // Customize the font weight
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 300, // Set the width of the container as needed
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensitive Information',
                            style: GoogleFonts.poppins(
                                fontSize: 20.0, // Customize the font size
                                fontWeight: FontWeight.w500,
                                color: Colors.white // Customize the font weight
                            ),
                          ),
                          const SizedBox(
                              height:
                              20.0), // Add some space between heading and paragraph
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'We request that you not send us, and you not disclose, any sensitive Personal Information (e.g., information related to racial or ethnic origin, political opinions, religion or other beliefs, health, sexual orientation, criminal background or membership in past organizations, including trade union memberships) on or through an Application, the Services or the Site or otherwise to us.',
                              style: GoogleFonts.poppins(
                                  fontSize: 13.0, // Customize the font size
                                  fontWeight: FontWeight.w400,
                                  color:
                                  Colors.white // Customize the font weight
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 300, // Set the width of the container as needed
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Children',
                            style: GoogleFonts.poppins(
                                fontSize: 20.0, // Customize the font size
                                fontWeight: FontWeight.w500,
                                color: Colors.white // Customize the font weight
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                              height:
                              15.0), // Add some space between heading and paragraph
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'We do not provide service focus on Children. Therefore if you are under 18, you may visit our website when you are with a parent or guardian.',
                              style: GoogleFonts.poppins(
                                  fontSize: 13.0, // Customize the font size
                                  fontWeight: FontWeight.w400,
                                  color:
                                  Colors.white // Customize the font weight
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 300, // Set the width of the container as needed
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Changes',
                            style: GoogleFonts.poppins(
                                fontSize: 20.0, // Customize the font size
                                fontWeight: FontWeight.w500,
                                color: Colors.white // Customize the font weight
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                              height:
                              20.0), // Add some space between heading and paragraph
                          Align(
                            // alignment: Alignment.center,
                            child: Text(
                              'Our Privacy Policy may change which will not reduce your rights under this Privacy Policy from time to time, we will post any privacy policy changes on this page, so please review it on regular intervals. If you do not agree to any modifications to this Policy, your could immediately stop all use of all the Services. Your continued use of the Site following the posting of any modifications to this Policy will constitute your acceptance of the revised Policy. Please note that none of our employees or agents has the authority to vary any of our Policies.',
                              style: GoogleFonts.poppins(
                                  fontSize: 13.0, // Customize the font size
                                  fontWeight: FontWeight.w400,
                                  color:
                                  Colors.white // Customize the font weight
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
