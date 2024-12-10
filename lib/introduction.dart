import 'package:credence/introduction_2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class Introduction extends StatefulWidget {
  const Introduction({super.key});

  @override
  State<Introduction> createState() => _IntroductionState();
}

class _IntroductionState extends State<Introduction> {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.grey.shade700,
            // backgroundColor: Color(0xc5d5c9c9),
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric( horizontal: 3.h),
                child: Column(
                  children: [
                    // Image.asset("assets/register.png"),
                    SizedBox(
                        height: MediaQuery.of(context).size.height*0.52,
                        width: MediaQuery.of(context).size.width*0.7,
                        child: Image.asset("assets/gps_new.png")),
                    Text(
                      "Welcome",
                      style: GoogleFonts.poppins(
                          fontSize: 45.0, fontWeight: FontWeight.w600, color: Colors.white),
                      // style: TextStyle(
                      //     fontSize: 45,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.white),
                    ),
                    SizedBox(
                      height: 4.w,
                    ),
                    const Text(
                      "This is a credence tracker used for tracking vehicles",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "poppins",
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    SizedBox(
                      width: 50.w,
                      height: 5.h,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the next screen when the button is pressed
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const Introduction2(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          backgroundColor: const Color(0xff050513),
                        ),
                        child: const Text(
                          'Lets begin',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
    });
  }
}
