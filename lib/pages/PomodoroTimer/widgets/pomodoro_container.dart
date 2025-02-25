import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PomodoroContainer extends StatefulWidget {
  final String currentPhase;
  final Duration currentDuration;
  final bool isRunning;
  final VoidCallback startTimer;
  final ValueNotifier<int> secondsNotifier;
  final VoidCallback stopTimer;
  final VoidCallback forwardTimer;

  const PomodoroContainer({
    Key? key,
    required this.currentPhase,
    required this.secondsNotifier,
    required this.currentDuration,
    required this.isRunning,
    required this.startTimer,
    required this.stopTimer,
    required this.forwardTimer,
  }) : super(key: key);

  @override
  State<PomodoroContainer> createState() => _PomodoroContainerState();
}

class _PomodoroContainerState extends State<PomodoroContainer> {
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: widget.currentPhase == "Pomodoro"
            ? const Color.fromRGBO(236, 146, 31, 1)
            : widget.currentPhase == "Kratka pauza"
                ? const Color.fromRGBO(23, 148, 210, 1)
                : const Color.fromRGBO(20, 133, 186, 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // --- Phase Tabs na vrhu containera ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pomodoro Tab
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: widget.currentPhase == "Pomodoro"
                        ? const Color.fromRGBO(202, 127, 30, 10)
                        : Colors.transparent,
                  ),
                  child: Text(
                    "Pomodoro",
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: widget.currentPhase == "Pomodoro"
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.currentPhase == "Pomodoro"
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

              // Kratka Pauza Tab
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: widget.currentPhase == "Kratka pauza"
                      ? const Color.fromRGBO(0, 124, 185, 10)
                      : Colors.transparent,
                ),
                child: Text(
                  "Kratka pauza",
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: widget.currentPhase == "Kratka pauza"
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: widget.currentPhase == "Kratka pauza"
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                  ),
                ),
              ),

              // Duga Pauza Tab
              Padding(
                padding: const EdgeInsets.only(right: 50),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: widget.currentPhase == "Duga pauza"
                        ? const Color.fromRGBO(14, 93, 130, 10)
                        : Colors.transparent,
                  ),
                  child: Text(
                    "Duga pauza",
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: widget.currentPhase == "Duga pauza"
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.currentPhase == "Duga pauza"
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- Timer Display + Controls ---
          Column(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: widget.secondsNotifier,
                builder: (context, secondsLeft, child) {
                  final duration = Duration(seconds: secondsLeft);
                  // Format minute:sekunde
                  String timeText = formatDuration(duration);
                  return Text(
                    timeText,
                    style: GoogleFonts.inter(
                      fontSize: 150,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                },
              ),

              // Start/Stop + Forward botuni
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 150),

                  // "Započni" or "Zaustavi" botui
                  SizedBox(
                    width: 300, // Fixed width
                    child: Transform.translate(
                      offset: Offset(
                          0,
                          widget.isRunning
                              ? 5
                              : 0), // 5 pixels down when active
                      child: ElevatedButton(
                        onPressed: widget.isRunning
                            ? widget.stopTimer
                            : widget.startTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: widget.currentPhase == "Pomodoro"
                              ? const Color.fromRGBO(236, 146, 31, 1)
                              : widget.currentPhase == "Kratka pauza"
                                  ? const Color.fromRGBO(23, 148, 210, 1)
                                  : const Color.fromRGBO(20, 133, 186, 1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 70,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          elevation: widget.isRunning ? 0 : 5,
                        ),
                        child: Text(widget.isRunning ? "ZAUSTAVI" : "ZAPOČNI"),
                      ),
                    ),
                  ),

                  const SizedBox(width: 50),

                  // Forward / Skip Phase botuni
                  widget.isRunning
                      ? IconButton(
                          onPressed: widget.forwardTimer,
                          icon: const Icon(Icons.skip_next),
                          iconSize: 100,
                          color: Colors.white,
                        )
                      //skrivamo reset button jer ga vise ne koristimo
                      : Opacity(
                          opacity: 0,
                          child: IgnorePointer(
                            child: IconButton(
                              onPressed: widget.forwardTimer,
                              icon: const Icon(Icons.rotate_right_outlined),
                              iconSize: 100,
                              color: Colors.white,
                            ),
                          ),
                        )
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
