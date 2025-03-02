import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:latext/latext.dart';

class SimilarTasksPage extends StatelessWidget {
  final List<Map<String, String>> tasks;
  final String originalTask;

  const SimilarTasksPage({
    Key? key,
    required this.tasks,
    required this.originalTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Split tasks into two lists for left and right columns
    final int halfLength = (tasks.length / 2).ceil();
    final List<Map<String, String>> leftTasks = tasks.take(halfLength).toList();
    final List<Map<String, String>> rightTasks =
        tasks.skip(halfLength).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.only(top: 25, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 40,
                  color: const Color.fromRGBO(236, 145, 32, 1),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Zadatci slični ovome",
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  flex: 4,
                  child: _buildTasksList(leftTasks, 0),
                ),

                // Right Column
                Expanded(
                  flex: 4,
                  child: _buildTasksList(rightTasks, leftTasks.length),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<Map<String, String>> tasks, int startIndex) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final String taskText = _cleanLatexForRendering(task['task'] ?? '');
          final String explanation =
              _betterDiacriticsFix(task['explanation'] ?? '');
          final int displayIndex = startIndex + index + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.white,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Zadatak ${displayIndex}.",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: _renderLatex(taskText),
                  ),
                ],
              ),
              children: [
                Divider(color: Colors.grey.shade300),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    explanation,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _cleanLatexForRendering(String latex) {
    // If the latex is null or empty, return a default value
    if (latex.isEmpty) {
      return '';
    }

    // Remove $$ markers if they exist
    if (latex.startsWith("\$\$") && latex.endsWith("\$\$")) {
      latex = latex.substring(2, latex.length - 2);
    } else if (latex.startsWith("\$") && latex.endsWith("\$")) {
      // Remove single $ markers
      latex = latex.substring(1, latex.length - 1);
    }

    // Handle escaped backslashes properly
    latex = latex.replaceAll(r'\\', r'\');

    // Remove problematic sequences
    latex = latex.replaceAll('\\1', '');
    latex = latex.replaceAll('1\\', '');

    return latex.trim();
  }

  String _betterDiacriticsFix(String text) {
    // Remove the strange character that appears after "Pronač"
    text = text.replaceAll(String.fromCharCode(0x0087), '');
    text = text.replaceAll(String.fromCharCode(0x008D), '');

    // Direct character replacements for Croatian letters
    final Map<String, String> replacements = {
      'Ä': 'č',
      'Å¡': 'š',
      'Å¾': 'ž',
      'Ä‡': 'ć',
    };

    // Apply replacements
    replacements.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    // Handle common word patterns
    final wordReplacements = {
      'PronaÄ': 'Pronađ',
      'IzraÄunaj': 'Izračunaj',
      'jednadÅ¾b': 'jednadžb',
      'konaÄno': 'konačno',
      'mnoÅ¾': 'množ',
      'mnoÅ¾enj': 'množnj',
      'Primjenjuje': 'Primjenjuje',
      'poniÅ¡tavaju': 'poništavaju',
      'cdot': '·',
    };

    // Apply word-level replacements
    wordReplacements.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    return text;
  }

  Widget _renderLatex(String latexString) {
    try {
      // First check if we have LaTeX content
      if (latexString.isEmpty) {
        return const Text("No LaTeX content");
      }

      // Remove $ delimiters if present
      String processedLatex = latexString;
      if (processedLatex.startsWith('\$') && processedLatex.endsWith('\$')) {
        processedLatex = processedLatex.substring(1, processedLatex.length - 1);
      }

      return Math.tex(
        processedLatex,
        textStyle: GoogleFonts.inter(fontSize: 26),
        onErrorFallback: (err) {
          // Try with LaTexT as fallback
          try {
            return LaTexT(
              laTeXCode: Text(
                latexString, // Use original string with $ delimiters
                style: GoogleFonts.inter(fontSize: 22),
              ),
            );
          } catch (latextErr) {
            return Text(
              latexString,
              style: GoogleFonts.inter(fontSize: 22),
            );
          }
        },
      );
    } catch (e) {
      return Text(
        latexString,
        style: GoogleFonts.inter(fontSize: 16),
      );
    }
  }
}
