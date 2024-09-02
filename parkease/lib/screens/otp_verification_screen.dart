import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Verify this path is correct.
import 'package:parkease/screens/get_started_screen.dart'; // Verify this path is correct.

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  OTPVerificationScreen({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> logoutUser() async {
    final logoutUrl = Uri.parse('http://192.168.1.61:3001/api/auth/logout');

    try {
      final response = await http.post(logoutUrl);

      if (response.statusCode == 200) {
        // Navigate to the initial screen or do something on successful logout
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => GetStartedScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // Handle error on logout
        _showErrorDialog('Failed to logout. Please try again.');
      }
    } catch (e) {
      // Handle any errors here
      _showErrorDialog('Error logging out: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An Error Occurred'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> verifyOTP() async {
    final url = Uri.parse('http://192.168.1.61:3001/api/auth/confirm-phone');

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        url,
        body: json.encode({
          'phoneNumber': widget.phoneNumber,
          'otp': otpController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Log out the current user if any. You will need to implement this part
        // according to your state management or user session management.
        await logoutUser();
      } else {
        setState(() {
          _errorMessage = 'Incorrect OTP. Please try again.';
        });
      }
    } catch (exception) {
      setState(() {
        _errorMessage = 'Failed to verify OTP: $exception';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Logo or a graphic to make the screen visually appealing
            Center(
              child: Image.asset(
                'assets/logo.png',
                height: 150.0,
              ),
            ),
            SizedBox(height: 40.0),
            Text(
              'OTP Verification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.0),
            Text(
              'Enter the OTP sent to your phone number.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.0),
            TextField(
              controller: otpController,
              decoration: InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : verifyOTP,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: Text(
                _isLoading ? 'Verifying...' : 'Verify',
                style: TextStyle(fontSize: 18),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
