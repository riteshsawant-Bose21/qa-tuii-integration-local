import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'firmware_update_vm_state.dart';

const String _firmwareUpdateFolderName = 'firmware-updates';
const String _downloadedBundlePathKey = 'firmware_update.downloaded_bundle_path';

class FirmwareUpdateViewModel extends Cubit<FirmwareUpdateViewModelState> {
  final FusionDeviceService fusionDeviceService;

  StreamSubscription<FileTransferState>? _downloadSubscription;
  StreamSubscription<FileTransferState>? _uploadSubscription;
  StreamSubscription<ResponseCallback<FirmwareUpdateProgressEvent>>? _firmwareInstallSocketSubscription;

  final TransferManagerCubit downloadManager = serviceLocator<TransferManagerCubit>();
  bool _isInitialized = false;

  FirmwareUpdateViewModel(this.fusionDeviceService) : super(const FirmwareUpdateViewModelState());

  String? get vip => serviceLocator<ProjectViewModel>().virtualIP;
  String? get bundleId => state.updateCheckResult?.bundleId;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    unawaited(checkNewFirmwareUpdates());
  }

  Future<void> checkNewFirmwareUpdates() async {
    final FirmwareUpdateUiState current = state.uiState;
    if (current == FirmwareUpdateUiState.downloading || current == FirmwareUpdateUiState.installing) return;

    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.checking,
        errorText: '',
      ),
    );

    try {
      final String desktopVersion = await loadDesktopVersion();
      final String targetVip = (vip ?? '').trim();

      if (targetVip.isEmpty) {
        _emitIfOpen(
          state.copyWith(
            uiState: FirmwareUpdateUiState.noUpdate,
            errorText: 'Target device is not configured.',
          ),
        );
        return;
      }

      final String currentVersion = _normalizedSemver(await getPrimaryFirmwareDeviceVersion());
      final String envChannel = AppConfig.firmwareUpdateChannel.trim();

      final FirmwareUpdateCheckResult updateCheckResult = await checkForUpdates(
        currentFirmwareVersion: currentVersion,
        desktopVersion: desktopVersion,
        channel: envChannel.isNotEmpty ? envChannel : null,
      );

      final String nextVersion = _normalizedSemver(updateCheckResult.version ?? '');
      final String downloadedBundlePath = await _loadDownloadedBundlePath();

      bool hasValidDownloadedBundle = false;
      if (downloadedBundlePath.isNotEmpty) {
        hasValidDownloadedBundle = await File(downloadedBundlePath).exists();
      }

      FirmwareUpdateUiState nextUiState = FirmwareUpdateUiState.updateAvailable;
      String nextErrorText = '';
      String nextDownloadedPath = downloadedBundlePath;
      double nextProgress = 0;

      if (!updateCheckResult.updateAvailable || nextVersion == '0.0.0') {
        if (hasValidDownloadedBundle) {
          await _deleteCachedBundleIfExists(downloadedBundlePath);
          await _clearDownloadedBundlePath();
        }
        nextUiState = FirmwareUpdateUiState.noUpdate;
        nextDownloadedPath = '';
      } else if (updateCheckResult.appUpdateRequired) {
        nextUiState = FirmwareUpdateUiState.appUpdateRequired;
        nextErrorText = 'Launcher update required (min ${updateCheckResult.minDesktopAppVersion ?? 'unknown'}).';
      } else if (currentVersion == nextVersion) {
        if (hasValidDownloadedBundle) {
          await _deleteCachedBundleIfExists(downloadedBundlePath);
          await _clearDownloadedBundlePath();
        }
        nextUiState = FirmwareUpdateUiState.installed;
        nextDownloadedPath = '';
        nextProgress = 1;
      } else if (hasValidDownloadedBundle) {
        final String localVersion = _normalizedSemver(path.basenameWithoutExtension(downloadedBundlePath));
        if (localVersion == nextVersion) {
          nextUiState = FirmwareUpdateUiState.downloaded;
          nextProgress = 1;
        } else {
          await _deleteCachedBundleIfExists(downloadedBundlePath);
          await _clearDownloadedBundlePath();
          nextUiState = FirmwareUpdateUiState.updateAvailable;
          nextDownloadedPath = '';
        }
      }

      _emitIfOpen(
        state.copyWith(
          uiState: nextUiState,
          errorText: nextErrorText,
          updateCheckResult: updateCheckResult,
          inUseVersion: currentVersion,
          availableVersion: nextVersion,
          downloadedFilePath: nextDownloadedPath,
          progress: nextProgress,
          installTrackingCompleted: nextUiState == FirmwareUpdateUiState.installed,
        ),
      );
    } catch (e) {
      _emitIfOpen(
        state.copyWith(
          uiState: FirmwareUpdateUiState.noUpdate,
          errorText: 'Failed to check firmware updates: $e',
        ),
      );
    }
  }

  String _normalizedSemver(String version) {
    final String trimmed = version.trim();
    if (trimmed.isEmpty) return '0.0.0';
    final String withoutPrefix = trimmed.startsWith('v') || trimmed.startsWith('V') ? trimmed.substring(1) : trimmed;
    return withoutPrefix.isEmpty ? '0.0.0' : withoutPrefix;
  }

  Future<String> loadDesktopVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return _normalizedSemver(info.version);
    } catch (_) {
      return '0.0.0';
    }
  }

  Future<FirmwareUpdateCheckResult> checkForUpdates({required String currentFirmwareVersion, required String desktopVersion, String? channel}) async {
    final ResponseCallback<FirmwareUpdateCheckResult> response = await fusionDeviceService.checkForFirmwareUpdates(
      currentFirmwareVersion: currentFirmwareVersion,
      currentDesktopAppVersion: desktopVersion,
      channel: channel,
    );

    if (!response.success || response.data == null) {
      throw Exception(response.message.isEmpty ? 'Firmware update check failed.' : response.message);
    }
    return response.data!;
  }

  Future<Directory> _getFirmwareUpdateDirectory() async {
    final Directory supportDir = await getApplicationSupportDirectory();
    final Directory updatesDir = Directory(path.join(supportDir.path, _firmwareUpdateFolderName));
    if (!await updatesDir.exists()) await updatesDir.create(recursive: true);
    return updatesDir;
  }

  Future<String> getFirmwareBundleDownloadSavePath(String fileName) async {
    final Directory firmwareUpdateDirectory = await _getFirmwareUpdateDirectory();
    return path.join(firmwareUpdateDirectory.path, fileName);
  }

  Future<BundleDownloadUrlResult> getDownloadUrl({required String bundleId}) async {
    final ResponseCallback<BundleDownloadUrlResult> response = await fusionDeviceService.requestFirmwareBundleDownloadUrl(bundleId: bundleId);
    if (!response.success || response.data == null) {
      throw Exception(response.message.isEmpty ? 'Failed to fetch firmware download URL.' : response.message);
    }
    return response.data!;
  }

  void _setDownloadFailed(String errorText) {
    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloadFailed,
        errorText: errorText,
        progress: 0,
      ),
    );
  }

  void _setDownloadCancelled() {
    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.updateAvailable,
        progress: 0,
        errorText: '',
      ),
    );
  }

  void _setDownloadProgress(double progress) => _emitIfOpen(state.copyWith(progress: progress.clamp(0, 1)));

  void _setInstallProgress(double progress) => _emitIfOpen(state.copyWith(progress: progress.clamp(0, 1)));

  void _markInstallUploadCompleted() => _emitIfOpen(state.copyWith(isUploadInProgress: false));

  Future<void> _setDownloaded({required BundleDownloadUrlResult metadata, required String filePath}) async {
    await _persistDownloadedBundlePath(filePath);
    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloaded,
        progress: 1,
        errorText: '',
        bundleDownloadUrlResult: metadata,
        downloadedFilePath: filePath,
      ),
    );
  }

  void _setInstallFailed(String errorText) {
    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.installFailed,
        errorText: errorText,
        isUploadInProgress: false,
        isSocketTrackingInProgress: false,
      ),
    );
  }

  Future<void> onDownloadTap() async {
    final String? currentBundleId = bundleId;
    if (currentBundleId == null || currentBundleId.trim().isEmpty) {
      _setDownloadFailed('Invalid bundle ID. Cannot download update.');
      return;
    }

    try {
      final BundleDownloadUrlResult bundleDownloadUrlResult = await getDownloadUrl(bundleId: currentBundleId);
      final String savePath = await getFirmwareBundleDownloadSavePath(bundleDownloadUrlResult.downloadFileName);

      await _deleteCachedBundleIfExists(savePath);

      _emitIfOpen(
        state.copyWith(
          uiState: FirmwareUpdateUiState.downloading,
          bundleDownloadUrlResult: bundleDownloadUrlResult,
          downloadedFilePath: savePath,
          progress: 0,
          errorText: '',
          installTrackingCompleted: false,
          deviceInstallProgress: const <FirmwareInstallDeviceProgress>[],
        ),
      );

      await _downloadSubscription?.cancel();

      final FileDownloadCubit task = downloadManager.enqueueDownload(
        downloadUrl: bundleDownloadUrlResult.downloadUrl,
        savePath: savePath,
        id: bundleDownloadUrlResult.downloadUrl,
      );

      _downloadSubscription = task.stream.listen(
        (FileTransferState fileDownloadState) {
          if (fileDownloadState.status == TransferStatus.inProgress) {
            _setDownloadProgress(fileDownloadState.progress);
            return;
          }

          if (fileDownloadState.status == TransferStatus.completed) {
            unawaited(_setDownloaded(metadata: bundleDownloadUrlResult, filePath: savePath));
            return;
          }

          if (fileDownloadState.status == TransferStatus.failed) {
            _setDownloadFailed('Download failed. Please try again.');
          }
        },
        onError: (Object error) => _setDownloadFailed('Download error: $error'),
      );
    } catch (e) {
      _setDownloadFailed('Download could not be started: $e');
    }
  }

  Future<void> cancelDownload() async {
    final BundleDownloadUrlResult? metadata = state.bundleDownloadUrlResult;

    await _downloadSubscription?.cancel();
    _downloadSubscription = null;

    if (metadata != null) {
      downloadManager.cancel(metadata.downloadUrl);
    }

    final String bundlePath = state.downloadedFilePath.trim();
    if (bundlePath.isNotEmpty) {
      await _deleteCachedBundleIfExists(bundlePath);
      await _clearDownloadedBundlePath();
    }

    _setDownloadCancelled();
  }

  Future<void> retryDownload() async {
    await cancelDownload();
    await onDownloadTap();
  }

  Future<void> installNow() async {
    final String targetVip = (vip ?? '').trim();
    if (targetVip.isEmpty) {
      _setInstallFailed('Virtual IP is not configured.');
      return;
    }

    BundleDownloadUrlResult? metadata = state.bundleDownloadUrlResult;
    final String? currentBundleId = bundleId;

    if (metadata == null && currentBundleId != null && currentBundleId.trim().isNotEmpty) {
      try {
        metadata = await getDownloadUrl(bundleId: currentBundleId);
        _emitIfOpen(state.copyWith(bundleDownloadUrlResult: metadata));
      } catch (e) {
        _setInstallFailed('Failed to fetch firmware metadata: $e');
        return;
      }
    }

    if (metadata == null) {
      _setInstallFailed('No firmware metadata available. Re-download and try again.');
      return;
    }

    final String bundleFilePath =
        state.downloadedFilePath.trim().isNotEmpty ? state.downloadedFilePath.trim() : await getFirmwareBundleDownloadSavePath(metadata.downloadFileName);

    if (!await File(bundleFilePath).exists()) {
      await _clearDownloadedBundlePath();
      _setInstallFailed('No downloaded bundle available for installation.');
      return;
    }

    final String host = targetVip.contains(':') ? targetVip : '$targetVip:8080';
    final String apiUrl = 'http://$host/softwareUpdate/upload';

    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.installing,
        errorText: '',
        progress: 0,
        isUploadInProgress: true,
        isSocketTrackingInProgress: false,
        installTrackingCompleted: false,
        deviceInstallProgress: const <FirmwareInstallDeviceProgress>[],
      ),
    );

    await _uploadSubscription?.cancel();

    try {
      final FileUploadCubit task = downloadManager.enqueueUpload(
        id: _uploadTaskId(metadata),
        apiUrl: apiUrl,
        data: FormData.fromMap(
          <String, dynamic>{
            'checksum': metadata.checksum,
            'bundle': await MultipartFile.fromFile(
              bundleFilePath,
              filename: path.basename(bundleFilePath),
            ),
          },
        ),
      );

      _uploadSubscription = task.stream.listen(
        (FileTransferState fileUploadState) {
          if (fileUploadState.status == TransferStatus.inProgress) {
            _setInstallProgress(fileUploadState.progress);
            return;
          }

          if (fileUploadState.status == TransferStatus.completed) {
            _markInstallUploadCompleted();
            unawaited(_listenToSoftwareInstallationProgress());
            return;
          }

          if (fileUploadState.status == TransferStatus.failed) {
            _setInstallFailed('Upload failed. Please try again.');
          }
        },
        onError: (Object error) => _setInstallFailed('Upload error: $error'),
      );
    } on DioException catch (e) {
      _setInstallFailed('Upload request failed: ${e.message ?? e.toString()}');
    } catch (e) {
      _setInstallFailed('Unexpected error during upload: $e');
    }
  }

  Future<void> retryInstall() async {
    await installNow();
  }

  Future<void> rollbackToDownloaded() async {
    await cancelSoftwareUpdateProgressListening();

    final BundleDownloadUrlResult? metadata = state.bundleDownloadUrlResult;
    if (metadata != null) {
      downloadManager.cancel(_uploadTaskId(metadata));
    }

    final String downloadedPath = state.downloadedFilePath.trim();
    final bool hasDownloadedBundle = downloadedPath.isNotEmpty && await File(downloadedPath).exists();

    _emitIfOpen(
      state.copyWith(
        uiState: hasDownloadedBundle ? FirmwareUpdateUiState.downloaded : FirmwareUpdateUiState.updateAvailable,
        progress: hasDownloadedBundle ? 1 : 0,
        errorText: '',
        isUploadInProgress: false,
        isSocketTrackingInProgress: false,
        installTrackingCompleted: false,
        deviceInstallProgress: const <FirmwareInstallDeviceProgress>[],
      ),
    );
  }

  void toggleProgressExpanded() {
    _emitIfOpen(state.copyWith(isProgressExpanded: !state.isProgressExpanded));
  }

  Future<String> getPrimaryFirmwareDeviceVersion() async {
    final String targetVip = (vip ?? '').trim();
    if (targetVip.isEmpty) return '';

    final ResponseCallback<List<FusionNetworkDevice>> response = await fusionDeviceService.getAvailableDevicesOnNetwork(ip: targetVip);

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      final FusionNetworkDevice? primaryDevice = response.data!.cast<FusionNetworkDevice?>().firstWhereOrNull((FusionNetworkDevice? d) => d?.isPrimary == true);
      return primaryDevice?.softwareUpdateVersion ?? '';
    }

    return '';
  }

  Future<FirmwareCheckDecision> checkForUpdatesDecision({
    required String inUseVersion,
    required String desktopVersion,
    required String downloadedFilePath,
  }) async {
    final String envChannel = AppConfig.firmwareUpdateChannel.trim();

    final FirmwareUpdateCheckResult result = await checkForUpdates(
      currentFirmwareVersion: inUseVersion,
      desktopVersion: desktopVersion,
      channel: envChannel.isNotEmpty ? envChannel : null,
    );

    final bool hasCachedBundlePath = downloadedFilePath.trim().isNotEmpty;

    if (result.appUpdateRequired) {
      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.appUpdateRequired,
        errorText: 'Launcher update required (min ${result.minDesktopAppVersion ?? 'unknown'}).',
      );
    }

    final String nextVersion = _normalizedSemver(result.version ?? '');
    final String nextBundleId = (result.bundleId ?? '').trim();

    if (!result.updateAvailable || nextVersion == '0.0.0') {
      if (hasCachedBundlePath) await _deleteCachedBundleIfExists(downloadedFilePath);

      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.noUpdate,
        clearDownloadedCache: hasCachedBundlePath,
      );
    }

    if (nextBundleId.isEmpty) {
      return const FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.failed,
        errorText: 'Update is available but bundle_id is missing in response.',
      );
    }

    if (_normalizedSemver(inUseVersion) == nextVersion) {
      if (hasCachedBundlePath) await _deleteCachedBundleIfExists(downloadedFilePath);

      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.installed,
        availableVersion: nextVersion,
        bundleId: nextBundleId,
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
          bundleId: nextBundleId,
          releaseNotes: result.releaseNotes ?? '',
          clearDownloadedCache: true,
        );
      }

      final String normalizedLocalAvailableVersion = _normalizedSemver(path.basenameWithoutExtension(downloadedFilePath));

      final bool isCachedBundleMatchingCurrentCloudVersion = normalizedLocalAvailableVersion == nextVersion;
      if (!isCachedBundleMatchingCurrentCloudVersion) {
        await _deleteCachedBundleIfExists(downloadedFilePath);
        return FirmwareCheckDecision(
          state: FirmwareCheckDecisionState.updateAvailable,
          availableVersion: nextVersion,
          bundleId: nextBundleId,
          releaseNotes: result.releaseNotes ?? '',
          clearDownloadedCache: true,
        );
      }

      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.downloaded,
        availableVersion: nextVersion,
        bundleId: nextBundleId,
        releaseNotes: result.releaseNotes ?? '',
      );
    }

    return FirmwareCheckDecision(
      state: FirmwareCheckDecisionState.updateAvailable,
      availableVersion: nextVersion,
      bundleId: nextBundleId,
      releaseNotes: result.releaseNotes ?? '',
    );
  }

  Future<void> _deleteCachedBundleIfExists(String downloadedFilePath) async {
    if (downloadedFilePath.trim().isEmpty) return;
    try {
      final File cachedBundleFile = File(downloadedFilePath);
      if (await cachedBundleFile.exists()) await cachedBundleFile.delete();
    } catch (_) {
      // Non-fatal: cache cleanup should not block state transitions.
    }
  }

  Future<void> _listenToSoftwareInstallationProgress() async {
    await Future<void>.delayed(const Duration(seconds: 3));

    final String targetVip = (vip ?? '').trim();
    final String targetBundleId = (bundleId ?? '').trim();

    if (targetVip.isEmpty || targetBundleId.isEmpty) {
      _setInstallFailed('Missing device IP or bundle ID for installation tracking.');
      return;
    }

    _emitIfOpen(state.copyWith(isSocketTrackingInProgress: true));

    final Completer<void> completer = Completer<void>();

    try {
      final ResponseCallback<void> connectResponse = await fusionDeviceService.connectFirmwareUpdateWebSocket(vip: targetVip);
      if (!connectResponse.success) {
        throw Exception(connectResponse.message.isEmpty ? 'Unable to connect firmware update websocket.' : connectResponse.message);
      }

      final ResponseCallback<void> startResponse = await fusionDeviceService.sendStartFirmwareUpdateEvent(bundleId: targetBundleId);
      if (!startResponse.success) {
        throw Exception(startResponse.message.isEmpty ? 'Failed to send start firmware update event.' : startResponse.message);
      }

      await _firmwareInstallSocketSubscription?.cancel();
      _firmwareInstallSocketSubscription = fusionDeviceService.listenFirmwareUpdateProgressEvents().listen(
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
              mergedBySerial.values.toList()
                ..sort((FirmwareInstallDeviceProgress a, FirmwareInstallDeviceProgress b) => a.serialNumber.compareTo(b.serialNumber));

          final bool failed = mergedProgress.any((FirmwareInstallDeviceProgress item) {
            final String normalized = item.updateState.toUpperCase();
            return normalized.contains('FAIL') || normalized.contains('ERROR') || normalized == 'CANCELLED';
          });

          final bool completed = mergedProgress.isNotEmpty && mergedProgress.every((FirmwareInstallDeviceProgress item) => item.isCompleted);

          _emitIfOpen(
            state.copyWith(
              deviceInstallProgress: mergedProgress,
              progress: completed ? 1 : _computeOverallInstallProgress(mergedProgress),
              installTrackingCompleted: completed,
            ),
          );

          if (failed && !completer.isCompleted) {
            completer.completeError(Exception('Device reported installation failure.'));
            return;
          }

          if (completed && !completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Firmware install websocket error: $error'));
          }
        },
        onDone: () {
          if (!completer.isCompleted && !state.installTrackingCompleted) {
            completer.completeError(Exception('Firmware install websocket closed before completion.'));
          }
        },
      );

      await completer.future;

      _emitIfOpen(
        state.copyWith(
          uiState: FirmwareUpdateUiState.installed,
          progress: 1,
          errorText: '',
          installTrackingCompleted: true,
          isSocketTrackingInProgress: false,
        ),
      );
    } catch (e) {
      _setInstallFailed('Installation failed: $e');
    } finally {
      await cancelSoftwareUpdateProgressListening();
      _emitIfOpen(state.copyWith(isSocketTrackingInProgress: false));
    }
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
      final int safeTotal = device.totalSteps.clamp(1, 1000);
      final double stepPart = device.stepProgress.clamp(0, 100) / 100;

      final double completedSteps = safeCurrent > 0 ? (safeCurrent - 1).toDouble() : 0;
      total += ((completedSteps + stepPart) / safeTotal).clamp(0, 1);
    }

    return (total / devices.length).clamp(0, 1);
  }

  Future<void> cancelSoftwareUpdateProgressListening() async {
    await _firmwareInstallSocketSubscription?.cancel();
    _firmwareInstallSocketSubscription = null;
    await fusionDeviceService.disconnectFirmwareUpdateWebSocket();
  }

  void _emitIfOpen(FirmwareUpdateViewModelState nextState) {
    if (!isClosed) emit(nextState);
  }

  String _uploadTaskId(BundleDownloadUrlResult metadata) => 'firmware-upload-${metadata.downloadUrl}';

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  Future<void> _persistDownloadedBundlePath(String filePath) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString(_downloadedBundlePathKey, filePath);
  }

  Future<String> _loadDownloadedBundlePath() async {
    final SharedPreferences prefs = await _getPrefs();
    return prefs.getString(_downloadedBundlePathKey) ?? '';
  }

  Future<void> _clearDownloadedBundlePath() async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.remove(_downloadedBundlePathKey);
  }

  @override
  Future<void> close() async {
    await _downloadSubscription?.cancel();
    await _uploadSubscription?.cancel();
    await cancelSoftwareUpdateProgressListening();
    return super.close();
  }
}
