import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


class ShareDevice extends StatefulWidget {
  final int? carID;
  final String? deviceName;
  const ShareDevice({super.key, this.carID, this.deviceName});

  @override
  State<ShareDevice> createState() => _AllVehicleLiveState();
}

class _AllVehicleLiveState extends State<ShareDevice> {

  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.1,
        backgroundColor: Colors.blueGrey.shade900,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Share Device',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body:Container()
    );
  }
}


