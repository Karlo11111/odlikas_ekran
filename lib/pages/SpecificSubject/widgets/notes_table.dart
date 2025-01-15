import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_ekran/viewmodels/viewmodel.dart';

class NotesTable extends StatelessWidget {
  final HomePageViewModel viewModel;

  const NotesTable({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final notes =
        viewModel.subjectGrades?.expand((month) => month.grades).toList() ?? [];

    if (notes.isEmpty) {
      return const Text("Trenutno nema bilješki za ovaj predmet.");
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // narančasti header
        Table(
          columnWidths: const {0: FlexColumnWidth()},
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "BILJEŠKE",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),

        // retci s podatcima
        Table(
          border: const TableBorder(
            left:
                BorderSide(color: Color.fromRGBO(113, 113, 113, 1), width: 0.4),
            right:
                BorderSide(color: Color.fromRGBO(113, 113, 113, 1), width: 0.4),
            bottom:
                BorderSide(color: Color.fromRGBO(113, 113, 113, 1), width: 0.4),
            horizontalInside:
                BorderSide(color: Color.fromRGBO(113, 113, 113, 1), width: 0.4),
            verticalInside:
                BorderSide(color: Color.fromRGBO(113, 113, 113, 1), width: 0.4),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(5),
          },
          children: [
            for (int i = 0; i < notes.length; i++)
              TableRow(
                children: [
                  _buildNotesCellWithRadius(
                    notes[i].gradeDate,
                    i == notes.length - 1
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                          )
                        : null,
                  ),
                  _buildNotesCellWithRadius(
                    notes[i].grade,
                    null,
                  ),
                  _buildNotesCellWithRadius(
                    notes[i].gradeNote,
                    i == notes.length - 1
                        ? const BorderRadius.only(
                            bottomRight: Radius.circular(15),
                          )
                        : null,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesCellWithRadius(String text, BorderRadius? borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        color: Colors.white,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
