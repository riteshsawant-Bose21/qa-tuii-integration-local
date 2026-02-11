import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

// Assuming your service locator is set up like this:
// import 'service_locator.dart';

class ZipImportDialog extends StatefulWidget {
  const ZipImportDialog({super.key});

  @override
  State<ZipImportDialog> createState() => _ZipImportDialogState();
}

class _ZipImportDialogState extends State<ZipImportDialog> {
  bool _isDragging = false;
  bool _isImporting = false;
  String? _errorMessage;

  /// Handles the file processing (both from drag and picker)
  Future<void> _handleFileImport(File file) async {
    // 1. Validate Extension
    if (!file.path.toLowerCase().endsWith('.zip')) {
      setState(() => _errorMessage = "Please select a valid .zip file");
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      // 2. Call your logic
      // Note: Ensure you import your service locator and ViewModel
      await serviceLocator<ProjectViewModel>().importProjectFromFile(file);

      // Mocking the delay for demonstration:
      if (kDebugMode) {
        print("Imported: ${file.path}");
      }

      // 3. Close Dialog on Success
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to import: ${e.toString()}";
        _isImporting = false;
      });
    }
  }

  /// Triggered when user clicks the browse button
  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final File file = File(result.files.single.path!);
      await _handleFileImport(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color activeColor = _isDragging ? colorScheme.primary : colorScheme.outline;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500, // Fixed width for desktop/web feel
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "Import Project",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Drop Zone
            DropTarget(
              onDragEntered: (DropEventDetails details) => setState(() => _isDragging = true),
              onDragExited: (DropEventDetails details) => setState(() => _isDragging = false),
              onDragDone: (DropDoneDetails details) async {
                setState(() => _isDragging = false);
                if (details.files.isNotEmpty) {
                  // desktop_drop returns XFile, convert to dart:io File
                  final File file = File(details.files.first.path);
                  await _handleFileImport(file);
                }
              },
              child: GestureDetector(
                onTap: _isImporting ? null : _pickFile,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isDragging ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activeColor,
                      width: 2,
                    ),
                  ),
                  child:
                      _isImporting
                          ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text("Importing project..."),
                            ],
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 64,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Drag & Drop .zip file here",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "or click to browse",
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
