import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:odlikas_ekran/exceptions/app_exceptions.dart';

class PomodoroSessionResult {
  final int currentStreak;
  final int longestStreak;
  final int todaySessions;
  final int todayMinutes;
  final bool? capped;

  PomodoroSessionResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.todaySessions,
    required this.todayMinutes,
    this.capped,
  });

  factory PomodoroSessionResult.fromStreakJson(Map<String, dynamic> json) {
    return PomodoroSessionResult(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      todaySessions: (json['todaySessions'] as num?)?.toInt() ?? 0,
      todayMinutes: (json['todayMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  factory PomodoroSessionResult.fromCompleteJson(Map<String, dynamic> json) {
    final streak = (json['streak'] as Map<String, dynamic>?) ?? {};
    return PomodoroSessionResult(
      currentStreak: (streak['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (streak['longestStreak'] as num?)?.toInt() ?? 0,
      todaySessions: (streak['todaySessions'] as num?)?.toInt() ?? 0,
      todayMinutes: (streak['todayMinutes'] as num?)?.toInt() ?? 0,
      capped: json['capped'] as bool?,
    );
  }
}

class PomodoroApiService {
  final String baseUrl;

  PomodoroApiService(this.baseUrl);

  Future<Map<String, String>> _headers() async {
    final box = await Hive.openBox('user_credentials');
    final token = box.get('token') as String? ?? '';
    return {'Authorization': 'Bearer $token'};
  }

  Future<PomodoroSessionResult> getStreak() async {
    final url = Uri.parse('$baseUrl/api/Pomodoro/GetStreak');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      return PomodoroSessionResult.fromStreakJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException(response.statusCode, 'GetStreak failed');
  }

  Future<PomodoroSessionResult> completeSession() async {
    final url = Uri.parse('$baseUrl/api/Pomodoro/CompleteSession');
    final response = await http.post(url, headers: await _headers());
    if (response.statusCode == 200) {
      return PomodoroSessionResult.fromCompleteJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException(response.statusCode, 'CompleteSession failed');
  }
}
