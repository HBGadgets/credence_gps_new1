import 'package:credence/provider/car_address_provider.dart';
import 'package:credence/provider/car_details_provider.dart';
import 'package:credence/provider/car_location_provider.dart';
import 'package:credence/provider/devicelist_provider.dart';
import 'package:credence/provider/map_provider.dart';
import 'package:credence/provider/notification_provider.dart';
import 'package:credence/provider/position_provider.dart';
import 'package:credence/provider/triplog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'splash_screen.dart';

Future main() async {
  await dotenv.load(fileName: "lib/.env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CarDetailsProvider>(
          create: (context) => CarDetailsProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => CarLocationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(),
        ),
        ChangeNotifierProvider(create: (context) => DevicePositionProvider()),
        ChangeNotifierProvider(create: (context) => PositionsProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (context) => TripLogProvider()),
        ChangeNotifierProvider(create: (context) => TripLogReportProvider()),
        ChangeNotifierProvider(create: (context) => DevicesProvider()),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: SplashScreen(key: UniqueKey()),
        ),
      ),
    );
  }
}
