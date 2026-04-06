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

  const FirmwareCheckDecision({
    required this.state,
    this.errorText = '',
    this.availableVersion = '',
    this.bundleId = '',
    this.releaseNotes = '',
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
