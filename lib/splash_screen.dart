import 'package:credence/introduction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'new_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required Key key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }


  void _checkUserLoggedIn() async {
    final String? email = await storage.read(key: "email");
    final String? password = await storage.read(key: "password");
    final userId = await storage.read(key: "userId");
    final sessionCookies = await storage.read(key: "sessionCookies");
    Future.delayed(const Duration(seconds: 2), () async {
      if (sessionCookies != null && userId != null && email != null && password != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => DevicesListScreen(
              userId: int.parse(userId),
              username: email,
              password: password,
              sessionCookies: sessionCookies,
            ),
          ),
          );
        }

      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const Introduction(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050513),
      body: Center(
        child: Image.asset("assets/logo_t.png"),
      ),
    );
  }
}
