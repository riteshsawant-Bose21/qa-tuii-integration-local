import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/controller/controller_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/touch_ui_zone_config/touch_ui_zone_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr/qr.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/utils/printer.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

/// Virtual Control section — shows a QR code for mobile virtual wall controller access
class VirtualControlSection extends StatelessWidget {
  final String? controllerId;

  const VirtualControlSection({super.key, this.controllerId});

  String get _qrData => jsonEncode(<String, String>{
    "vip": serviceLocator<ProjectViewModel>().virtualIP ?? "",
    "controller_id": controllerId ?? "",
  });

  Future<void> _printQr(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) => CustomPrintDialog(qrData: _qrData),
    );
  }

  Future<void> _downloadQrAsImage(BuildContext context) async {
    try {
      final QrCode qrCode = QrCode.fromData(
        data: _qrData,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final QrImage qrImage = QrImage(qrCode);

      final ui.Image image = await qrImage.toImage(
        size: 512,
        decoration: const PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(color: Color(0xFF000000)),
          background: Color(0xFFFFFFFF),
        ),
      );

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert QR to image');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Directory saveDir = await _getDownloadsDirectory();
      final String filePath = '${saveDir.path}/virtual_controller_qr.png';

      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR saved to: $filePath'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save QR: $e')),
        );
      }
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isMacOS || Platform.isWindows) {
      final Directory? downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    }
    return getApplicationDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        FusionTestKeys.instance.settingsTabvirtualControlsection,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Section header — shared PanelSectionHeader widget
          PanelSectionHeader(
            semanticId: FusionTestKeys.instance.settingsTabvirtualControlsectionHeader,
            title: 'VIRTUAL CONTROL',
          ),

          /// QR + description row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildQrCode(context),
                const SizedBox(width: 18),
                _buildDescription(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        FusionTestKeys.instance.settingsTabvirtualControlsectionQrPanel,
      ),
      child: Container(
        width: 158,
        height: 158,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colorScheme.strokeLight, width: 1),
        ),
        child: PrettyQrView.data(
          data: _qrData,
          decoration: const PrettyQrDecoration(
            shape: PrettyQrSmoothSymbol(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Expanded(
      child: SemanticHelper.container(
        testId: SemanticHelper.createTestId(
          SemanticTypes.container,
          FusionTestKeys.instance.settingsTabvirtualControlsectiondesc,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FusionAppText(
              semanticId: FusionTestKeys.instance.settingsTabvirtualControlsectiondesclabel,
              text: 'QR CODE',
              style: Theme.of(context).textTheme.l1Regular.withColor(
                context.colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                final WallControllerConfig config = serviceLocator<ProjectViewModel>().getWallControllerConfig();
                final TouchUIZoneConfig touchUiConfig = serviceLocator<ProjectViewModel>().getTouchUIZoneConfig();
                final String prettyJson = const JsonEncoder.withIndent('  ').convert(touchUiConfig.toJson());
                debugPrint('─── WallControllerConfig JSON ───');
                debugPrint(prettyJson);
              },
              child: FusionAppText(
                semanticId: FusionTestKeys.instance.settingsTabvirtualControlsectiondesctext,
                text: 'Scan the QR Code with any mobile devices on the same network to access a virtual wall controller',
                style: Theme.of(context).textTheme.l1Regular.withColor(
                  context.colorScheme.textBody,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              spacing: 6,
              children: <Widget>[
                FusionAppButton(
                  semanticId: FusionTestKeys.instance.settingsTabvirtualControlsectiondescdownloadbutton,
                  text: 'Download',
                  height: 32,
                  width: 110,
                  showSuffixIcon: true,
                  suffixIcon: Icons.download_outlined,
                  style: FusionAppButtonStyle.primary,
                  onPressed: () => _downloadQrAsImage(context),
                ),
                FusionAppButton(
                  semanticId: FusionTestKeys.instance.settingsTabvirtualControlsectiondescprintbutton,
                  text: 'Print',
                  height: 32,
                  width: 110,
                  showSuffixIcon: true,
                  suffixIcon: Icons.print_outlined,
                  style: FusionAppButtonStyle.primary,
                  onPressed: () => _printQr(context),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
