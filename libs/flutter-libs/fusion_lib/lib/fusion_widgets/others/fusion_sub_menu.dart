import 'package:flutter/material.dart' as material show showMenu;
import 'package:flutter/material.dart';

class FusionSubMenu extends StatefulWidget {
  final Widget child;

  const FusionSubMenu({super.key, required this.child});

  static _FusionSubMenuState of(BuildContext context) {
    final _FusionSubMenuState? state = context.findAncestorStateOfType<_FusionSubMenuState>();
    if (state == null) {
      throw FlutterError('FusionSubMenu.of() called with a context that does not contain a FusionSubMenu.');
    }
    return state;
  }

  @override
  _FusionSubMenuState createState() => _FusionSubMenuState();
}

class _FusionSubMenuState extends State<FusionSubMenu> {
  final GlobalKey _childKey = GlobalKey();

  void showMenu({required Widget content}) {
    final RenderBox renderBox = _childKey.currentContext!.findRenderObject() as RenderBox;
    final Offset childPosition = renderBox.localToGlobal(Offset.zero);
    final Size childSize = renderBox.size;

    final double contentWidth = content is SizedBox ? (content.width ?? 200) : 200;
    final double left = childPosition.dx - contentWidth;
    final double screenWidth = MediaQuery.of(context).size.width;

    final RelativeRect menuPosition = RelativeRect.fromLTRB(
      left,
      childPosition.dy,
      screenWidth,
      MediaQuery.of(context).size.height - childPosition.dy,
    );

    material.showMenu<void>(
      context: context,
      color: Colors.transparent,
      shadowColor: Colors.transparent,
      position: menuPosition,
      constraints: BoxConstraints(
        minHeight: childSize.height,
        maxWidth: screenWidth,
      ),
      menuPadding: EdgeInsets.all(0),
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          value: null,
          child: IntrinsicHeight(
            child: content,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _childKey,
      child: widget.child,
    );
  }
}
