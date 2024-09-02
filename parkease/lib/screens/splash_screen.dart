import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplashScreenTimer();
  }

  _startSplashScreenTimer() async {
    var _duration = Duration(seconds: 3);
    return Timer(_duration, _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacementNamed('/getStarted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Add your logo or splash image here
            Image.asset('assets/images/splash_logo.png',
                width: 150, height: 150),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
