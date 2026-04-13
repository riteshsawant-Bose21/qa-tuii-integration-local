import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_cubit.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_state.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_custom_textfield.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dialog for adding or editing a controller.
///
/// Pass [initialController] to open in edit mode (pre-populated fields,
/// "EDIT CONTROLLER" header, and "Update" button).
class AddControllerDialog extends StatelessWidget {
  /// Called with the controller's ID when it is successfully created or updated.
  final void Function(String controllerId)? onControllerAdded;

  /// When non-null the dialog opens in **edit** mode pre-populated with the
  /// existing controller's values.
  final FusionController? initialController;

  const AddControllerDialog({
    super.key,
    this.onControllerAdded,
    this.initialController,
  });

  /// Show the dialog in **add** mode.
  static Future<bool?> show(BuildContext context, {void Function(String controllerId)? onControllerAdded}) async {
    return await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return AddControllerDialog(onControllerAdded: onControllerAdded);
      },
    );
  }

  /// Show the dialog in **edit** mode pre-populated with [controller]'s data.
  static Future<bool?> showForEdit(
    BuildContext context, {
    required FusionController controller,
    void Function(String controllerId)? onControllerUpdated,
  }) async {
    return await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return AddControllerDialog(
          initialController: controller,
          onControllerAdded: onControllerUpdated,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddControllerCubit>(
      create: (BuildContext context) {
        final AddControllerCubit cubit = AddControllerCubit(
          projectViewModel: serviceLocator<ProjectViewModel>(),
        );
        if (initialController != null) {
          cubit.initForEdit(initialController!);
        }
        return cubit;
      },
      child: _AddControllerDialogContent(
        onControllerAdded: onControllerAdded,
        initialController: initialController,
      ),
    );
  }
}

class _AddControllerDialogContent extends StatefulWidget {
  final void Function(String controllerId)? onControllerAdded;
  final FusionController? initialController;

  const _AddControllerDialogContent({this.onControllerAdded, this.initialController});

  @override
  State<_AddControllerDialogContent> createState() => _AddControllerDialogContentState();
}

class _AddControllerDialogContentState extends State<_AddControllerDialogContent> {
  late TextEditingController _nameController;

