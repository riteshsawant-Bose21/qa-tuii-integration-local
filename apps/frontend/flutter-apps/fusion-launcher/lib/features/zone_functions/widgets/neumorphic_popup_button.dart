import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

List<BoxShadow> getNeumorphismBoxShadows({bool inner = false, Color? color}) {
  color ??= const Color(0xFFF5F5F5);
  return <BoxShadow>[
    if (inner) ...<BoxShadow>[
      const BoxShadow(color: Colors.black12, blurRadius: 0),
      // const BoxShadow(color: Colors.white, spreadRadius: -2, offset: Offset(2, 2)),
      BoxShadow(color: color, blurRadius: 4, offset: const Offset(3, 3)),
    ] else ...<BoxShadow>[
      const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(2, 2)),
      const BoxShadow(color: Colors.white, blurRadius: 2, offset: Offset(-2, -2)),
      BoxShadow(color: color),
    ],
  ];
}

class NeumorphicPopupButton extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final List<String> options;
  final ValueChanged<String> onSelect;
  final double borderRadius;

  const NeumorphicPopupButton({
    super.key,
    this.controller,
    this.hintText,
    this.height,
    this.width,
    this.backgroundColor,
    this.options = const <String>[],
    required this.onSelect,
    this.borderRadius = 8,
  });

  @override
  State<NeumorphicPopupButton> createState() => _NeumorphicPopupButtonState();
}

class _NeumorphicPopupButtonState extends State<NeumorphicPopupButton> {
  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: FusionContainer(
        width: widget.width,
        height: widget.height ?? 32,
        alignment: Alignment.center,
        color: context.colorScheme.elevation2,
        borderRadius: widget.borderRadius,
        child: Row(
          children: <Widget>[
            Expanded(
              child: SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, "mix_scenes_textfield"),
                child: Center(
                  child: TextField(
                    controller: widget.controller,
                    textAlign: TextAlign.center,
                    focusNode: _focusNode,
                    style: Theme.of(context).textTheme.labelLarge,
                    decoration: InputDecoration(
                      fillColor: widget.backgroundColor ?? context.colorScheme.elevation1,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hoverColor: Colors.transparent,
                      hintText: widget.hintText ?? 'Scene name',
                      hintStyle: context.textTheme.labelMedium?.copyWith(color: context.colorScheme.iconDisabled),
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.all(0),
                    ),
                  ),
                ),
              ),
            ),
            VerticalDivider(color: context.colorScheme.strokeLight, thickness: 1, width: 1),
            Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: context.colorScheme.elevation1,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                ),
                splashColor: Colors.transparent, // Disable ripple
                highlightColor: Colors.transparent, // Disable tap highlight
                hoverColor: Colors.transparent, // Disable hover color
              ),
              child: PopupMenuButton<String>(
                color: context.colorScheme.elevation2,
                shadowColor: Colors.transparent,
                position: PopupMenuPosition.under,
                tooltip: '',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                  side: BorderSide(color: context.colorScheme.strokeLight, width: 1),
                ),
                offset: const Offset(0, 10),
                padding: EdgeInsets.zero,
                menuPadding: EdgeInsets.zero,
                clipBehavior: Clip.none,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      enabled: false,
                      height: 50,
                      padding: const EdgeInsets.all(8).copyWith(right: 0),
                      child: Builder(
                        builder: (BuildContext context) {
                          if (widget.options.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FusionAppText(
                                text: "No scenes saved",
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ...widget.options.map(
                                (String value) => GestureDetector(
                                  onTap: () {
                                    widget.onSelect(value);
                                    Navigator.of(context).pop();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: FusionAppText(
                                      text: value,
                                      style: Theme.of(context).textTheme.labelMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ];
                },
                child: SemanticHelper.button(
                  testId: SemanticHelper.createTestId(SemanticTypes.button, "mix_scenes_dropdown"),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0).copyWith(right: 8),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.colorScheme.iconDefault,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
