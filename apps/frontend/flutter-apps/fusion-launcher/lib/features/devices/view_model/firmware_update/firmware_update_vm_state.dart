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
  bool get isCompleted => updateState.toUpperCase() == 'COMPLETED';
  bool get isSuccess => updateState.toUpperCase() == 'SUCCESS';

  @override
  List<Object?> get props => <Object?>[
    serialNumber,
    node,
    updateState,
    currentStep,
    totalSteps,
    currentTask,
    stepProgress,
    timestamp,
  ];
}

class FirmwareUpdateViewModelState extends Equatable {
  final FirmwareUpdateUiState uiState;
  final bool isProgressExpanded;
  final double progress;
  final String inUseVersion;
  final String availableVersion;
  final String releaseNotes;
  final String bundleId;
  final String downloadChecksum;
  final String downloadedFilePath;
  final String errorText;
  final String desktopVersion;
  final List<FirmwareInstallDeviceProgress> deviceInstallProgress;
  final bool installTrackingCompleted;
  final bool isUploadInProgress;
  final bool isSocketTrackingInProgress;

  const FirmwareUpdateViewModelState({
    this.uiState = FirmwareUpdateUiState.checking,
    this.isProgressExpanded = false,
    this.progress = 0,
    this.inUseVersion = '0.0.0',
    this.availableVersion = '',
    this.releaseNotes = '',
    this.bundleId = '',
    this.downloadChecksum = '',
    this.downloadedFilePath = '',
    this.errorText = '',
    this.desktopVersion = '0.0.0',
    this.deviceInstallProgress = const <FirmwareInstallDeviceProgress>[],
    this.installTrackingCompleted = false,
    this.isUploadInProgress = false,
    this.isSocketTrackingInProgress = false,
  });

  FirmwareUpdateViewModelState copyWith({
    FirmwareUpdateUiState? uiState,
    bool? isProgressExpanded,
    double? progress,
    String? inUseVersion,
    String? availableVersion,
    String? releaseNotes,
    String? bundleId,
    String? downloadChecksum,
    String? downloadedFilePath,
    String? errorText,
    String? desktopVersion,
    List<FirmwareInstallDeviceProgress>? deviceInstallProgress,
    bool? installTrackingCompleted,
    bool? isUploadInProgress,
    bool? isSocketTrackingInProgress,
  }) {
    return FirmwareUpdateViewModelState(
      uiState: uiState ?? this.uiState,
      isProgressExpanded: isProgressExpanded ?? this.isProgressExpanded,
      progress: progress ?? this.progress,
      inUseVersion: inUseVersion ?? this.inUseVersion,
      availableVersion: availableVersion ?? this.availableVersion,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      bundleId: bundleId ?? this.bundleId,
      downloadChecksum: downloadChecksum ?? this.downloadChecksum,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      errorText: errorText ?? this.errorText,
      desktopVersion: desktopVersion ?? this.desktopVersion,
      deviceInstallProgress: deviceInstallProgress ?? this.deviceInstallProgress,
      installTrackingCompleted: installTrackingCompleted ?? this.installTrackingCompleted,
      isUploadInProgress: isUploadInProgress ?? this.isUploadInProgress,
      isSocketTrackingInProgress: isSocketTrackingInProgress ?? this.isSocketTrackingInProgress,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    uiState,
    isProgressExpanded,
    progress,
    inUseVersion,
    availableVersion,
    releaseNotes,
    bundleId,
    downloadChecksum,
    downloadedFilePath,
    errorText,
    desktopVersion,
    deviceInstallProgress,
    installTrackingCompleted,
    isUploadInProgress,
    isSocketTrackingInProgress,
  ];
}

enum FirmwareCheckDecisionState {
  noUpdate,
  appUpdateRequired,
  updateAvailable,
  downloaded,
  installed,
  failed,
}

class FirmwareCheckDecision {
  final FirmwareCheckDecisionState state;
  final String errorText;
  final String availableVersion;
  final String bundleId;
  final String releaseNotes;
  final bool clearDownloadedCache;

  const FirmwareCheckDecision({
    required this.state,
    this.errorText = '',
    this.availableVersion = '',
    this.bundleId = '',
    this.releaseNotes = '',
    this.clearDownloadedCache = false,
  });
}

class FirmwareLocalState {
  final String inUseVersion;
  final String availableVersion;
  final String downloadChecksum;
  final String downloadedFilePath;

  const FirmwareLocalState({
    required this.inUseVersion,
    required this.availableVersion,
    required this.downloadChecksum,
    required this.downloadedFilePath,
  });
}
