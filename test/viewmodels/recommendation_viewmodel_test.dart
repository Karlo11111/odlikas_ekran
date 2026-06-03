import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/models/tests.dart';
import 'package:odlikas_ekran/viewmodels/recommendation_viewmodel.dart';

String _dateStr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

void main() {
  final viewmodel = RecommendationViewModel();

  group('RecommendationViewModel.getRecommendations', () {
    test('returns empty list when tests is null', () {
      expect(viewmodel.getRecommendations(null), isEmpty);
    });

    test('returns empty list when testsByMonth is empty', () {
      expect(viewmodel.getRecommendations(Tests(testsByMonth: {})), isEmpty);
    });

    test('returns recommendation for test within 14 days', () {
      final target = DateTime.now().add(const Duration(days: 5));
      final tests = Tests(testsByMonth: {
        'Test': [
          TestDetail(testName: 'Matematika', testDate: _dateStr(target), testDescription: ''),
        ],
      });
      final results = viewmodel.getRecommendations(tests);
      expect(results.length, 1);
      expect(results.first['title'], contains('Matematika'));
      expect(results.first['daysLeft'], greaterThan(0));
      expect(results.first['daysLeft'], lessThanOrEqualTo(14));
    });

    test('excludes test more than 14 days away', () {
      final target = DateTime.now().add(const Duration(days: 20));
      final tests = Tests(testsByMonth: {
        'Test': [
          TestDetail(testName: 'Fizika', testDate: _dateStr(target), testDescription: ''),
        ],
      });
      expect(viewmodel.getRecommendations(tests), isEmpty);
    });

    test('excludes test that is today', () {
      final tests = Tests(testsByMonth: {
        'Test': [
          TestDetail(testName: 'Kemija', testDate: _dateStr(DateTime.now()), testDescription: ''),
        ],
      });
      expect(viewmodel.getRecommendations(tests), isEmpty);
    });

    test('excludes past tests', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tests = Tests(testsByMonth: {
        'Test': [
          TestDetail(testName: 'Povijest', testDate: _dateStr(yesterday), testDescription: ''),
        ],
      });
      expect(viewmodel.getRecommendations(tests), isEmpty);
    });

    test('skips tests with invalid date format without throwing', () {
      final tests = Tests(testsByMonth: {
        'Test': [
          TestDetail(testName: 'Geografija', testDate: 'invalid-date', testDescription: ''),
        ],
      });
      expect(() => viewmodel.getRecommendations(tests), returnsNormally);
      expect(viewmodel.getRecommendations(tests), isEmpty);
    });

    test('recommendation title contains days left count', () {
      final target = DateTime.now().add(const Duration(days: 5));
      final tests = Tests(testsByMonth: {
        'Test': [
          TestDetail(testName: 'Biologija', testDate: _dateStr(target), testDescription: ''),
        ],
      });
      final results = viewmodel.getRecommendations(tests);
      expect(results.first['title'], contains('dana'));
    });

    test('returns recommendations in reversed order (furthest first)', () {
      final soon = DateTime.now().add(const Duration(days: 3));
      final later = DateTime.now().add(const Duration(days: 10));
      final tests = Tests(testsByMonth: {
        'Test': [
          TestDetail(testName: 'Fizika', testDate: _dateStr(soon), testDescription: ''),
          TestDetail(testName: 'Kemija', testDate: _dateStr(later), testDescription: ''),
        ],
      });
      final results = viewmodel.getRecommendations(tests);
      expect(results.length, 2);
      expect(results.first['title'], contains('Kemija'));
      expect(results.last['title'], contains('Fizika'));
    });
  });
}
