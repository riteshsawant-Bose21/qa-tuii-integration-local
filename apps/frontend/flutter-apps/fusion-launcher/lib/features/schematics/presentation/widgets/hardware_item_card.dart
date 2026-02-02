import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class HardwareItemCard extends StatefulWidget {
  final int index;
  final String name;
  final String assetImagePath;
  final String? itemId;
  final String? location;
  final String? equipmentLocation;
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
    required this.index,
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
    this.equipmentLocation,
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
        child: SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.card, "hardware_item_card_${widget.index}"),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: _isHovered ? context.colorScheme.elevation2 : Colors.transparent,
              border: Border.all(color: widget.isSelected ? context.colorScheme.elevation4 : Colors.transparent, width: 1),
              borderRadius: BorderRadius.circular(FusionSizes.borderRadius8),
            ),
            child: Row(
              children: <Widget>[
                /// draggable icon
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.card, "hardware_item_card_drag_handle_${widget.index}"),
                  child: Icon(
                    Icons.drag_indicator,
                    size: FusionSizes.iconSize16,
                    color: context.colorScheme.textPlaceholder,
                  ),
                ),
                const SizedBox(width: 6),

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
                          SemanticHelper.staticText(
                          testId: SemanticHelper.createTestId(SemanticTypes.container, "hardware_name"),child:

                          Expanded(child: _buildHighlightedName()),
                          )
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
                                    width: 8,
                                    height: 8,
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
                                      color: context.colorScheme.primaryBlack,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: SemanticHelper.staticText(
                                    testId: SemanticHelper.createTestId(SemanticTypes.text, "location"), child:

                                    FusionAppText(
                                      text: widget.location ?? "",
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                                      maxLine: 1,
                                      textOverflow: TextOverflow.ellipsis,
                                    ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (((widget.location == null || widget.location == "Add location") && widget.zoneName == null) && widget.equipmentLocation != null)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: context.colorScheme.elevation2,
                              width: 1,
                            ),
                          ),
                          child:
                          SemanticHelper.staticText(
                          testId: SemanticHelper.createTestId(SemanticTypes.text, "location"),child:
                            FusionAppText(
                            text: widget.equipmentLocation!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                          ),
                          ),
                        )
                      else
                        SemanticHelper.button(
                          testId: SemanticHelper.createTestId(SemanticTypes.button, "hardware_item_card_add_location_${widget.index}"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isHovered ? Colors.white.withOpacity(0.5) : (widget.isSelected ? Colors.transparent : context.colorScheme.primaryWhite),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: context.colorScheme.primaryBlack,
                                width: 1,
                              ),
                            ),
                            child: FusionAppText(
                              text: "Add location",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                            ),
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
                      color: context.colorScheme.elevation1,
                      menuPadding: EdgeInsets.zero,
                      tooltip: "",
                      borderRadius: BorderRadius.circular(FusionSizes.borderRadius12),
                      position: PopupMenuPosition.under,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                        side: BorderSide(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<ZoneMenuAction>>[
                          PopupMenuItem<ZoneMenuAction>(
                            height: 26,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            onTap: () {
                              widget.onDelete?.call(widget.itemId!);
                            },
                            child: FusionAppText(
                              text: "Delete",
                              lineHeight: FusionSizes.lineHeight16,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: FusionSizes.fontSize12,
                                color: context.colorScheme.textPrimary,
                              ),
                            ),
                          ),
                        ];
                      },
                      child: SemanticHelper.button(
                        testId: SemanticHelper.createTestId(SemanticTypes.button, "hardware_item_card_more_options_${widget.index}"),
                        child: Icon(
                          Icons.more_vert,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
