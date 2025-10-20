import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/service_locator.dart';
import '../../viewmodel/project_view_model.dart';

/// Multi‐selection device picker dialog (unchanged)
class MultiMixPickerDialog extends StatefulWidget {
  final String title;
  final List<SourceSet> devices;
  final List<SourceSet> initiallySelected;

  const MultiMixPickerDialog({
    super.key,
    required this.title,
    required this.devices,
    required this.initiallySelected,
  });

  @override
  MultiMixPickerDialogState createState() => MultiMixPickerDialogState();
}

class MultiMixPickerDialogState extends State<MultiMixPickerDialog> {
  late final Set<SourceSet> _selected;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected.toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SourceSet> get _filteredDevices {
    if (_searchQuery.isEmpty) return widget.devices;
    return widget.devices.where((SourceSet device) {
      return device.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: Colors.white,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Mix...',
              prefixIcon: const Icon(Icons.search),
              prefixStyle: const TextStyle(
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (String value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400, // Fixed height for better UX
        child: Column(
          children: <Widget>[
            // Selected count indicator
            if (_selected.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selected.length} Mix${_selected.length == 1 ? '' : 's'} selected',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ),

            // Device list
            Expanded(
              child:
                  _filteredDevices.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No mixes found',
                              style: TextStyle(
                                color: theme.colorScheme.outline,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _filteredDevices.length,
                        itemBuilder: (BuildContext context, int index) {
                          final SourceSet mix = _filteredDevices[index];
                          final bool isSelected = _selected.contains(mix);

                          final List<Source> sourcesInSet = serviceLocator<ProjectViewModel>().getSourcesInSourceSet(sourceSetId: mix.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            color: isSelected ? theme.colorScheme.surface : Colors.white30,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? Colors.grey.shade400 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selected.remove(mix);
                                  } else {
                                    _selected.add(mix);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: <Widget>[
                                    // Selection indicator
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                                          width: 2,
                                        ),
                                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                      ),
                                      child:
                                          isSelected
                                              ? Icon(
                                                Icons.check,
                                                size: 16,
                                                color: theme.colorScheme.onPrimary,
                                              )
                                              : null,
                                    ),

                                    const SizedBox(width: 12),

                                    // Device icon based on type
                                    Icon(
                                      Icons.shuffle,
                                      size: 24,
                                      color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                                    ),

                                    const SizedBox(width: 12),

                                    // Device information
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          // Device name
                                          Text(
                                            mix.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 14,
                                              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // Device details row
                                          Row(
                                            children: <Widget>[
                                              // Device type
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.outline.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  "${sourcesInSet.length.toString().toUpperCase()} Source${sourcesInSet.length == 1 ? '' : 's'}",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme.colorScheme.outline,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
          child: Text('Select (${_selected.length})'),
        ),
      ],
    );
  }

  String getLocation(LocationModel location) {
    if (location.floorId != null && location.listeningAreaId != null) {
      final FloorModel floor = serviceLocator<ProjectViewModel>().getFloorById(floorId: location.floorId!);
      final ListeningArea area = serviceLocator<ProjectViewModel>().getListeningArea(areaId: location.listeningAreaId!);
      return "${floor.name}/${area.name}"; // Display floor and listening area names
    } else if (location.floorId != null) {
      final FloorModel floor = serviceLocator<ProjectViewModel>().getFloorById(floorId: location.floorId!);
      return floor.name; // Display floor number
    } else if (location.listeningAreaId != null) {
      return "Listening Area ${location.listeningAreaId}"; // Display listening area number
    }
    return "No Location";
  }
}
