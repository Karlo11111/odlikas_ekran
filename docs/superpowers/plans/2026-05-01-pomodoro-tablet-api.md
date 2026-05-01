# Pomodoro Tablet API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing Firestore-based Pomodoro timer with an API-driven implementation that mirrors the mobile app exactly, calling the ASP.NET `/api/Pomodoro/*` endpoints for streak tracking and session completion.

**Architecture:** A new `PomodoroApiService` handles HTTP calls (bearer token from Hive). A `PomodoroNotifier` (ChangeNotifier) owns all timer state and calls the service, exposing a `ValueNotifier<int>` for the countdown. The existing `PomodoroTimerPage` is rewritten as a `Consumer<PomodoroNotifier>`, keeping the existing `PomodoroContainer` widget unchanged.

**Tech Stack:** Flutter, provider ^6.1.2, http ^1.3.0, hive ^2.2.3, flutter_dotenv

---

## File Map

| Action | Path | Responsibility |
|--------|------|---------------|
| Create | `lib/database/api/pomodoro_api_service.dart` | `PomodoroSessionResult` model + `PomodoroApiService` (HTTP wrapper) |
| Create | `lib/pages/PomodoroTimer/pomodoro_notifier.dart` | `TimerState` enum + `PomodoroNotifier` (all timer logic + state) |
| Create | `lib/pages/PomodoroTimer/widgets/session_circles.dart` | 8-circle session progress widget |
| Modify | `lib/main.dart` | Register `PomodoroNotifier` as `ChangeNotifierProvider` |
| Rewrite | `lib/pages/PomodoroTimer/pomodoro_timer_page.dart` | `Consumer<PomodoroNotifier>` page (removes Firestore deps) |
| Create | `test/pomodoro_api_service_test.dart` | Model parsing unit tests |
| Create | `test/pomodoro_notifier_test.dart` | Timer state machine unit tests |

---

## Task 1: PomodoroApiService

**Files:**
- Create: `lib/database/api/pomodoro_api_service.dart`
- Create: `test/pomodoro_api_service_test.dart`

- [ ] **Step 1: Write the failing model tests**

Create `test/pomodoro_api_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/database/api/pomodoro_api_service.dart';

void main() {
  group('PomodoroSessionResult.fromStreakJson', () {
    test('parses all fields correctly', () {
      final result = PomodoroSessionResult.fromStreakJson({
        'currentStreak': 3,
        'longestStreak': 7,
        'todaySessions': 2,
        'todayMinutes': 50,
      });
      expect(result.currentStreak, 3);
      expect(result.longestStreak, 7);
      expect(result.todaySessions, 2);
      expect(result.todayMinutes, 50);
      expect(result.capped, isNull);
    });

    test('defaults to 0 for missing fields', () {
      final result = PomodoroSessionResult.fromStreakJson({});
      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.todaySessions, 0);
      expect(result.todayMinutes, 0);
    });

    test('handles num type (not just int)', () {
      final result = PomodoroSessionResult.fromStreakJson({
        'currentStreak': 3.0,
        'longestStreak': 7.0,
        'todaySessions': 2.0,
        'todayMinutes': 50.0,
      });
      expect(result.todaySessions, 2);
    });
  });

  group('PomodoroSessionResult.fromCompleteJson', () {
    test('parses streak nested object and capped flag', () {
      final result = PomodoroSessionResult.fromCompleteJson({
        'streak': {
          'currentStreak': 3,
          'longestStreak': 7,
          'todaySessions': 3,
          'todayMinutes': 75,
        },
        'capped': false,
      });
      expect(result.currentStreak, 3);
      expect(result.todaySessions, 3);
      expect(result.todayMinutes, 75);
      expect(result.capped, false);
    });

    test('capped is true when server returns true', () {
      final result = PomodoroSessionResult.fromCompleteJson({
        'streak': {
          'currentStreak': 5,
          'longestStreak': 10,
          'todaySessions': 8,
          'todayMinutes': 200,
        },
        'capped': true,
      });
      expect(result.capped, true);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd D:/FlutterProjects/odlikas_ekran
flutter test test/pomodoro_api_service_test.dart
```

Expected: FAIL — `pomodoro_api_service.dart` not found.

- [ ] **Step 3: Create `lib/database/api/pomodoro_api_service.dart`**

