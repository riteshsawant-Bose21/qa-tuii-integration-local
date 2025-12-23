import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class BuildingPageDronDown<T> extends StatefulWidget {
  final T? value;
  final String? hintText;
  final List<T> items;
  final ValueChanged<T> onSelect;
  final Widget Function(T option) labelBuilder;

  const BuildingPageDronDown({
    super.key,
    this.value,
    this.hintText,
    required this.items,
    required this.onSelect,
    required this.labelBuilder,
  });

  @override
  State<BuildingPageDronDown<T>> createState() => _BuildingPageDronDownState<T>();
}

class _BuildingPageDronDownState<T> extends State<BuildingPageDronDown<T>> {
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
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: const PopupMenuThemeData(
            color: Color(0xFFF5F5F5),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          splashColor: Colors.transparent, // Disable ripple
          highlightColor: Colors.transparent, // Disable tap highlight
          hoverColor: Colors.transparent, // Disable hover color
        ),
        child: PopupMenuButton<String>(
          color: context.colorScheme.surfaceContainer,
          shadowColor: Colors.transparent,
          position: PopupMenuPosition.under,
          tooltip: '',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    if (widget.items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FusionAppText(
                          text: "Empty items",
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ...widget.items.map(
                          (T value) => GestureDetector(
                            onTap: () {
                              widget.onSelect(value);
                              Navigator.of(context).pop();
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: widget.labelBuilder(value),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0).copyWith(right: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Builder(
                      builder: (BuildContext context) {
                        if (widget.value != null) {
                          return widget.labelBuilder(widget.value as T);
                        } else {
                          return FusionAppText(
                            text: widget.hintText ?? 'Select',
                            maxLine: 1,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: context.colorScheme.onSurface.withValues(alpha: widget.value == null ? 0.5 : 1.0),
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
