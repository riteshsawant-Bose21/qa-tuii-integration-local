import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../viewModel/configuration_control_state.dart';

/// Virtual Control section — shows a QR code for mobile virtual wall controller access
class VirtualControlSection extends StatelessWidget {
  final String? controllerUrl;
  final ConfigurationControlState state;

  const VirtualControlSection({super.key, this.controllerUrl, required this.state});

  @override
  Widget build(BuildContext context) {
    final String qrData = jsonEncode(<String, String>{
      "vip": serviceLocator<ProjectViewModel>().virtualIP ?? "192.168.1.110",
      // "controller_id": state.selectedControllerId ?? "No Controller ID",
      "controller_id": "CTRL1762958340064766236",
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Section header — shared PanelSectionHeader widget
        const PanelSectionHeader(title: 'VIRTUAL CONTROL'),

        /// QR + description row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildQrCode(context, qrData),
              const SizedBox(width: 18),
              _buildDescription(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode(BuildContext context, String data) {
    return Container(
      width: 158,
      height: 158,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight, width: 1),
      ),
      child: PrettyQrView.data(
        data: data,
        decoration: const PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: 'QR CODE',
            style: Theme.of(context).textTheme.l1Regular.withColor(
              context.colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          FusionAppText(
            text: 'Scan the QR Code with any mobile devices on the same network to access a virtual wall controller',
            style: Theme.of(context).textTheme.l1Regular.withColor(
              context.colorScheme.textBody,
            ),
          ),
          const SizedBox(height: 12),

          // _PrintButton(qrData: qrData),
          const FusionAppButton(
            semanticId: "",
            text: 'Print',
            height: 32,
            width: 90,
            showSuffixIcon: true,
            suffixIcon: Icons.print_outlined,
            style: FusionAppButtonStyle.primary,
          ),
        ],
      ),
    );
  }
}
