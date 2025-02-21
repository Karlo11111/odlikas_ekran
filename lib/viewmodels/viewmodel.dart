import 'package:flutter/foundation.dart';
import 'package:odlikas_ekran/models/grades.dart';
import 'package:odlikas_ekran/models/specific_subject.dart';
import 'package:odlikas_ekran/models/student_profile.dart';
import '../database/api/api_service.dart';

class HomePageViewModel extends ChangeNotifier {
  final ApiService _apiService;

  HomePageViewModel(this._apiService);

  bool _isLoading = false;
  StudentProfile? _studentProfile;
  Grades? _grades;
  List<MonthlyGrades>? _subjectGrades;
  List<EvaluationElement>? _evaluationElements;
  String? _finalGrade;

  bool get isLoading => _isLoading;
  StudentProfile? get studentProfile => _studentProfile;
  Grades? get grades => _grades;
  List<MonthlyGrades>? get subjectGrades => _subjectGrades;
  List<EvaluationElement>? get evaluationElements => _evaluationElements;
  String? get finalGrade => _finalGrade;

  // metoda za dohvaćanje profila ucenika iz apija
  Future<void> fetchStudentProfile(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchStudentProfile(email, password);
      _studentProfile = data;
    } catch (e) {
      // ako je error, ispiši ga u konzolu
      debugPrint("Error fetching student profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // metoda za dohvaćanje ocjena iz apija
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

  // metoda za dohvaćanje ocjena za određeni predmet iz apija
  Future<void> fetchSpecificSubjectGrades(
      String email, String password, String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.fetchSpecificSubjectDetails(
          email, password, subjectId);
      _subjectGrades = data.monthlyGrades;
      _evaluationElements = data.evaluationElements;
      _finalGrade = data.finalGrade;
    } catch (e) {
      debugPrint("Error fetching specific subject grades: $e");
      _subjectGrades = null;
      _evaluationElements = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
