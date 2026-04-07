import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FusionKebabPopup extends StatefulWidget {
  const FusionKebabPopup({
    super.key,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.iconSize = 18,
    this.popupOffset = const Offset(0, 4),
    this.semanticsId,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final double iconSize;
  final Offset popupOffset;
  final String? semanticsId;

  @override
  State<FusionKebabPopup> createState() => _FusionKebabPopupState();
}

class _FusionKebabPopupState extends State<FusionKebabPopup> {
  bool _isHovered = false;
  bool _isMenuOpen = false;
  OverlayEntry? _overlayEntry;

  List<_KebabMenuItem> get _menuItems {
    final List<_KebabMenuItem> items = [];
    if (widget.onEdit != null) {
      items.add(
        _KebabMenuItem(
          label: 'Edit',
          icon: "packages/fusion_lib/lib/assets/svgs/edit.svg",
          onTap: widget.onEdit!,
        ),
      );
    }
    if (widget.onDuplicate != null) {
      items.add(
        _KebabMenuItem(
          label: 'Duplicate',
          icon: "packages/fusion_lib/lib/assets/svgs/copy.svg",
          onTap: widget.onDuplicate!,
        ),
      );
    }
    if (widget.onDelete != null) {
      items.add(
        _KebabMenuItem(
          label: 'Delete',
          icon: "packages/fusion_lib/lib/assets/svgs/trash.svg",
          onTap: widget.onDelete!,
        ),
      );
    }
    return items;
  }

  void _showPopup() {
    setState(() => _isMenuOpen = true);

    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    final Size size = button.size;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Stack(
        children: [
          // Dismiss layer
          GestureDetector(
            onTap: _closePopup,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          // Popup
          Positioned(
            left: offset.dx + widget.popupOffset.dx,
            top: offset.dy + size.height + widget.popupOffset.dy,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 10,
                      offset: const Offset(3, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(13, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.21),
                      blurRadius: 24,
                      offset: const Offset(30, 26),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 29,
                      offset: const Offset(54, 47),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.01),
                      blurRadius: 31,
                      offset: const Offset(84, 73),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _menuItems
                      .map(
                        (item) => GestureDetector(
                          onTap: () {
                            _closePopup();
                            item.onTap();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: _KebabMenuItemTile(item: item),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closePopup() {
    _cleanupPopup();
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isMenuOpen = false);
  }

  void _cleanupPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _cleanupPopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_menuItems.isEmpty) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _showPopup(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isMenuOpen
                ? context.colorScheme.elevation3
                : _isHovered
                ? context.colorScheme.elevation2
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            LucideIcons.ellipsisVertical,
            size: widget.iconSize,
            color: _isMenuOpen
                ? context.colorScheme.textPrimary
                : _isHovered
                ? context.colorScheme.textPrimary
                : context.colorScheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _KebabMenuItem {
  const _KebabMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;
}

class _RawKebabPopupItem<T> extends PopupMenuEntry<T> {
  const _RawKebabPopupItem({
    required this.value,
    required this.child,
  });

  final T value;
  final Widget child;

  @override
  double get height => 36;

  @override
  bool represents(T? value) => this.value == value;

  @override
  State<_RawKebabPopupItem<T>> createState() => _RawKebabPopupItemState<T>();
}

class _RawKebabPopupItemState<T> extends State<_RawKebabPopupItem<T>> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(widget.value),
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}

class _KebabMenuItemTile extends StatefulWidget {
  const _KebabMenuItemTile({required this.item});

  final _KebabMenuItem item;

  @override
  State<_KebabMenuItemTile> createState() => _KebabMenuItemTileState();
}

class _KebabMenuItemTileState extends State<_KebabMenuItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: 93,
        height: 24,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _isHovered ? context.colorScheme.elevation2 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          spacing: 4,
          children: [
            FusionIcon.svg(
              widget.item.icon,
              color: context.colorScheme.textPrimary,
            ),
            FusionAppText(text: widget.item.label, style: context.textTheme.l1Regular),
          ],
        ),
      ),
    );
  }
}
