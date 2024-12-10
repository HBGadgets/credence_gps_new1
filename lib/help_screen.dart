import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gsheets/gsheets.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class HelpScreen extends StatefulWidget {
  final int? userId;
  const HelpScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final storage = const FlutterSecureStorage();
  bool isGridMode = true; // Initially, set to grid mode

  void toggleGridMode() {
    setState(() {
      isGridMode = !isGridMode;
    });
  }

  void _performLogout(BuildContext context) async {
    // Clear session data (e.g., session cookies).
    const storage = FlutterSecureStorage();
    await storage.delete(key: "sessionCookies");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
    Fluttertoast.showToast(
      msg: "Deleted account successfully",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 1),
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.question_mark_sharp,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Are you sure?',
                style: GoogleFonts.poppins(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          content: Text(
            'Do you really want to delete your account? You will not be able to undo this action.',
            style: GoogleFonts.poppins(
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      side: const BorderSide(color: Colors.red),
                    ),
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      side: const BorderSide(color: Colors.black),
                    ),
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () {
                    userData();
                  },
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.white, // Grey out text when disabled
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> userData() async {
    final String userApi = dotenv.env['USERS_API']!;
    final String apiUrl = "$userApi/${widget.userId}";
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );
      print("statuscode ${response.statusCode}");
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Account deleted successfully",
          toastLength: Toast.LENGTH_SHORT,
        );
        await storage.delete(key: "sessionCookies");
        await storage.deleteAll();
        print("User account has been deleted from the device.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      } else if (response.statusCode == 204) {
        Fluttertoast.showToast(
          msg: "Account deleted successfully",
          toastLength: Toast.LENGTH_SHORT,
        );
        await storage.delete(key: "sessionCookies");
        await storage.deleteAll();
        print("User account has been deleted from the device.");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      } else {
        print("Failed to get user data. Status code: ${response.statusCode}");
      }
    } else {
      print("No session cookies found.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(8.0),
          ),
          child: AppBar(
            centerTitle: false,
            elevation: 0.0,
            title: Text(
              "Help and support",
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
            backgroundColor: Colors.black,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            actions: [
              if (Platform.isIOS)
                TextButton(
                    onPressed: () {
                      showLogoutDialog(context);
                    },
                    child: const Text(
                      "Delete Account",
                      style: TextStyle(color: Colors.white),
                    ))
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How can we help with you ?',
              style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            const Card(
              color: Colors.white,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      launch("tel:+91 9112000100");
                    },
                    child: const HelpOptionContainer(
                      icon: Icons.call,
                      label: 'Call',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      launch("sms:+91 8857971089");
                    },
                    child: const HelpOptionContainer(
                      icon: Icons.message,
                      label: 'Message',
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TicketForm()));
                    },
                    child: const HelpOptionContainer(
                      icon: Icons.report,
                      label: 'Raise Ticket',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              "Frequently Asked Question",
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                children: const [
                  FAQItem(
                    question: 'What is Credence ?',
                    answer: 'Credence is tracking application .',
                  ),
                  FAQItem(
                    question: 'Does it has live Map ?',
                    answer: 'Yes , it has live map .',
                  ),
                  // Add more FAQ items as needed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpOptionContainer extends StatelessWidget {
  final IconData icon;
  final String label;

  const HelpOptionContainer(
      {super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 100,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40.0,
            color: Colors.white,
          ),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({super.key, required this.question, required this.answer});

  @override
  _FAQItemState createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        widget.question,
        style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(widget.answer),
        ),
      ],
    );
  }
}

class TicketForm extends StatefulWidget {
  const TicketForm({super.key});

  @override
  _TicketFormState createState() => _TicketFormState();
}

class _TicketFormState extends State<TicketForm> {
  final TextEditingController _issueController = TextEditingController();
  String _selectedCategory = 'General'; // Default category

  Future<void> uploadIssue(String issue, String category) async {
    final gsheets = GSheets('assets/ticket-416310-7e444859d4f8.json');
    try {
      final spreadsheet = await gsheets.spreadsheet(
          'https://docs.google.com/spreadsheets/d/1TYtznhNI7TqxJX3RDNVE6e_EOzVMWdyWw15Y43pqBLU');

      // Use the first worksheet
      final sheet = spreadsheet.worksheetByTitle('Sheet1');

      // Add a new row with the issue and category
      await sheet!.values.insertRow(1, [issue, category]);
    } catch (exc) {
      // Return an error response if the above code fails
      var result = {"success": false, "message": exc};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise a Ticket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Category:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: <String>['General', 'Technical', 'Billing', 'Other']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Describe Your Issue:',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _issueController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Enter your issue here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                String issue = _issueController.text.trim();
                if (issue.isNotEmpty) {
                  // Upload the issue to Google Sheets
                  await uploadIssue(issue, _selectedCategory);
                  Navigator.pop(context); // Close the ticket form
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: const Text('Please describe your issue.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }
}
