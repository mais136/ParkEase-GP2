import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/user.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/get_started_screen.dart';
import 'screens/user_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = FlutterSecureStorage();
  String? token = await storage.read(key: 'accessToken');
  bool isAdmin = (await storage.read(key: 'isAdmin')) == 'true';

  runApp(
    ChangeNotifierProvider(
      create: (context) => User(token ?? "", isAdmin),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    Widget initialScreen = user.token.isNotEmpty
        ? UserParkingScreen(
        isAdmin: user.isAdmin, accessToken: user.accessToken)
        : GetStartedScreen();

    return MaterialApp(
      title: 'ParkEase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: initialScreen,
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/getStarted': (context) => GetStartedScreen(),
        '/home': (context) => UserParkingScreen(
          isAdmin: user.isAdmin,
          accessToken: user.accessToken,
        ),
      },
    );
  }
}
