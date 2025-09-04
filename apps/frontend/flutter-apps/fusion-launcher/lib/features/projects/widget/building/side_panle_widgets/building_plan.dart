import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

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
                onTap: () {},
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
          PopupMenuButton<int>(
            onSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            offset: const Offset(50, 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: Theme.of(context).colorScheme.dividerColor),
            ),
            color: Theme.of(context).colorScheme.white,
            elevation: 1,
            itemBuilder: (BuildContext context) {
              return List<PopupMenuEntry<int>>.generate(floorPlans.length, (int index) {
                final bool isSelected = index == selectedIndex;
                return PopupMenuItem<int>(
                  value: index,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.greyDark,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: FusionAppText(
                          text: floorPlans[index]["code"]!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.fusionButtonTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FusionAppText(
                              text: floorPlans[index]["name"]!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                            const SizedBox(height: 1),
                            FusionAppText(
                              text: floorPlans[index]["description"]!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
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
          ),
        ],
      ),
    );
  }
}
