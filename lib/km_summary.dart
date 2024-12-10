import 'package:credence/graph_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KmSummary extends StatefulWidget {
  const KmSummary({super.key});

  @override
  State<KmSummary> createState() => _KmSummaryState();
}

class _KmSummaryState extends State<KmSummary> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.1,
            backgroundColor: Colors.white,
            title: Text(
              "KM Summary",
              style: GoogleFonts.poppins(color: Colors.black),
            ),
            leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.black,
                )),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0x5c0f52b9),
                  ),
                  child: Center(
                    child: Text(
                      "Today",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 300,
                    height: 200, // Adjust the width as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0), // Curved sides
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => GraphScreen()));
                      },
                      child: Card(
                        elevation: 0, // No shadow for the inner card
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              20.0), // Curved sides for inner card
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'MH-01-HD-1596',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 2,
                                width: double.infinity,
                                color: Colors.black, // Black divider
                                margin: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              const TravelSummaryItem('Total Distance', '500 km'),
                              const TravelSummaryItem('Total Duration', '5 hours'),
                              const TravelSummaryItem('Fuel Consumed', '30 liters'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 300,
                    height: 200, // Adjust the width as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0), // Curved sides
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0, // No shadow for the inner card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Curved sides for inner card
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'MH-14-D-5665',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 2,
                              width: double.infinity,
                              color: Colors.black, // Black divider
                              margin: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            const TravelSummaryItem('Total Distance', '500 km'),
                            const TravelSummaryItem('Total Duration', '5 hours'),
                            const TravelSummaryItem('Fuel Consumed', '30 liters'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0x5c0f52b9),
                  ),
                  child: Center(
                    child: Text(
                      "Yesterday",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 300,
                    height: 200, // Adjust the width as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0), // Curved sides
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0, // No shadow for the inner card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Curved sides for inner card
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'MH-01-HD-1596',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 2,
                              width: double.infinity,
                              color: Colors.black, // Black divider
                              margin: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            const TravelSummaryItem('Total Distance', '500 km'),
                            const TravelSummaryItem('Total Duration', '5 hours'),
                            const TravelSummaryItem('Fuel Consumed', '30 liters'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 300,
                    height: 200, // Adjust the width as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0), // Curved sides
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 0, // No shadow for the inner card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Curved sides for inner card
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'MH-14-D-5665',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 2,
                              width: double.infinity,
                              color: Colors.black, // Black divider
                              margin: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            const TravelSummaryItem('Total Distance', '500 km'),
                            const TravelSummaryItem('Total Duration', '5 hours'),
                            const TravelSummaryItem('Fuel Consumed', '30 liters'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

class TravelSummaryItem extends StatelessWidget {
  final String title;
  final String value;

  const TravelSummaryItem(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(value),
      ],
    );
  }
}
