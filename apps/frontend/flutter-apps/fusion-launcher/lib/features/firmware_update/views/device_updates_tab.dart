import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/firmware_update/viewmodel/firmware_update_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DeviceUpdatesTab extends StatefulWidget {
  const DeviceUpdatesTab({super.key});

  @override
  State<DeviceUpdatesTab> createState() => _DeviceUpdatesTabState();
}

class _DeviceUpdatesTabState extends State<DeviceUpdatesTab> {
  final FirmwareUpdateViewModel _firmwareUpdateViewModel = serviceLocator<FirmwareUpdateViewModel>();
  OverlayEntry? _globalInstallBlockerEntry;

  @override
  void initState() {
    super.initState();
    _firmwareUpdateViewModel.initialize();
  }

  @override
  void dispose() {
    _hideGlobalInstallBlocker();
    super.dispose();
  }

  void _onDownloadNow() => unawaited(_firmwareUpdateViewModel.onDownloadTap());

  void _installNow() => unawaited(_firmwareUpdateViewModel.installNow());

  void _retryDownload() => unawaited(_firmwareUpdateViewModel.retryDownload());

  void _retryInstall() => unawaited(_firmwareUpdateViewModel.retryInstall());

  void _rollbackToDownloaded() => unawaited(_firmwareUpdateViewModel.rollbackToDownloaded());

  void _deleteDownloadedBundle() => unawaited(_firmwareUpdateViewModel.deleteDownloadedBundle());

  String get _description {
    final String releaseNotes = _firmwareUpdateViewModel.state.updateCheckResult?.releaseNotes ?? '';
    if (releaseNotes.trim().isNotEmpty) return releaseNotes;
    return 'A new update is ready. Download it now to get all the latest features and improvements.';
  }

