// ignore_for_file: unused_field, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_ekran/pages/Calendar/widgets/day_cell.dart';
import 'package:odlikas_ekran/viewmodels/test_viewmodel.dart';
import 'package:odlikas_ekran/viewmodels/viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String? _email;
  String? _password;

  Future<void> _fetchCredentialsAndGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final screenId = prefs.getString('screenId');

    if (screenId == null) {
      debugPrint('No screen ID found');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('CreatedScreens')
          .doc(screenId)
          .get();

      if (doc.exists) {
        final fetchedEmail = doc.get('linkedUser') as String?;
        final fetchedPassword = doc.get('password') as String?;

        if (fetchedEmail != null && fetchedPassword != null) {
          // Update local state
          setState(() {
            _email = fetchedEmail;
            _password = fetchedPassword;
          });

          // Save to Hive for next time
          final box = await Hive.openBox('user_credentials');
          await box.put('email', fetchedEmail);
          await box.put('password', fetchedPassword);

          // Now fetch the grades
          _fetchGradesFromViewModel(fetchedEmail, fetchedPassword);
        }
      }
    } catch (e) {
      print('Error fetching credentials: $e');
    }
  }

  void _fetchGradesFromViewModel(String email, String password) {
    final viewModel = context.read<HomePageViewModel>();
    viewModel.fetchGrades(email, password);
    viewModel.fetchStudentProfile(email, password);
  }

  Future<void> _initFromHive() async {
    // 1) Open (or create) your Hive box
    final box = await Hive.openBox('user_credentials');

    // 2) Attempt to read stored credentials
    final storedEmail = box.get('email') as String?;
    final storedPassword = box.get('password') as String?;

    if (storedEmail != null && storedPassword != null) {
      // We have them locally, so set state and fetch the grades
      setState(() {
        _email = storedEmail;
        _password = storedPassword;
      });

      _fetchGradesFromViewModel(storedEmail, storedPassword);
    } else {
      // No credentials in Hive, fall back to Firebase
      debugPrint('No credentials found in Hive. Fetching from Firebase...');
      await _fetchCredentialsAndGrades(); // the Firebase version
    }
  }

  @override
  void initState() {
    _updateMonth(_focusedDate);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromHive();
      _fetchHolidays();
    });
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

  // SAVE EVENTS IN FIREBASE
  Future<void> saveEvent({
    required String title,
    required String description,
    required DateTime date,
  }) async {
    // Make sure _email is not null before saving
    if (_email == null) {
      debugPrint('No email found. Cannot save event.');
      return;
    }

    try {
      // koristi subcollection pod 'CalendarEvents/{_email}/events'
      await FirebaseFirestore.instance
          .collection('CalendarEvents')
          .doc(_email) // email ucenika
          .collection('events') // subcollection events
          .add({
        'title': title,
        'description': description,
        'date': date,
      });

      debugPrint('Event saved successfully for user $_email.');
    } catch (e) {
      debugPrint('Error saving event: $e');
    }
  }

  Future<List<Map<String, String>>> _fetchEvents(DateTime date) async {
    if (_email == null) {
      debugPrint('No email found. Cannot fetch events.');
      return [];
    }

    try {
      // trazi sve evente za odredjeni datum pod user emailom
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('CalendarEvents')
          .doc(_email)
          .collection('events')
          .where('date', isEqualTo: date)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'title': doc['title'] as String,
          'description': doc['description'] as String,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TestViewmodel>();

    bool isTest(DateTime date) {
      if (viewModel.tests == null) {
        return false;
      }

      for (var monthTests in viewModel.tests!.testsByMonth.values) {
        for (var test in monthTests) {
          // pobrini se da je test u formatu "25.11." dan / mjesec
          if (test.testDate.isEmpty || !test.testDate.contains('.')) {
            continue;
          }

          // splitaj dan i mjesec
          final dateParts = test.testDate.split('.');
          if (dateParts.length < 2) {
            continue;
          }

          final day = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);

          // napravi datetime s trenutnom godinom jer u ednevniku ne pise godina samo datum
          final testDate = DateTime(date.year, month, day);

          // usporedi testdate s danom u kalendaru
          if (testDate.year == date.year &&
              testDate.month == date.month &&
              testDate.day == date.day) {
            return true;
          }
        }
      }

      return false;
    }

    if (viewModel.tests == null && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.fetchTests(_email!, _password!);
      });
    }

    if (_email == null) {
      // Show a loading indicator or a message while _email is still null
      return Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/animations/bird_animation.json',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
      );
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
                        _goToPreviousMonth(); // swipe desno
                      } else if (details.primaryVelocity! < 0) {
                        _goToNextMonth(); // swipe livo
                      }
                    }
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                // RETURN BUTTON
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.035),
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  iconSize: 50,
                                  color: const Color.fromRGBO(236, 145, 32, 1),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.29),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      iconSize: 45,
                                      icon:
                                          const Icon(Icons.keyboard_arrow_left),
                                      onPressed: _goToPreviousMonth,
                                    ),
                                    Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        Text(
                                          "${_monthNames[_focusedDate.month - 1]} ",
                                          style: GoogleFonts.inter(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w800),
                                        ),
                                        Text(
                                          "${_focusedDate.year}",
                                          style: GoogleFonts.inter(
                                              fontSize: 22,
                                              color: const Color.fromRGBO(
                                                  113, 113, 113, 1),
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.keyboard_arrow_right),
                                      iconSize: 45,
                                      onPressed: _goToNextMonth,
                                    ),
                                  ],
                                ),

                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.24),
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

                            // redak s danima u tjednu
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 70.0),
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
                          ],
                        ),
                      ),

                      // kalendar grid
                      SliverPadding(
                        padding: const EdgeInsets.only(
                            left: 80, right: 80, top: 10, bottom: 10),
                        sliver: SliverGrid(
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
                                isWithinCurrentMonth:
                                    _isWithinCurrentMonth(day),
                                isHoliday: _isHoliday(day),
                                isTest: isTest(day),
                              );
                            },
                            childCount: 42,
                          ),
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
    List<Map<String, String>> tests = [];
    List<Map<String, String>> events = [];
    bool isAddingEvent = false;
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

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
                  'description': test.testDescription
                });
              }
            }
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<List<Map<String, String>>>(
              future: _fetchEvents(date),
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
                } else if (snapshot.hasError) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/bird_animation.json',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  );
                } else {
                  events = snapshot.data ?? [];

                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    contentPadding: EdgeInsets.zero,
                    content: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: MediaQuery.of(context).size.width * 0.56,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ime mjeseca header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color:
                                            Color.fromRGBO(113, 113, 113, 0.2),
                                        width: 1)),
                              ),
                              child: Text(
                                _monthNames[date.month - 1].toUpperCase(),
                                style: GoogleFonts.inter(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black),
                              ),
                            ),

                            // testovi i ostali dogadaji
                            Expanded(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24, horizontal: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${date.day}.${date.month}.",
                                        style: GoogleFonts.inter(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black),
                                      ),
                                      const SizedBox(width: 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ...tests.map((test) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  test['name']!,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.black),
                                                ),
                                                Text(
                                                  test['description']!,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.black),
                                                ),
                                              ],
                                            );
                                          }),
                                          ...events.map((event) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  event['title']!,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.black),
                                                ),
                                                Text(
                                                  event['description']!,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.black),
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // dodaj dogadaj u kalendar sekcija
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                      () => isAddingEvent = !isAddingEvent),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                          top: BorderSide(
                                              color: Color.fromRGBO(
                                                  113, 113, 113, 0.2),
                                              width: 1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                            isAddingEvent
                                                ? Icons.remove
                                                : Icons.add,
                                            color: Colors.grey,
                                            size: 34),
                                        const SizedBox(width: 30),
                                        Text(
                                          "Dodaj događaj u kalendar",
                                          style: GoogleFonts.inter(
                                              fontSize: 24,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Expandable Event Input Fields
                                if (isAddingEvent)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(width: 20),
                                        // polja za upis opisa i naslova
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // naslov sekcija
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.4,
                                              child: TextField(
                                                controller: titleController,
                                                style: GoogleFonts.inter(
                                                    fontSize: 20),
                                                decoration: InputDecoration(
                                                  hintText: "Naslov",
                                                  hintStyle: GoogleFonts.inter(
                                                      color:
                                                          const Color.fromRGBO(
                                                              113,
                                                              113,
                                                              113,
                                                              1)),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8,
                                                          horizontal: 12),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                            color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            //  opis sekcija
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.4,
                                              child: TextField(
                                                maxLines: 3,
                                                controller:
                                                    descriptionController,
                                                style: GoogleFonts.inter(
                                                    fontSize: 20),
                                                maxLength: 30,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      "Opis (maksimalno 30 slova)",
                                                  hintStyle: GoogleFonts.inter(
                                                      color:
                                                          const Color.fromRGBO(
                                                              113,
                                                              113,
                                                              113,
                                                              1)),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8,
                                                          horizontal: 12),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                            color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 20),
                                        // Buttons
                                        Column(
                                          children: [
                                            const SizedBox(height: 20),
                                            IconButton(
                                              icon: const Icon(Icons.cancel,
                                                  size: 50),
                                              color: Colors.red,
                                              onPressed: () => setState(
                                                  () => isAddingEvent = false),
                                            ),
                                            const SizedBox(width: 10),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.check_circle,
                                                  size: 50),
                                              color: Colors.blue,
                                              onPressed: () async {
                                                setState(() =>
                                                    isAddingEvent = false);
                                                // 1. data iz kontrolera
                                                final enteredTitle =
                                                    titleController.text.trim();
                                                final enteredDescription =
                                                    descriptionController.text
                                                        .trim();
                                                // datum
                                                final selectedDate = date;

                                                // 2. spremi u firestore
                                                await saveEvent(
                                                  title: enteredTitle,
                                                  description:
                                                      enteredDescription,
                                                  date: selectedDate,
                                                );
                                                if (mounted) {
                                                  Navigator.pop(context);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  DateTime _calculateDayForCell(int index) {
    // izracunaj prvi dan mjeseca
    int leadingDays = _firstDayOfMonth.weekday - 1;
    return _firstDayOfMonth
        .subtract(Duration(days: leadingDays))
        .add(Duration(days: index));
  }

  bool _isWithinCurrentMonth(DateTime date) {
    return date.month == _focusedDate.month;
  }
}
