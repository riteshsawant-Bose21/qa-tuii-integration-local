import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

String _normalizeSerialKey(String raw) => raw.trim().toLowerCase();

/// Full software update orchestration with manual phase gates, rollback,
/// typed errors, and background transfer support.
///
/// FLOW & BUTTON MAPPING
/// ─────────────────────────────────────────────────────────────────────────────
///
///  ┌─────────────────────────────────────────────────────────────────────────┐
///  │ Phase          │ Trigger                  │ Buttons shown               │
///  ├─────────────────────────────────────────────────────────────────────────┤
///  │ idle           │ —                        │ [Check for Updates]         │
///  │ checking       │ checkForUpdates()        │ —  (spinner)                │
///  │ awaitDownload  │ auto after check         │ [Download]  [Cancel]        │
///  │ downloading    │ confirmDownload()        │ [Pause] [Cancel]            │
///  │ awaitInstall   │ auto after download      │ [Install]   [Cancel]        │
///  │ discovering    │ confirmInstall()         │ —  (spinner)                │
///  │ uploading      │ auto after discover      │ [Cancel]                    │
///  │ installing     │ auto after upload        │ [Cancel]                    │
///  │ rebooting      │ auto from WS event       │ —  (spinner)                │
///  │ completed      │ auto                     │ [Done]                      │
///  │ failed         │ on any error             │ [Retry / Re-download] or    │
///  │                │                          │ "Contact support"           │
///  │ cancelled      │ cancel()                 │ [Check for Updates]         │
///  │ rollingBack    │ rollback()               │ —  (spinner)                │
///  │ rolledBack     │ auto                     │ [Check for Updates]         │
///  └─────────────────────────────────────────────────────────────────────────┘
///
/// GATE MECHANISM
/// ─────────────────────────────────────────────────────────────────────────────
/// Phases that require user confirmation park the pipeline in an
/// "await*" state by awaiting a Completer.  The matching confirm*() method
/// resolves that Completer, unblocking the pipeline.
///
///   await confirmDownload()  ← tapping the Download button
///   await confirmInstall()   ← tapping the Install button
///
/// ROLLBACK
/// ─────────────────────────────────────────────────────────────────────────────
/// Available once the .swu file has been uploaded (phase ≥ uploading).
/// Calls the rollback API endpoint; on success emits [rolledBack].
/// The rollback endpoint URL is optional in config — if not set, the button
/// should be hidden in the UI.

// ═══════════════════════════════════════════════════════════════════════════════
// 1. TYPED ERROR MODEL
// ═══════════════════════════════════════════════════════════════════════════════

enum UpdateErrorCode {
  checkingFailed,
  versionMismatch,

  missingField,
  invalidFileType,
  checksumMismatch, // re-download needed
  fileTooLarge,
  syncTimeout, // retryable
  notFound, // retry from discover

  noDevicesFound,
  updateCheckFailed,

  downloadFailed,
  uploadFailed,
  rollbackFailed,

  wsConnectionFailed,
  wsDeviceFailed,
  wsClosedEarly,

  networkError,
  unknown,
}

class UpdateError {
  final UpdateErrorCode code;
  final String message;
  final int? httpStatus;
  final bool isRetryable;
  final String? retryLabel; // null → show "Contact support"

  const UpdateError({
    required this.code,
    required this.message,
    this.httpStatus,
    required this.isRetryable,
    this.retryLabel,
  });

  factory UpdateError.fromApiResponse({required int? httpStatus, required dynamic responseData}) {
    final Map<String, dynamic>? body = responseData is Map<String, dynamic> ? responseData : null;
    final String? errorCode = body?['error'] as String?;
    final String message = body?['message'] as String? ?? 'Unknown error (HTTP $httpStatus)';

    return switch (errorCode) {
      'missing_field' => UpdateError(code: UpdateErrorCode.missingField, message: message, httpStatus: httpStatus, isRetryable: false),
      'invalid_file_type' => UpdateError(code: UpdateErrorCode.invalidFileType, message: message, httpStatus: httpStatus, isRetryable: false),
      'checksum_mismatch' => UpdateError(
        code: UpdateErrorCode.checksumMismatch,
        message: message,
        httpStatus: httpStatus,
        isRetryable: true,
        retryLabel: 'Re-download & retry',
      ),
      'file_too_large' => UpdateError(code: UpdateErrorCode.fileTooLarge, message: message, httpStatus: httpStatus, isRetryable: false),
      'sync_timeout' => UpdateError(code: UpdateErrorCode.syncTimeout, message: message, httpStatus: httpStatus, isRetryable: true, retryLabel: 'Retry upload'),
      'not_found' => UpdateError(code: UpdateErrorCode.notFound, message: message, httpStatus: httpStatus, isRetryable: true, retryLabel: 'Retry'),
      _ => _fallbackForStatus(httpStatus, message),
    };
  }

  static UpdateError _fallbackForStatus(int? status, String message) {
    if (status == null) {
      return const UpdateError(
        code: UpdateErrorCode.networkError,
        message: 'No response from cloud. Check your connection.',
        isRetryable: true,
        retryLabel: 'Retry',
      );
    }
    if (status >= 500) {
      return UpdateError(
        code: UpdateErrorCode.unknown,
        message: 'Server error (HTTP $status): $message',
        httpStatus: status,
        isRetryable: true,
        retryLabel: 'Retry',
      );
    }
    return UpdateError(code: UpdateErrorCode.unknown, message: 'Unexpected error (HTTP $status): $message', httpStatus: status, isRetryable: false);
  }

  UpdateError copyWith({UpdateErrorCode? code}) => UpdateError(
    code: code ?? this.code,
    message: message,
    httpStatus: httpStatus,
    isRetryable: isRetryable,
    retryLabel: retryLabel,
  );

  @override
  String toString() => 'UpdateError(${code.name}, HTTP $httpStatus: $message)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. PHASE & STATE
// ═══════════════════════════════════════════════════════════════════════════════

enum UpdatePhase {
  idle,
  checking,
  awaitDownload, // ← GATE: pipeline paused, waiting for confirmDownload()
  downloading,
  awaitInstall, // ← GATE: pipeline paused, waiting for confirmInstall()
  discovering,
  uploading,
  installing,
  rebooting,
  completed,
  failed,
  cancelled,
  rollingBack,
  rolledBack,
}

extension UpdatePhaseX on UpdatePhase {
  /// True when rollback is meaningful (file has been uploaded to the device).
  bool get canRollback {
    return index >= UpdatePhase.uploading.index && index < UpdatePhase.completed.index && this != UpdatePhase.rollingBack && this != UpdatePhase.rolledBack;
  }
}

class UpdateState {
  final UpdatePhase phase;

  // Load these at the start of the pipeline to have them ready for the check
  // and to populate the UI during the process.  They won't update if devices
  // come online mid-update, but that's an edge case we can ignore for now.
  final List<FusionNetworkDevice> fusionNetworkDevices;

  // Phase 1
  final String? availableVersion;
  final BundleDownloadUrlResult? downloadResult;
  final String? releaseNotes;
  final String? bundleId;
  final bool appUpdateRequired;
  final String? minDesktopAppVersion;
  final bool updateAvailable;

  // Phase 2
  final double downloadProgress;

  // Phase 3
  final List<String> deviceSerialNumbers;

  // Phase 4
  final double uploadProgress;

  // Phase 5
  final Map<String, DeviceUpdateProgressEvent> deviceProgress;
  final Set<String> devicesRebooted;
  final bool isUploadInProgress;
  final bool isSocketTrackingInProgress;
  final bool isWaitingForSocketResponse;
  final bool isRebootTrackingInProgress;

