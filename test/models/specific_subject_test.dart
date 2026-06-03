import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/models/specific_subject.dart';

void main() {
  group('SpecificSubject.fromJson', () {
    test('parses all fields', () {
      final subject = SpecificSubject.fromJson({
        'gradeDate': '01.06.2026',
        'gradeNote': 'Usmena provjera',
        'grade': '5',
      });
      expect(subject.gradeDate, '01.06.2026');
      expect(subject.gradeNote, 'Usmena provjera');
      expect(subject.grade, '5');
    });
  });

  group('EvaluationElement.fromJson', () {
    test('parses name and gradesByMonth list', () {
      final element = EvaluationElement.fromJson({
        'name': 'Pismene provjere',
        'gradesByMonth': ['5', '4', '5'],
      });
      expect(element.name, 'Pismene provjere');
      expect(element.gradesByMonth, ['5', '4', '5']);
    });

    test('parses empty gradesByMonth', () {
      final element = EvaluationElement.fromJson({
        'name': 'Usmene provjere',
        'gradesByMonth': [],
      });
      expect(element.gradesByMonth, isEmpty);
    });

    test('preserves order of grades', () {
      final element = EvaluationElement.fromJson({
        'name': 'Test',
        'gradesByMonth': ['3', '5', '4', '2'],
      });
      expect(element.gradesByMonth, ['3', '5', '4', '2']);
    });
  });

  group('MonthlyGrades.fromJson', () {
    test('parses month and grades list', () {
      final monthly = MonthlyGrades.fromJson({
        'month': 'Lipanj',
        'grades': [
          {'gradeDate': '01.06', 'gradeNote': 'Provjera', 'grade': '5'},
          {'gradeDate': '15.06', 'gradeNote': 'Usmeno', 'grade': '4'},
        ],
      });
      expect(monthly.month, 'Lipanj');
      expect(monthly.grades.length, 2);
      expect(monthly.grades.first.grade, '5');
      expect(monthly.grades.last.grade, '4');
    });

    test('parses empty grades list', () {
      final monthly = MonthlyGrades.fromJson({'month': 'Srpanj', 'grades': []});
      expect(monthly.month, 'Srpanj');
      expect(monthly.grades, isEmpty);
    });
  });

  group('SubjectDetails.fromJson', () {
    final rawJson = {
      'finalGrade': '5',
      'evaluationElements': [
        {
          'name': 'Pismene provjere',
          'gradesByMonth': ['5', '4'],
        },
      ],
      'monthlyGrades': [
        {
          'month': 'Lipanj',
          'grades': [
            {'gradeDate': '01.06', 'gradeNote': 'Test', 'grade': '5'},
          ],
        },
      ],
    };

    test('parses finalGrade, evaluationElements and monthlyGrades', () {
      final details = SubjectDetails.fromJson(rawJson);
      expect(details.finalGrade, '5');
      expect(details.evaluationElements.length, 1);
      expect(details.evaluationElements.first.name, 'Pismene provjere');
      expect(details.monthlyGrades.length, 1);
      expect(details.monthlyGrades.first.month, 'Lipanj');
    });

    test('parses when wrapped in data key', () {
      final details = SubjectDetails.fromJson({'data': rawJson});
      expect(details.finalGrade, '5');
      expect(details.evaluationElements.length, 1);
    });

    test('parses empty evaluation elements and monthly grades', () {
      final details = SubjectDetails.fromJson({
        'finalGrade': 'N/A',
        'evaluationElements': [],
        'monthlyGrades': [],
      });
      expect(details.evaluationElements, isEmpty);
      expect(details.monthlyGrades, isEmpty);
    });
  });
}
