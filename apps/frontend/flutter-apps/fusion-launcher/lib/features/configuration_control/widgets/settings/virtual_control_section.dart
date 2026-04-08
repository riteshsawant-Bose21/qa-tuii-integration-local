import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:printing/printing.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../viewModel/configuration_control_state.dart';

/// Virtual Control section — shows a QR code for mobile virtual wall controller access
class VirtualControlSection extends StatelessWidget {
  final String? controllerUrl;
  final ConfigurationControlState state;

  const VirtualControlSection({super.key, this.controllerUrl, required this.state});

  String get _qrData => jsonEncode(<String, String>{
    "vip": serviceLocator<ProjectViewModel>().virtualIP ?? "",
    "controller_id": state.selectedControllerId ?? "",
  });

  /// Builds a PDF with a native vector QR code (no screen capture required)
  /// and opens the system print-preview dialog.
  Future<void> _printQrCode() async {
    final String data = _qrData;
    final pw.Document pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'VIRTUAL CONTROL',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  // Native vector QR code — black on white, always scannable
                  pw.Container(
                    width: 160,
                    height: 160,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: data,
                      color: PdfColors.black,
                      backgroundColor: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  // Description
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: <pw.Widget>[
                        pw.Text(
                          'QR CODE',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Scan the QR Code with any mobile devices on the same network to access a virtual wall controller.',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Open the system print-preview dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
      name: 'Virtual Control QR Code',
    );
  }

  @override
  Widget build(BuildContext context) {
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
              _buildQrCode(context),
              const SizedBox(width: 18),
              _buildDescription(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode(BuildContext context) {
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
        data: _qrData,
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
          FusionAppButton(
            semanticId: "",
            text: 'Print',
            height: 32,
            width: 90,
            showSuffixIcon: true,
            suffixIcon: Icons.print_outlined,
            style: FusionAppButtonStyle.primary,
            // onPressed: _printQrCode,
            onPressed: () {
              final WallControllerConfig config = serviceLocator<ProjectViewModel>().getWallControllerConfig();
              final String prettyJson = const JsonEncoder.withIndent('  ').convert(config.toJson());
              debugPrint('─── WallControllerConfig JSON ───');
              debugPrint(prettyJson);
            },
          ),
        ],
      ),
    );
  }
}
