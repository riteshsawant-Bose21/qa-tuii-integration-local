import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../core/models/products_data.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/widgets/horizontal_resizable_container.dart';

import '../widgets/hardware_list_card.dart';
import '../widgets/zone_schematic_card.dart';

class SchematicsPage extends StatefulWidget {
  const SchematicsPage({super.key});

  @override
  SchematicsPageState createState() => SchematicsPageState();
}

class SchematicsPageState extends State<SchematicsPage> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          return Row(
            children: <Widget>[
              Expanded(
                child: Scrollbar(
                  controller: _horizontalController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _horizontalController,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          HorizontalResizableContainer(
                            minWidth: 150,
                            maxWidth: 1000,
                            dragLeft: false,
                            dragRight: true,
                            child: _buildSourcesSection(),
                          ),
                          const SizedBox(width: 16),
                          HorizontalResizableContainer(
                            maxWidth: 1000,
                            dragLeft: false,
                            dragRight: true,
                            child: _buildProcessorsSection(),
                          ),
                          const SizedBox(width: 16),
                          HorizontalResizableContainer(
                            maxWidth: 1000,
                            dragLeft: false,
                            dragRight: true,
                            child: _buildAmplifiersSection(),
                          ),
                          const SizedBox(width: 16),
                          HorizontalResizableContainer(
                            maxWidth: 1000,
                            dragLeft: false,
                            dragRight: true,
                            child: _buildRacksSection(),
                          ),
                          const SizedBox(width: 16),
                          HorizontalResizableContainer(
                            minWidth: 300,
                            maxWidth: 1000,
                            dragLeft: false,
                            dragRight: true,
                            child: _buildZonesSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Container(
              //   width: 310,
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     border: Border(left: BorderSide(color: Colors.grey.shade200, width: 1)),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: <Widget>[
              //       // Header
              //       Container(
              //         width: double.infinity,
              //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              //         decoration: BoxDecoration(
              //           color: Colors.grey.shade50,
              //           borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              //           border: Border(
              //             bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              //           ),
              //         ),
              //         child: Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: <Widget>[
              //             const SizedBox(width: 8),
              //             Icon(Icons.tune, size: 18, color: Colors.grey.shade600),
              //             const SizedBox(width: 8),
              //             Expanded(
              //               child: AnimatedOpacity(
              //                 duration: const Duration(milliseconds: 150),
              //                 opacity: 1.0,
              //                 child: Text(
              //                   "Properties",
              //                   style: TextStyle(
              //                     fontSize: 14,
              //                     fontWeight: FontWeight.w600,
              //                     color: Colors.grey.shade700,
              //                   ),
              //                   overflow: TextOverflow.ellipsis,
              //                   maxLines: 1,
              //                 ),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //
              //       // Body
              //       Expanded(
              //         child: SingleChildScrollView(
              //           padding: const EdgeInsets.all(6),
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: <Widget>[
              //               Align(
              //                 alignment: Alignment.topRight,
              //                 child: SingleChildScrollView(
              //                   child: Column(
              //                     mainAxisAlignment: MainAxisAlignment.start,
              //                     children: <Widget>[
              //                       CostCalculatorScreen(
              //                         speakers: serviceLocator<ProjectViewModel>().speakers,
              //                         sources: serviceLocator<ProjectViewModel>().sources,
              //                         controllers:
              //                             serviceLocator<ProjectViewModel>().genericHardwareComponents
              //                                 .where((GenericHardwareComponent component) => component.type == GenericHardwareComponentType.controller)
              //                                 .toList(),
              //                         racks:
              //                             serviceLocator<ProjectViewModel>().genericHardwareComponents
              //                                 .where((GenericHardwareComponent component) => component.type == GenericHardwareComponentType.rack)
              //                                 .toList(),
              //                         amplifiers: <Amplifier>[],
              //                         fusionDevices: <FusionDevice>[],
              //                         others:
              //                             serviceLocator<ProjectViewModel>().genericHardwareComponents
              //                                 .where(
              //                                   (HardwareComponent component) =>
              //                                       component is GenericHardwareComponent && component.type == GenericHardwareComponentType.other,
              //                                 )
              //                                 .toList(),
              //                       ),
              //
              //                       const SizedBox(
              //                         height: 5,
              //                       ),
              //
              //                       const DevicesCatalogWidget(),
              //                     ],
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    bool showAddButton = true,
    Widget? addButton,
    Function()? onAddTap,
    Function()? onMoreTap,
    bool hasIncomingData = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        border: Border(bottom: BorderSide(color: hasIncomingData ? const Color(0xFF80C7FF) : const Color(0xFFD5D5D5))),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          if (showAddButton)
            Container(
              child:
                  addButton ??
                  InkWell(
                    onTap: onAddTap,
                    child: const Icon(Icons.add, size: 20, color: Colors.black),
                  ),
            ),

          InkWell(
            onTap: onMoreTap,
            child: const Icon(Icons.more_vert, size: 20, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesSection() {
    //get sources form projectManager.hardware componets
    final List<Source> sources = serviceLocator<ProjectViewModel>().sources;

    return DragTarget<DeviceComponent>(
      onAcceptWithDetails: (DragTargetDetails<DeviceComponent> details) {
        final DeviceComponent component = details.data;
        if (component is SourceData) {
          final Source source = Source(
            name: component.name,
            pos: const Offset(0, 0),
            assetImagePath: component.assetPath,
            type: component.type,
            locationEntity: LocationModel(),
            price: component.price,
            sku: component.id,
          );
          serviceLocator<ProjectViewModel>().addHardware(source);
        }
      },
      builder: (BuildContext context, List<DeviceComponent?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && (candidateItems.last is SourceData);

        return Container(
          decoration: ShapeDecoration(
            color: hasIncomingData ? const Color(0xFF80C7FF) : Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: hasIncomingData ? 3 : 1,
                strokeAlign: BorderSide.strokeAlignOutside,
                color: hasIncomingData ? const Color(0xFF80C7FF) : const Color(0xFFD5D5D5),
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSectionHeader(
                'Source(s)',
                hasIncomingData: hasIncomingData,
                addButton: PopupMenuButton<SourceData>(
                  tooltip: 'Add Source',
                  onSelected: (SourceData selectedBlock) {
                    final Source source = Source(
                      name: selectedBlock.name,
                      pos: null,
                      type: selectedBlock.type,
                      assetImagePath: selectedBlock.assetPath,
                      locationEntity: LocationModel(),
                      sku: selectedBlock.id,
                      price: selectedBlock.price,
                    );
                    serviceLocator<ProjectViewModel>().addHardware(source);
                  },
                  color: Colors.white,
                  itemBuilder: (BuildContext context) {
                    return SourceData.demoSources.map((SourceData block) {
                      return PopupMenuItem<SourceData>(
                        value: block,
                        child: Row(
                          children: <Widget>[
                            Image.asset(
                              block.assetPath,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(block.name),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: const IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: null,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 100),
                    color: hasIncomingData ? const Color(0xFF80C7FF) : Colors.white,

                    child:
                        (sources.isEmpty)
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  hasIncomingData ? 'Drop here' : 'No Sources available.',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ),
                            )
                            : HardwareListCard(
                              hardwareComponents: sources,
                              onDelete: (HardwareComponent component) {
                                serviceLocator<ProjectViewModel>().removeHardware(component.id);
                              },
                            ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProcessorsSection() {
    //get processors from projectManager.hardware components
    final List<FusionDevice> processors = serviceLocator<ProjectViewModel>().fusionDevices;

    final List<GenericHardwareComponent> processorComponents =
        processors
            .map(
              (FusionDevice device) => GenericHardwareComponent(
                id: device.id,
                locationEntity: LocationModel(id: device.location),
                name: device.name,
                sku: device.id,
                type: GenericHardwareComponentType.other,
                assetImagePath: "assets/images/processor_img.webp",
                price: 1000,
                pos: const Offset(0, 0),
              ),
            )
            .toList();

    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFD5D5D5)),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(
            'Processor(s)',
            showAddButton: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 100),

                child:
                    processorComponents.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No Processors available.',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : HardwareListCard(
                          componentWidth: 150,
                          componentHeight: 25,
                          hardwareComponents: processorComponents,
                          showAddedBySystem: true,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmplifiersSection() {
    //get amplifiers from projectManager.hardware components
    final List<Amplifier> amplifiers = <Amplifier>[];
    // final List<Amplifier> amplifiers = projectManager.value.amplifiers;

    final List<GenericHardwareComponent> amplifierComponents =
        amplifiers
            .map(
              (Amplifier amplifier) => GenericHardwareComponent(
                id: amplifier.id,
                locationEntity: LocationModel(id: amplifier.id),
                name: amplifier.name,
                sku: amplifier.id,
                type: GenericHardwareComponentType.controller,
                assetImagePath: "assets/images/amplifier_img.webp",
                price: 800,
                pos: const Offset(0, 0),
                hardwareName: amplifier.name,
              ),
            )
            .toList();
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFD5D5D5)),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader('Amplifier(s)', showAddButton: false),
          SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 100),
              child:
                  amplifierComponents.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No amplifiers available.',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : HardwareListCard(
                        componentWidth: 150,
                        componentHeight: 25,
                        hardwareComponents: amplifierComponents,
                        showAddedBySystem: true,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRacksSection() {
    final List<HardwareComponent> racks =
        serviceLocator<ProjectViewModel>().genericHardwareComponents
            .where(
              (HardwareComponent component) => component is GenericHardwareComponent && component.type == GenericHardwareComponentType.rack,
            )
            .toList();

    return DragTarget<DeviceComponent>(
      onAcceptWithDetails: (DragTargetDetails<DeviceComponent> details) {
        final DeviceComponent component = details.data;
        if (component is RackData) {
          final GenericHardwareComponent genericHardwareComponent = GenericHardwareComponent(
            name: component.name,
            pos: Offset.zero,
            type: GenericHardwareComponentType.rack,
            assetImagePath: component.assetPath,
            locationEntity: LocationModel(),
            price: component.price,
          );
          serviceLocator<ProjectViewModel>().addHardware(genericHardwareComponent);
        }
      },
      builder: (BuildContext context, List<DeviceComponent?> candidateItems, List<dynamic> rejectedItems) {
        final bool hasIncomingData = candidateItems.isNotEmpty && (candidateItems.last is RackData);

        return Container(
          decoration: ShapeDecoration(
            color: hasIncomingData ? const Color(0xFF80C7FF) : Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: hasIncomingData ? 3 : 1,
                strokeAlign: BorderSide.strokeAlignOutside,
                color: hasIncomingData ? const Color(0xFF80C7FF) : const Color(0xFFD5D5D5),
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSectionHeader(
                'Rack(s)',
                hasIncomingData: hasIncomingData,
                addButton: PopupMenuButton<RackData>(
                  tooltip: 'Add Racks',
                  onSelected: (RackData rackData) {
                    final GenericHardwareComponent rack = GenericHardwareComponent(
                      name: rackData.name,
                      pos: const Offset(0, 0),
                      type: GenericHardwareComponentType.rack,
                      assetImagePath: rackData.assetPath,
                      locationEntity: LocationModel(),
                      sku: rackData.name,
                      price: rackData.price,
                    );
                    serviceLocator<ProjectViewModel>().addHardware(rack);
                  },
                  color: Colors.white,
                  itemBuilder: (BuildContext context) {
                    return RackData.demoRacks.map((RackData block) {
                      return PopupMenuItem<RackData>(
                        value: block,
                        child: Row(
                          children: <Widget>[
                            Image.asset(
                              block.assetPath,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(block.name),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: const IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: null,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 100),

                    child:
                        racks.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  hasIncomingData ? 'Drop Here' : 'No Racks available.',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                            : HardwareListCard(
                              componentHeight: 70,
                              componentWidth: 80,
                              hardwareComponents: racks,
                              onDelete: (HardwareComponent component) {
                                serviceLocator<ProjectViewModel>().removeHardware(component.id);
                              },
                            ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZonesSection() {
    final List<HardwareComponent> speakersAndControllers = serviceLocator<ProjectViewModel>().hardwareComponents;

    final List<Zone> zones = serviceLocator<ProjectViewModel>().zones;

    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFD5D5D5)),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(
            'Zone(s)',
            onAddTap: () {
              serviceLocator<ProjectViewModel>().addZone(
                Zone(
                  id: "zone${DateTime.now().millisecondsSinceEpoch.toString()}",
                  name: 'Zone ${serviceLocator<ProjectViewModel>().zones.length + 1}',
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  if (zones.isEmpty)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 100),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No zones added.',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                  for (Zone zone in zones) ...<Widget>[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: ZoneSchematicCard(
                        zone: zone,
                        hardwareComponents:
                            speakersAndControllers.where((HardwareComponent component) {
                              if (component is Speaker) {
                                return component.locationEntity.zoneId == zone.id;
                              } else if (component is GenericHardwareComponent && component.type == GenericHardwareComponentType.controller) {
                                return component.locationEntity.zoneId == zone.id;
                              }
                              return false;
                            }).toList(),
                        onSpeakerAdded: (SpeakerData speakerData) {
                          final Speaker cs = Speaker(
                            name: speakerData.name,
                            speakerSKU: speakerData.sku,
                            gain:
                                speakerData.sku == "MSA12X"
                                    ? 50.0
                                    : speakerData.sku == "CO-12 H120"
                                    ? 10.0
                                    : 0.0,
                            pos: const Offset(0, 0),
                            rotation: 0.0,
                            assetImagePath: speakerData.assetPath,
                            type: speakerData.type,
                            locationEntity: LocationModel(zoneId: zone.id),
                            price: speakerData.price,
                          );
                          serviceLocator<ProjectViewModel>().addHardware(cs);
                        },
                        onControllerAdded: (ControllerData controllerData) {
                          final GenericHardwareComponent controller = GenericHardwareComponent(
                            name: controllerData.name,
                            pos: Offset.zero,
                            type: GenericHardwareComponentType.controller,
                            assetImagePath: controllerData.assetPath,
                            locationEntity: LocationModel(zoneId: zone.id),
                            price: controllerData.price,
                            hardwareName: controllerData.name,
                            sku: controllerData.sku,
                          );

                          serviceLocator<ProjectViewModel>().addHardware(controller);
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
