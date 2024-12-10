import 'package:credence/register.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class Introduction2 extends StatefulWidget {
  const Introduction2({Key? key}) : super(key: key);

  @override
  State<Introduction2> createState() => _Introduction2State();
}

class _Introduction2State extends State<Introduction2> {
  double _loginYOffset = 1.0;
  final PageController _pageController = PageController(initialPage: 0);

  final int _numPages = 3;
  int _currentPage = 0;

  final List<ScreenContent> _screenContents = [
    ScreenContent(
      title: "Navigating towards a secured futures",
      description: "Credence Tracker",
      imageAsset: "assets/intro1.png",
    ),
    ScreenContent(
      title: "Navigating towards a secured futures",
      description: "Track the journey",
      imageAsset: "assets/intro2.png",
    ),
    ScreenContent(
      title: "Navigating towards a secured futures",
      description: "Stay updated & Manage your bussiness",
      imageAsset: "assets/intro3.png",
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Add a delay to start the animation after a certain time
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _loginYOffset = 0.0; // Slide the login screen in from the top
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return  Sizer(builder: (context, orientation, deviceType)
    {
      return Scaffold(
        backgroundColor: Colors.grey.shade700,
        appBar: AppBar(
          elevation: 0.1,
          backgroundColor: Colors.grey.shade700,

          // actions: [
          //   GestureDetector(onTap: () {
          //     Navigator.push(context,
          //         MaterialPageRoute(builder: (context) => const Register()));
          //   },
          //       child: Padding(
          //         padding: const EdgeInsets.all(18.0),
          //         child: Text("skip",
          //           style: GoogleFonts.poppins(color: Colors.white),),
          //       ))
          // ],
        ),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 2000),
          curve: Curves.fastLinearToSlowEaseIn,
          transform: Matrix4.translationValues(
              0, _loginYOffset * MediaQuery
              .of(context)
              .size
              .height, 0),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _numPages,
            itemBuilder: (context, index) {
              return buildScreen(_screenContents[index]);
            },
          ),
        ),
        bottomNavigationBar: SingleChildScrollView(
          child: SizedBox(
            height: 3.h,
            child: BottomAppBar(
              color:Colors.grey.shade700,
              child: Row(
                children: [
                  Padding(
                    padding:  EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: List<Widget>.generate(_numPages, (
                          int index) {
                        return Container(
                          width: 3.w,
                          height: 2.h,
                          margin: EdgeInsets.symmetric(horizontal: 1.0.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.blue
                                : Colors.grey.withOpacity(0.6),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    );}

  Widget buildScreen(ScreenContent content) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 2000),
      curve: Curves.fastLinearToSlowEaseIn,
      transform: Matrix4.translationValues(
        _currentPage > 0 ? -_loginYOffset * MediaQuery.of(context).size.width : 0,
        0,
        0,
      ),
      child: Padding(
        padding:  EdgeInsets.symmetric(vertical: 3.h, horizontal: 10.w),
        child: Column(
          children: [
            Text(
              content.description,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white
              ),
            ),
            SizedBox(height: 0.2.h),
            SizedBox(
                height: MediaQuery.of(context).size.height*0.31,
                width: MediaQuery.of(context).size.width*0.7,
                child: Image.asset(content.imageAsset)),
            SizedBox(height: 5.h),
            Text(
              content.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontFamily: "poppins",
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 65,
                      width: 65,
                      decoration:  BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(22),
                        // border: Border.all(color: Colors.white,width: 2)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          alignment: Alignment.center,
                          decoration:  BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white,width: 4)
                          ),
                          child: IconButton(
                            icon: Icon(
                              _currentPage == _numPages - 1
                                  ? Icons.arrow_forward
                                  : Icons.arrow_forward,
                              size: 22,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (_currentPage == _numPages - 1) {
                                // Navigate to Register.dart when on the last screen
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) => const Register()),
                                );
                              } else {
                                // Go to the next screen
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    // Container(
                    //   height: 10.h,
                    //   width:20.w,
                    //   decoration: const BoxDecoration(
                    //     color: Colors.black,
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: Container(
                    //     height: 7.h,
                    //     width:15.w,
                    //     decoration:  BoxDecoration(
                    //       color: Colors.black,
                    //       shape: BoxShape.circle,
                    //       border: Border.all(color: Colors.white,width: 2)
                    //     ),
                    //     child: IconButton(
                    //       icon: Icon(
                    //         _currentPage == _numPages - 1
                    //             ? Icons.chevron_right
                    //             : Icons.chevron_right,
                    //         size: 40,
                    //         color: Colors.white,
                    //       ),
                    //       onPressed: () {
                    //         if (_currentPage == _numPages - 1) {
                    //           // Navigate to Register.dart when on the last screen
                    //           Navigator.of(context).pushReplacement(
                    //             MaterialPageRoute(builder: (context) => const Register()),
                    //           );
                    //         } else {
                    //           // Go to the next screen
                    //           _pageController.nextPage(
                    //             duration: const Duration(milliseconds: 500),
                    //             curve: Curves.easeInOut,
                    //           );
                    //         }
                    //       },
                    //     ),
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: GestureDetector(onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const Register()));
                      },
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Text("skip",
                              style: GoogleFonts.poppins(color: Colors.white,fontSize: 16),),
                          )),
                    )
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}

class ScreenContent {
  final String title;
  final String description;
  final String imageAsset;

  ScreenContent({
    required this.title,
    required this.description,
    required this.imageAsset,
  });
}
