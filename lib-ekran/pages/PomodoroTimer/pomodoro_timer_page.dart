// ignore_for_file: use_build_context_synchronously, unused_field

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_ekran/database/firebase_pomodoro_service.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/streaks/vertical_streak_progress.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/widgets/pomodoro_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  late FirestorePomodoroService pomodoroService;

  bool _isInitialized = false;
  bool _isLoading = true;

  int _daysLearning = 0;
  int _hoursLearning = 0;
  int _streakCount = 0;

  int _weeklySessions = 0;
  int _weeklyStreak = 0;

  // trebamo samo email jer ne fetchamo nikakve podatke s ednebvnik api - samo trebamo email uvatiti iz fierbasea jer se tako zove doc u firebaseu
  String? _email;

  // polja i metode za timer firestora
  String _currentPhase = 'Pomodoro';
  bool _isRunning = false;
  int _cycleCount = 0;
  int _initialDuration = 25 * 60; // sekunde
  Timestamp? _startTimestamp;

  int? _clientStartTime;

  // ovo je vrijeme koje se prikazuje korisniku, lokalno
  final int _displayedSecondsLeft = 25 * 60;
  Timer? _localTimer;

  late ValueNotifier<int> _secondsNotifier;

  int get displayedSecondsLeft => _secondsNotifier.value;

  @override
  void initState() {
    super.initState();
    _secondsNotifier = ValueNotifier<int>(0); // Or some other safe default

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromHive();
    });
  }

  int calculateSecondsRemaining(
      int initialDuration, Timestamp? serverTimestamp, int? clientStartTime) {
    // Always prefer client time if available for consistent timing
    if (clientStartTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMillis = now - clientStartTime;
      final elapsedSeconds =
          (elapsedMillis / 1000).floor(); // Use floor() for consistent rounding
      return (initialDuration - elapsedSeconds).clamp(0, initialDuration);
    }
    // Fall back to server timestamp if client time not available
    else if (serverTimestamp != null) {
      final now = DateTime.now();
      final elapsed = now.difference(serverTimestamp.toDate()).inSeconds;
      return (initialDuration - elapsed).clamp(0, initialDuration);
    }

    // If no timing information, just return initial duration
    return initialDuration;
  }

