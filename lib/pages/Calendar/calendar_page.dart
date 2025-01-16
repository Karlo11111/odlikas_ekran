// ignore_for_file: unused_field, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_ekran/pages/Calendar/widgets/day_cell.dart';
import 'package:odlikas_ekran/viewmodels/test_viewmodel.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Future<void> _initialDataLoad;

  DateTime _focusedDate = DateTime.now();
  late DateTime _firstDayOfMonth;
  late DateTime _lastDayOfMonth;
  List<Map<String, dynamic>> _holidays = [];

  final List<String> _weekDays = [
    'PON',
    'UTO',
    'SRI',
    'ČET',
    'PET',
    'SUB',
    'NED'
  ];

  final List<String> _monthNames = [
    'SIJEČANJ',
    'VELJAČA',
    'OŽUJAK',
    'TRAVANJ',
    'SVIBANJ',
    'LIPANJ',
    'SRPANJ',
    'KOLOVOZ',
    'RUJAN',
    'LISTOPAD',
    'STUDENI',
    'PROSINAC'
  ];

  @override
  void initState() {
    super.initState();
    _updateMonth(_focusedDate);

    // Fetch all required data during initialization
    _initialDataLoad = _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchHolidays();

    // Fetch tests through the ViewModel
    final viewModel = context.read<TestViewmodel>();
    await viewModel.fetchTests("karlo.ciciliani@skole.hr", "2kw3xpAS");
  }

  Future<void> _fetchHolidays() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('SchoolHolidays').get();

    setState(() {
      _holidays = snapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'startDate': (doc['startDate'] as Timestamp).toDate(),
          'endDate': (doc['endDate'] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  bool _isHoliday(DateTime date) {
    for (var holiday in _holidays) {
      DateTime startDate = holiday['startDate'];
      DateTime endDate = holiday['endDate'];

      // Normalize dates to remove the time component
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      DateTime normalizedStartDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      DateTime normalizedEndDate =
          DateTime(endDate.year, endDate.month, endDate.day);

      // Check if the normalized date is within the range (inclusive)
      if ((normalizedDate.isAtSameMomentAs(normalizedStartDate) ||
              normalizedDate.isAtSameMomentAs(normalizedEndDate)) ||
          (normalizedDate.isAfter(normalizedStartDate) &&
              normalizedDate.isBefore(normalizedEndDate))) {
        return true;
      }
    }
    return false;
  }

  void _updateMonth(DateTime date) {
    _firstDayOfMonth = DateTime(date.year, date.month, 1);
    _lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
      _updateMonth(_focusedDate);
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
      _updateMonth(_focusedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TestViewmodel>();

    bool isTest(DateTime date) {
      if (viewModel.tests == null) {
        return false; // No tests available
      }

      for (var monthTests in viewModel.tests!.testsByMonth.values) {
        for (var test in monthTests) {
          // Ensure testDate is in the expected format (e.g., "25.11.")
          if (test.testDate.isEmpty || !test.testDate.contains('.')) {
            continue; // Skip improperly formatted dates
          }

          // Split the date string into day and month
          final dateParts = test.testDate.split('.');
          if (dateParts.length < 2) {
            continue; // Skip if there aren't at least day and month
          }

          final day = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);

          // Construct a DateTime using the current year's context
          final testDate = DateTime(date.year, month, day);

          // Compare the testDate with the provided date
          if (testDate.year == date.year &&
              testDate.month == date.month &&
              testDate.day == date.day) {
            return true; // Match found
          }
        }
      }

      return false; // No match found
    }

    if (viewModel.tests == null && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.fetchTests("karlo.ciciliani@skole.hr", "2kw3xpAS");
      });
    }

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
          : viewModel.tests != null
              ? GestureDetector(
                  onHorizontalDragEnd: (DragEndDetails details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 0) {
                        _goToPreviousMonth(); // Swipe Right
                      } else if (details.primaryVelocity! < 0) {
                        _goToNextMonth(); // Swipe Left
                      }
                    }
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            Row(
                              children: [
                                // RETURN BUTTON
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  iconSize: 50,
                                  color: const Color.fromRGBO(236, 145, 32, 1),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Navigate back
                                  },
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.315),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: _goToPreviousMonth,
                                    ),
                                    Text(
                                      "${_monthNames[_focusedDate.month - 1]} ${_focusedDate.year}",
                                      style: GoogleFonts.inter(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward),
                                      onPressed: _goToNextMonth,
                                    ),
                                  ],
                                ),

                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.2),
                                // color legend

                                Row(children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: const Color.fromRGBO(
                                              23, 148, 210, 1),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: const Color.fromRGBO(
                                              236, 146, 31, 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "PRAZNICI",
                                        style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "ISPITI",
                                        style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800),
                                      )
                                    ],
                                  ),
                                ])
                              ],
                            ),

                            const SizedBox(height: 50),

                            // Weekday Row
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: _weekDays
                                    .map((day) => Expanded(
                                          child: Center(
                                            child: Text(
                                              day,
                                              style: GoogleFonts.inter(
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),

                      // Calendar Grid
                      SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            DateTime day = _calculateDayForCell(index);

                            return DayCell(
                              onTap: () => _showDayDetailsPopup(context, day),
                              date: day,
                              isWithinCurrentMonth: _isWithinCurrentMonth(day),
                              isHoliday: _isHoliday(day),
                              isTest: isTest(day),
                            );
                          },
                          childCount: 42, // Total grid cells (6 rows x 7 days)
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: Text("No data available"),
                ),
    );
  }

  void _showDayDetailsPopup(BuildContext context, DateTime date) {
    final viewModel = context.read<TestViewmodel>();

    // Get tests for the selected date
    List<Map<String, String>> tests = [];
    if (viewModel.tests != null) {
      for (var monthTests in viewModel.tests!.testsByMonth.values) {
        for (var test in monthTests) {
          if (test.testDate.isNotEmpty && test.testDate.contains('.')) {
            final dateParts = test.testDate.split('.');
            if (dateParts.length >= 2) {
              final day = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final testDate = DateTime(date.year, month, day);

              if (testDate.year == date.year &&
                  testDate.month == date.month &&
                  testDate.day == date.day) {
                tests.add({
                  'name': test.testName,
                  'description': test.testDescription,
                });
              }
            }
          }
        }
      }
    }

    // prikazi popup screen
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.56,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // gornji dio - ime mjeseca
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color.fromRGBO(113, 113, 113, 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      _monthNames[date.month - 1].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // sredjni dio - datum i detalji ispita
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DATUM
                        Text(
                          "${date.day}.${date.month}.",
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 20),

                        // TEST
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (tests.isNotEmpty)
                              Text(
                                tests[0]['name']!,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            if (tests.isNotEmpty)
                              Text(
                                tests[0]['description']!,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // donji dio - dodaj događaj u kalendar
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Color.fromRGBO(113, 113, 113, 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.add,
                          color: Color.fromRGBO(113, 113, 113, 1),
                          size: 34,
                        ),
                        const SizedBox(width: 30),
                        Text(
                          "Dodaj događaj u kalendar",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                            color: const Color.fromRGBO(113, 113, 113, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime _calculateDayForCell(int index) {
    // Calculate first day to display in the grid
    int leadingDays = _firstDayOfMonth.weekday - 1;
    return _firstDayOfMonth
        .subtract(Duration(days: leadingDays))
        .add(Duration(days: index));
  }

  bool _isWithinCurrentMonth(DateTime date) {
    return date.month == _focusedDate.month;
  }
}
