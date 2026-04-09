part of 'firmware_update_vm.dart';

enum FirmwareUpdateUiState {
  checking,
  noUpdate,
  appUpdateRequired,
  updateAvailable,
  downloading,
  downloaded,
  downloadFailed,
  installing,
  installFailed,
  installed,
}

class FirmwareUpdateViewModelState extends Equatable {
  final FirmwareUpdateUiState uiState;
  final FirmwareUpdateCheckResult? updateCheckResult;
  final BundleDownloadUrlResult? bundleDownloadUrlResult;
  final String inUseVersion;
  final String availableVersion;
  final String downloadedFilePath;
  final bool isProgressExpanded;
  final double progress;
  final String errorText;
  final List<FirmwareInstallDeviceProgress> deviceInstallProgress;
  final bool installTrackingCompleted;
  final bool isUploadInProgress;
  final bool isSocketTrackingInProgress;

  const FirmwareUpdateViewModelState({
    this.uiState = FirmwareUpdateUiState.checking,
    this.updateCheckResult,
    this.bundleDownloadUrlResult,
    this.inUseVersion = '',
    this.availableVersion = '',
    this.downloadedFilePath = '',
    this.isProgressExpanded = true,
    this.progress = 0,
    this.errorText = '',
    this.deviceInstallProgress = const <FirmwareInstallDeviceProgress>[],
    this.installTrackingCompleted = false,
    this.isUploadInProgress = false,
    this.isSocketTrackingInProgress = false,
  });

  FirmwareUpdateViewModelState copyWith({
    FirmwareUpdateUiState? uiState,
    FirmwareUpdateCheckResult? updateCheckResult,
    BundleDownloadUrlResult? bundleDownloadUrlResult,
    String? inUseVersion,
    String? availableVersion,
    String? downloadedFilePath,
    bool? isProgressExpanded,
    double? progress,
    String? errorText,
    List<FirmwareInstallDeviceProgress>? deviceInstallProgress,
    bool? installTrackingCompleted,
    bool? isUploadInProgress,
    bool? isSocketTrackingInProgress,
  }) {
    return FirmwareUpdateViewModelState(
      uiState: uiState ?? this.uiState,
      updateCheckResult: updateCheckResult ?? this.updateCheckResult,
      bundleDownloadUrlResult: bundleDownloadUrlResult ?? this.bundleDownloadUrlResult,
      inUseVersion: inUseVersion ?? this.inUseVersion,
      availableVersion: availableVersion ?? this.availableVersion,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,

      //
      isProgressExpanded: isProgressExpanded ?? this.isProgressExpanded,
      progress: progress ?? this.progress,
      errorText: errorText ?? this.errorText,
      deviceInstallProgress: deviceInstallProgress ?? this.deviceInstallProgress,
      installTrackingCompleted: installTrackingCompleted ?? this.installTrackingCompleted,
      isUploadInProgress: isUploadInProgress ?? this.isUploadInProgress,
      isSocketTrackingInProgress: isSocketTrackingInProgress ?? this.isSocketTrackingInProgress,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    uiState,
    updateCheckResult,
    bundleDownloadUrlResult,
    inUseVersion,
    availableVersion,
    downloadedFilePath,
    isProgressExpanded,
    progress,
    errorText,
    deviceInstallProgress,
    installTrackingCompleted,
    isUploadInProgress,
    isSocketTrackingInProgress,
  ];
}

enum FirmwareCheckDecisionState { noUpdate, appUpdateRequired, updateAvailable, downloaded, installed, failed }

class FirmwareCheckDecision {
  final FirmwareCheckDecisionState state;
  final String? errorText;
  final String? availableVersion;
  final String? bundleId;
  final String? releaseNotes;
  final bool clearDownloadedCache;

  const FirmwareCheckDecision({
    required this.state,
    this.errorText,
    this.availableVersion,
    this.bundleId,
    this.releaseNotes,
    this.clearDownloadedCache = false,
  });
}

class FirmwareInstallDeviceProgress extends Equatable {
  final String serialNumber;
  final String node;
  final String updateState;
  final int currentStep;
  final int totalSteps;
  final String currentTask;
  final int stepProgress;
  final String timestamp;

  const FirmwareInstallDeviceProgress({
    required this.serialNumber,
    required this.node,
    required this.updateState,
    required this.currentStep,
    required this.totalSteps,
    required this.currentTask,
    required this.stepProgress,
    required this.timestamp,
  });

  String get stepLabel => '$currentStep/$totalSteps';
  bool get isCompleted => updateState.toUpperCase() == 'COMPLETED' || updateState.toUpperCase() == 'SUCCESS';
  bool get isSuccess => updateState.toUpperCase() == 'SUCCESS';

  @override
  List<Object?> get props => <Object?>[serialNumber, node, updateState, currentStep, totalSteps, currentTask, stepProgress, timestamp];
}
