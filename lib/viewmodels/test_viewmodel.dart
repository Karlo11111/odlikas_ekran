// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:odlikas_ekran/database/api/api_service.dart';
import 'package:odlikas_ekran/models/tests.dart';

class TestViewmodel extends ChangeNotifier {
  final ApiService _apiService;

  TestViewmodel(this._apiService);

  bool _isLoading = false;
  Tests? _tests;

  Tests? get tests => _tests;
  bool get isLoading => _isLoading;

  Future<void> fetchTests(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchTestsDetails(email, password);
      _tests = data;
    } catch (e) {
      print("Error fetching grades: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
