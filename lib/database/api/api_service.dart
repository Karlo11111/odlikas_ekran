import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<Map<String, dynamic>> fetchStudentProfile(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/api/Scraper/ScrapeStudentProfile');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch student profile');
    }
  }

  Future<Map<String, dynamic>> fetchGrades(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/api/Scraper/ScrapeSubjectsAndProfessors');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch student profile');
    }
  }
}
