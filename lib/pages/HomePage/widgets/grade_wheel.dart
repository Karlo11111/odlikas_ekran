import 'package:flutter/material.dart';
import 'dart:math';

import 'package:odlikas_ekran/models/grades.dart';

class GradeWheel extends StatelessWidget {
  final List<Subject> subjects;

  const GradeWheel({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    double averageGrade = calculateAverageGrade(subjects);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // za skrivanje edge-va
      ),
      height: MediaQuery.of(context).size.width * 0.3,
      width: MediaQuery.of(context).size.width * 0.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width * 0.3,
              MediaQuery.of(context).size.width * 0.3,
            ),
            painter: GradeWheelPainter(subjects),
          ),
          Center(
            child: Text(
              averageGrade.toStringAsFixed(2),
              style: TextStyle(
                fontSize:
                    MediaQuery.of(context).size.width * 0.04, // font prosjeka
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //racunanje prosjeka ocjena iz api-ja
  double calculateAverageGrade(List<Subject> subjects) {
    double totalGrades = 0.0;
    int count = 0;

    for (var subject in subjects) {
      String gradeStr = subject.grade;
      if (gradeStr != 'N/A') {
        double grade = double.parse(gradeStr.replaceAll(',', '.'));
        double roundedGrade = roundGradeCroatian(grade);
        totalGrades += roundedGrade;
        count++;
      }
    }

    return count > 0 ? totalGrades / count : 0.0;
  }

  double roundGradeCroatian(double grade) {
    return (grade >= 4.5) ? 5.0 : grade.roundToDouble();
  }
}

class GradeWheelPainter extends CustomPainter {
  final List<Subject> subjects;

  GradeWheelPainter(this.subjects);

  @override
  void paint(Canvas canvas, Size size) {
    //centar kruga
    final center = Offset(size.width / 2, size.height / 2);

    // velicina i radius kruga
    final radius = size.width / 3;

    // prikupljanje ocjena i zbroj ponavljanja
    final Map<double, int> gradeCounts = {};
    for (var subject in subjects) {
      String gradeStr = subject.grade;
      if (gradeStr == 'N/A') continue;

      double grade = double.parse(gradeStr.replaceAll(',', '.'));
      double roundedGrade = roundGradeCroatian(grade);
      gradeCounts[roundedGrade] = (gradeCounts[roundedGrade] ?? 0) + 1;
    }

    // broj predmeta i ocjena koji se vaze
    final int totalSubjects = gradeCounts.values.fold(0, (a, b) => a + b);

    double startAngle = -pi / 2; // da krene od vrha kruga (za ocjene)

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09 // ŠIRINA LINIJE KRUGA
      ..strokeCap = StrokeCap.butt;

    // lukovi za svaku ocjenu
    gradeCounts.forEach((grade, count) {
      final sweepAngle = (count / totalSubjects) * 2 * pi;
      paint.color = getColorForGrade(grade);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle +=
          sweepAngle; // prijedi na sljedeci segment, jer tako ce ocjene biti jedna do druge
    });
  }

  //boja za svaku ocjenu
  Color getColorForGrade(double grade) {
    if (grade == 5.0) return Colors.green;
    if (grade == 4.0) return Colors.yellow;
    if (grade == 3.0) return Colors.orange;
    return Colors.red;
  }

  //hrvatski nacin racunanja ocjene (zaokruzivanje za zavrsni prosjek)
  double roundGradeCroatian(double grade) {
    return (grade >= 4.5) ? 5.0 : grade.roundToDouble();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
