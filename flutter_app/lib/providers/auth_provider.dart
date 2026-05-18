import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String emailOrBus, String password, {bool isConductor = false}) async {
    try {
      print('Login attempt for: $emailOrBus (isConductor: $isConductor)');
      final response = await ApiService.post('/token/', {
        isConductor ? 'bus_number' : 'email': emailOrBus,
        'password': password,
      });
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        
        // Fetch profile
        await fetchProfile();
        
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  Future<String?> register(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.post('/users/register/', userData);
      if (response.statusCode == 201) {
        return null; // Success
      } else {
        final data = jsonDecode(response.body);
        // Extract the first error message
        if (data is Map && data.isNotEmpty) {
          final firstKey = data.keys.first;
          final firstVal = data[firstKey];
          if (firstVal is List && firstVal.isNotEmpty) return firstVal[0];
          return firstVal.toString();
        }
        return 'Registration failed';
      }
    } catch (e) {
      print('Registration error: $e');
      return 'Connection error';
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await ApiService.get('/users/profile/');
      if (response.statusCode == 200) {
        _user = User.fromJson(jsonDecode(response.body));
        notifyListeners();
      }
    } catch (e) {
      print('Fetch profile error: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await ApiService.getToken();
    if (token != null) {
      await fetchProfile();
      if (_user != null) {
        _isAuthenticated = true;
        notifyListeners();
      }
    }
  }
}
