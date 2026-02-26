// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:fusion_launcher/core/service_locator.dart';
// import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
// import 'package:fusion_lib/fusion_lib.dart';
// import 'package:fusion_lib/models/project_entities/endpoints.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';

// import '../presentation/widgets/common_reorderable_list_view.dart';
// import '../presentation/widgets/hardware_item_card.dart';
// import 'widgets/section_header_with_actions.dart';

// class SourcesEndpiointsSection extends StatelessWidget {
//   const SourcesEndpiointsSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(4),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: context.colorScheme.elevation1,
//         border: Border.all(color: context.colorScheme.elevation2, width: 1),
//         borderRadius: const BorderRadius.all(Radius.circular(8)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: <Widget>[
//           Row(
//             children: <Widget>[
//               Expanded(
//                 child: FusionAppText(
//                   text: "SOURCES & ENDPOINTS",
//                   style: context.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w500,
//                     fontSize: FusionSizes.fontSize12,
//                     color: context.colorScheme.textBody,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               // add icon
//               Icon(
//                 LucideIcons.plus200,
//                 size: FusionSizes.iconSize16,
//                 color: context.colorScheme.primaryWhite,
//               ),
//             ],
//           ),

//           // REDORDERABLE SOURCES
//           const SchematicSourcesWidget(),

//           // REDORDERABLE ENDPOINTS
//           const SchematicEndpointsWidget(),
//         ],
//       ),
//     );
//   }
// }

// class SchematicSourcesWidget extends StatefulWidget {
//   const SchematicSourcesWidget({super.key});

//   @override
//   State<SchematicSourcesWidget> createState() => _SchematicSourcesWidgetState();
// }

// class _SchematicSourcesWidgetState extends State<SchematicSourcesWidget> {
//   final TextEditingController searchController = TextEditingController();

//   late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

//   bool get isSearching => searchController.text.isNotEmpty;

//   List<Source> get sources {
//     final String query = searchController.text.trim();
//     if (query.isEmpty) return projectViewModel.sources;
//     return projectViewModel.sources.where((Source s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     searchController.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
//       builder: (BuildContext context, ProjectViewModelState state) {
//         final SelectedItem? selectedDevice = projectViewModel.selectedDevice;

//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             const SizedBox(height: 12),
//             Divider(color: context.colorScheme.strokeLight, thickness: 1, height: 0),
//             const SizedBox(height: 8),
//             SectionHeaderWithActions(
//               sectionTitle: "SOURCES",
//               searchController: searchController,
//               onSearchTextChanged: (String value) {
//                 setState(() {
//                   //refresh UI
//                 });
//               },
//             ),
//             const SizedBox(height: 8),
//             Divider(color: context.colorScheme.strokeLight, thickness: 1, height: 0),
//             const SizedBox(height: 12),

//             CommonReorderableListView<Source>(
//               items: sources,
//               emptyMessage: isSearching ? "No sources match search" : "No sources added yet",
//               onReorder: (int oldIndex, int newIndex) {
//                 if (oldIndex < newIndex) newIndex -= 1;
//                 final String hwToMove = sources[oldIndex].id;
//                 final String hwAtNewIndex = sources[newIndex].id;
//                 projectViewModel.reOrderHardware(
//                   hardwareIdToMove: hwToMove,
//                   hardwareAtNewIndex: hwAtNewIndex,
//                 );
//                 projectViewModel.setSelectedDevice(
//                   hwToMove,
//                   SelectedItemType.source,
//                 );
//               },
//               proxyDecorator: (Widget child, int index, Animation<double> animation) => child,
//               keyExtractor: (Source source) => source.id,
//               itemBuilder: (BuildContext context, Source source, int index) {
//                 final bool isSelected = selectedDevice?.id == source.id && selectedDevice?.type == SelectedItemType.source;

//                 /// Get zone data from hardwareId
//                 String? getZoneName(String hardwareId) {
//                   final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
//                   String? zoneName = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.name;
//                   zoneName ??= projectViewModel.getSubZoneForHardware(hardwareId: hardwareId)?.name;
//                   return zoneName;
//                 }

//                 Color? getZoneColor(String hardwareId) {
//                   final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
//                   Color? zoneColor = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.color;
//                   if (zoneColor == null) {
//                     final SubZone? subZone = projectViewModel.getSubZoneForHardware(hardwareId: hardwareId);
//                     if (subZone != null) zoneColor = projectViewModel.getZoneForSubZone(subZoneId: subZone.id)?.color;
//                   }
//                   return zoneColor;
//                 }

//                 String? getEquipmentLocationForHardware(String hardwareId) {
//                   return projectViewModel.getEquipLocationForHardware(hardwareId: hardwareId)?.name;
//                 }

//                 /// Get location name from listeningAreaId
//                 String? getLocationName(String? areaId) {
//                   if (areaId == null) return null;
//                   final ListeningArea area = serviceLocator<ProjectViewModel>().getListeningArea(areaId: areaId);
//                   return area.name;
//                 }

