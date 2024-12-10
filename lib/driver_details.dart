import 'package:credence/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DriverDetails extends StatefulWidget {
  const DriverDetails({Key? key}) : super(key: key);

  @override
  State<DriverDetails> createState() => _DriverDetailsState();
}

class _DriverDetailsState extends State<DriverDetails> {
  String selectedGender = '';
  int selectedAge = 18; // Added age field

  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2050),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  DateTime? selectedDate2;

  Future<void> _selectDate2(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate2 ?? DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2050),
    );

    if (picked != null && picked != selectedDate2) {
      setState(() {
        selectedDate2 = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy');
    final dateFormat2 = DateFormat('MM/yyyy');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.1,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Dashboard(
                          userId: 0,
                        )));
              },
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
              ),
            ),
            title: Text(
              "Driver Details",
              style: GoogleFonts.roboto(color: Colors.black),
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Card(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Enter First Name",
                              style: GoogleFonts.poppins(fontSize: 20),
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                10.0), // Adjust the curve as needed
                            border: Border.all(
                              color: Colors.black,
                              width: 2.0, // Adjust the border width as needed
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Adjust padding as needed
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'First Name',
                              border: InputBorder
                                  .none, // Remove the default TextField border
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Enter Last Name",
                              style: GoogleFonts.poppins(fontSize: 20),
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                10.0), // Adjust the curve as needed
                            border: Border.all(
                              color: Colors.black,
                              width: 2.0, // Adjust the border width as needed
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Adjust padding as needed
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Last Name',
                              border: InputBorder
                                  .none, // Remove the default TextField border
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Choose your date of birth",
                              style: GoogleFonts.poppins(fontSize: 20),
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.calendar_today,
                                    color: Colors.grey),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      selectedDate == null
                                          ? 'Select Date of Birth'
                                          : dateFormat.format(selectedDate!),
                                      style: const TextStyle(fontSize: 18.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2.0,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: selectedGender,
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedGender = newValue!;
                                  });
                                },
                                items: <String>[
                                  '',
                                  'Male',
                                  'Female',
                                  'Other'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 18.0),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Selected Gender: $selectedGender',
                                style: const TextStyle(fontSize: 14.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Added age field
                      const SizedBox(height: 18), // Add spacing
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2.0,
                                ),
                              ),
                              child: DropdownButton<int>(
                                value: selectedAge,
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedAge = newValue!;
                                  });
                                },
                                items: List.generate(100, (index) => index + 1)
                                    .map<DropdownMenuItem<int>>((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(
                                      value.toString(),
                                      style: const TextStyle(fontSize: 18.0),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Selected Age: $selectedAge',
                                style: const TextStyle(fontSize: 14.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Enter Mobile Number",
                            style: GoogleFonts.poppins(fontSize: 20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                10.0), // Adjust the curve as needed
                            border: Border.all(
                              color: Colors.black,
                              width: 2.0, // Adjust the border width as needed
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Adjust padding as needed
                          child: const TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Mobile Number',
                              border: InputBorder
                                  .none, // Remove the default TextField border
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Enter Aadhar Number",
                            style: GoogleFonts.poppins(fontSize: 20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                10.0), // Adjust the curve as needed
                            border: Border.all(
                              color: Colors.black,
                              width: 2.0, // Adjust the border width as needed
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Adjust padding as needed
                          child: const TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Aadhar Number',
                              border: InputBorder
                                  .none, // Remove the default TextField border
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Enter License Number",
                            style: GoogleFonts.poppins(fontSize: 20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                10.0), // Adjust the curve as needed
                            border: Border.all(
                              color: Colors.black,
                              width: 2.0, // Adjust the border width as needed
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Adjust padding as needed
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'License Number',
                              border: InputBorder
                                  .none, // Remove the default TextField border
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "License Validity",
                              style: GoogleFonts.poppins(fontSize: 20),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color:
                                            Colors.black), // Add a border
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Add rounded corners
                                      ),
                                      child: ListTile(
                                        title: const Text("From:"),
                                        subtitle: Text(selectedDate != null
                                            ? dateFormat2.format(selectedDate!)
                                            : "mm/yyyy"),
                                        onTap: () => _selectDate(context),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color:
                                            Colors.black), // Add a border
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Add rounded corners
                                      ),
                                      child: ListTile(
                                        title: const Text("To:"),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 10.0),
                                          child: Text(selectedDate2 != null
                                              ? dateFormat2
                                              .format(selectedDate2!)
                                              : "mm/yyyy"),
                                        ),
                                        onTap: () => _selectDate2(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const DriverDetails2()));
                            /* // Navigate to the next screen when the button is pressed
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Dashboard(),
                      ),
                    );*/
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              // Adjust the value as needed
                            ),
                            backgroundColor: const Color(0xff050513),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DriverDetails2 extends StatefulWidget {
  const DriverDetails2({super.key});

  @override
  State<DriverDetails2> createState() => _DriverDetails2State();
}

class _DriverDetails2State extends State<DriverDetails2> {
  final TextEditingController _textController = TextEditingController();
  List<String> lines = [];
  String selectedGender = '';
  int experience = 1; // Added age field

  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2050),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  DateTime? selectedDate2;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.1,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DriverDetails()));
              },
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
              ),
            ),
            title: Text(
              "Driver Details",
              style: GoogleFonts.roboto(color: Colors.black),
            ),
          ),
          body: SingleChildScrollView(
            child: SingleChildScrollView(
              child: Center(
                child: Card(
                  child: SizedBox(
                    width: 320,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Mediclaim Number",
                                style: GoogleFonts.poppins(fontSize: 20),
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  10.0), // Adjust the curve as needed
                              border: Border.all(
                                color: Colors.black,
                                width: 2.0, // Adjust the border width as needed
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0), // Adjust padding as needed
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: 'Medical no.',
                                border: InputBorder
                                    .none, // Remove the default TextField border
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Medical No. Expiry Date",
                                style: GoogleFonts.poppins(fontSize: 20),
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.calendar_today,
                                      color: Colors.grey),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        selectedDate == null
                                            ? 'Expiry Date'
                                            : dateFormat.format(selectedDate!),
                                        style: const TextStyle(fontSize: 18.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Life Insurance Number",
                                style: GoogleFonts.poppins(fontSize: 20),
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  10.0), // Adjust the curve as needed
                              border: Border.all(
                                color: Colors.black,
                                width: 2.0, // Adjust the border width as needed
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0), // Adjust padding as needed
                            child: const TextField(
                              decoration: InputDecoration(
                                hintText: 'life insurance no.',
                                border: InputBorder
                                    .none, // Remove the default TextField border
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Life Insurance no. Expiry Date",
                                style: GoogleFonts.poppins(fontSize: 20),
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.calendar_today,
                                      color: Colors.grey),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        selectedDate == null
                                            ? 'Expiry Date'
                                            : dateFormat.format(selectedDate!),
                                        style: const TextStyle(fontSize: 18.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Experience",
                                style: GoogleFonts.poppins(fontSize: 20),
                              )),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: DropdownButton<int>(
                                    value: experience,
                                    onChanged: (newValue) {
                                      setState(() {
                                        experience = newValue!;
                                      });
                                    },
                                    items:
                                    List.generate(100, (index) => index + 1)
                                        .map<DropdownMenuItem<int>>(
                                            (int value) {
                                          return DropdownMenuItem<int>(
                                            value: value,
                                            child: Text(
                                              value.toString(),
                                              style:
                                              const TextStyle(fontSize: 18.0),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              const Padding(
                                padding: EdgeInsets.only(left: 18.0),
                                /*child: Text(
                                'Selected Experience: $selectedAge',
                                style: TextStyle(fontSize: 14.0),
                              ),*/
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Salary",
                                style: GoogleFonts.poppins(fontSize: 20),
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    10.0), // Adjust the curve as needed
                                border: Border.all(
                                  color: Colors.black,
                                  width:
                                  2.0, // Adjust the border width as needed
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0), // Adjust padding as needed
                              child: const TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Salary',
                                  border: InputBorder
                                      .none, // Remove the default TextField border
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Address",
                                style: GoogleFonts.poppins(fontSize: 20),
                              )),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2.0,
                                ),
                              ),
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                              child: const TextField(
                                keyboardType: TextInputType.multiline,
                                maxLines: null, // Allow multiple lines
                                decoration: InputDecoration(
                                  hintText: 'Address',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                      const DriverDetails2()));
                              /* // Navigate to the next screen when the button is pressed
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Dashboard(),
                        ),
                      );*/
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                // Adjust the value as needed
                              ),
                              backgroundColor: const Color(0xff050513),
                            ),
                            child: const Text(
                              'Save',
                              style:
                              TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
