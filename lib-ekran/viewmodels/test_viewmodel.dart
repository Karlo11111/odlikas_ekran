import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:odlikas_ekran/database/api/api_service.dart';
import 'package:odlikas_ekran/models/tests.dart';

// viewmodel za testove
class TestViewmodel extends ChangeNotifier {
  // variabla za api service
  final ApiService _apiService;

  TestViewmodel(this._apiService);

  // varijable za testove, praznike i loadanje
  bool _isLoading = false;
  Tests? _tests;
  List<Map<String, dynamic>> _holidays = [];

  // getter funkcije
  Tests? get tests => _tests;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get holidays => _holidays;

  // funkcija koja dohvaca testove iz api servica
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

  // funkcija koja dohvaca praznike iz firebasea
  Future<void> fetchHolidays() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('SchoolHolidays').get();

      _holidays = snapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'startDate': (doc['startDate'] as Timestamp).toDate(),
          'endDate': (doc['endDate'] as Timestamp).toDate(),
        };
      }).toList();

      notifyListeners(); 
    } catch (e) {
      print("Error fetching holidays: $e");
    }
  }
}
