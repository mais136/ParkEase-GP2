import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:parkease/screens/user_screen.dart';
import 'package:parkease/screens/signup_screen.dart';
import 'package:parkease/widgets/logo_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPasswordVisible = false;

  Future<void> loginUser(BuildContext context) async {
    if (phoneController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() =>
          _errorMessage = 'Please enter both your phone number and password.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.61:3001/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phoneController.text,
          'password': passwordController.text,
        }),
      );

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        await storage.write(
            key: 'accessToken', value: responseBody['accessToken']);
        await storage.write(
            key: 'isAdmin', value: responseBody['user']['isAdmin'].toString());

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UserParkingScreen(
              isAdmin: responseBody['user']['isAdmin'] ?? false,
              accessToken: responseBody['accessToken'],
            ),
          ),
        );
      } else {
        setState(() => _errorMessage =
            responseBody['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      setState(
          () => _errorMessage = 'An error occurred. Please try again later.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                LogoWidget(),
                SizedBox(height: 40.0),
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.0),
                Text(
                  'Please login to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black26,
                        offset: Offset(1.5, 1.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.0),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 30.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => loginUser(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    elevation: 10.0,
                  ),
                  child: Text(
                    _isLoading ? 'Logging in...' : 'Login',
                    style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                  ),
                ),
                SizedBox(height: 20.0),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SignupScreen()),
                  ),
                  child: Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
