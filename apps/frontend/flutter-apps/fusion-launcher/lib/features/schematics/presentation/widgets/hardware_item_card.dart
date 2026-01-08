import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_utils/app_enums.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class HardwareItemCard extends StatefulWidget {
  final String name;
  final String assetImagePath;
  final String? itemId;
  final String? location;
  final String? zoneName;
  final Color? zoneColor;
  final bool isSelected;
  final VoidCallback? onTap;
  final Function(String)? onDelete;
  final Function(String)? onRename;
  final Function(String)? onDuplicate;
  final String? highlightQuery;

  const HardwareItemCard({
    super.key,
    required this.name,
    required this.assetImagePath,
    this.itemId,
    this.location,
    required this.isSelected,
    this.onTap,
    this.onDelete,
    this.onRename,
    this.onDuplicate,
    this.zoneName,
    this.zoneColor,
    this.highlightQuery,
  });

  @override
  State<HardwareItemCard> createState() => _HardwareItemCardState();
}

class _HardwareItemCardState extends State<HardwareItemCard> {
  bool _isHovered = false;

  /// Builds the device name with highlighted search query matches.
  Widget _buildHighlightedName() {
    final TextStyle baseStyle = Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10);
    final String query = (widget.highlightQuery ?? '').trim();
    if (query.isEmpty) {
      return FusionAppText(
        text: widget.name,
        maxLine: 1,
        style: baseStyle,
      );
    }

    final RegExp reg = RegExp(RegExp.escape(query), caseSensitive: false);
    final List<TextSpan> spans = <TextSpan>[];
    int lastIndex = 0;

    for (final RegExpMatch m in reg.allMatches(widget.name)) {
      if (m.start > lastIndex) {
        spans.add(TextSpan(text: widget.name.substring(lastIndex, m.start), style: baseStyle));
      }
      spans.add(
        TextSpan(
          text: widget.name.substring(m.start, m.end),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w600,
            backgroundColor: Colors.yellow[200],
            color: Colors.black,
          ),
        ),
      );
      lastIndex = m.end;
    }
    if (lastIndex < widget.name.length) {
      spans.add(TextSpan(text: widget.name.substring(lastIndex), style: baseStyle));
    }

    return RichText(
      maxLines: 1,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withOpacity(0.5) : (widget.isSelected ? Colors.transparent : Colors.white),
            border: Border.all(color: widget.isSelected ? Colors.black : Colors.transparent, width: 1),
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
                        FusionImage.asset(
                          widget.assetImagePath,
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: _buildHighlightedName()),
                      ],
                    ),
                    const SizedBox(height: 6),

                    /// device location
                    if (widget.zoneName != null)
                      IntrinsicWidth(
                        child: Tooltip(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          preferBelow: false,
                          verticalOffset: -40,
                          message: serviceLocator<ProjectViewModel>().getFullPathForHardware(hardwareId: widget.itemId ?? ""),
                          waitDuration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: 7,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: widget.zoneColor ?? Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: FusionAppText(
                                    text: widget.zoneName ?? "",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                                    maxLine: 1,
                                    textOverflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (widget.location != null && widget.location != "Add location")
                      IntrinsicWidth(
                        child: Tooltip(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          preferBelow: false,
                          verticalOffset: -40,
                          message: serviceLocator<ProjectViewModel>().getFullPathForHardware(hardwareId: widget.itemId ?? ""),
                          waitDuration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: 7,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.grey,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: FusionAppText(
                                    text: widget.location ?? "",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                                    maxLine: 1,
                                    textOverflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isHovered ? Colors.white.withOpacity(0.5) : (widget.isSelected ? Colors.transparent : Theme.of(context).colorScheme.white),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.greyDark,
                            width: 1,
                          ),
                        ),
                        child: FusionAppText(
                          text: "Add location",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                        ),
                      ),
                  ],
                ),
              ),

              if (widget.isSelected && widget.itemId != null) ...<Widget>[
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: PopupMenuButton<ZoneMenuAction>(
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
                          PopupMenuItem<ZoneMenuAction>(
                            height: 26,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            onTap: () {
                              widget.onDelete?.call(widget.itemId!);
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
