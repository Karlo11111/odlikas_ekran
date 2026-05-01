// metoda za objekt ocjena po mjesecima
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

// metoda za objekt detalja predmeta
class SubjectDetails {
  final List<EvaluationElement> evaluationElements;
  final List<MonthlyGrades> monthlyGrades;
  final String finalGrade;

  SubjectDetails({
    required this.evaluationElements,
    required this.monthlyGrades,
    required this.finalGrade,
  });

  // metoda za pretvaranje JSON objekta u SubjectDetails objekt
  factory SubjectDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return SubjectDetails(
      finalGrade: data['finalGrade'],
      evaluationElements: (data['evaluationElements'] as List)
          .map((element) => EvaluationElement.fromJson(element))
          .toList(),
      monthlyGrades: (data['monthlyGrades'] as List)
          .map((month) => MonthlyGrades.fromJson(month))
          .toList(),
    );
  }
}

// metoda za objekt elementa evaluacije
class EvaluationElement {
  final String name;
  final List<String> gradesByMonth;

  EvaluationElement({
    required this.name,
    required this.gradesByMonth,
  });

  // metoda za pretvaranje JSON objekta u EvaluationElement objekt
  factory EvaluationElement.fromJson(Map<String, dynamic> json) {
    return EvaluationElement(
      name: json['name'],
      gradesByMonth: List<String>.from(json['gradesByMonth']),
    );
  }
}

// metoda za objekt specificnog predmeta
class SpecificSubject {
  final String gradeDate;
  final String gradeNote;
  final String grade;

  SpecificSubject({
    required this.gradeDate,
    required this.gradeNote,
    required this.grade,
  });

  // metoda za pretvaranje JSON objekta u SpecificSubject objekt
  factory SpecificSubject.fromJson(Map<String, dynamic> json) {
    return SpecificSubject(
      gradeDate: json['gradeDate'],
      gradeNote: json['gradeNote'],
      grade: json['grade'],
    );
  }
}
