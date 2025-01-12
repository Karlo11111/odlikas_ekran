import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/SpecificSubject/specific_subject_page.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_page_viewmodel.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<HomePageViewModel>();
      viewModel.fetchStudentProfile("karlo.ciciliani@skole.hr", "2kw3xpAS");
      viewModel.fetchGrades("karlo.ciciliani@skole.hr", "2kw3xpAS");
    });
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
                // da je app bar scrollable
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
                        // Back button
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 50,
                          color: const Color.fromRGBO(236, 145, 32, 1),
                          onPressed: () {
                            Navigator.of(context).pop(); // Navigate back
                          },
                        ),

                        // Program and Razrednik/ca stacked vertically
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),

                            // Wrap the *first* text in a width-constrained Container
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              // adjust 0.4 if you want more or less space
                              child: Text(
                                viewModel.studentProfile?.studentProgram ??
                                    "Loading...",
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
                              height: MediaQuery.of(context).size.width * 0.009,
                            ),

                            // The grade dropdown container you do NOT want to change
                            Container(
                              padding: EdgeInsets.only(
                                left: MediaQuery.of(context).size.width * 0.01,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color.fromRGBO(234, 234, 234, 1),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    (viewModel.studentProfile?.studentGrade ??
                                                '')
                                            .isNotEmpty
                                        ? '${viewModel.studentProfile?.studentGrade[0]}.${viewModel.studentProfile?.studentGrade.substring(1)}'
                                        : '',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.035,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    iconSize: 50,
                                    color:
                                        const Color.fromRGBO(236, 145, 32, 1),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Placeholder to balance alignment
                        const SizedBox(
                          width: 48,
                          height: 200,
                        ),
                      ],
                    ),
                  ),
                ),

                // predmeti sekcija
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.02),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // dva stupca
                      crossAxisSpacing: 35.0, // razmak izmedu dva stupca
                      mainAxisSpacing: 23.0, // razmak izmedu dva reda
                      childAspectRatio: MediaQuery.of(context).size.height *
                          0.008, // velicina jednog tile-a
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
            // Text Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subject Name
                    Text(
                      subjectName,
                      style: const TextStyle(
                        fontFamily: "Arial",
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                      maxLines: 1, // Limit to 1 line
                    ),

                    // Professor Name
                    Text(
                      professor,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color.fromRGBO(113, 113, 113, 1),
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                      maxLines: 1, // Limit to 1 line
                    ),
                  ],
                ),
              ),
            ),

            // Grade Box
            Container(
              width: 85, // Fixed width for the grade box
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
