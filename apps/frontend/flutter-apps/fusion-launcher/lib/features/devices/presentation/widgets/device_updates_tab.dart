import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/service/auth/fusion_auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum _UpdateViewState {
  checking,
  noUpdate,
  updateAvailable,
  downloading,
  downloaded,
  downloadFailed,
  installing,
  installFailed,
  installed,
}

class _FirmwareUpdateCheckResult {
  final bool updateAvailable;
  final bool appUpdateRequired;
  final String? bundleId;
  final String? version;
  final String? releaseNotes;
  final String? minDesktopAppVersion;

  const _FirmwareUpdateCheckResult({
    required this.updateAvailable,
    required this.appUpdateRequired,
    this.bundleId,
    this.version,
    this.releaseNotes,
    this.minDesktopAppVersion,
  });

  factory _FirmwareUpdateCheckResult.fromJson(Map<String, dynamic> json) {
    return _FirmwareUpdateCheckResult(
      updateAvailable: json['update_available'] as bool? ?? false,
      appUpdateRequired: json['app_update_required'] as bool? ?? false,
      bundleId: json['bundle_id'] as String?,
      version: json['version'] as String?,
      releaseNotes: json['release_notes'] as String?,
      minDesktopAppVersion: json['min_desktop_app_version'] as String?,
    );
  }
}

class _BundleDownloadUrlResult {
  final String downloadUrl;
  final String checksum;

  const _BundleDownloadUrlResult({
    required this.downloadUrl,
    required this.checksum,
  });

  factory _BundleDownloadUrlResult.fromJson(Map<String, dynamic> json) {
    return _BundleDownloadUrlResult(
      downloadUrl: json['download_url'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
    );
  }
}

class _FirmwareCloudApi {
  _FirmwareCloudApi(this._authService, this._dio);

  final FusionAuthService _authService;
  final Dio _dio;

  Future<Map<String, String>> _authHeaders() async {
    final String? token = await _authService.getValidAccessToken();
    if (token == null || token.isEmpty) {
      return <String, String>{};
    }
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  Future<_FirmwareUpdateCheckResult> checkForUpdates({
    required String currentFirmwareVersion,
    required String desktopVersion,
    String? channel,
  }) async {
    final Response<dynamic> response = await _dio.get(
      '${AppConfig.awsApiBaseUrl}/firmware/updates/check',
      queryParameters: <String, dynamic>{
        'current_firmware_version': currentFirmwareVersion,
        'current_desktop_app_version': desktopVersion,
        if (channel != null && channel.isNotEmpty) 'channel': channel,
      },
      options: Options(headers: await _authHeaders()),
    );

    final dynamic data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected update-check response.');
    }

    return _FirmwareUpdateCheckResult.fromJson(data);
  }

  Future<_BundleDownloadUrlResult> getDownloadUrl({required String bundleId}) async {
    final Response<dynamic> response = await _dio.get(
      '${AppConfig.awsApiBaseUrl}/firmware/bundles/$bundleId/request-download-url',
      options: Options(headers: await _authHeaders()),
    );

    final dynamic data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected request-download-url response.');
    }

    return _BundleDownloadUrlResult.fromJson(data);
  }

  Future<void> logInstallStatus({
    required String projectId,
    required String bundleVersion,
    required String previousVersion,
    required String launcherVersion,
    required String status,
  }) async {
    await _dio.post(
      '${AppConfig.awsApiBaseUrl}/firmware/updates/status',
      data: <String, dynamic>{
        'update_id': const Uuid().v4(),
        'project_id': projectId,
        'bundle_version': bundleVersion,
        'previous_version': previousVersion,
        'status': status,
        'launcher_version': launcherVersion,
        'installed_at': DateTime.now().toUtc().toIso8601String(),
      },
      options: Options(headers: await _authHeaders()),
    );
  }

  Future<void> downloadBundle({
    required String downloadUrl,
    required String targetFilePath,
    required CancelToken cancelToken,
    required void Function(int received, int total) onProgress,
  }) async {
    await _dio.download(
      downloadUrl,
      targetFilePath,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );
  }

