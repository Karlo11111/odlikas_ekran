import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_ekran/viewmodels/home_page_viewmodel.dart';

class EvaluationTable extends StatelessWidget {
  const EvaluationTable({super.key, required this.viewModel});

  final HomePageViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Table(
      // Table border for top part only
      border: TableBorder.all(
        color: const Color.fromRGBO(113, 113, 113, 1),
        width: 0.4,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      columnWidths: const {
        // Same ratio you'll use below for the Row
        0: FlexColumnWidth(5), // For the "OCJENE" and element names
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
        6: FlexColumnWidth(1),
        7: FlexColumnWidth(1),
        8: FlexColumnWidth(1),
        9: FlexColumnWidth(1),
        10: FlexColumnWidth(1),
      },
      children: [
        // Table Header
        TableRow(
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          children: [
            _buildTableHeaderCell("OCJENE", true),
            _buildTableHeaderCell("IX", false),
            _buildTableHeaderCell("X", false),
            _buildTableHeaderCell("XI", false),
            _buildTableHeaderCell("XII", false),
            _buildTableHeaderCell("I", false),
            _buildTableHeaderCell("II", false),
            _buildTableHeaderCell("III", false),
            _buildTableHeaderCell("IV", false),
            _buildTableHeaderCell("V", false),
            _buildTableHeaderCell("VI", false),
          ],
        ),
        // Table Rows
        ...viewModel.evaluationElements!.map((element) {
          return TableRow(
            children: [
              _buildTableCell(element.name),
              ...element.gradesByMonth.map((grade) {
                return _buildTableCell(grade.isNotEmpty ? grade : "");
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text, bool isWider) {
    return Container(
      alignment: !isWider ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontSize: 24,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Table Body Cells
  Widget _buildTableCell(String text) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: Colors.black,
            fontSize: 20,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
