import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:odlikas_ekran/database/api/api_service.dart';
import 'package:odlikas_ekran/models/tests.dart';

class TestViewmodel extends ChangeNotifier {
  final ApiService _apiService;

  TestViewmodel(this._apiService);

  bool _isLoading = false;
  Tests? _tests;
  List<Map<String, dynamic>> _holidays = [];

  Tests? get tests => _tests;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get holidays => _holidays;

  Future<void> fetchTests(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tests = await _apiService.fetchTestsDetails(token);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHolidays() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('SchoolHolidays')
          .get();
      _holidays = snapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'startDate': (doc['startDate'] as Timestamp).toDate(),
          'endDate': (doc['endDate'] as Timestamp).toDate(),
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
    }
  }
}
