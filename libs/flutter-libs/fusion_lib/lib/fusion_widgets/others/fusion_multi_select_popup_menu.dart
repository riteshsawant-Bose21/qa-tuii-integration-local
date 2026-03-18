import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A multi-select popup menu widget that allows selecting multiple items
/// with checkboxes and a save button.
class FusionMultiSelectPopupMenu<T> extends StatefulWidget {
  const FusionMultiSelectPopupMenu({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onSave,
    required this.child,
    this.itemBuilder,
    this.itemLabelBuilder,
    this.matchChildWidth = true,
    this.tooltip,
    this.popupOffset = const Offset(0, 6),
    this.semanticsId,
    this.saveButtonLabel = 'Save',
    this.maxHeight = 280,
  });

  /// List of all available items
  final List<T> items;

  /// Currently selected items
  final Set<T> selectedItems;

  /// Callback when save button is pressed with selected items
  final ValueChanged<Set<T>> onSave;

  /// Child widget that triggers the popup
  final Widget child;

  /// Custom item builder for each item in the list
  final Widget Function(BuildContext context, T item, bool isSelected)? itemBuilder;

  /// Function to get the label for an item
  final String Function(T item)? itemLabelBuilder;

  /// Whether to match the popup width with child width
  final bool matchChildWidth;

  /// Tooltip for the button
  final String? tooltip;

  /// Offset for the popup position
  final Offset popupOffset;

  /// Semantic ID for accessibility
  final String? semanticsId;

  /// Label for the save button
  final String saveButtonLabel;

  /// Maximum height of the popup
  final double maxHeight;

  @override
  State<FusionMultiSelectPopupMenu<T>> createState() => _FusionMultiSelectPopupMenuState<T>();
}

class _FusionMultiSelectPopupMenuState<T> extends State<FusionMultiSelectPopupMenu<T>> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late Set<T> _tempSelectedItems;

  @override
  void initState() {
    super.initState();
    _tempSelectedItems = Set<T>.from(widget.selectedItems);
  }

  @override
  void didUpdateWidget(covariant FusionMultiSelectPopupMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_overlayEntry == null) {
      _tempSelectedItems = Set<T>.from(widget.selectedItems);
    }
  }

  void _toggleItem(T item) {
    setState(() {
      if (_tempSelectedItems.contains(item)) {
        _tempSelectedItems.remove(item);
      } else {
        _tempSelectedItems.add(item);
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showDropdown() {
    _tempSelectedItems = Set<T>.from(widget.selectedItems);

    final RenderBox box = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    final String semanticId =
        widget.semanticsId ??
        SemanticHelper.createTestId(
          SemanticTypes.dropdown,
          widget.tooltip ?? 'multi_select_popup_menu',
        );

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Stack(
        children: <Widget>[
          // Dismiss layer
          GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          // Dropdown content
          Positioned(
            left: offset.dx + widget.popupOffset.dx,
            top: offset.dy + size.height + widget.popupOffset.dy,
            width: widget.matchChildWidth ? size.width : null,
            child: Material(
              color: Colors.transparent,
              child: SemanticHelper.dropdown(
                testId: '${semanticId}_container',
                value: widget.tooltip,
                child: Container(
                  constraints: BoxConstraints(maxHeight: widget.maxHeight),
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colorScheme.strokeLight),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Items list
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: widget.items.length,
                          itemBuilder: (BuildContext context, int index) {
                            final T item = widget.items[index];
                            final bool isSelected = _tempSelectedItems.contains(item);
                            final String itemSemanticId = '${semanticId}_item_$index';

                            return SemanticHelper.button(
                              testId: itemSemanticId,
                              child: InkWell(
                                onTap: () => _toggleItem(item),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: widget.itemBuilder != null
                                      ? widget.itemBuilder!(context, item, isSelected)
                                      : Row(
                                          children: <Widget>[
                                            FusionCheckbox(
                                              value: isSelected,
                                              semanticId: '${itemSemanticId}_checkbox',
                                              onChanged: () => _toggleItem(item),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: FusionAppText(
                                                text: widget.itemLabelBuilder != null ? widget.itemLabelBuilder!(item) : item.toString(),
                                                style: context.textTheme.bodySmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Divider
                      Divider(height: 1, color: context.colorScheme.strokeLight),
                      // Save button
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: double.infinity,
                          child: FusionPrimaryButton(
                            label: widget.saveButtonLabel,
                            accessLabel: '${semanticId}_save_button',
                            height: 32,
                            onTap: () {
                              widget.onSave(_tempSelectedItems);
                              _closeDropdown();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String semanticId =
        widget.semanticsId ??
        SemanticHelper.createTestId(
          SemanticTypes.dropdown,
          widget.tooltip ?? 'multi_select_popup_menu',
        );

    return SemanticHelper.button(
      testId: semanticId,
      child: GestureDetector(
        key: _buttonKey,
        onTap: widget.items.isEmpty ? null : _showDropdown,
        child: widget.child,
      ),
    );
  }
}