```dart
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class PomodoroSessionResult {
  final int currentStreak;
  final int longestStreak;
  final int todaySessions;
  final int todayMinutes;
  final bool? capped;

  PomodoroSessionResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.todaySessions,
    required this.todayMinutes,
    this.capped,
  });

  factory PomodoroSessionResult.fromStreakJson(Map<String, dynamic> json) {
    return PomodoroSessionResult(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      todaySessions: (json['todaySessions'] as num?)?.toInt() ?? 0,
      todayMinutes: (json['todayMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  factory PomodoroSessionResult.fromCompleteJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>;
    return PomodoroSessionResult(
      currentStreak: (streak['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (streak['longestStreak'] as num?)?.toInt() ?? 0,
      todaySessions: (streak['todaySessions'] as num?)?.toInt() ?? 0,
      todayMinutes: (streak['todayMinutes'] as num?)?.toInt() ?? 0,
      capped: json['capped'] as bool?,
    );
  }
}

class PomodoroApiService {
  final String baseUrl;

  PomodoroApiService(this.baseUrl);

  Future<Map<String, String>> _headers() async {
    final box = await Hive.openBox('user_credentials');
    final token = box.get('token') as String? ?? '';
    return {'Authorization': 'Bearer $token'};
  }

  Future<PomodoroSessionResult> getStreak() async {
    final url = Uri.parse('$baseUrl/api/Pomodoro/GetStreak');
    final response = await http.get(url, headers: await _headers());
    if (response.statusCode == 200) {
      return PomodoroSessionResult.fromStreakJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('GetStreak failed: ${response.statusCode}');
  }

  Future<PomodoroSessionResult> completeSession() async {
    final url = Uri.parse('$baseUrl/api/Pomodoro/CompleteSession');
    final response = await http.post(url, headers: await _headers());
    if (response.statusCode == 200) {
      return PomodoroSessionResult.fromCompleteJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('CompleteSession failed: ${response.statusCode}');
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/pomodoro_api_service_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/database/api/pomodoro_api_service.dart test/pomodoro_api_service_test.dart
git commit -m "feat: add PomodoroApiService and PomodoroSessionResult model"
```

---

## Task 2: PomodoroNotifier

**Files:**
- Create: `lib/pages/PomodoroTimer/pomodoro_notifier.dart`
- Create: `test/pomodoro_notifier_test.dart`

- [ ] **Step 1: Write the failing notifier tests**

Create `test/pomodoro_notifier_test.dart`:

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/database/api/pomodoro_api_service.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/pomodoro_notifier.dart';

// Fake service for testing — no network calls
class FakePomodoroApiService extends PomodoroApiService {
  PomodoroSessionResult? streakResult;
  PomodoroSessionResult? completeResult;
  bool shouldThrowOnComplete = false;

  FakePomodoroApiService() : super('http://fake');

  @override
  Future<PomodoroSessionResult> getStreak() async {
    return streakResult ??
        PomodoroSessionResult(
          currentStreak: 0,
          longestStreak: 0,
          todaySessions: 0,
          todayMinutes: 0,
        );
  }

  @override
  Future<PomodoroSessionResult> completeSession() async {
    if (shouldThrowOnComplete) throw Exception('network error');
    return completeResult ??
        PomodoroSessionResult(
          currentStreak: 1,
          longestStreak: 1,
          todaySessions: 1,
          todayMinutes: 25,
          capped: false,
        );
  }
}

