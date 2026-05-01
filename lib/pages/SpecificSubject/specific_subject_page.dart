// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_ekran/exceptions/app_exceptions.dart';
import 'package:odlikas_ekran/models/grades.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odlikas_ekran/pages/SpecificSubject/widgets/evaluation_table.dart';
import 'package:odlikas_ekran/pages/SpecificSubject/widgets/notes_table.dart';
import 'package:odlikas_ekran/pages/SpecificSubject/widgets/zakljuceno_row.dart';
import 'package:odlikas_ekran/viewmodels/viewmodel.dart';
import 'package:provider/provider.dart';

class SubjectDetailsPage extends StatefulWidget {
  final String subjectId;

  const SubjectDetailsPage({super.key, required this.subjectId});

  @override
  _SubjectDetailsPageState createState() => _SubjectDetailsPageState();
}

class _SubjectDetailsPageState extends State<SubjectDetailsPage> {
  Future<void> _loadData() async {
    final box = await Hive.openBox('user_credentials');
    final token = box.get('token') as String?;
    if (token == null || !mounted) return;
    final viewModel = context.read<HomePageViewModel>();
    try {
      await Future.wait([
        viewModel.fetchGrades(token),
        viewModel.fetchSpecificSubjectGrades(token, widget.subjectId),
      ]);
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await _handleExpiredSession();
      }
    }
  }

  Future<void> _handleExpiredSession() async {
    final box = await Hive.openBox('user_credentials');
    await box.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Session expired. Scan a new QR code from the Odlikas app.')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/setup', (_) => false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();

    final selectedSubject = viewModel.grades!.subjects.firstWhere(
      (subject) => subject.subjectId == widget.subjectId,
      orElse: () => Subject(
        subjectName: "N/A",
        grade: "",
        professor: "N/A",
        subjectId: widget.subjectId,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: viewModel.isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/bird_animation.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            )
          : viewModel.subjectGrades != null &&
                  viewModel.evaluationElements != null
              ? CustomScrollView(
                  slivers: [
                    // Scrollable AppBar
                    SliverToBoxAdapter(
                      child: Container(
                        color: const Color.fromRGBO(255, 255, 255, 1),
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                          vertical: 16.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              iconSize: 50,
                              color: const Color.fromRGBO(236, 145, 32, 1),
                              onPressed: () {
                                Navigator.of(context).pop(); // Navigate back
                              },
                            ),

                            // Subject and Professor
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  selectedSubject.subjectName,
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.03,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Nastavnik/ca: ${selectedSubject.professor}",
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.015,
                                    fontWeight: FontWeight.normal,
                                    color:
                                        const Color.fromRGBO(113, 113, 113, 1),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width * 0.009,
                                ),
                              ],
                            ),

                            // Placeholder to balance alignment
                            const SizedBox(
                              width: 48,
                              height: 150,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Evaluation Elements Table + Zakljuceno
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 70.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            EvaluationTable(viewModel: viewModel),
                            // The separate Zakljuceno "row" (really a Row with 2 containers)
                            ZakljucenoRow(viewModel: viewModel),
                          ],
                        ),
                      ),
                    ),

                    // Notes Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 70.0, vertical: 70),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            // NOTES TABLE WIDGET
                            NotesTable(viewModel: viewModel),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text("No grades available for this subject."),
                ),
    );
  }
}
