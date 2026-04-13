import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr/qr.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class VirtualControlSection extends StatelessWidget {
  final String? controllerUrl;
  final String? controllerId;

  const VirtualControlSection({super.key, this.controllerUrl, this.controllerId});

  String get _qrData => jsonEncode(<String, String>{
    "vip": serviceLocator<ProjectViewModel>().virtualIP ?? "192.168.1.110",
    "controller_id": "CTRL1762958340064766236",
  });

  Future<void> _printQr(BuildContext context) async {
    try {
      // 1. Render QR to PNG bytes (same as download)
      final QrCode qrCode = QrCode.fromData(
        data: _qrData,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final QrImage qrImage = QrImage(qrCode);

      final ui.Image image = await qrImage.toImage(
        size: 1024,
        decoration: const PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(color: Color(0xFF000000)),
          background: Color(0xFFFFFFFF),
        ),
      );

      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to render QR');
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 2. Wrap PNG in a PDF page
      final pw.Document doc = pw.Document();
      final pw.MemoryImage qrPwImage = pw.MemoryImage(pngBytes);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          build: (pw.Context ctx) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: <pw.Widget>[
                  pw.Text(
                    'Virtual Wall Controller',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.SizedBox(
                    width: 320,
                    height: 320,
                    child: pw.Image(qrPwImage),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Scan with a mobile device on the same network',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // 3. Open native print dialog
      await Printing.layoutPdf(
        dynamicLayout: true,
        name: 'virtual_controller_qr',
        onLayout: (PdfPageFormat format) async => doc.save(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print QR: $e')),
        );
      }
    }
  }

  Future<void> _downloadQrAsImage(BuildContext context) async {
    try {
      // 1. Build QR image using pretty_qr_code
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

      // 2. Resolve save directory
      final Directory saveDir = await _getDownloadsDirectory();
      final String filePath = '${saveDir.path}/virtual_controller_qr.png';

      // 3. Write file
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // 4. Notify user
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
      // path_provider returns the Downloads folder on desktop
      final Directory? downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    }
    // Fallback to app documents directory
    return getApplicationDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const PanelSectionHeader(title: 'VIRTUAL CONTROL'),
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
            text: 'Download',
            height: 32,
            width: 110,
            showSuffixIcon: true,
            suffixIcon: Icons.download_outlined,
            style: FusionAppButtonStyle.primary,
            onPressed: () => _downloadQrAsImage(context),
          ),
          FusionAppButton(
            semanticId: "",
            text: 'Print',
            height: 32,
            width: 110,
            showSuffixIcon: true,
            suffixIcon: Icons.print_outlined,
            style: FusionAppButtonStyle.primary,
            onPressed: () => _printQr(context),
          ),
        ],
      ),
    );
  }
}
