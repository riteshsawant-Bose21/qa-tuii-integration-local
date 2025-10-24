import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class HardwareItemCard extends StatelessWidget {
  final String name;
  final String assetImagePath;
  final String? itemId;
  final String? location;
  final Zone? zone;
  final bool isHovered;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onHover;
  final VoidCallback? onExit;
  final Function(String)? onDelete;
  final Function(String)? onRename;
  final Function(String)? onDuplicate;

  const HardwareItemCard({
    super.key,
    required this.name,
    required this.assetImagePath,
    this.itemId,
    this.location,
    required this.isHovered,
    required this.isSelected,
    this.onTap,
    this.onHover,
    this.onExit,
    this.onDelete,
    this.onRename,
    this.onDuplicate,
    this.zone,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        onEnter: (_) => onHover?.call(),
        onHover: (_) => onHover?.call(),
        onExit: (_) => onExit?.call(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isHovered ? Colors.white.withOpacity(0.5) : (isSelected ? Colors.transparent : Colors.white),
            border: Border.all(color: isSelected ? Colors.black : Colors.transparent, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// draggable icon
              Icon(
                Icons.drag_handle,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),

              /// device icon, name and location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// device name
                    Row(
                      children: <Widget>[
                        FusionImage.asset(assetImagePath, width: 22, height: 22, fit: BoxFit.contain),
                        const SizedBox(width: 6),
                        Expanded(
                          child: FusionAppText(
                            text: name,
                            maxLine: 1,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    /// device location
                    zone != null
                        ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 7,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: zone?.color ?? Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                // Wrap text in Expanded to prevent overflow
                                child: FusionAppText(
                                  text: zone?.name ?? "",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                                  maxLine: 1, // Prevent text overflow
                                ),
                              ),
                            ],
                          ),
                        )
                        : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHovered ? Colors.white.withOpacity(0.5) : (isSelected ? Colors.transparent : Theme.of(context).colorScheme.white),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Theme.of(context).colorScheme.greyDark, width: 1),
                          ),
                          child: FusionAppText(
                            text: location!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                          ),
                        ),
                  ],
                ),
              ),

              if (isSelected && itemId != null) ...<Widget>[
                const SizedBox(width: 4),
                PopupMenuButton<ZoneMenuAction>(
                  style: const ButtonStyle(
                    overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
                  ),
                  offset: const Offset(0, 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(maxHeight: 550, maxWidth: 140),
                  color: Theme.of(context).colorScheme.white,
                  menuPadding: EdgeInsets.zero,
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<ZoneMenuAction>>[
                        /// --- Delete ---
                        PopupMenuItem<ZoneMenuAction>(
                          height: 26,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          onTap: () {
                            onDelete?.call(itemId!);
                          },
                          child: FusionAppText(
                            text: "Delete",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.fusionTextViewColor,
                            ),
                          ),
                        ),
                      ],
                  child: Icon(
                    Icons.more_vert,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
