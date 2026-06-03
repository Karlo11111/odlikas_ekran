import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:odlikas_ekran/exceptions/app_exceptions.dart';

class LeaderboardEntry {
  final String nickname;
  final double combinedScore;
  final int currentStreak;
  final double gradeDeltaScore;
  final double streakScore;
  final String? classId;
  final String? city;
  final String? county;

  const LeaderboardEntry({
    required this.nickname,
    required this.combinedScore,
    required this.currentStreak,
    required this.gradeDeltaScore,
    required this.streakScore,
    this.classId,
    this.city,
    this.county,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      nickname: json['nickname'] as String,
      combinedScore: (json['combinedScore'] as num).toDouble(),
      currentStreak: json['currentStreak'] as int,
      gradeDeltaScore: (json['gradeDeltaScore'] as num).toDouble(),
      streakScore: (json['streakScore'] as num).toDouble(),
      classId: json['classId'] as String?,
      city: json['city'] as String?,
      county: json['county'] as String?,
    );
  }
}

class LeaderboardService {
  final String _baseUrl;

  LeaderboardService() : _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<Map<String, String>> _headers() async {
    final box = await Hive.openBox('user_credentials');
    final token = box.get('token') as String? ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> optIn({
    required String nickname,
    required String classId,
    required String schoolId,
    required String city,
    required String county,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Leaderboard/OptIn'),
      headers: await _headers(),
      body: jsonEncode({
        'nickname': nickname,
        'classId': classId,
        'schoolId': schoolId,
        'city': city,
        'county': county,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw ApiException(response.statusCode, response.body);
  }

  Future<void> optOut() async {
    await http.delete(
      Uri.parse('$_baseUrl/api/Leaderboard/OptOut'),
      headers: await _headers(),
    );
  }

  Future<List<LeaderboardEntry>> getClassLeaderboard(
      String schoolId, String classId) async {
    if (schoolId.isEmpty || classId.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Leaderboard/School/$schoolId/Class/$classId'),
      headers: await _headers(),
    );
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'getClassLeaderboard failed');
    }
    return (jsonDecode(response.body) as List)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntry>> getSchoolLeaderboard(String schoolId) async {
    if (schoolId.isEmpty) return [];
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Leaderboard/School/$schoolId'),
      headers: await _headers(),
    );
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'getSchoolLeaderboard failed');
    }
    return (jsonDecode(response.body) as List)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntry>> getProgramLeaderboard(String program) async {
    if (program.isEmpty) return [];
    final encoded = Uri.encodeComponent(program);
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Leaderboard/Program/$encoded'),
      headers: await _headers(),
    );
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'getProgramLeaderboard failed');
    }
    return (jsonDecode(response.body) as List)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
