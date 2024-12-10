import 'dart:convert';
import 'package:credence/register_user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'new_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  double _loginYOffset = 1.0;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  int? userId; //
  bool _showError = false; // Track whether to show an error message
  bool _showEmptyMsgUser = false; // Track whether to show an error message
  bool _showEmptyMsgPass = false; // Track whether to show an error message
  bool _obscureText = true;
  String _helperText = '';
  bool isLoginLoader = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      usernameController.clear();
      passwordController.clear();
    });
    _loadUserData();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _loginYOffset = 0.0;
      });
    });
    _checkLoginState();
  }

  void _loadUserData() async {
    final email = await storage.read(key: "email");
    final password = await storage.read(key: "password");
    final userId = await storage.read(key: "userId");
    if (email != null && password != null && userId != null) {
      usernameController.text = email;
      passwordController.text = password;
      userId;
    }
  }

  Future<void> login() async {
    final String apiUrl = dotenv.env['LOGIN_API']!;
    final Map<String, dynamic> data = {
      "email": usernameController.text ?? '',
      "password": passwordController.text ?? '',
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: data,
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final int userId = responseData['id'];
      final String name = responseData['name'];
      final cookies = response.headers['set-cookie'];
      await storage.write(key: "sessionCookies", value: cookies);
      await storage.write(key: "userId", value: userId.toString());
      await storage.write(
          key: "password", value: passwordController.text.toString());
      await storage.write(
          key: "email", value: usernameController.text.toString());
      await storage.write(key: "sessionCookies", value: cookies);
      await storage.write(
          key: "username", value: usernameController.text.toString());
      await storage.write(
          key: "password", value: passwordController.text.toString());

      // Login successful
      Fluttertoast.showToast(
        msg: "Login Successful",
        toastLength: Toast.LENGTH_SHORT,
      );

      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => DevicesListScreen(
              userId: userId,
              username: usernameController.text,
              password: passwordController.text,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      });

      setState(() {
        isLoginLoader = false;
      });
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => DevicesListScreen(
      //       userId: userId,
      //     username: usernameController.text,
      //     password: passwordController.text,
      //   )),
      //       (Route<dynamic> route) => false,
      // );
    } else {
      setState(() {
        isLoginLoader = false;
        _showError = true;
      });
    }
  }

  double getTimeZoneOffset() {
    DateTime now = DateTime.now();
    Duration offset = now.timeZoneOffset;

    double offsetHours = offset.inHours.toDouble();
    double offsetMinutes = offset.inMinutes.remainder(60).toDouble() / 60.0;
    double totalOffset = offsetHours + offsetMinutes;
    return totalOffset;
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: AnimatedContainer(
                    height: 49.h,
                    width: 100.w,
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.fastLinearToSlowEaseIn,
                    transform: Matrix4.translationValues(0,
                        _loginYOffset * MediaQuery.of(context).size.height, 0),
                    color: const Color(0xffd5c9c9),
                    child: AnimatedContainer(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffd5c9c9).withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(
                                0, 1), // changes position of shadow
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 3000),
                      curve: Curves.fastLinearToSlowEaseIn,
                      transform: Matrix4.translationValues(
                          0,
                          _loginYOffset * MediaQuery.of(context).size.height,
                          0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
                                width: MediaQuery.of(context).size.width * 0.6,
                                // child: Image.asset("assets/logo_t.png")),
                                child: Image.asset("assets/login_Buso.png")),
                          ),
                          Text(
                            "Navigating towards a secured future!",
                            style: GoogleFonts.lusitana(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                if (_showError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "Incorrect username or password",
                      style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                SizedBox(height: 1.h),
                SizedBox(
                  width: 80.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showEmptyMsgUser || _showError
                                  ? Colors.red
                                  : Colors.grey.shade700,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showEmptyMsgUser ||_showError
                                  ? Colors.red
                                  : Colors.grey.shade700,
                            ),
                          ),
                          hintText: "Email Address",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w400,
                          ),
                          helperText: _showEmptyMsgUser
                              ? 'Email Address is required'
                              : '', // Set the helper text
                          helperStyle: const TextStyle(
                              color: Colors.red), // Customize helper text style
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText:
                            _obscureText, // This line makes the input hidden as bullets
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showEmptyMsgPass || _showError
                                  ? Colors.red
                                  : Colors.grey.shade700,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _showEmptyMsgPass ||_showError
                                  ? Colors.red
                                  : Colors.grey.shade700,
                            ),
                          ),
                          hintText: "Password",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w400,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          helperText:
                              _showEmptyMsgPass ? 'Password is required' : '',
                          helperStyle: const TextStyle(color: Colors.red),
                        ),
                      ),
                      SizedBox(height: 2.h),

                      SizedBox(
                        width: 80.w,
                        height: 7.h,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoginLoader = true;
                            });

                            setState(() {
                              if (usernameController.text.isEmpty) {
                                _showEmptyMsgUser = true;
                                isLoginLoader = false;
                                _helperText = 'Email Address is required';
                              } else {
                                _showEmptyMsgUser = false;
                                _helperText = ''; // Clear helper text if valid
                              }
                              if (passwordController.text.isEmpty) {
                                _showEmptyMsgPass = true;
                                isLoginLoader = false;
                              } else {
                                _showEmptyMsgPass = false;
                              }
                              if (!_showEmptyMsgUser && !_showEmptyMsgPass) {
                                login();
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            backgroundColor:  isLoginLoader == true  ?  Colors.orange.shade800 :
                            Colors.orange.shade600,
                          ),
                          child: isLoginLoader == true
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ))
                              : Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      // GestureDetector(
                      //   onTap: (){
                      //     Navigator.of(context).pushReplacement(
                      //       MaterialPageRoute(
                      //         builder: (context) => const RegisterUserScreen(),
                      //       ),
                      //     );
                      //   },
                      //   child: Container(
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(10.0),
                      //       child: Row(
                      //         mainAxisAlignment: MainAxisAlignment.end,
                      //         children: [
                      //           Text(
                      //             'New user?',
                      //             style: GoogleFonts.poppins(
                      //               color: Colors.grey.shade600,
                      //               fontSize: 14,
                      //               fontWeight: FontWeight.w500,
                      //             ),
                      //           ),
                      //           SizedBox(width: 1.h),
                      //           Text(
                      //             'Register',
                      //             style: GoogleFonts.poppins(
                      //               color: Colors.orange.shade800,
                      //               fontSize: 18,
                      //               fontWeight: FontWeight.w600,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _checkLoginState() async {
    final sessionCookies = await storage.read(key: "sessionCookies");
    print("sessionCookiesLogin${sessionCookies}");
    final userId = await storage.read(key: "userId");
    if (sessionCookies != null) {
      Navigator.pushAndRemoveUntil(
        context,
        // MaterialPageRoute(builder: (context) => Dashboard(userId: int.parse(userId!))),
        MaterialPageRoute(
            builder: (context) =>
                DevicesListScreen(userId: int.parse(userId ?? ""))),
        (Route<dynamic> route) => false,
      );
    }
  }
}
