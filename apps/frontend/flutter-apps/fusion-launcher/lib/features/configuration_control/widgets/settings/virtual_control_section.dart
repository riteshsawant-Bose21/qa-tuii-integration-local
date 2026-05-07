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

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/service_locator.dart';
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
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.settingsTabvirtualControlsection),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Section header — shared PanelSectionHeader widget
          PanelSectionHeader(semanticId: FusionTestKeys.instance.settingsTabvirtualControlsectionHeader, title: 'VIRTUAL CONTROL'),

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
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.settingsTabvirtualControlsectionQrPanel),
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
                // final String prettyJson = const JsonEncoder.withIndent('  ').convert(config.toJson());
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
            // Row(
            //   children: <Widget>[
            //     FusionAppButton(
            //       semanticId: FusionTestKeys.instance.settingsTabvirtualControlsectiondescprintbutton,
            //       text: 'Print',
            //       height: 32,
            //       width: 110,
            //       showSuffixIcon: true,
            //       suffixIcon: Icons.print_outlined,
            //       style: FusionAppButtonStyle.primary,
            //       onPressed: () => _printQr(context),
            //     ),
            //     const SizedBox(width: 12),
            //
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

class CustomPrintDialog extends StatefulWidget {
  final String qrData;

  const CustomPrintDialog({super.key, required this.qrData});

  @override
  State<CustomPrintDialog> createState() => _CustomPrintDialogState();
}

class _CustomPrintDialogState extends State<CustomPrintDialog> {
  List<Printer> _printers = <Printer>[];
  Printer? _selectedPrinter;
  PdfPageFormat _selectedFormat = PdfPageFormat.letter;
  bool _landscape = false;
  int _copies = 1;
  bool _loading = true;
  bool _printing = false;

