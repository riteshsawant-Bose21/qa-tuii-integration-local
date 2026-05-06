import 'dart:async';

class AudioUtils {
  /// Convert UI volume (0.0-1.0) to dB gain (-60 to +12) for server communication.
  double percentageToDbfs(double percentage) {
    const double minDb = -60.0;
    const double maxDb = 12.0;

    final double clamped = percentage.clamp(0.0, 100.0);
    return minDb + (clamped / 100.0) * (maxDb - minDb);
  }

  /// Converts a dBFS value (-60 to 12) to a percentage value (0–100)
  double dbfsToPercentage(double dbfs) {
    const double minDb = -60.0;
    const double maxDb = 12.0;

    final double clamped = dbfs.clamp(minDb, maxDb);
    return ((clamped - minDb) / (maxDb - minDb)) * 100.0;
  }
}



class Throttler {
  final int milliseconds;
  Timer? _timer;
  Function? _pendingAction;

  Throttler({required this.milliseconds});

  void run(Function action) {
    if (_timer == null) {
      action();
      _timer = Timer(Duration(milliseconds: milliseconds), () {
        _timer = null;
        if (_pendingAction != null) {
          run(_pendingAction!);
          _pendingAction = null;
        }
      });
    } else {
      _pendingAction = action;
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
