import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_design_tool_prototype/core/models/floor_entity.dart';

import '../../../../../core/image_loader_service.dart';
import '../../../../../core/models/floor_plan_entity.dart';

class FloorPropertiesSidebar extends StatefulWidget {
  final FloorPlanEntity entity;
  final Floor floorEntity;
  final Function(Floor) onEntityChanged;
  final Function(Floor) onFloorDelete;

  const FloorPropertiesSidebar({super.key, required this.entity, required this.onEntityChanged, required this.floorEntity, required this.onFloorDelete});

  @override
  State<FloorPropertiesSidebar> createState() => _FloorPropertiesSidebarState();
}

class _FloorPropertiesSidebarState extends State<FloorPropertiesSidebar> {
  late TextEditingController _nameController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _positionXController;
  late TextEditingController _positionYController;

  // final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant FloorPropertiesSidebar oldWidget) {
    initializeTexts();
    super.didUpdateWidget(oldWidget);
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.floorEntity.name);
    _widthController = TextEditingController(text: widget.entity.size.width.toStringAsFixed(2).toString());
    _heightController = TextEditingController(text: widget.entity.size.height.toStringAsFixed(2).toString());
    _positionXController = TextEditingController(text: widget.entity.position.dx.toStringAsFixed(2).toString());
    _positionYController = TextEditingController(text: widget.entity.position.dy.toStringAsFixed(2).toString());
  }

  void initializeTexts() {
    _nameController.text = widget.floorEntity.name;
    _widthController.text = widget.entity.size.width.toStringAsFixed(2).toString();
    _heightController.text = widget.entity.size.height.toStringAsFixed(2).toString();
    _positionXController.text = widget.entity.position.dx.toStringAsFixed(2).toString();
    _positionYController.text = widget.entity.position.dy.toStringAsFixed(2).toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _positionXController.dispose();
    _positionYController.dispose();
    super.dispose();
  }

  void _updateEntity() {
    final FloorPlanEntity updatedEntity = FloorPlanEntity(
      id: widget.entity.id,
      imagePath: widget.entity.imagePath,
      position: Offset(
        double.tryParse(_positionXController.text) ?? widget.entity.position.dx,
        double.tryParse(_positionYController.text) ?? widget.entity.position.dy,
      ),
      size: Size(double.tryParse(_widthController.text) ?? widget.entity.size.width, double.tryParse(_heightController.text) ?? widget.entity.size.height),
    );

    final String name = _nameController.text.trim();
    final Floor floorEntity = widget.floorEntity.copyWith(name: name.isNotEmpty ? name : widget.floorEntity.name, floorPlan: updatedEntity);

    widget.onEntityChanged(floorEntity);
  }

  Future<void> _deleteFloorImageEntity() async {
    ImageLoaderService.deleteImageFile(widget.entity.imagePath);
    final FloorPlanEntity updatedEntity = widget.entity.copyWith(imagePath: '');
    final Floor floorEntity = widget.floorEntity.copyWith(floorPlan: updatedEntity);
    widget.onEntityChanged(floorEntity);
  }

  void _deleteFloorEntity() {
    //remove floor entity
    widget.onFloorDelete(widget.floorEntity);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: UniqueKey(),
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onSubmitted: (_) => _updateEntity(),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Floor Name
        _buildSectionTitle('Floor'),
        const SizedBox(height: 5),
        _buildTextField(label: 'Floor Name', controller: _nameController),

        // Image Section
        // _buildImageSection(),

        // Size Section
        _buildSectionTitle('Size'),
        const SizedBox(height: 5),
        _buildTextField(
          label: 'Width',
          controller: _widthController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
          suffix: 'm',
        ),
        const SizedBox(width: 12),
        _buildTextField(
          label: 'Height',
          controller: _heightController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
          suffix: 'm',
        ),

        // Position Section
        _buildSectionTitle('Position'),
        _buildTextField(
          label: 'X',
          controller: _positionXController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d*'))],
          // suffix: 'px',
        ),
        const SizedBox(width: 12),
        _buildTextField(
          label: 'Y',
          controller: _positionYController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d*'))],
          // suffix: 'px',
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.white),
            label: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Text("Floor", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _deleteFloorEntity,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.floorEntity.floorPlan.imagePath.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Text("Floor Plan", textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _deleteFloorImageEntity,
            ),
          ),
      ],
    );
  }

  // Future<void> _pickImage() async {
  //   try {
  //     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //     if (image != null) {
  //       final String savedPath = await _saveImageLocally(image);
  //       final FloorPlanEntity updatedEntity = widget.entity.copyWith(imagePath: savedPath);
  //       final FloorEntity floorEntity = widget.floorEntity.copyWith(floorPlan: updatedEntity);
  //       widget.onEntityChanged(floorEntity);
  //       setState(() {
  //         widget.entity.imagePath = savedPath;
  //       });
  //     }
  //   } catch (e) {
  //     // print("Error picking image: $e");
  //     // _showErrorSnackBar('Failed to pick image: $e');
  //   }
  // }

  // Future<String> _saveImageLocally(XFile image) async {
  //   try {
  //     final Directory appDir = await getApplicationDocumentsDirectory();
  //     final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
  //     final String localPath = path.join(appDir.path, 'floor_plans', fileName);
  //
  //     // Create directory if it doesn't exist
  //     final Directory floorPlansDir = Directory(path.dirname(localPath));
  //     if (!await floorPlansDir.exists()) {
  //       await floorPlansDir.create(recursive: true);
  //     }
  //
  //     // Copy file to local storage
  //     final File sourceFile = File(image.path);
  //     await sourceFile.copy(localPath);
  //
  //     return localPath;
  //   } catch (e) {
  //     throw Exception('Failed to save image locally: $e');
  //   }
  // }
  //
  // void _showErrorSnackBar(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  // }
  //
  // Widget _buildImageSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: <Widget>[
  //       _buildSectionTitle('Image'),
  //       Container(
  //         height: 120,
  //         decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
  //         child:
  //             widget.entity.imagePath.isNotEmpty
  //                 ? ClipRRect(
  //                   borderRadius: BorderRadius.circular(8),
  //                   child: Image.file(
  //                     File(widget.entity.imagePath),
  //                     fit: BoxFit.cover,
  //                     errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
  //                       return Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image, size: 40, color: Colors.grey));
  //                     },
  //                   ),
  //                 )
  //                 : Container(color: Colors.grey.shade100, child: const Icon(Icons.image, size: 40, color: Colors.grey)),
  //       ),
  //       const SizedBox(height: 8),
  //       Text(
  //         'Current: ${path.basename(widget.entity.imagePath)}',
  //         style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
  //         maxLines: 2,
  //         overflow: TextOverflow.ellipsis,
  //       ),
  //       const SizedBox(height: 8),
  //       SizedBox(
  //         width: double.infinity,
  //         child: ElevatedButton.icon(
  //           onPressed: _pickImage,
  //           icon: const Icon(Icons.photo_library, size: 18),
  //           label: const Text('Choose Image'),
  //           style: ElevatedButton.styleFrom(
  //             padding: const EdgeInsets.symmetric(vertical: 12),
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
