import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_ekran/database/task_service.dart';
import 'package:odlikas_ekran/models/task.dart';
import 'package:odlikas_ekran/models/tests.dart';
import 'package:odlikas_ekran/viewmodels/recommendation_viewmodel.dart';
import 'package:odlikas_ekran/viewmodels/test_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final RecommendationViewModel _recommendationViewModel =
      RecommendationViewModel();
  late final TaskService _taskService;
  String? _userEmail;

  Future<void> _loadUserEmail() async {
    final box = await Hive.openBox('user_credentials');
    setState(() {
      _userEmail = box.get('email') as String?;
      if (_userEmail != null) {
        _taskService = TaskService(_userEmail!);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final testViewModel = Provider.of<TestViewmodel>(context, listen: false);
      final box = Hive.box('user_credentials');
      final email = box.get('email');
      final password = box.get('password');

      if (email != null && password != null) {
        testViewModel.fetchTests(email, password);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get access to the test view model
    final testViewModel = Provider.of<TestViewmodel>(context);
    return testViewModel.isLoading
        ? Scaffold(
            body: Center(
              child: Lottie.asset(
                'assets/animations/bird_animation.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Colors.white,
            body: CustomScrollView(
              slivers: [
                // App bar with title and buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            iconSize: 50,
                            color: const Color.fromRGBO(236, 145, 32, 1),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        // Title
                        Text(
                          "Popis obveza",
                          style: GoogleFonts.inter(
                              fontSize: 36, fontWeight: FontWeight.w800),
                        ),
                        // Add button
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.add),
                            iconSize: 50,
                            color: const Color.fromRGBO(236, 145, 32, 1),
                            onPressed: () {
                              _showAddTaskDialog(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Weekly tasks section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade400, width: 1),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8AD42),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(9),
                                topRight: Radius.circular(9),
                              ),
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "U SLJEDEĆIH TJEDAN DANA",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          _buildWeeklyTasksTable(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Other tasks section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade400, width: 1),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0093D1),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(9),
                                topRight: Radius.circular(9),
                              ),
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "OSTALO",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          _buildOtherTasksTable(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Recommendations section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Preporuke:",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRecommendationsTable(testViewModel.tests),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildWeeklyTasksTable() {
    final now = DateTime.now();
    final oneWeekLater = now.add(const Duration(days: 7));

    return StreamBuilder<List<Task>>(
      stream: _taskService.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Lottie.asset(
              'assets/animations/bird_animation.json',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Error: ${snapshot.error}"),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Nema zadataka za sljedeći tjedan"),
          );
        }

        final weeklyTasks = snapshot.data!.where((task) {
          return task.dueDate != null &&
              task.dueDate!.isAfter(now) &&
              task.dueDate!.isBefore(oneWeekLater);
        }).toList();

        if (weeklyTasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Nema zadataka za sljedeći tjedan"),
          );
        }

        return Table(
          // Give a full outer border plus inside horizontal/vertical lines
          border: TableBorder.all(
              color: Color.fromRGBO(113, 113, 113, 1), width: 1),

          // Three columns: checkbox, date, and the title/description
          columnWidths: const {
            0: FixedColumnWidth(70), // checkbox column
            1: FixedColumnWidth(80), // date/time column
            2: FlexColumnWidth(), // fill the rest with description
          },
          children: List.generate(weeklyTasks.length, (index) {
            final task = weeklyTasks[index];
            final daysDiff = task.dueDate!.difference(now).inDays;

            return TableRow(
              children: [
                // Column 0: checkbox
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: Checkbox(
                    value: task.isCompleted,
                    activeColor: const Color(0xFFF8AD42),
                    onChanged: (bool? value) {
                      final updatedTask = Task(
                        id: task.id,
                        title: task.title,
                        dueDate: task.dueDate,
                        isCompleted: value ?? false,
                      );
                      _taskService.updateTask(updatedTask);
                    },
                  ),
                ),

                // Column 1: date + “Za x dana”
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${task.dueDate!.day}.${task.dueDate!.month}",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Za ${daysDiff + 1} dan${daysDiff > 0 ? 'a' : ''}",
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Column 2: task description
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    task.title,
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildOtherTasksTable() {
    final now = DateTime.now();
    final oneWeekLater = now.add(const Duration(days: 7));

    return StreamBuilder<List<Task>>(
      stream: _taskService.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Lottie.asset(
              'assets/animations/bird_animation.json',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Text("Error: ${snapshot.error}"),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text("Nema ostalih zadataka"),
          );
        }

        final otherTasks = snapshot.data!.where((task) {
          return task.dueDate == null || task.dueDate!.isAfter(oneWeekLater);
        }).toList();

        if (otherTasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text("Nema ostalih zadataka"),
          );
        }

        return Table(
          border: TableBorder.all(
            color: Color.fromRGBO(113, 113, 113, 1),
            width: 1,
          ),
          columnWidths: const {
            0: FixedColumnWidth(70), // checkbox column
            1: FixedColumnWidth(80), // date/time column
            2: FlexColumnWidth(), // fills the rest with description
          },
          children: List.generate(otherTasks.length, (index) {
            final task = otherTasks[index];
            final daysDiff = task.dueDate == null
                ? null
                : task.dueDate!.difference(now).inDays + 1;

            return TableRow(
              children: [
                // Column 0: checkbox
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Checkbox(
                    value: task.isCompleted,
                    activeColor: const Color(0xFFF8AD42),
                    onChanged: (bool? value) {
                      final updatedTask = Task(
                        id: task.id,
                        title: task.title,
                        dueDate: task.dueDate,
                        isCompleted: value ?? false,
                      );
                      _taskService.updateTask(updatedTask);
                    },
                  ),
                ),

                // Column 1: date + "Za X dana"
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.dueDate != null)
                        Text(
                          "${task.dueDate!.day}.${task.dueDate!.month}",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        (daysDiff != null) ? "Za $daysDiff dana" : "N/A",
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Column 2: task description
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    task.title,
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildRecommendationsTable(Tests? tests) {
    // Check if tests are loading or not available
    if (tests == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final testViewModel = Provider.of<TestViewmodel>(context);

    // Handle loading state
    if (testViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle empty state
    if (tests.testsByMonth.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: const Text("Nema preporuka za učenje"),
      );
    }

    final recommendations = _recommendationViewModel.getRecommendations(tests);

    if (recommendations.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: const Text("Nema preporuka za učenje"),
      );
    }

    final testDate =
        DateTime.now().add(Duration(days: recommendations[0]['daysLeft']));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8AD42),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            width: double.infinity,
            child: Table(
              border: TableBorder(
                verticalInside: BorderSide(color: Colors.white, width: 1),
                bottom: BorderSide(color: Colors.white, width: 1),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(5),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: [
                    // Task ID column
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "${testDate.day}.${testDate.month}",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Recommendation text column
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        recommendations[0]['title'],
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Add button column
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final testDate = DateTime.now().add(
                              Duration(days: recommendations[0]['daysLeft']));
                          final newTask = Task(
                            id: const Uuid().v4(),
                            title:
                                "${recommendations[0]['title'].split('.')[0].replaceAll('Uči ', '')}",
                            dueDate: testDate,
                            isCompleted: false,
                          );
                          _taskService.addTask(newTask);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Zadatak dodan u popis obveza"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Rest of recommendations in white rows
          if (recommendations.length > 1)
            Table(
              border: TableBorder(
                verticalInside:
                    BorderSide(color: Colors.grey.shade400, width: 1),
                horizontalInside:
                    BorderSide(color: Colors.grey.shade400, width: 1),
                // No top border as it would overlap with the header
                bottom: BorderSide(color: Colors.grey.shade400, width: 0),
                left: BorderSide(color: Colors.grey.shade400, width: 0),
                right: BorderSide(color: Colors.grey.shade400, width: 0),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(5),
                2: FlexColumnWidth(1),
              },
              children: List.generate(recommendations.length - 1, (index) {
                final recommendation = recommendations[index + 1];
                final testDate = DateTime.now()
                    .add(Duration(days: recommendation['daysLeft']));
                return TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: index == recommendations.length - 2
                          ? BorderSide(color: Colors.grey.shade400, width: 0)
                          : BorderSide.none,
                    ),
                  ),
                  children: [
                    // Task ID column
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "${testDate.day}.${testDate.month}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Recommendation text column
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        recommendation['title'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Add button column
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: const Color(0xFFF8AD42),
                        ),
                        onPressed: () {
                          final testDate = DateTime.now()
                              .add(Duration(days: recommendation['daysLeft']));
                          final newTask = Task(
                            id: const Uuid().v4(),
                            title:
                                "Učiti za ispit: ${recommendation['title'].split('.')[0].replaceAll('Uči ', '')}",
                            dueDate: testDate,
                            isCompleted: false,
                          );
                          _taskService.addTask(newTask);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Zadatak dodan u popis obveza"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dodaj novi zadatak"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Naziv zadatka",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text("Datum: "),
                  TextButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        selectedDate = pickedDate;
                      }
                    },
                    child: Text(
                      selectedDate != null
                          ? DateFormat('dd.MM.yyyy').format(selectedDate!)
                          : "Odaberi datum (opcionalno)",
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Odustani"),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final task = Task(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    dueDate: selectedDate,
                    isCompleted: false,
                  );
                  _taskService.addTask(task);
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Dodaj"),
            ),
          ],
        );
      },
    );
  }
}
