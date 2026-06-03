import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/models/tests.dart';

void main() {
  group('TestDetail.fromJson', () {
    test('parses all fields', () {
      final detail = TestDetail.fromJson({
        'testName': 'Pismena provjera',
        'testDate': '15.06',
        'testDescription': 'Poglavlja 1-3',
      });
      expect(detail.testName, 'Pismena provjera');
      expect(detail.testDate, '15.06');
      expect(detail.testDescription, 'Poglavlja 1-3');
    });
  });

  group('Tests.fromJson', () {
    test('parses tests grouped by month', () {
      final tests = Tests.fromJson({
        'Lipanj': [
          {'testName': 'Test A', 'testDate': '10.06', 'testDescription': 'Opis A'},
        ],
        'Srpanj': [
          {'testName': 'Test B', 'testDate': '05.07', 'testDescription': 'Opis B'},
          {'testName': 'Test C', 'testDate': '20.07', 'testDescription': 'Opis C'},
        ],
      });
      expect(tests.testsByMonth.keys, containsAll(['Lipanj', 'Srpanj']));
      expect(tests.testsByMonth['Lipanj']!.length, 1);
      expect(tests.testsByMonth['Srpanj']!.length, 2);
      expect(tests.testsByMonth['Lipanj']!.first.testName, 'Test A');
      expect(tests.testsByMonth['Srpanj']!.last.testName, 'Test C');
    });

    test('parses tests wrapped in data key', () {
      final tests = Tests.fromJson({
        'data': {
          'Lipanj': [
            {'testName': 'Test A', 'testDate': '10.06', 'testDescription': 'Opis A'},
          ],
        },
      });
      expect(tests.testsByMonth['Lipanj']!.length, 1);
      expect(tests.testsByMonth['Lipanj']!.first.testDate, '10.06');
    });

    test('returns empty map for empty input', () {
      final tests = Tests.fromJson({});
      expect(tests.testsByMonth, isEmpty);
    });

    test('preserves test description', () {
      final tests = Tests.fromJson({
        'Lipanj': [
          {'testName': 'Matematika', 'testDate': '01.06', 'testDescription': 'Derivacije i integrali'},
        ],
      });
      expect(tests.testsByMonth['Lipanj']!.first.testDescription, 'Derivacije i integrali');
    });
  });
}
