// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_ekran/database/api/deepseek_service.dart';

import 'package:odlikas_ekran/pages/SimilarTasks/similar_tasks_page.dart';

class SolutionStepsPage extends StatelessWidget {
  final List<Map<String, String>> steps;
  final String originalTask;

  const SolutionStepsPage({
    Key? key,
    required this.steps,
    required this.originalTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Improve the step card builder to handle overflow
    Widget buildStepCard(Map<String, String> step, int index) {
      final result = step['result'] ?? '';
      final explanation = _betterDiacriticsFix(
          step['explanation'] ?? 'Nema dostupnog objašnjenja');

      // Check specifically for currency-based final answers (most common issue)
      bool isNumericWithKuna =
          RegExp(r'^\s*\d+(\.\d+)?\s*(kn|kuna|Kn|Kuna)\s*').hasMatch(result);

      Widget resultWidget;

      if (isNumericWithKuna) {
        // For simple currency results, use regular Text
        resultWidget = Text(
          _betterDiacriticsFix(result),
          style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w600),
        );
      } else {
        // For everything else, use Math.tex
        resultWidget = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            _fixMultiplicationSymbols(result),
            textStyle: GoogleFonts.inter(fontSize: 30),
            onErrorFallback: (err) => Text(
              result, // On error, just show the raw result
              style: GoogleFonts.inter(fontSize: 30),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          color: Colors.white,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: resultWidget,
            trailing: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.orange[800],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                width: double.infinity,
                child: Text(
                  explanation,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lastResult = steps.isNotEmpty ? steps.last['result'] ?? '' : '';

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
                  iconSize: 50,
                  color: const Color.fromRGBO(236, 145, 32, 1),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Koraci rješenja",
                      style: GoogleFonts.inter(
                          fontSize: 36, fontWeight: FontWeight.w800),
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
                // Scrollable Steps List
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                      itemCount: steps.length,
                      itemBuilder: (context, index) =>
                          buildStepCard(steps[index], index),
                    ),
                  ),
                ),
                // Orange Line
                Container(
                  width: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC9120),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  height: double.infinity,
                ),
                // Solution Panel
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rješenje',
                            style: GoogleFonts.inter(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromRGBO(236, 145, 32, 1),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Spacer(),
                        // Fix for the final solution display with scroll
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.45,
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.55,
                                ),
                                child: _buildFinalAnswer(
                                    _betterDiacriticsFix(lastResult)),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(236, 145, 32, 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              "Prikaži korake",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _loadSimilarTasks(context),
                          child: Text(
                            "Zadatci slični ovome",
                            style: GoogleFonts.inter(
                                fontSize: 20, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // In your SolutionStepsPage class, modify how you display the final answer
  Widget _buildFinalAnswer(String result) {
    // Check if this is a math expression (has LaTeX commands or math symbols)
    bool isLaTeX =
        result.contains(r'\') || result.contains(r'=') || result.contains(r'^');

    // Check if it has plain text (letters other than common math variables)
    bool hasText = result.contains(RegExp(r'[a-zA-ZčćšđžČĆŠĐŽ]{3,}'));

    if (isLaTeX && hasText) {
      // It has both math and text - try to separate them

      // First, extract any LaTeX expressions within the string
      final mathExpressions = <String>[];
      final textParts = <String>[];

      // Simple split by common text indicators
      List<String> parts = result.split('-');
      if (parts.length <= 1) {
        parts = result.split(':');
      }

      if (parts.length > 1) {
        // We have some natural separation in the text
        for (final part in parts) {
          if (part.contains(r'\') ||
              (part.contains(RegExp(r'\d')) &&
                  !part.contains(RegExp(r'[a-zA-ZčćšđžČĆŠĐŽ]{3,}')))) {
            // This part is likely math
            mathExpressions.add(part.trim());
          } else {
            // This part is likely text
            textParts.add(part.trim());
          }
        }
      } else {
        // No obvious separator - just display with Math.tex and let user see
        // the fallback if it fails
        return Math.tex(
          result,
          textStyle: GoogleFonts.inter(fontSize: 58),
          onErrorFallback: (err) => Text(
            result,
            style: GoogleFonts.inter(fontSize: 58),
          ),
        );
      }

      // Build the UI with separated parts
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Math parts
          if (mathExpressions.isNotEmpty)
            ...mathExpressions.map((expr) => Math.tex(
                  expr,
                  textStyle: GoogleFonts.inter(fontSize: 58),
                  onErrorFallback: (err) => Text(
                    expr,
                    style: GoogleFonts.inter(fontSize: 58),
                  ),
                )),

          const SizedBox(height: 10),

          // Text parts
          if (textParts.isNotEmpty)
            ...textParts.map((text) => Text(
                  text,
                  style: GoogleFonts.inter(fontSize: 24, color: Colors.black87),
                  textAlign: TextAlign.center,
                )),
        ],
      );
    }

    // If it's just a formula or just text, handle appropriately
    if (isLaTeX) {
      return Math.tex(
        result,
        textStyle: GoogleFonts.inter(fontSize: 58),
        onErrorFallback: (err) => Text(
          result,
          style: GoogleFonts.inter(fontSize: 58),
        ),
      );
    } else {
      return Text(
        result,
        style: GoogleFonts.inter(fontSize: 44),
        textAlign: TextAlign.center,
      );
    }
  }

  // Nova metoda za učitavanje sličnih zadataka
  Future<void> _loadSimilarTasks(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Scaffold(
            body: Center(
          child: Lottie.asset(
            'assets/animations/bird_animation.json',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ));
      },
    );

    try {
      // Initialize OpenAI service
      final deepseekService = DeepseekService();

      // Get similar tasks
      final similarTasks =
          await deepseekService.generateSimilarTasks(originalTask);

      // Close loading dialog
      Navigator.of(context).pop();

      if (similarTasks != null && similarTasks.isNotEmpty) {
        // Navigate to similar tasks page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimilarTasksPage(
              tasks: similarTasks,
              originalTask: originalTask,
            ),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Nije moguće generirati slične zadatke. Pokušajte ponovno.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Original methods - kept exactly as they were, but added improvement for explanation handling
  String _fixMultiplicationSymbols(String latex) {
    return latex.replaceAllMapped(RegExp(r'( cdot )'), (match) => r'\times');
  }

  String _cleanRawLatex(String latex) {
    return latex
        .replaceAll(r'\', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll("boxed", "");
  }

  String _betterDiacriticsFix(String text) {
    // Remove the strange character that appears after "Pronač"
    text = text.replaceAll(String.fromCharCode(0x0087), '');
    text = text.replaceAll(String.fromCharCode(0x008D), '');

    // Direct character replacements for Croatian letters
    final Map<String, String> replacements = {
      'Ä': 'ć',
      'Å¡': 'š',
      'Å¾': 'ž',
      'Ä‡': 'č',
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
}
