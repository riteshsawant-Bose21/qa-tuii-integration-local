import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter, FilteringTextInputFormatter;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SchematicProperties extends StatefulWidget {
  const SchematicProperties({super.key});

  @override
  SchematicPropertiesState createState() => SchematicPropertiesState();
}

class SchematicPropertiesState extends State<SchematicProperties> {
  final ExpansibleController viewMoreExpansibleController = ExpansibleController();
  final TextEditingController speakerQtyController = TextEditingController(text: "1"); // default value 1
  final TextEditingController propertyModelNameController = TextEditingController(text: "1"); // default value 1

  int get speakerQty => int.tryParse(speakerQtyController.text) ?? 1;
  void speakerQtyModify(int value, bool increment) {
    setState(() {
      int newValue = increment ? speakerQty + 1 : speakerQty - 1;
      if (newValue < 1) newValue = 1; // prevent negative values and zero
      speakerQtyController.text = newValue.toString();
    });
  }

  @override
  void dispose() {
    viewMoreExpansibleController.dispose();
    speakerQtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SelectedItem? selectedItem = context.watch<ProjectViewModel>().selectedDevice;

    if (selectedItem?.id == null || selectedItem?.type == null) return const SizedBox.shrink();

    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();

    late final HardwareComponent? selectedDevice;

    String? assetImagePath;
    if (selectedItem!.type == SelectedItemType.circuit) {
      final List<HardwareComponent> hardwares = projectViewModel.getHardwareForCircuit(circuitId: selectedItem.id);
      if (hardwares.isEmpty) return const SizedBox.shrink();
      selectedDevice = hardwares.first;
      assetImagePath = selectedDevice.assetImagePath;
    } else {
      selectedDevice = projectViewModel.getHardware(hardwareId: selectedItem.id);
      assetImagePath = selectedDevice?.assetImagePath;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: <Widget>[
          Center(
            child: Builder(
              builder: (BuildContext context) {
                if (assetImagePath == null || assetImagePath.isEmpty) {
                  return const SizedBox(
                    width: 118,
                    height: 118,
                    child: Icon(
                      CupertinoIcons.photo,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                }
                return Image.asset(assetImagePath ?? '', width: 118);
              },
            ),
          ),
          const SizedBox(width: 8),
          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Name',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: propertyModelNameController,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: const InputDecoration.collapsed(hintText: 'Enter model name'),
                ),
              ),
            ],
          ),

          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Model',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: FusionAppText(
                  text: selectedDevice?.name ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),

