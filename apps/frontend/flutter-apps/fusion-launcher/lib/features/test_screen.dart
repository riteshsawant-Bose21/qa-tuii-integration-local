/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ProjectTestScreen extends StatefulWidget {
  const ProjectTestScreen({super.key});

  @override
  _ProjectTestScreenState createState() => _ProjectTestScreenState();
}

class _ProjectTestScreenState extends State<ProjectTestScreen> {
  final ProjectService _project = ProjectService(
    id: 'proj1',
    name: 'Demo Project',
    metaData: 'Demo metadata',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    cloudId: "",
    projectName: '',
    colors: <Color>[Colors.redAccent, Colors.green],
    minSPL: 40,
    maxSPL: 90,
  );

  bool _loading = true;
  String? _selectedHardwareId;
  String? _selectedFloorId;
  String? _selectedLAId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Seed data
    final FloorModel floor = FloorModel(id: 'floor1', name: 'Ground', floorPlan: FloorPlanModel.defaultFloorPlan);
    _project.floors.add(floor.id, floor);
    final ListeningArea la = ListeningArea(
      id: 'la1',
      name: 'Main Area',
      vertices: <Offset>[const Offset(0, 0), const Offset(100, 0), const Offset(100, 100), const Offset(0, 100)],
    );
    _project.listeningAreas.add(la.id, la);
    _project.relationships.link(RelationshipType.floorListening, floor.id, la.id);
    final Zone zone = Zone(id: 'zone1', name: 'Main Zone', listeningAreaIds: <String>[la.id]);
    _project.addZone(zone);
    final HardwareComponent hw = Speaker(
      id: 'hw1',
      name: 'Speaker A',
      assetImagePath: '',
      locationEntity: LocationModel(),
      price: 22,
      hardwareName: '',
      pos: const Offset(0, 0),
      speakerSKU: '',
      gain: 2,
      type: OutputType.aes67output,
    );
    _project.addHardware(hw);

