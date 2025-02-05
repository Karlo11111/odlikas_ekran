import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePomodoroService {
  final String timerId;

  FirestorePomodoroService(this.timerId);

  DocumentReference get timerDoc =>
      FirebaseFirestore.instance.collection('pomodoroTimers').doc(timerId);

  Future<void> initializeTimer() async {
    final docSnapshot = await timerDoc.get();
    if (!docSnapshot.exists) {
      await timerDoc.set({
        'currentPhase': 'Pomodoro',
        'currentDuration': 25 * 60,
        'isRunning': false,
        'cycleCount': 0,
        'startTimestamp': null,
      });
    }
  }

  Future<void> startTimer(
      String currentPhase, int duration, int cycleCount) async {
    await timerDoc.set({
      'currentPhase': currentPhase,
      'currentDuration': duration,
      'isRunning': true,
      'cycleCount': cycleCount,
      'startTimestamp': FieldValue.serverTimestamp(), // server timestamp
    }, SetOptions(merge: true));
  }

  Future<void> stopTimerWithLocalLeftover(int localLeftover) async {
    // localLeftover is your local _secondsNotifier.value
    final docSnapshot = await timerDoc.get();
    if (docSnapshot.exists) {
      await timerDoc.update({
        'currentDuration': localLeftover,
        'isRunning': false,
        'startTimestamp': null,
      });
    }
  }

  Future<void> forwardPhase(
      String newPhase, int newDuration, int cycleCount) async {
    await timerDoc.set({
      'currentPhase': newPhase,
      'currentDuration': newDuration,
      'cycleCount': cycleCount,
      'isRunning': false,
      'startTimestamp': null,
    }, SetOptions(merge: true));
  }

  // slusaj promene na timeru
  Stream<DocumentSnapshot> listenToTimer() {
    return timerDoc.snapshots();
  }
}
