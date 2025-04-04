import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:odlikas_ekran/models/grades.dart';
import 'package:odlikas_ekran/models/specific_subject.dart';
import 'package:odlikas_ekran/models/student_profile.dart';
import 'package:odlikas_ekran/models/tests.dart';

// klasa koja sadrži metode za dohvaćanje podataka s ASP.NET API-ja
class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  // metoda za dohvaćanje osnovnih podataka o uceniku
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

  // metoda za dohvaćanje ocjena
  Future<Grades> fetchGrades(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/Scraper/ScrapeSubjectsAndProfessors');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Grades.fromJson(data);
    } else {
      throw Exception('Failed to fetch grades');
    }
  }

  // metoda za dohvaćanje ocjena za određeni predmet
  Future<List<MonthlyGrades>> fetchSpecificSubjectGrades(
      String email, String password, String subjectId) async {
    final url = Uri.parse(
        '$baseUrl/api/Scraper/ScrapeSpecificSubjectGrades?subjectId=$subjectId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List)
          .map((month) => MonthlyGrades.fromJson(month))
          .toList();
    } else {
      throw Exception('Failed to fetch specific subject grades');
    }
  }

  // metoda za dohvaćanje detalja o određenom predmetu
  Future<SubjectDetails> fetchSpecificSubjectDetails(
      String email, String password, String subjectId) async {
    final url = Uri.parse(
        '$baseUrl/api/scraper/ScrapeSpecificSubjectGrades?subjectId=$subjectId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SubjectDetails.fromJson(data);
    } else {
      throw Exception('Failed to fetch specific subject details');
    }
  }

  // metoda za dohvaćanje detalja o testovima
  Future<Tests> fetchTestsDetails(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/scraper/ScrapeTests');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'Password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Tests.fromJson(data);
    } else {
      throw Exception('Failed to fetch specific subject details');
    }
  }
}
