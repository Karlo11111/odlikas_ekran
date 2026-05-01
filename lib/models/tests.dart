// klasa za model testova
class Tests {
  final Map<String, List<TestDetail>> testsByMonth;

  Tests({required this.testsByMonth});

  // metoda za pretvorbu JSON objekta u Tests objekt
  factory Tests.fromJson(Map<String, dynamic> json) {
    final Map<String, List<TestDetail>> parsedTestsByMonth = {};
    final data = json['data'] as Map<String, dynamic>? ?? json;

    data.forEach((month, tests) {
      parsedTestsByMonth[month] = (tests as List).map((test) {
        return TestDetail.fromJson(test as Map<String, dynamic>);
      }).toList();
    });

    return Tests(testsByMonth: parsedTestsByMonth);
  }
}

// klasa za model detaljnijeg objekta testa
class TestDetail {
  final String testName;
  final String testDate;
  final String testDescription;

  TestDetail({
    required this.testName,
    required this.testDate,
    required this.testDescription,
  });

  // metoda za pretvorbu JSON objekta u TestDetail objekt
  factory TestDetail.fromJson(Map<String, dynamic> json) {
    return TestDetail(
      testName: json['testName'],
      testDate: json['testDate'],
      testDescription: json['testDescription'],
    );
  }
}
