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
      vertices: <FusionCanvasPoint>[],
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
                BuildingPageDropDown<FloorModel>(
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
                  child: PropertyTextField(
                    controller: listeningAreaNameController,
                    hintText: 'Enter location name',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  ),
                ),
                const SizedBox(height: 12),

                /// Add Button
                Align(
                  alignment: Alignment.centerRight,

                  child: FusionButton(
                    accessLabel: 'create_new_listening_area_add_button',
                    height: 28,
                    width: 60,
                    label: "Add",
                    accessIdentifier: "create_new_listening_area_add_button",
                    activeBackgroundColor: context.colorScheme.primaryColor,
                    textStyle: context.textTheme.labelMedium?.copyWith(color: Colors.white),
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
