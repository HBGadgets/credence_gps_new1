import 'dart:convert';
import 'package:credence/provider/notification_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationScreen extends StatefulWidget {
  final String carNumber;
  final int carID;

  const NotificationScreen(
      {Key? key, required this.carNumber, required this.carID});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> carDetailsList = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  bool showFilter =
  false; // Variable to control the visibility of the filter card
  String? lastNotifiedEvent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    EventNotification();
  }

// Initialize notifications
  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }


  Future<void> EventNotification() async {
    // final String notificationApi = dotenv.env['NOTIFICATION_API_NEW']!;
    final String notificationApi = dotenv.env['NOTIFICATION_API']!;
    final String positionApi = dotenv.env['LIVE_API']!;
    DateTime currentDate = DateTime.now();
    String newDate = DateFormat("yyyy-MM-dd").format(currentDate);
    // Calculate yesterday's date by subtracting one day from the current date
    DateTime yesterday = currentDate.subtract(const Duration(days: 1));

    // Format yesterday's date
    String yesterDayDate = DateFormat("yyyy-MM-dd").format(yesterday);
    final String apiUrl =
        "$notificationApi?deviceId=${widget.carID}&from=${yesterDayDate}T18:30:00.000Z&to=${newDate}T18:28:59.999Z&type=allEvents";

    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(apiUrl),
        // Uri.parse(notificationApi),
        headers: {
          'Cookie': sessionCookies,
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        final jsonResponse = json.decode(response.body);
        String jsonsDataString = response.body.toString();
        setState(() {
          carDetailsList = List<Map<String, dynamic>>.from(jsonResponse);
        });

        // Show alert and push notification for a new event
        if (carDetailsList.isNotEmpty) {
          final latestEvent = jsonResponse.last;
          final String eventType = latestEvent['type'];
          String eventTime = latestEvent['eventTime'];

          // Convert event time to Indian local time by adding 5 hours and 30 minutes

          DateTime lastUpdateTime = DateTime.parse(eventTime);
          DateTime localTime = lastUpdateTime.toLocal();
          DateTime updatedTime = localTime.add(const Duration(hours: 5, minutes: 30));
          final formattedTimeAletr = DateFormat.yMMMMd('en_US').add_jm().format(updatedTime);
          DateTime indianEventTime = DateTime.parse(eventTime)
              .add(const Duration(hours: 5, minutes: 30));
          String indianFormattedEventTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(indianEventTime);

          final String eventMessage =
              '$eventType occurred at $formattedTimeAletr';

          // Check if the latest event is different from the last notified event
          if (lastNotifiedEvent != eventMessage) {
            // Assuming you want to show notifications for the latest event, adjust this part as needed
            const headerMessage = 'Latest Event Notification';

            // Show the notification
            showNotification(eventMessage, headerMessage);

            // Update the last notified event
            lastNotifiedEvent = eventMessage;

          }
        }
      } else {
        // Handle error if the request is not successful
      }
    }
  }


  void showNotification(String message, String header) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      header,
      message,
      platformChannelSpecifics,
      payload: 'item x',
    );
    Provider.of<NotificationProvider>(context, listen: false)
        .setNewNotification('New Event', message);
  }

  double convertToDecimal(int coordinate) {
    // Assuming a conversion factor of 1,000,000
    double decimalCoordinate = coordinate / 1000000.0;
    return decimalCoordinate;
  }

  void openGoogleMaps(double latitude, double longitude) async {
    String url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          elevation: 0.1,
          backgroundColor: Colors.black,
          leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                      bottom: BorderSide(
                        color:
                        Colors.grey.shade700.withOpacity(0.5), // Border color
                        width: 1.0,
                      )),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.white,
                ),
              )),
          title: Text(
            "Notifications",
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ),
        body: isLoading
            ? Center(
            child: LoadingAnimationWidget.threeArchedCircle(
              color: Colors.white,
              size: 50,
            ))
            : ListView.builder(
          itemCount: carDetailsList.length,
          itemBuilder: (context, index) {
            final carDetails = carDetailsList[index];
            final lastUpdate = carDetails['eventTime'];
            final notId = carDetails['id'];
            String deviceType =
            carDetails['type'] == "deviceOnline"
                ? "vehicle has started!"
                : carDetails['type'] == "deviceStopped"
                ? "vehicle has stopped!"
                :carDetails['type'] == "geofenceEnter"
                ? "Geofence entered"
                :carDetails['type'] == "geofenceExit"
                ? "Geofence exited"
                :  carDetails['type'] == "deviceMoving"
                ? "Device moving"

                : carDetails['type'] == "commandResult"
                ? "Command Result"
                : carDetails['type'] == "deviceUnknown"
                ? "Device Unknown"
                :carDetails['type'] == "deviceOffline"
                ? "Device Offline"
                : carDetails['type'] == "deviceInactive"
                ? "Device Inactive"
                :carDetails['type'] == "queuedCommandSent"
                ? "Queued Command Sent"
                : carDetails['type'] == "deviceOverspeed"
                ? "Device Overspeed"
                : carDetails['type'] == "deviceFuelDrop"
                ? "Device Fuel Drop"
                : carDetails['type'] == "deviceFuelIncrease"
                ? "Device Fuel Increase"
                : carDetails['type'] == "alarm"
                ? "Alarm"
                : carDetails['type'] == "ignitionOn"
                ? "Ignition On"
                : carDetails['type'] == "ignitionOff"
                ? "Ignition Off"
                :carDetails['type'] == "maintenance"
                ? "Maintenance"
                :carDetails['type'] == "textMessage"
                ? "Text Message"
                : carDetails['type'] == "driverChanged"
                ? "Driver Changed"
                : carDetails['type'] == "media"
                ? "Media"
                : "Not Found";
            DateTime lastUpdateTime = DateTime.parse(lastUpdate);
            DateTime localTime = lastUpdateTime.toLocal();
            DateTime updatedTime = localTime.add(const Duration(hours: 5, minutes: 30));
            final formattedTime = DateFormat.yMMMMd('en_US').add_jm().format(updatedTime);
            return InkWell(
              onTap: () {
                openGoogleMaps(
                  convertToDecimal(carDetails['y']),
                  convertToDecimal(carDetails['x']),
                );
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.135,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 1,
                          offset: const Offset(
                              0, 1), // changes position of shadow
                        ),
                      ],
                      borderRadius: BorderRadius.circular(
                          10.0), // Adjust the value as needed
                      color: Colors.grey.shade400,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child:
                            Icon(
                                carDetails['type'] == "deviceOnline"
                                    ? Icons.key
                                    : carDetails['type'] == "deviceStopped"
                                    ? Icons.directions_car
                                    :carDetails['type'] == "geofenceEnter"
                                    ? Icons.pin_drop_rounded
                                    :carDetails['type'] == "geofenceExit"
                                    ? Icons.pin_drop_rounded
                                    :  carDetails['type'] == "deviceMoving"
                                    ?Icons.directions_car
                                    : carDetails['type'] == "commandResult"
                                    ? Icons.keyboard_command_key
                                    : carDetails['type'] == "deviceUnknown"
                                    ?Icons.device_unknown_sharp
                                    :carDetails['type'] == "deviceOffline"
                                    ? Icons.key
                                    : carDetails['type'] == "deviceInactive"
                                    ? Icons.local_activity
                                    :carDetails['type'] == "queuedCommandSent"
                                    ? Icons.keyboard_command_key
                                    : carDetails['type'] == "deviceOverspeed"
                                    ? Icons.speed
                                    : carDetails['type'] == "deviceFuelDrop"
                                    ?Icons.oil_barrel
                                    : carDetails['type'] == "deviceFuelIncrease"
                                    ? Icons.oil_barrel
                                    : carDetails['type'] == "alarm"
                                    ?Icons.directions_car
                                    : carDetails['type'] == "ignitionOn"
                                    ? Icons.directions_car
                                    : carDetails['type'] == "ignitionOff"
                                    ? Icons.directions_car
                                    :carDetails['type'] == "maintenance"
                                    ?Icons.directions_car
                                    :carDetails['type'] == "textMessage"
                                    ? Icons.directions_car
                                    : carDetails['type'] == "driverChanged"
                                    ? Icons.directions_car
                                    : carDetails['type'] == "media"
                                    ? Icons.directions_car
                                    : Icons.directions_car
                              //
                              // Icons.directions_car,
                              // color:
                              // carDetails['type'] == "deviceOnline"
                              // ? Colors.green
                              // : carDetails['type'] == "deviceStopped"
                              // ? Colors.red.shade700
                              //   :carDetails['type'] == "geofenceEnter"
                              // ? Colors.amber.shade800
                              //   :carDetails['type'] == "geofenceExit"
                              //     ? Colors.amber.shade800
                              //     :carDetails['type'] == "deviceMoving"
                              //     ? Colors.amber.shade800
                              //     : Colors.amber.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                widget.carNumber,
                                style: GoogleFonts.robotoSlab(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                deviceType,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                formattedTime,
                                // updatedTime ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}





//UNUSED DATA
void main() => runApp(const AllNotification());

class AllNotification extends StatefulWidget {
  const AllNotification({super.key});

  @override
  State<AllNotification> createState() => _AllNotificationState();
}

class _AllNotificationState extends State<AllNotification> {
  String carNumber = '';
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> carDetailsList = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  bool showFilter =
  false; // Variable to control the visibility of the filter card

  Map<String, bool> eventTypeFilters = {
    'Ignition Off': false,
    'Ignition On': false,
    'Geofence Enter': false,
  };

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    fetchCarDetails();
  }

  // Initialize notifications
  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  // Show alert dialog
  void showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Event'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show push notification
  void showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Event',
      message,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> fetchCarDetails() async {
    const String carDetailsApiUrl =
        "https://mocki.io/v1/5e1ec956-b10e-47be-baf4-324933d117d8";
    final String? sessionCookies = await storage.read(key: "sessionCookies");

    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(carDetailsApiUrl),

      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        List<Map<String, dynamic>> filteredEvents = [];

        for (var carDetails in jsonResponse) {
          if (_isEventFiltered(carDetails)) {
            filteredEvents.add(carDetails);
          }
        }

        setState(() {
          carDetailsList = filteredEvents;
        });

        for (var carDetails in carDetailsList) {
          final eventMessage =
              'New Event for Car ${carDetails['c']}: ${carDetails['a']}';
          carNumber = carDetails['c'];

          showNotification(eventMessage);
        }
      } else {
      }
    } else {
      Fluttertoast.showToast(
        msg: "Login again",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  bool _isEventFiltered(Map<String, dynamic> carDetails) {
    if (eventTypeFilters.values.every((element) => element == false)) {
      return true;
    }

    String eventType = carDetails['type'] ?? '';

    for (var filter in eventTypeFilters.keys) {
      if (eventTypeFilters[filter] == true &&
          eventType.toLowerCase().contains(filter.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  double convertToDecimal(int coordinate) {
    double decimalCoordinate = coordinate / 1000000.0;
    return decimalCoordinate;
  }

  void openGoogleMaps(double latitude, double longitude) async {
    String url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
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
                        color:
                        Colors.grey.shade700.withOpacity(0.5), // Border color
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
                    color: Colors.grey.shade700.withOpacity(0.5), // Border color
                    width: 1.0,
                  )),
            ),
            child: ListTile(
              title: Text(
                "Event Logs",
                style: GoogleFonts.robotoSlab(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    showFilter =
                    !showFilter; // Toggle the visibility of the filter card
                  });
                },
                child: const Icon(Icons.filter_alt_outlined),
              ),
            )
          ],
        ),
        body: Stack(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: carDetailsList.length,
                itemBuilder: (context, index) {
                  final carDetails = carDetailsList[index];
                  return InkWell(
                    onTap: () {
                      openGoogleMaps(
                        convertToDecimal(carDetails['y']),
                        convertToDecimal(carDetails['x']),
                      );
                    },
                    child: SizedBox(
                      height: 120,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Card(
                          elevation: 0.1,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'Car Number: ${carDetails['c']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Event: ${carDetails['type'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Lat: ${carDetails['x']} Long: ${carDetails['y']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Time: ${carDetails['eventTime'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (showFilter) ...[
              // Show the filter card if showFilter is true
              FilterCard(
                eventTypeFilters: eventTypeFilters,
                onFilterChanged: (filter) {
                  setState(() {
                    eventTypeFilters = filter;
                  });
                },
              ),
              const Divider(), // Add a divider below the filter card
            ],
          ],
        ),
      ),
    );
  }
}

class FilterCard extends StatefulWidget {
  final Map<String, bool> eventTypeFilters;
  final Function(Map<String, bool>) onFilterChanged;

  const FilterCard({super.key,
    required this.eventTypeFilters,
    required this.onFilterChanged,
  });

  @override
  _FilterCardState createState() => _FilterCardState();
}

class _FilterCardState extends State<FilterCard> {
  late Map<String, bool> _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.eventTypeFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Options',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Column(
                  children: _filters.keys.map((String eventType) {
                    return CheckboxListTile(
                      title: Text(
                        eventType,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      value: _filters[eventType],
                      onChanged: (bool? value) {
                        setState(() {
                          _filters[eventType] = value!;
                        });
                        widget.onFilterChanged(_filters);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onFilterChanged(_filters);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
