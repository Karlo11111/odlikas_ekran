import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/services/leaderboard_service.dart';

void main() {
  group('LeaderboardEntry.fromJson', () {
    test('parses all fields including optional', () {
      final entry = LeaderboardEntry.fromJson({
        'nickname': 'TestUser',
        'combinedScore': 87.5,
        'currentStreak': 5,
        'gradeDeltaScore': 12.3,
        'streakScore': 75.2,
        'classId': 'CLASS-01',
        'city': 'Zagreb',
        'county': 'Grad Zagreb',
      });
      expect(entry.nickname, 'TestUser');
      expect(entry.combinedScore, 87.5);
      expect(entry.currentStreak, 5);
      expect(entry.gradeDeltaScore, closeTo(12.3, 0.001));
      expect(entry.streakScore, closeTo(75.2, 0.001));
      expect(entry.classId, 'CLASS-01');
      expect(entry.city, 'Zagreb');
      expect(entry.county, 'Grad Zagreb');
    });

    test('optional fields default to null when absent', () {
      final entry = LeaderboardEntry.fromJson({
        'nickname': 'User',
        'combinedScore': 50.0,
        'currentStreak': 1,
        'gradeDeltaScore': 10.0,
        'streakScore': 40.0,
      });
      expect(entry.classId, isNull);
      expect(entry.city, isNull);
      expect(entry.county, isNull);
    });

    test('coerces integer scores to double', () {
      final entry = LeaderboardEntry.fromJson({
        'nickname': 'User',
        'combinedScore': 100,
        'currentStreak': 3,
        'gradeDeltaScore': 20,
        'streakScore': 80,
      });
      expect(entry.combinedScore, 100.0);
      expect(entry.combinedScore, isA<double>());
      expect(entry.gradeDeltaScore, isA<double>());
      expect(entry.streakScore, isA<double>());
    });

    test('parses zero scores', () {
      final entry = LeaderboardEntry.fromJson({
        'nickname': 'NewUser',
        'combinedScore': 0,
        'currentStreak': 0,
        'gradeDeltaScore': 0,
        'streakScore': 0,
      });
      expect(entry.combinedScore, 0.0);
      expect(entry.currentStreak, 0);
    });
  });
}
