// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:odlikas_ekran/exceptions/app_exceptions.dart';
import 'package:odlikas_ekran/pages/SpecificSubject/specific_subject_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/viewmodel.dart';
import 'package:lottie/lottie.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final box = await Hive.openBox('user_credentials');
    final token = box.get('token') as String?;
    if (token == null || !mounted) return;
    final viewModel = context.read<HomePageViewModel>();
    try {
      await Future.wait([
        viewModel.fetchGrades(token),
        viewModel.fetchStudentProfile(token),
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
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();

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
          : CustomScrollView(
              slivers: [
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
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Text(
                                viewModel.studentProfile?.studentProgram ?? "",
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.03,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Razrednik/ca: ${viewModel.studentProfile?.classMaster ?? ''}",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.015,
                                fontWeight: FontWeight.normal,
                                color: const Color.fromRGBO(113, 113, 113, 1),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.width * 0.009,
                            ),
                            Container(
                              padding: EdgeInsets.only(
                                left:
                                    MediaQuery.of(context).size.width * 0.015,
                                right:
                                    MediaQuery.of(context).size.width * 0.015,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      const Color.fromRGBO(234, 234, 234, 1),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                (viewModel.studentProfile?.studentGrade ?? '')
                                        .isNotEmpty
                                    ? '${viewModel.studentProfile?.studentGrade[0]}.${viewModel.studentProfile?.studentGrade.substring(1)}'
                                    : '',
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 48, height: 200),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.02),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 35.0,
                      mainAxisSpacing: 23.0,
                      childAspectRatio:
                          MediaQuery.of(context).size.height * 0.008,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final subject = viewModel.grades!.subjects[index];
                        return GradeTile(
                          subjectName: subject.subjectName,
                          professor: subject.professor,
                          grade: subject.grade,
                          subjectId: subject.subjectId,
                        );
                      },
                      childCount: viewModel.grades?.subjects.length ?? 0,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
    );
  }
}

class GradeTile extends StatelessWidget {
  final String subjectName;
  final String professor;
  final String grade;
  final String subjectId;

  const GradeTile({
    Key? key,
    required this.subjectId,
    required this.subjectName,
    required this.professor,
    required this.grade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SubjectDetailsPage(subjectId: subjectId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(234, 234, 234, 1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subjectName,
                      style: const TextStyle(
                        fontFamily: "Arial",
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      professor,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color.fromRGBO(113, 113, 113, 1),
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 85,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(23, 148, 210, 1),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                grade,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
