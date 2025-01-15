class Tests {
  final Map<String, List<TestDetail>> testsByMonth;

  Tests({required this.testsByMonth});

  factory Tests.fromJson(Map<String, dynamic> json) {
    final Map<String, List<TestDetail>> parsedTestsByMonth = {};

    json.forEach((month, tests) {
      parsedTestsByMonth[month] = (tests as List).map((test) {
        return TestDetail.fromJson(test as Map<String, dynamic>);
      }).toList();
    });

    return Tests(testsByMonth: parsedTestsByMonth);
  }
}

class TestDetail {
  final String testName;
  final String testDate;
  final String testDescription;

  TestDetail({
    required this.testName,
    required this.testDate,
    required this.testDescription,
  });

  factory TestDetail.fromJson(Map<String, dynamic> json) {
    return TestDetail(
      testName: json['testName'],
      testDate: json['testDate'],
      testDescription: json['testDescription'],
    );
  }
}
