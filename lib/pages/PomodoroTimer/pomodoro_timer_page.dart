import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/pomodoro_notifier.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/widgets/pomodoro_container.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/widgets/session_circles.dart';
import 'package:provider/provider.dart';

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PomodoroNotifier>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroNotifier>(
      builder: (context, notifier, _) {
        final isRunning = notifier.state == TimerState.running;
        final phase = notifier.phase;

        final color = phase == 'Pomodoro'
            ? const Color.fromRGBO(236, 146, 31, 1)
            : phase == 'Kratka pauza'
                ? const Color.fromRGBO(23, 148, 210, 1)
                : const Color.fromRGBO(20, 133, 186, 1);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // --- Header ---
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
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.23),
                    Text(
                      "Pomodoro mjerač vremena",
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

              // --- Session error ---
              if (notifier.sessionError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Greška pri spremanju sesije. Pokušaj ponovo.',
                    style: GoogleFonts.inter(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),

              // --- Timer + Session circles ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  Padding(
                    padding: const EdgeInsets.only(left: 80),
                    child: PomodoroContainer(
                      currentPhase: phase,
                      currentDuration:
                          Duration(seconds: notifier.secondsNotifier.value),
                      isRunning: isRunning,
                      secondsNotifier: notifier.secondsNotifier,
                      startTimer: notifier.start,
                      stopTimer: notifier.pause,
                      forwardTimer: notifier.skipToNext,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: SessionCircles(
                      todaySessions: notifier.todaySessions,
                      color: color,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Cycle count ---
              Text(
                "#${1 + notifier.cycleCount}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 35,
                  color: color,
                ),
              ),

              // --- Phase hint ---
              Text(
                phase == 'Pomodoro'
                    ? "Vrijeme je za učiti!"
                    : "Vrijeme je za pauzu!",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              // --- Streak info ---
              Text(
                "🔥 ${notifier.currentStreak} dan niz  •  ${notifier.todaySessions}/8 sesija danas",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),

              // --- Capped banner ---
              if (notifier.isCapped)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Dnevni maksimum dostignut (8/8). Odlično!",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
