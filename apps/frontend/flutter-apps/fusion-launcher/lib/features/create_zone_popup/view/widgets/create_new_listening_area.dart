part of '../create_zone_popup.dart';

class _CreateNewListeningAreaWidget extends StatefulWidget {
  final ValueChanged<ListeningArea> onListeningAreaCreated;

  const _CreateNewListeningAreaWidget({required this.onListeningAreaCreated});

  @override
  State<_CreateNewListeningAreaWidget> createState() => __CreateNewListeningAreaWidgetState();
}

class __CreateNewListeningAreaWidgetState extends State<_CreateNewListeningAreaWidget> {
  final TextEditingController listeningAreaNameController = TextEditingController();
  bool _isExpanded = false;
  FloorModel? _selectedFloor;

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  void _addNewLocationToFloor() {
    if (listeningAreaNameController.text.trim().isEmpty || _selectedFloor == null) {
      FusionToast.error(context, message: "Please enter location name and select a floor");
      return;
    }

    final String floorId = _selectedFloor!.id;
    final String locationName = listeningAreaNameController.text.trim();

    final ListeningArea newListeningArea = ListeningArea(
      name: locationName,
      vertices: <Offset>[],
      isDrawn: false,
    );

    serviceLocator<ProjectViewModel>().addListeningArea(area: newListeningArea, floorId: floorId);
    FusionToast.success(context, message: "Listening area '${newListeningArea.name}' created");
    widget.onListeningAreaCreated(newListeningArea);

    // clear inputs
    listeningAreaNameController.clear();
    _selectedFloor = null;
    setState(() => _isExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Header
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: "Create new location",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SemanticHelper.toggle(
                  testId: SemanticHelper.createTestId(SemanticTypes.toggle, "create_new_listening_area_toggle"),
                  value: _isExpanded,
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),

        /// Expanded form
        if (_isExpanded) ...<Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0).copyWith(top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// Floor label
                FusionAppText(
                  text: "Floor",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                /// Floor dropdown
                BuildingPageDronDown<FloorModel>(
                  value: _selectedFloor,
                  items: serviceLocator<ProjectViewModel>().getAllFloors(),
                  onSelect: (FloorModel selectedValue) {
                    setState(() {
                      _selectedFloor = selectedValue;
                    });
                  },
                  labelBuilder: (FloorModel option) {
                    return FusionAppText(
                      text: option.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
                const SizedBox(height: 12),

                /// Location Name
                FusionAppText(
                  text: "Location Name",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                SemanticHelper.formControl(
                  testId: SemanticHelper.createTestId(SemanticTypes.textInput, "create_new_listening_area_input"),
                  child: TextFormField(
                    controller: listeningAreaNameController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Enter location name',
                      hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      hoverColor: Colors.transparent,
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      fillColor: context.colorScheme.surface,
                    ),
                    style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 12),

                /// Add Button
                Align(
                  alignment: Alignment.centerRight,

                  child: FusionButton(
                    height: 28,
                    width: 60,
                    label: "Add",
                    accessIdentifier: "create_new_listening_area_add_button",
                    textStyle: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.surface,
                    ),
                    onTap: _addNewLocationToFloor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
