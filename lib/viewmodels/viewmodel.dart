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

  Future<void> fetchStudentProfile(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _studentProfile = await _apiService.fetchStudentProfile(token);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGrades(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _grades = await _apiService.fetchGrades(token);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSpecificSubjectGrades(String token, String subjectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data =
          await _apiService.fetchSpecificSubjectDetails(token, subjectId);
      _subjectGrades = data.monthlyGrades;
      _evaluationElements = data.evaluationElements;
      _finalGrade = data.finalGrade;
    } catch (e) {
      _subjectGrades = null;
      _evaluationElements = null;
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }
}
