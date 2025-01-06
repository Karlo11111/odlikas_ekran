class StudentProfile {
  final String studentSchool;
  final String studentSchoolCity;
  final String studentSchoolYear;
  final String studentGrade;
  final String studentName;

  StudentProfile({
    required this.studentSchool,
    required this.studentSchoolCity,
    required this.studentSchoolYear,
    required this.studentGrade,
    required this.studentName,
  });

  // Factory method to create a StudentProfile from JSON
  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['studentProfile'] ?? {};
    return StudentProfile(
      studentSchool: profile['studentSchool'] ?? '',
      studentSchoolCity: profile['studentSchoolCity'] ?? '',
      studentSchoolYear: profile['studentSchoolYear'] ?? '',
      studentGrade: profile['studentGrade'] ?? '',
      studentName: profile['studentName'] ?? '',
    );
  }
}
