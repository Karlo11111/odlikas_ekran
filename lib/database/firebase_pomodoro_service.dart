import 'package:cloud_firestore/cloud_firestore.dart';

// klasa za interakciju sa Firestore bazom podataka za Pomodoro timer
class FirestorePomodoroService {
  final String timerId;

  FirestorePomodoroService(this.timerId);

  // referenca na dokument u Firestore bazi podataka
  DocumentReference get timerDoc =>
      FirebaseFirestore.instance.collection('pomodoroTimers').doc(timerId);

  // metoda za inicijalizaciju timera
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

  // metoda za pokretanje timera
  Future<void> startTimer(
      String currentPhase, int duration, int cycleCount) async {
    await timerDoc.set({
      'currentPhase': currentPhase,
      'currentDuration': duration,
      'isRunning': true,
      'cycleCount': cycleCount,
      'startTimestamp': FieldValue.serverTimestamp(), // vrijeme servera
    }, SetOptions(merge: true));
  }

  // metoda za zaustavljanje timera s lokalnim preostalim vremenom
  Future<void> stopTimerWithLocalLeftover(int localLeftover) async {
    final docSnapshot = await timerDoc.get();
    if (docSnapshot.exists) {
      await timerDoc.update({
        'currentDuration': localLeftover,
        'isRunning': false,
        'startTimestamp': null,
      });
    }
  }

  // metoda za prelazak u sljedeću fazu
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

  // slusaj promjene na timeru
  Stream<DocumentSnapshot> listenToTimer() {
    return timerDoc.snapshots();
  }
}
