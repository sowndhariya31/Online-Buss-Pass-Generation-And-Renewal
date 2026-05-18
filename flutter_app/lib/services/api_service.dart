import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Render production network
  static String get baseUrl {
    return 'https://online-buss-pass-generation-and-renewal.onrender.com/api';
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
