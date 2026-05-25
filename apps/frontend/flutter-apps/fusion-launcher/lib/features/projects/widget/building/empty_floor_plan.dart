import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/image_loader_service.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_building_view/floor_plan_calibrator.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'widgets/building_canvas_option_button.dart';

class EmptyFloorPlan extends StatefulWidget {
  const EmptyFloorPlan({super.key});

  @override
  State<EmptyFloorPlan> createState() => _EmptyFloorPlanState();
}

class _EmptyFloorPlanState extends State<EmptyFloorPlan> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          /// icon
          // const FusionImageAuto(
          //   path: "assets/images/upload_floor_plan.png",
          //   width: 64,
          //   height: 64,
          // ),

          // const SizedBox(height: 24),

          /// Title
          FusionAppText(
            text: "Getting Started",
            style: context.textTheme.h1Bold.copyWith(
              color: context.colorScheme.black,
            ),
            // style: Theme.of(
            //   context,
            // ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          /// Subtitle
          FusionAppText(
            text: "Build mode is where you take the first steps in crafting\n your system, choose an option below to start.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.b1Regular.copyWith(color: context.colorScheme.textGrey),
          ),
          const SizedBox(height: 28),
          Row(
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              BuildingCanvasOptionButton(
                title: "Upload Floor Plan",
                description: "Start with a pre-built structure",
                icon: "floorplan.png",
                onTap: () {
                  _showFloorPlanPicker();
                },
              ),
              BuildingCanvasOptionButton(
                title: "Blank Canvas",
                description: "Design from scratch",
                icon: "blank_canvas.png",
                onTap: () {
                  // _showFloorPlanPicker();
                  serviceLocator<ProjectViewModel>().updateFloor(
                    floor: serviceLocator<ProjectViewModel>().floors[serviceLocator<ProjectViewModel>().currentFloorIndex].copyWith(
                      skipFloorPlan: true,
                    ),
                  );
                },
              ),
            ],
          ),
         
        ],
      ),
    );
  }

  Future<void> _showFloorPlanPicker() async {
    final List<String> plans = <String>[
      "assets/images/floor_plans/cafe.png",
      "assets/images/floor_plans/restaurant.png",
      // "assets/images/floor_plans/floor_plan_gym.png",
      "assets/images/floor_plans/gym.jpg",
    ];

    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.elevation1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 720,
            height: 500,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: 'Upload Floor Plan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                    ),
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.closeX),
                      child: IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(
                          Icons.close,
                          color: context.colorScheme.primaryWhite,
                          size: 20,
                        ),
                        splashRadius: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Import Section (Primary)
                Expanded(
                  flex: 2,
                  child: _buildImportSection(ctx),
                ),

                const SizedBox(height: 16),

                // Divider
                Row(
                  children: <Widget>[
                    Expanded(child: Divider(color: context.colorScheme.elevation2)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FusionAppText(
                        text: 'or choose from samples',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.primaryWhite,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.colorScheme.elevation2)),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: List<Widget>.generate(
                    plans.length,
                    (int index) {
                      final String planPath = plans[index];
                      return Expanded(
                        child: _buildSamplePlanCard(index, planPath),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImportSection(BuildContext ctx) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (DragTargetDetails<String> details) => true,
      onAcceptWithDetails: (DragTargetDetails<String> details) => _importFloorPlan(),
      builder: (BuildContext context, List<String?> candidateData, List<dynamic> rejectedData) {
        final bool isDragActive = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => _importFloorPlan(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDragActive ? Theme.of(context).colorScheme.primaryColor.withValues(alpha: 0.05) : context.colorScheme.elevation1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: isDragActive ? 2 : 1,
                color: isDragActive ? Theme.of(context).colorScheme.primaryWhite : context.colorScheme.elevation2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  isDragActive ? LucideIcons.download200 : LucideIcons.cloudUpload200,
                  size: 48,
                  color: context.colorScheme.primaryWhite,
                ),
                const SizedBox(height: 16),
                FusionAppText(
                  text: isDragActive ? 'Drop your file here!' : 'Click here to upload',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: isDragActive ? context.colorScheme.primaryWhite : context.colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                FusionAppText(
                  text: 'Upload .PDF, .JPEG or .PNG\nfiles (max file size- 5MB)',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isDragActive ? context.colorScheme.primaryWhite : context.colorScheme.elevation4,
                  ),
                ),
                const SizedBox(height: 8),
                FusionNeumorphicButton(
                  semanticId: "import_floor_plan",
                  height: 36,
                  width: 140,
                  text: 'Browse Files',
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  onTap: () => _importFloorPlan(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSamplePlanCard(int index, String planPath) {
    final String title = planPath.split('/').last.split('.').first.replaceAll('_', ' ').toUpperCase();

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        'floor_plan_sample_${index + 1}',
      ),
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.elevation2,
          ),
        ),
        child: GestureDetector(
          onTap: () => _selectAssetFloorPlan(planPath),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: _buildFloorPlanImage(planPath),
              ),
              const SizedBox(height: 8),
              FusionAppText(
                text: title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLine: 1,
                // overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloorPlanImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return FusionImageAuto(
        path: imagePath,
        fit: BoxFit.cover,
      );
    } else {
      return FusionImageAuto(
        path: imagePath,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Container(
            color: Colors.grey.shade300,
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey.shade600,
              size: 30,
            ),
          );
        },
      );
    }
  }

  Future<void> _selectAssetFloorPlan(String assetImagePath) async {
    if (mounted) Navigator.of(context).pop();
    serviceLocator<GuideShowCaseController>().completeStep(
      GuideShowCaseSteps.uploadFloorPlan,
    );

    final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addAssetImageToProject(
      assetPath: assetImagePath,
    );
    if (responseCallback.success && responseCallback.data != null) {
      final String savedImagePath = responseCallback.data!;
      _calibrateFloorPlan(savedImagePath);
    }
  }

  Future<void> _importFloorPlan() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: <String>['png', 'jpg', 'jpeg', 'pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final String sourcePath = result.files.single.path!;
        final String fileName = result.files.single.name;

        // Enforce 5 MB maximum file size
        const int maxBytes = 5 * 1024 * 1024; // 5 MB
        final int fileSize = result.files.single.size;
        if (fileSize > maxBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File is too large. Maximum allowed size is 5 MB.'),
              ),
            );
          }
          return;
        }

        // Handle PDF files: convert selected page to image first
        String imagePath = sourcePath;
        if (fileName.toLowerCase().endsWith('.pdf')) {
          final String? convertedPath = await _handlePdfImport(sourcePath);
          if (convertedPath == null) return; // User cancelled page selection
          imagePath = convertedPath;
        }

        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
          );

          final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addImageToProject(
            imagePath: imagePath,
          );

          if (mounted) Navigator.of(context).pop();

          // ignore: use_build_context_synchronously
          serviceLocator<GuideShowCaseController>().completeStep(
            GuideShowCaseSteps.uploadFloorPlan,
          );

          if (responseCallback.success && responseCallback.data != null) {
            final String savedImagePath = responseCallback.data!;
            _calibrateFloorPlan(savedImagePath);
          }

          if (mounted) {
            Navigator.of(context).pop();
          }
          debugPrint('Floor plan imported successfully: $fileName');
        } else {
          debugPrint("Dialog is not mounted !!!!!");
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('Error importing floor plan: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: FusionAppText(
            text: 'Error importing floor plan: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Opens a PDF, and if it has multiple pages shows a page selection dialog.
  /// Returns the path to a temporary PNG image of the selected page, or null if cancelled.
  Future<String?> _handlePdfImport(String pdfPath) async {
    final PdfDocument document = await PdfDocument.openFile(pdfPath);
    try {
      final int pageCount = document.pages.length;

      if (pageCount == 1) {
        return _renderPdfPageToFile(document.pages[0]);
      }

      // Multi-page: show selection dialog
      if (!mounted) return null;
      final int? selectedIndex = await showDialog<int>(
        context: context,
        builder: (BuildContext ctx) => _PdfPageSelectionDialog(document: document),
      );

      if (selectedIndex == null) return null;
      return _renderPdfPageToFile(document.pages[selectedIndex]);
    } finally {
      document.dispose();
    }
  }

  /// Renders a single PDF page at 4x resolution (288 dpi) and saves as a temp PNG file.
  Future<String> _renderPdfPageToFile(PdfPage page) async {
    const double scale = 4.0; // 72 dpi * 4 = 288 dpi
    final PdfImage? pdfImage = await page.render(
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: Colors.white,
    );
    if (pdfImage == null) throw Exception('Failed to render PDF page');

    final ui.Image uiImage = await pdfImage.createImage();
    pdfImage.dispose();

    final ByteData? byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    uiImage.dispose();
    if (byteData == null) throw Exception('Failed to encode PDF page as PNG');

    final String tempPath = '${Directory.systemTemp.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(tempPath).writeAsBytes(byteData.buffer.asUint8List());
    return tempPath;
  }

  Future<void> _calibrateFloorPlan(String savedImagePath) async {
    try {
      final ui.Image image = await serviceLocator<ImageLoaderService>().loadImage(savedImagePath);

      // if (!mounted) return;
      //
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (_) => const Center(child: CircularProgressIndicator()),
      // );
      //
      // await Future<void>.delayed(const Duration(milliseconds: 100));
      //
      // if (mounted) Navigator.of(context).pop();

      if (!mounted) return;

      final CalibrationData? calibrationData = await showDialog<CalibrationData>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Dialog(
            insetPadding: const EdgeInsets.all(100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: context.colorScheme.elevation1,
            child: FloorPlanCalibrationDialog(
              floorPlanImage: image,
              onCalibrationComplete: (CalibrationData data) {
                serviceLocator<GuideShowCaseController>().completeStep(GuideShowCaseSteps.confirmFloorCalibrated);
                if (context.mounted) Navigator.of(context).pop(data);
              },
              onCancel: () {
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          );
        },
      );

      if (calibrationData != null) {
        debugPrint('Calibration completed: $calibrationData');

        const double canvasPixelsPerMeter = 100.0;

        //get current floor
        final int floorIndex = serviceLocator<ProjectViewModel>().currentFloorIndex;
        final FloorModel floor = serviceLocator<ProjectViewModel>().floors[floorIndex];

        // Use cropped image if available, otherwise use original
        final ui.Image imageToUse = calibrationData.croppedImage ?? image;

        final double widthInUnits = imageToUse.width * calibrationData.unitsPerPixel;
        final double heightInUnits = imageToUse.height * calibrationData.unitsPerPixel;

        double widthInMeters = widthInUnits;
        double heightInMeters = heightInUnits;

        switch (calibrationData.unit) {
          case MeasurementUnit.meters:
            break;
          case MeasurementUnit.feet:
            widthInMeters = widthInUnits * 0.3048;
            heightInMeters = heightInUnits * 0.3048;
            break;
          case MeasurementUnit.centimeters:
            widthInMeters = widthInUnits * 0.01;
            heightInMeters = heightInUnits * 0.01;
            break;
          case MeasurementUnit.inches:
            widthInMeters = widthInUnits * 0.0254;
            heightInMeters = heightInUnits * 0.0254;
            break;
        }

        final double canvasWidthInPixels = widthInMeters * canvasPixelsPerMeter;
        final double canvasHeightInPixels = heightInMeters * canvasPixelsPerMeter;
        final Size floorPlanSize = Size(
          canvasWidthInPixels,
          canvasHeightInPixels,
        );

        debugPrint(
          'Real-world dimensions: ${widthInMeters.toStringAsFixed(2)}m x ${heightInMeters.toStringAsFixed(2)}m',
        );
        debugPrint(
          'Canvas dimensions: ${canvasWidthInPixels.toStringAsFixed(1)}px x ${canvasHeightInPixels.toStringAsFixed(1)}px',
        );

        // If we have a cropped image, save it and use it instead of the original
        String imagePathToUse = savedImagePath;
        if (calibrationData.croppedImage != null) {
          // Save the cropped image
          final String croppedImagePath = await _saveCroppedImage(
            calibrationData.croppedImage!,
            savedImagePath,
          );
          imagePathToUse = croppedImagePath;
        }

        serviceLocator<ProjectViewModel>().updateFloor(
          floor: floor.copyWith(
            floorPlan: floor.floorPlan.copyWith(
              imagePath: imagePathToUse,
              position: floor.floorPlan.imagePath.isNotEmpty ? floor.floorPlan.position : Offset.zero,
              size: floorPlanSize,
            ),
          ),
        );

        // ignore: use_build_context_synchronously
        serviceLocator<GuideShowCaseController>().completeStep(
          GuideShowCaseSteps.confirmFloorCalibrated,
        );
      } else {
        debugPrint('Calibration cancelled by user');
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      debugPrint('Error during calibration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: FusionAppText(text: 'Error during calibration: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<String> _saveCroppedImage(
    ui.Image croppedImage,
    String originalImagePath,
  ) async {
    // Convert the cropped image to byte data
    final ByteData? byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) throw Exception('Failed to convert cropped image to byte data.');

    // Create a temporary file to save the cropped image
    final String tempFileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.png';
    final String tempPath = '${Directory.systemTemp.path}/$tempFileName';

    // Write the byte data to the temporary file first
    final File tempFile = File(tempPath);
    await tempFile.writeAsBytes(byteData.buffer.asUint8List());

    debugPrint('Cropped image temporarily saved to: $tempPath');

    // Now use the project's image management system to properly store it
    final ResponseCallback<String?> responseCallback = await serviceLocator<ProjectViewModel>().addImageToProject(
      imagePath: tempPath,
    );

    // Clean up the temporary file
    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      debugPrint('Warning: Could not delete temporary file: $e');
    }

    if (responseCallback.success && responseCallback.data != null) {
      final String savedCroppedImagePath = responseCallback.data!;
      debugPrint('Cropped image properly saved to: $savedCroppedImagePath');
      return savedCroppedImagePath;
    } else {
      throw Exception('Failed to save cropped image to project storage');
    }
  }
}

/// Dialog that displays PDF page thumbnails and lets the user select one.
class _PdfPageSelectionDialog extends StatefulWidget {
  final PdfDocument document;

  const _PdfPageSelectionDialog({required this.document});

  @override
  State<_PdfPageSelectionDialog> createState() => _PdfPageSelectionDialogState();
}

class _PdfPageSelectionDialogState extends State<_PdfPageSelectionDialog> {
  int? _selectedIndex;
  final Map<int, ui.Image?> _thumbnails = <int, ui.Image?>{};

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  Future<void> _loadThumbnails() async {
    for (int i = 0; i < widget.document.pages.length; i++) {
      final PdfPage page = widget.document.pages[i];
      // Render at 1x (72 dpi) for thumbnails
      final PdfImage? pdfImage = await page.render(fullWidth: page.width, fullHeight: page.height, backgroundColor: Colors.white);
      if (pdfImage != null) {
        final ui.Image image = await pdfImage.createImage();
        pdfImage.dispose();
        if (mounted) {
          setState(() => _thumbnails[i] = image);
        }
      }
    }
  }

  @override
  void dispose() {
    for (final ui.Image? image in _thumbnails.values) {
      image?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int pageCount = widget.document.pages.length;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.elevation1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.all(100),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FusionAppText(
                  text: 'Select a Page ($pageCount pages)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: context.colorScheme.primaryWhite, size: 20),
                  splashRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Page grid
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colorScheme.strokeLight,
                    width: 1,
                  ),
                ),
                child: GridView.builder(
                  itemCount: pageCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (BuildContext context, int index) {
                    final bool isSelected = _selectedIndex == index;
                    final ui.Image? thumbnail = _thumbnails[index];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primaryColor : context.colorScheme.strokeLight,
                            width: isSelected ? 2 : 1,
                          ),
                          color: context.colorScheme.elevation1,
                        ),
                        child: Builder(
                          builder: (BuildContext context) {
                            if (thumbnail != null) {
                              return RawImage(image: thumbnail, fit: BoxFit.contain);
                            } else {
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Confirm button
            Align(
              alignment: Alignment.centerRight,
              child: FusionNeumorphicButton(
                semanticId: 'pdf_page_import',
                height: 36,
                width: 120,
                text: 'Import',
                enabled: _selectedIndex != null,
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                onTap: () => Navigator.of(context).pop(_selectedIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
