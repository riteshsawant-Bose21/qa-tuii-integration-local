import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class ListeningAreaProperties extends StatelessWidget {
  final ListeningArea selectedListeningArea;

  ListeningAreaProperties({
    super.key,
    required this.selectedListeningArea,
  });

  final List<String> venueOptions = <String>[
    "Indoor",
    "Outdoor",
    "Mixed",
    "Stadium",
  ];

  final List<String> listeningHeightOptions = <String>[
    "Sitting",
    "Standing",
    "Custom",
  ];

  // Map display options to actual values
  final Map<String, double> listeningHeightValues = <String, double>{
    "Sitting": 3.0,
    "Standing": 6.0,
    "Custom": 1.0,
  };

  final List<String> splRangeOptions = <String>[
    "Background Music",
    "Paging",
    "Foreground Music",
    "Moderate live sound reinforcement",
    "High-SPL live sound reinforcement",
  ];

  final TextEditingController ceilingHeightController = TextEditingController();
  final TextEditingController listeningAreaController = TextEditingController();
  final TextEditingController customListeningHeightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();

    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        ceilingHeightController.text = selectedListeningArea.ceilingHeight;
        listeningAreaController.text = selectedListeningArea.name;

        // Determine display value and if custom is selected based on listeningHeight double value
        String displayValue;
        bool isCustomListeningHeight = false;

        if (selectedListeningArea.listeningHeight == 3.0) {
          displayValue = "Sitting";
        } else if (selectedListeningArea.listeningHeight == 6.0) {
          displayValue = "Standing";
        } else {
          displayValue = "Custom";
          isCustomListeningHeight = true;
          customListeningHeightController.text = selectedListeningArea.listeningHeight.toString();
        }

        //prepare List<PropertyRow> rows from selectedListeningArea vertices
        final List<PropertyRow> rows =
            selectedListeningArea.vertices.asMap().entries.map((MapEntry<int, Offset> entry) {
              final int index = entry.key + 1; // Start index from 1
              final Offset vertex = entry.value;
              return PropertyRow(
                title: "P $index",
                x: double.parse(vertex.dx.toStringAsFixed(2)),
                y: double.parse(vertex.dy.toStringAsFixed(2)),
                z: 0.0,
              );
            }).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header section with name and delete button
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: TextFormField(
                      controller: listeningAreaController,
                      decoration: const InputDecoration(
                        hintText: 'Area Name',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      onFieldSubmitted: (String v) {
                        final ListeningArea updatedLA = selectedListeningArea.copyWith(name: v);
                        viewModel.updateListeningArea(updatedLA);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  //small delete icon button to delete the selectedListeningArea
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      viewModel.removeListeningArea(selectedListeningArea.id);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Properties section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Properties',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.fusionTextViewColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLAPropertyRow(
                    context: context,
                    label: "Zone",
                    value: viewModel.getZonesForListeningArea(selectedListeningArea.id)?.name ?? "N/A",
                    options: viewModel.zones.map((Zone zone) => zone.name).toList(),
                    onOptionSelected: (int selectedIndex) {
                      final Zone selectedZone = viewModel.zones[selectedIndex];
                      viewModel.addListeningAreaToZone(selectedListeningArea.id, selectedZone.id);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLAPropertyRow(
                    context: context,
                    label: "Type",
                    value: selectedListeningArea.venuType,
                    options: venueOptions,
                    onOptionSelected: (int selectedIndex) {
                      final String selectedType = venueOptions[selectedIndex];
                      final ListeningArea updatedLA = selectedListeningArea.copyWith(venuType: selectedType);
                      viewModel.updateListeningArea(updatedLA);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildLAPropertyRow(
                    context: context,
                    label: "Listening Ht",
                    value: displayValue,
                    options: listeningHeightOptions,
                    onOptionSelected: (int selectedIndex) {
                      final String selectedOption = listeningHeightOptions[selectedIndex];
                      final double heightValue = listeningHeightValues[selectedOption] ?? 3.0;

                      final ListeningArea updatedLA = selectedListeningArea.copyWith(listeningHeight: heightValue);
                      viewModel.updateListeningArea(updatedLA);
                    },
                  ),

                  // Show custom listening height text field if "Custom" is selected
                  if (isCustomListeningHeight) ...<Widget>[
                    const SizedBox(height: 10),
                    _buildPropertyRowForTextField(
                      context: context,
                      label: "Custom Height",
                      controller: customListeningHeightController,
                      hintText: "e.g., 4.5",
                      onSubmit: (String newValue) {
                        final double? customHeight = double.tryParse(newValue);
                        if (customHeight != null) {
                          final ListeningArea updatedLA = selectedListeningArea.copyWith(listeningHeight: customHeight);
                          viewModel.updateListeningArea(updatedLA);
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 10),
                  _buildLAPropertyRow(
                    context: context,
                    label: "SPL Range",
                    value: _getCurrentSplRange(selectedListeningArea.minSPL, selectedListeningArea.maxSPL),
                    options: splRangeOptions,
                    onOptionSelected: (int selectedIndex) {
                      // Set min/max SPL values based on selection
                      double minSPL, maxSPL;
                      switch (selectedIndex) {
                        case 0: // Background Music
                          minSPL = 60.0;
                          maxSPL = 70.0;
                          break;
                        case 1: // Paging
                          minSPL = 70.0;
                          maxSPL = 80.0;
                          break;
                        case 2: // Foreground Music
                          minSPL = 75.0;
                          maxSPL = 90.0;
                          break;
                        case 3: // Moderate live sound reinforcement
                          minSPL = 90.0;
                          maxSPL = 100.0;
                          break;
                        case 4: // High-SPL live sound reinforcement
                          minSPL = 100.0;
                          maxSPL = 120.0;
                          break;
                        default:
                          minSPL = 60.0;
                          maxSPL = 70.0;
                      }

                      final ListeningArea updatedLA = selectedListeningArea.copyWith(
                        minSPL: minSPL,
                        maxSPL: maxSPL,
                      );
                      viewModel.updateListeningArea(updatedLA);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildPropertyRowForTextField(
                    context: context,
                    label: "Ceiling Ht",
                    controller: ceilingHeightController,
                    hintText: "e.g., 10 ft",
                    onSubmit: (String newValue) {
                      final ListeningArea updatedLA = selectedListeningArea.copyWith(ceilingHeight: newValue);
                      viewModel.updateListeningArea(updatedLA);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Vertices section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Vertices',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.fusionTextViewColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PropertyListWidget(
                    rows: rows,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a dropdown row displaying a property label and its selectable value.
  Widget _buildLAPropertyRow({
    required BuildContext context,
    required String label,
    required String value,
    List<String>? options,
    required Function(int selectedIndex) onOptionSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: (String newValue) {
        final int selectedIndex = options?.indexOf(newValue) ?? -1;
        if (selectedIndex != -1) {
          onOptionSelected(selectedIndex);
        }
      },
      constraints: const BoxConstraints(maxHeight: 600, minWidth: 200),
      padding: EdgeInsets.zero,
      offset: const Offset(50, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
      ),
      color: Theme.of(context).colorScheme.white,
      elevation: 1,
      itemBuilder: (BuildContext context) {
        if (options == null || options.isEmpty) {
          return <PopupMenuEntry<String>>[];
        }

        return options.map((String option) {
          return PopupMenuItem<String>(
            value: option,
            child: FusionAppText(
              text: option,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left: Label
            FusionAppText(
              text: label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.fusionTextViewColor.withValues(alpha: 0.5),
              ),
            ),
            // Right: Value + Arrow
            Container(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: FusionAppText(
                      text: value,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.fusionTextViewColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRowForTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    String? hintText,
    Function(String)? onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Left: Label
          FusionAppText(
            text: label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.fusionTextViewColor.withValues(alpha: 0.5),
            ),
          ),

          // Right: TextField
          SizedBox(
            width: 100,
            height: 28,
            child: TextField(
              controller: controller,
              onSubmitted: onSubmit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.fusionTextViewColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.fusionTextViewColor.withValues(alpha: 0.5),
                ),
                fillColor: Theme.of(context).colorScheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to determine current SPL range based on min/max values
  String _getCurrentSplRange(double minSPL, double maxSPL) {
    if (minSPL == 60.0 && maxSPL == 70.0) {
      return "Background Music";
    } else if (minSPL == 70.0 && maxSPL == 80.0) {
      return "Paging";
    } else if (minSPL == 75.0 && maxSPL == 90.0) {
      return "Foreground Music";
    } else if (minSPL == 90.0 && maxSPL == 100.0) {
      return "Moderate live sound reinforcement";
    } else if (minSPL == 100.0 && maxSPL == 120.0) {
      return "High-SPL live sound reinforcement";
    } else {
      return "Background Music"; // Default fallback
    }
  }
}

class PropertyRow {
  final String title;
  final double x;
  final double y;
  final double z;

  PropertyRow({
    required this.title,
    required this.x,
    required this.y,
    required this.z,
  });
}

class PropertyListWidget extends StatefulWidget {
  final List<PropertyRow> rows;

  const PropertyListWidget({super.key, required this.rows});

  @override
  State<PropertyListWidget> createState() => _PropertyListWidgetState();
}

class _PropertyListWidgetState extends State<PropertyListWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final List<PropertyRow> visibleRows = _showAll ? widget.rows : widget.rows.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Table-style layout ensures alignment
        Column(
          children: visibleRows.map((PropertyRow row) => _PropertyRowWidget(row: row)).toList(),
        ),

        // Show more / less button if more than 4 rows
        if (widget.rows.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _showAll = !_showAll);
              },
              child: Text(
                _showAll ? "Show Less" : "Show More",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PropertyRowWidget extends StatelessWidget {
  final PropertyRow row;

  const _PropertyRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyleGrey = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 10,
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    );
    final TextStyle? textStyleBlack = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 9,
      color: Colors.black87,
      fontWeight: FontWeight.w400,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Row(
        children: <Widget>[
          // Title
          Expanded(
            flex: 1,
            child: Text(row.title, style: textStyleGrey),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                Text("X", style: textStyleGrey),
                const SizedBox(width: 4),
                Text(
                  "${row.x}",
                  style: textStyleBlack,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                Text("Y", style: textStyleGrey),
                const SizedBox(width: 4),
                Text(
                  "${row.y}",
                  style: textStyleBlack,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                Text("Z", style: textStyleGrey),
                const SizedBox(width: 4),
                Text(
                  "${row.z}",
                  style: textStyleBlack,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
