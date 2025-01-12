class MonthlyGrades {
  final String month;
  final List<SpecificSubject> grades;

  MonthlyGrades({required this.month, required this.grades});

  factory MonthlyGrades.fromJson(Map<String, dynamic> json) {
    return MonthlyGrades(
      month: json['month'],
      grades: (json['grades'] as List)
          .map((grade) => SpecificSubject.fromJson(grade))
          .toList(),
    );
  }
}

class SubjectDetails {
  final List<EvaluationElement> evaluationElements;
  final List<MonthlyGrades> monthlyGrades;
  final String finalGrade;

  SubjectDetails({
    required this.evaluationElements,
    required this.monthlyGrades,
    required this.finalGrade,
  });

  factory SubjectDetails.fromJson(Map<String, dynamic> json) {
    return SubjectDetails(
      finalGrade: json['finalGrade'],
      evaluationElements: (json['evaluationElements'] as List)
          .map((element) => EvaluationElement.fromJson(element))
          .toList(),
      monthlyGrades: (json['monthlyGrades'] as List)
          .map((month) => MonthlyGrades.fromJson(month))
          .toList(),
    );
  }
}

class EvaluationElement {
  final String name;
  final List<String> gradesByMonth;

  EvaluationElement({
    required this.name,
    required this.gradesByMonth,
  });

  factory EvaluationElement.fromJson(Map<String, dynamic> json) {
    return EvaluationElement(
      name: json['name'],
      gradesByMonth: List<String>.from(json['gradesByMonth']),
    );
  }
}

class SpecificSubject {
  final String gradeDate;
  final String gradeNote;
  final String grade;

  SpecificSubject({
    required this.gradeDate,
    required this.gradeNote,
    required this.grade,
  });

  factory SpecificSubject.fromJson(Map<String, dynamic> json) {
    return SpecificSubject(
      gradeDate: json['gradeDate'],
      gradeNote: json['gradeNote'],
      grade: json['grade'],
    );
  }
}
