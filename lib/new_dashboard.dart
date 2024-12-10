import 'dart:async';
import 'dart:convert';
import 'package:credence/privacy_policy.dart';
import 'package:credence/provider/devicelist_provider.dart';
import 'package:credence/provider/position_provider.dart';
import 'package:credence/rate_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_us.dart';
import 'admin/admin_page.dart';
import 'all_vehicle_live.dart';
import 'change_password.dart';
import 'data_screen.dart';
import 'edit_profile.dart';
import 'feedback.dart';
import 'help_screen.dart';
import 'invite_friend.dart';
import 'login_screen.dart';
import 'package:shimmer/shimmer.dart';

class DevicesListScreen extends StatefulWidget {
  final int userId;
  final String? username;
  final String? password;
  final String? sessionCookies;

  const DevicesListScreen(
      {super.key,
      required this.userId,
      this.username,
      this.password,
      this.sessionCookies});

  @override
  _DevicesListScreenState createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  TextEditingController searchController = TextEditingController();
  TextEditingController groupSearchCotroller = TextEditingController();
  final storage = const FlutterSecureStorage();
  int allCount = 0;
  int runningCount = 0;
  int stopCount = 0;
  int idleCount = 0;
  int onlineCount = 0;
  int overSpeedCount = 0;
  int inactiveCount = 0;
  int id = 0;
  final int _selectedItem = 0;
  String currentFilter = 'All';
  String myName = '';
  String? phone = '';
  String? address = "";
  bool isLoading = true;
  bool isSearchActive = false;
  double totalDistance = 0.0;
  double todayDistance = 0.0;
  bool? statusDevice;
  List<dynamic> devicesList = [];
  List<dynamic> positionsList = [];
  List<dynamic> filteredDevicesList = [];
  List<Map<String, dynamic>> groupDetails = [];
  Map<int, double> deviceDistances = {};
  Set<int> selectedGroupId = {};
  Set<String> selectedNames = {};
  List<int> selectedGroupIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData();
    });
    groupListApi();
  }

  Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade300,
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(
              fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        content: Text(
          'Are you sure you want to Logout?',
          style: GoogleFonts.poppins(
              fontSize: 13.0, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
                side: const BorderSide(color: Colors.black),
              ),
              backgroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No',
                style: GoogleFonts.poppins(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
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
              _performLogout(context);
            },
            //return true when click on "Yes"
            child: Text('Yes',
                style: GoogleFonts.poppins(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: "sessionCookies");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
    Fluttertoast.showToast(
      msg: "Logout Successful",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<void> fetchData() async {
    final devicesProvider =
        Provider.of<DevicePositionProvider>(context, listen: false);
    final positionsProvider =
        Provider.of<PositionsProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      await Future.wait([
        devicesProvider.fetchDevicesList(context),
        positionsProvider.fetchPositions(context),
      ]);
      if (mounted) {
        setState(() {
          isLoading = false;
          devicesList = devicesProvider.devices;
          positionsList = positionsProvider.positions;
          filteredDevicesList = devicesList;
          searchController.addListener(_filterDevicess);
          _updateCounts();
        });

        // Fetch trip and summary logs concurrently for each device
        // await Future.wait(filteredDevicesList.map((device) async {
        //   // await fetchTripLog(device['id']);
        //   // await fetchSummaryLog(device['id']);
        // }));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<List<dynamic>> devicesListApi() async {
    final String deviceApi = dotenv.env['DEVICE_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(deviceApi),
          headers: {'Cookie': sessionCookies},
        );
        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = json.decode(response.body);
          return jsonResponse;
        } else {}
      } catch (error) {}
    } else {
      Fluttertoast.showToast(
        msg: "Session Expired. Redirecting to login.",
        toastLength: Toast.LENGTH_SHORT,
      );
      await storage.delete(key: "sessionCookies");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
    return [];
  }

  Future<void> userData() async {
    final String userApi = dotenv.env['USERS_API']!;
    final String apiUrl = "$userApi/${widget.userId}";
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Cookie': sessionCookies,
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        int userId = responseData['id'];
        String name = responseData['name'];
        phone = responseData['phone'];

        setState(() {
          myName = name;
          id = userId;
        });
      } else {}
    }
  }

  Timer? _debounce;
  void _filterDevices(String filter) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        currentFilter = filter;
        filteredDevicesList = _applyFilter(filter);
        _updateCounts();
      });
    });
  }

  void _filterDevicess() {
    final query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      setState(() {
        filteredDevicesList = devicesList.where((device) {
          final deviceName = device['name']?.toString()?.toLowerCase() ?? '';
          return deviceName.contains(query);
        }).toList();
      });
    } else {
      setState(() {
        filteredDevicesList = devicesList;
      });
    }
  }

  Future<void> _onRefresh() async {
    await fetchData();
  }

  List<dynamic> _applyFilter(String filter) {
    switch (filter) {
      case 'Running':
        return devicesList.where((device) {
          final position = positionsList.firstWhere(
              (pos) => pos['id'] == device['positionId'],
              orElse: () => {});
          return position.isNotEmpty &&
              position['speed'] >= 2 &&
              position['attributes']['ignition'] == true;
        }).toList();

      case 'Stop':
        return devicesList.where((device) {
          final position = positionsList.firstWhere(
              (pos) => pos['id'] == device['positionId'],
              orElse: () => {});
          return position.isNotEmpty &&
              position['speed'] >= 0 &&
              position['attributes']['ignition'] == false;
        }).toList();

      case 'Idle':
        return devicesList.where((device) {
          final position = positionsList.firstWhere(
              (pos) => pos['id'] == device['positionId'],
              orElse: () => {});
          return position.isNotEmpty &&
              position['speed'] < 2 &&
              position['attributes']['ignition'] == true;
        }).toList();

      case 'Online':
        return devicesList.where((device) {
          return device['status'] == 'online' || device['positionId'] != 0;
        }).toList();

      case 'Overspeed':
        return devicesList.where((device) {
          final position = positionsList.firstWhere(
              (pos) => pos['id'] == device['positionId'],
              orElse: () => {});
          return position.isNotEmpty &&
              position['speed'] > 60 &&
              position['attributes']['ignition'] == true;
        }).toList();

      case 'Inactive':
        return devicesList.where((device) {
          return device['status'] == 'offline' &&
              device['lastUpdate'] == null &&
              device['positionId'] == 0;
        }).toList();

      default:
        return devicesList;
    }
  }

  void _updateCounts() {
    allCount = devicesList.length;
    runningCount = _applyFilter('Running').length;
    stopCount = _applyFilter('Stop').length;
    idleCount = _applyFilter('Idle').length;
    onlineCount = _applyFilter('Online').length;
    overSpeedCount = _applyFilter('Overspeed').length;
    inactiveCount = _applyFilter('Inactive').length;
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return "${placemark.street} ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}";
      }
    } catch (e) {}
    return "Updating address...";
  }

  Future<void> groupListApi() async {
    final String groupListApiurl = dotenv.env['GROUP_API']!;
    final String? sessionCookies = await storage.read(key: "sessionCookies");
    if (sessionCookies != null) {
      try {
        final response = await http.get(
          Uri.parse(groupListApiurl),
          headers: {
            'Cookie': sessionCookies,
          },
        ).timeout(const Duration(seconds: 30)); // Set timeout duration here

        if (response.statusCode == 200) {
          final List<dynamic> responseData = json.decode(response.body);
          groupDetails.clear(); // Clear previous data if any
          for (var item in responseData) {
            final int id = item['id'];
            final String name = item['name'];
            groupDetails.add({
              'id': id,
              'name': name,
            });
          }
        } else {}
      } on TimeoutException catch (_) {
      } on http.ClientException catch (e) {
      } catch (e) {}
    }
  }

  Future<void> fetchAndFilterDevicesListByGroup(BuildContext context) async {
    final deviceProvider =
        Provider.of<DevicePositionProvider>(context, listen: false);
    await deviceProvider.fetchDevicesList(context);
    filterDevicesListByGroup(deviceProvider.devices);
  }

  void filterDevicesListByGroup(List<dynamic> devicesList) {
    filteredDevicesList.clear();
    setState(() {
      for (var device in devicesList) {
        if (selectedGroupIds.contains(device['groupId'])) {
          filteredDevicesList.add(device);
          _updateCounts();
        }
      }
      print("Filtered Devices List: $filteredDevicesList");
    });
  }

  // void filterDevicesListByGroup(List<dynamic> devicesList) {
  //   filteredDevicesList.clear();
  //   print("Selected Group IDs: $selectedGroupIds");
  //   print("Devices List: ${devicesList.map((device) => device['groupId']).toList()}");
  //   setState(() {
  //     for (var device in devicesList) {
  //       print("Device Group ID: ${device['groupId']}");
  //       if (selectedGroupIds.contains(device['groupId'])) {
  //         filteredDevicesList.add(device);
  //       }
  //     }
  //     print("Filtered Devices List: $filteredDevicesList");
  //   });
  // }

  // void filterDevicesListByGroup(List<dynamic> devicesList) {
  //   filteredDevicesList.clear();
  //   setState(() {
  //     for (var device in devicesList) {
  //       if (selectedGroupIds.contains(device['groupId'])) {
  //         filteredDevicesList.add(device);
  //       }
  //     }
  //   });
  // }

  List<Map<String, dynamic>> filteredGroupDetails = [];
  void _showCustomDialog() {
    final devicesProvider =
        Provider.of<DevicePositionProvider>(context, listen: false);
    filteredGroupDetails = List.from(groupDetails);
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.zero,
              insetPadding: EdgeInsets.zero,
              buttonPadding: EdgeInsets.zero,
              titlePadding: EdgeInsets.zero,
              title: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: groupDetails.isNotEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: SizedBox(
                                height: 45,
                                child: TextFormField(
                                  controller: groupSearchCotroller,
                                  decoration: InputDecoration(
                                    hintText: "Search",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.black),
                                    ),
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        groupSearchCotroller.text = '';
                                        setState(() {
                                          filteredGroupDetails =
                                              List.from(groupDetails);
                                        });
                                      },
                                    ),
                                  ),
                                  onChanged: (value) {
                                    search(value, setState);
                                  },
                                ),
                              ),
                            ),
                            filteredGroupDetails.isNotEmpty
                                ? SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.5,
                                    child: ListView.builder(
                                      itemCount: filteredGroupDetails.length,
                                      itemBuilder: (context, index) {
                                        final id =
                                            filteredGroupDetails[index]['id'];
                                        final name =
                                            filteredGroupDetails[index]['name'];
                                        return CheckboxListTile(
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: Colors.green,
                                          title: Text(
                                            name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.0,
                                              fontWeight:
                                                  selectedNames.contains(name)
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                          value: selectedNames.contains(name),
                                          onChanged: (bool? isChecked) {
                                            setState(() {
                                              if (isChecked == true) {
                                                selectedNames.add(name);
                                                selectedGroupIds.add(id);
                                              } else {
                                                selectedNames.remove(name);
                                                selectedGroupIds.remove(id);
                                              }

                                              // final deviceProvider = Provider.of<DevicePositionProvider>(context, listen: false);
                                              // filterDevicesListByGroup(deviceProvider.devices);
                                              // filterDevicesListByGroup(devicesList);
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      "No Group Found",
                                      style: GoogleFonts.poppins(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        side: BorderSide(
                                            color: Colors.red.shade700),
                                      ),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                      groupSearchCotroller.text = '';
                                    },
                                    // => Navigator.of(context).pop(false),
                                    child: Text('Cancel',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(width: 20),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        side: const BorderSide(
                                            color: Colors.black),
                                      ),
                                      backgroundColor: Colors.black,
                                    ),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      // final deviceProvider = Provider.of<DevicePositionProvider>(context, listen: false);
                                      // filterDevicesListByGroup(deviceProvider.devices);
                                      //
                                      // final deviceProvider = Provider.of<DevicePositionProvider>(context, listen: false);
                                      // filterDevicesListByGroup(deviceProvider.devices);
                                      // print('Devices from provider: ${deviceProvider.devices}');
                                      await fetchAndFilterDevicesListByGroup(
                                          context);

                                      // List<dynamic> devicesList = await devicesListApi();
                                      // filterDevicesListByGroup(devicesList);
                                    },
                                    child: Text('OK',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Text("No Groups Found!",
                            style: GoogleFonts.poppins(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w500,
                                color: Colors.red)),
                      ),
              ),
            );
          },
        );
      },
    );
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
            elevation: 0.0,
            backgroundColor: Colors.grey.shade300,
            title: isSearchActive
                ? SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search vehicle',
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.black,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Text(
                          "Dashboard",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Image.asset(
                  'assets/menu_black.png',
                  width: 24.0,
                  height: 22.0,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            actions: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _showCustomDialog();
                    },
                    icon: const Icon(
                      Icons.filter_alt_outlined,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isSearchActive = !isSearchActive;
                      });
                    },
                    icon: Icon(
                      isSearchActive ? Icons.close : Icons.search,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          children: <Widget>[
            GestureDetector(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                          height: 70,
                          width: 250,
                          child: Image.asset(
                            "assets/credence_white.png",
                            fit: BoxFit.fill,
                          )),
                    ),
                    const SizedBox(height: 10.0), // Spacer
                    GestureDetector(
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) {
                      //         return const AdminScreen();
                      //       },
                      //     ),
                      //   );
                      // },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  myName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 18.0, // Customize the font size
                                      fontWeight: FontWeight.w500,
                                      color: Colors
                                          .black // Customize the font weight
                                      ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_sharp,
                                  color: Colors.black,
                                  size: 17,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 0
                  ? const EdgeInsets.symmetric(horizontal: 0.0)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  color: _selectedItem == 0
                      ? Colors.grey.shade500.withOpacity(0.5)
                      : Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 15,
                      width: 15,
                      child: Image.asset(
                        "assets/home_new.png",
                        color: _selectedItem == 0 ? Colors.white : Colors.black,
                      )),
                  title: Text(
                    'Home',
                    style: GoogleFonts.poppins(
                        color: _selectedItem == 0 ? Colors.white : Colors.black,
                        fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DevicesListScreen(
                                  userId: id,
                                )));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 11
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/black_vehicles.png",
                      )),
                  // const Icon(Icons.help),
                  title: Text(
                    "All Vehicles",
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AllVehicleLive()));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 4
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/about_image.png",
                      )),
                  // const Icon(Icons.info),
                  title: Text(
                    'About Us',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    // Handle About Us tap
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AboutUs(
                                myName: myName,
                                phone: phone,
                                userId: widget.userId)));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 2
                  ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/invite_image.png",
                      )),
                  // const Icon(Icons.person_add),
                  title: Text(
                    'Invite Friend',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    // Handle Invite Friend tap
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Invite(
                                myName: myName,
                                phone: phone,
                                userId: widget.userId)));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 9
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/black_rc.png",
                      )),
                  // const Icon(Icons.help),
                  title: Text(
                    'Check RC',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    launch(
                        "https://vahan.parivahan.gov.in/vahanservice/vahan/ui/appl_status/form_Know_Appl_Status.xhtml");
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 8
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/black_license.png",
                      )),
                  // const Icon(Icons.help),
                  title: Text(
                    'License',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    launch("https://parivahan.gov.in/rcdlstatus/?pur_cd=101");
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 7
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/black_profile.png",
                      )),
                  // const Icon(Icons.help),
                  title: Text(
                    'Update Profile',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditProfile(
                                  userId: widget.userId,
                                  phone: phone ?? "",
                                  myName: myName,
                                )));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 5
                  ? const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/privacy_image.png",
                      )),
                  // const Icon(Icons.policy),
                  title: Text(
                    'Privacy',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PrivacyPolicy(
                                myName: myName,
                                phone: phone,
                                userId: widget.userId)));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 6
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/help_image.png",
                      )),
                  // const Icon(Icons.help),
                  title: Text(
                    'Help',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                HelpScreen(userId: widget.userId)));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 1
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/feedback_image.png",
                      )),
                  // const Icon(Icons.feedback),
                  title: Text(
                    'Feedback',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FeedBack(
                                myName: myName,
                                phone: phone,
                                userId: widget.userId)));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 3
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/rate_app.png",
                      )),
                  // const Icon(Icons.star),
                  title: Text(
                    'Rate the App',
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Rate(
                                myName: myName,
                                phone: phone,
                                userId: widget.userId)));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 10
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/black_password.png",
                      )),
                  // const Icon(Icons.help),
                  title: Text(
                    "Change Password",
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChangePassword()));
                  },
                ),
              ),
            ),
            Padding(
              padding: _selectedItem == 12
                  ? const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: ListTile(
                  leading: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        "assets/black_logout.png",
                      )),
                  // const Icon(Icons.help),
                  title: Text(
                    "Exit",
                    style:
                        GoogleFonts.poppins(color: Colors.black, fontSize: 12),
                  ),
                  onTap: () {
                    showLogoutDialog(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            height: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusCircle(Colors.blue, 'All', allCount),
                  const SizedBox(width: 16), // Space between circles
                  _buildStatusCircle(Colors.green, 'Running', runningCount),
                  const SizedBox(width: 16),
                  _buildStatusCircle(Colors.red, 'Stop', stopCount),
                  const SizedBox(width: 16),
                  _buildStatusCircle(Colors.yellow, 'Idle', idleCount),
                  const SizedBox(width: 16),
                  _buildStatusCircle(Colors.blueGrey, 'Online', onlineCount),
                  const SizedBox(width: 16),
                  _buildStatusCircle(
                      Colors.orange, 'Overspeed', overSpeedCount),
                  const SizedBox(width: 16),
                  _buildStatusCircle(Colors.grey, 'Inactive', inactiveCount),
                ],
              ),
            ),
          ),
          // ListView.builder
          isLoading
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.75,
                        ),
                        child: SingleChildScrollView(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: buildShimmerContainer(context),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Expanded(
                  child: RefreshIndicator(
                      displacement: 20,
                      color: Colors.white,
                      backgroundColor: Colors.black,
                      strokeWidth: 2,
                      onRefresh: _onRefresh,
                      child: filteredDevicesList.isNotEmpty
                          ? ListView.builder(
                              itemCount: filteredDevicesList.length,
                              itemBuilder: (context, index) {
                                final device = filteredDevicesList[index];
                                final position = positionsList.firstWhere(
                                  (pos) => pos['id'] == device['positionId'],
                                  orElse: () => {},
                                );

                                final speed =
                                    (position['speed'] as double?) ?? 0.0;
                                final lastUpdate = device['lastUpdate'] ?? "";
                                final positionId = device['positionId'] ?? 0;
                                final vehicleName = device['name'] ?? "";
                                final battery = (position['attributes']
                                        ?['battery'] as double?) ??
                                    0.0;
                                final totalDistance = ((position['attributes']
                                            ?['totalDistance'] as double?) ??
                                        0.0) /
                                    1000;
                                final deviceId = (device['id'] as int?) ?? 0.0;
                                final ignition = (position['attributes']
                                        ?['ignition'] as bool?) ??
                                    false;
                                final deviceStatus =
                                    (device['status'].toString()) ?? 'unknown';

                                statusDevice = deviceStatus == "online";
                                final status = getStatus(speed, ignition,
                                    deviceStatus, lastUpdate, positionId);
                                double latitude = position['latitude'] ?? 0.0;
                                double longitude = position['longitude'] ?? 0.0;
                                final vehicleType = device['category'] ?? "";
                                Future<String> fetchAddress(
                                    double latitude, double longitude) async {
                                  return await getAddress(latitude, longitude);
                                }
                                String formatDate(String dateString) {
                                  try {
                                    DateTime dateTime =
                                        DateTime.parse(dateString);
                                    dateTime = dateTime.add(
                                        const Duration(hours: 5, minutes: 30));
                                    return DateFormat('dd-MM-yyyy \nHH:mm:ss')
                                        .format(dateTime);
                                  } catch (e) {
                                    return '00-00-0000 00:00:00';
                                  }
                                }
                                String imagePath = 'assets/walk.png';
                                String imagePath2 = 'assets/walk.png';
                                switch (vehicleType) {
                                  case 'motorcycle':
                                    switch (status) {
                                      case 'Idle':
                                        imagePath =
                                            'assets/bike_yellow_img.png';
                                        imagePath2 = 'assets/bike-yellow.png';
                                        break;
                                      case 'Running':
                                        imagePath = 'assets/bike_green_img.png';
                                        imagePath2 = 'assets/bike-green.png';
                                        break;
                                      case 'Stopped':
                                        imagePath = 'assets/bike_red_img.png';
                                        imagePath2 = 'assets/bike-red.png';
                                        break;
                                      default:
                                        imagePath =
                                            'assets/bike_grey_img.png'; // Set default image path
                                        imagePath2 = 'assets/bike-yellow.png';
// Set default color
                                        break;
                                    }
                                    break;
                                  case 'car':
                                    switch (status) {
                                      case 'Idle':
                                        imagePath = 'assets/car_yellow_img.png';
                                        imagePath2 = 'assets/car-yellow2.png';
                                        break;
                                      case 'Running':
                                        imagePath = 'assets/car_green_img.png';
                                        imagePath2 = 'assets/car-green2.png';
                                        break;
                                      case 'Stopped':
                                        imagePath = 'assets/car_red_img.png';
                                        imagePath2 = 'assets/car-red2.png';
                                        break;
                                      default:
                                        imagePath =
                                            'assets/car_grey_img.png'; // Set default image path
                                        imagePath2 = 'assets/car-red2.png';
// Set default color
                                        break;
                                    }
                                    break;
                                  case 'bus':
                                    switch (status) {
                                      case 'Idle':
                                        imagePath = 'assets/bus_yellow_img.png';
                                        imagePath2 = 'assets/bus-yellow2.png';
                                        break;
                                      case 'Running':
                                        imagePath = 'assets/bus_green_img.png';
                                        imagePath2 = 'assets/bus-green2.png';
                                        break;
                                      case 'Stopped':
                                        imagePath = 'assets/bus_red_img.png';
                                        imagePath2 = 'assets/bus-red2.png';
                                        break;
                                      default:
                                        imagePath =
                                            'assets/bus_grey_img.png'; // Set default image path
                                        imagePath2 = 'assets/bus-yellow2.png';

//
                                        break;
                                    }
                                    break;
                                  case 'tractor':
                                    switch (status) {
                                      case 'Idle':
                                        imagePath =
                                            'assets/tractor_yellow_new.png';
                                        imagePath2 = 'assets/truck-yellow2.png';
                                        break;
                                      case 'Running':
                                        imagePath = 'assets/tractor_green.png';
                                        imagePath2 = 'assets/truck-green2.png';
                                        break;
                                      case 'Stopped':
                                        imagePath = 'assets/tractor_red.png';
                                        imagePath2 = 'assets/truck-red2.png';
                                        break;
                                      default:
                                        imagePath =
                                            'assets/tractor_grey.png'; // Set default image path
                                        imagePath2 = 'assets/truck-red2.png';
// Set default color
                                        break;
                                    }
                                    break;
                                  case 'truck':
                                    switch (status) {
                                      case 'Idle':
                                        imagePath =
                                            'assets/truck_yellow_img.png';
                                        imagePath2 = 'assets/truck-yellow2.png';
                                        break;
                                      case 'Running':
                                        imagePath =
                                            'assets/truck_green_img.png';
                                        imagePath2 = 'assets/truck-green2.png';
                                        break;
                                      case 'Stopped':
                                        imagePath = 'assets/truck_red_img.png';
                                        imagePath2 = 'assets/truck-red2.png';
                                        break;
                                      default:
                                        imagePath =
                                            'assets/truck_grey_img.png'; // Set default image path
                                        imagePath2 = 'assets/truck-red2.png';
                                        break;
                                    }
                                }
                                return FutureBuilder<String>(
                                  future: fetchAddress(latitude, longitude),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      if (snapshot.hasData) {
                                        // Address fetched successfully
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DataScreen(
                                                  carNumber: vehicleName,
                                                  fuel: 0,
                                                  lastUpdate:
                                                      formatDate(lastUpdate),
                                                  Odometer: totalDistance
                                                      .roundToDouble()
                                                      .toString(),
                                                  battery: battery.toInt(),
                                                  Engine: ignition,
                                                  stopMatch: "stop.toString()",
                                                  id: deviceId.toInt(),
                                                  carSpeed: speed,
                                                  status: statusDevice as bool,
                                                  driver: 'N/A',
                                                  address: snapshot.data ??
                                                      'Address not found',
                                                  todayDistance: 0,
                                                  imagePath: imagePath,
                                                  imagePath2: imagePath2,
                                                ),
                                              ),
                                            );
                                          },
                                          child: _buildDeviceItem(
                                              device,
                                              snapshot.data ??
                                                  'Address not found',
                                              position,
                                              imagePath,
                                              formatDate,

                                              ),
                                        );
                                      } else {
                                        // Handle the error if needed
                                        return _buildDeviceItem(
                                            device,
                                            snapshot.data ??
                                                'Address not found',
                                            position,
                                            imagePath,
                                            formatDate,

                                            ); // Or another placeholder
                                      }
                                    } else {
                                      return _buildDeviceItem(
                                          device,
                                          snapshot.data ?? 'Address not found',
                                          position,
                                          imagePath,
                                          formatDate,
                                          ); // Or another placeholder
                                    }
                                  },
                                );
                              },
                            )
                          : const Text("No Data Found",
                              style: TextStyle(color: Colors.white))))
        ],
      ),
    );
  }

  Widget _buildDeviceItem(
      Map device,
      String address,
      position,
      String imagePath,
      String Function(String dateString) formatDate,
 ) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 5, right: 5),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.97,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1), // changes position of shadow
            ),
          ],
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
        ),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.04,
              child: Container(
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(15),
                              topLeft: Radius.circular(8),
                            ),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  position['attributes'] != null &&
                                          position['attributes']['battery'] !=
                                              null
                                      ? '${position['attributes']['battery'].toStringAsFixed(2)}%'
                                      : '0%',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.gps_fixed_outlined,
                                size: 15.0,
                                color: device['status'] == "online"
                                    ? Colors.green
                                    : Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 3,
                        child: Container(
                          color: Colors.black,
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15)),
                              color: Colors.black,
                            ),
                            child: Text(
                              device['name'],
                              style: GoogleFonts.sansita(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(8),
                            ),
                            color: Colors.white,
                          ),
                          child: Row(

                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.signal_cellular_alt_outlined,
                                  size: 18.0,
                                  color: device['status'] == "online"
                                      ? Colors.green
                                      : Colors.black,
                                ),
                              ),
                              Icon(Icons.key,
                                  size: 18.0,
                                  color: (position['speed'] != null &&
                                          position['speed'] == 0 &&
                                          position['attributes'] != null &&
                                          position['attributes']['ignition'] ==
                                              true)
                                      ? Colors.yellow
                                      : (position['speed'] != null &&
                                              position['speed'] > 0 &&
                                              position['attributes'] != null &&
                                              position['attributes']
                                                      ['ignition'] ==
                                                  true)
                                          ? Colors.green
                                          : (position['speed'] != null &&
                                                  position['speed'] < 2 &&
                                                  position['attributes'] !=
                                                      null &&
                                                  position['attributes']
                                                          ['ignition'] ==
                                                      false)
                                              ? Colors.red
                                              : device['status'] == "offline"
                                                  ? Colors.grey
                                                  : Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 0, top: 10, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 80,
                          width: 150,
                          child: Center(
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    "Spent Fuel",
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  height: 5,
                                  width: 5,
                                  color: Colors.green,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    // " ${fuel.toStringAsFixed(2)}",
                                    "0.00",
                                    style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    "ETA",
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  height: 5,
                                  width: 5,
                                  color: Colors.red,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    "0.00",
                                    // _etaText ?? "00:00:00",
                                    style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    "Driver",
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  height: 5,
                                  width: 5,
                                  color: Colors.purple,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    "Unknown",
                                    style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      device['name'],
                      style: GoogleFonts.sansita(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      address.toString(),
                      style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset:
                              const Offset(0, 1), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, bottom: 7, top: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Last Update",
                                style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(
                                height: 0,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.2,
                                child: Text(
                                  formatDate(device['lastUpdate'].toString()),
                                  style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Km",
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                 "0.00\n km",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              ]),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Km",
                                style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                position['attributes'] != null &&
                                        position['attributes']
                                        ['totalDistance'] != null
                                    ? (() {
                                        double distanceN = double.tryParse(
                                                position['attributes']
                                                ['totalDistance']
                                                    .toString()) ??
                                            0.0;
                                        return '${(distanceN / 1000).toStringAsFixed(2)}\n km';
                                      })()
                                    : '0.00\n km',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Speed",
                                style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                "${position['speed'] != null ? position['speed'].toStringAsFixed(2) : '0.00'} \nkmph",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCircle(Color color, String label, int count) {
    return GestureDetector(
      onTap: () => _filterDevices(label),
      child: Container(
        width: 60,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.01),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1), // changes position of shadow
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$count',
                  style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 20)),
              Text(
                label,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildShimmerContainer(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            shimmerLine(context,
                width: 200,
                height: 30,
                borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10))),
            const SizedBox(height: 10),
            buildShimmerRow(context),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                shimmerLine(context,
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.03),
                const SizedBox(height: 5),
                shimmerLine(context,
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.015),
                const SizedBox(height: 4),
                shimmerLine(context,
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: MediaQuery.of(context).size.height * 0.015),
                const SizedBox(height: 10),
                shimmerLine(context,
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.073),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildShimmerRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        shimmerLine(context,
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.1),
        Column(
          children: [
            shimmerLine(context,
                width: MediaQuery.of(context).size.width * 0.25,
                height: MediaQuery.of(context).size.height * 0.02),
            const SizedBox(height: 10),
            shimmerLine(context,
                width: MediaQuery.of(context).size.width * 0.25,
                height: MediaQuery.of(context).size.height * 0.02),
            const SizedBox(height: 10),
            shimmerLine(context,
                width: MediaQuery.of(context).size.width * 0.25,
                height: MediaQuery.of(context).size.height * 0.02),
          ],
        ),
      ],
    );
  }

  Widget shimmerLine(BuildContext context,
      {required double width,
      required double height,
      BorderRadius? borderRadius}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: borderRadius ?? BorderRadius.circular(5),
            ),
          ),
        ),
      ],
    );
  }

  void search(String query, StateSetter setState) {
    setState(() {
      filteredGroupDetails = groupDetails
          .where((group) =>
              group['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
}

String? getStatus(
    double speed, bool ignition, String status, lastUpdate, positionId) {
  if (speed < 2.0 && !ignition && status != "offline") {
    return 'Stopped';
  } else {
    if (speed < 2.0 && ignition) {
      return 'Idle';
    } else if (speed > 2.0 && ignition) {
      return 'Running';
    } else if (status == "offline" && lastUpdate == null && positionId == 0) {
      return 'Inactive';
    } else {
      return 'Online';
    }
  }
}