  static const Map<String, PdfPageFormat> _paperSizes = <String, PdfPageFormat>{
    'Letter': PdfPageFormat.letter,
    'A4': PdfPageFormat.a4,
    'A3': PdfPageFormat.a3,
    'A5': PdfPageFormat.a5,
    'Legal': PdfPageFormat.legal,
  };

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    try {
      final List<Printer> printers = await Printing.listPrinters();
      setState(() {
        _printers = printers;
        _selectedPrinter =
            printers.isNotEmpty
                ? printers.firstWhere(
                  (Printer p) => p.isDefault,
                  orElse: () => printers.first,
                )
                : null;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<Uint8List> _buildPdf() async {
    // Render QR
    final QrCode qrCode = QrCode.fromData(
      data: widget.qrData,
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
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Build PDF
    final pw.Document doc = pw.Document();
    final pw.MemoryImage qrPwImage = pw.MemoryImage(pngBytes);
    final PdfPageFormat format = _landscape ? _selectedFormat.landscape : _selectedFormat.portrait;

    doc.addPage(
      pw.Page(
        pageFormat: format,
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

    return doc.save();
  }

  Future<void> _print() async {
    if (_selectedPrinter == null) return;
    setState(() => _printing = true);

    try {
      final Uint8List pdfBytes = await _buildPdf();

      for (int i = 0; i < _copies; i++) {
        await Printing.directPrintPdf(
          printer: _selectedPrinter!,
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'virtual_controller_qr',
          format: _landscape ? _selectedFormat.landscape : _selectedFormat.portrait,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent to ${_selectedPrinter!.name}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _printing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colorScheme.elevation2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colorScheme.strokeLight),
      ),
      child: Container(
        width: 820,
        padding: const EdgeInsets.all(24),
        child:
            _loading
                ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        FusionAppText(
                          text: 'Print',
                          style: Theme.of(context).textTheme.titleLarge!.withColor(context.colorScheme.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: context.colorScheme.textBody,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Two-column body: controls | preview
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // LEFT: controls
                          SizedBox(
                            width: 380,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _buildLabel(context, 'Printer', 'print_dialog_printer_label'),
                                const SizedBox(height: 6),
                                _buildPrinterDropdown(context),
                                const SizedBox(height: 16),
                                _buildLabel(context, 'Paper Size', 'print_dialog_paper_size_label'),
                                const SizedBox(height: 6),
                                _buildPaperSizeDropdown(context),
                                const SizedBox(height: 16),
                                _buildLabel(context, 'Orientation', 'print_dialog_orientation_label'),
                                const SizedBox(height: 6),
                                Row(
                                  children: <Widget>[
                                    _buildOrientationChip(context, 'Portrait', false, Icons.crop_portrait),
                                    const SizedBox(width: 8),
                                    _buildOrientationChip(context, 'Landscape', true, Icons.crop_landscape),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildLabel(context, 'Copies', 'print_dialog_copies_label'),
                                const SizedBox(height: 6),
                                _buildCopiesSelector(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // RIGHT: preview
                          Expanded(child: _buildPreview(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        FusionAppButton(
                          semanticId: '',
                          text: 'Cancel',
                          height: 36,
                          width: 100,
                          style: FusionAppButtonStyle.secondary,
                          onPressed: _printing ? null : () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        FusionAppButton(
                          semanticId: '',
                          text: _printing ? 'Printing...' : 'Print',
                          height: 36,
                          width: 100,
                          style: FusionAppButtonStyle.primary,
                          onPressed: _printing || _selectedPrinter == null ? null : _print,
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: PdfPreview(
        // Rebuild whenever paper size / orientation changes
        key: ValueKey<String>(
          '${_selectedFormat.width}_'
          '${_selectedFormat.height}_$_landscape',
        ),
        build: (PdfPageFormat format) => _buildPdf(),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        useActions: false,
        pdfPreviewPageDecoration: const BoxDecoration(color: Colors.white),
        previewPageMargin: const EdgeInsets.all(8),
        scrollViewDecoration: BoxDecoration(
          color: context.colorScheme.elevation1,
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text, String semanticId) {
    return FusionAppText(
      text: text,
      semanticId: semanticId,
      style: Theme.of(context).textTheme.l1Regular.withColor(context.colorScheme.textBody),
    );
  }

  Widget _buildPrinterDropdown(BuildContext context) {
    return FusionNeumorphicDropdown<Printer>(
      semanticId: 'print_dialog_printer_dropdown',
      value: _selectedPrinter,
      borderRadius: BorderRadius.circular(8),
      items: _printers,
      itemLabelBuilder: (Printer p) => p.name, // ← name may differ, check the class
      onChanged: (Printer? p) => setState(() => _selectedPrinter = p),
    );
  }

  Widget _buildPaperSizeDropdown(BuildContext context) {
    return FusionNeumorphicDropdown<PdfPageFormat>(
      semanticId: 'print_dialog_paper_size_dropdown',
      value: _selectedFormat,
      borderRadius: BorderRadius.circular(8),
      items: _paperSizes.values.toList(),
      itemLabelBuilder: (PdfPageFormat format) {
        return _paperSizes.entries.firstWhere((MapEntry<String, PdfPageFormat> e) => e.value == format).key;
      },
      onChanged: (PdfPageFormat? f) {
        if (f != null) setState(() => _selectedFormat = f);
      },
    );
  }

  Widget _buildOrientationChip(
    BuildContext context,
    String label,
    bool landscape,
    IconData icon,
  ) {
    final bool selected = _landscape == landscape;

    return Expanded(
      child: SemanticHelper.container(
        testId: SemanticHelper.createTestId(
          SemanticTypes.container,
          'print_dialog_orientation_chip',
        ),
        value: label,
        child: GestureDetector(
          onTap: () => setState(() => _landscape = landscape),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: context.colorScheme.elevation1,
              borderRadius: BorderRadius.circular(8),
              boxShadow:
                  selected
                      // Pressed-in (inset) shadows
                      ? <BoxShadow>[
                        BoxShadow(
                          color: context.colorScheme.shadowDark,
                          blurRadius: 1,
                          offset: const Offset(-2, -2),
                          blurStyle: BlurStyle.inner,
                        ),
                        BoxShadow(
                          color: context.colorScheme.shadowLight,
                          blurRadius: 1,
                          offset: const Offset(2, 2),
                          blurStyle: BlurStyle.inner,
                        ),
                        BoxShadow(
                          color: context.colorScheme.elevation1,
                          blurRadius: 4,
                          blurStyle: BlurStyle.inner,
                        ),
                      ]
                      // Raised (extruded) shadows
                      : <BoxShadow>[
                        BoxShadow(
                          color: context.colorScheme.shadowLight,
                          blurRadius: 2,
                          offset: const Offset(-2, -2),
                        ),
                        BoxShadow(
                          color: context.colorScheme.shadowDark,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                        BoxShadow(color: context.colorScheme.elevation1),
                      ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: selected ? context.colorScheme.primary : context.colorScheme.textBody,
                ),
                const SizedBox(width: 8),
                FusionAppText(
                  text: label,
                  style: Theme.of(context).textTheme.l1Regular.withColor(
                    selected ? context.colorScheme.textPrimary : context.colorScheme.textBody,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopiesSelector(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'print_dialog_copies_selector'),
      value: _copies.toString(),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(8),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: context.colorScheme.shadowDark,
              blurRadius: 1,
              offset: const Offset(-2, -2),
              blurStyle: BlurStyle.inner,
            ),
            BoxShadow(
              color: context.colorScheme.shadowLight,
              blurRadius: 1,
              offset: const Offset(2, 2),
              blurStyle: BlurStyle.inner,
            ),
            BoxShadow(
              color: context.colorScheme.elevation1,
              blurRadius: 4,
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              color: context.colorScheme.textBody,
              onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
            ),
            Expanded(
              child: Center(
                child: FusionAppText(
                  text: '$_copies',
                  style: Theme.of(context).textTheme.l1Regular.withColor(context.colorScheme.textPrimary),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              color: context.colorScheme.textBody,
              onPressed: _copies < 99 ? () => setState(() => _copies++) : null,
            ),
          ],
        ),
      ),
    );
  }
}
