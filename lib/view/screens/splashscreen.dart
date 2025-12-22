import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'login.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();

    // Delay for 2 seconds and navigate
    Future.delayed(const Duration(seconds: 2), () async {
      String token = await PreferenceManager.getStringValue(key: "token") ?? "";
      if (token.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Background Image
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/iv_splash_bg.png"),
            // your background image
            fit: BoxFit.cover,
          ),
        ),

        // Foreground content
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image.asset(
              //   "assets/images/app_icon_trans.png",
              //   height: MediaQuery.of(context).size.height * 0.35,
              // ),
              // textRoboto(
              //     text: "Imagine,Speak,Achieve",
              //     fontWeight: FontWeight.w900,
              //     fontSize: 30)
            ],
          ),
        ),
      ),
    );
  }
}
