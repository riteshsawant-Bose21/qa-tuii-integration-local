import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/constants/assets_constants.dart';

class BuildingToolbar extends StatefulWidget {
  final Function() onSplSelected;
  final Function() onPanSelected;
  final Function() onMoveSelected;
  final Function() onPencilSelected;
  final Function() onEditFloorPlanSelected;
  final Function() onTrashSelected;
  final Function() onFitSelected;
  final bool isSplSelected;

  const BuildingToolbar({
    super.key,
    required this.onSplSelected,
    required this.onPanSelected,
    required this.onMoveSelected,
    required this.onPencilSelected,
    required this.onEditFloorPlanSelected,
    required this.onTrashSelected,
    required this.onFitSelected,
    required this.isSplSelected,
  });

  @override
  State<BuildingToolbar> createState() => _BuildingToolbarState();
}

class _BuildingToolbarState extends State<BuildingToolbar> {
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
          _buildToolItem(assetIcon: Assets.moveIcon, "Cursor", onTap: widget.onMoveSelected, isSelected: true),
          _buildToolItem(
            assetIcon: Assets.pencilIcon,
            "Pen",
            onTap: widget.onPencilSelected,
          ),
          _buildToolItem(
            assetIcon: Assets.splIcon,
            "Spl",
            onTap: widget.onSplSelected,
            isSelected: widget.isSplSelected,
          ),
          _buildToolItem(
            assetIcon: Assets.tableIcon,
            "floor plan",
            onTap: widget.onEditFloorPlanSelected,
          ),
          _buildToolItem(
            assetIcon: Assets.panIcon,
            "Hand",
            onTap: widget.onPanSelected,
          ),
          _buildToolItem(
            assetIcon: Assets.trashIcon,
            "Delete",
            onTap: widget.onTrashSelected,
          ),
          _buildToolItem(
            icon: Icons.fit_screen_rounded,
            "Fit to screen",
            onTap: widget.onFitSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(String tooltip, {String? assetIcon, IconData? icon, bool isSelected = false, required Function() onTap}) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          onTap();
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
