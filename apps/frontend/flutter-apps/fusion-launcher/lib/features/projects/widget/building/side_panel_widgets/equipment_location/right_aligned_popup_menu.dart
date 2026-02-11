import 'package:flutter/material.dart';

class RightAlignedPopupMenu extends StatefulWidget {
  const RightAlignedPopupMenu({super.key, required this.child, required this.menuContent});
  final Widget child;
  final Widget menuContent;
  @override
  State<RightAlignedPopupMenu> createState() => _RightAlignedPopupMenuState();
}

class _RightAlignedPopupMenuState extends State<RightAlignedPopupMenu> {
  final GlobalKey _buttonKey = GlobalKey();

  void _showRightMenu() {
    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Calculate the position for the menu to appear to the right of the button.
    // We set `left` to the right edge of the button (position.dx + size.width)
    // and let the `right` constraint handle the width and screen boundaries.
    final RelativeRect menuPosition = RelativeRect.fromLTRB(
      position.dx + size.width + 28, // left: right edge of the button
      position.dy, // top: top edge of the button
      MediaQuery.of(context).size.width - (position.dx + size.width), // right: remaining space to the right
      MediaQuery.of(context).size.height - position.dy, // bottom: remaining space to the bottom
    );

    showMenu(
      context: context,
      color: Colors.transparent,
      position: menuPosition,
      shadowColor: Colors.transparent,

      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      items: <PopupMenuItem<String>>[
        PopupMenuItem<String>(
          enabled: false,
          value: 'item1',
          child: widget.menuContent,
        ),
      ],
      elevation: 8.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: _buttonKey, // Assign the GlobalKey to the anchor widget
      onTap: _showRightMenu,
      child: widget.child,
    );
  }
}
