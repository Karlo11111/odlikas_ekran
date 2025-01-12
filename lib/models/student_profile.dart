class StudentProfile {
  final String studentSchool;
  final String studentSchoolCity;
  final String studentSchoolYear;
  final String studentGrade;
  final String studentName;
  final String studentProgram;
  final String classMaster;

  StudentProfile({
    required this.studentSchool,
    required this.studentSchoolCity,
    required this.studentSchoolYear,
    required this.studentGrade,
    required this.studentName,
    required this.studentProgram,
    required this.classMaster,
  });

  // kreiranje StudentProfila iz json-a koji fetcha api
  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['studentProfile'] ?? {};
    return StudentProfile(
      studentSchool: profile['studentSchool'] ?? '',
      studentSchoolCity: profile['studentSchoolCity'] ?? '',
      studentSchoolYear: profile['studentSchoolYear'] ?? '',
      studentGrade: profile['studentGrade'] ?? '',
      studentName: profile['studentName'] ?? '',
      studentProgram: profile['studentProgram'] ?? '',
      classMaster: profile['classMaster'] ?? '',
    );
  }
}
