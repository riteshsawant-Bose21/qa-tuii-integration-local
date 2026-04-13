import 'package:equatable/equatable.dart';

/// Screen mode for the controller settings.
enum ScreenMode { light, dark }

extension ScreenModeX on ScreenMode {
  String get key => name;

  static ScreenMode fromKey(String key) {
    return ScreenMode.values.firstWhere(
      (ScreenMode m) => m.name == key,
      orElse: () => ScreenMode.dark,
    );
  }
}

/// Screen saver option for the controller settings.
enum ScreenSaverOption { dateAndTime, qrCode, homeScreen, blackScreen }

extension ScreenSaverOptionX on ScreenSaverOption {
  String get label {
    switch (this) {
      case ScreenSaverOption.dateAndTime:
        return 'Date and time';
      case ScreenSaverOption.qrCode:
        return 'QR Code';
      case ScreenSaverOption.homeScreen:
        return 'Home screen';
      case ScreenSaverOption.blackScreen:
        return 'Black screen';
    }
  }

  String get key => name;

  static ScreenSaverOption fromKey(String key) {
    return ScreenSaverOption.values.firstWhere(
      (ScreenSaverOption o) => o.name == key,
      orElse: () => ScreenSaverOption.qrCode,
    );
  }
}

/// State for the Settings tab panel.
sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - no data loaded yet.
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading state - fetching data.
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Loaded state - settings successfully loaded.
class SettingsLoaded extends SettingsState {
  /// Screen mode (light/dark).
  final ScreenMode screenMode;

  /// Screen saver option.
  final ScreenSaverOption screenSaver;

  /// Screen sleep time in seconds.
  final int sleepTime;

  /// The controller ID this state belongs to.
  final String? controllerId;

  const SettingsLoaded({
    this.screenMode = ScreenMode.dark,
    this.screenSaver = ScreenSaverOption.qrCode,
    this.sleepTime = 30,
    this.controllerId,
  });

  SettingsLoaded copyWith({
    ScreenMode? screenMode,
    ScreenSaverOption? screenSaver,
    int? sleepTime,
    Object? controllerId = _sentinel,
  }) {
    return SettingsLoaded(
      screenMode: screenMode ?? this.screenMode,
      screenSaver: screenSaver ?? this.screenSaver,
      sleepTime: sleepTime ?? this.sleepTime,
      controllerId: identical(controllerId, _sentinel) ? this.controllerId : controllerId as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[screenMode, screenSaver, sleepTime, controllerId];
}

/// Error state - failed to load data.
class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object?> get props => <Object?>[message];
}

/// Sentinel for nullable copyWith parameters.
const Object _sentinel = Object();