          if (selectedItem.type == SelectedItemType.circuit) ...<Widget>[
            Row(
              spacing: 3,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: 'Speaker Qty',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Row(
                    spacing: 3,
                    children: <Widget>[
                      GestureDetector(
                        child: const Icon(
                          Icons.remove,
                          size: 17,
                        ),
                        onTap: () => speakerQtyModify(speakerQty, false),
                      ),
                      Flexible(
                        child: Container(
                          width: 36,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: speakerQtyController,
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            onChanged: (String value) {
                              final int modifiedQty = int.tryParse(value) ?? 0;
                              if (modifiedQty == 0) speakerQtyController.text = "1";
                            },
                            style: Theme.of(context).textTheme.bodySmall,
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration.collapsed(hintText: '0'),
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: const Icon(
                          Icons.add,
                          size: 17,
                        ),
                        onTap: () => speakerQtyModify(speakerQty, true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Price',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: FusionAppText(
                  text: '\$100',
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),

          if (!<SelectedItemType>[
            SelectedItemType.processor,
            SelectedItemType.amplifier,
          ].contains(selectedItem.type)) ...<Widget>[
            Row(
              spacing: 3,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: 'Location',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: DropdownButton<ListeningArea>(
                    value: projectViewModel.getAllListeningAreas().firstWhere(
                      (ListeningArea area) => area.id == selectedDevice?.locationEntity.listeningAreaId,
                      orElse: () => projectViewModel.getAllListeningAreas().first,
                    ),
                    underline: const SizedBox.shrink(),
                    padding: const EdgeInsets.only(),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    isDense: true,
                    onChanged: (ListeningArea? v) {
                      final LocationModel newLocation = LocationModel(
                        listeningAreaId: v?.id,
                        floorId: projectViewModel.getFloorForListeningArea(areaId: v?.id ?? '')?.id,
                      );
                      projectViewModel.updateHardwareLocation(
                        hardwareId: selectedDevice!.id,
                        newLocation: newLocation,
                      );
                    },
                    items: <DropdownMenuItem<ListeningArea>>[
                      ...projectViewModel.getAllListeningAreas().map(
                        (ListeningArea area) {
                          final FloorModel? floorName = projectViewModel.getFloorForListeningArea(areaId: area.id);

                          return DropdownMenuItem<ListeningArea>(
                            value: area,
                            child: FusionAppText(
                              text: "${floorName?.name} / ${area.name}",
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          Expansible(
            controller: viewMoreExpansibleController,
            headerBuilder: (BuildContext context, Animation<double> animation) {
              final bool isExpanded = viewMoreExpansibleController.isExpanded;

              return GestureDetector(
                onTap: () {
                  if (viewMoreExpansibleController.isExpanded) {
                    viewMoreExpansibleController.collapse();
                  } else {
                    viewMoreExpansibleController.expand();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isExpanded ? 10.0 : 0.0),
                  child: FusionAppText(
                    text: isExpanded ? 'view less' : 'view more',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF186E79)),
                  ),
                ),
              );
            },
            expansibleBuilder: (BuildContext context, Widget header, Widget body, Animation<double> animation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: body,
                  ),
                  header,
                ],
              );
            },
            bodyBuilder: (BuildContext context, Animation<double> animation) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: <Widget>[
                  Row(
                    spacing: 3,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: 'Serial Number',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: FusionAppText(
                          text: "DG221G28983",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),

                  // Row(
                  //   spacing: 3,
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: <Widget>[
                  //     Expanded(
                  //       child: FusionAppText(
                  //         text: 'MAC Address',
                  //         style: Theme.of(context).textTheme.bodySmall,
                  //       ),
                  //     ),
                  //     Expanded(
                  //       child: FusionAppText(
                  //         text: "00:1A:2B:3C:4D:5E",
                  //         style: Theme.of(context).textTheme.bodySmall,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              );
            },
          ),

          // const SizedBox(height: 5),
          // const SectionHeader(title: 'Settings'),

          // Row(
          //   spacing: 3,
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: <Widget>[
          //     Expanded(
          //       child: FusionAppText(
          //         text: 'Impedance',
          //         style: Theme.of(context).textTheme.bodySmall,
          //       ),
          //     ),
          //     Expanded(
          //       child: DropdownButton<String>(
          //         value: impedance,
          //         underline: const SizedBox.shrink(),
          //         icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          //         isDense: true,
          //         onChanged: (String? v) => setState(() => impedance = v ?? impedance),
          //         isExpanded: true,
          //         items:
          //             <String>['Auto', 'High', 'Low'].map(
          //               (String value) {
          //                 return DropdownMenuItem<String>(
          //                   value: value,
          //                   child: FusionAppText(text: value, style: Theme.of(context).textTheme.bodySmall),
          //                 );
          //               },
          //             ).toList(),
          //       ),
          //     ),
          //   ],
          // ),

          // Row(
          //   spacing: 3,
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: <Widget>[
          //     Expanded(
          //       child: FusionAppText(
          //         text: 'Tap Settings',
          //         style: Theme.of(context).textTheme.bodySmall,
          //       ),
          //     ),
          //     Expanded(
          //       child: DropdownButton<String>(
          //         value: tapSettings,
          //         underline: const SizedBox.shrink(),
          //         padding: const EdgeInsets.only(),
          //         icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          //         isExpanded: true,
          //         isDense: true,
          //         onChanged: (String? v) => setState(() => tapSettings = v ?? tapSettings),
          //         items:
          //             <String>['Tap 1', 'Tap 2', 'Tap 3'].map(
          //               (String value) {
          //                 return DropdownMenuItem<String>(
          //                   value: value,
          //                   child: FusionAppText(text: value, style: Theme.of(context).textTheme.bodySmall),
          //                 );
          //               },
          //             ).toList(),
          //       ),
          //     ),
          //   ],
          // ),

          // const SizedBox(height: 5),
          // const SectionHeader(title: 'Zones & Listening Areas'),

          // Row(
          //   spacing: 3,
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: <Widget>[
          //     Expanded(
          //       child: FusionAppText(
          //         text: 'Zone',
          //         style: Theme.of(context).textTheme.bodySmall,
          //       ),
          //     ),
          //     Expanded(
          //       child: Row(
          //         spacing: 8,
          //         children: <Widget>[
          //           Container(
          //             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          //             decoration: BoxDecoration(
          //               color: const Color(0xFFEFF7F6),
          //               borderRadius: BorderRadius.circular(4),
          //             ),
          //             child: FusionAppText(
          //               text: 'Z1',
          //               style: Theme.of(context).textTheme.bodySmall,
          //             ),
          //           ),
          //           Expanded(
          //             child: FusionAppText(
          //               text: 'Reception',
          //               style: Theme.of(context).textTheme.bodySmall,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black38),
    );
  }
}
