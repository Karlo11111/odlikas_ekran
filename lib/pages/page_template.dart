import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SolutionStepsPages extends StatelessWidget {
  const SolutionStepsPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // MATEMATICKE BILJESKE TIMER TEXT AND RETURN BUTTON
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
                    width: MediaQuery.of(context).size.width * 0.236,
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

          // Koraci rjesenja
        ],
      ),
    );
  }
}
