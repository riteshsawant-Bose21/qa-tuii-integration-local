import 'package:equatable/equatable.dart';
import 'package:fusion_lib/fusion_lib.dart';

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

  /// Wake function option for the controller settings tab (per-controller).
  final WakeFunctionOption wakeFunction;

  /// Selected zone for wake function (if wakeFunction == zone).
  final String? wakeZoneId;

  final List<Zone> zones;

  /// Whether the controller is a Pro controller.
  final bool isPro;

  /// Whether the controller is a Virtual controller (Virtual Control Pal Pro or LT).
  final bool isVirtual;

  const SettingsLoaded({
    this.screenMode = ScreenMode.dark,
    this.screenSaver = ScreenSaverOption.qrCode,
    this.sleepTime = 30,
    this.controllerId,
    this.wakeFunction = WakeFunctionOption.lastScreen,
    this.wakeZoneId,
    this.zones = const <Zone>[],
    this.isPro = false,
    this.isVirtual = false,
  });

  SettingsLoaded copyWith({
    ScreenMode? screenMode,
    ScreenSaverOption? screenSaver,
    int? sleepTime,
    Object? controllerId = _sentinel,
    WakeFunctionOption? wakeFunction,
    String? wakeZoneId,
    List<Zone>? zones,
    bool? isPro,
    bool? isVirtual,
  }) {
    return SettingsLoaded(
      screenMode: screenMode ?? this.screenMode,
      screenSaver: screenSaver ?? this.screenSaver,
      sleepTime: sleepTime ?? this.sleepTime,
      controllerId: identical(controllerId, _sentinel) ? this.controllerId : controllerId as String?,
      wakeFunction: wakeFunction ?? this.wakeFunction,
      wakeZoneId: wakeZoneId ?? this.wakeZoneId,
      zones: zones ?? this.zones,
      isPro: isPro ?? this.isPro,
      isVirtual: isVirtual ?? this.isVirtual,
    );
  }

  @override
  List<Object?> get props => <Object?>[screenMode, screenSaver, sleepTime, controllerId, wakeFunction, wakeZoneId, zones, isPro, isVirtual];
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

// Wake function options for the controller settings tab.
enum WakeFunctionOption { lastScreen, homeScreen, zone }

extension WakeFunctionOptionLabel on WakeFunctionOption {
  String get label {
    switch (this) {
      case WakeFunctionOption.lastScreen:
        return 'Last screen visited';
      case WakeFunctionOption.homeScreen:
        return 'Home screen';
      case WakeFunctionOption.zone:
        return 'zone';
    }
  }
}
