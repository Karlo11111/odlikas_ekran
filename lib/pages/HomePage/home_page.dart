import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/HomePage/widgets/grade_wheel.dart';
import 'package:odlikas_ekran/responsive.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_page_viewmodel.dart';
import 'package:lottie/lottie.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Responsive res = Responsive();

  @override
  void initState() {
    super.initState();
    // fetchaj podatke nakon sto se widget (home page) postavi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<HomePageViewModel>();
      viewModel.fetchGrades("karlo.ciciliani@skole.hr", "2kw3xpAS");
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();

    return Scaffold(
      body: viewModel.isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/bird_animation.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            )
          : viewModel.grades != null
              ? Center(
                  child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top-left container
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.02,
                      top: MediaQuery.of(context).size.height * 0.02,
                      child: _buildContainer(
                        label: "POPIS OBVEZA",
                        width: MediaQuery.of(context).size.width * 0.47,
                        height: MediaQuery.of(context).size.height * 0.463,
                      ),
                    ),

                    // Bottom-left container
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.02,
                      bottom: MediaQuery.of(context).size.height * 0.02,
                      child: _buildContainer(
                        label: "KALENDAR",
                        width: MediaQuery.of(context).size.width * 0.47,
                        height: MediaQuery.of(context).size.height * 0.463,
                      ),
                    ),

                    // Top-right container
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.02,
                      top: MediaQuery.of(context).size.height * 0.02,
                      child: _buildContainer(
                        label: "POMODORO MJERAČ VREMENA",
                        width: MediaQuery.of(context).size.width * 0.47,
                        height: MediaQuery.of(context).size.height * 0.463,
                      ),
                    ),

                    // Bottom-right container
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.02,
                      bottom: MediaQuery.of(context).size.height * 0.02,
                      child: _buildContainer(
                        label: "STREAKSS",
                        width: MediaQuery.of(context).size.width * 0.47,
                        height: MediaQuery.of(context).size.height * 0.463,
                      ),
                    ),

                    // GradeWheel u sredini

                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/grades'),
                          child: Container(
                            width: MediaQuery.of(context).size.width *
                                0.25, // Adjust wheel size
                            height: MediaQuery.of(context).size.width * 0.25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .scaffoldBackgroundColor, // za skrivanje edge-va
                            ),
                            child: ClipOval(
                              child: GradeWheel(
                                  subjects: viewModel.grades?.subjects ?? []),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ))
              : const Center(
                  child: Text("No data available"),
                ),
    );
  }

  Widget _buildContainer({
    required String label,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18, // font u containeru
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
