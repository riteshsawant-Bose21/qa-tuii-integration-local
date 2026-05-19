import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'settings_state.dart';

/// ViewModel/Cubit for the Settings tab panel.
///
/// Manages display configuration (screen mode, saver, sleep time).
/// Loads and persists data using [ProjectViewModel] relationships.
class SettingsViewModel extends Cubit<SettingsState> {
  SettingsViewModel() : super(const SettingsInitial());

  /// Lazy reference to ProjectViewModel.
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();

  /// Get current loaded state, or null if not loaded.
  SettingsLoaded? get _loaded {
    final SettingsState s = state;
    return s is SettingsLoaded ? s : null;
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  /// Loads settings data for the specified controller.
  void loadData(String controllerId, {bool isProController = false, bool isVirtualController = false}) {
    emit(const SettingsLoading());

    try {
      final ControllerDisplayConfig config = _projectViewModel.getControllerDisplayConfig(controllerId);
      final List<Zone> zones = _projectViewModel.getAllZones();

      emit(
        SettingsLoaded(
          screenMode: ScreenModeX.fromKey(config.screenMode),
          screenSaver: ScreenSaverOptionX.fromKey(config.screenSaver),
          sleepTime: config.sleepTime,
          controllerId: controllerId,
          zones: zones,
          isPro: isProController,
          isVirtual: isVirtualController,
        ),
      );
    } catch (e) {
      FusionLogger.log(tag: LogTag.project, message: 'SettingsViewModel: failed to load data: $e');
      emit(SettingsError(message: 'Failed to load settings: $e'));
    }
  }

  /// Reloads data from persistence.
  void refresh() {
    final SettingsLoaded? loaded = _loaded;
    if (loaded?.controllerId != null) {
      loadData(loaded!.controllerId!);
    }
  }

  // ─── Settings Actions ──────────────────────────────────────────────────────

  /// Update screen mode and persist.
  void setScreenMode(ScreenMode mode) {
    final SettingsLoaded? loaded = _loaded;
    if (loaded == null) return;

    final SettingsLoaded next = loaded.copyWith(screenMode: mode);
    _persistConfig(next);
    emit(next);
  }

  /// Update screen saver option and persist.
  void setScreenSaver(ScreenSaverOption option) {
    final SettingsLoaded? loaded = _loaded;
    if (loaded == null) return;

    final SettingsLoaded next = loaded.copyWith(screenSaver: option);
    _persistConfig(next);
    emit(next);
  }

  /// Update screen sleep time and persist.
  void setSleepTime(int seconds) {
    final SettingsLoaded? loaded = _loaded;
    if (loaded == null) return;

    final SettingsLoaded next = loaded.copyWith(sleepTime: seconds);
    _persistConfig(next);
    emit(next);
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  /// Persists display configuration for the controller.
  void _persistConfig(SettingsLoaded state) {
    if (state.controllerId == null) return;

    _projectViewModel.setControllerDisplayConfig(
      controllerId: state.controllerId!,
      config: ControllerDisplayConfig(
        screenMode: state.screenMode.key,
        screenSaver: state.screenSaver.key,
        sleepTime: state.sleepTime,
      ),
    );
  }

  void setWakeFunction(WakeFunctionOption option) {
    final SettingsLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(wakeFunction: option, wakeZoneId: option == WakeFunctionOption.zone ? loaded.wakeZoneId : null));
  }

  void setWakeZone(String? zoneId) {
    final SettingsLoaded? loaded = _loaded;
    if (loaded == null) return;
    emit(loaded.copyWith(wakeFunction: WakeFunctionOption.zone, wakeZoneId: zoneId));
  }
}
