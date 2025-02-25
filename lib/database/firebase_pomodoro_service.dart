import 'package:cloud_firestore/cloud_firestore.dart';

// klasa za interakciju sa Firestore bazom podataka za Pomodoro timer
class FirestorePomodoroService {
  final String timerId;
  final int daysLearning;
  final int hoursLearning;

  FirestorePomodoroService(this.timerId, int days, int hours)
      : daysLearning = days,
        hoursLearning = hours;

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
        'weeklySessions': 0,
        'weeklyStreak': 0,
        'lastUpdatedWeek': Timestamp.now(),
      }, SetOptions(merge: true));
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
    final now = DateTime.now();
    final data = <String, dynamic>{
      'currentPhase': newPhase,
      'currentDuration': newDuration,
      'cycleCount': cycleCount,
      'isRunning': false,
      'startTimestamp': null,
    };

    final doc = await timerDoc.get();
    final existingData = doc.data() as Map<String, dynamic>;

    // Handle null case for lastUpdatedWeek
    final lastUpdatedWeek = existingData['lastUpdatedWeek'] as Timestamp?;

    final lastUpdated = lastUpdatedWeek?.toDate() ??
        DateTime(2000); // Use a default old date if null

    // Handle null cases for weekly values
    int weeklySessions = existingData['weeklySessions'] ?? 0;
    int weeklyStreak = existingData['weeklyStreak'] ?? 0;

    final targetSessions = daysLearning * (hoursLearning * 60 ~/ 30);

    if (!_isSameWeek(lastUpdated, now)) {
      final metGoal = weeklySessions >= targetSessions;

      data['weeklyStreak'] = metGoal ? weeklyStreak + 1 : 0;
      data['weeklySessions'] = 1;
      data['lastUpdatedWeek'] = Timestamp.now();
    } else {
      data['weeklySessions'] = FieldValue.increment(1);
    }

    await timerDoc.set(data, SetOptions(merge: true));
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final aStart = a.subtract(Duration(days: a.weekday - 1));
    final bStart = b.subtract(Duration(days: b.weekday - 1));
    return aStart.year == bStart.year &&
        aStart.month == bStart.month &&
        aStart.day == bStart.day;
  }

  // slusaj promjene na timeru
  Stream<DocumentSnapshot> listenToTimer() {
    return timerDoc.snapshots();
  }
}
