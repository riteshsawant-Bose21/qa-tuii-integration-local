import 'dart:async';

class AudioUtils {
  /// Convert UI volume (0.0-1.0) to dB gain (-60 to +12) for server communication.
  static double volumeToDbGain(double volume) {
    volume = volume.clamp(0.0, 1.0);
    return -60.0 + (volume * 72.0);
  }

  /// Convert dB gain (-60 to +12) from server back to UI volume (0.0-1.0).
  static double dbGainToVolume(double dbGain) {
    dbGain = dbGain.clamp(-60.0, 12.0);
    return (dbGain + 60.0) / 72.0;
  }

  /// Scales a 0.0-1.0 volume to 0-100 for UI display.
  static double toUiVolume(double dbGain) {
    return dbGainToVolume(dbGain) * 100.0;
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
