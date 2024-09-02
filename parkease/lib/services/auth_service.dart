import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  final String _baseUrl = 'http://10.99.28.5:3001';
  final _storage = FlutterSecureStorage();

  Future<void> getUserProfile(BuildContext context) async {
    String? token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('$_baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print("Profile Data: $data");
      // Update UI or state with profile data
    } else {
      // Handle error
      print('Failed to load profile');
    }
  }

  Future<void> updateUserProfile(
      BuildContext context, String newUsername, String newPhoneNumber) async {
    String? token = await _storage.read(key: 'jwt_token');
    final response = await http.post(
      Uri.parse('$_baseUrl/updateProfile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'newUsername': newUsername,
        'newPhoneNumber': newPhoneNumber,
      }),
    );

    if (response.statusCode == 200) {
      // Handle successful update
      print('Profile updated successfully');
    } else {
      // Handle error
      print('Failed to update profile');
    }
  }
}
