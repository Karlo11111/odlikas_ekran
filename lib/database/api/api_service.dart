import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:odlikas_ekran/exceptions/app_exceptions.dart';
import 'package:odlikas_ekran/models/grades.dart';
import 'package:odlikas_ekran/models/specific_subject.dart';
import 'package:odlikas_ekran/models/student_profile.dart';
import 'package:odlikas_ekran/models/tests.dart';

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
      };

  Future<StudentProfile> fetchStudentProfile(String token) async {
    final url = Uri.parse('$baseUrl/api/Scraper/ScrapeStudentProfile');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return StudentProfile.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'fetchStudentProfile failed');
  }

  Future<Grades> fetchGrades(String token) async {
    final url =
        Uri.parse('$baseUrl/api/Scraper/ScrapeSubjectsAndProfessors');
    final response = await http.get(url, headers: _headers(token));
    debugPrint('[API] fetchGrades status: ${response.statusCode}');
    debugPrint('[API] fetchGrades body: ${response.body}');
    if (response.statusCode == 200) {
      return Grades.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'fetchGrades failed');
  }

  Future<List<MonthlyGrades>> fetchSpecificSubjectGrades(
      String token, String subjectId) async {
    final url = Uri.parse(
        '$baseUrl/api/Scraper/ScrapeSpecificSubjectGrades?subjectId=$subjectId');
    final response = await http.get(url, headers: _headers(token));
    debugPrint('[API] fetchSpecificSubjectGrades body: ${response.body}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = (decoded is Map ? decoded['data'] : decoded) as List;
      return list.map((m) => MonthlyGrades.fromJson(m as Map<String, dynamic>)).toList();
    }
    throw ApiException(response.statusCode, 'fetchSpecificSubjectGrades failed');
  }

  Future<SubjectDetails> fetchSpecificSubjectDetails(
      String token, String subjectId) async {
    final url = Uri.parse(
        '$baseUrl/api/Scraper/ScrapeSpecificSubjectGrades?subjectId=$subjectId');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return SubjectDetails.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'fetchSpecificSubjectDetails failed');
  }

  Future<Tests> fetchTestsDetails(String token) async {
    final url = Uri.parse('$baseUrl/api/scraper/ScrapeTests');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      return Tests.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'fetchTestsDetails failed');
  }

  Future<({bool isOdlikasPlus, DateTime? odlikasPlusSince})> fetchAccountStatus(String token) async {
    final url = Uri.parse('$baseUrl/api/Account/Status');
    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? json;
      final since = data['odlikasPlusSince'] as String?;
      return (
        isOdlikasPlus: data['isOdlikasPlus'] as bool,
        odlikasPlusSince: since != null ? DateTime.parse(since) : null,
      );
    }
    throw ApiException(response.statusCode, 'fetchAccountStatus failed');
  }
}
