import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'firmware_update_vm_state.dart';

class FirmwareUpdateViewModel extends Cubit<FirmwareUpdateViewModelState> {
  final FusionDeviceService fusionDeviceService;
  StreamSubscription<ResponseCallback<FirmwareUpdateProgressEvent>>? _firmwareInstallSocketSubscription;
  bool _socketTrackingCancelledByUser = false;

  FirmwareUpdateViewModel(this.fusionDeviceService) : super(const FirmwareUpdateViewModelState());

  void setChecking() => emit(state.copyWith(uiState: FirmwareUpdateUiState.checking, errorText: ''));
  void setDesktopVersion(String version) => emit(state.copyWith(desktopVersion: normalizedSemver(version)));
  void setDownloadProgress(double progress) => emit(state.copyWith(progress: progress.clamp(0, 1)));
  void setDownloadCancelled() {
    emit(
      state.copyWith(
        uiState: FirmwareUpdateUiState.updateAvailable,
        progress: 0,
        downloadedFilePath: '',
        downloadChecksum: '',
        errorText: '',
      ),
    );
  }

  void setDownloadFailed(String errorText) {
    emit(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloadFailed,
        errorText: errorText,
        downloadedFilePath: '',
        downloadChecksum: '',
        progress: 0,
      ),
    );
  }

  void setInstallProgress(double progress) => emit(state.copyWith(progress: progress.clamp(0, 1)));
  void setInstallFailed(String errorText) => emit(state.copyWith(uiState: FirmwareUpdateUiState.installFailed, errorText: errorText));
  void toggleProgressExpanded() => emit(state.copyWith(isProgressExpanded: !state.isProgressExpanded));

  void setInUseVersion(String version) => emit(state.copyWith(inUseVersion: version));

  Future<String> fetchDeviceVersion({required String vip}) async {
    final ResponseCallback<List<FusionNetworkDevice>> response = await fusionDeviceService.getAvailableDevicesOnNetwork(ip: vip);
    if (response.success && response.data != null && response.data!.isNotEmpty) {
      final FusionNetworkDevice? primaryDevice = response.data!.cast<FusionNetworkDevice?>().firstWhere(
        (FusionNetworkDevice? d) => d?.isPrimary == true,
        orElse: () => null,
      );
      return primaryDevice?.softwareUpdateVersion ?? '';
    }
    return '';
  }

  void hydrateLocalState(FirmwareLocalState restored) {
    emit(
      state.copyWith(
        inUseVersion: restored.inUseVersion,
        availableVersion: restored.availableVersion,
        downloadChecksum: restored.downloadChecksum,
        downloadedFilePath: restored.downloadedFilePath,
      ),
    );
  }

  void applyCheckDecision(FirmwareCheckDecision decision) {
    emit(
      state.copyWith(
        uiState: _mapDecisionState(decision.state),
        availableVersion: decision.availableVersion,
        bundleId: decision.bundleId,
        releaseNotes: decision.releaseNotes,
        errorText: decision.errorText,
        downloadedFilePath: decision.clearDownloadedCache ? '' : state.downloadedFilePath,
        downloadChecksum: decision.clearDownloadedCache ? '' : state.downloadChecksum,
      ),
    );
  }

  void setDownloadStarted() {
    emit(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloading,
        progress: 0,
        errorText: '',
      ),
    );
  }

  void setDownloaded({required String filePath, required String checksum}) {
    emit(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloaded,
        downloadedFilePath: filePath,
        downloadChecksum: checksum,
        progress: 1,
      ),
    );
  }

  void setInstallStarted() {
    emit(
      state.copyWith(
        uiState: FirmwareUpdateUiState.installing,
        progress: 0,
        errorText: '',
        isProgressExpanded: false,
        deviceInstallProgress: const <FirmwareInstallDeviceProgress>[],
        installTrackingCompleted: false,
        isUploadInProgress: true,
        isSocketTrackingInProgress: false,
      ),
    );
  }

  void markInstallUploadCompleted() {
    emit(
      state.copyWith(
        isUploadInProgress: false,
        isSocketTrackingInProgress: true,
      ),
    );
  }

  void setInstalledSuccess() {
    emit(
      state.copyWith(
        uiState: FirmwareUpdateUiState.installed,
        inUseVersion: state.availableVersion,
        downloadedFilePath: '',
        downloadChecksum: '',
        progress: 1,
        installTrackingCompleted: true,
        isUploadInProgress: false,
        isSocketTrackingInProgress: false,
      ),
    );
  }

  void setInstallCancelled({String message = 'Install cancelled by user.'}) {
    emit(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloaded,
        errorText: message,
        isUploadInProgress: false,
        isSocketTrackingInProgress: false,
      ),
    );
  }

  void rollbackToDownloadedOrAvailable() {
    final bool hasDownloadedFile = state.downloadedFilePath.isNotEmpty && File(state.downloadedFilePath).existsSync();
    emit(
      state.copyWith(
        uiState: hasDownloadedFile ? FirmwareUpdateUiState.downloaded : FirmwareUpdateUiState.updateAvailable,
        errorText: '',
      ),
    );
  }

  FirmwareUpdateUiState _mapDecisionState(FirmwareCheckDecisionState decisionState) {
    switch (decisionState) {
      case FirmwareCheckDecisionState.noUpdate:
        return FirmwareUpdateUiState.noUpdate;
      case FirmwareCheckDecisionState.appUpdateRequired:
        return FirmwareUpdateUiState.appUpdateRequired;
      case FirmwareCheckDecisionState.updateAvailable:
        return FirmwareUpdateUiState.updateAvailable;
      case FirmwareCheckDecisionState.downloaded:
        return FirmwareUpdateUiState.downloaded;
      case FirmwareCheckDecisionState.installed:
        return FirmwareUpdateUiState.installed;
      case FirmwareCheckDecisionState.failed:
        return FirmwareUpdateUiState.downloadFailed;
    }
  }

  String normalizedSemver(String version) {
    final String trimmed = version.trim();
    if (trimmed.isEmpty) return '0.0.0';
    final String withoutPrefix = trimmed.startsWith('v') || trimmed.startsWith('V') ? trimmed.substring(1) : trimmed;
    return withoutPrefix.isEmpty ? '0.0.0' : withoutPrefix;
  }

  String? deriveChannel({required String inUseVersion}) {
    final String envChannel = AppConfig.firmwareUpdateChannel.trim();
    if (envChannel.isNotEmpty) {
      return envChannel;
    }

    final RegExpMatch? preReleaseMatch = RegExp(r'^\d+\.\d+\.\d+\-([0-9A-Za-z]+)').firstMatch(inUseVersion);
    final String? fromVersion = preReleaseMatch?.group(1)?.trim();
    if (fromVersion != null && fromVersion.isNotEmpty) return fromVersion;

    return null;
  }

  Future<String> loadDesktopVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return normalizedSemver(info.version);
    } catch (_) {
      return '0.0.0';
    }
  }

  FirmwareLocalState restoreLocalState({
    required String? rawState,
    required String fallbackInUseVersion,
  }) {
    if (rawState == null || rawState.isEmpty) {
      return FirmwareLocalState(
        inUseVersion: fallbackInUseVersion,
        availableVersion: '',
        downloadChecksum: '',
        downloadedFilePath: '',
      );
    }

    try {
      final Map<String, dynamic> json = jsonDecode(rawState) as Map<String, dynamic>;
      final String restoredPath = json['downloaded_file_path'] as String? ?? '';
      final String validPath = restoredPath.isNotEmpty && !File(restoredPath).existsSync() ? '' : restoredPath;

      return FirmwareLocalState(
        inUseVersion: fallbackInUseVersion,
        availableVersion: normalizedSemver(json['available_version'] as String? ?? ''),
        downloadChecksum: json['download_checksum'] as String? ?? '',
        downloadedFilePath: validPath,
      );
    } catch (_) {
      return FirmwareLocalState(
        inUseVersion: fallbackInUseVersion,
        availableVersion: '',
        downloadChecksum: '',
        downloadedFilePath: '',
      );
    }
  }

  String serializeLocalState({
    required String availableVersion,
    required String downloadChecksum,
    required String downloadedFilePath,
  }) {
    return jsonEncode(
      <String, dynamic>{
        'available_version': availableVersion,
        'download_checksum': downloadChecksum,
        'downloaded_file_path': downloadedFilePath,
      },
    );
  }

  Future<Directory> updatesDirectory() async {
    final Directory supportDir = await getApplicationSupportDirectory();
    final Directory updatesDir = Directory(p.join(supportDir.path, 'firmware-updates'));
    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }
    return updatesDir;
  }

  Future<FirmwareCheckDecision> checkForUpdatesDecision({
    required String inUseVersion,
    required String desktopVersion,
    required String downloadedFilePath,
    required String localAvailableVersion,
  }) async {
    final String normalizedInUseVersion = normalizedSemver(inUseVersion);
    final String normalizedLocalAvailableVersion = normalizedSemver(localAvailableVersion);
    final FirmwareUpdateCheckResult result = await checkForUpdates(
      currentFirmwareVersion: normalizedInUseVersion,
      desktopVersion: desktopVersion,
      channel: deriveChannel(inUseVersion: normalizedInUseVersion),
    );

    final bool hasCachedBundlePath = downloadedFilePath.trim().isNotEmpty;

    if (result.appUpdateRequired) {
      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.appUpdateRequired,
        errorText: 'Launcher update required (min ${result.minDesktopAppVersion ?? 'unknown'}).',
      );
    }

    final String nextVersion = normalizedSemver(result.version ?? '');
    final String bundleId = (result.bundleId ?? '').trim();

    if (!result.updateAvailable || nextVersion == '0.0.0') {
      if (hasCachedBundlePath) await _deleteCachedBundleIfExists(downloadedFilePath);

      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.noUpdate,
        clearDownloadedCache: hasCachedBundlePath,
      );
    }

    if (bundleId.isEmpty) {
      return const FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.failed,
        errorText: 'Update is available but bundle_id is missing in response.',
      );
    }

    if (normalizedInUseVersion == nextVersion) {
      if (hasCachedBundlePath) {
        await _deleteCachedBundleIfExists(downloadedFilePath);
      }
      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.installed,
        availableVersion: nextVersion,
        bundleId: bundleId,
        releaseNotes: result.releaseNotes ?? '',
        clearDownloadedCache: hasCachedBundlePath,
      );
    }

    if (hasCachedBundlePath) {
      final bool cachedBundleExists = await File(downloadedFilePath).exists();
      if (!cachedBundleExists) {
        return FirmwareCheckDecision(
          state: FirmwareCheckDecisionState.updateAvailable,
          availableVersion: nextVersion,
          bundleId: bundleId,
          releaseNotes: result.releaseNotes ?? '',
          clearDownloadedCache: true,
        );
      }

      final bool isCachedBundleMatchingCurrentCloudVersion = normalizedLocalAvailableVersion == nextVersion;
      if (!isCachedBundleMatchingCurrentCloudVersion) {
        await _deleteCachedBundleIfExists(downloadedFilePath);
        return FirmwareCheckDecision(
          state: FirmwareCheckDecisionState.updateAvailable,
          availableVersion: nextVersion,
          bundleId: bundleId,
          releaseNotes: result.releaseNotes ?? '',
          clearDownloadedCache: true,
        );
      }

      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.downloaded,
        availableVersion: nextVersion,
        bundleId: bundleId,
        releaseNotes: result.releaseNotes ?? '',
      );
    }

    return FirmwareCheckDecision(
      state: FirmwareCheckDecisionState.updateAvailable,
      availableVersion: nextVersion,
      bundleId: bundleId,
      releaseNotes: result.releaseNotes ?? '',
    );
  }

  Future<void> _deleteCachedBundleIfExists(String downloadedFilePath) async {
    if (downloadedFilePath.trim().isEmpty) {
      return;
    }

    try {
      final File cachedBundleFile = File(downloadedFilePath);
      if (await cachedBundleFile.exists()) {
        await cachedBundleFile.delete();
      }
    } catch (_) {
      // Non-fatal: check flow continues and state is still cleared.
    }
  }

  Future<FirmwareUpdateCheckResult> checkForUpdates({
    required String currentFirmwareVersion,
    required String desktopVersion,
    String? channel,
  }) async {
    final ResponseCallback<FirmwareUpdateCheckResult> response = await fusionDeviceService.checkForFirmwareUpdates(
      currentFirmwareVersion: currentFirmwareVersion,
      currentDesktopAppVersion: desktopVersion,
      channel: channel,
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }

    return response.data!;
  }

  Future<BundleDownloadUrlResult> getDownloadUrl({required String bundleId}) async {
    final ResponseCallback<BundleDownloadUrlResult> response = await fusionDeviceService.requestFirmwareBundleDownloadUrl(bundleId: bundleId);
    if (!response.success || response.data == null) throw Exception(response.message);
    return response.data!;
  }

  Future<void> logInstallStatus({
    required String projectId,
    required String bundleVersion,
    required String previousVersion,
    required String launcherVersion,
    required String status,
  }) async {
    final ResponseCallback<void> response = await fusionDeviceService.logFirmwareUpdateStatus(
      projectId: projectId,
      bundleVersion: bundleVersion,
      previousVersion: previousVersion,
      launcherVersion: launcherVersion,
      status: status,
    );

    if (!response.success) {
      throw Exception(response.message);
    }
  }

  Future<void> downloadBundle({
    required String downloadUrl,
    required String targetFilePath,
    required CancelToken cancelToken,
    required void Function(int received, int total) onProgress,
  }) async {
    final ResponseCallback<void> response = await fusionDeviceService.downloadFirmwareBundle(
      downloadUrl: downloadUrl,
      targetFilePath: targetFilePath,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );

    if (!response.success) throw Exception(response.message);
  }

  Future<void> uploadToFusionServer({
    required String vip,
    required String bundleFilePath,
    required String checksum,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    final ResponseCallback<void> response = await fusionDeviceService.uploadFirmwareBundleToFusionServer(
      vip: vip,
      bundleFilePath: bundleFilePath,
      checksum: checksum,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );

    log("uploadToFusionServer :: ${response.success} == ${response.message}");

    if (!response.success) throw Exception(response.message);
  }

  Future<void> trackFirmwareInstallProgress({required String vip}) async {
    _socketTrackingCancelledByUser = false;
    await stopFirmwareInstallProgressTracking();

    final ResponseCallback<void> connectResponse = await fusionDeviceService.connectFirmwareUpdateWebSocket(vip: vip);
    if (!connectResponse.success) {
      throw Exception(connectResponse.message);
    }

    final ResponseCallback<void> startResponse = await fusionDeviceService.sendStartFirmwareUpdateEvent();

    log("WEB SOCKET CONNECTION ::: ${startResponse.success}");
    if (!startResponse.success) {
      await fusionDeviceService.disconnectFirmwareUpdateWebSocket();
      throw Exception(startResponse.message);
    }

    final Completer<void> completer = Completer<void>();

    _firmwareInstallSocketSubscription = fusionDeviceService.firmwareUpdateProgressEvents().listen(
      (ResponseCallback<FirmwareUpdateProgressEvent> response) {
        if (!response.success || response.data == null) return;

        final FirmwareUpdateProgressEvent event = response.data!;
        if (event.devicesBySerial.isEmpty) return;

        final Map<String, FirmwareInstallDeviceProgress> mergedBySerial = <String, FirmwareInstallDeviceProgress>{
          for (final FirmwareInstallDeviceProgress item in state.deviceInstallProgress) item.serialNumber: item,
        };

        for (final MapEntry<String, FirmwareUpdateDeviceProgress> entry in event.devicesBySerial.entries) {
          final FirmwareUpdateDeviceProgress device = entry.value;
          final String serial = device.serialNumber.trim().isNotEmpty ? device.serialNumber.trim() : entry.key;
          final ({int current, int total}) step = _parseStep(device.step);

          mergedBySerial[serial] = FirmwareInstallDeviceProgress(
            serialNumber: serial,
            node: device.node,
            updateState: device.updateState,
            currentStep: step.current,
            totalSteps: step.total,
            currentTask: device.currentTask,
            stepProgress: device.progress.clamp(0, 100),
            timestamp: device.timestamp,
          );
        }

        final List<FirmwareInstallDeviceProgress> mergedProgress =
            mergedBySerial.values.toList()..sort(
              (FirmwareInstallDeviceProgress a, FirmwareInstallDeviceProgress b) => a.serialNumber.compareTo(
                b.serialNumber,
              ),
            );

        final bool completed = mergedProgress.isNotEmpty && mergedProgress.every((FirmwareInstallDeviceProgress item) => item.isCompleted);

        emit(
          state.copyWith(
            deviceInstallProgress: mergedProgress,
            progress: completed ? 1 : _computeOverallInstallProgress(mergedProgress),
            installTrackingCompleted: completed,
          ),
        );

        if (completed && !completer.isCompleted) completer.complete();
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Firmware install websocket error: $error'));
        }
      },
      onDone: () {
        if (_socketTrackingCancelledByUser) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('socket-progress-cancelled-by-user'));
          }
          return;
        }

        if (!completer.isCompleted && !state.installTrackingCompleted) {
          completer.completeError(Exception('Firmware install websocket closed before completion.'));
        }
      },
    );

    try {
      await completer.future;
    } finally {
      await stopFirmwareInstallProgressTracking();
    }
  }

  Future<void> stopFirmwareInstallProgressTracking() async {
    await _firmwareInstallSocketSubscription?.cancel();
    _firmwareInstallSocketSubscription = null;
    await fusionDeviceService.disconnectFirmwareUpdateWebSocket();
  }

  Future<void> cancelSocketProgressTrackingByUser() async {
    _socketTrackingCancelledByUser = true;
    await stopFirmwareInstallProgressTracking();
    emit(
      state.copyWith(
        isSocketTrackingInProgress: false,
        isUploadInProgress: false,
      ),
    );
  }

  ({int current, int total}) _parseStep(String rawStep) {
    final List<String> parts = rawStep.split('/');
    if (parts.length != 2) return (current: 0, total: 0);
    final int current = int.tryParse(parts.first.trim()) ?? 0;
    final int total = int.tryParse(parts.last.trim()) ?? 0;
    return (current: current, total: total);
  }

  double _computeOverallInstallProgress(List<FirmwareInstallDeviceProgress> devices) {
    if (devices.isEmpty) return 0;

    double total = 0;
    for (final FirmwareInstallDeviceProgress device in devices) {
      final int safeCurrent = device.currentStep.clamp(0, 1000);
      final int safeTotal = device.totalSteps.clamp(0, 1000);
      final double stepPart = device.stepProgress.clamp(0, 100) / 100;

      if (safeTotal > 0) {
        final double completedSteps = safeCurrent > 0 ? (safeCurrent - 1).toDouble() : 0;
        total += ((completedSteps + stepPart) / safeTotal).clamp(0, 1);
      } else {
        total += device.isCompleted ? 1 : stepPart;
      }
    }

    return (total / devices.length).clamp(0, 1);
  }

  @override
  Future<void> close() async {
    await stopFirmwareInstallProgressTracking();
    return super.close();
  }
}
