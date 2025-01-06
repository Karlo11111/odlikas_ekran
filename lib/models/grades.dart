class Grades {
  final List<Subject> subjects;

  Grades({
    required this.subjects,
  });

  factory Grades.fromJson(Map<String, dynamic> json) {
    return Grades(
      subjects: (json['subjects'] as List<dynamic>)
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Subject {
  final String grade, subjectId, professor, subjectName;

  Subject({
    required this.subjectName,
    required this.grade,
    required this.professor,
    required this.subjectId,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectName: json['subjectName'] ?? '',
      grade: json['grade'] ?? 'N/A',
      subjectId: json['subjectId'] ?? '',
      professor: json['professor'] ?? 0,
    );
  }
}
