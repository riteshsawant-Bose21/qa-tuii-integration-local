import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr/qr.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      print('Load printers error: $e');
      setState(() => _loading = false);
    }
  }

  Future<Uint8List> _buildPdf() async {
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

    final pw.Font fontRegular = await PdfGoogleFonts.notoSansRegular();
    final pw.Font fontBold = await PdfGoogleFonts.notoSansBold();

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
                    font: fontBold,
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
                  style: pw.TextStyle(font: fontRegular, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  /// Resolves the real CUPS queue name from a Flutter display name.
  /// CUPS queues use underscores; display names may use spaces.
  /// e.g. "Mangalore Office Printer" → "Mangalore_Office_Printer"
  Future<String> _resolveCupsQueueName(String displayName) async {
    try {
      /// lpstat -a lists all accepting queues with their real CUPS queue names
      final ProcessResult result = await Process.run('lpstat', <String>['-a']);
      final String output = result.stdout as String;

      print('lpstat -a output:\n$output');

      for (final String line in output.split('\n')) {
        if (line.trim().isEmpty) continue;

        /// Each line format: "QueueName accepting requests since ..."
        final String queueName = line.split(' ').first;

        /// Normalize both sides: replace underscores with spaces, lowercase
        final String normalizedQueue = queueName.replaceAll('_', ' ').toLowerCase();
        final String normalizedDisplay = displayName.replaceAll('_', ' ').toLowerCase();

        if (normalizedQueue == normalizedDisplay) {
          print('Matched CUPS queue: $queueName for display name: $displayName');
          return queueName;
        }
      }

      print('No exact match found in lpstat -a, falling back to underscore replacement');
    } catch (e) {
      print('Could not resolve CUPS queue name: $e');
    }

    /// Fallback: replace spaces with underscores
    return displayName.replaceAll(' ', '_');
  }

  Future<void> _print() async {
    if (_selectedPrinter == null) return;
    setState(() => _printing = true);

    try {
      print('========== PRINT ==========');
      print('Display name: ${_selectedPrinter!.name}');
      print('Copies: $_copies');

      print('Building PDF...');
      final Uint8List pdfBytes = await _buildPdf();
      print('PDF built: ${pdfBytes.length} bytes');

      final Directory tempDir = await getTemporaryDirectory();
      final String pdfPath = '${tempDir.path}/virtual_controller_qr.pdf';
      await File(pdfPath).writeAsBytes(pdfBytes);
      print('PDF saved to: $pdfPath');

      if (Platform.isMacOS) {
        /// Resolve real CUPS queue name (handles spaces in printer display names)
        final String cupsQueue = await _resolveCupsQueueName(_selectedPrinter!.name);
        print('Resolved CUPS queue: $cupsQueue');

        /// Pass args as a list — Process.run does NOT use shell,
        /// so spaces in cupsQueue and pdfPath are handled correctly
        final ProcessResult result = await Process.run(
          'lpr',
          <String>[
            '-P',
            cupsQueue,
            '-#',
            _copies.toString(),
            pdfPath,
          ],
        );

        print('lpr stdout: ${result.stdout}');
        print('lpr stderr: ${result.stderr}');
        print('lpr exit code: ${result.exitCode}');

        if (result.exitCode != 0) {
          throw Exception('lpr failed (exit ${result.exitCode}): ${result.stderr}');
        }

        print('Print job submitted successfully');
        if (mounted) Navigator.of(context).pop(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sent to printer successfully'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        /// Windows / Linux — directPrintPdf works reliably
        if (mounted) Navigator.of(context).pop(true);
        await Printing.directPrintPdf(
          printer: _selectedPrinter!,
          onLayout: (_) async => pdfBytes,
          name: 'virtual_controller_qr',
        );
      }

      print('========== END PRINT ==========');
    } catch (e, stack) {
      print('Print error: $e');
      print('Stack: $stack');
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
                    // ── Header ──────────────────────────────────────────────
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

                    // ── Body: controls | preview ─────────────────────────
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // LEFT — controls
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
                          // RIGHT — preview
                          Expanded(child: _buildPreview(context)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Action buttons ───────────────────────────────────
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
        key: ValueKey<String>(
          '${_selectedFormat.width}_${_selectedFormat.height}_$_landscape',
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
      itemLabelBuilder: (Printer p) => p.name,
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
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        'print_dialog_copies_selector',
      ),
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