  Future<void> _showInstallSuccessDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: dialogContext.colorScheme.elevation1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: dialogContext.colorScheme.strokeLight),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0x1F1BC47D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF1BC47D),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                FusionAppText(
                  text: 'Firmware Updated',
                  style: dialogContext.textTheme.b2Medium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                FusionAppText(
                  text: 'Firmware update was successful.',
                  style: dialogContext.textTheme.b3Regular.copyWith(
                    color: dialogContext.colorScheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLine: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInstallSuccessDialogForTwoSeconds() async {
    if (!mounted) return;

    _showInstallSuccessDialog();
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final NavigatorState navigator = Navigator.of(context, rootNavigator: false);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _syncGlobalInstallBlocker(FirmwareUpdateViewModelState state) {
    if (state.uiState == FirmwareUpdateUiState.downloading || state.uiState == FirmwareUpdateUiState.installing || state.isRebootTrackingInProgress) {
      // Remove existing and recreate to update the state
      _hideGlobalInstallBlocker();
      _showGlobalInstallBlocker(state);
    } else {
      _hideGlobalInstallBlocker();
    }
  }

  void _showGlobalInstallBlocker(FirmwareUpdateViewModelState state) {
    if (!mounted || _globalInstallBlockerEntry != null) return;

    final OverlayState overlayState = Overlay.of(context, rootOverlay: true);

    _globalInstallBlockerEntry = OverlayEntry(
      builder: (BuildContext context) {
        final bool isDownloading = state.uiState == FirmwareUpdateUiState.downloading;
        final bool isInstalling = state.uiState == FirmwareUpdateUiState.installing;
        final bool isUploading = isInstalling && state.isUploadInProgress;
        final bool isRebooting = state.isRebootTrackingInProgress;
        final int totalDevices = state.networkDevices.length;
        final int completedDevices = state.devicesRebootStatus.where((FirmwareDeviceRebootStatus d) => d.isSUCCESS).length;

        String title() {
          if (isDownloading) return "Firmware is downloading";
          if (isUploading) return "Firmware is uploading";
          if (isRebooting) return "Devices are rebooting";
          if (isInstalling) return "Firmware is installing";
          return "Devices are rebooting";
        }

        String description() {
          if (isDownloading) return 'Firmware bundle is being downloaded to your devices. Please do not close the launcher or disconnect your devices.';
          if (isUploading) return 'Firmware bundle is being uploaded to your devices. Please do not close the launcher or disconnect your devices.';
          if (isRebooting) return 'Devices are rebooting with new firmware. Please do not close the launcher or disconnect your devices.';
          if (isInstalling) return 'Firmware bundle is being installed on your devices. Please do not close the launcher or disconnect your devices.';
          return 'Devices are rebooting with new firmware. Please do not close the launcher or disconnect your devices.';
        }

        return Positioned.fill(
          child: Material(
            color: const Color(0x80000000),
            child: Stack(
              children: <Widget>[
                const SizedBox.expand(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF27B177),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FusionAppText(
                        text: title(),
                        style: context.textTheme.b3Bold,
                      ),
                      const SizedBox(height: 8),
                      FusionAppText(
                        text: description(),
                        style: context.textTheme.b3Regular.copyWith(
                          color: context.colorScheme.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // if (isRebooting && totalDevices > 0 && completedDevices > 0) ...<Widget>[
                      //   const SizedBox(height: 16),
                      //   FusionAppText(
                      //     text: '$completedDevices of $totalDevices devices rebooted',
                      //     style: context.textTheme.b2Medium.copyWith(
                      //       color: const Color(0xFF27B177),
                      //     ),
                      //   ),
                      // ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlayState.insert(_globalInstallBlockerEntry!);
  }

  void _hideGlobalInstallBlocker() {
    _globalInstallBlockerEntry?.remove();
    _globalInstallBlockerEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FirmwareUpdateViewModel, FirmwareUpdateViewModelState>(
      bloc: _firmwareUpdateViewModel,
      listenWhen: (FirmwareUpdateViewModelState previous, FirmwareUpdateViewModelState current) {
        return previous.uiState != current.uiState ||
            previous.isRebootTrackingInProgress != current.isRebootTrackingInProgress ||
            previous.isUploadInProgress != current.isUploadInProgress;
      },
      listener: (BuildContext context, FirmwareUpdateViewModelState state) {
        _syncGlobalInstallBlocker(state);
        if (state.uiState == FirmwareUpdateUiState.installed) {
          _showInstallSuccessDialogForTwoSeconds();
        }
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
              if (state.errorText.trim().isNotEmpty) const SizedBox(height: 12),
              if (state.errorText.trim().isNotEmpty) _buildDetailedErrorFooter(context, state.errorText),
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
          const SizedBox(height: 20),
          _buildButton(
            context,
            'Check Again',
            () => unawaited(_firmwareUpdateViewModel.checkNewFirmwareUpdates()),
            width: 180,
          ),
        ],
      ),
    );
  }

  Widget _buildHeading(BuildContext context, FirmwareUpdateViewModelState state) {
    final String version = state.availableVersion.isEmpty ? serviceLocator<FirmwareUpdateViewModel>().primaryFusionDeviceVersion : state.availableVersion;

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
        content = _buildButton(
          context,
          'Download Now',
          _onDownloadNow,
        );
      case FirmwareUpdateUiState.downloading:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildProgressCircle(state),
            const SizedBox(width: 14),
            FusionAppText(
              text: 'Downloading',
              style: context.textTheme.b2Medium,
            ),
          ],
        );
      case FirmwareUpdateUiState.downloaded:
        content = Column(
          children: <Widget>[
            _buildButton(context, 'Install Now', _installNow),
            const SizedBox(height: 14),
            _buildSuccessLabel('Downloaded Successfully'),
            if (kDebugMode) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  InkWell(
                    onTap: _retryDownload,
                    child: FusionAppText(
                      text: 'Re-download',
                      style: context.textTheme.b3Regular.copyWith(
                        color: context.colorScheme.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: context.colorScheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FusionAppText(
                    text: '•',
                    style: context.textTheme.b3Regular.copyWith(
                      color: context.colorScheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: _deleteDownloadedBundle,
                    child: FusionAppText(
                      text: 'Delete file',
                      style: context.textTheme.b3Regular.copyWith(
                        color: const Color(0xFFE43333),
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFFE43333),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: _buildErrorLabel(state.errorShortText.isEmpty ? 'Download failed.' : state.errorShortText),
            ),
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
              child: _buildErrorLabel(state.errorShortText.isEmpty ? 'Device Timeout' : state.errorShortText),
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
            _buildErrorLabel(state.errorShortText.isEmpty ? 'Launcher update required.' : state.errorShortText),
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

  Widget _buildDetailedErrorFooter(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33E43333)),
        color: const Color(0x14E43333),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, color: Color(0xFFE43333), size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FusionAppText(
              text: text,
              maxLine: 6,
              style: context.textTheme.b3Regular.copyWith(
                color: const Color(0xFFE43333),
              ),
            ),
          ),
        ],
      ),
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
            text: 'v ${serviceLocator<FirmwareUpdateViewModel>().primaryFusionDeviceVersion}',
            style: context.textTheme.b3Bold,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceProgressTable(BuildContext context, FirmwareUpdateViewModelState state) {
    final List<FirmwareInstallDeviceProgress> devices = state.deviceInstallProgress;

    return Column(
      children: <Widget>[
        if (serviceLocator<FirmwareUpdateViewModel>().state.isWaitingForSocketResponse) ...<Widget>[
          Row(
            spacing: 12,
            children: <Widget>[
              const Flexible(child: FusionAppText(text: "Waiting for udpate progress from devices")),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  color: context.colorScheme.primaryColor,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2F2F2F), width: 1),
          ),
          child: Column(
            children: <Widget>[
              if (devices.isEmpty) ...<Widget>[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    // Downloaded file is uploaded message
                    child: _TableValueText('Firmware software file is uploading...'),
                  ),
                ),
              ] else ...<Widget>[
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
                Builder(
                  builder: (BuildContext context) {
                    final List<FusionNetworkDevice> networkDevices = serviceLocator<FirmwareUpdateViewModel>().state.networkDevices;

                    return Column(
                      children: <Widget>[
                        ...networkDevices.map((FusionNetworkDevice networkDevice) {
                          final FirmwareInstallDeviceProgress? device = devices.firstWhereOrNull(
                            (FirmwareInstallDeviceProgress d) => d.serialNumber == networkDevice.serialNumber,
                          );

                          return _buildDeviceRow(networkDevice, device, state);
                        }),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceRow(FusionNetworkDevice networkDevice, FirmwareInstallDeviceProgress? device, FirmwareUpdateViewModelState state) {
    // Check if we're in reboot tracking mode
    final bool isRebooting = state.isRebootTrackingInProgress;

    final String normalizedState = isRebooting ? 'REBOOTING' : device?.updateState.toUpperCase() ?? '';

    final bool completed = normalizedState == 'COMPLETED';
    final bool success = normalizedState == 'SUCCESS';
    final Color stateColor = completed || success ? const Color(0xFF5CC59A) : const Color(0xFFE0A645);
    final double rowProgress = completed || success ? 1 : ((device?.stepProgress ?? 0) / 100).clamp(0, 1);
    final String progressLabel = completed || success ? '100%' : '${(device?.stepProgress ?? 0).clamp(0, 100)}%';

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
          Expanded(flex: 3, child: _TableValueText(networkDevice.serialNumber, color: const Color(0xFF2FA16B), underline: true)),
          Expanded(flex: 3, child: _TableValueText(device?.node.isEmpty ?? true ? '--' : device?.node ?? '')),
          Expanded(flex: 2, child: _TableValueText(device?.stepLabel ?? '--')),
          Expanded(flex: 3, child: _TableValueText(device?.currentTask.isEmpty ?? true ? '--' : device?.currentTask ?? '')),
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
