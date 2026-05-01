// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_ekran/database/api/deepseek_service.dart';

import 'package:odlikas_ekran/pages/SimilarTasks/similar_tasks_page.dart';

class SolutionStepsPage extends StatefulWidget {
  final List<Map<String, String>> steps;
  final String originalTask;

  const SolutionStepsPage({
    Key? key,
    required this.steps,
    required this.originalTask,
  }) : super(key: key);

  @override
  State<SolutionStepsPage> createState() => _SolutionStepsPageState();
}

class _SolutionStepsPageState extends State<SolutionStepsPage> {
  int _currentStep = -1;
  late final List<ExpansionTileController> _tileControllers;

  @override
  void initState() {
    super.initState();
    _tileControllers = List.generate(
      widget.steps.length,
      (_) => ExpansionTileController(),
    );
  }

  bool get _isStarted => _currentStep >= 0;
  bool get _isLastStep => _currentStep == widget.steps.length - 1;

  void _advance() {
    final next = _currentStep + 1;
    if (_currentStep >= 0) {
      _tileControllers[_currentStep].collapse();
    }
    _tileControllers[next].expand();
    setState(() => _currentStep = next);
  }

  @override
  Widget build(BuildContext context) {
    Widget buildStepCard(Map<String, String> step, int index) {
      final result = step['result'] ?? '';
      final explanation = _betterDiacriticsFix(
          step['explanation'] ?? 'Nema dostupnog objašnjenja');

      bool isNumericWithKuna =
          RegExp(r'^\s*\d+(\.\d+)?\s*(kn|kuna|Kn|Kuna)\s*').hasMatch(result);

      // Strip delimiters Math.tex doesn't understand
      final cleanResult = result
          .replaceAll(r'$$', '')
          .replaceAll(r'$', '')
          .replaceAll(r'\[', '')
          .replaceAll(r'\]', '')
          .replaceAll(r'\(', '')
          .replaceAll(r'\)', '')
          .trim();

      Widget resultWidget;

      if (isNumericWithKuna) {
        resultWidget = Text(
          _betterDiacriticsFix(result),
          style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w600),
        );
      } else {
        resultWidget = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            _fixMultiplicationSymbols(cleanResult),
            textStyle: GoogleFonts.inter(fontSize: 30),
            onErrorFallback: (err) {
              debugPrint('Math.tex step error for "$cleanResult": $err');
              return Text(
                cleanResult,
                style: GoogleFonts.inter(fontSize: 30),
              );
            },
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
            controller: _tileControllers[index],
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

    final lastResult = widget.steps.isNotEmpty ? widget.steps.last['result'] ?? '' : '';

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
                      itemCount: widget.steps.length,
                      itemBuilder: (context, index) =>
                          buildStepCard(widget.steps[index], index),
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
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: _buildFinalAnswer(
                                  _betterDiacriticsFix(lastResult)),
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
                            onPressed: _isLastStep && _isStarted ? null : _advance,
                            child: Text(
                              _isStarted ? "Sljedeći korak" : "Prikaži korake",
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

  Widget _buildFinalAnswer(String result) {
    bool isPrimarilyLaTeX(String text) {
      final mathSymbols = RegExp(r'[=<>≤≥≈±×÷⋅∙√∛∜∫∬∮∯∰∱∲∳∑∏∐⊕⊗⊙⊛⊝⊞⊟⊠⊡∕]');
      final latexCommands = RegExp(r'\\[a-zA-Z]+|\\[^a-zA-Z]');
      final fractions = RegExp(r'\\frac');
      final displayStyle = RegExp(r'\\displaystyle');
      return latexCommands.hasMatch(text) ||
          fractions.hasMatch(text) ||
          displayStyle.hasMatch(text) ||
          mathSymbols.hasMatch(text);
    }

    bool isLaTeX = isPrimarilyLaTeX(result);
    bool hasMultipleLines = result.contains('\n') || result.contains('\\\\');
    bool isSimpleEquation = result.contains('=') && !result.contains('\n');

    if (isSimpleEquation) {
      String cleanResult =
          result.replaceAll(r'$$', '').replaceAll(r'$', '').trim();
      if (!cleanResult.contains(r'\displaystyle')) {
        cleanResult = r'\displaystyle ' + cleanResult;
      }
      return Math.tex(
        cleanResult,
        textStyle: GoogleFonts.inter(fontSize: 58),
        onErrorFallback: (err) =>
            Text(result, style: GoogleFonts.inter(fontSize: 58)),
      );
    }

    if (isLaTeX) {
      String cleanResult =
          result.replaceAll(r'$$', '').replaceAll(r'$', '').trim();
      if (hasMultipleLines) {
        if (!cleanResult.contains(r'\begin{align}') &&
            !cleanResult.contains(r'\begin{aligned}')) {
          cleanResult = cleanResult
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .join(r' \\ ');
          cleanResult = r'\begin{aligned} ' + cleanResult + r' \end{aligned}';
        }
      } else if (!cleanResult.contains(r'\displaystyle')) {
        cleanResult = r'\displaystyle ' + cleanResult;
      }
      return Math.tex(
        cleanResult,
        textStyle: GoogleFonts.inter(fontSize: 58),
        onErrorFallback: (err) =>
            Text(result, style: GoogleFonts.inter(fontSize: 58)),
      );
    }

    return Text(result,
        style: GoogleFonts.inter(fontSize: 44), textAlign: TextAlign.center);
  }

  Future<void> _loadSimilarTasks(BuildContext context) async {
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
      final deepseekService = DeepseekService();
      final similarTasks =
          await deepseekService.generateSimilarTasks(widget.originalTask);

      Navigator.of(context).pop();

      if (similarTasks != null && similarTasks.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimilarTasksPage(
              tasks: similarTasks,
              originalTask: widget.originalTask,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Nije moguće generirati slične zadatke. Pokušajte ponovno.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
    text = text.replaceAll(String.fromCharCode(0x0087), '');
    text = text.replaceAll(String.fromCharCode(0x008D), '');

    final Map<String, String> replacements = {
      'Ä': 'ć',
      'Å¡': 'š',
      'Å¾': 'ž',
      'Ä‡': 'đ',
    };
    replacements.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

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
    wordReplacements.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    return text;
  }
}