  Future<void> uploadToFusionServer({
    required String vip,
    required String bundleFilePath,
    required String checksum,
    required CancelToken cancelToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    final String host = vip.contains(':') ? vip : '$vip:8080';
    await _dio.post(
      'http://$host/softwareUpdate/upload',
      cancelToken: cancelToken,
      data: FormData.fromMap(
        <String, dynamic>{
          'checksum': checksum,
          'bundle': await MultipartFile.fromFile(bundleFilePath, filename: p.basename(bundleFilePath)),
        },
      ),
      onSendProgress: onProgress,
    );
  }
}

class DeviceUpdatesTab extends StatefulWidget {
  const DeviceUpdatesTab({super.key});

  @override
  State<DeviceUpdatesTab> createState() => _DeviceUpdatesTabState();
}

class _DeviceUpdatesTabState extends State<DeviceUpdatesTab> {
  static const String _prefsKey = 'firmware_updates_state_v1';

  final _FirmwareCloudApi _api = _FirmwareCloudApi(
    serviceLocator<FusionAuthService>(),
    serviceLocator<FusionNetworkClient>().httpClient.dioInstance,
  );

  _UpdateViewState _state = _UpdateViewState.checking;
  bool _isProgressExpanded = false;
  double _progress = 0;

  String _inUseVersion = '1.2.1';
  String _availableVersion = '';
  String _releaseNotes = '';
  String _bundleId = '';
  String _downloadChecksum = '';
  String _downloadedFilePath = '';
  String _errorText = '';

  CancelToken? _downloadCancelToken;
  CancelToken? _installCancelToken;

  String _desktopVersion = '0.5.0';

  List<HardwareComponent> get _fusionDevices {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    return <HardwareComponent>[
      ...vm.fusionDsps,
      ...vm.amplifiers,
      ...vm.fusionControllers,
      ...vm.fusionEndpoints,
    ];
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _downloadCancelToken?.cancel();
    _installCancelToken?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadDesktopVersion();
    await _restoreState();
    await _checkForUpdates();
  }

