import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/database/api/pomodoro_api_service.dart';

void main() {
  group('PomodoroSessionResult.fromStreakJson', () {
    test('parses all fields correctly', () {
      final result = PomodoroSessionResult.fromStreakJson({
        'currentStreak': 3,
        'longestStreak': 7,
        'todaySessions': 2,
        'todayMinutes': 50,
      });
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 7);
      expect(result.todaySessions, 2);
      expect(result.todayMinutes, 50);
      expect(result.capped, isNull);
    });

    test('defaults to 0 for missing fields', () {
      final result = PomodoroSessionResult.fromStreakJson({});
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.todaySessions, 0);
      expect(result.todayMinutes, 0);
    });

    test('handles num type (not just int)', () {
      final result = PomodoroSessionResult.fromStreakJson({
        'currentStreak': 3.0,
        'longestStreak': 7.0,
        'todaySessions': 2.0,
        'todayMinutes': 50.0,
      });
      expect(result.todaySessions, 2);
    });
  });

  group('PomodoroSessionResult.fromCompleteJson', () {
    test('parses streak nested object and capped flag', () {
      final result = PomodoroSessionResult.fromCompleteJson({
        'streak': {
          'currentStreak': 3,
          'longestStreak': 7,
          'todaySessions': 3,
          'todayMinutes': 75,
        },
        'capped': false,
      });
      expect(result.currentStreak, 3);
      expect(result.todaySessions, 3);
      expect(result.todayMinutes, 75);
      expect(result.capped, false);
    });

    test('capped is true when server returns true', () {
      final result = PomodoroSessionResult.fromCompleteJson({
        'streak': {
          'currentStreak': 5,
          'longestStreak': 10,
          'todaySessions': 8,
          'todayMinutes': 200,
        },
        'capped': true,
      });
      expect(result.capped, true);
    });

    test('defaults to 0 for missing streak key', () {
      final result = PomodoroSessionResult.fromCompleteJson({
        'streak': <String, dynamic>{},
        'capped': null,
      });
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.todaySessions, 0);
      expect(result.todayMinutes, 0);
      expect(result.capped, isNull);
    });
  });
}
