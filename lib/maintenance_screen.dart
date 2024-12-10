import 'dart:convert';
import 'package:credence/status_report.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path/path.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class MaintenanceScreen extends StatefulWidget {
  final int carId;
  final String carNumber;

  const MaintenanceScreen(
      {super.key, required this.carId, required this.carNumber});

  @override
  State<MaintenanceScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<MaintenanceScreen> {
  final storage = const FlutterSecureStorage();
  String driver_name = '';
  String phone_no = '';
  String driver_address = '';
  String License_no = '';
  String work_id = '0';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMaintenancer();
  }

  List<Map<String, dynamic>> driverDetailsList = [];

  Future<void> _fetchMaintenancer() async {
    final String maintenanceApi = dotenv.env['MAINTENANCE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(maintenanceApi),
          headers: {'Cookie': sessionCookies},
        );
        if (response.statusCode == 200) {
          setState(() {
            isLoading = false;
          });
          final List<dynamic> driverDetailsJson = json.decode(response.body);
          if (driverDetailsJson.isNotEmpty) {
            setState(() {
              driverDetailsList = driverDetailsJson.map((item) {
                return {
                  'id': item['id'].toString(),
                  'attribute': item['attributes']['geofance'] ?? '',
                  'name': item['name'],
                  'type': item['type'],
                  'start': item['start'].toString(),
                  'period': item['period'].toString(),
                };
              }).toList();
            });
          } else {
          }
        } else {
        }
      } catch (e) {
      }
    } else {
    }
  }

  Future<void> _generateTravellSummaryPdf(BuildContext context) async {
    final pdf = pw.Document();

    if (driverDetailsList == null || driverDetailsList.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Text(
              'No Data Here',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
      );
    } else {
      const int itemsPerPage = 20;
      int itemCount = driverDetailsList.length;

      // Loop to handle multiple pages
      for (int page = 0; page * itemsPerPage < itemCount; page++) {
        pdf.addPage(
          pw.Page(
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                // Display headers
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey,
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: <pw.Widget>[
                      pw.Text(
                        'Driver Summary',
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),

                // Display Driver Details in a table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey, width: 1),
                  columnWidths: {
                    0: pw.FractionColumnWidth(0.2),
                    1: pw.FractionColumnWidth(0.2),
                    2: pw.FractionColumnWidth(0.2),
                    3: pw.FractionColumnWidth(0.2),
                    4: pw.FractionColumnWidth(0.2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        _buildTableCell('Id'),
                        _buildTableCell('Name'),
                        _buildTableCell('Type'),
                        _buildTableCell('Start'),
                        _buildTableCell('Period'),
                      ],
                    ),
                    for (int i = page * itemsPerPage;
                    i < (page + 1) * itemsPerPage && i < itemCount;
                    i++)
                      pw.TableRow(
                        children: [
                          _buildTableCell(driverDetailsList[i]['id']),
                          _buildTableCell(driverDetailsList[i]['name']),
                          _buildTableCell(driverDetailsList[i]['type']),
                          _buildTableCell(driverDetailsList[i]['start']),
                          _buildTableCell(driverDetailsList[i]['period']),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Maintenance Details.pdf');
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravellSummaryPDFViewerScreen(file.path),
      ),
    );
  }

// Helper function to build table cells
  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8.0),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0.1,
        backgroundColor: Colors.black,
        title: Text(
          "Maintenance Details",
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white,
            ),
            // onPressed: () => _generateInvoicePdf(context),
            onPressed: () async {
              // await _fetchStatusLogAndUpdateQuery();
              _fetchMaintenancer();
              _generateTravellSummaryPdf(
                  context); // Generate PDF with fetched data
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.white,
            size: 50,
          ))
          :
      driverDetailsList.isNotEmpty ?
      ListView.builder(
        itemCount: driverDetailsList.length,
        itemBuilder: (context, index) {
          final driver = driverDetailsList[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height *
                  0.2, // Adjust the height as needed
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.grey.shade700),
                  color: Colors.grey.shade900,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(
                          0, 1), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Align items to the start
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Center items vertically
                      children: [
                        Text(
                          "Id :",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 15,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            driver['id'],
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Align items to the start
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Center items vertically
                      children: [
                        Text(
                          "Name :",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 15,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            driver['name'],
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Align items to the start
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Center items vertically
                      children: [
                        Text(
                          "Type :",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 15,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            driver['type'],
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Align items to the start
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Center items vertically
                      children: [
                        Text(
                          "start :",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 15,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            driver['start'],
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .start, // Align items to the start
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Center items vertically
                      children: [
                        Text(
                          "Period :",
                          style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 15,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            driver['period'],
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ):
      Center(
        child: Text(
          "No Data Found",
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400),
        ),
      ),);
  }
}

class UpperCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
        size.width / 2, size.height + 20, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class GeofencingRouteMap extends StatefulWidget {
  const GeofencingRouteMap({super.key});

  @override
  _GeofencingRouteMapState createState() => _GeofencingRouteMapState();
}

class _GeofencingRouteMapState extends State<GeofencingRouteMap> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  LatLng point1 = const LatLng(37.7749, -122.4194);
  LatLng point2 = const LatLng(34.0522, -118.2437);

  @override
  void initState() {
    super.initState();
    _addMarkers();
    _fetchAndDisplayRoute();
  }

  Future<List<LatLng>> _fetchRoute(LatLng origin, LatLng destination) async {
    const apiKey =
        'AIzaSyAvHHoPKPwRFui0undeEUrz00-8w6qFtik'; // Replace with your API key
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points = data['routes'][0]['overview_polyline']['points'];
      return _decodePolyline(points);
    } else {
      throw Exception('Failed to load route');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int latitude = 0;
    int longitude = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      latitude += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlon = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      longitude += dlon;

      LatLng point = LatLng(
        (latitude / 1E5).toDouble(),
        (longitude / 1E5).toDouble(),
      );

      polyline.add(point);
    }

    return polyline;
  }

  void _addMarkers() {
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('point1'),
        position: point1,
      ));
      _markers.add(Marker(
        markerId: const MarkerId('point2'),
        position: point2,
      ));
    });
  }

  Future<void> _fetchAndDisplayRoute() async {
    try {
      List<LatLng> polylinePoints = await _fetchRoute(point1, point2);
      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: Colors.black,
          width: 5,
        ));
      });
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geofencing Route')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: point1,
          zoom: 6,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: _markers,
        polylines: _polylines,
      ),
    );
  }
}
