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
            padding: const EdgeInsets.only(top: 25, left: 16, right: 56),
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
    // Function to check if content is primarily LaTeX math
    bool isPrimarilyLaTeX(String text) {
      // Math symbols and operations that indicate LaTeX content
      final mathSymbols = RegExp(r'[=<>≤≥≈±×÷⋅∙√∛∜∫∬∮∯∰∱∲∳∑∏∐⊕⊗⊙⊛⊝⊞⊟⊠⊡∕]');
      final latexCommands = RegExp(r'\\[a-zA-Z]+|\\[^a-zA-Z]');
      final fractions = RegExp(r'\\frac');
      final displayStyle = RegExp(r'\\displaystyle');

      // Check for these indicators
      bool hasLatexCommands = latexCommands.hasMatch(text);
      bool hasMathSymbols = mathSymbols.hasMatch(text);
      bool hasFractions = fractions.hasMatch(text);
      bool hasDisplayStyle = displayStyle.hasMatch(text);

      // If it has any specific LaTeX indicators, consider it primarily LaTeX
      return hasLatexCommands ||
          hasFractions ||
          hasDisplayStyle ||
          hasMathSymbols;
    }

    // Check if the result contains any LaTeX indicators
    bool isLaTeX = isPrimarilyLaTeX(result);

    // Check if content contains multiple lines (which might need special handling)
    bool hasMultipleLines = result.contains('\n') || result.contains('\\\\');

    // Special cases for equations
    bool isSimpleEquation = result.contains('=') && !result.contains('\n');

    if (isSimpleEquation) {
      // For simple equations, make sure we're using LaTeX rendering
      // Sometimes these don't get the proper LaTeX formatting from the API

      // Remove any existing LaTeX delimiters if present
      String cleanResult =
          result.replaceAll(r'$$', '').replaceAll(r'$', '').trim();

      // Wrap with displaystyle to ensure it's rendered properly on one line
      if (!cleanResult.contains(r'\displaystyle')) {
        cleanResult = r'\displaystyle ' + cleanResult;
      }

      return Math.tex(
        cleanResult,
        textStyle: GoogleFonts.inter(fontSize: 58),
        onErrorFallback: (err) {
          // print("LaTeX rendering error: $err for content: $cleanResult");
          return Text(
            result,
            style: GoogleFonts.inter(fontSize: 58),
          );
        },
      );
    }

    if (isLaTeX) {
      // Clean up the content and ensure proper LaTeX formatting
      String cleanResult = result.trim();

      // Remove existing LaTeX delimiters if present, we'll add our own
      cleanResult =
          cleanResult.replaceAll(r'$$', '').replaceAll(r'$', '').trim();

      if (hasMultipleLines) {
        // For multi-line equations, use align environment
        if (!cleanResult.contains(r'\begin{align}') &&
            !cleanResult.contains(r'\begin{aligned}')) {
          // Replace newlines with proper LaTeX line breaks
          cleanResult = cleanResult
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .join(r' \\ ');

          // Wrap in align environment
          cleanResult = r'\begin{aligned} ' + cleanResult + r' \end{aligned}';
        }
      } else if (!cleanResult.contains(r'\displaystyle')) {
        // Add displaystyle for better rendering of single-line equations
        cleanResult = r'\displaystyle ' + cleanResult;
      }

      return Math.tex(
        cleanResult,
        textStyle: GoogleFonts.inter(fontSize: 58),
        onErrorFallback: (err) {
          // print("LaTeX rendering error: $err for content: $cleanResult");
          return Text(
            result,
            style: GoogleFonts.inter(fontSize: 58),
          );
        },
      );
    } else {
      // For plain text
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