  bool get _isEditMode => widget.initialController != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialController?.name ?? 'Untitled Controller',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onClose(BuildContext context) async {
    if (context.mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          /// Dismiss on tap outside
          GestureDetector(
            onTap: () => _onClose(context),
            child: Container(color: Colors.transparent),
          ),

          /// Dialog content
          Center(
            child: Container(
              width: 426,
              margin: const EdgeInsets.all(24.0),
              constraints: const BoxConstraints(maxHeight: 500),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                border: Border.all(color: context.colorScheme.strokeLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: BlocBuilder<AddControllerCubit, AddControllerState>(
                builder: (BuildContext context, AddControllerState state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      /// Header
                      _buildHeader(context),

                      /// Main content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              /// Name field
                              _buildNameField(context, state),
                              const SizedBox(height: 16),

                              /// Type dropdown
                              _buildTypeDropdown(context, state),
                              const SizedBox(height: 16),

                              /// Location dropdown
                              _buildLocationDropdown(context, state),

                              /// Zone/Equipment Location selection
                              if (state.locationType != null) ...<Widget>[
                                const SizedBox(height: 12),
                                _buildLocationSelectionDropdown(context, state),
                              ],

                              /// Assign Control checkbox
                              const SizedBox(height: 24),
                              _buildAssignControlCheckbox(context, state),

                              /// Control Assignment dropdown (conditional)
                              if (state.assignControl) ...<Widget>[
                                const SizedBox(height: 16),
                                _buildControlAssignmentDropdown(context, state),
                              ],

                              /// Error message
                              if (state.errorMessage != null) ...<Widget>[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.errorFill,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: FusionAppText(
                                    text: state.errorMessage!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.colorScheme.errorText,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      /// Footer with Add button
                      _buildFooter(context, state),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog header with title and close button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FusionAppText(
            text: _isEditMode ? 'EDIT CONTROLLER' : 'ADD CONTROLLER',
            style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary),
          ),

          /// Close button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onClose(context),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: FusionIcon.icon(
                  LucideIcons.x,
                  color: context.colorScheme.iconDefault,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(BuildContext context, AddControllerState state) {
    return _FormFieldRow(
      label: 'Name',
      child: FusionCustomTextField(
        semanticId: 'add_controller_name',
        hint: 'Enter controller name',
        controller: _nameController,
        width: double.infinity,
        height: 30,
        borderRadius: 8,
        variant: FusionFieldVariant.neumorphic,
        onChange: (String value) {
          context.read<AddControllerCubit>().updateName(value);
        },
      ),
    );
  }

  Widget _buildTypeDropdown(BuildContext context, AddControllerState state) {
    String? displayText;
    if (state.controllerType != null) {
      switch (state.controllerType!) {
        case ControllerType.controlPalLT:
          displayText = 'Control Pal LT';
          break;
        case ControllerType.controlPalPro:
          displayText = 'Control Pal Pro';
          break;
        case ControllerType.virtualControlPalLT:
          displayText = 'Virtual Dimming LT';
          break;
        case ControllerType.virtualControlPalPro:
          displayText = 'Virtual Dimming Pro';
          break;
      }
    }

    return _FormFieldRow(
      label: 'Type',
      child: FusionNeumorphicDropdown<ControllerType>(
        value: state.controllerType,
        displayValue: displayText,
        hintText: 'Select Controller',
        height: 30,
        borderRadius: BorderRadius.circular(8),
        items: ControllerType.values,
        // itemLabelBuilder: (ControllerType type) => type.displayN?ame,
        itemBuilder: (BuildContext ctx, ControllerType type) {
          String text;
          switch (type) {
            case ControllerType.controlPalLT:
              text = 'Control Pal LT';
              break;
            case ControllerType.controlPalPro:
              text = 'Control Pal Pro';
              break;
            case ControllerType.virtualControlPalLT:
              text = 'Virtual Dimming LT';
              break;
            case ControllerType.virtualControlPalPro:
              text = 'Virtual Dimming Pro';
              break;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FusionAppText(text: text, style: Theme.of(context).textTheme.bodySmall),
          );
        },
        onChanged: (ControllerType value) {
          context.read<AddControllerCubit>().updateControllerType(value);
        },
      ),
    );
  }

  Widget _buildLocationDropdown(BuildContext context, AddControllerState state) {
    String? displayText;
    if (state.locationType != null) {
      switch (state.locationType!) {
        case LocationType.zone:
          displayText = 'Zone';
          break;
        case LocationType.equipmentLocation:
          displayText = 'Equipment';
          break;
      }
    }

    return _FormFieldRow(
      label: 'Location',
      child: FusionNeumorphicDropdown<LocationType>(
        value: state.locationType,
        displayValue: displayText,
        hintText: 'Select Location',
        height: 30,
        borderRadius: BorderRadius.circular(8),
        items: LocationType.values,
        itemBuilder: (BuildContext ctx, LocationType type) {
          String text;
          switch (type) {
            case LocationType.zone:
              text = 'Zone';
              break;
            case LocationType.equipmentLocation:
              text = 'Equipment';
              break;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FusionAppText(text: text, style: Theme.of(context).textTheme.bodySmall),
          );
        },
        onChanged: (LocationType value) {
          context.read<AddControllerCubit>().updateLocationType(value);
        },
      ),
    );
  }

  Widget _buildLocationSelectionDropdown(BuildContext context, AddControllerState state) {
    if (state.locationType == LocationType.zone) {
      return _buildZoneLocationDropdown(context);
    } else {
      return _buildEquipmentLocationDropdown(context);
    }
  }

  Widget _buildZoneLocationDropdown(BuildContext context) {
    return BlocSelector<AddControllerCubit, AddControllerState, ({String? zoneId, String? subZoneId})>(
      selector: (AddControllerState state) => (zoneId: state.selectedZoneId, subZoneId: state.selectedSubZoneId),
      builder: (BuildContext context, ({String? zoneId, String? subZoneId}) selection) {
        final AddControllerCubit cubit = context.read<AddControllerCubit>();
        final List<Zone> zones = cubit.availableZones;

        /// Build flat list of selectable items
        final List<_ZoneSelectItem> selectableItems = _buildZoneSelectItems(zones, cubit);

        /// Find currently selected item
        final _ZoneSelectItem? selectedItem = _findSelectedZoneItem(
          selectableItems,
          selection.zoneId,
          selection.subZoneId,
        );

        return Padding(
          padding: const EdgeInsets.only(left: 120),
          child: FusionNeumorphicDropdown<_ZoneSelectItem>(
            value: selectedItem,
            matchChildWidth: true,
            hintText: 'Select Zone',
            height: 30,
            borderRadius: BorderRadius.circular(8),
            items: selectableItems,
            displayValue: selectedItem?.name,
            isItemEnabled: (_ZoneSelectItem item) => item.isSelectable,
            itemPadding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildZoneDropdownChild(context, selectedItem),
            itemBuilder: (BuildContext ctx, _ZoneSelectItem item) {
              final bool isSelected = selectedItem?.id == item.id;
              return _buildZoneDropdownItem(ctx, item, isSelected, zones, cubit);
            },
            onChanged: (_ZoneSelectItem item) {
              if (item.isSubZone) {
                cubit.updateSelectedZone(item.parentZoneId, subZoneId: item.id);
              } else {
                cubit.updateSelectedZone(item.id);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEquipmentLocationDropdown(BuildContext context) {
    return BlocSelector<AddControllerCubit, AddControllerState, String?>(
      selector: (AddControllerState state) => state.selectedEquipmentLocationId,
      builder: (BuildContext context, String? selectedEquipLocationId) {
        final AddControllerCubit cubit = context.read<AddControllerCubit>();
        final List<EquipLocation> equipLocations = cubit.availableEquipmentLocations;

        final EquipLocation? selectedLocation =
            selectedEquipLocationId != null
                ? equipLocations.cast<EquipLocation?>().firstWhere(
                  (EquipLocation? e) => e?.id == selectedEquipLocationId,
                  orElse: () => null,
                )
                : null;

        return Padding(
          padding: const EdgeInsets.only(left: 120),
          child: FusionNeumorphicDropdown<EquipLocation>(
            value: selectedLocation,
            hintText: 'Select equipment location',
            height: 30,
            borderRadius: BorderRadius.circular(8),
            items: equipLocations,
            displayValue: selectedLocation?.name,
            itemLabelBuilder: (EquipLocation location) => location.name,
            onChanged: (EquipLocation location) {
              cubit.updateSelectedEquipmentLocation(location.id);
            },
          ),
        );
      },
    );
  }

  /// Build flat list of zone items (including non-selectable parent zones with subzones)
  List<_ZoneSelectItem> _buildZoneSelectItems(List<Zone> zones, AddControllerCubit cubit) {
    final List<_ZoneSelectItem> selectableItems = <_ZoneSelectItem>[];
    for (final Zone zone in zones) {
      final List<SubZone> subZones = cubit.getSubZonesForZone(zone.id);
      if (subZones.isEmpty) {
        /// Zone without subzones - can be selected directly
        selectableItems.add(
          _ZoneSelectItem(
            id: zone.id,
            name: zone.name,
            color: zone.color,
            isSubZone: false,
            isSelectable: true,
            parentZoneId: null,
          ),
        );
      } else {
        /// Zone with subzones - add as non-selectable header
        selectableItems.add(
          _ZoneSelectItem(
            id: zone.id,
            name: zone.name,
            color: zone.color,
            isSubZone: false,
            isSelectable: false,
            parentZoneId: null,
          ),
        );

        /// Add all subzones as selectable items
        for (final SubZone subZone in subZones) {
          selectableItems.add(
            _ZoneSelectItem(
              id: subZone.id,
              name: subZone.name,
              color: zone.color,
              isSubZone: true,
              isSelectable: true,
              parentZoneId: zone.id,
              parentZoneName: zone.name,
            ),
          );
        }
      }
    }
    return selectableItems;
  }

  /// Find currently selected zone item from the list
  _ZoneSelectItem? _findSelectedZoneItem(
    List<_ZoneSelectItem> items,
    String? zoneId,
    String? subZoneId,
  ) {
    if (subZoneId != null) {
      return items.cast<_ZoneSelectItem?>().firstWhere(
        (_ZoneSelectItem? item) => item?.id == subZoneId,
        orElse: () => null,
      );
    } else if (zoneId != null) {
      return items.cast<_ZoneSelectItem?>().firstWhere(
        (_ZoneSelectItem? item) => item?.id == zoneId && !item!.isSubZone,
        orElse: () => null,
      );
    }
    return null;
  }

  /// Build the child widget displayed in the dropdown button
  Widget? _buildZoneDropdownChild(BuildContext context, _ZoneSelectItem? selectedItem) {
    if (selectedItem == null) return null;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(color: context.colorScheme.elevation2, blurRadius: 1, offset: const Offset(-2, -3)),
          BoxShadow(color: context.colorScheme.black, blurRadius: 1, offset: const Offset(2, 3)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: selectedItem.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FusionAppText(
              text: selectedItem.name,
              style: Theme.of(context).textTheme.bodySmall,
              textOverflow: TextOverflow.ellipsis,
            ),
          ),
          FusionIcon.icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: context.colorScheme.onSurface.withAlpha(200),
          ),
        ],
      ),
    );
  }

  /// Build a zone dropdown item with proper styling
  Widget _buildZoneDropdownItem(
    BuildContext context,
    _ZoneSelectItem item,
    bool isSelected,
    List<Zone> allZones,
    AddControllerCubit cubit,
  ) {
    /// If this is a non-selectable parent zone (has subzones), show as header only
    if (!item.isSelectable && !item.isSubZone) {
      return Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FusionAppText(
              text: item.name,
              style: Theme.of(context).textTheme.l1Regular,
            ),
          ),
        ],
      );
    }

    /// Selectable item (zone without subzones OR subzone)
    return Padding(
      padding: EdgeInsets.only(
        left: item.isSubZone ? 20 : 0,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        children: <Widget>[
          if (item.isSubZone)
            /// Bullet point for subzone
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation5,
                shape: BoxShape.circle,
              ),
            )
          else
            /// Color indicator for zone
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

          /// Name
          Expanded(
            child: FusionAppText(text: item.name, style: Theme.of(context).textTheme.l1Regular),
          ),

          /// Radio button (only for selectable items)
          _buildRadioButton(context, isSelected),
        ],
      ),
    );
  }

  /// Build a styled radio button
  Widget _buildRadioButton(BuildContext context, bool isSelected) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? context.colorScheme.iconWhite : context.colorScheme.strokeDark,
          width: 1,
        ),
      ),
      child:
          isSelected
              ? Center(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.iconWhite,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildAssignControlCheckbox(BuildContext context, AddControllerState state) {
    return Padding(
      padding: const EdgeInsets.only(left: 120),
      child: GestureDetector(
        onTap: () {
          context.read<AddControllerCubit>().toggleAssignControl(!state.assignControl);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FusionCheckbox(
              semanticId: '',
              value: state.assignControl,
              onChanged: () {
                context.read<AddControllerCubit>().toggleAssignControl(!state.assignControl);
              },
            ),
            const SizedBox(width: 8),
            FusionAppText(
              text: 'Assign control',
              style: Theme.of(context).textTheme.l1Regular,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlAssignmentDropdown(BuildContext context, AddControllerState state) {
    return BlocSelector<AddControllerCubit, AddControllerState, Set<String>>(
      selector: (AddControllerState state) => state.selectedControlZoneIds,
      builder: (BuildContext context, Set<String> selectedControlZoneIds) {
        final AddControllerCubit cubit = context.read<AddControllerCubit>();
        final List<Zone> zones = cubit.availableZones;
        final bool isProController = cubit.supportsMultipleZones;
        final bool isZoneLocation = state.locationType == LocationType.zone;
        final String? thisZoneId = cubit.thisZoneId;

        /// Build flat list of selectable items for control zones
        final List<_ZoneSelectItem> selectableItems = _buildControlZoneSelectItems(
          zones,
          cubit,
          thisZoneId: thisZoneId,
          isZoneLocation: isZoneLocation,
        );

        /// Find currently selected item (for single select - LT controllers)
        _ZoneSelectItem? selectedItem;
        if (selectedControlZoneIds.length == 1) {
          final String selectedId = selectedControlZoneIds.first;
          selectedItem = selectableItems.cast<_ZoneSelectItem?>().firstWhere(
            (_ZoneSelectItem? item) => item?.id == selectedId && item!.isSelectable,
            orElse: () => null,
          );
        }

        /// Get display text
        String? displayText;
        if (selectedControlZoneIds.isEmpty) {
          displayText = null;
        } else if (selectedControlZoneIds.length == 1) {
          // Show "This Zone" prefix if the selected zone is the current location zone
          if (selectedItem != null && isZoneLocation && selectedItem.id == thisZoneId) {
            displayText = 'This Zone (${selectedItem.name})';
          } else {
            displayText = selectedItem?.name ?? 'Select zone';
          }
        } else {
          displayText = '${selectedControlZoneIds.length} zones selected';
        }

        return _FormFieldRow(
          label: 'Control',
          child: FusionNeumorphicDropdown<_ZoneSelectItem>(
            value: selectedItem,
            matchChildWidth: true,
            hintText: 'Select zone',
            height: 30,
            borderRadius: BorderRadius.circular(8),
            items: selectableItems,
            displayValue: displayText,
            isItemEnabled: (_ZoneSelectItem item) => item.isSelectable,
            itemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: _buildControlZoneDropdownChild(context, selectedItem, selectedControlZoneIds, isProController, thisZoneId),
            itemBuilder: (BuildContext ctx, _ZoneSelectItem item) {
              final bool isSelected = selectedControlZoneIds.contains(item.id);
              final bool isThisZone = item.id == thisZoneId && isZoneLocation;
              return _buildControlZoneDropdownItem(ctx, item, isSelected, isProController, isThisZone);
            },
            onChanged: (_ZoneSelectItem item) {
              cubit.toggleControlZone(item.id);
            },
          ),
        );
      },
    );
  }

  /// Build dropdown child for control zone selection
  Widget? _buildControlZoneDropdownChild(
    BuildContext context,
    _ZoneSelectItem? selectedItem,
    Set<String> selectedControlZoneIds,
    bool isProController,
    String? thisZoneId,
  ) {
    if (selectedControlZoneIds.isEmpty) return null;
    if (selectedControlZoneIds.length > 1) {
      return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(8),
          boxShadow: <BoxShadow>[
            BoxShadow(color: context.colorScheme.elevation2, blurRadius: 1, offset: const Offset(-2, -3)),
            BoxShadow(color: context.colorScheme.black, blurRadius: 1, offset: const Offset(2, 3)),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: '${selectedControlZoneIds.length} zones selected',
                style: Theme.of(context).textTheme.bodySmall,
                textOverflow: TextOverflow.ellipsis,
              ),
            ),
            FusionIcon.icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: context.colorScheme.onSurface.withAlpha(200),
            ),
          ],
        ),
      );
    }

    if (selectedItem == null) return null;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(color: context.colorScheme.elevation2, blurRadius: 1, offset: const Offset(-2, -3)),
          BoxShadow(color: context.colorScheme.black, blurRadius: 1, offset: const Offset(2, 3)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: selectedItem.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FusionAppText(
              text: selectedItem.id == thisZoneId ? 'This Zone (${selectedItem.name})' : selectedItem.name,
              style: Theme.of(context).textTheme.bodySmall,
              textOverflow: TextOverflow.ellipsis,
            ),
          ),
          FusionIcon.icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: context.colorScheme.onSurface.withAlpha(200),
          ),
        ],
      ),
    );
  }

  /// Build a control zone dropdown item with proper styling (checkbox for Pro, radio for LT)
  Widget _buildControlZoneDropdownItem(
    BuildContext context,
    _ZoneSelectItem item,
    bool isSelected,
    bool isProController,
    bool isThisZone,
  ) {
    /// If this is a non-selectable parent zone (has subzones), show as header only
    if (!item.isSelectable && !item.isSubZone) {
      return Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FusionAppText(
              text: item.name,
              style: Theme.of(context).textTheme.l1Regular,
            ),
          ),
        ],
      );
    }

    /// Selectable item (zone without subzones OR subzone)
    return Padding(
      padding: EdgeInsets.only(
        left: item.isSubZone ? 20 : 0,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        children: <Widget>[
          if (item.isSubZone)
            /// Bullet point for subzone
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation5,
                shape: BoxShape.circle,
              ),
            )
          else
            /// Color indicator for zone
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

          /// Name with "This Zone" suffix if applicable
          Expanded(
            child: FusionAppText(
              text: isThisZone ? '${item.name} (This Zone)' : item.name,
              style: Theme.of(context).textTheme.l1Regular,
            ),
          ),

          /// Checkbox for Pro controllers, Radio for LT controllers
          if (isProController) _buildCheckbox(context, isSelected) else _buildRadioButton(context, isSelected),
        ],
      ),
    );
  }

  /// Build a styled checkbox
  Widget _buildCheckbox(BuildContext context, bool isSelected) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isSelected ? context.colorScheme.iconWhite : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? context.colorScheme.iconWhite : context.colorScheme.strokeDark,
          width: 1,
        ),
      ),
      child:
          isSelected
              ? Icon(
                Icons.check,
                size: 12,
                color: context.colorScheme.primaryBlack,
              )
              : null,
    );
  }

  /// Build flat list of zone items for control assignment
  List<_ZoneSelectItem> _buildControlZoneSelectItems(
    List<Zone> zones,
    AddControllerCubit cubit, {
    String? thisZoneId,
    bool isZoneLocation = false,
  }) {
    final List<_ZoneSelectItem> selectableItems = <_ZoneSelectItem>[];
    for (final Zone zone in zones) {
      final List<SubZone> subZones = cubit.getSubZonesForZone(zone.id);
      if (subZones.isEmpty) {
        /// Zone without subzones - can be selected directly
        selectableItems.add(
          _ZoneSelectItem(
            id: zone.id,
            name: zone.name,
            color: zone.color,
            isSubZone: false,
            isSelectable: true,
            parentZoneId: null,
          ),
        );
      } else {
        /// Zone with subzones - add as non-selectable header
        selectableItems.add(
          _ZoneSelectItem(
            id: zone.id,
            name: zone.name,
            color: zone.color,
            isSubZone: false,
            isSelectable: false,
            parentZoneId: null,
          ),
        );

        /// Add all subzones as selectable items
        for (final SubZone subZone in subZones) {
          selectableItems.add(
            _ZoneSelectItem(
              id: subZone.id,
              name: subZone.name,
              color: zone.color,
              isSubZone: true,
              isSelectable: true,
              parentZoneId: zone.id,
              parentZoneName: zone.name,
            ),
          );
        }
      }
    }
    return selectableItems;
  }

  Widget _buildFooter(BuildContext context, AddControllerState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          NeumorphicButton(
            semanticId: _isEditMode ? 'edit_controller_update_btn' : 'add_controller_add_message_btn',
            onTap: () => _isEditMode ? _onUpdateButtonPressed(context) : _onAddButtonPressed(context),
            height: 32,
            borderRadius: 8,
            width: 90,
            isActive: !state.isLoading,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FusionIcon.icon(
                  _isEditMode ? Icons.check : Icons.add,
                  size: 18,
                  color: context.colorScheme.iconWhite,
                ),
                const SizedBox(width: 8),
                FusionAppText(
                  text: state.isLoading ? (_isEditMode ? 'Updating...' : 'Adding...') : (_isEditMode ? 'Update' : 'Add'),
                  style: context.textTheme.l1Medium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddButtonPressed(BuildContext context) async {
    final String? newControllerId = await context.read<AddControllerCubit>().addController();
    if (newControllerId != null && context.mounted) {
      widget.onControllerAdded?.call(newControllerId);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _onUpdateButtonPressed(BuildContext context) async {
    final String? controllerId = await context.read<AddControllerCubit>().updateController();
    if (controllerId != null && context.mounted) {
      widget.onControllerAdded?.call(controllerId);
      Navigator.of(context).pop(true);
    }
  }
}

/// Form field row with label on the left
class _FormFieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormFieldRow({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 120,
          child: FusionAppText(text: label, style: Theme.of(context).textTheme.l1Regular),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Helper class for zone selection dropdown items
class _ZoneSelectItem {
  final String id;
  final String name;
  final Color color;
  final bool isSubZone;
  final bool isSelectable;
  final String? parentZoneId;
  final String? parentZoneName;

  const _ZoneSelectItem({
    required this.id,
    required this.name,
    required this.color,
    required this.isSubZone,
    required this.isSelectable,
    required this.parentZoneId,
    this.parentZoneName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ZoneSelectItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
