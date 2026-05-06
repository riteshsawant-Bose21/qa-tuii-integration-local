// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fusion_launcher/core/service_locator.dart';
// import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
// import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_cubit.dart';
// import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_state.dart';
// import 'package:fusion_lib/fusion_lib.dart';
// import 'package:fusion_lib/fusion_widgets/form_fields/fusion_custom_textfield.dart';
// import 'package:fusion_lib/models/project_entities/controller.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';
//
// /// Dialog for adding or editing a controller.
// ///
// /// Pass [initialController] to open in edit mode (pre-populated fields,
// /// "EDIT CONTROLLER" header, and "Update" button).
// class AddControllerDialog extends StatelessWidget {
//   /// Called with the controller's ID when it is successfully created or updated.
//   final void Function(String controllerId)? onControllerAdded;
//
//   /// When non-null the dialog opens in **edit** mode pre-populated with the
//   /// existing controller's values.
//   final FusionController? initialController;
//
//   const AddControllerDialog({
//     super.key,
//     this.onControllerAdded,
//     this.initialController,
//   });
//
//   /// Show the dialog in **add** mode.
//   static Future<bool?> show(BuildContext context, {void Function(String controllerId)? onControllerAdded}) async {
//     return await showGeneralDialog<bool>(
//       context: context,
//       barrierDismissible: true,
//       barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
//       barrierColor: Colors.black87,
//       transitionDuration: const Duration(milliseconds: 200),
//       pageBuilder: (BuildContext buildContext, _, __) {
//         return AddControllerDialog(onControllerAdded: onControllerAdded);
//       },
//     );
//   }
//
//   /// Show the dialog in **edit** mode pre-populated with [controller]'s data.
//   static Future<bool?> showForEdit(
//     BuildContext context, {
//     required FusionController controller,
//     void Function(String controllerId)? onControllerUpdated,
//   }) async {
//     return await showGeneralDialog<bool>(
//       context: context,
//       barrierDismissible: true,
//       barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
//       barrierColor: Colors.black87,
//       transitionDuration: const Duration(milliseconds: 200),
//       pageBuilder: (BuildContext buildContext, _, __) {
//         return AddControllerDialog(
//           initialController: controller,
//           onControllerAdded: onControllerUpdated,
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider<AddControllerCubit>(
//       create: (BuildContext context) {
//         final AddControllerCubit cubit = AddControllerCubit(
//           projectViewModel: serviceLocator<ProjectViewModel>(),
//         );
//         if (initialController != null) {
//           cubit.initForEdit(initialController!);
//         }
//         return cubit;
//       },
//       child: _AddControllerDialogContent(
//         onControllerAdded: onControllerAdded,
//         initialController: initialController,
//       ),
//     );
//   }
// }
//
// class _AddControllerDialogContent extends StatefulWidget {
//   final void Function(String controllerId)? onControllerAdded;
//   final FusionController? initialController;
//
//   const _AddControllerDialogContent({this.onControllerAdded, this.initialController});
//
//   @override
//   State<_AddControllerDialogContent> createState() => _AddControllerDialogContentState();
// }
//
// class _AddControllerDialogContentState extends State<_AddControllerDialogContent> {
//   late TextEditingController _nameController;
//
//   bool get _isEditMode => widget.initialController != null;
//
//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(
//       text: widget.initialController?.name ?? 'Untitled Controller',
//     );
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onClose(BuildContext context) async {
//     if (context.mounted) {
//       Navigator.of(context).pop(false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       type: MaterialType.transparency,
//       child: Stack(
//         children: <Widget>[
//           /// Dismiss on tap outside
//           GestureDetector(
//             onTap: () => _onClose(context),
//             child: Container(color: Colors.transparent),
//           ),
//
//           /// Dialog content
//           Center(
//             child: Container(
//               width: 426,
//               margin: const EdgeInsets.all(24.0),
//               constraints: const BoxConstraints(maxHeight: 500),
//               clipBehavior: Clip.hardEdge,
//               decoration: BoxDecoration(
//                 color: context.colorScheme.elevation1,
//                 border: Border.all(color: context.colorScheme.strokeLight),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: BlocBuilder<AddControllerCubit, AddControllerState>(
//                 builder: (BuildContext context, AddControllerState state) {
//                   return Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: <Widget>[
//                       /// Header
//                       _buildHeader(context),
//
//                       /// Main content
//                       Flexible(
//                         child: SingleChildScrollView(
//                           padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: <Widget>[
//                               /// Name field
//                               _buildNameField(context, state),
//                               const SizedBox(height: 16),
//
//                               /// Type dropdown
//                               _buildTypeDropdown(context, state),
//                               const SizedBox(height: 16),
//
//                               /// Location dropdown
//                               _buildLocationDropdown(context, state),
//
//                               /// Zone/Equipment Location selection
//                               if (state.locationType != null) ...<Widget>[
//                                 const SizedBox(height: 12),
//                                 _buildLocationSelectionDropdown(context, state),
//                               ],
//
//                               /// Assign Control checkbox
//                               const SizedBox(height: 24),
//                               _buildAssignControlCheckbox(context, state),
//
//                               /// Control Assignment dropdown (conditional)
//                               if (state.assignControl) ...<Widget>[
//                                 const SizedBox(height: 16),
//                                 _buildControlAssignmentDropdown(context, state),
//                               ],
//
//                               /// Error message
//                               if (state.errorMessage != null) ...<Widget>[
//                                 const SizedBox(height: 16),
//                                 Container(
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: context.colorScheme.errorFill,
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: FusionAppText(
//                                     text: state.errorMessage!,
//                                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                                       color: context.colorScheme.errorText,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),
//                       ),
//
//                       /// Footer with Add button
//                       _buildFooter(context, state),
//                     ],
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Dialog header with title and close button
//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(
//             color: context.colorScheme.strokeLight,
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: <Widget>[
//           FusionAppText(
//             text: _isEditMode ? 'EDIT CONTROLLER' : 'ADD CONTROLLER',
//             style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary),
//           ),
//
//           /// Close button
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () => _onClose(context),
//               customBorder: const CircleBorder(),
//               child: Padding(
//                 padding: const EdgeInsets.all(4.0),
//                 child: FusionIcon.icon(
//                   LucideIcons.x,
//                   color: context.colorScheme.iconDefault,
//                   size: 18,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNameField(BuildContext context, AddControllerState state) {
//     return _FormFieldRow(
//       label: 'Name',
//       child: FusionCustomTextField(
//         semanticId: 'add_controller_name',
//         hint: 'Enter controller name',
//         controller: _nameController,
//         width: double.infinity,
//         height: 32,
//         borderRadius: 8,
//         variant: FusionFieldVariant.neumorphic,
//         onChange: (String value) {
//           context.read<AddControllerCubit>().updateName(value);
//         },
//       ),
//     );
//   }
//
//   Widget _buildTypeDropdown(BuildContext context, AddControllerState state) {
//     String? displayText;
//     if (state.controllerType != null) {
//       switch (state.controllerType!) {
//         case ControllerType.controlPalLT:
//           displayText = 'Control Pal LT';
//           break;
//         case ControllerType.controlPalPro:
//           displayText = 'Control Pal Pro';
//           break;
//         case ControllerType.virtualControlPalLT:
//           displayText = 'Virtual Dimming LT';
//           break;
//         case ControllerType.virtualControlPalPro:
//           displayText = 'Virtual Dimming Pro';
//           break;
//       }
//     }
//
//     return _FormFieldRow(
//       label: 'Type',
//       child: FusionNeumorphicDropdown<ControllerType>(
//         value: state.controllerType,
//         displayValue: displayText,
//         hintText: 'Select Controller',
//         height: 32,
//         borderRadius: BorderRadius.circular(8),
//         items: ControllerType.values,
//         // itemLabelBuilder: (ControllerType type) => type.displayN?ame,
//         itemBuilder: (BuildContext ctx, ControllerType type) {
//           String text;
//           switch (type) {
//             case ControllerType.controlPalLT:
//               text = 'Control Pal LT';
//               break;
//             case ControllerType.controlPalPro:
//               text = 'Control Pal Pro';
//               break;
//             case ControllerType.virtualControlPalLT:
//               text = 'Virtual Dimming LT';
//               break;
//             case ControllerType.virtualControlPalPro:
//               text = 'Virtual Dimming Pro';
//               break;
//           }
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: FusionAppText(text: text, style: Theme.of(context).textTheme.bodySmall),
//           );
//         },
//         onChanged: (ControllerType value) {
//           context.read<AddControllerCubit>().updateControllerType(value);
//         },
//       ),
//     );
//   }
//
//   Widget _buildLocationDropdown(BuildContext context, AddControllerState state) {
//     String? displayText;
//     if (state.locationType != null) {
//       switch (state.locationType!) {
//         case LocationType.zone:
//           displayText = 'Zone';
//           break;
//         case LocationType.equipmentLocation:
//           displayText = 'Equipment';
//           break;
//       }
//     }
//
//     return _FormFieldRow(
//       label: 'Location',
//       child: FusionNeumorphicDropdown<LocationType>(
//         value: state.locationType,
//         displayValue: displayText,
//         hintText: 'Select Location',
//         height: 32,
//         borderRadius: BorderRadius.circular(8),
//         items: LocationType.values,
//         itemBuilder: (BuildContext ctx, LocationType type) {
//           String text;
//           switch (type) {
//             case LocationType.zone:
//               text = 'Zone';
//               break;
//             case LocationType.equipmentLocation:
//               text = 'Equipment';
//               break;
//           }
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: FusionAppText(text: text, style: Theme.of(context).textTheme.bodySmall),
//           );
//         },
//         onChanged: (LocationType value) {
//           context.read<AddControllerCubit>().updateLocationType(value);
//         },
//       ),
//     );
//   }
//
//   Widget _buildLocationSelectionDropdown(BuildContext context, AddControllerState state) {
//     if (state.locationType == LocationType.zone) {
//       return _buildZoneLocationDropdown(context);
//     } else {
//       return _buildEquipmentLocationDropdown(context);
//     }
//   }
//
//   Widget _buildZoneLocationDropdown(BuildContext context) {
//     return BlocSelector<AddControllerCubit, AddControllerState, ({String? zoneId, String? subZoneId})>(
//       selector: (AddControllerState state) => (zoneId: state.selectedZoneId, subZoneId: state.selectedSubZoneId),
//       builder: (BuildContext context, ({String? zoneId, String? subZoneId}) selection) {
//         final AddControllerCubit cubit = context.read<AddControllerCubit>();
//         final List<Zone> zones = cubit.availableZones;
//
//         /// Build flat list of selectable items
//         final List<_ZoneSelectItem> selectableItems = _buildZoneSelectItems(zones, cubit);
//
//         /// Find currently selected item
//         final _ZoneSelectItem? selectedItem = _findSelectedZoneItem(
//           selectableItems,
//           selection.zoneId,
//           selection.subZoneId,
//         );
//
//         return Padding(
//           padding: const EdgeInsets.only(left: 120),
//           child: FusionNeumorphicDropdown<_ZoneSelectItem>(
//             value: selectedItem,
//             matchChildWidth: true,
//             hintText: 'Select Zone',
//             height: 32,
//             borderRadius: BorderRadius.circular(8),
//             items: selectableItems,
//             displayValue: selectedItem?.name,
//             isItemEnabled: (_ZoneSelectItem item) => item.isSelectable,
//             itemPadding: const EdgeInsets.symmetric(horizontal: 12),
//             child: _buildZoneDropdownChild(context, selectedItem),
//             itemBuilder: (BuildContext ctx, _ZoneSelectItem item) {
//               final bool isSelected = selectedItem?.id == item.id;
//               return _buildZoneDropdownItem(ctx, item, isSelected, zones, cubit);
//             },
//             onChanged: (_ZoneSelectItem item) {
//               if (item.isSubZone) {
//                 cubit.updateSelectedZone(item.parentZoneId, subZoneId: item.id);
//               } else {
//                 cubit.updateSelectedZone(item.id);
//               }
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildEquipmentLocationDropdown(BuildContext context) {
//     return BlocSelector<AddControllerCubit, AddControllerState, String?>(
//       selector: (AddControllerState state) => state.selectedEquipmentLocationId,
//       builder: (BuildContext context, String? selectedEquipLocationId) {
//         final AddControllerCubit cubit = context.read<AddControllerCubit>();
//         final List<EquipLocation> equipLocations = cubit.availableEquipmentLocations;
//
//         final EquipLocation? selectedLocation =
//             selectedEquipLocationId != null
//                 ? equipLocations.cast<EquipLocation?>().firstWhere(
//                   (EquipLocation? e) => e?.id == selectedEquipLocationId,
//                   orElse: () => null,
//                 )
//                 : null;
//
//         return Padding(
//           padding: const EdgeInsets.only(left: 120),
//           child: FusionNeumorphicDropdown<EquipLocation>(
//             value: selectedLocation,
//             hintText: 'Select equipment location',
//             height: 32,
//             borderRadius: BorderRadius.circular(8),
//             items: equipLocations,
//             displayValue: selectedLocation?.name,
//             itemLabelBuilder: (EquipLocation location) => location.name,
//             onChanged: (EquipLocation location) {
//               cubit.updateSelectedEquipmentLocation(location.id);
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   /// Build flat list of zone items (including non-selectable parent zones with subzones)
//   List<_ZoneSelectItem> _buildZoneSelectItems(List<Zone> zones, AddControllerCubit cubit) {
//     final List<_ZoneSelectItem> selectableItems = <_ZoneSelectItem>[];
//     for (final Zone zone in zones) {
//       final List<SubZone> subZones = cubit.getSubZonesForZone(zone.id);
//       if (subZones.isEmpty) {
//         /// Zone without subzones - can be selected directly
//         selectableItems.add(
//           _ZoneSelectItem(
//             id: zone.id,
//             name: zone.name,
//             color: zone.color,
//             isSubZone: false,
//             isSelectable: true,
//             parentZoneId: null,
//           ),
//         );
//       } else {
//         /// Zone with subzones - add as non-selectable header
//         selectableItems.add(
//           _ZoneSelectItem(
//             id: zone.id,
//             name: zone.name,
//             color: zone.color,
//             isSubZone: false,
//             isSelectable: false,
//             parentZoneId: null,
//           ),
//         );
//
//         /// Add all subzones as selectable items
//         for (final SubZone subZone in subZones) {
//           selectableItems.add(
//             _ZoneSelectItem(
//               id: subZone.id,
//               name: subZone.name,
//               color: zone.color,
//               isSubZone: true,
//               isSelectable: true,
//               parentZoneId: zone.id,
//               parentZoneName: zone.name,
//             ),
//           );
//         }
//       }
//     }
//     return selectableItems;
//   }
//
//   /// Find currently selected zone item from the list
//   _ZoneSelectItem? _findSelectedZoneItem(
//     List<_ZoneSelectItem> items,
//     String? zoneId,
//     String? subZoneId,
//   ) {
//     if (subZoneId != null) {
//       return items.cast<_ZoneSelectItem?>().firstWhere(
//         (_ZoneSelectItem? item) => item?.id == subZoneId,
//         orElse: () => null,
//       );
//     } else if (zoneId != null) {
//       return items.cast<_ZoneSelectItem?>().firstWhere(
//         (_ZoneSelectItem? item) => item?.id == zoneId && !item!.isSubZone,
//         orElse: () => null,
//       );
//     }
//     return null;
//   }
//
//   /// Build the child widget displayed in the dropdown button
//   Widget? _buildZoneDropdownChild(BuildContext context, _ZoneSelectItem? selectedItem) {
//     if (selectedItem == null) return null;
//
//     return Container(
//       height: 32,
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: context.colorScheme.elevation1,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: <BoxShadow>[
//           BoxShadow(color: context.colorScheme.elevation2, blurRadius: 1, offset: const Offset(-2, -3)),
//           BoxShadow(color: context.colorScheme.black, blurRadius: 1, offset: const Offset(2, 3)),
//         ],
//       ),
//       child: Row(
//         children: <Widget>[
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: selectedItem.color,
//               borderRadius: BorderRadius.circular(3),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: FusionAppText(
//               text: selectedItem.name,
//               style: Theme.of(context).textTheme.bodySmall,
//               textOverflow: TextOverflow.ellipsis,
//             ),
//           ),
//           FusionIcon.icon(
//             Icons.keyboard_arrow_down_rounded,
//             size: 22,
//             color: context.colorScheme.onSurface.withAlpha(200),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Build a zone dropdown item with proper styling
//   Widget _buildZoneDropdownItem(
//     BuildContext context,
//     _ZoneSelectItem item,
//     bool isSelected,
//     List<Zone> allZones,
//     AddControllerCubit cubit,
//   ) {
//     /// If this is a non-selectable parent zone (has subzones), show as header only
//     if (!item.isSelectable && !item.isSubZone) {
//       return Row(
//         children: <Widget>[
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: item.color,
//               borderRadius: BorderRadius.circular(3),
//               border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: FusionAppText(
//               text: item.name,
//               style: Theme.of(context).textTheme.l1Regular,
//             ),
//           ),
//         ],
//       );
//     }
//
//     /// Selectable item (zone without subzones OR subzone)
//     return Padding(
//       padding: EdgeInsets.only(
//         left: item.isSubZone ? 20 : 0,
//         top: 6,
//         bottom: 6,
//       ),
//       child: Row(
//         children: <Widget>[
//           if (item.isSubZone)
//             /// Bullet point for subzone
//             Container(
//               width: 5,
//               height: 5,
//               margin: const EdgeInsets.only(right: 8),
//               decoration: BoxDecoration(
//                 color: context.colorScheme.elevation5,
//                 shape: BoxShape.circle,
//               ),
//             )
//           else
//             /// Color indicator for zone
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: item.color,
//                     borderRadius: BorderRadius.circular(3),
//                     border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//               ],
//             ),
//
//           /// Name
//           Expanded(
//             child: FusionAppText(text: item.name, style: Theme.of(context).textTheme.l1Regular),
//           ),
//
//           /// Radio button (only for selectable items)
//           _buildRadioButton(context, isSelected),
//         ],
//       ),
//     );
//   }
//
//   /// Build a styled radio button
//   Widget _buildRadioButton(BuildContext context, bool isSelected) {
//     return Container(
//       width: 16,
//       height: 16,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(
//           color: isSelected ? context.colorScheme.iconWhite : context.colorScheme.strokeDark,
//           width: 1,
//         ),
//       ),
//       child:
//           isSelected
//               ? Center(
//                 child: Container(
//                   width: 9,
//                   height: 9,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: context.colorScheme.iconWhite,
//                   ),
//                 ),
//               )
//               : null,
//     );
//   }
//
//   Widget _buildAssignControlCheckbox(BuildContext context, AddControllerState state) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 120),
//       child: GestureDetector(
//         onTap: () {
//           context.read<AddControllerCubit>().toggleAssignControl(!state.assignControl);
//         },
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             FusionCheckbox(
//               semanticId: '',
//               value: state.assignControl,
//               onChanged: () {
//                 context.read<AddControllerCubit>().toggleAssignControl(!state.assignControl);
//               },
//             ),
//             const SizedBox(width: 8),
//             FusionAppText(
//               text: 'Assign control',
//               style: Theme.of(context).textTheme.l1Regular,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildControlAssignmentDropdown(BuildContext context, AddControllerState state) {
//     return BlocSelector<AddControllerCubit, AddControllerState, Set<String>>(
//       selector: (AddControllerState state) => state.selectedControlZoneIds,
//       builder: (BuildContext context, Set<String> selectedControlZoneIds) {
//         final AddControllerCubit cubit = context.read<AddControllerCubit>();
//         final List<Zone> zones = cubit.availableZones;
//         final bool isProController = cubit.supportsMultipleZones;
//         final bool isZoneLocation = state.locationType == LocationType.zone;
//         final String? thisZoneId = cubit.thisZoneId;
//
//         /// Build flat list of selectable items for control zones
//         final List<_ZoneSelectItem> selectableItems = _buildControlZoneSelectItems(
//           zones,
//           cubit,
//           thisZoneId: thisZoneId,
//           isZoneLocation: isZoneLocation,
//         );
//
//         /// Find currently selected item (for single select - LT controllers)
//         _ZoneSelectItem? selectedItem;
//         if (selectedControlZoneIds.length == 1) {
//           final String selectedId = selectedControlZoneIds.first;
//           selectedItem = selectableItems.cast<_ZoneSelectItem?>().firstWhere(
//             (_ZoneSelectItem? item) => item?.id == selectedId && item!.isSelectable,
//             orElse: () => null,
//           );
//         }
//
//         /// Get display text
//         String? displayText;
//         if (selectedControlZoneIds.isEmpty) {
//           displayText = null;
//         } else if (selectedControlZoneIds.length == 1) {
//           // Show "This Zone" prefix if the selected zone is the current location zone
//           if (selectedItem != null && isZoneLocation && selectedItem.id == thisZoneId) {
//             displayText = 'This Zone (${selectedItem.name})';
//           } else {
//             displayText = selectedItem?.name ?? 'Select zone';
//           }
//         } else {
//           displayText = '${selectedControlZoneIds.length} zones selected';
//         }
//
//         return _FormFieldRow(
//           label: 'Control',
//           child: FusionNeumorphicDropdown<_ZoneSelectItem>(
//             value: selectedItem,
//             matchChildWidth: true,
//             hintText: 'Select zone',
//             height: 30,
//             borderRadius: BorderRadius.circular(8),
//             items: selectableItems,
//             displayValue: displayText,
//             isItemEnabled: (_ZoneSelectItem item) => item.isSelectable,
//             itemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
//             child: _buildControlZoneDropdownChild(context, selectedItem, selectedControlZoneIds, isProController, thisZoneId),
//             itemBuilder: (BuildContext ctx, _ZoneSelectItem item) {
//               final bool isSelected = selectedControlZoneIds.contains(item.id);
//               final bool isThisZone = item.id == thisZoneId && isZoneLocation;
//               return _buildControlZoneDropdownItem(ctx, item, isSelected, isProController, isThisZone);
//             },
//             onChanged: (_ZoneSelectItem item) {
//               cubit.toggleControlZone(item.id);
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   /// Build dropdown child for control zone selection
//   Widget? _buildControlZoneDropdownChild(
//     BuildContext context,
//     _ZoneSelectItem? selectedItem,
//     Set<String> selectedControlZoneIds,
//     bool isProController,
//     String? thisZoneId,
//   ) {
//     if (selectedControlZoneIds.isEmpty) return null;
//     if (selectedControlZoneIds.length > 1) {
//       return Container(
//         height: 30,
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         decoration: BoxDecoration(
//           color: context.colorScheme.elevation1,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: <BoxShadow>[
//             BoxShadow(color: context.colorScheme.elevation2, blurRadius: 1, offset: const Offset(-2, -3)),
//             BoxShadow(color: context.colorScheme.black, blurRadius: 1, offset: const Offset(2, 3)),
//           ],
//         ),
//         child: Row(
//           children: <Widget>[
//             Expanded(
//               child: FusionAppText(
//                 text: '${selectedControlZoneIds.length} zones selected',
//                 style: Theme.of(context).textTheme.bodySmall,
//                 textOverflow: TextOverflow.ellipsis,
//               ),
//             ),
//             FusionIcon.icon(
//               Icons.keyboard_arrow_down_rounded,
//               size: 22,
//               color: context.colorScheme.onSurface.withAlpha(200),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (selectedItem == null) return null;
//
//     return Container(
//       height: 30,
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       decoration: BoxDecoration(
//         color: context.colorScheme.elevation1,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: <BoxShadow>[
//           BoxShadow(color: context.colorScheme.elevation2, blurRadius: 1, offset: const Offset(-2, -3)),
//           BoxShadow(color: context.colorScheme.black, blurRadius: 1, offset: const Offset(2, 3)),
//         ],
//       ),
//       child: Row(
//         children: <Widget>[
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: selectedItem.color,
//               borderRadius: BorderRadius.circular(3),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: FusionAppText(
//               text: selectedItem.id == thisZoneId ? 'This Zone (${selectedItem.name})' : selectedItem.name,
//               style: Theme.of(context).textTheme.bodySmall,
//               textOverflow: TextOverflow.ellipsis,
//             ),
//           ),
//           FusionIcon.icon(
//             Icons.keyboard_arrow_down_rounded,
//             size: 22,
//             color: context.colorScheme.onSurface.withAlpha(200),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Build a control zone dropdown item with proper styling (checkbox for Pro, radio for LT)
//   Widget _buildControlZoneDropdownItem(
//     BuildContext context,
//     _ZoneSelectItem item,
//     bool isSelected,
//     bool isProController,
//     bool isThisZone,
//   ) {
//     /// If this is a non-selectable parent zone (has subzones), show as header only
//     if (!item.isSelectable && !item.isSubZone) {
//       return Row(
//         children: <Widget>[
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: item.color,
//               borderRadius: BorderRadius.circular(3),
//               border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: FusionAppText(
//               text: item.name,
//               style: Theme.of(context).textTheme.l1Regular,
//             ),
//           ),
//         ],
//       );
//     }
//
//     /// Selectable item (zone without subzones OR subzone)
//     return Padding(
//       padding: EdgeInsets.only(
//         left: item.isSubZone ? 20 : 0,
//         top: 6,
//         bottom: 6,
//       ),
//       child: Row(
//         children: <Widget>[
//           if (item.isSubZone)
//             /// Bullet point for subzone
//             Container(
//               width: 5,
//               height: 5,
//               margin: const EdgeInsets.only(right: 8),
//               decoration: BoxDecoration(
//                 color: context.colorScheme.elevation5,
//                 shape: BoxShape.circle,
//               ),
//             )
//           else
//             /// Color indicator for zone
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 Container(
//                   width: 12,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: item.color,
//                     borderRadius: BorderRadius.circular(3),
//                     border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//               ],
//             ),
//
//           /// Name with "This Zone" suffix if applicable
//           Expanded(
//             child: FusionAppText(
//               text: isThisZone ? '${item.name} (This Zone)' : item.name,
//               style: Theme.of(context).textTheme.l1Regular,
//             ),
//           ),
//
//           /// Checkbox for Pro controllers, Radio for LT controllers
//           if (isProController) _buildCheckbox(context, isSelected) else _buildRadioButton(context, isSelected),
//         ],
//       ),
//     );
//   }
//
//   /// Build a styled checkbox
//   Widget _buildCheckbox(BuildContext context, bool isSelected) {
//     return Container(
//       width: 16,
//       height: 16,
//       decoration: BoxDecoration(
//         color: isSelected ? context.colorScheme.iconWhite : Colors.transparent,
//         borderRadius: BorderRadius.circular(4),
//         border: Border.all(
//           color: isSelected ? context.colorScheme.iconWhite : context.colorScheme.strokeDark,
//           width: 1,
//         ),
//       ),
//       child:
//           isSelected
//               ? Icon(
//                 Icons.check,
//                 size: 12,
//                 color: context.colorScheme.primaryBlack,
//               )
//               : null,
//     );
//   }
//
//   /// Build flat list of zone items for control assignment
//   List<_ZoneSelectItem> _buildControlZoneSelectItems(
//     List<Zone> zones,
//     AddControllerCubit cubit, {
//     String? thisZoneId,
//     bool isZoneLocation = false,
//   }) {
//     final List<_ZoneSelectItem> selectableItems = <_ZoneSelectItem>[];
//     for (final Zone zone in zones) {
//       final List<SubZone> subZones = cubit.getSubZonesForZone(zone.id);
//       if (subZones.isEmpty) {
//         /// Zone without subzones - can be selected directly
//         selectableItems.add(
//           _ZoneSelectItem(
//             id: zone.id,
//             name: zone.name,
//             color: zone.color,
//             isSubZone: false,
//             isSelectable: true,
//             parentZoneId: null,
//           ),
//         );
//       } else {
//         /// Zone with subzones - add as non-selectable header
//         selectableItems.add(
//           _ZoneSelectItem(
//             id: zone.id,
//             name: zone.name,
//             color: zone.color,
//             isSubZone: false,
//             isSelectable: false,
//             parentZoneId: null,
//           ),
//         );
//
//         /// Add all subzones as selectable items
//         for (final SubZone subZone in subZones) {
//           selectableItems.add(
//             _ZoneSelectItem(
//               id: subZone.id,
//               name: subZone.name,
//               color: zone.color,
//               isSubZone: true,
//               isSelectable: true,
//               parentZoneId: zone.id,
//               parentZoneName: zone.name,
//             ),
//           );
//         }
//       }
//     }
//     return selectableItems;
//   }
//
//   Widget _buildFooter(BuildContext context, AddControllerState state) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border(
//           top: BorderSide(
//             color: context.colorScheme.strokeLight,
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: <Widget>[
//           NeumorphicButton(
//             semanticId: _isEditMode ? 'edit_controller_update_btn' : 'add_controller_add_message_btn',
//             onTap: () => _isEditMode ? _onUpdateButtonPressed(context) : _onAddButtonPressed(context),
//             height: 32,
//             borderRadius: 8,
//             width: 90,
//             isActive: !state.isLoading,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 FusionIcon.icon(
//                   _isEditMode ? Icons.check : Icons.add,
//                   size: 18,
//                   color: context.colorScheme.iconWhite,
//                 ),
//                 const SizedBox(width: 8),
//                 FusionAppText(
//                   text: state.isLoading ? (_isEditMode ? 'Updating...' : 'Adding...') : (_isEditMode ? 'Update' : 'Add'),
//                   style: context.textTheme.l1Medium,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _onAddButtonPressed(BuildContext context) async {
//     final String? newControllerId = await context.read<AddControllerCubit>().addController();
//     if (newControllerId != null && context.mounted) {
//       widget.onControllerAdded?.call(newControllerId);
//       Navigator.of(context).pop(true);
//     }
//   }
//
//   Future<void> _onUpdateButtonPressed(BuildContext context) async {
//     final String? controllerId = await context.read<AddControllerCubit>().updateController();
//     if (controllerId != null && context.mounted) {
//       widget.onControllerAdded?.call(controllerId);
//       Navigator.of(context).pop(true);
//     }
//   }
// }
//
// /// Form field row with label on the left
// class _FormFieldRow extends StatelessWidget {
//   final String label;
//   final Widget child;
//
//   const _FormFieldRow({
//     required this.label,
//     required this.child,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: <Widget>[
//         SizedBox(
//           width: 120,
//           child: FusionAppText(text: label, style: Theme.of(context).textTheme.l1Regular),
//         ),
//         Expanded(child: child),
//       ],
//     );
//   }
// }
//
// /// Helper class for zone selection dropdown items
// class _ZoneSelectItem {
//   final String id;
//   final String name;
//   final Color color;
//   final bool isSubZone;
//   final bool isSelectable;
//   final String? parentZoneId;
//   final String? parentZoneName;
//
//   const _ZoneSelectItem({
//     required this.id,
//     required this.name,
//     required this.color,
//     required this.isSubZone,
//     required this.isSelectable,
//     required this.parentZoneId,
//     this.parentZoneName,
//   });
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is _ZoneSelectItem && other.id == id;
//   }
//
//   @override
//   int get hashCode => id.hashCode;
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_cubit.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/add_controller/add_controller_state.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import '../../../../add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import '../../../../add_source_popup/view/widgets/common_widgets/add_sources_dropdown.dart';
import '../../../../create_zone_popup/view/widgets/CommonWidgets/create_zone_bordered_textfield.dart';
import '../../../../create_zone_popup/view/widgets/CommonWidgets/create_zone_label_field.dart';

class AddControllerDialog {
  AddControllerDialog._();

  static Future<bool?> show(
    BuildContext context, {
    void Function(String controllerId)? onControllerAdded,
  }) {
    final AddControllerCubit cubit = AddControllerCubit(
      projectViewModel: serviceLocator<ProjectViewModel>(),
    );
    final ValueNotifier<bool> buttonEnabled = ValueNotifier<bool>(false); // ← start false

    return FusionDrawer.show<bool>(
      context: context,
      semanticId: 'add_controller',
      title: 'Add Controller',
      buttonLabel: 'Save Controller',
      buttonEnabledNotifier: buttonEnabled,
      onButtonPressed: () async {
        buttonEnabled.value = false; // ← local variable, not widget.
        final String? id = await cubit.addController();
        if (id != null) {
          onControllerAdded?.call(id);
          if (context.mounted) Navigator.of(context).pop(true);
        }
      },
      content: BlocProvider<AddControllerCubit>.value(
        value: cubit,
        child: _DrawerContent(
          isEditMode: false,
          buttonEnabledNotifier: buttonEnabled,
        ),
      ),
    );
  }

  static Future<bool?> showForEdit(
    BuildContext context, {
    required FusionController controller,
    void Function(String controllerId)? onControllerUpdated,
  }) {
    final AddControllerCubit cubit = AddControllerCubit(
      projectViewModel: serviceLocator<ProjectViewModel>(),
    )..initForEdit(controller);
    final ValueNotifier<bool> buttonEnabled = ValueNotifier<bool>(false);

    return FusionDrawer.show<bool>(
      context: context,
      semanticId: 'edit_controller',
      title: 'Edit Controller',
      buttonLabel: 'Edit Controller',
      buttonEnabledNotifier: buttonEnabled,
      onButtonPressed: () async {
        buttonEnabled.value = false; // ← local variable, not widget.
        final String? id = await cubit.updateController();
        if (id != null) {
          onControllerUpdated?.call(id);
          if (context.mounted) Navigator.of(context).pop(true);
        }
      },
      content: BlocProvider<AddControllerCubit>.value(
        value: cubit,
        child: _DrawerContent(
          isEditMode: true,
          initialName: controller.name,
          buttonEnabledNotifier: buttonEnabled,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

class _DrawerContent extends StatefulWidget {
  final bool isEditMode;
  final String? initialName;
  final ValueNotifier<bool> buttonEnabledNotifier; // ← added

  const _DrawerContent({
    required this.isEditMode,
    required this.buttonEnabledNotifier, // ← added
    this.initialName,
  });

  @override
  State<_DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends State<_DrawerContent> {
  late final TextEditingController _nameController;
  final GlobalKey _controlFieldKey = GlobalKey();
  bool _wasAssignControl = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName ?? 'Untitled Controller',
    );
    widget.buttonEnabledNotifier.value = false;
    _nameController.addListener(() {
      final AddControllerState state = context.read<AddControllerCubit>().state;
      widget.buttonEnabledNotifier.value = _isFormValid(state);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Add this helper to _DrawerContentState
  bool _isFormValid(AddControllerState state) {
    if (_nameController.text.trim().isEmpty) return false;
    if (state.controllerType == null) return false;
    if (state.locationType == null) return false;
    if (state.locationType == LocationType.zone) {
      if (state.selectedZoneId == null && state.selectedSubZoneId == null) {
        return false;
      }
    } else {
      if (state.selectedEquipmentLocationId == null) return false;
    }
    if (state.assignControl && state.selectedControlZoneIds.isEmpty) {
      return false;
    }

    return true;
  }

  void _scrollToControlField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? ctx = _controlFieldKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.9,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddControllerCubit, AddControllerState>(
      listener: (BuildContext context, AddControllerState state) {
        // ── Auto-scroll when control section appears ────────────────────────
        if (state.assignControl && !_wasAssignControl) {
          _scrollToControlField();
        }
        _wasAssignControl = state.assignControl;

        // ── Re-evaluate button validity on every state change ───────────────
        widget.buttonEnabledNotifier.value = _isFormValid(state);

        // ── Error: show toast (button already disabled from onButtonPressed) ─
        if (state.errorMessage != null) {
          FusionToast.error(
            context,
            message: state.errorMessage!,
          );
          // Re-enable only if the form is still valid after the error
          widget.buttonEnabledNotifier.value = _isFormValid(state);
        }
      },
      builder: (BuildContext context, AddControllerState state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ── Controller Name ──────────────────────────────────────────
              FusionLabeledField(
                label: 'Controller Name',
                semanticId: 'output_name_label',
                child: FusionBorderedTextField(
                  controller: _nameController,
                  semanticId: 'add_controller_name',
                  hintText: 'Enter controller name',
                  contentPadding: const EdgeInsets.all(16),
                  onChanged: (String v) => context.read<AddControllerCubit>().updateName(v),
                ),
              ),
              const SizedBox(height: 20),

              // ── Controller Type ──────────────────────────────────────────
              _buildTypeDropdown(context, state),

              // ── Location ─────────────────────────────────────────────────
              if (state.controllerType != null) ...<Widget>[
                const SizedBox(height: 20),
                _buildLocationSegment(context, state),
              ],

              // ── Select Zone / Equipment Location ─────────────────────────
              if (state.locationType != null) ...<Widget>[
                const SizedBox(height: 20),
                _buildLocationSelectionDropdown(context, state),
              ],

              // ── Auto-add toggle ───────────────────────────────────────────
              if (state.locationType != null) ...<Widget>[
                const SizedBox(height: 20),
                _buildAutoAddToggle(context, state),
              ],

              // ── Control ───────────────────────────────────────────────────
              if (state.assignControl) ...<Widget>[
                const SizedBox(height: 20),
                SizedBox(
                  key: _controlFieldKey,
                  child: _buildControlAssignmentDropdown(context, state),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Type dropdown ──────────────────────────────────────────────────────────

  Widget _buildTypeDropdown(BuildContext context, AddControllerState state) {
    return FusionOutlinedDropdown<ControllerType>(
      label: 'Controller Type',
      hint: 'Select controller Type',
      value: state.controllerType,
      items: ControllerType.values,
      itemLabelBuilder: (ControllerType type) => _controllerTypeLabel(type),
      onChanged: (ControllerType value) => context.read<AddControllerCubit>().updateControllerType(value),
    );
  }

  String _controllerTypeLabel(ControllerType type) {
    switch (type) {
      case ControllerType.controlPalLT:
        return 'Control Pal LT';
      case ControllerType.controlPalPro:
        return 'Control Pal Pro';
      case ControllerType.virtualControlPalLT:
        return 'Virtual Control Pal LT';
      case ControllerType.virtualControlPalPro:
        return 'Virtual Control Pal Pro';
    }
  }

  bool _isProController(ControllerType? type) => type == ControllerType.controlPalPro || type == ControllerType.virtualControlPalPro;

  // ── Location segmented control ─────────────────────────────────────────────

  Widget _buildLocationSegment(BuildContext context, AddControllerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'Location',
          style: context.textTheme.l1Medium.copyWith(
            color: context.colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        FusionRadioChipSelector<LocationType>(
          selected: state.locationType,
          options: LocationType.values,
          labelBuilder: (LocationType type) {
            switch (type) {
              case LocationType.zone:
                return 'Zone';
              case LocationType.equipmentLocation:
                return 'Equipment Location';
            }
          },
          onChanged: (LocationType value) => context.read<AddControllerCubit>().updateLocationType(value),
        ),
      ],
    );
  }

  // ── Zone / Equipment location dropdown ────────────────────────────────────

  Widget _buildLocationSelectionDropdown(BuildContext context, AddControllerState state) {
    if (state.locationType == LocationType.zone) {
      return _buildZoneDropdown(context);
    }
    return _buildEquipmentLocationDropdown(context);
  }

  Widget _buildZoneDropdown(BuildContext context) {
    return BlocSelector<AddControllerCubit, AddControllerState, ({String? zoneId, String? subZoneId})>(
      selector: (AddControllerState s) => (zoneId: s.selectedZoneId, subZoneId: s.selectedSubZoneId),
      builder: (BuildContext context, ({String? zoneId, String? subZoneId}) selection) {
        final AddControllerCubit cubit = context.read<AddControllerCubit>();
        final List<Zone> zones = cubit.availableZones;
        final List<_ZoneSelectItem> items = _buildZoneSelectItems(zones, cubit);
        final _ZoneSelectItem? selected = _findSelectedZoneItem(items, selection.zoneId, selection.subZoneId);

        // Derive the selected id once so itemWidgetBuilder can close over it
        final String? selectedId = selection.subZoneId ?? selection.zoneId;

        return FusionOutlinedDropdown<_ZoneSelectItem>(
          label: 'Select Zone',
          hint: 'Select Zone',
          value: selected,
          items: items,
          itemLabelBuilder: (_ZoneSelectItem i) => i.name,
          selectedItemBuilder: selected != null ? (BuildContext ctx, _ZoneSelectItem item) => _buildZoneSelectedItem(ctx, item) : null,
          itemWidgetBuilder: (BuildContext ctx, _ZoneSelectItem item, bool _) {
            // Use selectedId directly instead of the dropdown's isSelected param
            final bool isSelected = item.id == selectedId;
            return _buildZoneItem(ctx, item, isSelected);
          },
          onChanged: (_ZoneSelectItem item) {
            if (!item.isSelectable) return;
            if (item.isSubZone) {
              cubit.updateSelectedZone(item.parentZoneId, subZoneId: item.id);
            } else {
              cubit.updateSelectedZone(item.id);
            }
          },
        );
      },
    );
  }

  Widget _buildEquipmentLocationDropdown(BuildContext context) {
    return BlocSelector<AddControllerCubit, AddControllerState, String?>(
      selector: (AddControllerState s) => s.selectedEquipmentLocationId,
      builder: (BuildContext context, String? selectedId) {
        final AddControllerCubit cubit = context.read<AddControllerCubit>();
        final List<EquipLocation> locations = cubit.availableEquipmentLocations;
        final EquipLocation? selected =
            selectedId != null ? locations.cast<EquipLocation?>().firstWhere((EquipLocation? e) => e?.id == selectedId, orElse: () => null) : null;

        return FusionOutlinedDropdown<EquipLocation>(
          label: 'Select Equipment Location',
          hint: 'Select equipment location',
          value: selected,
          items: locations,
          itemLabelBuilder: (EquipLocation l) => l.name,
          onChanged: (EquipLocation l) => cubit.updateSelectedEquipmentLocation(l.id),
        );
      },
    );
  }

  // ── Auto-add toggle ────────────────────────────────────────────────────────

  Widget _buildAutoAddToggle(BuildContext context, AddControllerState state) {
    return Row(
      children: <Widget>[
        FusionSwitch(
          value: state.assignControl,
          onChanged: (bool value) => context.read<AddControllerCubit>().toggleAssignControl(value),
          width: 44,
          height: 24,
        ),
        const SizedBox(width: 12),
        FusionAppText(
          text: 'Assign Control',
          style: Theme.of(context).textTheme.b3Regular,
        ),
      ],
    );
  }

  // ── Control assignment dropdown ────────────────────────────────────────────

  Widget _buildControlAssignmentDropdown(BuildContext context, AddControllerState state) {
    return BlocSelector<AddControllerCubit, AddControllerState, Set<String>>(
      selector: (AddControllerState s) => s.selectedControlZoneIds,
      builder: (BuildContext context, Set<String> selectedIds) {
        final AddControllerCubit cubit = context.read<AddControllerCubit>();
        final bool isProController = _isProController(state.controllerType);
        final bool isZoneLocation = state.locationType == LocationType.zone;
        final String? thisZoneId = cubit.thisZoneId;

        // ── Stable order — no sorting, no bubbling ───────────────────────────
        final List<_ZoneSelectItem> items = _buildControlZoneSelectItems(
          cubit.availableZones,
          cubit,
          thisZoneId: thisZoneId,
          isZoneLocation: isZoneLocation,
        );

        if (isProController) {
          return _ProControlMultiSelect(
            items: items,
            selectedIds: selectedIds,
            thisZoneId: thisZoneId,
            isZoneLocation: isZoneLocation,
            onToggle: (String id) => cubit.toggleControlZone(id),
          );
        }

        // ── LT: single select dropdown ─────────────────────────────────────
        _ZoneSelectItem? selectedItem;
        if (selectedIds.isNotEmpty) {
          selectedItem = items.cast<_ZoneSelectItem?>().firstWhere(
            (_ZoneSelectItem? i) => i != null && selectedIds.contains(i.id) && i.isSelectable,
            orElse: () => null,
          );
        }

        String displayLabel() {
          if (selectedIds.isEmpty) return '';
          if (selectedItem != null) {
            final bool isThisZone = isZoneLocation && selectedItem.id == thisZoneId;
            final String name =
                selectedItem.isSubZone && selectedItem.parentZoneName != null ? '${selectedItem.parentZoneName} - ${selectedItem.name}' : selectedItem.name;
            return isThisZone ? 'This Zone - $name' : name;
          }
          return '';
        }

        return FusionOutlinedDropdown<_ZoneSelectItem>(
          label: 'Control',
          hint: 'Select Control',
          value: selectedItem,
          items: items,
          itemLabelBuilder: (_ZoneSelectItem i) => i.name,
          selectedItemBuilder:
              selectedIds.isNotEmpty
                  ? (BuildContext ctx, _ZoneSelectItem item) => FusionAppText(
                    text: displayLabel(),
                    maxLine: 1,
                    style: ctx.textTheme.b3Regular.copyWith(
                      color: ctx.colorScheme.textPrimary,
                    ),
                  )
                  : null,
          itemWidgetBuilder: (BuildContext ctx, _ZoneSelectItem item, bool _) {
            final bool isSelected = selectedIds.contains(item.id);
            final bool isThisZone = item.id == thisZoneId && isZoneLocation;
            return _buildControlZoneItem(ctx, item, isSelected, false, isThisZone);
          },
          onChanged: (_ZoneSelectItem item) {
            if (!item.isSelectable) return;
            cubit.toggleControlZone(item.id);
          },
        );
      },
    );
  }

  // ── Zone item renderers ────────────────────────────────────────────────────

  Widget _buildZoneSelectedItem(BuildContext context, _ZoneSelectItem item) {
    final String label = item.isSubZone && item.parentZoneName != null ? '${item.parentZoneName} - ${item.name}' : item.name;

    return Row(
      children: <Widget>[
        _ColorDot(color: item.color),
        const SizedBox(width: 8),
        Expanded(
          child: FusionAppText(
            text: label,
            maxLine: 1,
            style: context.textTheme.b3Regular.copyWith(
              color: context.colorScheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneItem(BuildContext context, _ZoneSelectItem item, bool isSelected) {
    final String label = item.isSubZone && item.parentZoneName != null ? '${item.parentZoneName} - ${item.name}' : item.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          _ColorDot(color: item.color),
          const SizedBox(width: 8),
          Expanded(
            child: FusionAppText(
              text: label,
              style: Theme.of(context).textTheme.l1Regular,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlZoneItem(
    BuildContext context,
    _ZoneSelectItem item,
    bool isSelected,
    bool isProController,
    bool isThisZone,
  ) {
    if (!item.isSelectable && !item.isSubZone) return const SizedBox.shrink();

    final String label =
        item.isSubZone && item.parentZoneName != null
            ? '${item.parentZoneName} - ${item.name}'
            : isThisZone
            ? '${item.name} (This Zone)'
            : item.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          _ColorDot(color: item.color),
          const SizedBox(width: 8),
          Expanded(
            child: FusionAppText(
              text: label,
              style: Theme.of(context).textTheme.l1Regular,
            ),
          ),
        ],
      ),
    );
  }
  // ── Zone list builders ─────────────────────────────────────────────────────

  // Replace _buildZoneSelectItems with this flat version
  List<_ZoneSelectItem> _buildZoneSelectItems(List<Zone> zones, AddControllerCubit cubit) {
    final List<_ZoneSelectItem> result = <_ZoneSelectItem>[];
    for (final Zone zone in zones) {
      final List<SubZone> subs = cubit.getSubZonesForZone(zone.id);
      if (subs.isEmpty) {
        result.add(
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
        // Skip non-selectable parent header — subzones carry "Parent - Sub" label
        for (final SubZone sub in subs) {
          result.add(
            _ZoneSelectItem(
              id: sub.id,
              name: sub.name,
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
    return result;
  }

  List<_ZoneSelectItem> _buildControlZoneSelectItems(
    List<Zone> zones,
    AddControllerCubit cubit, {
    String? thisZoneId,
    bool isZoneLocation = false,
  }) {
    final List<_ZoneSelectItem> result = <_ZoneSelectItem>[];
    for (final Zone zone in zones) {
      final List<SubZone> subs = cubit.getSubZonesForZone(zone.id);
      if (subs.isEmpty) {
        // Zone without subzones — add directly as selectable
        result.add(
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
        // Zone WITH subzones — skip the non-selectable parent header entirely,
        // subzones carry "ParentName - SubName" label themselves
        for (final SubZone sub in subs) {
          result.add(
            _ZoneSelectItem(
              id: sub.id,
              name: sub.name,
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
    return result;
  }

  _ZoneSelectItem? _findSelectedZoneItem(
    List<_ZoneSelectItem> items,
    String? zoneId,
    String? subZoneId,
  ) {
    if (subZoneId != null) {
      return items.cast<_ZoneSelectItem?>().firstWhere((_ZoneSelectItem? i) => i?.id == subZoneId, orElse: () => null);
    }
    if (zoneId != null) {
      return items.cast<_ZoneSelectItem?>().firstWhere((_ZoneSelectItem? i) => i?.id == zoneId && !i!.isSubZone, orElse: () => null);
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Small reusable sub-widgets
// ---------------------------------------------------------------------------

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: context.colorScheme.zone3Stroke, width: 1),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

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
  bool operator ==(Object other) => identical(this, other) || (other is _ZoneSelectItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Proper radio button: white border ring, dark filled dot when selected.

class _ProControlMultiSelect extends StatefulWidget {
  final List<_ZoneSelectItem> items;
  final Set<String> selectedIds;
  final String? thisZoneId;
  final bool isZoneLocation;
  final void Function(String id) onToggle;

  const _ProControlMultiSelect({
    required this.items,
    required this.selectedIds,
    required this.thisZoneId,
    required this.isZoneLocation,
    required this.onToggle,
  });

  @override
  State<_ProControlMultiSelect> createState() => _ProControlMultiSelectState();
}

class _ProControlMultiSelectState extends State<_ProControlMultiSelect> {
  bool _isOpen = false;
  final GlobalKey _dropdownKey = GlobalKey();
  List<_ZoneSelectItem> _filtered = <_ZoneSelectItem>[];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items.where((_ZoneSelectItem i) => i.isSelectable).toList();
  }

  void _toggleOpen() {
    final bool wasOpen = _isOpen; // capture BEFORE setState
    setState(() => _isOpen = !_isOpen);
    if (!wasOpen) {
      // was closed, now opening
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? ctx = _dropdownKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 1.0,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String get _headerLabel {
    final int count = widget.selectedIds.length;
    if (count == 0) return 'Select Zones';
    if (count == 1) {
      final _ZoneSelectItem? item = widget.items.cast<_ZoneSelectItem?>().firstWhere(
        (_ZoneSelectItem? i) => i != null && widget.selectedIds.contains(i.id),
        orElse: () => null,
      );
      return item?.name ?? '1 Zone Selected';
    }
    return '$count Zones Selected';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'Control',
          style: context.textTheme.l1Medium.copyWith(
            color: context.colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        TapRegion(
          onTapOutside: (_) => setState(() => _isOpen = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Trigger ───────────────────────────────────────────────
              GestureDetector(
                onTap: _toggleOpen,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colorScheme.strokeLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: _headerLabel,
                          style: context.textTheme.b3Regular.copyWith(
                            color: widget.selectedIds.isEmpty ? context.colorScheme.onSurface.withAlpha(155) : context.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: context.colorScheme.iconDefault,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Dropdown list ─────────────────────────────────────────
              if (_isOpen) ...<Widget>[
                const SizedBox(height: 4),
                Container(
                  key: _dropdownKey,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.colorScheme.strokeLight,
                      width: 1,
                    ),
                    color: context.colorScheme.elevation2,
                  ),
                  child: Column(
                    children: <Widget>[
                      // Items
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          itemBuilder: (BuildContext context, int index) {
                            final _ZoneSelectItem item = _filtered[index];
                            final bool isSelected = widget.selectedIds.contains(item.id);
                            final bool isThisZone = item.id == widget.thisZoneId && widget.isZoneLocation;
                            final String label =
                                item.isSubZone && item.parentZoneName != null
                                    ? '${item.parentZoneName} - ${item.name}'
                                    : isThisZone
                                    ? '${item.name} (This Zone)'
                                    : item.name;

                            return GestureDetector(
                              onTap: () => widget.onToggle(item.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                color: Colors.transparent,
                                child: Row(
                                  children: <Widget>[
                                    FusionCheckbox(
                                      semanticId: 'ctrl_${item.id}',
                                      value: isSelected,
                                      shape: BoxShape.rectangle,
                                      innerChild: Icon(
                                        Icons.check,
                                        size: 10,
                                        color: context.colorScheme.black,
                                      ),
                                      onChanged: () => widget.onToggle(item.id),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FusionAppText(
                                        text: label,
                                        style: context.textTheme.b3Regular.copyWith(
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    _ColorDot(color: item.color),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Done button ───────────────────────────────────
                      Divider(height: 1, color: context.colorScheme.strokeLight),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: FusionAppButton(
                            semanticId: 'control_zone_done',
                            height: 36,
                            text: widget.selectedIds.isEmpty ? 'Done' : 'Add ${widget.selectedIds.length} Zone${widget.selectedIds.length == 1 ? '' : 's'}',
                            color: context.colorScheme.elevation3,
                            borderRadius: 8,
                            textstyle: context.textTheme.l1Medium.copyWith(
                              color: context.colorScheme.textPrimary,
                            ),
                            onPressed: () => setState(() => _isOpen = false),
                            style: FusionAppButtonStyle.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
