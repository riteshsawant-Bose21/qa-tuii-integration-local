import 'dart:convert';
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
    if (trimmed.isEmpty) {
      return '0.0.0';
    }
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
    if (fromVersion != null && fromVersion.isNotEmpty) {
      return fromVersion;
    }

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
        inUseVersion: normalizedSemver(json['in_use_version'] as String? ?? fallbackInUseVersion),
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
    required String inUseVersion,
    required String availableVersion,
    required String downloadChecksum,
    required String downloadedFilePath,
  }) {
    return jsonEncode(
      <String, dynamic>{
        'in_use_version': inUseVersion,
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

  String buildBundleTargetFilePath({required String directoryPath, required String availableVersion}) {
    final String safeVersion = availableVersion.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return p.join(directoryPath, 'bundle_$safeVersion.swu');
  }

  Future<FirmwareCheckDecision> checkForUpdatesDecision({
    required String inUseVersion,
    required String desktopVersion,
    required String downloadedFilePath,
  }) async {
    final String normalizedInUseVersion = normalizedSemver(inUseVersion);
    final FirmwareUpdateCheckResult result = await checkForUpdates(
      currentFirmwareVersion: normalizedInUseVersion,
      desktopVersion: desktopVersion,
      channel: deriveChannel(inUseVersion: normalizedInUseVersion),
    );

    if (result.appUpdateRequired) {
      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.appUpdateRequired,
        errorText: 'Launcher update required (min ${result.minDesktopAppVersion ?? 'unknown'}).',
      );
    }

    final String nextVersion = normalizedSemver(result.version ?? '');
    final String bundleId = (result.bundleId ?? '').trim();

    if (!result.updateAvailable || nextVersion == '0.0.0') {
      return const FirmwareCheckDecision(state: FirmwareCheckDecisionState.noUpdate);
    }

    if (bundleId.isEmpty) {
      return const FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.failed,
        errorText: 'Update is available but bundle_id is missing in response.',
      );
    }

    if (normalizedInUseVersion == nextVersion) {
      return FirmwareCheckDecision(
        state: FirmwareCheckDecisionState.installed,
        availableVersion: nextVersion,
        bundleId: bundleId,
        releaseNotes: result.releaseNotes ?? '',
      );
    }

    if (downloadedFilePath.isNotEmpty && File(downloadedFilePath).existsSync()) {
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

  Future<FirmwareUpdateCheckResult> checkForUpdates({required String currentFirmwareVersion, required String desktopVersion, String? channel}) async {
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

    if (!response.success) {
      throw Exception(response.message);
    }
  }
}
