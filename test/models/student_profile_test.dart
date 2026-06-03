import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/models/student_profile.dart';

void main() {
  const fullProfile = {
    'studentSchool': 'Tehnička škola',
    'studentSchoolCity': 'Zagreb',
    'studentSchoolYear': '2025/2026',
    'studentGrade': '3.A',
    'studentName': 'Ivan Horvat',
    'studentProgram': 'Tehničar za računalstvo',
    'classMaster': 'Pero Perić',
  };

  group('StudentProfile.fromJson', () {
    test('parses profile from data.studentProfile path', () {
      final profile = StudentProfile.fromJson({
        'data': {'studentProfile': fullProfile},
      });
      expect(profile.studentName, 'Ivan Horvat');
      expect(profile.studentSchool, 'Tehnička škola');
      expect(profile.studentSchoolCity, 'Zagreb');
      expect(profile.studentSchoolYear, '2025/2026');
      expect(profile.studentGrade, '3.A');
      expect(profile.studentProgram, 'Tehničar za računalstvo');
      expect(profile.classMaster, 'Pero Perić');
    });

    test('parses profile from studentProfile at root (no data wrapper)', () {
      final profile = StudentProfile.fromJson({'studentProfile': fullProfile});
      expect(profile.studentName, 'Ivan Horvat');
      expect(profile.studentSchool, 'Tehnička škola');
    });

    test('defaults all fields to empty string when studentProfile key missing', () {
      final profile = StudentProfile.fromJson({});
      expect(profile.studentName, '');
      expect(profile.studentSchool, '');
      expect(profile.studentSchoolCity, '');
      expect(profile.studentSchoolYear, '');
      expect(profile.studentGrade, '');
      expect(profile.studentProgram, '');
      expect(profile.classMaster, '');
    });

    test('defaults missing fields to empty string when profile is partial', () {
      final profile = StudentProfile.fromJson({
        'studentProfile': {'studentName': 'Ana'},
      });
      expect(profile.studentName, 'Ana');
      expect(profile.studentSchool, '');
      expect(profile.classMaster, '');
    });
  });
}
