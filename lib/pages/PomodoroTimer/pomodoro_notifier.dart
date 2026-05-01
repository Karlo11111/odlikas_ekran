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
