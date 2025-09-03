import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_properties/project_properties_view_model.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_networking/ble/ble_connection_manager.dart';
import 'package:fusion_lib/fusion_networking/ble/commands/fusion_commands.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../../../../core/service_locator.dart';

class VipConfiguration extends StatefulWidget {
  const VipConfiguration({super.key});

  @override
  State<VipConfiguration> createState() => _VipConfigurationState();
}

class _VipConfigurationState extends State<VipConfiguration> {
  final TextEditingController _vipController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isVipConfigured = false;
  String configuredVip = '';
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _vipController.dispose();
    BleConnectionManager().disconnect();
    super.dispose();
  }

  String? _validateIP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a VIP address';
    }

    final RegExp ipRegex = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    if (!ipRegex.hasMatch(value.trim())) {
      return 'Please enter a valid IP address';
    }

    return null;
  }

  void _setVIP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FusionUtils.showLoader(context);
    final ResponseCallback<dynamic> response = await serviceLocator<FusionBleCommands>().updateFusionVIP(_vipController.text.trim());
    FusionUtils.hideLoader(context);
    BleConnectionManager().disconnect();
    if (response.success) {
      serviceLocator<ProjectViewModel>().setVirtualIP(_vipController.text.trim());
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: <Widget>[
          Icon(Icons.settings_ethernet, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            'Virtual IP Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // IP Input Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        controller: _vipController,
                        validator: _validateIP,
                        decoration: InputDecoration(
                          labelText: 'Virtual IP Address',
                          hintText: '192.168.1.100',
                          prefixIcon: Icon(Icons.computer, color: colors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.primary, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.secondary.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.info_outline, color: colors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add static IP of your device. This IP will be used for all further communication with the device, if you don\'t know static IP of your device please contact your IT team.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSecondaryContainer,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: colors.onSurface)),
        ),
        FilledButton(
          onPressed: _setVIP,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: const Text('Set VIP'),
        ),
      ],
    );
  }
}
