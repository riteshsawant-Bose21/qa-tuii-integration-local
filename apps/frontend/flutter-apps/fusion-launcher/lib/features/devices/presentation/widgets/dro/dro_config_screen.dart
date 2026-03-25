import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/devices/presentation/widgets/details/device_setting/settings_section_container.dart';
import 'package:fusion_lib/fusion_lib.dart';

class DroConfigScreen extends StatefulWidget {
  const DroConfigScreen({super.key});

  @override
  State<DroConfigScreen> createState() => _DroConfigScreenState();
}

class _DroConfigScreenState extends State<DroConfigScreen> {
  late final TextEditingController _droIpController;

  @override
  void initState() {
    super.initState();
    _droIpController = TextEditingController(
      text: serviceLocator<FusionPreferences>().droServerUrl,
    );
  }

  @override
  void dispose() {
    _droIpController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _droResponse => serviceLocator<ProjectViewModel>().getDroResponse();

  DroResultData? get _droResult {
    final Map<String, dynamic>? response = _droResponse;
    if (response == null) return null;
    try {
      final Map<String, dynamic>? result = response['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      return DroResultData.fromJson(result);
    } catch (e) {
      debugPrint('Failed to parse DRO result: $e');
      return null;
    }
  }

  void _updateDroIp() {
    final String ip = _droIpController.text.trim();
    if (ip.isEmpty) return;
    serviceLocator<FusionPreferences>().setDroServerUrl(ip);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: FusionAppText(text: 'DRO IP updated to $ip'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final DroResultData? result = _droResult;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- DRO IP Address Section ---
              _buildDroIpSection(context),

              const SizedBox(height: 16),

              //button to trigger DRO process - for testing purposes
              SizedBox(
                width: 300,
                child: Row(
                  children: <Widget>[
                    FusionAppText(
                      text: 'Enable Dev Mode',
                      style: TextStyle(
                        color: context.colorScheme.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    FusionSwitch(
                      height: 40,
                      semanticId: 'trigger_dro_process',
                      value: serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.enableDevMode) ?? false,
                      onChanged: (bool value) {
                        serviceLocator<SharedPreferencesHandler>().setBool(SharedPreferenceKeys.enableDevMode, value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- DRO Response Images Section ---
              if (result != null) ...<Widget>[
                _buildImagesSection(context, result),
                const SizedBox(height: 16),

                // --- IO Ports JSON Section ---
                if (result.ioPorts != null && result.ioPorts!.isNotEmpty) _buildIoPortsSection(context, result.ioPorts!),
              ],

              if (result == null)
                SettingsSectionContainer(
                  title: 'DRO RESPONSE',
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: FusionAppText(
                        text: 'No DRO response available. Run a DRO process to see results.',
                        style: TextStyle(
                          color: context.colorScheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the DRO IP address input section
  Widget _buildDroIpSection(BuildContext context) {
    return SettingsSectionContainer(
      title: 'DRO CONFIGURATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: 'DRO IP Address',
            style: TextStyle(
              color: context.colorScheme.textBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              SizedBox(
                child: FusionTextField(
                  semanticFieldId: 'dro_ip_address',
                  controller: _droIpController,
                  hintText: 'Enter DRO IP (e.g. 10.8.50.144:8080)',
                  color: context.colorScheme.elevation2,
                  style: context.textTheme.bodySmall,
                  hintStyle: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  width: 300,
                  onSubmitted: (_) => _updateDroIp(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 36,
                child: FusionButton(
                  accessLabel: 'dro_config_update_ip_button',
                  label: 'Update',
                  activeBackgroundColor: context.colorScheme.primaryWhite,
                  isActive: true,
                  onTap: _updateDroIp,
                ),
              ),
            ],
          ),

          // Row(
          //   children: <Widget>[
          //     SizedBox(
          //       child: FusionTextField(
          //         semanticFieldId: 'vip_address',
          //         hintText: 'Enter VIP (e.g. 10.8.50.144:8080)',
          //         color: context.colorScheme.elevation2,
          //         style: context.textTheme.bodySmall,
          //         hintStyle: context.textTheme.bodySmall?.copyWith(
          //           color: context.colorScheme.textSecondary,
          //         ),
          //         contentPadding: const EdgeInsets.symmetric(
          //           horizontal: 12,
          //           vertical: 12,
          //         ),
          //         width: 300,
          //         onSubmitted: (String vip) {
          //           if (vip.isEmpty) return;
          //           serviceLocator<ProjectViewModel>().setVirtualIP(ip: vip);
          //         },
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  /// Builds the DRO response images section
  Widget _buildImagesSection(BuildContext context, DroResultData result) {
    final bool hasInput = result.imageInput != null && result.imageInput!.isNotEmpty;
    final bool hasOutput = result.imageOutput != null && result.imageOutput!.isNotEmpty;

    return SettingsSectionContainer(
      title: 'DRO DESIGN VISUALIZER',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasInput) ...<Widget>[
            FusionAppText(
              text: 'Input Design',
              style: TextStyle(
                color: context.colorScheme.textBody,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildBase64Image(context, result.imageInput!),
          ],
          if (hasInput && hasOutput) const SizedBox(height: 16),
          if (hasOutput) ...<Widget>[
            FusionAppText(
              text: 'Optimized Design',
              style: TextStyle(
                color: context.colorScheme.textBody,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildBase64Image(context, result.imageOutput!),
          ],
          if (!hasInput && !hasOutput)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: FusionAppText(
                  text: 'No design images available.',
                  style: TextStyle(
                    color: context.colorScheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a base64 decoded image widget with tap-to-expand
  Widget _buildBase64Image(BuildContext context, String base64Data) {
    try {
      final Uint8List imageBytes = base64Decode(base64Data);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colorScheme.strokeLight),
          ),
          child: GestureDetector(
            onTap: () => _showFullScreenImage(context, imageBytes),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FusionAppText(
          text: 'Failed to decode image: $e',
          style: TextStyle(color: context.colorScheme.textSecondary, fontSize: 12),
        ),
      );
    }
  }

  /// Shows the image in a full-screen dialog
  void _showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: <Widget>[
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the IO Ports JSON section
  Widget _buildIoPortsSection(
    BuildContext context,
    List<Map<String, dynamic>> ioPorts,
  ) {
    return SettingsSectionContainer(
      title: 'IO PORTS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < ioPorts.length; i++) ...<Widget>[
            _buildIoPortCard(context, ioPorts[i], i),
            if (i < ioPorts.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// Builds a single IO port card displaying the JSON data
  Widget _buildIoPortCard(
    BuildContext context,
    Map<String, dynamic> ioPort,
    int index,
  ) {
    final String deviceId = ioPort['device_id']?.toString() ?? 'N/A';
    final String ioId = ioPort['io_id']?.toString() ?? 'N/A';
    final String portType = ioPort['port_type']?.toString() ?? 'N/A';
    final List<dynamic> portNums = ioPort['port_nums'] as List<dynamic>? ?? <dynamic>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: 'Port ${index + 1}',
            style: TextStyle(
              color: context.colorScheme.textBody,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildIoPortRow(context, 'Device ID', deviceId),
          const SizedBox(height: 4),
          _buildIoPortRow(context, 'IO ID', ioId),
          const SizedBox(height: 4),
          _buildIoPortRow(context, 'Port Type', portType),
          const SizedBox(height: 4),
          _buildIoPortRow(context, 'Port Numbers', portNums.join(', ')),
        ],
      ),
    );
  }

  /// Builds a single row for IO port data display
  Widget _buildIoPortRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 120,
          child: FusionAppText(
            text: label,
            style: TextStyle(
              color: context.colorScheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: FusionAppText(
            text: value,
            style: TextStyle(
              color: context.colorScheme.textBody,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
