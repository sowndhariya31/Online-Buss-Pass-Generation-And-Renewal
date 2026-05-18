import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bus_pass.dart';
import '../models/user.dart';

class PassProvider with ChangeNotifier {
  List<BusPass> _myPasses = [];
  List<BusPass> _allPasses = [];
  List<User> _studentUsers = [];
  List<User> _publicUsers = [];
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = false;

  List<BusPass> get myPasses => _myPasses;
  List<BusPass> get allPasses => _allPasses;
  List<User> get studentUsers => _studentUsers;
  List<User> get publicUsers => _publicUsers;
  List<Map<String, dynamic>> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;

  Future<void> fetchMyPasses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('/passes/list/');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _myPasses = data.map((json) => BusPass.fromJson(json)).toList();
      }
    } catch (e) {
      print('Fetch my passes error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllPasses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.get('/passes/admin/list/');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _allPasses = data.map((json) => BusPass.fromJson(json)).toList();
      }
    } catch (e) {
      print('Fetch all passes error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updatePassStatus(int passId, String status) async {
    try {
      // Map frontend status to backend expected status
      String backendStatus = status;
      if (status == 'ACTIVE') {
        backendStatus = 'APPROVED';
      }
      
      final response = await ApiService.patch('/passes/admin/$passId/action/', {'status': backendStatus});
      if (response.statusCode == 200) {
        // Refresh lists
        await fetchAllPasses();
        return true;
      }
    } catch (e) {
      print('Update pass status error: $e');
    }
    return false;
  }

  Future<bool> deletePass(int passId) async {
    try {
      final response = await ApiService.delete('/passes/admin/$passId/action/');
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Refresh lists
        await fetchAllPasses();
        return true;
      }
    } catch (e) {
      print('Delete pass error: $e');
    }
    return false;
  }

  Future<void> fetchUsers() async {
    try {
      final responseStudents = await ApiService.get('/users/list/?role=STUDENT');
      if (responseStudents.statusCode == 200) {
        final List data = jsonDecode(responseStudents.body);
        _studentUsers = data.map((json) => User.fromJson(json)).toList();
      }
      
      final responsePublic = await ApiService.get('/users/list/?role=PUBLIC');
      if (responsePublic.statusCode == 200) {
        final List data = jsonDecode(responsePublic.body);
        _publicUsers = data.map((json) => User.fromJson(json)).toList();
      }
      notifyListeners();
    } catch (e) {
      print('Fetch users error: $e');
    }
  }

  Future<void> fetchAuditLogs() async {
    try {
      final response = await ApiService.get('/passes/admin/logs/');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _auditLogs = List<Map<String, dynamic>>.from(data);
        notifyListeners();
      }
    } catch (e) {
      print('Fetch audit logs error: $e');
    }
  }
}