  Future<void> _loadDesktopVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _desktopVersion = info.version;
    } catch (_) {
      _desktopVersion = '0.5.0';
    }
  }

  Future<void> _restoreState() async {
    final SharedPreferences prefs = serviceLocator<SharedPreferences>();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      _inUseVersion = json['in_use_version'] as String? ?? _inUseVersion;
      _downloadedFilePath = json['downloaded_file_path'] as String? ?? '';
      _downloadChecksum = json['download_checksum'] as String? ?? '';
      _availableVersion = json['available_version'] as String? ?? '';

      if (_downloadedFilePath.isNotEmpty && !File(_downloadedFilePath).existsSync()) {
        _downloadedFilePath = '';
      }
    } catch (_) {
      // Ignore corrupted local state and continue with fresh state.
    }
  }

  Future<void> _persistState() async {
    final SharedPreferences prefs = serviceLocator<SharedPreferences>();
    await prefs.setString(
      _prefsKey,
      jsonEncode(
        <String, dynamic>{
          'in_use_version': _inUseVersion,
          'available_version': _availableVersion,
          'download_checksum': _downloadChecksum,
          'downloaded_file_path': _downloadedFilePath,
        },
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _state = _UpdateViewState.checking;
      _errorText = '';
    });

    try {
      final _FirmwareUpdateCheckResult result = await _api.checkForUpdates(
        currentFirmwareVersion: _inUseVersion,
        desktopVersion: _desktopVersion,
      );

      if (!mounted) {
        return;
      }

      if (result.appUpdateRequired) {
        setState(() {
          _state = _UpdateViewState.downloadFailed;
          _errorText = 'Launcher update required (min ${result.minDesktopAppVersion ?? 'unknown'}).';
        });
        return;
      }

      if (!result.updateAvailable || (result.version ?? '').isEmpty) {
        setState(() {
          _state = _UpdateViewState.noUpdate;
          _availableVersion = '';
          _bundleId = '';
          _releaseNotes = '';
        });
        return;
      }

      _availableVersion = result.version ?? '';
      _bundleId = result.bundleId ?? '';
      _releaseNotes = result.releaseNotes ?? '';

      if (_inUseVersion == _availableVersion) {
        setState(() => _state = _UpdateViewState.installed);
        return;
      }

      if (_downloadedFilePath.isNotEmpty && File(_downloadedFilePath).existsSync()) {
        setState(() => _state = _UpdateViewState.downloaded);
      } else {
        setState(() => _state = _UpdateViewState.updateAvailable);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _UpdateViewState.downloadFailed;
        _errorText = 'Failed to check updates: $e';
      });
    }
  }

  Future<Directory> _updatesDirectory() async {
    final Directory supportDir = await getApplicationSupportDirectory();
    final Directory updatesDir = Directory(p.join(supportDir.path, 'firmware-updates'));
    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }
    return updatesDir;
  }

  Future<void> _downloadNow() async {
    if (_bundleId.isEmpty) {
      setState(() {
        _state = _UpdateViewState.downloadFailed;
        _errorText = 'Bundle id is missing.';
      });
      return;
    }

    _downloadCancelToken?.cancel();
    _downloadCancelToken = CancelToken();

    setState(() {
      _state = _UpdateViewState.downloading;
      _progress = 0;
      _errorText = '';
    });

    try {
      final _BundleDownloadUrlResult downloadInfo = await _api.getDownloadUrl(bundleId: _bundleId);
      if (downloadInfo.downloadUrl.isEmpty) {
        throw Exception('Cloud did not return a download URL.');
      }

      final Directory dir = await _updatesDirectory();
      final String safeVersion = _availableVersion.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final String targetFilePath = p.join(dir.path, 'bundle_$safeVersion.swu');

      await _api.downloadBundle(
        downloadUrl: downloadInfo.downloadUrl,
        targetFilePath: targetFilePath,
        cancelToken: _downloadCancelToken!,
        onProgress: (int received, int total) {
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _progress = (received / total).clamp(0, 1);
          });
        },
      );

      if (!mounted) {
        return;
      }

      _downloadedFilePath = targetFilePath;
      _downloadChecksum = downloadInfo.checksum;
      await _persistState();

      setState(() {
        _state = _UpdateViewState.downloaded;
        _progress = 1;
      });
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      if (CancelToken.isCancel(e)) {
        setState(() {
          _state = _UpdateViewState.updateAvailable;
          _progress = 0;
        });
        return;
      }

      setState(() {
        _state = _UpdateViewState.downloadFailed;
        _errorText = 'Device Timeout';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _UpdateViewState.downloadFailed;
        _errorText = 'Download failed: $e';
      });
    }
  }

  Future<void> _installNow() async {
    final String? vip = serviceLocator<ProjectViewModel>().virtualIP;
    if (vip == null || vip.isEmpty) {
      setState(() {
        _state = _UpdateViewState.installFailed;
        _errorText = 'Virtual IP is not configured.';
      });
      return;
    }

    if (_downloadedFilePath.isEmpty || !File(_downloadedFilePath).existsSync()) {
      setState(() {
        _state = _UpdateViewState.installFailed;
        _errorText = 'Downloaded file not found.';
      });
      return;
    }

    _installCancelToken?.cancel();
    _installCancelToken = CancelToken();

    final String previousVersion = _inUseVersion;

    setState(() {
      _state = _UpdateViewState.installing;
      _progress = 0;
      _errorText = '';
      _isProgressExpanded = false;
    });

    try {
      await _api.uploadToFusionServer(
        vip: vip,
        bundleFilePath: _downloadedFilePath,
        checksum: _downloadChecksum,
        cancelToken: _installCancelToken!,
        onProgress: (int sent, int total) {
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _progress = (sent / total).clamp(0, 1);
          });
        },
      );

      if (!mounted) {
        return;
      }

      _inUseVersion = _availableVersion;
      _state = _UpdateViewState.installed;
      _progress = 1;
      await _persistState();

      final String projectId = serviceLocator<ProjectViewModel>().projectId;
      await _api.logInstallStatus(
        projectId: projectId,
        bundleVersion: _availableVersion,
        previousVersion: previousVersion,
        launcherVersion: _desktopVersion,
        status: 'INSTALL_SUCCESS',
      );

      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _state = _UpdateViewState.installFailed;
        _errorText = 'Device Timeout';
      });

      try {
        final String projectId = serviceLocator<ProjectViewModel>().projectId;
        await _api.logInstallStatus(
          projectId: projectId,
          bundleVersion: _availableVersion,
          previousVersion: previousVersion,
          launcherVersion: _desktopVersion,
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
    if (_downloadedFilePath.isNotEmpty && File(_downloadedFilePath).existsSync()) {
      setState(() {
        _state = _UpdateViewState.downloaded;
        _errorText = '';
      });
      return;
    }

    setState(() {
      _state = _UpdateViewState.updateAvailable;
      _errorText = '';
    });
  }

  String get _description {
    if (_releaseNotes.trim().isNotEmpty) return _releaseNotes;
    return 'A new update is ready. Download it now to get all the latest features and improvements. '
        'It only takes a moment, and updating ensures everything works smoothly and feels better than before. '
        'Don\'t miss out grab the newest version.';
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _UpdateViewState.noUpdate) {
      return _buildNoUpdateView(context);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                    _buildHeading(context),
                    const SizedBox(height: 10),
                    FusionAppText(
                      text: _description,
                      style: context.textTheme.h6Regular,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              _buildActionPanel(context),
            ],
          ),
          const SizedBox(height: 18),
          if ((_state == _UpdateViewState.installing || _state == _UpdateViewState.installed) && _isProgressExpanded) _buildDeviceProgressTable(context),
          if ((_state == _UpdateViewState.installing || _state == _UpdateViewState.installed) && _isProgressExpanded) const SizedBox(height: 18),
          _buildInUseVersionRow(context),
        ],
      ),
    );
  }

  Widget _buildNoUpdateView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDFDFDF), width: 2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                ':(',
                style: TextStyle(
                  fontSize: 54,
                  color: Color(0xFFDFDFDF),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FusionAppText(
            text: 'Oh no! No new updates available',
            style: context.textTheme.titleMedium?.copyWith(
              color: const Color(0xFFD0D0D0),
              fontSize: 38,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 560,
            child: _buildInUseVersionRow(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeading(BuildContext context) {
    final String version = _availableVersion.isEmpty ? _inUseVersion : _availableVersion;
    final String stateText;
    switch (_state) {
      case _UpdateViewState.updateAvailable:
        stateText = 'available for download';
      case _UpdateViewState.downloading:
        stateText = 'is downloading';
      case _UpdateViewState.downloaded:
        stateText = 'available to install';
      case _UpdateViewState.downloadFailed:
        stateText = 'failed to download';
      case _UpdateViewState.installing:
        stateText = 'is installing';
      case _UpdateViewState.installFailed:
        stateText = 'failed to install';
      case _UpdateViewState.installed:
        stateText = 'is installed successfully';
      case _UpdateViewState.checking:
        stateText = 'is checking';
      case _UpdateViewState.noUpdate:
        stateText = 'is up to date';
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

  Widget _buildActionPanel(BuildContext context) {
    Widget content;

    switch (_state) {
      case _UpdateViewState.updateAvailable:
        content = _buildButton(context, 'Download Now', _downloadNow);
      case _UpdateViewState.downloading:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildProgressCircle(),
            const SizedBox(width: 14),
            _buildButton(context, 'Cancel', _cancelDownload, width: 170),
          ],
        );
      case _UpdateViewState.downloaded:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _buildButton(context, 'Install Now', _installNow),
            const SizedBox(height: 14),
            _buildSuccessLabel('Downloaded Successfully'),
          ],
        );
      case _UpdateViewState.downloadFailed:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
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
            // _buildErrorLabel(_errorText.isEmpty ? 'Device Timeout' : _errorText),
          ],
        );
      case _UpdateViewState.installing:
        content = InkWell(
          onTap: () => setState(() => _isProgressExpanded = !_isProgressExpanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildProgressCircle(),
              const SizedBox(width: 14),
              FusionAppText(
                text: 'View Device Progress',
                style: context.textTheme.b2Medium,
              ),
              const SizedBox(width: 10),
              Icon(
                _isProgressExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                color: const Color(0xFFB9B9B9),
              ),
            ],
          ),
        );
      case _UpdateViewState.installFailed:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
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
            _buildErrorLabel(_errorText.isEmpty ? 'Device Timeout' : _errorText),
          ],
        );
      case _UpdateViewState.installed:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _buildSuccessLabel('Installed Successfully'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _isProgressExpanded = !_isProgressExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FusionAppText(
                    text: 'View Device Progress',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFB9B9B9),
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isProgressExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                    color: const Color(0xFFB9B9B9),
                  ),
                ],
              ),
            ),
          ],
        );
      case _UpdateViewState.checking:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF27B177),
              ),
            ),
            const SizedBox(width: 10),
            FusionAppText(
              text: 'Checking',
              style: context.textTheme.labelMedium?.copyWith(color: const Color(0xFFD0D0D0)),
            ),
          ],
        );
      case _UpdateViewState.noUpdate:
        content = const SizedBox.shrink();
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

  Widget _buildProgressCircle() {
    final int percent = (_progress * 100).round().clamp(0, 100);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            value: _progress,
            strokeWidth: 3,
            backgroundColor: const Color(0xFF3A3A3A),
            color: const Color(0xFF27B177),
          ),
        ),
        FusionAppText(
          text: '$percent%',
          style: const TextStyle(color: Color(0xFFC7C7C7), fontSize: 10),
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
          style: context.textTheme.l1Medium.copyWith(
            color: const Color(0xFFE43333),
          ),
        ),
      ],
    );
  }

  Widget _buildInUseVersionRow(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF313131), width: 1),
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
            text: 'v $_inUseVersion',
            style: context.textTheme.b3Bold,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceProgressTable(BuildContext context) {
    final List<HardwareComponent> devices = _fusionDevices;

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
                Expanded(flex: 1, child: _TableHeaderText('STATUS')),
                Expanded(flex: 3, child: _TableHeaderText('DEVICE NAME')),
                Expanded(flex: 3, child: _TableHeaderText('MODEL')),
                Expanded(flex: 3, child: _TableHeaderText('LOCATION')),
                Expanded(flex: 2, child: _TableHeaderText('IP ADDRESS')),
                Expanded(flex: 2, child: _TableHeaderText('FIRMWARE VERSION')),
                Expanded(flex: 4, child: _TableHeaderText('INSTALLATION PROGRESS')),
              ],
            ),
          ),
          for (int i = 0; i < devices.length; i++) _buildDeviceRow(devices[i], i),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(HardwareComponent device, int index) {
    final double shifted = (_progress * 1.2) - (index * 0.02);
    final double rowProgress = shifted.clamp(0, 0.99);

    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    String location = '--';

    if (device.locationEntity.listeningAreaId != null) {
      final Zone? zone = vm.getZonesForListeningArea(areaId: device.locationEntity.listeningAreaId!);
      if (zone != null) {
        location = zone.name;
      } else {
        final SubZone? subZone = vm.getSubZoneForListeningArea(areaId: device.locationEntity.listeningAreaId!);
        if (subZone != null) {
          location = subZone.name;
        }
      }
    }

    if (location == '--') {
      final EquipLocation? equip = vm.getEquipLocationForHardware(hardwareId: device.id);
      if (equip != null) {
        location = equip.name;
      }
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.circle, color: Color(0xFF5CC59A), size: 10),
            ),
          ),
          Expanded(flex: 3, child: _TableValueText(device.name, color: const Color(0xFF2FA16B), underline: true)),
          Expanded(flex: 3, child: _TableValueText(device.hardwareName)),
          Expanded(flex: 3, child: _TableValueText(location)),
          Expanded(flex: 2, child: _TableValueText('192.168.0.${index + 1}')),
          const Expanded(flex: 2, child: _TableValueText('v1.0.1')),
          Expanded(
            flex: 4,
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
      style: const TextStyle(
        color: Color(0xFF888888),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
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
      style: TextStyle(
        color: color,
        fontSize: 14,
        decoration: underline ? TextDecoration.underline : TextDecoration.none,
      ),
      maxLine: 1,
    );
  }
}