// Function to start local ticker with consistent timing
  void startLocalTicker(
      Timer? localTimer,
      ValueNotifier<int> secondsNotifier,
      bool isRunning,
      Timestamp? startTimestamp,
      int initialDuration,
      int? clientStartTime,
      VoidCallback? onTimerEnd) {
    // Cancel existing timer if any
    localTimer?.cancel();

    if (!isRunning) return;

    localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isRunning) {
        timer.cancel();
        return;
      }

      // Use consistent calculation function
      final secondsLeft = calculateSecondsRemaining(
          initialDuration, startTimestamp, clientStartTime);

      secondsNotifier.value = secondsLeft;

      if (secondsLeft <= 0) {
        timer.cancel();
        if (onTimerEnd != null) {
          onTimerEnd();
        }
      }
    });
  }

  Future<void> _initFromHive() async {
    try {
      final box = await Hive.openBox('user_credentials');
      final storedEmail = box.get('email') as String?;

      // If there’s no email in Hive, maybe exit or handle differently
      if (storedEmail == null) {
        Navigator.of(context).pop();
        return;
      }

      // Retrieve additional prefs
      final prefs = await SharedPreferences.getInstance();
      final screenId = prefs.getString('screenId');

      if (screenId != null) {
        final prefsDoc = await FirebaseFirestore.instance
            .collection('studentProfiles')
            .doc(storedEmail)
            .get();

        if (prefsDoc.exists) {
          final data = prefsDoc.data()!;
          final preferences = data['preferences'] as Map<String, dynamic>;
          setState(() {
            _daysLearning = (preferences['daysLearning'] as int?) ?? 0;
            _hoursLearning = (preferences['hoursLearning'] as int?) ?? 0;
            _email = storedEmail;
          });
        }
      }

      // Now initialize the service
      setState(() {
        pomodoroService = FirestorePomodoroService(
          _email!,
          _daysLearning,
          _hoursLearning,
        );
        pomodoroService.initializeTimer();
        _listenToPomodoroChanges();

        // We are done loading!
        _isLoading = false;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  void _listenToPomodoroChanges() {
    pomodoroService.listenToTimer().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          final mapData = data as Map<String, dynamic>;
          _currentPhase = mapData['currentPhase'] ?? 'Pomodoro';
          _cycleCount = mapData['cycleCount'] ?? 0;
          _isRunning = mapData['isRunning'] ?? false;
          _initialDuration = mapData['currentDuration'] ?? 25 * 60;
          _startTimestamp = mapData['startTimestamp'] as Timestamp?;
          _clientStartTime = mapData['clientStartTime'] as int?;
          _streakCount = mapData['streakCount'] ?? 0;
          _weeklySessions = mapData['weeklySessions'] ?? 0;
          _weeklyStreak = mapData['weeklyStreak'] ?? 0;
        });

        if (_isRunning) {
          _secondsNotifier.value = calculateSecondsRemaining(
              _initialDuration, _startTimestamp, _clientStartTime);

          if (!(_localTimer?.isActive ?? false)) {
            _startLocalTicker();
          }
        } else {
          _secondsNotifier.value = _initialDuration;
          _stopLocalTicker();
        }
      }
    });
  }

  void _startLocalTicker() {
    if (_localTimer != null && _localTimer!.isActive) return;

    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) {
        _stopLocalTicker();
        return;
      }

      final secondsLeft = calculateSecondsRemaining(
          _initialDuration, _startTimestamp, _clientStartTime);

      _secondsNotifier.value = secondsLeft;

      if (secondsLeft <= 0) {
        _stopLocalTicker();
        _forwardTimer();
      }
    });
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  // stopiraj lokalni timer
  void _stopLocalTicker() {
    _localTimer?.cancel();
    _localTimer = null;
  }

  // kada se klikne forward button
  void _forwardTimer() {
    if (_isRunning) {
      String nextPhase;
      int nextDuration;
      int updatedCycleCount = _cycleCount;

      if (_currentPhase == "Pomodoro") {
        if (_cycleCount % 4 == 3) {
          nextPhase = "Duga pauza";
          nextDuration = 15 * 60; // 15 min
        } else {
          nextPhase = "Kratka pauza";
          nextDuration = 5 * 60; // 5 min
        }
      } else if (_currentPhase == "Kratka pauza") {
        nextPhase = "Pomodoro";
        nextDuration = 25 * 60; // 25 min
        updatedCycleCount++;
      } else {
        // Duga pauza
        nextPhase = "Pomodoro";
        nextDuration = 25 * 60;
        updatedCycleCount = 0; // reset cycle nakon duge pauze
      }

      pomodoroService.forwardPhase(
        nextPhase,
        nextDuration,
        updatedCycleCount,
      );
    } else {
      // If the timer is stopped, reset the timer and cycle count
      pomodoroService.forwardPhase(
        "Pomodoro",
        25 * 60, // resetiraj na 25 min
        0, // resetiraj cycle count na 0
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/bird_animation.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            )
          : Column(
              children: [
                // return botun i naslov
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Row(
                    children: [
                      SizedBox(
                          width: MediaQuery.of(context).size.width * 0.032),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        iconSize: 50,
                        color: const Color.fromRGBO(236, 145, 32, 1),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.23),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            "Pomodoro mjerač vremena",
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.05),

                // --- POMODORO CONTAINER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(), // gurne sve desno
                    Padding(
                      padding: const EdgeInsets.only(left: 80),
                      child: PomodoroContainer(
                        currentPhase: _currentPhase,
                        currentDuration:
                            Duration(seconds: _displayedSecondsLeft),
                        isRunning: _isRunning,
                        secondsNotifier: _secondsNotifier,
                        startTimer: () {
                          final leftover = _secondsNotifier.value;
                          pomodoroService.startTimer(
                              _currentPhase, leftover, _cycleCount);
                          setState(() {
                            _isRunning = true;
                            _initialDuration = leftover;
                          });
                        },
                        stopTimer: () {
                          final now = DateTime.now();
                          final elapsed = _startTimestamp != null
                              ? now
                                  .difference(_startTimestamp!.toDate())
                                  .inSeconds
                              : 0;
                          final leftover = (_initialDuration - elapsed)
                              .clamp(0, _initialDuration);

                          pomodoroService.stopTimerWithLocalLeftover(leftover);
                          _stopLocalTicker();
                        },
                        forwardTimer: _forwardTimer,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: VerticalProgressCircles(
                        daysLearning: _daysLearning,
                        hoursLearning: _hoursLearning,
                        streakCount: _weeklySessions,
                        onTap: _showStreakDetails,
                        color: _currentPhase == "Pomodoro"
                            ? const Color.fromRGBO(236, 146, 31, 1)
                            : _currentPhase == "Kratka pauza"
                                ? const Color.fromRGBO(23, 148, 210, 1)
                                : const Color.fromRGBO(20, 133, 186, 1),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // --- CYCLE COUNT ---
                Text(
                  "#${1 + _cycleCount}",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 35,
                    color: _currentPhase == "Pomodoro"
                        ? const Color.fromRGBO(236, 146, 31, 1)
                        : _currentPhase == "Kratka pauza"
                            ? const Color.fromRGBO(23, 148, 210, 1)
                            : const Color.fromRGBO(20, 133, 186, 1),
                  ),
                ),

                // --- PHASE HINT TEXT ---
                _currentPhase == "Pomodoro"
                    ? Text(
                        "Vrijeme je za učiti!",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        "Vrijeme je za pauzu!",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      ),
              ],
            ),
    );
  }

  void _showStreakDetails() {
    final targetSessions = _daysLearning * (_hoursLearning * 60 ~/ 25);
    final progress =
        targetSessions > 0 ? (_weeklySessions / targetSessions).clamp(0, 1) : 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statistika Učenja',
                  style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 40,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildStatItem('🔥 Trenutni Niz', '$_weeklyStreak tjedana'),
              const SizedBox(height: 15),
              _buildStatItem('📅 Cilj tjedno', '$_daysLearning dana/tjedno'),
              const SizedBox(height: 15),
              _buildStatItem('⏳ Dnevni cilj', '$_hoursLearning sati/dan'),
              const SizedBox(height: 15),
              _buildStatItem(
                  '✅ Održane sesije', '$_weeklySessions sesija ovaj tjedan'),
              const Spacer(),
              LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.black.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _currentPhase == "Pomodoro"
                      ? const Color.fromRGBO(236, 146, 31, 1)
                      : _currentPhase == "Kratka pauza"
                          ? const Color.fromRGBO(23, 148, 210, 1)
                          : const Color.fromRGBO(20, 133, 186, 1),
                ),
                minHeight: 20,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Napredak:',
                      style: GoogleFonts.inter(
                          color: _currentPhase == "Pomodoro"
                              ? const Color.fromRGBO(236, 146, 31, 1)
                              : _currentPhase == "Kratka pauza"
                                  ? const Color.fromRGBO(23, 148, 210, 1)
                                  : const Color.fromRGBO(20, 133, 186, 1),
                          fontSize: 16)),
                  Text('${(progress * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                          color: _currentPhase == "Pomodoro"
                              ? const Color.fromRGBO(236, 146, 31, 1)
                              : _currentPhase == "Kratka pauza"
                                  ? const Color.fromRGBO(23, 148, 210, 1)
                                  : const Color.fromRGBO(20, 133, 186, 1),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: _currentPhase == "Pomodoro"
                        ? const Color.fromRGBO(236, 146, 31, 1)
                        : _currentPhase == "Kratka pauza"
                            ? const Color.fromRGBO(23, 148, 210, 1)
                            : const Color.fromRGBO(20, 133, 186, 1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('UREDU',
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
