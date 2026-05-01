import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePomodoroService {
  final String timerId;
  final int daysLearning;
  final int hoursLearning;

  FirestorePomodoroService(this.timerId,
      [this.daysLearning = 0, this.hoursLearning = 0]);

  DocumentReference get timerDoc =>
      FirebaseFirestore.instance.collection('pomodoroTimers').doc(timerId);

  // funkcija koja inacijalizira timer u bazi podataka
  Future<void> initializeTimer() async {
    final docSnapshot = await timerDoc.get();
    if (!docSnapshot.exists) {
      await timerDoc.set({
        'currentPhase': 'Pomodoro',
        'currentDuration': 25 * 60,
        'isRunning': false,
        'cycleCount': 0,
        'startTimestamp': null,
        'clientStartTime': null,
        'streakCount': 0,
        'weeklySessions': 0,
        'weeklyStreak': 0,
        'lastSessionDate': null,
      });
    }
  }

  // funkcija koja pokrece timer
  Future<void> startTimer(
      String currentPhase, int duration, int cycleCount) async {
    // dobijanje trenutnog vremena
    final now = DateTime.now();
    final currentMs = now.millisecondsSinceEpoch;

    // izracunavanje vremena do sljedece sekunde da bi se izbjeglo neprecizno mjerenje
    final msToNextSecond = 1000 - (currentMs % 1000);
    final nextSecondBoundary = currentMs + msToNextSecond;

    // cekaj do sljedece sekunde
    await Future.delayed(Duration(milliseconds: msToNextSecond));

    // spremi i server i lokalni timestamp
    final updateData = {
      'currentPhase': currentPhase,
      'currentDuration': duration,
      'isRunning': true,
      'cycleCount': cycleCount,
      'startTimestamp': Timestamp.fromDate(DateTime.now()),
      'clientStartTime': nextSecondBoundary,
      'syncToken': DateTime.now().microsecondsSinceEpoch,
    };

    // logika za streakove i sesije
    final docSnapshot = await timerDoc.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>?;
      if (data != null) {
        final streakUpdates =
            await _calculateStreakUpdates(data, Timestamp.fromDate(now));
        if (streakUpdates.isNotEmpty) {
          updateData.addAll(streakUpdates.cast<String, Object>());
        }
      }
    }

    // spremi podatke u bazu
    await timerDoc.set(updateData, SetOptions(merge: true));
  }

  // funkcija koja racuna streakove i sesije
  Future<Map<String, dynamic>> _calculateStreakUpdates(
      Map<String, dynamic> data, Timestamp now) async {
    final lastSessionTimestamp = data['lastSessionDate'] as Timestamp?;
    int streakCount = data['streakCount'] ?? 0;
    int weeklySessions = data['weeklySessions'] ?? 0;
    int weeklyStreak = data['weeklyStreak'] ?? 0;

    final currentDate = now.toDate();

    // ako je prvi put pokrenut tajmer, postavi sve na 1
    if (lastSessionTimestamp == null) {
      return {
        'lastSessionDate': now,
        'streakCount': 1,
        'weeklySessions': 1,
        'weeklyStreak': 1,
      };
    }

    final lastSessionDate = lastSessionTimestamp.toDate();

    // provjeri je li novi dan
    final isNewDay = !_isSameDay(currentDate, lastSessionDate);

    // provjeri jesmo li u istom tjednu
    final isNewWeek = !_isSameWeek(currentDate, lastSessionDate);

    // preskoči ako nije novi dan
    if (!isNewDay) {
      return {};
    }

    // resetiraj tjedne sesije ako je novi tjedan
    if (isNewWeek) {
      // ako smo zavrsili sesiju, resetiraj tjedne sesije
      final targetSessions = daysLearning > 0 ? daysLearning : 1;
      if (weeklySessions >= targetSessions) {
        weeklyStreak++;
      } else {
        weeklyStreak = 0;
      }

      weeklySessions = 1;
    } else {
      weeklySessions++;
    }

    // za nove sesije dodaj 1 na streak
    streakCount++;

    return {
      'lastSessionDate': now,
      'streakCount': streakCount,
      'weeklySessions': weeklySessions,
      'weeklyStreak': weeklyStreak,
    };
  }

  // funkcija koja zaustavlja timer s lokalnim preostalim vremenom
  Future<void> stopTimerWithLocalLeftover(int localLeftover) async {
    final syncToken = DateTime.now().microsecondsSinceEpoch;

    await timerDoc.update({
      'currentDuration': localLeftover,
      'isRunning': false,
      'startTimestamp': null,
      'clientStartTime': null,
      'syncToken': syncToken,
    });
  }

  // funkcija koja preskače trenutnu fazu
  Future<void> forwardPhase(
      String newPhase, int newDuration, int cycleCount) async {
    final syncToken = DateTime.now().microsecondsSinceEpoch;

    // Check if a Pomodoro was completed
    final docSnapshot = await timerDoc.get();
    final data = docSnapshot.exists
        ? (docSnapshot.data() as Map<String, dynamic>)
        : null;
    final currentPhase = data?['currentPhase'];

    // Check if a Pomodoro was completed
    bool completedPomodoro = currentPhase == 'Pomodoro' &&
        (newPhase == 'Kratka pauza' || newPhase == 'Duga pauza');

    final updateData = {
      'currentPhase': newPhase,
      'currentDuration': newDuration,
      'cycleCount': cycleCount,
      'isRunning': false,
      'startTimestamp': null,
      'clientStartTime': null,
      'syncToken': syncToken,
    };

    // azuriraj podatke o tjednim sesijama i streakovima
    if (completedPomodoro) {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      // dobij podatke o trenutnom tjednu
      int weeklySessions = data?['weeklySessions'] ?? 0;

      // provjeri trebamo li azurirati tjedne sesije
      final lastUpdatedWeek = data?['lastUpdatedWeek'] as Timestamp?;
      if (lastUpdatedWeek != null) {
        final lastWeekDate = lastUpdatedWeek.toDate();
        if (!_isSameWeek(lastWeekDate, now)) {
          // resetiraj za novi tjedan
          final targetSessions = daysLearning > 0 ? daysLearning : 1;
          final int weeklyStreak = data?['weeklyStreak'] ?? 0;

          updateData['weeklyStreak'] =
              weeklySessions >= targetSessions ? weeklyStreak + 1 : 0;
          updateData['weeklySessions'] = 1;
          updateData['lastUpdatedWeek'] = timestamp;
        } else {
          // ako je isti tjedan, samo povecaj broj sesija
          updateData['weeklySessions'] = FieldValue.increment(1);
        }
      } else {
        // prvi put postavi tjedne sesije
        updateData['weeklySessions'] = 1;
        updateData['lastUpdatedWeek'] = timestamp;
      }
    }

    // postavi azurirane podatke u bazu
    await timerDoc.set(updateData, SetOptions(merge: true));
  }

  // pomoćne funkcije za provjeru dana i tjedna
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    // dobij ponedjeljak kao prvi dan tjedna
    final aStart = a.subtract(Duration(days: a.weekday - 1));
    final bStart = b.subtract(Duration(days: b.weekday - 1));
    return aStart.year == bStart.year &&
        aStart.month == bStart.month &&
        aStart.day == bStart.day;
  }

  // slušaj promjene u dokumentu u Firestoreu
  Stream<DocumentSnapshot> listenToTimer() {
    return timerDoc.snapshots();
  }
}