void main() {
  group('PomodoroNotifier initial state', () {
    test('starts idle with 25 minutes on the clock', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      expect(notifier.state, TimerState.idle);
      expect(notifier.phase, 'Pomodoro');
      expect(notifier.secondsNotifier.value, 25 * 60);
      expect(notifier.isCapped, false);
      expect(notifier.sessionError, isNull);
      notifier.dispose();
    });
  });

  group('init()', () {
    test('loads streak data from API', () async {
      final api = FakePomodoroApiService();
      api.streakResult = PomodoroSessionResult(
        currentStreak: 3,
        longestStreak: 7,
        todaySessions: 2,
        todayMinutes: 50,
      );
      final notifier = PomodoroNotifier(api);
      await notifier.init();
      expect(notifier.currentStreak, 3);
      expect(notifier.longestStreak, 7);
      expect(notifier.todaySessions, 2);
      expect(notifier.isCapped, false);
      notifier.dispose();
    });

    test('sets isCapped when todaySessions >= 8', () async {
      final api = FakePomodoroApiService();
      api.streakResult = PomodoroSessionResult(
        currentStreak: 5,
        longestStreak: 10,
        todaySessions: 8,
        todayMinutes: 200,
      );
      final notifier = PomodoroNotifier(api);
      await notifier.init();
      expect(notifier.isCapped, true);
      notifier.dispose();
    });

    test('does not crash if API throws', () async {
      final api = FakePomodoroApiService();
      api.shouldThrowOnComplete = false;
      // make getStreak throw
      final notifier = PomodoroNotifier(_ThrowingApiService());
      await notifier.init(); // must not throw
      expect(notifier.currentStreak, 0);
      notifier.dispose();
    });
  });

  group('start()', () {
    test('sets state to running', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      notifier.start();
      expect(notifier.state, TimerState.running);
      notifier.dispose();
    });

    test('does nothing when capped', () async {
      final api = FakePomodoroApiService();
      api.streakResult = PomodoroSessionResult(
        currentStreak: 0,
        longestStreak: 0,
        todaySessions: 8,
        todayMinutes: 200,
      );
      final notifier = PomodoroNotifier(api);
      await notifier.init();
      notifier.start();
      expect(notifier.state, TimerState.idle);
      notifier.dispose();
    });

    test('clears sessionError on start', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      // Manually poke error in (via reset + fake error state not possible directly,
      // so just verify the contract: after start() sessionError is null)
      notifier.start();
      expect(notifier.sessionError, isNull);
      notifier.dispose();
    });
  });

  group('pause()', () {
    test('sets state to paused', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      notifier.start();
      notifier.pause();
      expect(notifier.state, TimerState.paused);
      notifier.dispose();
    });
  });

  group('reset()', () {
    test('restores secondsNotifier and sets idle', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      notifier.start();
      notifier.secondsNotifier.value = 100;
      notifier.reset();
      expect(notifier.state, TimerState.idle);
      expect(notifier.secondsNotifier.value, 25 * 60);
      notifier.dispose();
    });
  });

  group('skipToNext()', () {
    test('Pomodoro -> Kratka pauza when cycleCount % 4 != 3', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      expect(notifier.cycleCount, 0); // 0 % 4 != 3
      notifier.skipToNext();
      expect(notifier.phase, 'Kratka pauza');
      expect(notifier.secondsNotifier.value, 5 * 60);
      expect(notifier.state, TimerState.idle);
      notifier.dispose();
    });

    test('Pomodoro -> Duga pauza when cycleCount % 4 == 3', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      // advance cycleCount to 3 by going through 3 short breaks
      notifier.skipToNext(); // Pomodoro(0) -> Kratka pauza
      notifier.skipToNext(); // Kratka pauza -> Pomodoro, cycleCount=1
      notifier.skipToNext(); // Pomodoro(1) -> Kratka pauza
      notifier.skipToNext(); // Kratka pauza -> Pomodoro, cycleCount=2
      notifier.skipToNext(); // Pomodoro(2) -> Kratka pauza
      notifier.skipToNext(); // Kratka pauza -> Pomodoro, cycleCount=3
      notifier.skipToNext(); // Pomodoro(3) -> Duga pauza (3 % 4 == 3)
      expect(notifier.phase, 'Duga pauza');
      expect(notifier.secondsNotifier.value, 15 * 60);
      notifier.dispose();
    });

    test('Kratka pauza -> Pomodoro increments cycleCount', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      notifier.skipToNext(); // Pomodoro -> Kratka pauza
      notifier.skipToNext(); // Kratka pauza -> Pomodoro
      expect(notifier.phase, 'Pomodoro');
      expect(notifier.cycleCount, 1);
      expect(notifier.secondsNotifier.value, 25 * 60);
      notifier.dispose();
    });

    test('Duga pauza -> Pomodoro resets cycleCount to 0', () {
      final notifier = PomodoroNotifier(FakePomodoroApiService());
      // Get to Duga pauza (cycleCount=3)
      for (int i = 0; i < 6; i++) notifier.skipToNext();
      notifier.skipToNext(); // Pomodoro(3) -> Duga pauza
      expect(notifier.phase, 'Duga pauza');
      notifier.skipToNext(); // Duga pauza -> Pomodoro
      expect(notifier.phase, 'Pomodoro');
      expect(notifier.cycleCount, 0);
      notifier.dispose();
    });
  });

  group('optimistic session update on timer end', () {
    test('increments todaySessions optimistically then confirms from API', () async {
      final api = FakePomodoroApiService();
      api.completeResult = PomodoroSessionResult(
        currentStreak: 1,
        longestStreak: 1,
        todaySessions: 1,
        todayMinutes: 25,
        capped: false,
      );
      final notifier = PomodoroNotifier(api);
      await notifier.init();
      expect(notifier.todaySessions, 0);

      // Drive the timer to zero manually
      notifier.start();
      notifier.secondsNotifier.value = 1;
      // simulate 1 tick
      await notifier.testTick();

      await Future.delayed(Duration.zero); // let async complete
      expect(notifier.todaySessions, 1);
      expect(notifier.phase, 'Kratka pauza'); // advanced after completion
      expect(notifier.sessionError, isNull);
      notifier.dispose();
    });

    test('reverts todaySessions and sets error when API fails', () async {
      final api = FakePomodoroApiService();
      api.shouldThrowOnComplete = true;
      final notifier = PomodoroNotifier(api);
      await notifier.init();

      notifier.start();
      notifier.secondsNotifier.value = 1;
      await notifier.testTick();
      await Future.delayed(Duration.zero);

      expect(notifier.todaySessions, 0); // reverted
      expect(notifier.sessionError, isNotNull);
      expect(notifier.state, TimerState.idle); // back to idle
      expect(notifier.phase, 'Pomodoro'); // did NOT advance
      notifier.dispose();
    });
  });
}

