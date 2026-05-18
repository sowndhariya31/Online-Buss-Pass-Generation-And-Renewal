import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Local network IP for physical device connection
  static String get baseUrl {
    // For physical Android devices, use the PC's local IP address and port 8080
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://192.168.1.34:8080/api';
    }
    return 'http://127.0.0.1:8080/api';
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final url = '$baseUrl$endpoint';
    print('ApiService POST calling: $url');
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    return await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await getHeaders();
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await getHeaders();
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  }

  static Future<http.Response> postMultipart(String endpoint, Map<String, String> fields, Map<String, http.MultipartFile> files) async {
    final token = await getToken();
    final url = '$baseUrl$endpoint';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields.addAll(fields);
    files.forEach((key, file) {
      request.files.add(file);
    });
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}
