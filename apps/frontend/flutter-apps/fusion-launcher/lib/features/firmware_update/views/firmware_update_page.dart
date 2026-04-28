import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../software_update/software_update_service.dart';
import '../viewmodel/firmware_update_vm.dart';

class FirmwareUpdatesTab extends StatefulWidget {
  const FirmwareUpdatesTab({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<FirmwareUpdatesTab> createState() => _FusionSoftwareUpdate2State();
}

class _FusionSoftwareUpdate2State extends State<FirmwareUpdatesTab> {
  final SoftwareUpdateCubit _cubit = SoftwareUpdateCubit(
    networkClient: serviceLocator<FusionNetworkClient>(),
  );

  final GlobalBlockerController _screenBlocker = GlobalBlockerController();
  bool _showedSuccessDialog = false;
  bool _isInitialSilentCheckInProgress = true;
  bool _hasSeenCheckingPhaseForSilentCheck = false;

  @override
  void initState() {
    super.initState();
    _runSilentCheck();
  }

  @override
  void didUpdateWidget(covariant FirmwareUpdatesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _runSilentCheck();
    }
  }

  void _runSilentCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isInitialSilentCheckInProgress = true;
      _hasSeenCheckingPhaseForSilentCheck = false;
      unawaited(_cubit.checkForUpdates());
    });
  }

  @override
  void dispose() {
    _screenBlocker.dispose();
    _cubit.close();
    super.dispose();
  }

  bool _isHeadlineProcessingPhase(UpdatePhase phase) {
    return phase == UpdatePhase.downloading ||
        phase == UpdatePhase.discovering ||
        phase == UpdatePhase.uploading ||
        phase == UpdatePhase.installing ||
        phase == UpdatePhase.rebooting;
  }

  void _syncGlobalInstallBlocker(UpdateState state) {
    final bool shouldBlock =
        state.phase == UpdatePhase.downloading ||
        state.phase == UpdatePhase.discovering ||
        state.phase == UpdatePhase.uploading ||
        state.phase == UpdatePhase.installing ||
        state.phase == UpdatePhase.rebooting;

    if (shouldBlock) {
      _screenBlocker.show(context, content: const SizedBox());
    } else {
      _screenBlocker.hide();
    }
  }

  Future<void> _showInstallSuccessDialogForTwoSeconds() async {
    if (!mounted || _showedSuccessDialog) return;
    _showedSuccessDialog = true;

    showDialog<void>(
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.check_circle, color: Color(0xFF1BC47D), size: 38),
                const SizedBox(height: 12),
                FusionAppText(text: 'Firmware Updated', style: dialogContext.textTheme.b2Medium),
                const SizedBox(height: 6),
                FusionAppText(
                  text: 'Firmware update was successful.',
                  style: dialogContext.textTheme.b3Regular.copyWith(color: dialogContext.colorScheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final NavigatorState nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SoftwareUpdateCubit, UpdateState>(
      bloc: _cubit,
      listener: (BuildContext context, UpdateState state) {
        if (_isInitialSilentCheckInProgress) {
          if (state.phase == UpdatePhase.checking) {
            _hasSeenCheckingPhaseForSilentCheck = true;
          } else if (_hasSeenCheckingPhaseForSilentCheck) {
            _isInitialSilentCheckInProgress = false;
            _hasSeenCheckingPhaseForSilentCheck = false;
          }
        }
        _syncGlobalInstallBlocker(state);
        if (state.phase == UpdatePhase.completed) {
          _showInstallSuccessDialogForTwoSeconds();
        }
      },
      builder: (BuildContext context, UpdateState state) {
        final bool showUpToDateHero = _showUpToDateHero(state);
        final String description = state.releaseNotes?.trim() ?? 'No release notes provided for this update.';

        final String inUseVersion = state.fusionNetworkDevices.firstWhereOrNull((FusionNetworkDevice element) => element.isPrimary)?.primaryDeviceVersion ?? '';
        final String availableVersion = state.availableVersion?.trim() ?? '';
        final bool shouldShowAvailableVersion = state.updateAvailable && availableVersion.isNotEmpty;
        final String headlineVersion = shouldShowAvailableVersion ? availableVersion : inUseVersion;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!showUpToDateHero)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: <InlineSpan>[
                                TextSpan(text: '$headlineVersion ', style: context.textTheme.h1Bold),
                                TextSpan(
                                  text: _headline(state),
                                  style: context.textTheme.h2Regular.copyWith(fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          FusionAppText(text: description, style: context.textTheme.h6Regular),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    _buildActionPanel(context, state),
                  ],
                ),
              if (!showUpToDateHero) const SizedBox(height: 18),
              if (!showUpToDateHero && _showProgressTable(state)) _buildDeviceProgressTable(context, state),
              if (!showUpToDateHero && _showProgressTable(state)) const SizedBox(height: 18),
              if (!showUpToDateHero) _buildInUseVersionRow(context, state, inUseVersion),
              if (showUpToDateHero) Expanded(child: _buildUpToDateBody(context, state, inUseVersion)),
              if (state.error?.message.trim().isNotEmpty == true) const SizedBox(height: 12),
              if (state.error?.message.trim().isNotEmpty == true) _buildDetailedErrorFooter(context, state.error!.message),
            ],
          ),
        );
      },
    );
  }

  bool _showProgressTable(UpdateState s) {
    // During upload, keep device list hidden until file transfer is fully done.
    if (s.phase == UpdatePhase.uploading) {
      return s.uploadProgress >= 1.0;
    }

    return s.phase == UpdatePhase.installing ||
        s.phase == UpdatePhase.rebooting ||
        s.phase == UpdatePhase.completed ||
        s.isWaitingForSocketResponse ||
        s.deviceProgress.isNotEmpty;
  }

  bool _showUpToDateHero(UpdateState state) {
    if (_isInitialSilentCheckInProgress && state.phase == UpdatePhase.checking) {
      return true;
    }
    return state.phase == UpdatePhase.idle && !state.updateAvailable && !state.appUpdateRequired;
  }

  Widget _buildUpToDateHero(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SvgPicture.asset(
            'assets/svg/smily_face.svg',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 12),
          FusionAppText(
            text: 'Your device is up to date!',
            style: context.textTheme.h4SemiBold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FusionAppText(
            text: 'No new updates available, as your device is already running on the latest firmware version.',
            style: context.textTheme.b3Regular.copyWith(color: context.colorScheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDateBody(BuildContext context, UpdateState state, String versionText) {
    return Column(
      children: <Widget>[
        const Spacer(),
        _buildUpToDateHero(context),
        const SizedBox(height: 34),
        Center(
          child: SizedBox(
            width: 360,
            child: _buildInUseVersionRow(context, state, versionText),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  String _headline(UpdateState state) {
    if (state.appUpdateRequired) return 'requires launcher update';

    switch (state.phase) {
      case UpdatePhase.idle:
        return state.updateAvailable ? 'available for download' : 'is up to date';
      case UpdatePhase.checking:
        return 'is checking';
      case UpdatePhase.awaitDownload:
        return 'available for download';
      case UpdatePhase.downloading:
        return 'is downloading';
      case UpdatePhase.awaitInstall:
        return 'available to install';
      case UpdatePhase.discovering:
        return 'is discovering devices';
      case UpdatePhase.uploading:
        return 'is uploading to device';
      case UpdatePhase.installing:
        return 'is installing';
      case UpdatePhase.rebooting:
        return 'is rebooting devices';
      case UpdatePhase.completed:
        return 'is installed successfully';
      case UpdatePhase.failed:
        return switch (state.error?.code) {
          UpdateErrorCode.checkingFailed => 'failed to connect to Fusion server',
          UpdateErrorCode.versionMismatch => 'device versions are mismatching',
          UpdateErrorCode.downloadFailed => 'failed to download update',
          UpdateErrorCode.uploadFailed => 'failed to upload update to device',
          UpdateErrorCode.rollbackFailed => 'failed to rollback update',
          UpdateErrorCode.wsConnectionFailed => 'connection to device lost',
          UpdateErrorCode.wsDeviceFailed => 'device failed during update',
          UpdateErrorCode.wsClosedEarly => 'connection to device lost',
          UpdateErrorCode.syncTimeout => 'devices did not come back online in time',
          UpdateErrorCode.networkError => 'network error occurred',
          UpdateErrorCode.unknown => 'an unknown error occurred',
          _ => 'an unknown error occurred',
        };
      case UpdatePhase.cancelled:
        return 'was cancelled';
      case UpdatePhase.rollingBack:
        return 'is rolling back';
      case UpdatePhase.rolledBack:
        return 'was rolled back';
    }
  }

  Widget _buildActionPanel(BuildContext context, UpdateState state) {
    switch (state.phase) {
      case UpdatePhase.awaitDownload:
        return _BuildAction(text: 'Download Now', onTap: _cubit.confirmDownload);
      case UpdatePhase.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildProgressCircle(state.downloadProgress),
            const SizedBox(width: 12),
            _AnimatedHeadlineStatusText(
              animate: _isHeadlineProcessingPhase(state.phase),
              child: FusionAppText(text: 'Downloading', style: context.textTheme.b2Medium),
            ),
          ],
        );
      case UpdatePhase.awaitInstall:
        return Column(
          children: <Widget>[
            _BuildAction(text: 'Install Now', onTap: _cubit.confirmInstall),
            // const SizedBox(height: 10),
            // _BuildAction(text: 'Cancel', onTap: () => unawaited(_cubit.cancel())),
          ],
        );
      case UpdatePhase.uploading:
      case UpdatePhase.discovering:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildProgressCircle(_overallProgress(state)),
            const SizedBox(width: 12),
            _AnimatedHeadlineStatusText(
              animate: _isHeadlineProcessingPhase(state.phase),
              child: FusionAppText(text: _phaseLabel(state.phase), style: context.textTheme.b2Medium),
            ),
          ],
        );
      case UpdatePhase.installing:
      case UpdatePhase.rebooting:
        return _AnimatedHeadlineStatusText(
          animate: _isHeadlineProcessingPhase(state.phase),
          child: FusionAppText(text: _phaseLabel(state.phase), style: context.textTheme.b2Medium),
        );
      case UpdatePhase.failed:
        return Column(
          children: <Widget>[
            if (state.canRetry) _BuildAction(text: state.error?.retryLabel ?? 'Retry', onTap: () => unawaited(_cubit.retryPhase())),
            if (state.showRollbackButton) ...<Widget>[
              const SizedBox(height: 10),
              _BuildAction(text: 'Rollback', onTap: () => unawaited(_cubit.rollback())),
            ],
          ],
        );
      case UpdatePhase.completed:
        return Column(
          children: <Widget>[
            _buildSuccessLabel('Installed Successfully'),
            const SizedBox(height: 12),
            _BuildAction(text: 'Check Again', onTap: () => unawaited(_cubit.checkForUpdates())),
          ],
        );
      case UpdatePhase.idle:
      case UpdatePhase.cancelled:
      case UpdatePhase.rolledBack:
      case UpdatePhase.rollingBack:
      case UpdatePhase.checking:
        if (state.appUpdateRequired) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: _buildErrorLabel(
              'Launcher update required${state.minDesktopAppVersion == null ? '' : ' (min ${state.minDesktopAppVersion})'}',
            ),
          );
        }
        if (state.phase == UpdatePhase.checking) {
          if (_isInitialSilentCheckInProgress) return const SizedBox.shrink();
          return const SizedBox.shrink();
        }
        return _BuildAction(
          text: 'Check for Updates',
          onTap: () => unawaited(_cubit.checkForUpdates()),
        );
    }
  }

  String _phaseLabel(UpdatePhase phase) {
    return switch (phase) {
      UpdatePhase.discovering => 'Discovering devices',
      UpdatePhase.uploading => 'Uploading to system',
      UpdatePhase.installing => 'Installing to devices',
      UpdatePhase.rebooting => 'Rebooting devices',
      _ => 'Working',
    };
  }

  double _overallProgress(UpdateState state) {
    if (state.phase == UpdatePhase.uploading) return state.uploadProgress.clamp(0, 1);
    if (state.deviceProgress.isEmpty) return 0;
    final List<DeviceUpdateProgressEvent> values = state.deviceProgress.values.toList();
    final double sum = values.fold<double>(0, (double p, DeviceUpdateProgressEvent e) => p + e.progress.clamp(0, 1));
    return (sum / values.length).clamp(0, 1);
  }

  Widget _buildProgressCircle(double progress) {
    final double safe = progress.clamp(0, 1).toDouble();
    final int percent = (safe * 100).round();
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            value: safe,
            strokeWidth: 3,
            backgroundColor: const Color(0xFF3A3A3A),
            color: const Color(0xFF27B177),
          ),
        ),
        FusionAppText(text: '$percent%', style: const TextStyle(fontSize: 12, color: Color(0xFF27B177))),
      ],
    );
  }

  Widget _buildSuccessLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.check_circle, color: Color(0xFF1BC47D), size: 18),
        const SizedBox(width: 8),
        FusionAppText(text: text, style: const TextStyle(color: Color(0xFF1BC47D))),
      ],
    );
  }

  Widget _buildErrorLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.cancel, color: Color(0xFFE43333), size: 18),
        const SizedBox(width: 8),
        Flexible(child: FusionAppText(text: text, maxLine: 3, style: const TextStyle(color: Color(0xFFE43333)))),
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
          Expanded(child: FusionAppText(text: text, maxLine: 6, style: context.textTheme.b3Regular.copyWith(color: const Color(0xFFE43333)))),
        ],
      ),
    );
  }

  Widget _buildInUseVersionRow(BuildContext context, UpdateState state, String versionText) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: Row(
        children: <Widget>[
          FusionAppText(text: 'In-use Version', style: context.textTheme.b3Regular.copyWith(color: context.colorScheme.textSecondary)),
          const Spacer(),
          FusionAppText(text: versionText, style: context.textTheme.b3Bold),
        ],
      ),
    );
  }

  Widget _buildDeviceProgressTable(BuildContext context, UpdateState state) {
    final List<FusionNetworkDevice> devices = state.fusionNetworkDevices;
    final bool hideInstallProgressColumn = state.phase == UpdatePhase.rebooting;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2F2F2F), width: 1),
      ),
      child: Column(
        children: <Widget>[
          if (state.isWaitingForSocketResponse)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TableValueText('Waiting for update progress from devices...'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                const Expanded(flex: 2, child: _TableHeaderText('STATUS')),
                const Expanded(flex: 3, child: _TableHeaderText('SERIAL NUMBER')),
                const Expanded(flex: 3, child: _TableHeaderText('NODE')),
                const Expanded(flex: 2, child: _TableHeaderText('STEP')),
                Expanded(
                  flex: 4,
                  child: hideInstallProgressColumn ? const SizedBox.shrink() : const _TableHeaderText('INSTALLATION PROGRESS'),
                ),
              ],
            ),
          ),
          ...devices.map((FusionNetworkDevice networkDevice) {
            final DeviceUpdateProgressEvent? event = state.deviceProgress[networkDevice.serialNumber];

            final String status = event?.updateState ?? 'PENDING';
            final bool completed = event?.isCompleted == true || event?.isSuccess == true;
            final double rowProgress = completed ? 1.0 : (event?.stepProgress ?? 0.0);
            final Color stateColor = completed ? const Color(0xFF5CC59A) : const Color(0xFFE0A645);

            return Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1))),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.square_rounded, color: stateColor, size: 10),
                        const SizedBox(width: 8),
                        Expanded(child: _TableValueText(status, color: stateColor)),
                      ],
                    ),
                  ),
                  Expanded(flex: 3, child: _TableValueText(networkDevice.serialNumber, color: const Color(0xFF2FA16B), underline: true)),
                  Expanded(flex: 3, child: _TableValueText(networkDevice.modelName)),
                  Expanded(flex: 2, child: _TableValueText(event?.step ?? "-/-")),
                  Expanded(
                    flex: 4,
                    child:
                        hideInstallProgressColumn
                            ? const SizedBox.shrink()
                            : Row(
                              children: <Widget>[
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: rowProgress.clamp(0, 1),
                                      minHeight: 4,
                                      backgroundColor: const Color(0xFF363636),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B9A66)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(width: 40, child: _TableValueText('${(rowProgress * 100).round()}%')),
                              ],
                            ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AnimatedHeadlineStatusText extends StatefulWidget {
  const _AnimatedHeadlineStatusText({
    required this.child,
    required this.animate,
  });

  final Widget child;
  final bool animate;

  @override
  State<_AnimatedHeadlineStatusText> createState() => _AnimatedHeadlineStatusTextState();
}

class _AnimatedHeadlineStatusTextState extends State<_AnimatedHeadlineStatusText> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      reverseDuration: const Duration(milliseconds: 650),
      value: 1.0,
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedHeadlineStatusText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate == widget.animate) return;

    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double opacity = widget.animate ? (0.35 + (0.65 * _controller.value)) : 1.0;
        return Opacity(opacity: opacity, child: child);
      },
      child: widget.child,
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
      style: context.textTheme.l1Regular.copyWith(color: context.colorScheme.textSecondary),
      maxLine: 1,
    );
  }
}

class _TableValueText extends StatelessWidget {
  const _TableValueText(this.text, {this.color = const Color(0xFFD3D3D3), this.underline = false});

  final String text;
  final Color color;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: text,
      style: context.textTheme.b2Medium.copyWith(color: color, fontSize: 14, decoration: underline ? TextDecoration.underline : TextDecoration.none),
      maxLine: 1,
    );
  }
}

class _BuildAction extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _BuildAction({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId("btn", 'updates_$text'),
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: context.colorScheme.elevation2,
            foregroundColor: context.colorScheme.textPrimary,
            textStyle: context.textTheme.l1Medium,
            side: BorderSide(color: context.colorScheme.elevation3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: FusionAppText(
            text: text,
            style: context.textTheme.l1Medium,
          ),
        ),
      ),
    );
  }
}