class _ThrowingApiService extends PomodoroApiService {
  _ThrowingApiService() : super('http://fake');

  @override
  Future<PomodoroSessionResult> getStreak() async {
    throw Exception('network error');
  }
}
```

> **Note on `testTick()`:** The notifier needs a `testTick()` method for deterministic testing (drives one tick without relying on `Timer.periodic`). This is added in the implementation step below.

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test test/pomodoro_notifier_test.dart
```

Expected: FAIL — `pomodoro_notifier.dart` not found.

- [ ] **Step 3: Create `lib/pages/PomodoroTimer/pomodoro_notifier.dart`**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:odlikas_ekran/database/api/pomodoro_api_service.dart';

enum TimerState { idle, running, paused }

class PomodoroNotifier extends ChangeNotifier {
  final PomodoroApiService _api;

  String _phase = 'Pomodoro';
  TimerState _state = TimerState.idle;
  int _cycleCount = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _todaySessions = 0;
  int _todayMinutes = 0;
  bool _isCapped = false;
  String? _sessionError;

  late final ValueNotifier<int> secondsNotifier;
  Timer? _ticker;

  static const int _dailyCap = 8;

  String get phase => _phase;
  TimerState get state => _state;
  int get cycleCount => _cycleCount;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get todaySessions => _todaySessions;
  int get todayMinutes => _todayMinutes;
  bool get isCapped => _isCapped;
  String? get sessionError => _sessionError;

  PomodoroNotifier(this._api) {
    secondsNotifier = ValueNotifier<int>(_durationFor('Pomodoro'));
  }

  int _durationFor(String phase) {
    if (phase == 'Pomodoro') return 25 * 60;
    if (phase == 'Kratka pauza') return 5 * 60;
    return 15 * 60;
  }

  Future<void> init() async {
    try {
      final result = await _api.getStreak();
      _currentStreak = result.currentStreak;
      _longestStreak = result.longestStreak;
      _todaySessions = result.todaySessions;
      _todayMinutes = result.todayMinutes;
      _isCapped = _todaySessions >= _dailyCap;
      notifyListeners();
    } catch (_) {
      // start with defaults — don't crash on network failure
    }
  }

  void start() {
    if (_isCapped || _state == TimerState.running) return;
    _sessionError = null;
    _state = TimerState.running;
    notifyListeners();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _ticker?.cancel();
    _ticker = null;
    _state = TimerState.paused;
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    secondsNotifier.value = _durationFor(_phase);
    _state = TimerState.idle;
    notifyListeners();
  }

  void skipToNext() {
    _ticker?.cancel();
    _ticker = null;
    _advancePhase();
  }

  // Exposed for deterministic unit tests only — not part of public API.
  @visibleForTesting
  Future<void> testTick() => _tick();

  Future<void> _tick() async {
    secondsNotifier.value--;
    if (secondsNotifier.value <= 0) {
      _ticker?.cancel();
      _ticker = null;
      await _onTimerEnd();
    }
  }

