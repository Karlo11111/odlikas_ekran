import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_page_viewmodel.dart';

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
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // da je app bar scrollable
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.02,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 50,
                          color: const Color.fromRGBO(236, 145, 32, 1),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        Text(
                          viewModel.studentProfile?.studentSchool ??
                              "Loading...",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.025,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            width: 48), // Placeholder da bude u sredini
                      ],
                    ),
                  ),
                ),

                // dobrodosao tekst
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.02),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Dobrodošao ${viewModel.studentProfile?.studentName ?? ''}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(113, 113, 113, 100),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.studentProfile?.studentGrade ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(236, 145, 32, 1),
                          ),
                        ),
                        const SizedBox(height: 16),
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

  const GradeTile({
    Key? key,
    required this.subjectName,
    required this.professor,
    required this.grade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    professor,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color.fromRGBO(113, 113, 113, 1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          //gradebox
          Container(
            width: 70, // stalna duljina za ocjenu
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