  // Error
  final UpdateError? error;
  final UpdatePhase? failedPhase;

  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.availableVersion,
    this.downloadResult,
    this.releaseNotes,
    this.bundleId,
    this.appUpdateRequired = false,
    this.minDesktopAppVersion,
    this.updateAvailable = false,
    this.downloadProgress = 0,
    this.deviceSerialNumbers = const <String>[],
    this.uploadProgress = 0,
    this.deviceProgress = const <String, DeviceUpdateProgressEvent>{},
    this.fusionNetworkDevices = const <FusionNetworkDevice>[],
    this.isUploadInProgress = false,
    this.isSocketTrackingInProgress = false,
    this.isWaitingForSocketResponse = false,
    this.isRebootTrackingInProgress = false,
    this.devicesRebooted = const <String>{},
    this.error,
    this.failedPhase,
  });

  bool get isTerminal => phase == UpdatePhase.completed || phase == UpdatePhase.failed || phase == UpdatePhase.cancelled || phase == UpdatePhase.rolledBack;
  bool get isActive => !isTerminal && phase != UpdatePhase.idle;
  bool get canRetry => phase == UpdatePhase.failed && (error?.isRetryable ?? false);

  /// Whether the Download button should be shown and enabled.
  bool get showDownloadButton => phase == UpdatePhase.awaitDownload;

  /// Whether the Install button should be shown and enabled.
  bool get showInstallButton => phase == UpdatePhase.awaitInstall;

  /// Whether Cancel is meaningful right now.
  bool get showCancelButton => isActive && phase != UpdatePhase.rebooting && phase != UpdatePhase.rollingBack;

  /// Whether Pause/Resume for download is available.
  bool get showPauseButton => phase == UpdatePhase.downloading;

  /// Whether the Rollback button should be offered.
  bool get showRollbackButton => phase.canRollback || (phase == UpdatePhase.failed && error?.code == UpdateErrorCode.versionMismatch);

  bool get allDevicesCompleted =>
      deviceSerialNumbers.isNotEmpty && deviceSerialNumbers.every((String serialNumber) => deviceProgress[serialNumber]?.isCompleted == true);

  UpdateState copyWith({
    UpdatePhase? phase,
    String? availableVersion,
    BundleDownloadUrlResult? downloadResult,
    String? releaseNotes,
    String? bundleId,
    bool? appUpdateRequired,
    String? minDesktopAppVersion,
    bool? updateAvailable,
    double? downloadProgress,
    List<String>? deviceSerialNumbers,
    double? uploadProgress,
    Map<String, DeviceUpdateProgressEvent>? deviceProgress, // serialNumber : progress
    List<FusionNetworkDevice>? fusionNetworkDevices,
    bool? isUploadInProgress,
    bool? isSocketTrackingInProgress,
    bool? isWaitingForSocketResponse,
    bool? isRebootTrackingInProgress,
    Set<String>? devicesRebooted,
    UpdateError? error,
    UpdatePhase? failedPhase,
    bool clearError = false,
    bool clearFailedPhase = false,
  }) => UpdateState(
    phase: phase ?? this.phase,
    availableVersion: availableVersion ?? this.availableVersion,
    downloadResult: downloadResult ?? this.downloadResult,
    releaseNotes: releaseNotes ?? this.releaseNotes,
    bundleId: bundleId ?? this.bundleId,
    appUpdateRequired: appUpdateRequired ?? this.appUpdateRequired,
    minDesktopAppVersion: minDesktopAppVersion ?? this.minDesktopAppVersion,
    updateAvailable: updateAvailable ?? this.updateAvailable,
    downloadProgress: downloadProgress ?? this.downloadProgress,
    deviceSerialNumbers: deviceSerialNumbers ?? this.deviceSerialNumbers,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    deviceProgress: deviceProgress ?? this.deviceProgress,
    fusionNetworkDevices: fusionNetworkDevices ?? this.fusionNetworkDevices,
    isUploadInProgress: isUploadInProgress ?? this.isUploadInProgress,
    isSocketTrackingInProgress: isSocketTrackingInProgress ?? this.isSocketTrackingInProgress,
    isWaitingForSocketResponse: isWaitingForSocketResponse ?? this.isWaitingForSocketResponse,
    isRebootTrackingInProgress: isRebootTrackingInProgress ?? this.isRebootTrackingInProgress,
    devicesRebooted: devicesRebooted ?? this.devicesRebooted,
    error: clearError ? null : (error ?? this.error),
    failedPhase: clearFailedPhase ? null : (failedPhase ?? this.failedPhase),
  );

  @override
  String toString() {
    return 'UpdateState($phase, dl=${(downloadProgress * 100).toStringAsFixed(0)}%, ul=${(uploadProgress * 100).toStringAsFixed(0)}%, devices=${deviceSerialNumbers.length}, err=${error?.code.name})';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. INTERNAL EXCEPTION
// ═══════════════════════════════════════════════════════════════════════════════

class _UpdateException implements Exception {
  final UpdateError error;
  const _UpdateException(this.error);
  @override
  String toString() => error.toString();
}

class _RebootCheckResult {
  final Map<String, DeviceUpdateProgressEvent> deviceProgress;
  final bool hasUpdateProcessing;
  final bool allSucceeded;

  const _RebootCheckResult({
    required this.deviceProgress,
    required this.hasUpdateProcessing,
    required this.allSucceeded,
  });
}

class _SwUpdateInfoDevice {
  final String serialNumber;
  final String currentBundleVersion;
  final String previousBundleVersion;
  final String status;
  final String currentState;
  final String error;

  const _SwUpdateInfoDevice({
    required this.serialNumber,
    required this.currentBundleVersion,
    required this.previousBundleVersion,
    required this.status,
    required this.currentState,
    required this.error,
  });

  bool get isSuccess => status.toUpperCase() == 'SUCCESS' && error.isEmpty;
  bool get isUpdateProcessing => currentState.toUpperCase() == 'UPDATE_PROCESSING';

  factory _SwUpdateInfoDevice.fromJson(Map<String, dynamic> json) {
    return _SwUpdateInfoDevice(
      serialNumber: _normalizeSerialKey(json['serial_number'] as String? ?? ''),
      currentBundleVersion: (json['current_bundle_version'] as String? ?? '').trim(),
      previousBundleVersion: (json['previous_bundle_version'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      currentState: (json['current_state'] as String? ?? '').trim(),
      error: (json['error'] as String? ?? '').trim(),
    );
  }
}

class _SwUpdateInfoResponse {
  final String id;
  final String type;
  final List<_SwUpdateInfoDevice> data;

  const _SwUpdateInfoResponse({
    required this.id,
    required this.type,
    required this.data,
  });

  factory _SwUpdateInfoResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    final List<dynamic> list = rawData is List<dynamic> ? rawData : <dynamic>[];

    return _SwUpdateInfoResponse(
      id: (json['id'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? '').trim(),
      data: list.map<_SwUpdateInfoDevice>((dynamic item) => _SwUpdateInfoDevice.fromJson(Map<String, dynamic>.from(item))).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. CONFIG
// ═══════════════════════════════════════════════════════════════════════════════

class SoftwareUpdateConfig {
  final String virtualIp;

  /// Optional: if set, a Rollback button is shown after upload starts.
  /// The service will POST to this URL with no body to trigger rollback.
  final String? rollbackUrl;

  final Duration rebootPollInterval;
  final Duration rebootTimeout;

  const SoftwareUpdateConfig({
    required this.virtualIp,
    this.rollbackUrl,
    this.rebootPollInterval = const Duration(seconds: 10),
    this.rebootTimeout = const Duration(minutes: 3),
  });

  bool get supportsRollback => rollbackUrl != null;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. SERVICE
// ═══════════════════════════════════════════════════════════════════════════════

class SoftwareUpdateService {
  SoftwareUpdateService._(this._config, this._networkClient) {
    dev.log('[SoftwareUpdateService] Instance created', name: 'SoftwareUpdateService');
  }

  static SoftwareUpdateService? _instance;

  static SoftwareUpdateService get instance {
    assert(_instance != null, 'Call SoftwareUpdateService.init() first.');
    return _instance!;
  }

  static void init(SoftwareUpdateConfig config, FusionNetworkClient networkClient) {
    _instance ??= SoftwareUpdateService._(config, networkClient);
    unawaited(_instance!._initCacheDir());
    dev.log('[SoftwareUpdateService] Initialized', name: 'SoftwareUpdateService');
  }

  AppCacheService? _softwareUpdateCacheDir;
  final SoftwareUpdateConfig _config;
  final FusionNetworkClient _networkClient;

  UpdateState _state = const UpdateState();
  final StreamController<UpdateState> _ctrl = StreamController<UpdateState>.broadcast();

  bool _cancelled = false;

  // ── Gate completers ──────────────────────────────────────────────────────────
  // Each gate is a Completer the pipeline awaits.  The user action resolves it.
  Completer<void>? _downloadGate;
  Completer<void>? _installGate;

  // ── WS resources ─────────────────────────────────────────────────────────────
  StreamSubscription<ResponseCallback<dynamic>>? _wsSub;
  String get wsHost => "ws://${_config.virtualIp.contains(':') ? _config.virtualIp : '${_config.virtualIp}:8080'}/ws";

  // ── Upload cancel token ───────────────────────────────────────────────────────
  CancelToken? _uploadCancelToken;
  CancelToken? _downloadCancelToken;
  String? _rollbackBundleVersion;
  bool _downloadPaused = false;
  Completer<void>? _downloadResumeGate;

  static const Duration _initialRebootSocketDelay = Duration(seconds: 30);
  static const Duration _installSocketRetryDelay = Duration(seconds: 5);
  static const String _swUpdateInfoRequestIdPrefix = 'req';

  int _swUpdateInfoRequestCounter = 0;

  // ── Public API ───────────────────────────────────────────────────────────────

  UpdateState get state => _state;
  Stream<UpdateState> get stream => _ctrl.stream;

  // ── Entry points ─────────────────────────────────────────────────────────────

  /// Step 1: check for an available update.
  /// On success, parks in [awaitDownload] until [confirmDownload] is called.
  Future<void> checkForUpdates() async {
    if (_state.isActive) return;
    _cancelled = false;
    await _runPipeline(fromPhase: UpdatePhase.checking);
  }

  /// Step 2 (button): user taps "Download".
  /// No-op if not currently waiting for download confirmation.
  void confirmDownload() {
    if (_state.phase != UpdatePhase.awaitDownload) return;
    _downloadGate?.complete();
    dev.log('[SoftwareUpdateService] Download confirmed', name: 'SoftwareUpdateService');
  }

  /// Step 3 (button): user taps "Install".
  /// No-op if not currently waiting for install confirmation.
  void confirmInstall() {
    if (_state.phase != UpdatePhase.awaitInstall) return;
    _installGate?.complete();
    dev.log('[SoftwareUpdateService] Install confirmed', name: 'SoftwareUpdateService');
  }

  /// Pause the background download (only useful in [downloading] phase).
  void pauseDownload() {
    if (_state.phase != UpdatePhase.downloading) return;
    if (_downloadCancelToken == null) return;
    _downloadPaused = true;
    _downloadCancelToken?.cancel('paused');
  }

  /// Resume a paused background download.
  void resumeDownload() {
    if (!_downloadPaused) return;
    _downloadPaused = false;
    _downloadResumeGate?.complete();
  }

  /// Cancel everything.  Safe to call at any phase.
  Future<void> cancel() async {
    _cancelled = true;
    // Unblock any waiting gate so the pipeline can reach the cancellation check.
    _downloadGate?.complete();
    _installGate?.complete();
    await _cleanup();
    _emit(_state.copyWith(phase: UpdatePhase.cancelled));
    dev.log('[SoftwareUpdateService] Cancelled', name: 'SoftwareUpdateService');
  }

  /// Retry the failed phase with smart re-entry logic.
  Future<void> retryPhase() async {
    if (!_state.canRetry) return;
    _cancelled = false;

    UpdatePhase resumeFrom = _state.failedPhase!;
    final UpdateErrorCode? code = _state.error?.code;

    // checksumMismatch: the downloaded file is bad — must re-fetch.
    if (code == UpdateErrorCode.checksumMismatch) {
      await _deleteDownloadedSwuFileIfExists();
      resumeFrom = UpdatePhase.downloading;
    }

    // notFound on upload: device state stale — re-discover then re-upload.
    if (code == UpdateErrorCode.notFound && resumeFrom == UpdatePhase.uploading) {
      resumeFrom = UpdatePhase.discovering;
    }

    // Install/socket/reboot tracking failures must restart from install.
    // If we resume from rebooting, the pipeline can skip install steps and
    // incorrectly fall through to completed.
    if (code == UpdateErrorCode.wsConnectionFailed ||
        code == UpdateErrorCode.wsDeviceFailed ||
        code == UpdateErrorCode.wsClosedEarly ||
        code == UpdateErrorCode.syncTimeout) {
      resumeFrom = UpdatePhase.installing;
    }

    await _runPipeline(fromPhase: resumeFrom);
  }

  /// Rollback: revert the software update on the device.
  ///
  /// Available when [state.showRollbackButton] is true.
  /// Emits [rollingBack] → [rolledBack] on success, or [failed] on error.
  Future<void> rollback() async {
    final String rollbackVersion = (_rollbackBundleVersion ?? '').trim();
    if (rollbackVersion.isEmpty) {
      _emit(
        _state.copyWith(
          phase: UpdatePhase.failed,
          error: const UpdateError(
            code: UpdateErrorCode.rollbackFailed,
            message: 'Rollback version is not available from device update info.',
            isRetryable: false,
          ),
          failedPhase: UpdatePhase.rollingBack,
        ),
      );
      return;
    }

    _cancelled = false;
    _downloadGate?.complete();
    _installGate?.complete();
    _downloadResumeGate?.complete();
    await _cleanup();

    _emit(
      _state.copyWith(
        phase: UpdatePhase.rollingBack,
        availableVersion: rollbackVersion,
        downloadResult: null,
        downloadProgress: 0,
        uploadProgress: 0,
        isUploadInProgress: false,
        isSocketTrackingInProgress: false,
        isWaitingForSocketResponse: false,
        isRebootTrackingInProgress: false,
        clearError: true,
        clearFailedPhase: true,
      ),
    );

    await _runPipeline(fromPhase: UpdatePhase.downloading);
  }

  Future<void> _reloadFusionDevices() async {
    dev.log('[SoftwareUpdateService] Reloading Fusion devices from ${_config.virtualIp}', name: 'SoftwareUpdateService');
    try {
      final ResponseCallback<List<FusionNetworkDevice>> response = await _networkClient.get(
        api: FusionApiEndpoint.fusionDevice,
        baseUrlToOverride: _config.virtualIp,
        isSecure: false,
        fromJson: (dynamic json) {
          return List<FusionNetworkDevice>.from((json as List<dynamic>).map((dynamic e) => FusionNetworkDevice.fromJson(e as Map<String, dynamic>)));
        },
      );

      if (response.success) {
        _emit(_state.copyWith(fusionNetworkDevices: response.data ?? <FusionNetworkDevice>[]));
        dev.log('[SoftwareUpdateService] Loaded ${response.data?.length ?? 0} device(s)', name: 'SoftwareUpdateService');
      } else {
        throw _UpdateException(
          UpdateError(
            code: UpdateErrorCode.checkingFailed,
            message: 'Unable to reach Fusion server at ${_config.virtualIp}. Ensure the device is powered on and connected to the network.',
            httpStatus: response.statusCode,
            isRetryable: true,
            retryLabel: 'Retry',
          ),
        );
      }
    } on _UpdateException {
      rethrow;
    } on DioException catch (e) {
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.checkingFailed,
          message: 'Fusion server request failed: ${e.message}',
          isRetryable: true,
          retryLabel: 'Retry',
        ),
      );
    } catch (e) {
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.checkingFailed,
          message: 'Unexpected error while connecting to Fusion server: $e',
          isRetryable: true,
          retryLabel: 'Retry',
        ),
      );
    }
  }

  // ── Pipeline ─────────────────────────────────────────────────────────────────

  Future<void> _runPipeline({required UpdatePhase fromPhase}) async {
    try {
      // Load the latest device list to ensure we have the freshest data for the
      // update check and to populate the UI during the update process.
      await _reloadFusionDevices();

      // Phase 1: check
      if (fromPhase.index <= UpdatePhase.checking.index) {
        await _phase1Check();
        if (_cancelled || !_state.updateAvailable) return;
      }

      // GATE A: wait for Download button
      if (fromPhase.index <= UpdatePhase.awaitDownload.index) {
        await _gateAwaitDownload();
        if (_cancelled) return;
      }

      // Phase 2: download
      if (fromPhase.index <= UpdatePhase.downloading.index) {
        await _phase2Download();
        if (_cancelled) return;
      }

      // GATE B: wait for Install button
      if (fromPhase.index <= UpdatePhase.awaitInstall.index) {
        await _gateAwaitInstall();
        if (_cancelled) return;
      }

      // Phase 3: discover
      if (fromPhase.index <= UpdatePhase.discovering.index) {
        await _phase3Discover();
        if (_cancelled) return;
      }

      // Phase 4: upload
      if (fromPhase.index <= UpdatePhase.uploading.index) {
        await _phase4Upload();
        if (_cancelled) return;
      }

      // Phase 5: install via WS
      if (fromPhase.index <= UpdatePhase.installing.index) {
        await _phase5Install();
        if (_cancelled) return;
      }

      _emit(_state.copyWith(phase: UpdatePhase.completed));
      dev.log('[SoftwareUpdateService] Update completed ✓', name: 'SoftwareUpdateService');
    } on _UpdateException catch (e) {
      if (_cancelled) return;
      dev.log('[SoftwareUpdateService] ✗ ${e.error}', name: 'SoftwareUpdateService');
      _emit(
        _state.copyWith(
          phase: UpdatePhase.failed,
          error: e.error,
          failedPhase: _state.phase,
        ),
      );
    } catch (e, st) {
      if (_cancelled) return;
      dev.log('[SoftwareUpdateService] ✗ Unexpected: $e\n$st', name: 'SoftwareUpdateService');
      _emit(
        _state.copyWith(
          phase: UpdatePhase.failed,
          error: UpdateError(code: UpdateErrorCode.unknown, message: e.toString(), isRetryable: true, retryLabel: 'Retry'),
          failedPhase: _state.phase,
        ),
      );
    }
  }

  // ── Gate implementations ─────────────────────────────────────────────────────

  Future<void> _gateAwaitDownload() async {
    _downloadGate = Completer<void>();
    _emit(_state.copyWith(phase: UpdatePhase.awaitDownload));
    dev.log('[SoftwareUpdateService] Waiting for Download confirmation...', name: 'SoftwareUpdateService');
    await _downloadGate!.future;
    _downloadGate = null;
    _assertNotCancelled();
  }

  Future<void> _gateAwaitInstall() async {
    _installGate = Completer<void>();
    _emit(_state.copyWith(phase: UpdatePhase.awaitInstall));
    dev.log('[SoftwareUpdateService] Waiting for Install confirmation...', name: 'SoftwareUpdateService');
    await _installGate!.future;
    _installGate = null;
    _assertNotCancelled();
  }

  // ── Phase 1: Check ───────────────────────────────────────────────────────────

  Future<void> _phase1Check() async {
    dev.log('[SoftwareUpdateService] Checking for updates...', name: 'SoftwareUpdateService');
    _emit(_state.copyWith(phase: UpdatePhase.checking));

    late ResponseCallback<FirmwareUpdateCheckResult> response;
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentDesktopAppVersion = packageInfo.version;

      final List<FusionNetworkDevice> fusionNetworkDevices = state.fusionNetworkDevices;
      final FusionNetworkDevice? primaryDevice = fusionNetworkDevices.firstWhereOrNull((FusionNetworkDevice? d) => d?.isPrimary == true);
      _assertFleetMatchesPrimaryVersion(fusionNetworkDevices: fusionNetworkDevices, primaryDevice: primaryDevice);

      dev.log("primaryDevice?.primaryDeviceVersion.  ${primaryDevice?.primaryDeviceVersion}.   ===. ${primaryDevice?.softwareUpdateVersion}");

      response = await _networkClient.get<FirmwareUpdateCheckResult>(
        api: FusionApiEndpoint.firmwareUpdateCheck,
        urlParameters: <String, dynamic>{
          'current_firmware_version': primaryDevice?.primaryDeviceVersion,
          'current_desktop_app_version': currentDesktopAppVersion,
        },
        fromJson: (dynamic json) {
          if (json is! Map<String, dynamic>) throw Exception('Unexpected firmware update check response format.');
          return FirmwareUpdateCheckResult.fromJson(json);
        },
      );
    } on DioException catch (e) {
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.networkError,
          message: 'Could not reach update server: ${e.message}',
          isRetryable: true,
          retryLabel: 'Retry',
        ),
      );
    }

    _assertNotCancelled();

    if (response.statusCode != 200) {
      throw _UpdateException(
        UpdateError.fromApiResponse(
          httpStatus: response.statusCode,
          responseData: response.data,
        ).copyWith(code: UpdateErrorCode.updateCheckFailed),
      );
    }

    final bool updateAvailable = response.data?.updateAvailable ?? false;
    final bool appUpdateRequired = response.data?.appUpdateRequired ?? false;
    final String? releaseNotes = response.data?.releaseNotes;
    final String? bundleId = response.data?.bundleId;
    final String? minDesktopAppVersion = response.data?.minDesktopAppVersion;
    final String? version = response.data?.version;

    if (updateAvailable == false) {
      _emit(_state.copyWith(phase: UpdatePhase.idle, updateAvailable: false));
      return;
    }

    if (appUpdateRequired) {
      _emit(
        _state.copyWith(
          phase: UpdatePhase.idle,
          appUpdateRequired: true,
          minDesktopAppVersion: minDesktopAppVersion,
          availableVersion: version,
          releaseNotes: releaseNotes,
          updateAvailable: false,
        ),
      );
      return;
    }

    // Don't advance phase here — _gateAwaitDownload() will emit awaitDownload.
    _emit(
      _state.copyWith(
        updateAvailable: true,
        availableVersion: version,
        releaseNotes: releaseNotes,
        bundleId: bundleId,
        appUpdateRequired: false,
        minDesktopAppVersion: minDesktopAppVersion,
      ),
    );
    dev.log('[SoftwareUpdateService] Update available: v$version', name: 'SoftwareUpdateService');
  }

  void _assertFleetMatchesPrimaryVersion({required List<FusionNetworkDevice> fusionNetworkDevices, required FusionNetworkDevice? primaryDevice}) {
    if (fusionNetworkDevices.isEmpty || primaryDevice == null) {
      return;
    }

    final String primarySerial = primaryDevice.serialNumber.trim();
    final String primaryVersion = primaryDevice.softwareUpdateVersion.trim();

    final List<String> allDevices =
        fusionNetworkDevices.map((FusionNetworkDevice device) {
          final String serial = device.serialNumber.trim().isNotEmpty ? device.serialNumber.trim() : 'unknown';
          final String version = device.softwareUpdateVersion.trim();
          return '${device.name} $serial:${version.isEmpty ? 'unknown' : version}';
        }).toList();

    final List<String> mismatchedDevices =
        fusionNetworkDevices
            .where((FusionNetworkDevice device) {
              final String serial = device.serialNumber.trim();
              if (serial == primarySerial) return false;
              final String deviceVersion = device.softwareUpdateVersion.trim();
              return primaryVersion.isEmpty || deviceVersion.isEmpty || deviceVersion != primaryVersion;
            })
            .map((FusionNetworkDevice device) {
              final String serial = device.serialNumber.trim().isNotEmpty ? device.serialNumber.trim() : 'unknown';
              final String version = device.softwareUpdateVersion.trim();
              return '${device.name} $serial:${version.isEmpty ? 'unknown' : version}';
            })
            .toList();

    if (mismatchedDevices.isEmpty) {
      return;
    }

    final String primaryVersionText = primaryVersion.isEmpty ? 'unknown' : primaryVersion;

    throw _UpdateException(
      UpdateError(
        code: UpdateErrorCode.versionMismatch,
        message:
            'Device versions are mismatching. Primary device $primarySerial is on $primaryVersionText. All devices: ${allDevices.join(', ')}. Mismatched devices: ${mismatchedDevices.join(', ')}.',
        isRetryable: false,
      ),
    );
  }

  // ── Phase 2: Download ────────────────────────────────────────────────────────

  Future<void> _phase2Download() async {
    _downloadPaused = false;
    _downloadResumeGate = null;
    _emit(_state.copyWith(phase: UpdatePhase.downloading, downloadProgress: 0));

    late ResponseCallback<BundleDownloadUrlResult> requestDownloadUrlResponse;

    try {
      if (_state.availableVersion?.isEmpty ?? true) throw Exception("Version is required to get software bundle");

      requestDownloadUrlResponse = await _networkClient.get<BundleDownloadUrlResult>(
        api: FusionApiEndpoint.firmwareBundleDownloadUrl,
        additionalPath: '${_state.availableVersion}/request-download-url',
        fromJson: (dynamic json) {
          if (json is! Map<String, dynamic>) throw Exception('Unexpected firmware bundle download response format.');
          return BundleDownloadUrlResult.fromJson(json);
        },
      );
    } catch (e) {
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.downloadFailed,
          message: e.toString(),
          isRetryable: true,
          retryLabel: 'Retry download',
        ),
      );
    }

    if (!_cancelled) {
      _emit(_state.copyWith(downloadResult: requestDownloadUrlResponse.data));
    }

    dev.log("Download URL response: ${requestDownloadUrlResponse.data?.downloadUrl}");

    final String downloadUrl = requestDownloadUrlResponse.data?.downloadUrl ?? '';
    if (downloadUrl.isEmpty) {
      throw const _UpdateException(
        UpdateError(
          code: UpdateErrorCode.downloadFailed,
          message: 'Bundle download URL is missing.',
          isRetryable: true,
          retryLabel: 'Retry download',
        ),
      );
    }

    final String savePath = _resolvedDownloadPath();

    // If the file already exists at the expected path, skip the download and
    // treat it as already complete so the user can proceed directly to Install.
    if (File(savePath).existsSync()) {
      dev.log('[SoftwareUpdateService] Skipping download — file already exists: $savePath', name: 'SoftwareUpdateService');
      _emit(_state.copyWith(downloadProgress: 1.0));
      return;
    }

    while (true) {
      _downloadCancelToken = CancelToken();
      try {
        await _networkClient.downloadFile(
          url: downloadUrl,
          savePath: savePath,
          cancelToken: _downloadCancelToken!,
          onProgress: (int received, int total) {
            if (!_cancelled && total > 0) {
              _emit(_state.copyWith(downloadProgress: received / total));
            }
          },
        );

        _downloadCancelToken = null;
        _assertNotCancelled();
        _emit(_state.copyWith(downloadProgress: 1.0));
        return;
      } on DioException catch (e) {
        final bool paused = _downloadPaused && CancelToken.isCancel(e);
        _downloadCancelToken = null;

        if (paused) {
          _downloadResumeGate = Completer<void>();
          await _downloadResumeGate!.future;
          _downloadResumeGate = null;
          _assertNotCancelled();
          continue;
        }

        throw _UpdateException(
          UpdateError(
            code: UpdateErrorCode.downloadFailed,
            message: 'Download request failed: ${e.message}',
            isRetryable: true,
            retryLabel: 'Retry download',
          ),
        );
      }
    }
  }

  // ── Phase 3: Discover ────────────────────────────────────────────────────────

  Future<void> _phase3Discover() async {
    _emit(_state.copyWith(phase: UpdatePhase.discovering));

    try {
      await _reloadFusionDevices(); // ensure freshest device data for discovery
    } on DioException catch (e) {
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.networkError,
          message: 'Could not reach local device API: ${e.message}',
          isRetryable: true,
          retryLabel: 'Retry',
        ),
      );
    }

    _assertNotCancelled();

    final List<String> deviceSerialNumbers =
        _state.fusionNetworkDevices.map((FusionNetworkDevice d) => _normalizeSerialKey(d.serialNumber)).where((String s) => s.isNotEmpty).toList();

    if (deviceSerialNumbers.isEmpty) {
      throw const _UpdateException(
        UpdateError(
          code: UpdateErrorCode.noDevicesFound,
          message: 'No devices found on the local network. Ensure devices are powered on and connected.',
          isRetryable: true,
          retryLabel: 'Scan again',
        ),
      );
    }

    final Map<String, DeviceUpdateProgressEvent> initialProgress = <String, DeviceUpdateProgressEvent>{
      for (final FusionNetworkDevice device in _state.fusionNetworkDevices)
        _normalizeSerialKey(device.serialNumber): DeviceUpdateProgressEvent.empty(serialNumber: _normalizeSerialKey(device.serialNumber)),
    };

    _emit(_state.copyWith(deviceSerialNumbers: deviceSerialNumbers, deviceProgress: initialProgress));
    dev.log('[SoftwareUpdateService] Found ${deviceSerialNumbers.length} device(s)', name: 'SoftwareUpdateService');
  }

  // ── Phase 4: Upload ──────────────────────────────────────────────────────────
  // HTTP 409 (already_exists) = file already on device = soft success, continue.

  Future<void> _phase4Upload() async {
    _emit(_state.copyWith(phase: UpdatePhase.uploading, uploadProgress: 0, isUploadInProgress: true));

    // throw error if checksum is missing, since upload will likely fail and there's no point in proceeding without it
    if (_state.downloadResult == null || _state.downloadResult!.checksum.isEmpty) {
      throw const _UpdateException(
        UpdateError(
          code: UpdateErrorCode.checksumMismatch,
          message: 'Missing file checksum. Cannot proceed with upload.',
          isRetryable: false,
        ),
      );
    }

    final String savedPath = _resolvedDownloadPath();
    final String uploadUrl = _networkClient.getApiUrl(
      FusionApiEndpoint.softwareUpdateUpload,
      baseUrlToOverride: _config.virtualIp,
      isSecure: false,
    );

    _uploadCancelToken = CancelToken();

    try {
      final Response<dynamic> response = await _networkClient.httpClient.dioInstance.post<dynamic>(
        uploadUrl,
        cancelToken: _uploadCancelToken,
        data: FormData.fromMap(<String, dynamic>{
          'checksum': _state.downloadResult!.checksum,
          'bundle': await MultipartFile.fromFile(
            savedPath,
            filename: p.basename(savedPath),
          ),
        }),
        onSendProgress: (int sent, int total) {
          if (!_cancelled && total > 0) {
            _emit(_state.copyWith(uploadProgress: sent / total));
          }
        },
        options: Options(validateStatus: (int? status) => status != null),
      );

      _uploadCancelToken = null;
      _assertNotCancelled();

      final int? statusCode = response.statusCode;

      if (statusCode == 409) {
        _emit(_state.copyWith(isUploadInProgress: false));
        dev.log('[SoftwareUpdateService] Upload skipped: already exists (HTTP 409)', name: 'SoftwareUpdateService');
        return;
      }

      if (statusCode != null && statusCode >= 200 && statusCode < 300) {
        _emit(_state.copyWith(isUploadInProgress: false, uploadProgress: 1.0));
        dev.log('[SoftwareUpdateService] Upload accepted', name: 'SoftwareUpdateService');
        return;
      }

      throw _UpdateException(
        UpdateError.fromApiResponse(
          httpStatus: statusCode,
          responseData: response.data,
        ),
      );
    } on DioException catch (e) {
      _uploadCancelToken = null;
      if (CancelToken.isCancel(e)) return; // user cancelled — pipeline handles it
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.uploadFailed,
          message: 'Upload request failed: ${e.message}',
          isRetryable: true,
          retryLabel: 'Retry upload',
        ),
      );
    } catch (e) {
      _uploadCancelToken = null;
      if (e is _UpdateException) rethrow;
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.uploadFailed,
          message: e.toString(),
          isRetryable: true,
          retryLabel: 'Retry upload',
        ),
      );
    }
  }

  // ── Phase 5: Install via WebSocket ───────────────────────────────────────────

  Future<void> _phase5Install() async {
    _emit(
      _state.copyWith(
        phase: UpdatePhase.installing,
        isSocketTrackingInProgress: true,
        isWaitingForSocketResponse: true,
      ),
    );

    final ResponseCallback<void> connect = await _connectInstallWebSocketWithRetry();
    if (!connect.success) {
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.wsConnectionFailed,
          message: connect.message,
          isRetryable: true,
          retryLabel: 'Retry install',
        ),
      );
    }

    // Trigger the update via WS — this will kick off the install process on the service side,
    // which will then stream progress updates back over the socket.
    final ResponseCallback<void> startResponse = await _networkClient.sendWebSocketMessage<void>(<String, dynamic>{
      'id': _state.bundleId ?? _state.availableVersion ?? 'software-update',
      'version': 1,
      'type': 'start_update',
    });

    if (!startResponse.success) {
      throw _UpdateException(
        UpdateError(
          code: UpdateErrorCode.wsConnectionFailed,
          message: startResponse.message,
          isRetryable: true,
          retryLabel: 'Retry install',
        ),
      );
    }

    final Completer<void> completer = Completer<void>();
    await _wsSub?.cancel();

    _wsSub = _networkClient.webSocketMessages.listen(
      (ResponseCallback<dynamic> message) {
        if (_cancelled) {
          if (!completer.isCompleted) completer.complete();
          return;
        }

        if (!message.success || message.data == null) return;

        final dynamic payload = message.data;
        if (payload is! Map<String, dynamic>) return;

        final FirmwareUpdateProgressEvent event = FirmwareUpdateProgressEvent.fromJson(payload);
        if (!event.isUpdateProgress) return;

        _emit(_state.copyWith(isWaitingForSocketResponse: false));
        _handleWsProgressEvent(event, completer);
      },
      onError: (dynamic e) {
        if (!completer.isCompleted) {
          if (_state.allDevicesCompleted) {
            completer.complete();
          } else {
            completer.completeError(
              _UpdateException(
                UpdateError(
                  code: UpdateErrorCode.wsConnectionFailed,
                  message: 'WebSocket error: $e',
                  isRetryable: true,
                  retryLabel: 'Retry install',
                ),
              ),
            );
          }
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          if (_state.allDevicesCompleted) {
            completer.complete();
          } else {
            completer.completeError(
              const _UpdateException(
                UpdateError(
                  code: UpdateErrorCode.wsClosedEarly,
                  message: 'Connection closed before all devices finished.',
                  isRetryable: true,
                  retryLabel: 'Retry install',
                ),
              ),
            );
          }
        }
      },
      cancelOnError: false,
    );

    await completer.future;

    await _wsSub?.cancel();
    _wsSub = null;

    // Clean up the .swu file from disk before rebooting — it has been uploaded
    // to the device and is no longer needed locally.
    final String swuPath = _resolvedDownloadPath();
    try {
      final File swuFile = File(swuPath);
      if (swuFile.existsSync()) {
        swuFile.deleteSync();
        dev.log('[SoftwareUpdateService] Deleted local .swu file: $swuPath', name: 'SoftwareUpdateService');
      }
    } catch (e) {
      dev.log('[SoftwareUpdateService] Warning: could not delete .swu file: $e', name: 'SoftwareUpdateService');
    }

    // Start tracking on REBOOT Devices
    await _trackRebootUntilOnline();

    _emit(
      _state.copyWith(
        isSocketTrackingInProgress: false,
        isWaitingForSocketResponse: false,
        isRebootTrackingInProgress: false,
        phase: UpdatePhase.completed,
      ),
    );
  }

  Future<ResponseCallback<void>> _connectInstallWebSocketWithRetry() async {
    final ResponseCallback<void> connect = await _networkClient.connectWebSocket<void>(url: wsHost);
    if (connect.success) return connect;
    dev.log('[SoftwareUpdateService] Install WS connect failed, retrying in ${_installSocketRetryDelay.inSeconds}s: ${connect.message}');
    await Future<void>.delayed(_installSocketRetryDelay);
    if (_cancelled) return connect;
    return _networkClient.connectWebSocket<void>(url: wsHost);
  }

  void _handleWsProgressEvent(FirmwareUpdateProgressEvent event, Completer<void> completer) {
    final Map<String, DeviceUpdateProgressEvent> merged = Map<String, DeviceUpdateProgressEvent>.from(_state.deviceProgress);

    for (final MapEntry<String, DeviceUpdateProgressEvent> entry in event.devicesBySerial.entries) {
      final DeviceUpdateProgressEvent device = entry.value;
      final String serial = _normalizeSerialKey(device.serialNumber.isNotEmpty ? device.serialNumber : entry.key);

      final DeviceUpdateProgressEvent existing = merged[serial] ?? DeviceUpdateProgressEvent.empty(serialNumber: serial);

      merged[serial] = existing.copyWith(
        serialNumber: serial,
        node: device.node,
        updateState: device.updateState,
        currentTask: device.currentTask,
        handler: device.handler,
        progress: device.progress,
        step: device.step,
        timestamp: device.timestamp,
      );
    }

    final List<DeviceUpdateProgressEvent> all = merged.values.toList();
    final bool failed = all.any((DeviceUpdateProgressEvent d) => d.isFailed);
    final bool completed = all.isNotEmpty && all.every((DeviceUpdateProgressEvent d) => d.isCompleted);

    _emit(_state.copyWith(deviceProgress: merged));

    if (failed && !completer.isCompleted) {
      completer.completeError(
        const _UpdateException(
          UpdateError(
            code: UpdateErrorCode.wsDeviceFailed,
            message: 'At least one device reported failure during update.',
            isRetryable: true,
            retryLabel: 'Retry install',
          ),
        ),
      );
      return;
    }

    if (completed && !completer.isCompleted) completer.complete();
  }

  Future<void> _trackRebootUntilOnline() async {
    _emit(_state.copyWith(phase: UpdatePhase.rebooting, isRebootTrackingInProgress: true));

    // Mark all devices as rebooting to start, so the UI can reflect that immediately while we wait for the first WS update with real progress.
    final Map<String, DeviceUpdateProgressEvent> rebootingDevices = <String, DeviceUpdateProgressEvent>{
      for (final MapEntry<String, DeviceUpdateProgressEvent> entry in _state.deviceProgress.entries)
        entry.key: entry.value.copyWith(updateState: 'REBOOTING', currentTask: 'Waiting for device to reboot...'),
    };

    _emit(_state.copyWith(deviceProgress: rebootingDevices));

    final List<FusionNetworkDevice> expectedDevices = _state.fusionNetworkDevices;
    final Set<String> expectedSerials =
        expectedDevices.map((FusionNetworkDevice d) => _normalizeSerialKey(d.serialNumber)).where((String s) => s.isNotEmpty).toSet();
    if (expectedSerials.isEmpty) {
      _emit(_state.copyWith(isRebootTrackingInProgress: false));
      return;
    }

    final DateTime deadline = DateTime.now().add(_config.rebootTimeout);
    bool delayedFirstTry = false;
    bool sawUpdateProcessing = false;

    while (!_cancelled && DateTime.now().isBefore(deadline)) {
      final Duration remaining = deadline.difference(DateTime.now());
      final Duration delay = delayedFirstTry ? _config.rebootPollInterval : _initialRebootSocketDelay;
      delayedFirstTry = true;

      if (delay > Duration.zero) {
        final Duration cappedDelay = delay < remaining ? delay : remaining;
        await Future<void>.delayed(cappedDelay);
      }

      if (_cancelled || !DateTime.now().isBefore(deadline)) break;

      try {
        // Try to send on the existing connection first. Only disconnect+reconnect
        // if the socket is no longer alive — avoids unnecessary churn when the
        // connection from the install phase is still open.
        final String requestId = _nextSwUpdateInfoRequestId();
        ResponseCallback<void> request = await _networkClient.sendWebSocketMessage<void>(<String, dynamic>{
          'id': requestId,
          'version': 1,
          'type': 'sw_update_info',
        });

        if (!request.success) {
          // Connection dropped — attempt a fresh connect.
          dev.log('[SoftwareUpdateService] WS not connected during reboot check, reconnecting...', name: 'SoftwareUpdateService');

          try {
            await _networkClient.disconnectWebSocket<void>();
          } catch (e) {
            dev.log('[SoftwareUpdateService] WS disconnect before reboot reconnect failed: $e', name: 'SoftwareUpdateService');
          }

          final ResponseCallback<void> connect = await _networkClient.connectWebSocket<void>(url: wsHost);
          if (!connect.success) {
            dev.log('[SoftwareUpdateService] WS reconnect failed during reboot check: ${connect.message}', name: 'SoftwareUpdateService');
            continue;
          }

          request = await _networkClient.sendWebSocketMessage<void>(<String, dynamic>{
            'id': requestId,
            'version': 1,
            'type': 'sw_update_info',
          });

          if (!request.success) {
            continue;
          }
        }

        final List<_SwUpdateInfoDevice> deviceInfo = await _awaitSwUpdateInfoPayload(
          timeout: _config.rebootPollInterval,
          requestId: requestId,
        );

        final _RebootCheckResult rebootCheckResult = _evaluateRebootInfo(deviceInfo: deviceInfo, expectedSerials: expectedSerials);

        _emit(_state.copyWith(deviceProgress: rebootCheckResult.deviceProgress));

        if (rebootCheckResult.hasUpdateProcessing) {
          sawUpdateProcessing = true;
          continue;
        }

        if (rebootCheckResult.allSucceeded) {
          return;
        }
      } catch (_) {
        // Keep retrying until timeout.
      }
    }

    throw _UpdateException(
      UpdateError(
        code: UpdateErrorCode.syncTimeout,
        message: switch (sawUpdateProcessing) {
          true => 'Device reboot timeout: one or more devices stayed in update_processing for more than ${_config.rebootTimeout.inMinutes} minutes.',
          false => 'Device reboot timeout: not all devices reported SUCCESS in time.',
        },
        isRetryable: true,
        retryLabel: 'Retry install',
      ),
    );
  }

  Future<List<_SwUpdateInfoDevice>> _awaitSwUpdateInfoPayload({required Duration timeout, required String requestId}) async {
    final ResponseCallback<dynamic> message = await _networkClient.webSocketMessages
        .firstWhere(
          (ResponseCallback<dynamic> msg) {
            return msg.success && msg.data is Map<String, dynamic> && msg.data['type'] == 'sw_update_info' && msg.data['id'] == requestId;
          },
        )
        .timeout(timeout);

    dev.log('[SoftwareUpdateService] sw_update_info response payload: ${message.data}', name: 'SoftwareUpdateService');
    final List<_SwUpdateInfoDevice> devices = _parseSwUpdateInfoResponse(message.data)?.data ?? <_SwUpdateInfoDevice>[];

    dev.log('[SoftwareUpdateService] Parsed ${devices.length} device(s) from sw_update_info response', name: 'SoftwareUpdateService');
    return devices;
  }

  String _nextSwUpdateInfoRequestId() {
    _swUpdateInfoRequestCounter++;
    return '$_swUpdateInfoRequestIdPrefix-${DateTime.now().microsecondsSinceEpoch}-$_swUpdateInfoRequestCounter';
  }

  _SwUpdateInfoResponse? _parseSwUpdateInfoResponse(dynamic payload) {
    if (payload is! Map<String, dynamic>) return null;
    return _SwUpdateInfoResponse.fromJson(payload);
  }

  _RebootCheckResult _evaluateRebootInfo({required List<_SwUpdateInfoDevice> deviceInfo, required Set<String> expectedSerials}) {
    final Map<String, _SwUpdateInfoDevice> infoBySerial = <String, _SwUpdateInfoDevice>{
      for (final _SwUpdateInfoDevice item in deviceInfo)
        if (item.serialNumber.isNotEmpty) _normalizeSerialKey(item.serialNumber): item,
    };

    final Map<String, DeviceUpdateProgressEvent> updatedProgress = <String, DeviceUpdateProgressEvent>{};
    bool hasUpdateProcessing = false;
    bool allSucceeded = true;

    for (final String serial in expectedSerials) {
      final _SwUpdateInfoDevice? item = infoBySerial[serial];
      final DeviceUpdateProgressEvent existing = _state.deviceProgress[serial] ?? DeviceUpdateProgressEvent.empty(serialNumber: serial);

      final bool isSuccess = item?.isSuccess == true;
      final bool isProcessing = item?.isUpdateProcessing == true;

      if (item == null || !isSuccess) {
        allSucceeded = false;
      }
      if (isProcessing) {
        hasUpdateProcessing = true;
        allSucceeded = false;
      }

      updatedProgress[serial] = existing.copyWith(
        updateState: isSuccess ? 'SUCCESS' : 'REBOOTING',
        currentTask: isSuccess ? 'Device is back online' : (isProcessing ? 'Device update is still processing' : 'Waiting for device to reboot'),
      );
    }

    if (allSucceeded && expectedSerials.isNotEmpty) {
      _assertVersionsFromSwUpdateInfo(infoBySerial: infoBySerial, expectedSerials: expectedSerials);
    }

    return _RebootCheckResult(deviceProgress: updatedProgress, hasUpdateProcessing: hasUpdateProcessing, allSucceeded: allSucceeded);
  }

  void _assertVersionsFromSwUpdateInfo({required Map<String, _SwUpdateInfoDevice> infoBySerial, required Set<String> expectedSerials}) {
    final Map<String, String> currentBySerial = <String, String>{
      for (final String serial in expectedSerials) serial: (infoBySerial[serial]?.currentBundleVersion ?? '').trim(),
    };
    final Map<String, String> previousBySerial = <String, String>{
      for (final String serial in expectedSerials) serial: (infoBySerial[serial]?.previousBundleVersion ?? '').trim(),
    };

    dev.log(
      '[SoftwareUpdateService] Version check — current: $currentBySerial  previous: $previousBySerial',
      name: 'SoftwareUpdateService',
    );

    // Normalize a version string for comparison: strip dots and any build
    // metadata suffix (e.g. "0.1.12-dev.68+abc" → "0112", "0.1.12" → "0112").
    String normalizeVersion(String v) => v.split(RegExp(r'[-+]')).first.replaceAll('.', '');

    // All devices where current == previous means this is a first install
    // (no prior version to upgrade from). Treat as success.
    final bool allFirstInstall = expectedSerials.every((String serial) {
      final String cur = currentBySerial[serial] ?? '';
      final String prev = previousBySerial[serial] ?? '';
      return cur.isNotEmpty && prev.isNotEmpty && normalizeVersion(cur) == normalizeVersion(prev);
    });

    if (allFirstInstall) {
      dev.log('[SoftwareUpdateService] Version check passed (first install — current == previous)', name: 'SoftwareUpdateService');
      _rollbackBundleVersion = null;
      return;
    }

    // Compare normalized current versions against expected.
    final bool hasMissingCurrent = currentBySerial.values.any((String v) => v.isEmpty);
    final Set<String> uniqueCurrentNormalized = currentBySerial.values.where((String v) => v.isNotEmpty).map(normalizeVersion).toSet();

    final String expectedVersion = (_state.availableVersion ?? '').trim();
    final String expectedNormalized = normalizeVersion(expectedVersion);

    final bool matchesExpected =
        expectedNormalized.isEmpty || (!hasMissingCurrent && uniqueCurrentNormalized.length == 1 && uniqueCurrentNormalized.first == expectedNormalized);

    if (!hasMissingCurrent && uniqueCurrentNormalized.length == 1 && matchesExpected) {
      dev.log('[SoftwareUpdateService] Version check passed (current matches expected)', name: 'SoftwareUpdateService');
      _rollbackBundleVersion = null;
      return;
    }

    // Pick the lowest previous version across all devices (by stripping dots and
    // comparing as integers, e.g. "3.4.6"→346, "3.4.5"→345 → pick "3.4.5").
    final List<String> nonEmptyPrevious = previousBySerial.values.where((String v) => v.isNotEmpty).toList();
    final String lowestPrevious =
        nonEmptyPrevious.isEmpty
            ? ''
            : nonEmptyPrevious.reduce((String a, String b) {
              final int aInt = int.tryParse(normalizeVersion(a)) ?? 0;
              final int bInt = int.tryParse(normalizeVersion(b)) ?? 0;
              return aInt <= bInt ? a : b;
            });
    _rollbackBundleVersion = lowestPrevious.trim();

    final String observedCurrent = currentBySerial.entries.map((MapEntry<String, String> e) => '${e.key}:${e.value.isEmpty ? 'unknown' : e.value}').join(', ');
    final String observedPrevious = previousBySerial.entries
        .map((MapEntry<String, String> e) => '${e.key}:${e.value.isEmpty ? 'unknown' : e.value}')
        .join(', ');

    throw _UpdateException(
      UpdateError(
        code: UpdateErrorCode.versionMismatch,
        message:
            'Version verification failed after reboot. Expected all devices on $expectedVersion. Current bundle versions: $observedCurrent. Previous bundle versions: $observedPrevious. Rollback is available.',
        isRetryable: false,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _emit(UpdateState next) {
    if (next.phase != UpdatePhase.failed && (next.error != null || next.failedPhase != null)) {
      next = next.copyWith(clearError: true, clearFailedPhase: true);
    }
    _state = next;
    if (!_ctrl.isClosed) _ctrl.add(next);
  }

  void _assertNotCancelled() {
    if (_cancelled) {
      throw const _UpdateException(
        UpdateError(
          code: UpdateErrorCode.unknown,
          message: 'Cancelled',
          isRetryable: false,
        ),
      );
    }
  }

  String _resolvedDownloadPath() {
    final String url = _state.downloadResult?.downloadUrl ?? '';
    final String fileName = Uri.tryParse(url)?.pathSegments.lastWhere((String s) => s.isNotEmpty, orElse: () => 'update.swu') ?? 'update.swu';
    final String? cacheDirPath = _softwareUpdateCacheDir?.directoryPath;
    if (cacheDirPath == null || cacheDirPath.isEmpty) return fileName;
    return '$cacheDirPath/$fileName';
  }

  Future<void> _deleteDownloadedSwuFileIfExists() async {
    final String swuPath = _resolvedDownloadPath();
    final File swuFile = File(swuPath);
    if (swuFile.existsSync()) {
      await swuFile.delete();
      dev.log('[SoftwareUpdateService] Deleted local .swu file: $swuPath', name: 'SoftwareUpdateService');
    }
  }

  Future<void> _initCacheDir() async {
    if (_softwareUpdateCacheDir != null) return;
    try {
      final AppCacheService appCacheService = await AppCacheService.root();
      _softwareUpdateCacheDir = await appCacheService.scope('firmware_updates');
    } catch (e, st) {
      dev.log('[SoftwareUpdateService] Cache init failed: $e\n$st', name: 'SoftwareUpdateService');
    }
  }

  Future<void> _cleanup() async {
    await _wsSub?.cancel();
    _wsSub = null;
    await _networkClient.disconnectWebSocket<void>();
    _downloadResumeGate?.complete();
    _downloadResumeGate = null;
    _downloadPaused = false;
    _downloadCancelToken?.cancel('cleanup');
    _downloadCancelToken = null;
    _uploadCancelToken?.cancel('cleanup');
    _uploadCancelToken = null;
  }

  Future<void> dispose() async {
    await _cleanup();
    await _ctrl.close();
    // _networkClient is injected (from service locator) — do NOT close it here.
  }
}

//
// ═══════════════════════════════════════════════════════════════════════════════
// 7. SCREEN BUILDER EXAMPLE
// ═══════════════════════════════════════════════════════════════════════════════
//
// BlocBuilder<SoftwareUpdateCubit, UpdateState>(
//   builder: (context, state) {
//     final cubit = context.read<SoftwareUpdateCubit>();
//     return Column(children: [
//
//       // ── Main status area ──────────────────────────────────────────────────
//       switch (state.phase) {
//         UpdatePhase.idle         => Text('Up to date'),
//         UpdatePhase.checking     => CircularProgressIndicator(),
//         UpdatePhase.awaitDownload=> Text('v${state.availableVersion} available'),
//         UpdatePhase.downloading  => LinearProgressIndicator(value: state.downloadProgress),
//         UpdatePhase.awaitInstall => Text('Download complete. Ready to install.'),
//         UpdatePhase.discovering  => Text('Finding devices…'),
//         UpdatePhase.uploading    => LinearProgressIndicator(value: state.uploadProgress),
//         UpdatePhase.installing   => DeviceProgressList(devices: state.deviceProgress),
//         UpdatePhase.rebooting    => Text('Devices rebooting…'),
//         UpdatePhase.completed    => Text('Update complete ✓'),
//         UpdatePhase.failed       => Text(state.error?.message ?? 'Unknown error'),
//         UpdatePhase.cancelled    => Text('Cancelled'),
//         UpdatePhase.rollingBack  => CircularProgressIndicator(),
//         UpdatePhase.rolledBack   => Text('Rolled back'),
//       },
//
//       // ── Action buttons ────────────────────────────────────────────────────
//       Row(children: [
//         // Check / re-check
//         if (!state.isActive && !state.updateAvailable)
//           ElevatedButton(onPressed: cubit.checkForUpdates, child: Text('Check for Updates')),
//
//         // Download (shown only at awaitDownload gate)
//         if (state.showDownloadButton)
//           ElevatedButton(onPressed: cubit.confirmDownload, child: Text('Download')),
//
//         // Pause / Resume download
//         if (state.showPauseButton)
//           ElevatedButton(onPressed: cubit.pauseDownload, child: Text('Pause')),
//
//         // Install (shown only at awaitInstall gate)
//         if (state.showInstallButton)
//           ElevatedButton(onPressed: cubit.confirmInstall, child: Text('Install')),
//
//         // Retry (only when failed + retryable)
//         if (state.canRetry)
//           ElevatedButton(
//             onPressed: cubit.retryPhase,
//             child: Text(state.error?.retryLabel ?? 'Retry'),
//           ),
//
//         // Cancel
//         if (state.showCancelButton)
//           TextButton(onPressed: cubit.cancel, child: Text('Cancel')),
//
//         // Rollback (only when file is on device)
//         if (state.showRollbackButton)
//           OutlinedButton(
//             style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
//             onPressed: cubit.rollback,
//             child: Text('Rollback'),
//           ),
//       ]),
//
//       // No retry available → contact support message
//       if (state.phase == UpdatePhase.failed && !state.canRetry)
//         Text('Please contact support.', style: TextStyle(color: Colors.red)),
//     ]);
//   },
// )
