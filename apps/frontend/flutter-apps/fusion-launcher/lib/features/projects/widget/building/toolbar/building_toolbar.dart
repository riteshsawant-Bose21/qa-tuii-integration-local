import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/constants/assets_constants.dart';

class BuildingToolbar extends StatefulWidget {
  const BuildingToolbar({super.key});

  @override
  State<BuildingToolbar> createState() => _BuildingToolbarState();
}

class _BuildingToolbarState extends State<BuildingToolbar> {
  int selectedIndex = 4; // Hand tool is selected by default

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildToolItem(0, assetIcon: Assets.moveIcon, "Cursor"),
          _buildToolItem(1, assetIcon: Assets.pencilIcon, "Pen"),
          _buildToolItem(2, assetIcon: Assets.splIcon, "Delete"),
          _buildToolItem(3, assetIcon: Assets.tableIcon, "Delete"),
          _buildToolItem(4, assetIcon: Assets.panIcon, "Hand"),
          _buildToolItem(5, assetIcon: Assets.trashIcon, "Delete"),
          _buildToolItem(6, icon: Icons.fit_screen_rounded, "Delete"),
        ],
      ),
    );
  }

  Widget _buildToolItem(int index, String tooltip, {String? assetIcon, IconData? icon}) {
    final bool isSelected = selectedIndex == index;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
          // Handle tool selection
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.withAlpha((0.3 * 255).toInt()) : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child:
              icon != null
                  ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      icon,
                      size: 20.0,
                      color: Colors.black54,
                    ),
                  )
                  : Image.asset(
                    assetIcon!,
                    width: 44.0,
                    height: 44.0,
                  ),
        ),
      ),
    );
  }
}