    setState(() => _loading = false);
  }

  Future<void> _saveAndRefresh() async {
    setState(() {});
  }

  String _newId(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch}';

  void _onAddFloor() {
    final String id = _newId('floor');
    final FloorModel f = FloorModel(id: id, name: 'Floor ${_project.floors.getAll().length + 1}', floorPlan: FloorPlanModel.defaultFloorPlan);
    _project.floors.add(f.id, f);
    _project.addFloorForRoom(f);
    _saveAndRefresh();
  }

  void _onAddListeningArea() {
    final String id = _newId('la');
    final ListeningArea la = ListeningArea(
      id: id,
      name: 'LA ${_project.listeningAreas.getAll().length + 1}',
      vertices: <Offset>[const Offset(0, 0), const Offset(50, 0), const Offset(50, 50), const Offset(0, 50)],
    );
    _project.listeningAreas.add(la.id, la);
    // if there's a selected floor, link it
    final List<FloorModel> floors = _project.floors.getAll();
    if (floors.isNotEmpty) {
      final FloorModel floor = floors.first;
      _project.relationships.link(RelationshipType.floorListening, floor.id, la.id);
      floor.listeningAreaIds.add(la.id);
    }
    _saveAndRefresh();
  }

  void _onAddZone() {
    final String id = _newId('zone');
    final List<ListeningArea> las = _project.listeningAreas.getAll();
    final Zone zone = Zone(
      id: id,
      name: 'Zone ${_project.zones.getAll().length + 1}',
      listeningAreaIds: las.isNotEmpty ? <String>[las.first.id] : <String>[],
    );
    _project.addZone(zone);
    _saveAndRefresh();
  }

  void _onAddHardware() {
    final String id = _newId('hw');
    final HardwareComponent hw = Speaker(
      id: id,
      name: 'Speaker ${_project.hardware.getAll().length + 1}',
      assetImagePath: '',
      speakerSKU: '',
      gain: 1,
      type: OutputType.analogOutput,
      price: 222,
      locationEntity: LocationModel(),
      pos: const Offset(0, 1),
    );
    _project.addHardware(hw);
    _saveAndRefresh();
  }

  void _onMoveHardwareToLA() {
    if (_selectedHardwareId == null || _selectedLAId == null) return;
    try {
      _project.moveHardware(_selectedHardwareId!, listeningAreaId: _selectedLAId);
      _saveAndRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _onMoveHardwareToFloor() {
    if (_selectedHardwareId == null || _selectedFloorId == null) return;
    try {
      _project.moveHardware(_selectedHardwareId!, floorId: _selectedFloorId);
      _saveAndRefresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _onAddMix() {
    final String id = _newId('mix');
    final SourceSet mix = SourceSet(id: id, name: 'Mix ${_project.mixes.getAll().length + 1}');
    _project.addSourceSet(mix);
    _saveAndRefresh();
  }

  void _showJsonPopup() {
    final String pretty = const JsonEncoder.withIndent('  ').convert(_project.toJson());
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Project JSON'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(pretty),
              ),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<FloorModel> floors = _project.floors.getAll();
    final List<ListeningArea> las = _project.listeningAreas.getAll();
    final List<Zone> zones = _project.zones.getAll();
    final List<HardwareComponent> hws = _project.hardware.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ProjectService Full Demo'),
        actions: <Widget>[
          IconButton(onPressed: _showJsonPopup, icon: const Icon(Icons.code)),
          IconButton(onPressed: _saveAndRefresh, icon: const Icon(Icons.save)),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Project: ${_project.name} (id: ${_project.id})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        ElevatedButton(onPressed: _onAddFloor, child: const Text('Add Floor')),
                        ElevatedButton(onPressed: _onAddListeningArea, child: const Text('Add Listening Area')),
                        ElevatedButton(onPressed: _onAddZone, child: const Text('Add Zone')),
                        ElevatedButton(onPressed: _onAddHardware, child: const Text('Add Speaker')),
                        ElevatedButton(onPressed: _onAddMix, child: const Text('Add Mix')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(child: _buildLeftColumn(hws)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRightColumn(floors, las, zones)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildLeftColumn(List<HardwareComponent> hws) {
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(title: Text('Speakers (${hws.length})')),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: hws.length,
              itemBuilder: (BuildContext context, int i) {
                final HardwareComponent hw = hws[i];
                final LocationModel loc = hw.locationEntity;
                final String subtitle = loc == null ? 'not placed' : 'floor:${loc.floorId ?? '-'} la:${loc.listeningAreaId ?? '-'} zone:${loc.zoneId ?? '-'}';
                return ListTile(
                  title: Text(hw.name),
                  subtitle: Text(subtitle),
                  selected: _selectedHardwareId == hw.id,
                  onTap: () => setState(() => _selectedHardwareId = hw.id),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String val) {
                      if (val == 'remove') {
                        _project.removeHardware(hw.id);
                        _saveAndRefresh();
                        if (_selectedHardwareId == hw.id) _selectedHardwareId = null;
                      }
                    },
                    itemBuilder: (_) => <PopupMenuEntry<String>>[const PopupMenuItem<String>(value: 'remove', child: Text('Remove'))],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn(List<FloorModel> floors, List<ListeningArea> las, List<Zone> zones) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Card(
            child: Column(
              children: <Widget>[
                ListTile(title: Text('Floors (${floors.length})')),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: floors.length,
                    itemBuilder: (BuildContext context, int i) {
                      final FloorModel f = floors[i];
                      return ListTile(
                        title: Text(f.name),
                        subtitle: Text('LAs: ${f.listeningAreaIds.join(', ')}'),
                        selected: _selectedFloorId == f.id,
                        onTap: () => setState(() => _selectedFloorId = f.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            child: Column(
              children: <Widget>[
                ListTile(title: Text('Listening Areas (${las.length})')),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: las.length,
                    itemBuilder: (BuildContext context, int i) {
                      final ListeningArea la = las[i];
                      return ListTile(
                        title: Text(la.name),
                        selected: _selectedLAId == la.id,
                        onTap: () => setState(() => _selectedLAId = la.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            child: Column(
              children: <Widget>[
                ListTile(title: Text('Zones (${zones.length})')),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: zones.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Zone z = zones[i];
                      return ListTile(
                        title: Text(z.name),
                        subtitle: Text('LAs: ${z.listeningAreasIds.join(', ')} mixes:${z.mixIds.join(', ')}'),
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: ElevatedButton(onPressed: _onMoveHardwareToLA, child: const Text('Move Speaker → selected LA'))),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(onPressed: _onMoveHardwareToFloor, child: const Text('Move Speaker → selected Floor'))),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Select a speaker on left, then select a target floor / listening area on right.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
*/
