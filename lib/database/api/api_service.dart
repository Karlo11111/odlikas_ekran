import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:odlikas_ekran/models/grades.dart';
import 'package:odlikas_ekran/models/student_profile.dart';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<StudentProfile> fetchStudentProfile(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/api/Scraper/ScrapeStudentProfile');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return StudentProfile.fromJson(data); //convert to StudentProfile
    } else {
      throw Exception('Failed to fetch student profile');
    }
  }

  Future<Grades> fetchGrades(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/Scraper/ScrapeSubjectsAndProfessors');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return Grades.fromJson(data); // Ensure this is correctly mapping the data
    } else {
      throw Exception('Failed to fetch grades');
    }
  }
}
