// klasa za model ocjena
class Grades {
  final List<Subject> subjects;

  Grades({
    required this.subjects,
  });

  // metoda za pretvorbu JSON objekta u Grades objekt
  factory Grades.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return Grades(
      subjects: (data['subjects'] as List<dynamic>)
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// klasa za model specificnog predmeta
class Subject {
  final String grade, subjectId, professor, subjectName;

  Subject({
    required this.subjectName,
    required this.grade,
    required this.professor,
    required this.subjectId,
  });

  // metoda za pretvorbu JSON objekta u Subject objekt
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectName: json['subjectName'] ?? '',
      grade: json['grade'] ?? 'N/A',
      subjectId: json['subjectId'] ?? '',
      professor: json['professor'] ?? 0,
    );
  }
}
