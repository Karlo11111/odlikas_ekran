import 'package:odlikas_ekran/models/tests.dart';

class RecommendationViewModel {
  List<Map<String, dynamic>> getRecommendations(Tests? tests) {
    if (tests == null) {
      return [];
    }

    final now = DateTime.now();
    final recommendations = <Map<String, dynamic>>[];

    // Collect all TestDetail objects from all months
    final allTestDetails = <TestDetail>[];
    tests.testsByMonth.forEach((month, testsInMonth) {
      allTestDetails.addAll(testsInMonth);
    });

    // Process each TestDetail
    for (final test in allTestDetails) {
      DateTime? testDate;
      try {
        final dateParts = test.testDate.split('.');
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        testDate = DateTime(DateTime.now().year, month, day);
      } catch (e) {
        print("Error parsing date for test: $e");
        continue;
      }

      final daysUntilTest = testDate.difference(now).inDays;

      if (daysUntilTest <= 14 && daysUntilTest > 0) {
        recommendations.add({
          'title':
              "Bilo bi dobro početi učiti ${test.testName}. Još $daysUntilTest dana do ispita!",
          'daysLeft': daysUntilTest,
        });
      }
    }

    return recommendations.reversed.toList();
  }
}
