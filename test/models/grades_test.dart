import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/models/grades.dart';

void main() {
  group('Subject.fromJson', () {
    test('parses all fields', () {
      final subject = Subject.fromJson({
        'subjectName': 'Matematika',
        'grade': '5',
        'professor': 'Horvat',
        'subjectId': 'MAT-01',
      });
      expect(subject.subjectName, 'Matematika');
      expect(subject.grade, '5');
      expect(subject.professor, 'Horvat');
      expect(subject.subjectId, 'MAT-01');
    });

    test('defaults to empty string for missing subjectName and subjectId', () {
      final subject = Subject.fromJson({});
      expect(subject.subjectName, '');
      expect(subject.subjectId, '');
    });

    test('defaults grade to N/A when missing', () {
      final subject = Subject.fromJson({});
      expect(subject.grade, 'N/A');
    });
  });

  group('Grades.fromJson', () {
    test('parses subjects list from root json', () {
      final grades = Grades.fromJson({
        'subjects': [
          {'subjectName': 'Fizika', 'grade': '4', 'professor': 'Novak', 'subjectId': 'FIZ-01'},
        ],
      });
      expect(grades.subjects.length, 1);
      expect(grades.subjects.first.subjectName, 'Fizika');
    });

    test('parses subjects list wrapped in data key', () {
      final grades = Grades.fromJson({
        'data': {
          'subjects': [
            {'subjectName': 'Kemija', 'grade': '3', 'professor': 'Kovač', 'subjectId': 'KEM-01'},
          ],
        },
      });
      expect(grades.subjects.length, 1);
      expect(grades.subjects.first.subjectName, 'Kemija');
    });

    test('parses multiple subjects', () {
      final grades = Grades.fromJson({
        'subjects': [
          {'subjectName': 'Fizika', 'grade': '4', 'professor': 'A', 'subjectId': '1'},
          {'subjectName': 'Kemija', 'grade': '5', 'professor': 'B', 'subjectId': '2'},
          {'subjectName': 'Matematika', 'grade': '3', 'professor': 'C', 'subjectId': '3'},
        ],
      });
      expect(grades.subjects.length, 3);
    });

    test('parses empty subjects list', () {
      final grades = Grades.fromJson({'subjects': []});
      expect(grades.subjects, isEmpty);
    });
  });
}
