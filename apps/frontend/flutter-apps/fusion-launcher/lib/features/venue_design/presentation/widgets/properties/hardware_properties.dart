import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/models/fusion_models.dart';

class HardwareProperties extends StatefulWidget {
  final FloorModel floorEntity;
  final HardwareComponent hardwareComponent;
  final Function(FloorModel floorEntity) onEntityChanged;
  final Function(HardwareComponent hardwareComponent) onHardwareDelete;

  const HardwareProperties({
    super.key,
    required this.floorEntity,
    required this.hardwareComponent,
    required this.onEntityChanged,
    required this.onHardwareDelete,
  });

  @override
  State<HardwareProperties> createState() => _HardwarePropertiesState();
}

class _HardwarePropertiesState extends State<HardwareProperties> {
  late TextEditingController _nameController;
  late TextEditingController _positionXController;
  late TextEditingController _positionYController;
  late TextEditingController _rotationController;
  late TextEditingController _gainController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant HardwareProperties oldWidget) {
    initializeTexts();
    super.didUpdateWidget(oldWidget);
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.hardwareComponent.name);
    _positionXController = TextEditingController(text: widget.hardwareComponent.pos.dx.toStringAsFixed(2).toString());
    _positionYController = TextEditingController(text: widget.hardwareComponent.pos.dy.toStringAsFixed(2).toString());
    if (widget.hardwareComponent is Speaker) {
      _rotationController = TextEditingController(text: (widget.hardwareComponent as Speaker).rotation.toString());
      _gainController = TextEditingController(text: (widget.hardwareComponent as Speaker).gain.toString());
    } else {
      _rotationController = TextEditingController(text: '0.0');
      _gainController = TextEditingController(text: '0.0');
    }
  }

  void initializeTexts() {
    _nameController.text = widget.hardwareComponent.name;
    _positionXController.text = widget.hardwareComponent.pos.dx.toStringAsFixed(2).toString();
    _positionYController.text = widget.hardwareComponent.pos.dy.toStringAsFixed(2).toString();
    if (widget.hardwareComponent is Speaker) {
      _rotationController.text = (widget.hardwareComponent as Speaker).rotation.toString();
      _gainController.text = (widget.hardwareComponent as Speaker).gain.toString();
    } else {
      _rotationController.text = '0.0';
      _gainController.text = '0.0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rotationController.dispose();
    _gainController.dispose();
    _positionXController.dispose();
    _positionYController.dispose();
    super.dispose();
  }

  void _updateEntity() {
    if (widget.hardwareComponent is Speaker) {
      final Speaker updatedComponent = (widget.hardwareComponent as Speaker).copyWith(
        name: _nameController.text,
        pos: Offset(double.tryParse(_positionXController.text) ?? 0.0, double.tryParse(_positionYController.text) ?? 0.0),
        rotation: double.tryParse(_rotationController.text) ?? 0.0,
        gain: double.tryParse(_gainController.text) ?? 0.0,
      );
      serviceLocator<ProjectViewModel>().updateHardware(updatedComponent);
      serviceLocator<ProjectViewModel>().saveProjectToLocal();
    } else {
      final HardwareComponent updatedComponent = widget.hardwareComponent.copyWith(
        name: _nameController.text,
        pos: Offset(double.tryParse(_positionXController.text) ?? 0.0, double.tryParse(_positionYController.text) ?? 0.0),
      );
      serviceLocator<ProjectViewModel>().updateHardware(updatedComponent);
      serviceLocator<ProjectViewModel>().saveProjectToLocal();
    }
  }

  void _deleteSpeaker() {
    widget.onHardwareDelete(widget.hardwareComponent);
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
      child: TextFormField(
        key: UniqueKey(),
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onFieldSubmitted: (String value) {
          _updateEntity();
        },
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
        _buildSectionTitle('General'),
        const SizedBox(height: 5),
        _buildTextField(label: 'Device Name', controller: _nameController),

        if (widget.hardwareComponent is Speaker) ...<Widget>[
          // Rotation Section
          // _buildSectionTitle('Rotation'),
          // _buildTextField(
          //   label: 'Rotation',
          //   controller: _rotationController,
          //   keyboardType: TextInputType.number,
          //   inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d*'))],
          //   suffix: '°',
          // ),
          // Gain Section
          _buildSectionTitle('Gain'),
          _buildTextField(
            label: 'Gain',
            controller: _gainController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d*'))],
            suffix: 'dB',
          ),
        ],
        // Position Section
        _buildSectionTitle('Position'),
        _buildTextField(
          label: 'X',
          controller: _positionXController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d*'))],
          suffix: ' ',
        ),
        const SizedBox(width: 12),
        _buildTextField(
          label: 'Y',
          controller: _positionYController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^-?\d+\.?\d*'))],
          suffix: ' ',
        ),

        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete, color: Colors.white),
          label: const Text("Delete", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _deleteSpeaker,
        ),
      ],
    );
  }
}
