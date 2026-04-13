import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'firmware_update_vm_state.dart';

const String _firmwareUpdateFolderName = 'firmware-updates';
const String _firmwareUpdateSnapshotKey = 'firmware_update.snapshot.v1';

class FirmwareUpdateViewModel extends Cubit<FirmwareUpdateViewModelState> {
  final FusionDeviceService fusionDeviceService;

  StreamSubscription<FileTransferState>? _downloadSubscription;
  StreamSubscription<FileTransferState>? _uploadSubscription;
  StreamSubscription<ResponseCallback<FirmwareUpdateProgressEvent>>? _firmwareInstallSocketSubscription;

  final TransferManagerCubit downloadManager = serviceLocator<TransferManagerCubit>();
  String? _persistedBundleId;
  String? _activeUploadTaskId;

  FirmwareUpdateViewModel(this.fusionDeviceService) : super(const FirmwareUpdateViewModelState());

  String? get vip => serviceLocator<ProjectViewModel>().virtualIP;
  String? get bundleId => state.updateCheckResult?.bundleId ?? _persistedBundleId;

  void initialize() => unawaited(_initializeInternal());

  Future<void> _initializeInternal() async {
    if (vip?.isEmpty ?? true) {
      _emitIfOpen(
        state.copyWith(
          uiState: FirmwareUpdateUiState.noUpdate,
          errorShortText: _shortError('Target device is not configured.'),
          errorText: 'Target device is not configured.',
        ),
      );
      return;
    }

    await getFusionNetworkDevice();
    await _restoreStateFromSnapshot();
    if (await _restoreInstallableStateFromSnapshot()) return;
    await checkNewFirmwareUpdates();
  }

  Future<void> getFusionNetworkDevice() async {
    try {
      final ResponseCallback<List<FusionNetworkDevice>> response = await fusionDeviceService.getAvailableDevicesOnNetwork(ip: vip!);
      emit(state.copyWith(networkDevices: response.data ?? <FusionNetworkDevice>[]));
    } catch (e) {
      emit(state.copyWith(networkDevices: <FusionNetworkDevice>[]));
    }
  }

