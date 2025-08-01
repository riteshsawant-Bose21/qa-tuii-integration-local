import 'package:flutter/material.dart';

import '../../../../../core/models/floor_entity.dart';
import '../../../../../core/models/listening_area_entity.dart';

class SurfaceProperties extends StatefulWidget {
  final Floor floorEntity;
  final ListeningArea canvasSurface;
  final ValueChanged<Floor> onEntityChanged;
  final ValueChanged<ListeningArea> onSurfaceDelete;

  const SurfaceProperties({
    Key? key,
    required this.floorEntity,
    required this.canvasSurface,
    required this.onEntityChanged,
    required this.onSurfaceDelete,
  }) : super(key: key);

  @override
  _SurfacePropertiesState createState() => _SurfacePropertiesState();
}

class _SurfacePropertiesState extends State<SurfaceProperties> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.canvasSurface.name);
  }

  @override
  void didUpdateWidget(covariant SurfaceProperties old) {
    super.didUpdateWidget(old);
    // if the surface instance changes, reset the controller
    if (old.canvasSurface.id != widget.canvasSurface.id) {
      _nameController.text = widget.canvasSurface.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateEntity(ListeningArea updated) {
    final List<ListeningArea> listeningAreas = List<ListeningArea>.from(widget.floorEntity.listeningAreas);
    final int idx = listeningAreas.indexWhere((ListeningArea s) => s.id == updated.id);
    if (idx != -1) listeningAreas[idx] = updated;
    final Floor newFloor = widget.floorEntity.copyWith(listeningAreas: listeningAreas);
    widget.onEntityChanged(newFloor);
  }

  void _deleteEntity() => widget.onSurfaceDelete(widget.canvasSurface);

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── Surface Name ───────────────────────────────────────────────
        _buildSectionTitle('Listening Area'),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter a name for this listening area',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onFieldSubmitted: (String val) {
            final ListeningArea updated = widget.canvasSurface.copyWith(name: val);
            _updateEntity(updated);
          },
        ),

        // … your existing for-loop of X/Y textfields …
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete, color: Colors.white),
          label: const Text("Delete", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _deleteEntity,
        ),
      ],
    );
  }
}
