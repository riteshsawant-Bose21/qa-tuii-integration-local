import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../../../../core/service_locator.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';

class BuildingPlan extends StatefulWidget {
  const BuildingPlan({Key? key}) : super(key: key);

  @override
  State<BuildingPlan> createState() => _BuildingPlanState();
}

class _BuildingPlanState extends State<BuildingPlan> {
  int selectedIndex = 0;

  // Sample floor plans data
  final List<Map<String, String>> floorPlans = <Map<String, String>>[
    <String, String>{"code": "FF", "name": "Floor plan 1", "description": "Description"},
    <String, String>{"code": "SF", "name": "Floor plan 2", "description": "Second floor layout"},
    <String, String>{"code": "TF", "name": "Floor plan 3", "description": "Third floor design"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
    <String, String>{"code": "BF", "name": "Floor plan 4", "description": "Basement floor"},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,

        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FusionAppText(text: "Building Plan", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
              GestureDetector(
                onTap: () {
                  final FloorModel model = FloorModel(
                    name: "Floor plan ${serviceLocator<ProjectViewModel>().floors.length + 1}",
                    floorPlan: FloorPlanModel.defaultFloorPlan,
                  );
                  serviceLocator<ProjectViewModel>().addFloor(model);
                },
                child: Icon(
                  Icons.add_sharp,
                  size: 14,
                  color: Theme.of(context).colorScheme.fusionTextViewColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// PopupMenuButton for dropdown functionality
          BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              return PopupMenuButton<int>(
                onSelected: (int index) {
                  setState(() {
                    selectedIndex = index;
                  });
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
                  return List<PopupMenuEntry<int>>.generate(serviceLocator<ProjectViewModel>().floors.length, (int index) {
                    final bool isSelected = index == selectedIndex;
                    serviceLocator<ProjectViewModel>().setCurrentFloorIndex(selectedIndex);
                    return PopupMenuItem<int>(
                      value: index,
                      padding: EdgeInsets.zero,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: isSelected ? Theme.of(context).colorScheme.grey : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.greyDark,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.dividerColor,
                                  width: 1,
                                ),
                              ),
                              child: FusionAppText(
                                text: floorPlans[index]["code"]!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.fusionButtonTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  FusionAppText(
                                    text: serviceLocator<ProjectViewModel>().floors[index].name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context).colorScheme.fusionTextViewColor,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  FusionAppText(
                                    text: serviceLocator<ProjectViewModel>().floors[index].name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.fusionTextViewColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.greyDark,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                      ),
                      child: FusionAppText(
                        text: floorPlans[selectedIndex]["code"]!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.fusionButtonTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(text: floorPlans[selectedIndex]["name"]!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                          const SizedBox(height: 1),
                          FusionAppText(
                            text: floorPlans[selectedIndex]["description"]!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Theme.of(context).colorScheme.fusionTextViewColor,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
