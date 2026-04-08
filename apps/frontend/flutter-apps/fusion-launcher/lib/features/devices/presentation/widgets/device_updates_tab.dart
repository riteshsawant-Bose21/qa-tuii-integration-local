import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/view_model/firmware_update/firmware_update_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceUpdatesTab extends StatefulWidget {
  const DeviceUpdatesTab({super.key});

  @override
  State<DeviceUpdatesTab> createState() => _DeviceUpdatesTabState();
}

class _DeviceUpdatesTabState extends State<DeviceUpdatesTab> {
  static const String _prefsKey = 'firmware_updates_state_v1';

  final FirmwareUpdateViewModel _firmwareUpdateViewModel = serviceLocator<FirmwareUpdateViewModel>();

  CancelToken? _downloadCancelToken;
  CancelToken? _installCancelToken;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _downloadCancelToken?.cancel();
    _installCancelToken?.cancel();
    _firmwareUpdateViewModel.stopFirmwareInstallProgressTracking();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadDesktopVersion();
    await _loadInUseVersionFromDevice();
    await _restoreState();
    await _checkForUpdates();
  }

  Future<void> _loadInUseVersionFromDevice() async {
    final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
    if (vip == null || vip.isEmpty) return;
    try {
      final String deviceVersion = await _firmwareUpdateViewModel.fetchDeviceVersion(vip: vip);
      if (deviceVersion.isNotEmpty) {
        _firmwareUpdateViewModel.setInUseVersion(deviceVersion);
      }
    } catch (_) {
      // Non-fatal: fall back to persisted or default version.
    }
  }

  Future<void> _loadDesktopVersion() async {
    final String desktopVersion = await _firmwareUpdateViewModel.loadDesktopVersion();
    _firmwareUpdateViewModel.setDesktopVersion(desktopVersion);
  }

  Future<void> _restoreState() async {
    final SharedPreferences prefs = serviceLocator<SharedPreferences>();
    final String? raw = prefs.getString(_prefsKey);
    final FirmwareLocalState restored = _firmwareUpdateViewModel.restoreLocalState(
      rawState: raw,
      fallbackInUseVersion: _firmwareUpdateViewModel.state.inUseVersion,
    );
    _firmwareUpdateViewModel.hydrateLocalState(restored);

    if (restored.downloadedFilePath.isNotEmpty) {
      debugPrint('Firmware bundle cached at: ${restored.downloadedFilePath}');
    }
  }

  Future<void> _persistState() async {
    final FirmwareUpdateViewModelState state = _firmwareUpdateViewModel.state;
    final SharedPreferences prefs = serviceLocator<SharedPreferences>();
    await prefs.setString(
      _prefsKey,
      _firmwareUpdateViewModel.serializeLocalState(
        availableVersion: state.availableVersion,
        downloadChecksum: state.downloadChecksum,
        downloadedFilePath: state.downloadedFilePath,
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    // Don't re-check while a download or install is actively in progress.
    // Re-initialization (tab reopen) must not overwrite an active operation.
    final FirmwareUpdateUiState current = _firmwareUpdateViewModel.state.uiState;
    if (current == FirmwareUpdateUiState.downloading || current == FirmwareUpdateUiState.installing) return;

    _firmwareUpdateViewModel.setChecking();

    try {
      final FirmwareUpdateViewModelState state = _firmwareUpdateViewModel.state;
      final FirmwareCheckDecision decision = await _firmwareUpdateViewModel.checkForUpdatesDecision(
        inUseVersion: state.inUseVersion,
        desktopVersion: state.desktopVersion,
        downloadedFilePath: state.downloadedFilePath,
        localAvailableVersion: state.availableVersion,
      );

      if (!mounted) return;

      _firmwareUpdateViewModel.applyCheckDecision(decision);
      await _persistState();
    } catch (e) {
      if (!mounted) return;
      _firmwareUpdateViewModel.setDownloadFailed('Failed to check updates: $e');
    }
  }

  Future<void> _downloadNow() async {
    if (_firmwareUpdateViewModel.state.bundleId.isEmpty) {
      _firmwareUpdateViewModel.setDownloadFailed('Bundle id is missing.');
      return;
    }

    _downloadCancelToken?.cancel();
    _downloadCancelToken = CancelToken();

    _firmwareUpdateViewModel.setDownloadStarted();

    try {
      final String bundleId = _firmwareUpdateViewModel.state.bundleId;
      final BundleDownloadUrlResult downloadInfo = await _firmwareUpdateViewModel.getDownloadUrl(bundleId: bundleId);
      if (downloadInfo.downloadUrl.isEmpty) {
        throw Exception('Cloud did not return a download URL.');
      }

      final Directory dir = await _firmwareUpdateViewModel.updatesDirectory();
      final Uri downloadUri = Uri.parse(downloadInfo.downloadUrl);
      final String originalFileName = downloadUri.pathSegments.isNotEmpty ? Uri.decodeComponent(downloadUri.pathSegments.last) : '';
      final String fallbackFileName = 'firmware_${_firmwareUpdateViewModel.state.availableVersion}.bundle';
      final String targetFilePath =
          originalFileName.trim().isEmpty
              ? File('${dir.path}${Platform.pathSeparator}$fallbackFileName').path
              : File('${dir.path}${Platform.pathSeparator}$originalFileName').path;

      await _firmwareUpdateViewModel.downloadBundle(
        downloadUrl: downloadInfo.downloadUrl,
        targetFilePath: targetFilePath,
        cancelToken: _downloadCancelToken!,
        onProgress: (int received, int total) {
          if (!mounted || total <= 0) {
            return;
          }
          _firmwareUpdateViewModel.setDownloadProgress(received / total);
        },
      );

      if (!mounted) {
        return;
      }

      _firmwareUpdateViewModel.setDownloaded(filePath: targetFilePath, checksum: downloadInfo.checksum);
      debugPrint('Firmware bundle downloaded at: $targetFilePath');
      await _persistState();
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      if (CancelToken.isCancel(e)) {
        _firmwareUpdateViewModel.setDownloadCancelled();
        return;
      }
      _firmwareUpdateViewModel.setDownloadFailed('Download failed. Please try again.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _firmwareUpdateViewModel.setDownloadFailed('Download failed: $e');
    }
  }

  Future<void> _installNow() async {
    final FirmwareUpdateViewModelState state = _firmwareUpdateViewModel.state;
    final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
    if (vip == null || vip.isEmpty) {
      _firmwareUpdateViewModel.setInstallFailed('Virtual IP is not configured.');
      return;
    }

    if (state.downloadedFilePath.isEmpty || !File(state.downloadedFilePath).existsSync()) {
      _firmwareUpdateViewModel.setInstallFailed('Downloaded file not found.');
      return;
    }

    _installCancelToken?.cancel();
    _installCancelToken = CancelToken();

    final String previousVersion = state.inUseVersion;
    final String installedBundlePath = state.downloadedFilePath;

    _firmwareUpdateViewModel.setInstallStarted();

    try {
      await _firmwareUpdateViewModel.uploadToFusionServer(
        vip: vip,
        bundleFilePath: state.downloadedFilePath,
        checksum: state.downloadChecksum,
        cancelToken: _installCancelToken!,
        onProgress: (int sent, int total) {
          if (!mounted || total <= 0) {
            return;
          }
          _firmwareUpdateViewModel.setInstallProgress(sent / total);
        },
      );

      if (!mounted) return;

      _firmwareUpdateViewModel.markInstallUploadCompleted();

      await Future<void>.delayed(const Duration(seconds: 3));

      await _firmwareUpdateViewModel.trackFirmwareInstallProgress(vip: vip);

      if (!mounted) {
        return;
      }

      _firmwareUpdateViewModel.setInstalledSuccess();

      // Keep cached file through install, then clean it up after successful upload.
      try {
        final File cachedBundle = File(installedBundlePath);
        if (await cachedBundle.exists()) {
          await cachedBundle.delete();
        }
      } catch (_) {
        // Install already succeeded; ignore cache cleanup errors.
      }

      await _persistState();

      try {
        final String projectId = serviceLocator<ProjectViewModel>().projectId;
        await _firmwareUpdateViewModel.logInstallStatus(
          projectId: projectId,
          bundleVersion: _firmwareUpdateViewModel.state.availableVersion,
          previousVersion: previousVersion,
          launcherVersion: _firmwareUpdateViewModel.state.desktopVersion,
          status: 'INSTALL_SUCCESS',
        );
      } catch (e) {
        //
      }
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      if (CancelToken.isCancel(e)) {
        _firmwareUpdateViewModel.setInstallCancelled(message: 'Upload cancelled by user.');
        return;
      }
      _firmwareUpdateViewModel.setInstallFailed('Install failed. Please retry. $e');

      try {
        final String projectId = serviceLocator<ProjectViewModel>().projectId;
        await _firmwareUpdateViewModel.logInstallStatus(
          projectId: projectId,
          bundleVersion: _firmwareUpdateViewModel.state.availableVersion,
          previousVersion: previousVersion,
          launcherVersion: _firmwareUpdateViewModel.state.desktopVersion,
          status: 'INSTALL_FAIL',
        );
      } catch (_) {
        // Keep install failure visible even if logging fails.
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      if (e.toString().contains('cancelled by user')) {
        _firmwareUpdateViewModel.setInstallCancelled(message: 'Socket progress tracking cancelled by user.');
        return;
      }

      _firmwareUpdateViewModel.setInstallFailed('Install failed. Please retry. $e');

      try {
        final String projectId = serviceLocator<ProjectViewModel>().projectId;
        await _firmwareUpdateViewModel.logInstallStatus(
          projectId: projectId,
          bundleVersion: _firmwareUpdateViewModel.state.availableVersion,
          previousVersion: previousVersion,
          launcherVersion: _firmwareUpdateViewModel.state.desktopVersion,
          status: 'INSTALL_FAIL',
        );
      } catch (_) {
        // Keep install failure visible even if logging fails.
      }
    }
  }

  void _cancelDownload() {
    _downloadCancelToken?.cancel('cancelled-by-user');
  }

  void _retryDownload() {
    _downloadNow();
  }

  void _retryInstall() {
    _installNow();
  }

  void _rollbackToDownloaded() {
    _firmwareUpdateViewModel.rollbackToDownloadedOrAvailable();
  }

  String get _description {
    final String releaseNotes = _firmwareUpdateViewModel.state.releaseNotes;
    if (releaseNotes.trim().isNotEmpty) return releaseNotes;
    return 'A new update is ready. Download it now to get all the latest features and improvements. '
        'It only takes a moment, and updating ensures everything works smoothly and feels better than before. '
        'Don\'t miss out grab the newest version.';
  }

  Future<void> _showInstallSuccessDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          title: Text('Firmware Update'),
          content: Text('Firmware update was successful.'),
        );
      },
    );
  }

  Future<void> _showInstallSuccessDialogForTwoSeconds() async {
    if (!mounted) {
      return;
    }

    _showInstallSuccessDialog();
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context, rootNavigator: false);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FirmwareUpdateViewModel, FirmwareUpdateViewModelState>(
      bloc: _firmwareUpdateViewModel,
      listenWhen:
          (FirmwareUpdateViewModelState previous, FirmwareUpdateViewModelState current) =>
              previous.uiState == FirmwareUpdateUiState.installing && current.uiState == FirmwareUpdateUiState.installed,
      listener: (BuildContext context, FirmwareUpdateViewModelState state) {
        _showInstallSuccessDialogForTwoSeconds();
      },
      builder: (BuildContext context, FirmwareUpdateViewModelState state) {
        if (state.uiState == FirmwareUpdateUiState.noUpdate) {
          return _buildNoUpdateView(context, state);
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildHeading(context, state),
                        const SizedBox(height: 10),
                        FusionAppText(
                          text: _description,
                          style: context.textTheme.h6Regular,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                  _buildActionPanel(context, state),
                ],
              ),
              const SizedBox(height: 18),
              if ((state.uiState == FirmwareUpdateUiState.installing || state.uiState == FirmwareUpdateUiState.installed) && state.isProgressExpanded)
                _buildDeviceProgressTable(context, state),
              if ((state.uiState == FirmwareUpdateUiState.installing || state.uiState == FirmwareUpdateUiState.installed) && state.isProgressExpanded)
                const SizedBox(height: 18),
              _buildInUseVersionRow(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoUpdateView(BuildContext context, FirmwareUpdateViewModelState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FusionIcon.svg(
            AssetSvg.sadFace,
            color: context.colorScheme.textPrimary,
          ),
          const SizedBox(height: 24),
          FusionAppText(
            text: 'Oh no! No new updates available',
            style: context.textTheme.h4SemiBold,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 560,
            child: _buildInUseVersionRow(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeading(BuildContext context, FirmwareUpdateViewModelState state) {
    final String version = state.availableVersion.isEmpty ? state.inUseVersion : state.availableVersion;
    final String stateText;
    switch (state.uiState) {
      case FirmwareUpdateUiState.updateAvailable:
        stateText = 'available for download';
      case FirmwareUpdateUiState.downloading:
        stateText = 'is downloading';
      case FirmwareUpdateUiState.downloaded:
        stateText = 'available to install';
      case FirmwareUpdateUiState.downloadFailed:
        stateText = 'failed to download';
      case FirmwareUpdateUiState.installing:
        stateText = 'is installing';
      case FirmwareUpdateUiState.installFailed:
        stateText = 'failed to install';
      case FirmwareUpdateUiState.installed:
        stateText = 'is installed successfully';
      case FirmwareUpdateUiState.checking:
        stateText = 'is checking';
      case FirmwareUpdateUiState.noUpdate:
        stateText = 'is up to date';
      case FirmwareUpdateUiState.appUpdateRequired:
        stateText = 'requires launcher update';
    }

    return RichText(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'v $version ',
            style: context.textTheme.h1Bold,
          ),
          TextSpan(
            text: stateText,
            style: context.textTheme.h2Regular.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(BuildContext context, FirmwareUpdateViewModelState state) {
    Widget content;

    switch (state.uiState) {
      case FirmwareUpdateUiState.updateAvailable:
        content = _buildButton(context, 'Download Now', _downloadNow);
      case FirmwareUpdateUiState.downloading:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildProgressCircle(state),
          ],
        );
      case FirmwareUpdateUiState.downloaded:
        content = Column(
          children: <Widget>[
            _buildButton(context, 'Install Now', _installNow),
            const SizedBox(height: 14),
            _buildSuccessLabel('Downloaded Successfully'),
          ],
        );
      case FirmwareUpdateUiState.downloadFailed:
        content = Column(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildButton(context, 'Retry Download', _retryDownload, width: 180),
                const SizedBox(width: 10),
                _buildButton(context, 'Rollback', _rollbackToDownloaded, width: 150),
              ],
            ),
            const SizedBox(height: 14),
          ],
        );
      case FirmwareUpdateUiState.installing:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: _firmwareUpdateViewModel.toggleProgressExpanded,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildProgressCircle(state),
                  const SizedBox(width: 14),
                  FusionAppText(
                    text: 'View Device Progress',
                    style: context.textTheme.b2Medium,
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    state.isProgressExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                    color: const Color(0xFFB9B9B9),
                  ),
                ],
              ),
            ),
          ],
        );
      case FirmwareUpdateUiState.installFailed:
        content = Column(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildButton(context, 'Retry Install', _retryInstall, width: 170),
                const SizedBox(width: 10),
                _buildButton(context, 'Rollback', _rollbackToDownloaded, width: 150),
              ],
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: _buildErrorLabel(state.errorText.isEmpty ? 'Device Timeout' : state.errorText),
            ),
          ],
        );
      case FirmwareUpdateUiState.installed:
        content = Column(
          children: <Widget>[
            _buildSuccessLabel('Installed Successfully'),
            const SizedBox(height: 12),
            InkWell(
              onTap: _firmwareUpdateViewModel.toggleProgressExpanded,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FusionAppText(
                    text: 'View Device Progress',
                    style: context.textTheme.b2Medium,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    state.isProgressExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                    color: const Color(0xFFB9B9B9),
                  ),
                ],
              ),
            ),
          ],
        );
      case FirmwareUpdateUiState.checking:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: Color(0xFF27B177),
              ),
            ),
            const SizedBox(width: 10),
            FusionAppText(
              text: 'Checking',
              style: context.textTheme.b2Medium,
            ),
          ],
        );
      case FirmwareUpdateUiState.noUpdate:
        content = const SizedBox.shrink();
      case FirmwareUpdateUiState.appUpdateRequired:
        content = Column(
          children: <Widget>[
            _buildErrorLabel(state.errorText.isEmpty ? 'Launcher update required.' : state.errorText),
          ],
        );
    }

    return content;
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onTap, {double width = 230}) {
    return SizedBox(
      width: width,
      child: FusionNeumorphicButton(
        semanticId: 'updates_${text.toLowerCase().replaceAll(' ', '_')}',
        text: text,
        onTap: onTap,
        borderRadius: 8,
        height: 45,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        textStyle: context.textTheme.l1Medium,
      ),
    );
  }

  Widget _buildProgressCircle(FirmwareUpdateViewModelState state) {
    final int percent = (state.progress * 100).round().clamp(0, 100);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            value: state.progress,
            strokeWidth: 3,
            backgroundColor: const Color(0xFF3A3A3A),
            color: const Color(0xFF27B177),
          ),
        ),
        FusionAppText(
          text: '$percent%',
          style: context.textTheme.l1Regular.copyWith(
            color: const Color(0xFF27B177),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.check_circle, color: Color(0xFF1BC47D), size: 18),
        const SizedBox(width: 8),
        FusionAppText(
          text: text,
          style: context.textTheme.l1Medium.copyWith(
            color: const Color(0xFF1BC47D),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.cancel, color: Color(0xFFE43333), size: 18),
        const SizedBox(width: 8),
        FusionAppText(
          text: text,
          maxLine: 3,
          style: context.textTheme.l1Medium.copyWith(
            color: const Color(0xFFE43333),
          ),
        ),
      ],
    );
  }

  Widget _buildInUseVersionRow(BuildContext context, FirmwareUpdateViewModelState state) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: Row(
        children: <Widget>[
          FusionAppText(
            text: 'In-use Version',
            style: context.textTheme.b3Regular.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          const Spacer(),
          FusionAppText(
            text: 'v ${state.inUseVersion}',
            style: context.textTheme.b3Bold,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceProgressTable(BuildContext context, FirmwareUpdateViewModelState state) {
    final List<FirmwareInstallDeviceProgress> devices = state.deviceInstallProgress;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2F2F2F), width: 1),
      ),
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Expanded(flex: 2, child: _TableHeaderText('STATUS')),
                Expanded(flex: 3, child: _TableHeaderText('SERIAL NUMBER')),
                Expanded(flex: 3, child: _TableHeaderText('NODE')),
                Expanded(flex: 2, child: _TableHeaderText('STEP')),
                Expanded(flex: 3, child: _TableHeaderText('TASK')),
                Expanded(flex: 4, child: _TableHeaderText('INSTALLATION PROGRESS')),
              ],
            ),
          ),
          if (devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TableValueText('Waiting for device update events...'),
              ),
            ),
          for (final FirmwareInstallDeviceProgress device in devices) _buildDeviceRow(device),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(FirmwareInstallDeviceProgress device) {
    final String normalizedState = device.updateState.toUpperCase();
    final bool completed = normalizedState == 'COMPLETED';
    final bool success = normalizedState == 'SUCCESS';
    final Color stateColor = completed || success ? const Color(0xFF5CC59A) : const Color(0xFFE0A645);
    final int safeCurrentStep = device.currentStep.clamp(0, 1000);
    final int safeTotalSteps = device.totalSteps.clamp(0, 1000);
    final double currentStepProgress = device.stepProgress.clamp(0, 100) / 100;
    final double computedOverallProgress =
        safeTotalSteps > 0 ? (((safeCurrentStep > 0 ? safeCurrentStep - 1 : 0) + currentStepProgress) / safeTotalSteps).clamp(0, 1) : currentStepProgress;

    final double rowProgress = completed || success ? 1 : computedOverallProgress;
    final String progressLabel = '${(rowProgress * 100).round().clamp(0, 100)}%';

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                Icon(Icons.square_rounded, color: stateColor, size: 10),
                const SizedBox(width: 8),
                Expanded(child: _TableValueText(normalizedState, color: stateColor)),
              ],
            ),
          ),
          Expanded(flex: 3, child: _TableValueText(device.serialNumber, color: const Color(0xFF2FA16B), underline: true)),
          Expanded(flex: 3, child: _TableValueText(device.node.isEmpty ? '--' : device.node)),
          Expanded(flex: 2, child: _TableValueText(device.stepLabel)),
          Expanded(flex: 3, child: _TableValueText(device.currentTask.isEmpty ? '--' : device.currentTask)),
          Expanded(
            flex: 4,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: rowProgress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFF363636),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B9A66)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: _TableValueText(progressLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  const _TableHeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: text,
      style: context.textTheme.l1Regular.copyWith(
        color: context.colorScheme.textSecondary,
      ),
      maxLine: 1,
    );
  }
}

class _TableValueText extends StatelessWidget {
  const _TableValueText(
    this.text, {
    this.color = const Color(0xFFD3D3D3),
    this.underline = false,
  });

  final String text;
  final Color color;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: text,
      style: context.textTheme.b2Medium.copyWith(
        color: color,
        fontSize: 14,
        decoration: underline ? TextDecoration.underline : TextDecoration.none,
      ),
      maxLine: 1,
    );
  }
}
