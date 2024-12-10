import 'package:credence/status_report.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'maintenance_screen.dart';

class StatusCard extends StatefulWidget {
  final String carNumber;
  final int carID;
  final String lastUpdate;
  final String odometer;
  final String address;
  final String imagePath;

  const StatusCard(
      {super.key,
        required this.address,
        required this.carNumber,
        required this.carID,
        required this.lastUpdate,
        required this.odometer,
        required this.imagePath});
  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  int daysDifference = 0;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now().subtract(const Duration(days: 14));

  final List<String> options = [
    'Status Report',
    'Travel Summary',
    // 'Idle Summary',
    'Stop Detailed Report',
    'Distance Report',
    'Vehicle Maintenance',
    // 'Vehicle Invoice'
    'Vehicle Analysis'
  ];

  @override
  void initState() {
    super.initState();
    _focusedDay = _selectedDay;
  }

  final List<IconData> dataIcons = [
    Icons.report_gmailerrorred,
    Icons.travel_explore,

    // Icons.power_settings_new,
    Icons.stop_circle_outlined,
    Icons.analytics_outlined,
    Icons.settings,
    Icons.receipt_long
  ];

  final List<String> imagePaths = [
    "assets/report_white.png",
    "assets/travel_report_white.png",
    "assets/stop_report_white.png",
    "assets/vehicle_invoice.png",
    "assets/vehicle_maintenance.png",
    // "assets/vehicle_invoice.png",
    "assets/vehicle_analysys.png",
  ];
  final List<Color> cardcolors = [
    Colors.green.shade200,
    Colors.blue.shade200,
    // Colors.orange.shade200,
    Colors.red.shade200,
    Colors.purple.shade200,
    Colors.cyanAccent.shade200,
    Colors.teal.shade200
  ];
  final List<Color> iconColors = [
    Colors.green,
    Colors.blue,
    // Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.cyan,
    Colors.teal
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8.0),
            ),
            child: AppBar(
              backgroundColor: Colors.black,
              elevation: 10,
              leading: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade700
                                .withOpacity(0.5), // Border color
                            width: 1.0,
                          )),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.white,
                    ),
                  )),
              title: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                      bottom: BorderSide(
                        color:
                        Colors.grey.shade700.withOpacity(0.5), // Border color
                        width: 1.0,
                      )),
                ),
                child: ListTile(
                  title: Text(
                    widget.carNumber,
                    style: GoogleFonts.robotoSlab(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.grey.shade400,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: GridView.builder(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 30.0,
                          mainAxisSpacing: 30.0,
                        ),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              switch (options[index]) {
                                case 'Status Report':
                                  navigateToStatusReport();
                                  break;
                                case 'Stop Detailed Report':
                                  navigateToStopDetailedSummary();
                                  break;
                                case 'Travel Summary':
                                  navigateToTravelSummary();
                                  break;
                              // case 'Idle Summary':
                              //   navigateToIdleSummary();
                              //   break;
                                case 'Vehicle Analysis':
                                  naivgateToVehicleAnalaysis();
                                  break;
                                case 'Vehicle Maintenance':
                                  navigateToVehicleMaintenance();
                                  break;
                                case 'Distance Report':
                                  navigateToVehicleDistanceReport();
                                  break;
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xD3000000),
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(imagePaths[
                                          index]), // Replace with your image path
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 23,
                                    right: 10,
                                    left: 10,
                                    child: Text(
                                      options[index],
                                      style: GoogleFonts.poppins(
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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

  void navigateToStatusReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusLog(
          carID: widget.carID,
          carNumber: widget.carNumber,
          // fromDate: _fromDate.toString(),
          // toDate: _toDate.toString(),
        ),
      ),
    );
  }

  void navigateToTravelSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelSummary(
            carID: widget.carID,
            carNumber: widget.carNumber,
            imagePath: widget.imagePath
          // fromDate: _fromDate.toString(),
          // toDate: _toDate.toString(),
        ),
      ),
    );
  }

  void navigateToIdleSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdleReport(
          carID: widget.carID,
          carNumber: widget.carNumber,
          // fromDate: _fromDate.toString(),
          // toDate: _toDate.toString(),
        ),
      ),
    );
  }

  // void navigateToVehicleInvoice(){
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) =>
  //           VehicleInvoice(
  //             carID: widget.carID,
  //             carNumber: widget.carNumber,
  //             // fromDate: _fromDate.toString(),
  //             // toDate: _toDate.toString(),
  //           ),
  //     ),
  //   );
  // }
  void navigateToVehicleDistanceReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DistanceReport(
            carID: widget.carID,
            carNumber: widget.carNumber,
            imagePath: widget.imagePath
          // fromDate: _fromDate.toString(),
          // toDate: _toDate.toString(),
        ),
      ),
    );
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) =>
    //           VehicleInvoice(
    //             carID: widget.carID,
    //             carNumber: widget.carNumber,
    //             // fromDate: _fromDate.toString(),
    //             // toDate: _toDate.toString(),
    //           ),
    //     ),
    //   );
  }

  void navigateToVehicleMaintenance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceScreen(
          carNumber: widget.carNumber,
          carId: widget.carID,
        ),
        // builder: (context) => GeofencingRouteMap(),
      ),
    );

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => VehicleMaintenance(
    //       carID: widget.carID,
    //       carNumber: widget.carNumber,
    //       // fromDate: _fromDate.toString(),
    //       // toDate: _toDate.toString(),
    //     ),
    //   ),
    // );
  }

  void naivgateToVehicleAnalaysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
                  VehicleInvoice(
                    carID: widget.carID,
                    carNumber: widget.carNumber,
                    // fromDate: _fromDate.toString(),
                    // toDate: _toDate.toString(),
                  ),
        //     VehicleAnalysis(
        //   carID: widget.carID,
        //   carNumber: widget.carNumber,
        //   // fromDate: _fromDate.toString(),
        //   // toDate: _toDate.toString(),
        // ),
      ),
    );
  }

  void navigateToStopDetailedSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StopReport(
            carID: widget.carID,
            carNumber: widget.carNumber,
            imagePath: widget.imagePath
          // fromDate: _fromDate.toString(),
          // toDate: _toDate.toString(),
        ),
      ),
    );
  }
}

class CardSelection extends StatelessWidget {
  final String title;
  final DateTime? date;
  final ValueChanged<String> onDateSelected;

  const CardSelection({
    Key? key,
    required this.title,
    required this.date,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onDateSelected(title);
      },
      child: Card(
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade800,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date != null
                        ? '${date!.day}/${date!.month}/${date!.year}'
                        : 'Select Date',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
