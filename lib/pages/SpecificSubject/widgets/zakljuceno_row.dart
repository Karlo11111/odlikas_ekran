import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_ekran/viewmodels/viewmodel.dart';

class ZakljucenoRow extends StatelessWidget {
  const ZakljucenoRow({super.key, required this.viewModel});

  final HomePageViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    double _calculateAverageGrade(HomePageViewModel viewModel) {
      final List<double> allGrades = [];

      // prodi kroz svaki element ocjenjivanja
      for (final element in viewModel.evaluationElements!) {
        // svaki element ima ocjene po mjesecima
        for (final gradeString in element.gradesByMonth) {
          // preskoci prazne ocjene
          if (gradeString.isNotEmpty) {
            final parsed = double.tryParse(gradeString);
            if (parsed != null) {
              allGrades.add(parsed);
            }
          }
        }
      }

      if (allGrades.isEmpty) {
        return 0;
      }

      // kalkulacija prosjeka ocjena
      final sum = allGrades.reduce((a, b) => a + b);
      return sum / allGrades.length;
    }

    return Row(
      children: [
        Expanded(
          flex: 5, // OMJERI SIRINE REDAKA
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromRGBO(113, 113, 113, 1),
                width: 0.4,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
              ),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ),
            child: Row(
              children: [
                const SizedBox(width: 15),
                Text(
                  "PROSJEK OCJENA: ",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 50),
                Text(
                  _calculateAverageGrade(viewModel).toStringAsFixed(2),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: Colors.blue,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 6, // OMJERI REDAKA
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromRGBO(113, 113, 113, 1),
                width: 0.4,
              ),
              borderRadius:
                  const BorderRadius.only(bottomRight: Radius.circular(15)),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ),
            child: Row(
              children: [
                const SizedBox(width: 15),
                Text(
                  "ZAKLJUČENA OCJENA: ",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 50),
                Text(
                  viewModel.finalGrade ?? "",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    color: Colors.blue,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4, //prazni stupci
          child: Container(),
        ),
      ],
    );
  }
}
