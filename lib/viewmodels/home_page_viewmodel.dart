import 'package:flutter/foundation.dart';
import '../database/api/api_service.dart';

class HomePageViewModel extends ChangeNotifier {
  final ApiService _apiService;

  HomePageViewModel(this._apiService);

  bool _isLoading = false;
  Map<String, dynamic>? _studentProfile;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get studentProfile => _studentProfile;

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
}
