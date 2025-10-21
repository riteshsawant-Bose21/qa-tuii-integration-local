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
                          decoration: BoxDecoration(
                            color: isHovered ? Colors.white.withOpacity(0.5) : (isSelected ? Colors.transparent : Theme.of(context).colorScheme.white),
                            // border: Border.all(color: Theme.of(context).colorScheme.greyDark, width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 8,
                                height: 16, // Add explicit height
                                decoration: BoxDecoration(
                                  color: zone?.color ?? Colors.red, // Use zone color instead of hardcoded red
                                  borderRadius: BorderRadius.circular(2), // Optional: add slight border radius
                                ),
                              ),
                              const SizedBox(width: 4), // Add spacing between color indicator and text
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

              /// kebab menu
              if ((isHovered || isSelected) && itemId != null) ...<Widget>[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.white,
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'rename',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.edit, size: 12),
                              SizedBox(width: 6),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'duplicate',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (String value) {
                    switch (value) {
                      case 'rename':
                        onRename?.call(itemId!);
                        break;
                      case 'duplicate':
                        onDuplicate?.call(itemId!);
                        break;
                      case 'delete':
                        onDelete?.call(itemId!);
                        break;
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
