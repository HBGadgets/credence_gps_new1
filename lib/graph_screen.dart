import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GraphScreen extends StatelessWidget {
  final List<DataPoint> data = [
    DataPoint('Distance', 500),
    DataPoint('Duration', 5),
    DataPoint('Fuel', 30),
  ];

  GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Travel Summary',
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
      body: Padding(
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
            for (int i = 0; i < data.length; i++)
              TravelSummaryItem(data[i].category, data[i].value.toString()),
            const SizedBox(height: 20),
            const Text(
              'Graph',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class DataPoint {
  final String category;
  final double value;

  DataPoint(this.category, this.value);
}

class TravelSummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const TravelSummaryItem(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GraphScreen(),
  ));
}
