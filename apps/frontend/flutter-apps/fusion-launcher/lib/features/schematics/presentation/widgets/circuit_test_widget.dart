import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../configuration/presentation/widgets/common/location_configuration_widget.dart';
import '../../../product_query/presentation/pages/product_query.dart';

class ZoneCircuitConfigPage extends StatefulWidget {
  const ZoneCircuitConfigPage({super.key});

  @override
  State<ZoneCircuitConfigPage> createState() => _ZoneCircuitConfigPageState();
}

class _ZoneCircuitConfigPageState extends State<ZoneCircuitConfigPage> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {},
      builder: (BuildContext context, ProjectViewModelState state) {
        final List<Zone> zones = serviceLocator<ProjectViewModel>().zones;
        final List<Speaker> speakers = serviceLocator<ProjectViewModel>().speakers;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Row(
            children: <Widget>[
              // Left Sidebar
              Container(
                width: 280,
                color: const Color(0xFF1E293B),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.audio_file, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Zone Config',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[
                          _buildSidebarButton(
                            icon: Icons.add_circle_outline,
                            label: 'Add Zone',
                            onTap: () => _showAddZoneDialog(),
                          ),
                          const SizedBox(height: 8),
                          _buildSidebarButton(
                            icon: Icons.add_location_alt_outlined,
                            label: 'Add Location',
                            onTap: () async {
                              final LocationModel? location = await showConfigureDeviceDialog(
                                context,
                                LocationModel(),
                                (FloorModel newFloor) {
                                  // serviceLocator<ProjectViewModel>().addFloor(newFloor);
                                },
                                (FloorModel updatedFloor) {
                                  // serviceLocator<ProjectViewModel>().updateFloor(updatedFloor);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Column(
                  children: <Widget>[
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Text(
                            'Zone Configuration',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${zones.length} Zones • ${speakers.length} Speakers',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child:
                          zones.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                padding: const EdgeInsets.all(24),
                                itemCount: zones.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return _buildZoneCard(zones[index]);
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.speaker_group_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No zones configured yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add Zone" to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  Widget _buildZoneCard(Zone zone) {
    final Color zoneColor = _parseColor(zone.zoneColor);

    final List<SubZone> subZones = getSubZonesForZone(zone.id);
    final List<ListeningArea> listeningAreas = getListeningAreasForZone(zone.id);
    final List<CircuitModel> circuits = getCircuitForZone(zone.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: zoneColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: zoneColor),
          ),
          title: Text(
            zone.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            '${listeningAreas.length} Listening Areas • ${circuits.length} Circuits • ${subZones.length} SubZones',
            style: const TextStyle(fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => _showZoneOptionsDialog(zone),
                tooltip: 'Add to Zone',
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditZoneDialog(zone),
                tooltip: 'Edit Zone',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteZone(zone),
                tooltip: 'Delete Zone',
              ),
            ],
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (circuits.isNotEmpty) ...<Widget>[
                    _buildSectionHeader('Circuits', circuits.length),
                    const SizedBox(height: 8),
                    ...circuits.map((CircuitModel circuit) {
                      return _buildCircuitTile(circuit, zone, null);
                    }),
                    const SizedBox(height: 16),
                  ],
                  if (subZones.isNotEmpty) ...<Widget>[
                    _buildSectionHeader('SubZones', subZones.length),
                    const SizedBox(height: 8),
                    ...subZones.map((SubZone subZone) {
                      return _buildSubZoneTile(subZone, zone);
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircuitTile(CircuitModel circuit, Zone zone, SubZone? subZone) {
    final List<Speaker> circuitSpeakers = _getSpeakersInCircuit(circuit.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cable, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  circuit.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${circuitSpeakers.length} Speakers',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Zone: ${serviceLocator<ProjectViewModel>().getZoneForHardware(hardwareId: circuitSpeakers.first.id)?.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'SubZone: ${serviceLocator<ProjectViewModel>().getSubZoneForHardware(hardwareId: circuitSpeakers.first.id)?.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () {
              final Speaker speaker = circuitSpeakers.last;
              decrementHardwareInCircuit(speaker.id);
            },
            tooltip: 'remove Speaker',
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {
              final Speaker speaker = circuitSpeakers.first.getClone();
              incrementHardwareInCircuit(speaker, circuit.id);
            },
            tooltip: 'Add Speaker',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _deleteCircuit(circuit, zone, subZone),
            tooltip: 'Delete Circuit',
          ),
        ],
      ),
    );
  }

  Widget _buildSubZoneTile(SubZone subZone, Zone zone) {
    final List<CircuitModel> circuits = getCircuitForSubZone(subZone.id);
    final List<ListeningArea> listeningAreas = getListeningAreasForSubZone(subZone.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: Icon(Icons.folder, color: zone.color),
        title: Text(
          subZone.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${listeningAreas.length} Listening Areas • ${circuits.length} Circuits',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              onPressed: () => _showAddCircuitDialog(zone, subZone),
              tooltip: 'Add Circuit',
            ),
            //edit
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _showEditSubZoneDialog(subZone, zone),
              tooltip: 'Edit SubZone',
            ),

            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _deleteSubZone(subZone, zone),
              tooltip: 'Delete SubZone',
            ),
          ],
        ),
        children: <Widget>[
          if (circuits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children:
                    circuits.map((CircuitModel circuit) {
                      return _buildCircuitTile(circuit, zone, subZone);
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddZoneDialog() {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    final List<String> selectedListeningAreas = <String>[];
    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().listeningAreas;
    showDialog(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder:
                (BuildContext context, dynamic setDialogState) => AlertDialog(
                  title: const Text('Add New Zone'),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Zone Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.label),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Zone Color', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                <MaterialColor>[
                                  Colors.blue,
                                  Colors.red,
                                  Colors.green,
                                  Colors.orange,
                                  Colors.purple,
                                  Colors.teal,
                                ].map((MaterialColor color) {
                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedColor = color;
                                      });
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selectedColor == color ? Colors.black : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text('Listening Areas', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              children:
                                  listeningAreas.map((ListeningArea area) {
                                    return CheckboxListTile(
                                      title: Text(area.name),
                                      value: selectedListeningAreas.contains(area.id),
                                      onChanged: (bool? value) {
                                        setDialogState(() {
                                          if (value == true) {
                                            selectedListeningAreas.add(area.id);
                                          } else {
                                            selectedListeningAreas.remove(area.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          addZone(
                            nameController.text,
                            '#${selectedColor.value.toRadixString(16).substring(2)}',
                            selectedListeningAreas,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add Zone'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditZoneDialog(Zone zone) {
    final TextEditingController nameController = TextEditingController(text: zone.name);
    Color selectedColor = _parseColor(zone.zoneColor);
    final List<ListeningArea> zoneAreas = getListeningAreasForZone(zone.id);
    final List<String> selectedListeningAreas = zoneAreas.map((ListeningArea e) => e.id).toList();

    final List<ListeningArea> availableAreas = serviceLocator<ProjectViewModel>().getAvailableListeningAreasForZone(id: zone.id);

    showDialog(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder:
                (BuildContext context, dynamic setDialogState) => AlertDialog(
                  title: const Text('Edit Zone'),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Zone Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.label),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Zone Color', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                <Color>[
                                  Colors.blue,
                                  Colors.red,
                                  Colors.green,
                                  Colors.orange,
                                  Colors.purple,
                                  Colors.teal,
                                ].map((Color color) {
                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedColor = color;
                                      });
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selectedColor == color ? Colors.black : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text('Listening Areas', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              children:
                                  availableAreas.map((ListeningArea area) {
                                    return CheckboxListTile(
                                      title: Text(area.name),
                                      value: selectedListeningAreas.contains(area.id),
                                      onChanged: (bool? value) {
                                        setDialogState(() {
                                          if (value == true) {
                                            selectedListeningAreas.add(area.id);
                                          } else {
                                            selectedListeningAreas.remove(area.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          updateZone(
                            zone.id,
                            name: nameController.text,
                            color: '#${selectedColor.value.toRadixString(16).substring(2)}',
                            listeningAreaIds: selectedListeningAreas,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Update Zone'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showZoneOptionsDialog(Zone zone) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text('Add to ${zone.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.cable),
                  title: const Text('Add Circuit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddCircuitDialog(zone, null);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Add SubZone'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddSubZoneDialog(zone);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showAddCircuitDialog(Zone zone, SubZone? subZone) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController numberOfSpeakers = TextEditingController(text: "1");
    String? selectedListeningAreaId;
    List<ListeningArea> listeningAreas = <ListeningArea>[];

    if (subZone != null) {
      listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(subZoneId: subZone.id);
    } else {
      listeningAreas = serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: zone.id);
    }

    ProductQueryModel? speakerData;

    showDialog(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setDialogState) {
              return AlertDialog(
                title: Text('Add Circuit to ${subZone?.name ?? zone.name}'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Speakers list
                        ...ProductAPI.getSpeakerProducts().map(
                          (ProductQueryModel item) => InkWell(
                            onTap: () {
                              setDialogState(() {
                                speakerData = item;
                              });
                            },
                            child: Container(
                              height: 30,
                              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: speakerData?.sku == item.sku ? Colors.blueAccent : Theme.of(context).colorScheme.outlineVariant,
                                  width: 1,
                                ),
                                color: speakerData?.sku == item.sku ? Colors.blueAccent.withOpacity(0.1) : null,
                              ),
                              child: Row(
                                children: <Widget>[
                                  FusionImage.asset(
                                    item.image.isNotEmpty ? item.image : '',
                                    height: 14,
                                    width: 14,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FusionAppText(
                                      text: item.name,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Speakers count',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: numberOfSpeakers,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Number of Speakers',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          onChanged: (String value) {
                            setDialogState(() {
                              final int count = int.tryParse(value) ?? 1;
                              if (count < 1 || count > 25) {
                                numberOfSpeakers.text = '1';
                                FusionToast.error(context, message: "Count should be between 1 and 25");
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Listening Area',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),

                        // FIXED: ListView replaced with constrained scrollable area
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              child: Column(
                                children:
                                    listeningAreas.map((ListeningArea area) {
                                      return RadioListTile<String>(
                                        title: Text(area.name),
                                        value: area.id,
                                        groupValue: selectedListeningAreaId,
                                        onChanged: (String? value) {
                                          setDialogState(() {
                                            selectedListeningAreaId = value;
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Circuit Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.cable),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        if (speakerData != null && selectedListeningAreaId != null) {
                          createCircuitWithSpeaker(
                            speakerData: speakerData!,
                            listeningAreaId: selectedListeningAreaId!,
                            speakerCount: int.tryParse(numberOfSpeakers.text) ?? 1,
                            zoneId: zone.id,
                            subZoneId: subZone?.id,
                            circuitName: nameController.text,
                          );
                          Navigator.pop(context);
                        } else {
                          FusionToast.error(context, message: "Please select a speaker and listening area");
                        }
                      }
                    },
                    child: const Text('Add Circuit'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showAddSubZoneDialog(Zone zone) {
    final TextEditingController nameController = TextEditingController();
    final List<String> selectedListeningAreas = <String>[];
    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().getAvailableListeningAreasForSubZone(parentZoneId: zone.id);
    showDialog(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder:
                (BuildContext context, dynamic setDialogState) => AlertDialog(
                  title: Text('Add SubZone to ${zone.name}'),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'SubZone Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.folder),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Listening Areas', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              children:
                                  listeningAreas.map((ListeningArea area) {
                                    return CheckboxListTile(
                                      title: Text(area.name),
                                      value: selectedListeningAreas.contains(area.id),
                                      onChanged: (bool? value) {
                                        setDialogState(() {
                                          if (value == true) {
                                            selectedListeningAreas.add(area.id);
                                          } else {
                                            selectedListeningAreas.remove(area.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          addSubZoneToZone(nameController.text, selectedListeningAreas, zone.id);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add SubZone'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditSubZoneDialog(SubZone subZone, Zone zone) {
    final TextEditingController nameController = TextEditingController(text: subZone.name);
    final List<ListeningArea> subZoneAreas = getListeningAreasForSubZone(subZone.id);
    final List<String> selectedListeningAreas = subZoneAreas.map((ListeningArea e) => e.id).toList();

    final List<ListeningArea> availableAreas = serviceLocator<ProjectViewModel>().getAvailableListeningAreasForSubZone(
      parentZoneId: zone.id,
      subZoneId: subZone.id,
    );

    showDialog(
      context: context,
      builder:
          (BuildContext context) => StatefulBuilder(
            builder:
                (BuildContext context, dynamic setDialogState) => AlertDialog(
                  title: const Text('Edit SubZone'),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'SubZone Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.folder),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Listening Areas', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              children:
                                  availableAreas.map((ListeningArea area) {
                                    return CheckboxListTile(
                                      title: Text(area.name),
                                      value: selectedListeningAreas.contains(area.id),
                                      onChanged: (bool? value) {
                                        setDialogState(() {
                                          if (value == true) {
                                            selectedListeningAreas.add(area.id);
                                          } else {
                                            selectedListeningAreas.remove(area.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          updateSubZone(
                            subZone.id,
                            name: nameController.text,
                            listeningAreaIds: selectedListeningAreas,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Update SubZone'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showAddSpeakerToCircuitDialog(CircuitModel circuit) {
    final List<Speaker> circuitSpeakers = _getSpeakersInCircuit(circuit.id);

    final List<Speaker> speakers = serviceLocator<ProjectViewModel>().speakers;

    final List<Speaker> availableSpeakers =
        speakers.where((Speaker s) {
          if (circuitSpeakers.isEmpty) return true;
          return s.speakerSKU == circuitSpeakers.first.speakerSKU;
        }).toList();

    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text('Add Speaker to ${circuit.name}'),
            content: SizedBox(
              width: 300,
              child:
                  availableSpeakers.isEmpty
                      ? const Text('No compatible speakers available')
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableSpeakers.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Speaker speaker = availableSpeakers[index];
                          return ListTile(
                            leading: const Icon(Icons.speaker),
                            title: Text(speaker.name),
                            subtitle: Text('SKU: ${speaker.speakerSKU}'),
                            onTap: () {
                              addSpeakerToCircuit(speaker.id, circuit.id);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
            ),
          ),
    );
  }

  List<CircuitModel> getCircuitForZone(String zoneId) {
    return serviceLocator<ProjectViewModel>().getCircuitsInZone(zoneId);
  }

  List<CircuitModel> getCircuitForSubZone(String subZoneId) {
    return serviceLocator<ProjectViewModel>().getCircuitsInSubZone(subZoneId: subZoneId);
  }

  List<ListeningArea> getListeningAreasForZone(String zoneId) {
    return serviceLocator<ProjectViewModel>().getListeningAreasForZone(zoneId: zoneId);
  }

  List<ListeningArea> getListeningAreasForSubZone(String subZoneId) {
    return serviceLocator<ProjectViewModel>().getListeningAreasInSubZone(subZoneId: subZoneId);
  }

  List<SubZone> getSubZonesForZone(String zoneId) {
    return serviceLocator<ProjectViewModel>().getSubZonesForZone(parentZoneId: zoneId);
  }

  void _deleteZone(Zone zone) {
    removeZone(zone.id);
  }

  void _deleteCircuit(CircuitModel circuit, Zone zone, SubZone? subZone) {
    if (subZone != null) {
      removeCircuitFromSubZone(circuit.id, subZone.id);
    } else {
      removeCircuitFromZone(circuit.id, zone.id);
    }
  }

  void _deleteSubZone(SubZone subZone, Zone zone) {
    removeSubZoneFromZone(subZone.id, zone.id);
  }

  CircuitModel? _findCircuitById(String id) {
    return serviceLocator<ProjectViewModel>().getCircuitById(circuitId: id);
  }

  SubZone? _findSubZoneById(String id) {
    return serviceLocator<ProjectViewModel>().getSubZone(subZoneId: id);
  }

  List<Speaker> _getSpeakersInCircuit(String circuitId) {
    return serviceLocator<ProjectViewModel>().getHardwareForCircuit(circuitId: circuitId).whereType<Speaker>().toList();
  }

  // CRUD Methods for Zone
  void addZone(String name, String color, List<String> listeningAreaIds) {
    final Zone newZone = Zone(
      id: 'zone_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      selectedMixIndex: 0,
      zoneColor: color,
    );
    serviceLocator<ProjectViewModel>().recordSnapshot();
    serviceLocator<ProjectViewModel>().addZone(zone: newZone, autoSave: false);
    serviceLocator<ProjectViewModel>().updateListeningAreasInZone(zoneId: newZone.id, listeningAreaIds: listeningAreaIds, autoSave: false);
    serviceLocator<ProjectViewModel>().saveProject();
  }

  void updateZone(String zoneId, {String? name, String? color, List<String>? listeningAreaIds}) {
    final Zone? zone = serviceLocator<ProjectViewModel>().getZone(zoneId: zoneId);
    if (zone == null) {
      return;
    }

    final Zone updatedZone = zone.copyWith(
      name: name ?? zone.name,
      zoneColor: color ?? zone.zoneColor,
    );

    serviceLocator<ProjectViewModel>().recordSnapshot();
    serviceLocator<ProjectViewModel>().updateZone(zone: updatedZone, autoSave: false);
    if (listeningAreaIds != null) {
      serviceLocator<ProjectViewModel>().updateListeningAreasInZone(zoneId: zoneId, listeningAreaIds: listeningAreaIds, autoSave: false);
    }
    serviceLocator<ProjectViewModel>().saveProject();
  }

  void removeZone(String zoneId) {
    serviceLocator<ProjectViewModel>().removeZone(zoneId: zoneId);
  }

  // CRUD Methods for Circuit
  void addNewCircuitToZone(String? circuitName, String zoneId) {
    final CircuitModel circuitModel = CircuitModel(name: circuitName ?? "Circuit ${serviceLocator<ProjectViewModel>().circuits.length + 1}");
    serviceLocator<ProjectViewModel>().addCircuit(
      circuit: circuitModel,
    );

    serviceLocator<ProjectViewModel>().addCircuitToZone(circuitId: circuitModel.id, zoneId: zoneId);
  }

  void addCircuitToSubZone(String circuitName, String subZoneId) {
    final CircuitModel circuitModel = CircuitModel(name: "Circuit ${serviceLocator<ProjectViewModel>().circuits.length + 1}");
    serviceLocator<ProjectViewModel>().addCircuit(
      circuit: circuitModel,
    );

    serviceLocator<ProjectViewModel>().addCircuitToSubZone(subZoneId: subZoneId, circuitId: circuitModel.id);
  }

  void updateCircuit(String circuitId, String newName) {
    final CircuitModel? circuit = serviceLocator<ProjectViewModel>().getCircuitById(circuitId: circuitId);
    if (circuit == null) {
      return;
    }

    final CircuitModel updatedCircuit = circuit.copyWith(
      name: newName,
    );

    serviceLocator<ProjectViewModel>().updateCircuit(circuit: updatedCircuit);
  }

  void removeCircuitFromZone(String circuitId, String zoneId) {
    serviceLocator<ProjectViewModel>().removeCircuitFromZone(circuitId: circuitId, zoneId: zoneId);
  }

  void removeCircuitFromSubZone(String circuitId, String subZoneId) {
    serviceLocator<ProjectViewModel>().removeCircuitFromSubZone(subZoneId: subZoneId, circuitId: circuitId);
  }

  // CRUD Methods for SubZone
  void addSubZoneToZone(String subZoneName, List<String> listeningAreaIds, String zoneId) {
    final SubZone newSubZone = SubZone(
      id: 'subzone_${DateTime.now().millisecondsSinceEpoch}',
      name: subZoneName,
    );

    serviceLocator<ProjectViewModel>().recordSnapshot();
    serviceLocator<ProjectViewModel>().addSubZone(subZone: newSubZone, autoSave: false);
    serviceLocator<ProjectViewModel>().addSubZoneToZone(subZoneId: newSubZone.id, parentZoneId: zoneId, autoSave: false);
    serviceLocator<ProjectViewModel>().updateListeningAreasInSubZone(subZoneId: newSubZone.id, listeningAreaIds: listeningAreaIds, autoSave: false);
    serviceLocator<ProjectViewModel>().saveProject();
  }

  void updateSubZone(String subZoneId, {String? name, List<String>? listeningAreaIds}) {
    final SubZone? subZone = serviceLocator<ProjectViewModel>().getSubZone(subZoneId: subZoneId);
    if (subZone == null) {
      return;
    }

    final SubZone updatedSubZone = subZone.copyWith(
      name: name ?? subZone.name,
    );
    serviceLocator<ProjectViewModel>().recordSnapshot();
    serviceLocator<ProjectViewModel>().updateSubZone(subZone: updatedSubZone, autoSave: false);

    if (listeningAreaIds != null) {
      serviceLocator<ProjectViewModel>().updateListeningAreasInSubZone(subZoneId: subZoneId, listeningAreaIds: listeningAreaIds, autoSave: false);
    }
    serviceLocator<ProjectViewModel>().saveProject();
  }

  void removeSubZoneFromZone(String subZoneId, String zoneId) {
    serviceLocator<ProjectViewModel>().removeSubZoneFromZone(subZoneId: subZoneId, parentZoneId: zoneId);
  }

  void createCircuitWithSpeaker({
    required ProductQueryModel speakerData,
    required String listeningAreaId,
    required int speakerCount,
    String? circuitName,
    String? subZoneId,
    required String zoneId,
  }) {
    serviceLocator<ProjectViewModel>().createCircuitWithSpeakers(
      speakerData: speakerData,
      listeningAreaId: listeningAreaId,
      speakerCount: speakerCount,
      circuitName: circuitName,
      subZoneId: subZoneId,
      zoneId: zoneId,
    );
  }

  void updateSpeaker(String speakerId, {String? name, String? sku, String? listeningAreaId}) {
    final Speaker speaker = serviceLocator<ProjectViewModel>().getHardware(hardwareId: speakerId) as Speaker;

    final Speaker updatedSpeaker = speaker.copyWith(
      name: name ?? speaker.name,
      speakerSKU: sku ?? speaker.speakerSKU,
      locationEntity:
          listeningAreaId != null
              ? LocationModel(
                id: speaker.locationEntity.id,
                listeningAreaId: listeningAreaId,
                floorId: speaker.locationEntity.floorId,
              )
              : speaker.locationEntity,
    );

    serviceLocator<ProjectViewModel>().updateHardware(hardware: updatedSpeaker);
  }

  void removeSpeaker(String speakerId) {
    serviceLocator<ProjectViewModel>().removeHardware(hardwareId: speakerId);
  }

  void addSpeakerToCircuit(String speakerId, String circuitId) {
    serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speakerId, circuitId: circuitId);
  }

  void incrementHardwareInCircuit(Speaker speaker, String circuitId) {
    serviceLocator<ProjectViewModel>().addHardware(hardware: speaker, autoSave: false);
    serviceLocator<ProjectViewModel>().addHardwareToCircuit(hwId: speaker.id, circuitId: circuitId);
  }

  void decrementHardwareInCircuit(String speakerId) {
    serviceLocator<ProjectViewModel>().removeHardware(hardwareId: speakerId);
  }

  void removeSpeakerFromCircuit(String speakerId, String circuitId) {
    serviceLocator<ProjectViewModel>().removeHardwareFromCircuit(hwId: speakerId, circuitId: circuitId);
  }
}
