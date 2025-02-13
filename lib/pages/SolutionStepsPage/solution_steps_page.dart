import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class SolutionStepsPage extends StatelessWidget {
  final List<Map<String, String>> steps;

  const SolutionStepsPage({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    Widget _buildStepCard(Map<String, String> step, int index) {
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
            title: Math.tex(
              step['result'] ?? '',
              textStyle: GoogleFonts.inter(fontSize: 30),
            ),
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
                  step['step'] ?? 'Nema dostupnog objašnjenja',
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

    // ako je null zadnje rijesenje
    final lastResult = steps.isNotEmpty ? steps.last['result'] ?? '' : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header with Back Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Row(
                children: [
                  // RETURN BUTTON
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.035,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 50,
                    color: const Color.fromRGBO(236, 145, 32, 1),
                    onPressed: () {
                      Navigator.of(context).pop(); // Navigate back
                    },
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.32,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Koraci rješenja",
                        style: GoogleFonts.inter(
                            fontSize: 36, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Steps
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: steps.length,
                      itemBuilder: (context, index) =>
                          _buildStepCard(steps[index], index),
                    ),
                  ),
                ),

                Container(
                  width: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC9120),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  height: MediaQuery.of(context).size.height * 0.85,
                ),

                // Right Column - Final Solution
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Rješenje',
                              style: GoogleFonts.inter(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromRGBO(236, 145, 32, 1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 230),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Math.tex(
                              lastResult,
                              textStyle: GoogleFonts.inter(
                                fontSize: 58,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 130),
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
                          const SizedBox(height: 5),
                          TextButton(
                            onPressed: () {},
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