  Future<void> checkNewFirmwareUpdates() async {
    final FirmwareUpdateUiState current = state.uiState;
    if (current == FirmwareUpdateUiState.downloading || current == FirmwareUpdateUiState.installing) return;

    _emitIfOpen(state.copyWith(uiState: FirmwareUpdateUiState.checking, errorShortText: '', errorText: ''));

    try {
      final FirmwareUpdateCheckResult updateCheckResult = await checkForUpdates();
      _persistedBundleId = (updateCheckResult.bundleId ?? '').trim().isEmpty ? null : (updateCheckResult.bundleId ?? '').trim();

      final String updateAvailableVersion = _normalizedSemver(updateCheckResult.version ?? '');
      final _PersistedFirmwareUpdateSnapshot snapshot = await _loadFirmwareSnapshot();
      final String downloadedBundlePath = await _cachedBundlePathFromSnapshot(snapshot);
      final String downloadedBundleVersion = snapshot.availableVersion;

      bool hasValidDownloadedBundle = false;
      if (downloadedBundlePath.isNotEmpty) {
        hasValidDownloadedBundle = await File(downloadedBundlePath).exists();
      }

      // If the persisted path no longer exists on disk, clear the stale record.
      if (downloadedBundlePath.isNotEmpty && !hasValidDownloadedBundle) {
        await _clearDownloadedBundlePath();
      }

      FirmwareUpdateUiState nextUiState = FirmwareUpdateUiState.updateAvailable;
      String nextErrorText = '';
      String nextDownloadedPath = downloadedBundlePath;
      double nextProgress = 0;

      if (!updateCheckResult.updateAvailable || updateAvailableVersion == '0.0.0') {
        if (hasValidDownloadedBundle) {
          await _deleteCachedBundleIfExists(downloadedBundlePath);
          await _clearDownloadedBundlePath();
        }
        nextUiState = FirmwareUpdateUiState.noUpdate;
        nextDownloadedPath = '';
      } else if (updateCheckResult.appUpdateRequired) {
        nextUiState = FirmwareUpdateUiState.appUpdateRequired;
        nextErrorText = 'Launcher update required (min ${updateCheckResult.minDesktopAppVersion ?? 'unknown'}).';
      } else if (primaryFusionDeviceVersion == updateAvailableVersion) {
        // Already on the latest version — no need to keep a downloaded bundle.
        if (hasValidDownloadedBundle) {
          await _deleteCachedBundleIfExists(downloadedBundlePath);
          await _clearDownloadedBundlePath();
        }
        nextUiState = FirmwareUpdateUiState.installed;
        nextDownloadedPath = '';
        nextProgress = 1;
      } else if (hasValidDownloadedBundle) {
        // Use the persisted version tag (reliable) rather than filename parsing.
        final bool cachedVersionMatches = downloadedBundleVersion.isNotEmpty && _normalizedSemver(downloadedBundleVersion) == updateAvailableVersion;

        if (cachedVersionMatches) {
          nextUiState = FirmwareUpdateUiState.downloaded;
          nextProgress = 1;
        } else {
          // Cached bundle is for a different version — discard it.
          await _deleteCachedBundleIfExists(downloadedBundlePath);
          await _clearDownloadedBundlePath();
          nextUiState = FirmwareUpdateUiState.updateAvailable;
          nextDownloadedPath = '';
        }
      }

      _emitIfOpen(
        state.copyWith(
          uiState: nextUiState,
          errorShortText: _shortError(nextErrorText),
          errorText: nextErrorText,
          updateCheckResult: updateCheckResult,
          inUseVersion: primaryFusionDeviceVersion,
          availableVersion: updateAvailableVersion,
          downloadedFilePath: nextDownloadedPath,
          progress: nextProgress,
          installTrackingCompleted: nextUiState == FirmwareUpdateUiState.installed,
        ),
      );
    } catch (e) {
      _emitIfOpen(
        state.copyWith(
          uiState: FirmwareUpdateUiState.noUpdate,
          errorShortText: _shortError('Failed to check firmware updates: $e'),
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

  Future<FirmwareUpdateCheckResult> checkForUpdates() async {
    final ResponseCallback<FirmwareUpdateCheckResult> response = await fusionDeviceService.checkForFirmwareUpdates(
      currentFirmwareVersion: primaryFusionDeviceVersion,
      currentDesktopAppVersion: (await PackageInfo.fromPlatform()).version,
      jenkinsBuildNumber: primaryFusionDevicejenkinsBuildNumber,
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

  Future<BundleDownloadUrlResult> getDownloadUrl({required String version}) async {
    final ResponseCallback<BundleDownloadUrlResult> response = await fusionDeviceService.requestFirmwareBundleDownloadUrl(version: version);
    if (!response.success || response.data == null) {
      throw Exception(response.message.isEmpty ? 'Failed to fetch firmware download URL.' : response.message);
    }
    return response.data!;
  }

  void _setDownloadFailed(String errorText) {
    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloadFailed,
        errorShortText: _shortError(errorText),
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
        errorShortText: '',
        errorText: '',
      ),
    );
  }

  void _setDownloadProgress(double progress) => _emitIfOpen(state.copyWith(progress: progress.clamp(0, 1)));

  void _setInstallProgress(double progress) => _emitIfOpen(state.copyWith(progress: progress.clamp(0, 1)));

  void _markInstallUploadCompleted() => _emitIfOpen(state.copyWith(isUploadInProgress: false));

  Future<void> _setDownloaded({required BundleDownloadUrlResult metadata, required String filePath}) async {
    await _persistDownloadedBundleMetadata(metadata);
    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloaded,
        progress: 1,
        errorShortText: '',
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
        errorShortText: _shortError(errorText),
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
      _emitIfOpen(state.copyWith(uiState: FirmwareUpdateUiState.downloading));

      final String version = state.updateCheckResult?.version?.trim() ?? '';

      final BundleDownloadUrlResult bundleDownloadUrlResult = await getDownloadUrl(version: version);
      await _persistDownloadedBundleMetadata(bundleDownloadUrlResult);
      final String savePath = await getFirmwareBundleDownloadSavePath(bundleDownloadUrlResult.downloadFileName);

      await _deleteCachedBundleIfExists(savePath);

      _emitIfOpen(
        state.copyWith(
          uiState: FirmwareUpdateUiState.downloading,
          bundleDownloadUrlResult: bundleDownloadUrlResult,
          downloadedFilePath: savePath,
          progress: 0,
          errorShortText: '',
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
    final _PersistedBundleMetadata? persistedMetadata = await _loadDownloadedBundleMetadata();

    await _downloadSubscription?.cancel();
    _downloadSubscription = null;

    final String downloadTaskId = (metadata?.downloadUrl ?? persistedMetadata?.downloadUrl ?? '').trim();
    if (downloadTaskId.isNotEmpty) {
      downloadManager.cancel(downloadTaskId);
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

    final BundleDownloadUrlResult? metadata = state.bundleDownloadUrlResult;
    final _PersistedBundleMetadata? persistedMetadata = await _loadDownloadedBundleMetadata();

    final String resolvedDownloadUrl = (metadata?.downloadUrl ?? persistedMetadata?.downloadUrl ?? '').trim();
    final String resolvedDownloadFileName = (metadata?.downloadFileName ?? persistedMetadata?.downloadFileName ?? '').trim();
    final String resolvedChecksum = (metadata?.checksum ?? persistedMetadata?.checksum ?? '').trim();

    if (resolvedDownloadUrl.isEmpty || resolvedDownloadFileName.isEmpty || resolvedChecksum.isEmpty) {
      _setInstallFailed('No firmware metadata available. Re-download and try again.');
      return;
    }

    final String bundleFilePath =
        state.downloadedFilePath.trim().isNotEmpty ? state.downloadedFilePath.trim() : await getFirmwareBundleDownloadSavePath(resolvedDownloadFileName);

    if (!await File(bundleFilePath).exists()) {
      await _clearDownloadedBundlePath();
      _setInstallFailed('No downloaded bundle available for installation.');
      return;
    }

    final String host = targetVip.contains(':') ? targetVip : '$targetVip:8080';
    final String apiUrl = 'http://$host/softwareUpdate/upload';

    await _uploadSubscription?.cancel();
    _uploadSubscription = null;
    await _cancelActiveUploadTask();

    // Fetch and pre-populate all available network devices before starting install
    final List<FusionNetworkDevice> availableDevices = state.networkDevices;
    final List<FirmwareInstallDeviceProgress> initialDeviceProgress =
        availableDevices.map((FusionNetworkDevice device) {
          return FirmwareInstallDeviceProgress(
            serialNumber: device.serialNumber,
            node: device.modelName,
            updateState: 'PENDING',
            currentStep: 0,
            totalSteps: 0,
            currentTask: 'Waiting for update to start',
            stepProgress: 0,
            timestamp: DateTime.now().toIso8601String(),
          );
        }).toList();

    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.installing,
        errorShortText: '',
        errorText: '',
        progress: 0,
        isUploadInProgress: true,
        isSocketTrackingInProgress: false,
        installTrackingCompleted: false,
        deviceInstallProgress: initialDeviceProgress,
      ),
    );

    try {
      final String uploadTaskId = '${_uploadTaskId(resolvedDownloadUrl)}-${DateTime.now().microsecondsSinceEpoch}';
      _activeUploadTaskId = uploadTaskId;

      final FileUploadCubit task = downloadManager.enqueueUpload(
        id: uploadTaskId,
        apiUrl: apiUrl,
        data: FormData.fromMap(
          <String, dynamic>{
            'checksum': resolvedChecksum,
            'bundle': await MultipartFile.fromFile(
              bundleFilePath,
              filename: path.basename(bundleFilePath),
            ),
          },
        ),
      );

      _uploadSubscription = task.stream.listen(
        (FileTransferState fileUploadState) {
          log("FileTransferState == ${fileUploadState.progress}");

          if (fileUploadState.status == TransferStatus.inProgress) {
            _setInstallProgress(fileUploadState.progress);
            return;
          }

          if (fileUploadState.status == TransferStatus.completed) {
            _markInstallUploadCompleted();
            _listenToSoftwareInstallationProgress();
            return;
          }

          if (fileUploadState.status == TransferStatus.failed) {
            _setInstallFailed('Upload failed. Please try again.');
          }
        },
        onError: (Object error) {
          log("FM file upload error: $error");
          _setInstallFailed('Upload error: $error');
        },
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
    final _PersistedBundleMetadata? persistedMetadata = await _loadDownloadedBundleMetadata();
    await _uploadSubscription?.cancel();
    _uploadSubscription = null;
    await _cancelActiveUploadTask();
    final String uploadTaskId = _uploadTaskId((metadata?.downloadUrl ?? persistedMetadata?.downloadUrl ?? '').trim());
    if (uploadTaskId.isNotEmpty) {
      downloadManager.cancel(uploadTaskId);
    }

    final String downloadedPath = state.downloadedFilePath.trim();
    final bool hasDownloadedBundle = downloadedPath.isNotEmpty && await File(downloadedPath).exists();

    _emitIfOpen(
      state.copyWith(
        uiState: hasDownloadedBundle ? FirmwareUpdateUiState.downloaded : FirmwareUpdateUiState.updateAvailable,
        progress: hasDownloadedBundle ? 1 : 0,
        errorShortText: '',
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

  String get primaryFusionDeviceVersion {
    final List<FusionNetworkDevice> fustionNetworkDevices = state.networkDevices;
    final FusionNetworkDevice? primaryDevice = fustionNetworkDevices.firstWhereOrNull((FusionNetworkDevice? d) => d?.isPrimary == true);
    return primaryDevice?.softwareUpdateVersion ?? '';
  }

  String get primaryFusionDevicejenkinsBuildNumber {
    final List<FusionNetworkDevice> fustionNetworkDevices = state.networkDevices;
    final FusionNetworkDevice? primaryDevice = fustionNetworkDevices.firstWhereOrNull((FusionNetworkDevice? d) => d?.isPrimary == true);
    return primaryDevice?.jenkinsBuildNumber ?? '';
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

          log("FW update : ${event.status}");

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

          if (completed && !completer.isCompleted) completer.complete();
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

      final bool allCompleted = state.deviceInstallProgress.every((FirmwareInstallDeviceProgress e) => e.isCompleted);

      if (allCompleted) {
        // Installation successful - delete the downloaded bundle file but keep metadata for rollback
        final String bundlePathToDelete = state.downloadedFilePath.trim();
        if (bundlePathToDelete.isNotEmpty) {
          await _deleteCachedBundleIfExists(bundlePathToDelete);
        }
      }

      _emitIfOpen(
        state.copyWith(
          uiState: FirmwareUpdateUiState.installed,
          progress: 1,
          errorText: '',
          errorShortText: '',
          installTrackingCompleted: true,
          isSocketTrackingInProgress: false,
          inUseVersion: state.availableVersion, // Update in-use version to the newly installed version
          downloadedFilePath: '', // Clear the file path since we deleted the bundle
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
    // await fusionDeviceService.disconnectFirmwareUpdateWebSocket();
  }

  void _emitIfOpen(FirmwareUpdateViewModelState nextState) {
    if (!isClosed) {
      emit(nextState);
      unawaited(_persistUiStateSnapshot(nextState));
    }
  }

  String _uploadTaskId(String downloadUrl) {
    if (downloadUrl.trim().isEmpty) return '';
    return 'firmware-upload-$downloadUrl';
  }

  Future<void> _cancelActiveUploadTask() async {
    final String activeTaskId = (_activeUploadTaskId ?? '').trim();
    if (activeTaskId.isNotEmpty) {
      downloadManager.cancel(activeTaskId);
      _activeUploadTaskId = null;
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  Future<void> _restoreStateFromSnapshot() async {
    final _PersistedFirmwareUpdateSnapshot snapshot = await _loadFirmwareSnapshot();

    _persistedBundleId = snapshot.bundleId.isEmpty ? null : snapshot.bundleId;

    if (snapshot.availableVersion.isEmpty) return;
    _emitIfOpen(state.copyWith(availableVersion: snapshot.availableVersion));
  }

  Future<bool> _restoreInstallableStateFromSnapshot() async {
    final _PersistedFirmwareUpdateSnapshot snapshot = await _loadFirmwareSnapshot();
    final _PersistedBundleMetadata? metadata = await _loadDownloadedBundleMetadata();
    if (metadata == null) return false;

    final String bundlePath = await _cachedBundlePathFromSnapshot(snapshot);
    if (bundlePath.isEmpty) return false;

    final bool fileExists = await File(bundlePath).exists();
    if (!fileExists) {
      await _clearDownloadedBundlePath();
      return false;
    }

    _emitIfOpen(
      state.copyWith(
        uiState: FirmwareUpdateUiState.downloaded,
        downloadedFilePath: bundlePath,
        availableVersion: snapshot.availableVersion,
        progress: 1,
        errorShortText: '',
        errorText: '',
      ),
    );

    return true;
  }

  Future<void> _persistUiStateSnapshot(FirmwareUpdateViewModelState nextState) async {
    final _PersistedFirmwareUpdateSnapshot currentSnapshot = await _loadFirmwareSnapshot();
    final BundleDownloadUrlResult? metadata = nextState.bundleDownloadUrlResult;

    final _PersistedFirmwareUpdateSnapshot updatedSnapshot = currentSnapshot.copyWith(
      availableVersion: nextState.availableVersion.isNotEmpty ? nextState.availableVersion : currentSnapshot.availableVersion,
      bundleId: (bundleId ?? currentSnapshot.bundleId).trim(),
      downloadUrl: metadata?.downloadUrl,
      downloadFileName: metadata?.downloadFileName,
      checksum: metadata?.checksum,
    );

    await _saveFirmwareSnapshot(updatedSnapshot);
  }

  Future<_PersistedFirmwareUpdateSnapshot> _loadFirmwareSnapshot() async {
    final SharedPreferences prefs = await _getPrefs();
    final String rawJson = (prefs.getString(_firmwareUpdateSnapshotKey) ?? '').trim();
    if (rawJson.isEmpty) return const _PersistedFirmwareUpdateSnapshot();

    try {
      final dynamic decodedRaw = jsonDecode(rawJson);
      if (decodedRaw is! Map) return const _PersistedFirmwareUpdateSnapshot();

      final Map<dynamic, dynamic> decodedMap = decodedRaw;
      final Map<String, dynamic> decoded = decodedMap.map(
        (dynamic key, dynamic value) {
          return MapEntry<String, dynamic>(
            key.toString(),
            value,
          );
        },
      );
      return _PersistedFirmwareUpdateSnapshot.fromMap(decoded);
    } catch (_) {
      return const _PersistedFirmwareUpdateSnapshot();
    }
  }

  Future<void> _saveFirmwareSnapshot(_PersistedFirmwareUpdateSnapshot snapshot) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString(_firmwareUpdateSnapshotKey, jsonEncode(snapshot.toMap()));
  }

  Future<void> _clearDownloadedBundlePath() async {
    final _PersistedFirmwareUpdateSnapshot snapshot = await _loadFirmwareSnapshot();
    await _saveFirmwareSnapshot(
      snapshot.copyWith(
        downloadUrl: '',
        downloadFileName: '',
        checksum: '',
      ),
    );
  }

  Future<void> _persistDownloadedBundleMetadata(BundleDownloadUrlResult metadata) async {
    final _PersistedFirmwareUpdateSnapshot snapshot = await _loadFirmwareSnapshot();
    await _saveFirmwareSnapshot(
      snapshot.copyWith(
        bundleId: (bundleId ?? snapshot.bundleId).trim(),
        availableVersion: state.availableVersion.isNotEmpty ? state.availableVersion : snapshot.availableVersion,
        downloadUrl: metadata.downloadUrl,
        downloadFileName: metadata.downloadFileName,
        checksum: metadata.checksum,
      ),
    );
  }

  Future<String> _cachedBundlePathFromSnapshot(_PersistedFirmwareUpdateSnapshot snapshot) async {
    final String fileName = snapshot.downloadFileName.trim();
    if (fileName.isEmpty) return '';
    return getFirmwareBundleDownloadSavePath(fileName);
  }

  Future<_PersistedBundleMetadata?> _loadDownloadedBundleMetadata() async {
    final _PersistedFirmwareUpdateSnapshot snapshot = await _loadFirmwareSnapshot();
    final String downloadUrl = snapshot.downloadUrl.trim();
    final String downloadFileName = snapshot.downloadFileName.trim();
    final String checksum = snapshot.checksum.trim();

    if (downloadUrl.isEmpty || downloadFileName.isEmpty || checksum.isEmpty) {
      return null;
    }

    return _PersistedBundleMetadata(
      downloadUrl: downloadUrl,
      downloadFileName: downloadFileName,
      checksum: checksum,
    );
  }

  String _shortError(String message) {
    final String normalized = message.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return '';
    if (normalized.length <= 100) return normalized;
    return '${normalized.substring(0, 97)}...';
  }

  @override
  Future<void> close() async {
    await _downloadSubscription?.cancel();
    await _uploadSubscription?.cancel();
    await _cancelActiveUploadTask();
    await cancelSoftwareUpdateProgressListening();
    return super.close();
  }
}

class _PersistedFirmwareUpdateSnapshot {
  final String availableVersion;
  final String downloadUrl;
  final String downloadFileName;
  final String checksum;
  final String bundleId;

  const _PersistedFirmwareUpdateSnapshot({
    this.availableVersion = '',
    this.downloadUrl = '',
    this.downloadFileName = '',
    this.checksum = '',
    this.bundleId = '',
  });

  _PersistedFirmwareUpdateSnapshot copyWith({
    String? availableVersion,
    String? downloadUrl,
    String? downloadFileName,
    String? checksum,
    String? bundleId,
  }) {
    return _PersistedFirmwareUpdateSnapshot(
      availableVersion: availableVersion ?? this.availableVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadFileName: downloadFileName ?? this.downloadFileName,
      checksum: checksum ?? this.checksum,
      bundleId: bundleId ?? this.bundleId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'available_version': availableVersion,
      'download_url': downloadUrl,
      'download_file_name': downloadFileName,
      'checksum': checksum,
      'bundle_id': bundleId,
    };
  }

  factory _PersistedFirmwareUpdateSnapshot.fromMap(Map<String, dynamic> map) {
    return _PersistedFirmwareUpdateSnapshot(
      availableVersion: (map['available_version'] ?? '').toString(),
      downloadUrl: (map['download_url'] ?? '').toString(),
      downloadFileName: (map['download_file_name'] ?? '').toString(),
      checksum: (map['checksum'] ?? '').toString(),
      bundleId: (map['bundle_id'] ?? '').toString(),
    );
  }
}

class _PersistedBundleMetadata {
  final String downloadUrl;
  final String downloadFileName;
  final String checksum;

  const _PersistedBundleMetadata({
    required this.downloadUrl,
    required this.downloadFileName,
    required this.checksum,
  });
}
