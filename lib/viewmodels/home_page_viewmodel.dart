import 'package:flutter/foundation.dart';
import 'package:odlikas_ekran/models/grades.dart';
import 'package:odlikas_ekran/models/student_profile.dart';
import '../database/api/api_service.dart';

class HomePageViewModel extends ChangeNotifier {
  final ApiService _apiService;

  HomePageViewModel(this._apiService);

  bool _isLoading = false;
  StudentProfile? _studentProfile;
  Grades? _grades;

  bool get isLoading => _isLoading;
  StudentProfile? get studentProfile => _studentProfile;
  Grades? get grades => _grades;

  Future<void> fetchStudentProfile(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchStudentProfile(email, password);
      _studentProfile = data;
    } catch (e) {
      // Handle error (e.g., show a snackbar or log the error)
      print("Error fetching student profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGrades(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchGrades(email, password);
      _grades = data;
    } catch (e) {
      print("Error fetching grades: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