  Future<void> _onTimerEnd() async {
    if (_phase == 'Pomodoro') {
      _todaySessions++;
      notifyListeners();

      try {
        final result = await _api.completeSession();
        _currentStreak = result.currentStreak;
        _longestStreak = result.longestStreak;
        _todaySessions = result.todaySessions;
        _todayMinutes = result.todayMinutes;
        _isCapped = result.capped ?? (_todaySessions >= _dailyCap);
        notifyListeners();
      } catch (e) {
        _todaySessions--;
        _sessionError = e.toString();
        _state = TimerState.idle;
        notifyListeners();
        return;
      }
    }
    _advancePhase();
  }

  void _advancePhase() {
    String nextPhase;

    if (_phase == 'Pomodoro') {
      nextPhase = _cycleCount % 4 == 3 ? 'Duga pauza' : 'Kratka pauza';
    } else if (_phase == 'Kratka pauza') {
      nextPhase = 'Pomodoro';
      _cycleCount++;
    } else {
      nextPhase = 'Pomodoro';
      _cycleCount = 0;
    }

    _phase = nextPhase;
    secondsNotifier.value = _durationFor(nextPhase);
    _state = TimerState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    secondsNotifier.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/pomodoro_notifier_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/pages/PomodoroTimer/pomodoro_notifier.dart test/pomodoro_notifier_test.dart
git commit -m "feat: add PomodoroNotifier with full timer state machine"
```

---

## Task 3: Register PomodoroNotifier in main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add the import at the top of `lib/main.dart`**

After the existing imports, add:

```dart
import 'package:odlikas_ekran/database/api/pomodoro_api_service.dart';
import 'package:odlikas_ekran/pages/PomodoroTimer/pomodoro_notifier.dart';
```

- [ ] **Step 2: Add the provider to MultiProvider in `lib/main.dart`**

In `MyApp.build()`, inside the `providers: [...]` list in `MultiProvider`, add after the last existing `ChangeNotifierProxyProvider`:

```dart
ChangeNotifierProvider<PomodoroNotifier>(
  create: (_) => PomodoroNotifier(
    PomodoroApiService(dotenv.env['API_BASE_URL']!),
  ),
),
```

The full providers list should now be:

```dart
providers: [
  Provider<ApiService>(
    create: (_) => ApiService(dotenv.env['API_BASE_URL']!),
  ),
  ChangeNotifierProxyProvider<ApiService, HomePageViewModel>(
    create: (context) => HomePageViewModel(context.read<ApiService>()),
    update: (_, apiService, previous) => HomePageViewModel(apiService),
  ),
  ChangeNotifierProxyProvider<ApiService, TestViewmodel>(
    create: (context) => TestViewmodel(context.read<ApiService>()),
    update: (_, apiService, previous) => TestViewmodel(apiService),
  ),
  ChangeNotifierProvider<PomodoroNotifier>(
    create: (_) => PomodoroNotifier(
      PomodoroApiService(dotenv.env['API_BASE_URL']!),
    ),
  ),
],
```

- [ ] **Step 3: Verify the app compiles**

```bash
flutter analyze lib/main.dart
```

Expected: No errors (warnings about unused imports are OK if any).

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: register PomodoroNotifier provider in app root"
```

---

## Task 4: SessionCircles Widget

**Files:**
- Create: `lib/pages/PomodoroTimer/widgets/session_circles.dart`

- [ ] **Step 1: Create `lib/pages/PomodoroTimer/widgets/session_circles.dart`**

This replaces `VerticalProgressCircles` for the Pomodoro page. Shows 8 fixed circles (daily cap), filling from the top as sessions complete.

```dart
import 'package:flutter/material.dart';

class SessionCircles extends StatelessWidget {
  final int todaySessions;
  final Color color;

  const SessionCircles({
    super.key,
    required this.todaySessions,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(8, (index) {
          final filled = index < todaySessions;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: _SessionCirclePainter(filled: filled),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SessionCirclePainter extends CustomPainter {
  final bool filled;

  const _SessionCirclePainter({required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..color = Colors.white
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_SessionCirclePainter old) => old.filled != filled;
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/pages/PomodoroTimer/widgets/session_circles.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/pages/PomodoroTimer/widgets/session_circles.dart
git commit -m "feat: add SessionCircles widget (8 daily session circles)"
```

---

## Task 5: Rewrite PomodoroTimerPage

**Files:**
- Rewrite: `lib/pages/PomodoroTimer/pomodoro_timer_page.dart`

- [ ] **Step 1: Replace the entire content of `lib/pages/PomodoroTimer/pomodoro_timer_page.dart`**

Remove all Firestore imports and logic. The page is now a thin `Consumer<PomodoroNotifier>` wrapper. Keep the existing `PomodoroContainer` (unchanged) and the title/back-button layout.

```dart
import 'dart:async';
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
                      currentDuration: Duration(
                          seconds: notifier.secondsNotifier.value),
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
```

- [ ] **Step 2: Verify the app compiles with no errors**

```bash
flutter analyze lib/pages/PomodoroTimer/
```

Expected: No errors. (If `FirestorePomodoroService` import warnings appear in other files, ignore — the file itself is not deleted, only the import is removed from this page.)

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/pages/PomodoroTimer/pomodoro_timer_page.dart
git commit -m "feat: rewrite PomodoroTimerPage to use PomodoroNotifier (API-based, removes Firestore)"
```

---

## Self-Review

**Spec coverage:**
- ✅ `GET /api/Pomodoro/GetStreak` — `PomodoroApiService.getStreak()` (Task 1)
- ✅ `POST /api/Pomodoro/CompleteSession` — `PomodoroApiService.completeSession()` (Task 1)
- ✅ `PomodoroSessionResult` with both factory constructors — Task 1
- ✅ `(json['x'] as num?)?.toInt() ?? 0` pattern — used in all int fields (Task 1)
- ✅ Daily cap of 8 sessions — `_dailyCap = 8`, checked in `init()` and after `completeSession()` (Task 2)
- ✅ `ValueNotifier<int>` for countdown — `secondsNotifier` in `PomodoroNotifier` (Task 2)
- ✅ Phase durations: 25/5/15 min — `_durationFor()` (Task 2)
- ✅ Phase cycling (cycleCount % 4 == 3 → Duga pauza) — `_advancePhase()` (Task 2)
- ✅ cycleCount increments only after Kratka pauza — confirmed in `_advancePhase()` (Task 2)
- ✅ States: idle/running/paused — `TimerState` enum (Task 2)
- ✅ `start()` checks isCapped first — first line of `start()` (Task 2)
- ✅ Optimistic increment of todaySessions on Pomodoro end — `_onTimerEnd()` (Task 2)
- ✅ Revert on error + set sessionError + idle + do NOT advance phase — `_onTimerEnd()` catch block (Task 2)
- ✅ `pause()` cancels ticker — `pause()` (Task 2)
- ✅ `reset()` restores secondsNotifier + idle — `reset()` (Task 2)
- ✅ `skipToNext()` no API call — `skipToNext()` (Task 2)
- ✅ No `notifyListeners()` in ticker — ticker calls `_tick()` which only mutates `secondsNotifier.value` directly (Task 2)
- ✅ Bearer token from Hive `user_credentials` box — `_headers()` in Task 1
- ✅ Provider registered above page (app root MultiProvider) — Task 3
- ✅ `notifier.init()` via `addPostFrameCallback` in `initState` — Task 5
- ✅ `Consumer<PomodoroNotifier>` wraps only the page — Task 5
- ✅ `ValueListenableBuilder` wrapping countdown text — already in existing `PomodoroContainer` (unchanged)
- ✅ Session circles (8 total, filled = completed) — `SessionCircles` widget (Task 4)
- ✅ Error message if `sessionError != null` — shown in page UI (Task 5)
- ✅ Capped banner when daily cap reached — shown in page UI (Task 5)

**Placeholder scan:** No TBDs, no TODOs, no vague requirements — all steps contain complete code.

**Type consistency:**
- `PomodoroSessionResult` defined in Task 1, used identically in Task 2
- `TimerState` enum defined in Task 2, referenced in Task 5 as `TimerState.running`
- `PomodoroNotifier` getters (`phase`, `state`, `cycleCount`, `todaySessions`, etc.) defined in Task 2, consumed in Task 5
- `secondsNotifier` (ValueNotifier<int>) defined in Task 2, passed to `PomodoroContainer.secondsNotifier` in Task 5 ✅
- `PomodoroApiService` constructor `(String baseUrl)` matches usage in Task 3
