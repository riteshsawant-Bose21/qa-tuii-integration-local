import 'package:flutter/material.dart';
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
    "Default Type",
    "Indoor",
    "Outdoor",
    "Mixed",
    "Stadium",
  ];

  final List<String> listeningHeightOptions = <String>[
    "Ground 1 ft",
    "Sitting 3 ft",
    "Standing 6 ft",
  ];

  final List<String> splRangeOptions = <String>[
    "Low (70-90 dB)",
    "Medium (90-110 dB)",
    "High (110-130 dB)",
  ];

  final TextEditingController ceilingHeightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    ceilingHeightController.text = selectedListeningArea.ceilingHeight;

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
      padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                flex: 7,
                child: TextFormField(
                  initialValue: selectedListeningArea.name,
                  decoration: const InputDecoration(
                    hintText: 'Area Name',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onFieldSubmitted: (String v) {
                    final ListeningArea updatedLA = selectedListeningArea.copyWith(name: v);
                    viewModel.updateListeningArea(updatedLA);
                  },
                ),
              ),

              //small delete icon button to delete the selectedListeningArea
              Expanded(
                flex: 3,
                child: IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 15,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () {
                    viewModel.removeListeningArea(selectedListeningArea.id);
                  },
                ),
              ),
            ],
          ),
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
          const SizedBox(
            height: 8,
          ),
          _buildLAPropertyRow(
            context: context,
            label: "Type",
            value: selectedListeningArea.venuType.isNotEmpty ? selectedListeningArea.venuType : "Default Type",
            options: venueOptions,
            onOptionSelected: (int selectedIndex) {
              final String selectedType = venueOptions[selectedIndex];
              final ListeningArea updatedLA = selectedListeningArea.copyWith(venuType: selectedType);
              viewModel.updateListeningArea(updatedLA);
            },
          ),
          const SizedBox(
            height: 8,
          ),
          _buildLAPropertyRow(
            context: context,
            label: "Listening Ht",
            value: selectedListeningArea.listeningHeight,
            options: listeningHeightOptions,
            onOptionSelected: (int selectedIndex) {
              final String selectedHeight = listeningHeightOptions[selectedIndex];
              final ListeningArea updatedLA = selectedListeningArea.copyWith(listeningHeight: selectedHeight);
              viewModel.updateListeningArea(updatedLA);
            },
          ),
          const SizedBox(
            height: 8,
          ),
          _buildLAPropertyRow(
            context: context,
            label: "SPL Range",
            value: selectedListeningArea.splRange,
            options: splRangeOptions,
            onOptionSelected: (int selectedIndex) {
              final String selectedRange = splRangeOptions[selectedIndex];
              final ListeningArea updatedLA = selectedListeningArea.copyWith(splRange: selectedRange);
              viewModel.updateListeningArea(updatedLA);
            },
          ),
          const SizedBox(
            height: 8,
          ),
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
          const SizedBox(
            height: 8,
          ),

          PropertyListWidget(
            rows: rows,
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left: Label
            FusionAppText(
              text: label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.fusionTextViewColor.withOpacity(0.5),
              ),
            ),
            // Right: Value + Arrow
            Container(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: <Widget>[
                  FusionAppText(
                    text: value,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // Left: Label
        FusionAppText(
          text: label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Theme.of(context).colorScheme.fusionTextViewColor.withOpacity(0.5),
          ),
        ),

        // Right: TextField
        SizedBox(
          width: 100,
          height: 24,
          child: TextField(
            controller: controller,
            onSubmitted: onSubmit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.fusionTextViewColor,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              hintText: hintText,
              hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.fusionTextViewColor.withOpacity(0.5),
              ),
              // border: OutlineInputBorder(
              //   borderRadius: BorderRadius.circular(4),
              //   borderSide: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
              // ),
              // focusedBorder: OutlineInputBorder(
              //   borderRadius: BorderRadius.circular(4),
              //   borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              // ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.white,
            ),
          ),
        ),
      ],
    );
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
          GestureDetector(
            onTap: () {
              setState(() => _showAll = !_showAll);
            },
            child: Text(_showAll ? "Show Less" : "Show More"),
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
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
                const SizedBox(
                  width: 2,
                ),
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
                const SizedBox(
                  width: 2,
                ),
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
                const SizedBox(
                  width: 2,
                ),
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
