// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:odlikas_ekran/database/firebase_pomodoro_service.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/widgets/pomodoro_container.dart';

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  late FirestorePomodoroService pomodoroService;

  // trebamo samo email jer ne fetchamo nikakve podatke s ednebvnik api - samo trebamo email uvatiti iz fierbasea jer se tako zove doc u firebaseu
  String? _email;

  Future<void> _initFromHive() async {
    // otvori Hive box
    final box = await Hive.openBox('user_credentials');

    // loadaj email
    final storedEmail = box.get('email') as String?;

    if (storedEmail == null) {
      // ako nema nista u hive-u, vrati na homepage
      debugPrint('No credentials found in Hive.');
      Navigator.of(context).pop();
      return;
    }

    // updejtat state s emailom
    setState(() {
      _email = storedEmail;
    });

    // sad kad imamo email zovi firestore pomdooro service
    pomodoroService = FirestorePomodoroService(_email!);

    // inicializiraj timer i slusaj promjene
    pomodoroService.initializeTimer();
    _listenToPomodoroChanges();
  }

  void _listenToPomodoroChanges() {
    // ovaj dio slusa firebase promjene
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
        });

        if (_isRunning && _startTimestamp != null) {
          final now = DateTime.now();
          final elapsed = now.difference(_startTimestamp!.toDate()).inSeconds;
          final secondsLeft =
              (_initialDuration - elapsed).clamp(0, _initialDuration);
          _secondsNotifier.value = secondsLeft;
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

  // polja i metode za timer firestora
  String _currentPhase = 'Pomodoro';
  bool _isRunning = false;
  int _cycleCount = 0;
  int _initialDuration = 25 * 60; // sekunde
  Timestamp? _startTimestamp;

  // ovo je vrijeme koje se prikazuje korisniku, lokalno
  final int _displayedSecondsLeft = 25 * 60;
  Timer? _localTimer;

  late ValueNotifier<int> _secondsNotifier;

  int get displayedSecondsLeft => _secondsNotifier.value;

  @override
  void initState() {
    super.initState();
    _secondsNotifier = ValueNotifier<int>(_displayedSecondsLeft);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromHive(); // loadaj email/password iz Hivea
    });
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    super.dispose();
  }

  // kreni s lokalnim tickerom koji odbrojava vrijeme savake sec
  void _startLocalTicker() {
    if (_localTimer != null && _localTimer!.isActive) return;

    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning || _startTimestamp == null) {
        _stopLocalTicker();
        return;
      }

      final now = DateTime.now();
      final elapsed = now.difference(_startTimestamp!.toDate()).inSeconds;
      final secondsLeft =
          (_initialDuration - elapsed).clamp(0, _initialDuration);

      _secondsNotifier.value = secondsLeft;

      if (secondsLeft <= 0) {
        _stopLocalTicker();
        _forwardTimer(); // tranzicija s jedne faze na drugu
      }
    });
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
      body: Column(
        children: [
          // return botun i naslov
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.035),
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 50,
                  color: const Color.fromRGBO(236, 145, 32, 1),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.236),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Pomodoro mjerač vremena",
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.05),

          // --- POMODORO CONTAINER ---
          PomodoroContainer(
            currentPhase: _currentPhase,
            currentDuration: Duration(seconds: _displayedSecondsLeft),
            isRunning: _isRunning,
            secondsNotifier: _secondsNotifier,
            startTimer: () {
              // vas lokalni ostatak vremena
              final leftover = _secondsNotifier.value;

              // kreni u firestoru
              pomodoroService.startTimer(_currentPhase, leftover, _cycleCount);

              // updejtaj lokalni state
              setState(() {
                _isRunning = true;
                _startTimestamp = Timestamp.now();
                _initialDuration = leftover;
              });

              // pokreni lokalni timer
              _startLocalTicker();
            },
            stopTimer: () {
              final now = DateTime.now();
              final elapsed = _startTimestamp != null
                  ? now.difference(_startTimestamp!.toDate()).inSeconds
                  : 0;
              final leftover =
                  (_initialDuration - elapsed).clamp(0, _initialDuration);

              pomodoroService.stopTimerWithLocalLeftover(leftover);
              _stopLocalTicker();
            },
            forwardTimer: _forwardTimer,
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
}