//                 return HardwareItemCard(
//                   index: index,
//                   name: source.name,
//                   // highlightQuery: _sourcesEndpointsSearchQuery,
//                   assetImagePath: source.assetImagePath,
//                   itemId: source.id,
//                   zoneName: getZoneName(source.id),
//                   zoneColor: getZoneColor(source.id),
//                   location: getLocationName(source.locationEntity.listeningAreaId) ?? "Add location",
//                   equipmentLocation: getEquipmentLocationForHardware(source.id),
//                   isSelected: isSelected,
//                   onTap: () {
//                     projectViewModel.setSelectedDevice(
//                       source.id,
//                       SelectedItemType.source,
//                     );
//                   },
//                   onDelete: (String id) {
//                     serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);
//                     FusionToast.error(context, message: 'Source "${source.name}" deleted');
//                   },
//                   // onRename: (String id) => print('Rename source $id'),
//                   // onDuplicate: (String id) => print('Duplicate source $id'),
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class SchematicEndpointsWidget extends StatefulWidget {
//   const SchematicEndpointsWidget({super.key});

//   @override
//   State<SchematicEndpointsWidget> createState() => _SchematicEndpointsWidgetState();
// }

// class _SchematicEndpointsWidgetState extends State<SchematicEndpointsWidget> {
//   final TextEditingController searchController = TextEditingController();

//   late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

//   bool get isSearching => searchController.text.isNotEmpty;

//   List<FusionEndpoints> get endpoints {
//     final String query = searchController.text.trim();
//     if (query.isEmpty) return projectViewModel.fusionEndpoints;
//     return projectViewModel.fusionEndpoints.where((FusionEndpoints s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     searchController.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
//       builder: (BuildContext context, ProjectViewModelState state) {
//         final SelectedItem? selectedDevice = projectViewModel.selectedDevice;

//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             const SizedBox(height: 12),
//             Divider(color: context.colorScheme.strokeLight, thickness: 1, height: 0),
//             const SizedBox(height: 8),
//             SectionHeaderWithActions(
//               sectionTitle: "ENDPOINTS",
//               searchController: searchController,
//               onSearchTextChanged: (String value) {
//                 setState(() {
//                   //refresh UI
//                 });
//               },
//             ),
//             const SizedBox(height: 8),
//             Divider(color: context.colorScheme.strokeLight, thickness: 1, height: 0),
//             const SizedBox(height: 12),

//             CommonReorderableListView<FusionEndpoints>(
//               items: endpoints,
//               emptyMessage: isSearching ? "No endpoints match search" : "No endpoints added yet",
//               onReorder: (int oldIndex, int newIndex) {
//                 if (oldIndex < newIndex) newIndex -= 1;
//                 final String hwToMove = endpoints[oldIndex].id;
//                 final String hwAtNewIndex = endpoints[newIndex].id;
//                 projectViewModel.reOrderHardware(hardwareIdToMove: hwToMove, hardwareAtNewIndex: hwAtNewIndex);
//                 projectViewModel.setSelectedDevice(hwToMove, SelectedItemType.endpoint);
//               },
//               proxyDecorator: (Widget child, int index, Animation<double> animation) => child,
//               keyExtractor: (FusionEndpoints endpoint) => endpoint.id,
//               itemBuilder: (BuildContext context, FusionEndpoints endpoint, int index) {
//                 final bool isSelected = selectedDevice?.id == endpoint.id && selectedDevice?.type == SelectedItemType.endpoint;

//                 /// Get zone data from hardwareId
//                 String? getZoneName(String hardwareId) {
//                   final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
//                   String? zoneName = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.name;
//                   zoneName ??= projectViewModel.getSubZoneForHardware(hardwareId: hardwareId)?.name;
//                   return zoneName;
//                 }

//                 Color? getZoneColor(String hardwareId) {
//                   final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
//                   Color? zoneColor = projectViewModel.getZoneForHardware(hardwareId: hardwareId)?.color;
//                   if (zoneColor == null) {
//                     final SubZone? subZone = projectViewModel.getSubZoneForHardware(hardwareId: hardwareId);
//                     if (subZone != null) zoneColor = projectViewModel.getZoneForSubZone(subZoneId: subZone.id)?.color;
//                   }
//                   return zoneColor;
//                 }

//                 String? getEquipmentLocationForHardware(String hardwareId) {
//                   return projectViewModel.getEquipLocationForHardware(hardwareId: hardwareId)?.name;
//                 }

//                 /// Get location name from listeningAreaId
//                 String? getLocationName(String? areaId) {
//                   if (areaId == null) return null;
//                   final ListeningArea area = serviceLocator<ProjectViewModel>().getListeningArea(areaId: areaId);
//                   return area.name;
//                 }

//                 return HardwareItemCard(
//                   index: index,
//                   name: endpoint.name,
//                   // highlightQuery: _endpointsEndpointsSearchQuery,
//                   assetImagePath: endpoint.assetImagePath,
//                   itemId: endpoint.id,
//                   zoneName: getZoneName(endpoint.id),
//                   zoneColor: getZoneColor(endpoint.id),
//                   location: getLocationName(endpoint.locationEntity.listeningAreaId) ?? "Add location",
//                   equipmentLocation: getEquipmentLocationForHardware(endpoint.id),
//                   isSelected: isSelected,
//                   onTap: () {
//                     projectViewModel.setSelectedDevice(
//                       endpoint.id,
//                       SelectedItemType.endpoint,
//                     );
//                   },
//                   onDelete: (String id) {
//                     serviceLocator<ProjectViewModel>().removeHardware(hardwareId: id);
//                     FusionToast.error(context, message: 'Endpoint "${endpoint.name}" deleted');
//                   },
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
