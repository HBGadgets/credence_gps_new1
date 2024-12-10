import 'package:credence/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.grey.shade700,
            body: Container(
              child: Padding(
                padding: EdgeInsets.only(top: 10.h, left: 1.w),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(4.h),
                      child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Image.asset("assets/signimag.png")),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    Text(
                      "Welcome",
                      style: GoogleFonts.poppins(
                          fontSize: 45,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    Text(
                      "this is a credence tracker used for tracking vehicles",
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: "poppins",
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 3.h,
                    ),
                    Container(
                      width: 63.w,
                      height: 8.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            // Adjust the value as needed
                          ),
                          backgroundColor: Color(0xff050513),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(width: 5.w),
                            Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: 19.sp, color: Colors.white),
                            ),
                            SizedBox(
                              width: 8.6.w,
                            ),
                            Icon(
                              Icons.arrow_forward_outlined,
                              size: 19.sp,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
