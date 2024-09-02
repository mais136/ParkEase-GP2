import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final storage = FlutterSecureStorage();
  final String baseUrl = 'http://192.168.1.61:3001';

  Future<dynamic> getProtectedData() async {
    String? token = await storage.read(key: 'accessToken');
    var response = await http.get(
      Uri.parse('$baseUrl/api/protected-route'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load protected data');
    }
  }
}
