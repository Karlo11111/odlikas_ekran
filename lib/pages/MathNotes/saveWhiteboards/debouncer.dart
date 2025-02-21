import 'dart:async';
import 'dart:ui';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel(); // Cancel any previous timer
    _timer = Timer(delay, action);
  }

  // New cancel method
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
