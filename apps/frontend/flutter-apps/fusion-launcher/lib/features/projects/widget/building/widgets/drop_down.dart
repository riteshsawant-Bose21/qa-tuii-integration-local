import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BuildingPageDropDown<T> extends StatefulWidget {
  final T? value;
  final String? hintText;
  final List<T> items;
  final ValueChanged<T> onSelect;
  final Widget Function(T option) labelBuilder;
  final Widget Function(T option)? valueBuilder;

  const BuildingPageDropDown({
    super.key,
    this.value,
    this.hintText,
    required this.items,
    required this.onSelect,
    required this.labelBuilder,
    this.valueBuilder,
  });

  @override
  State<BuildingPageDropDown<T>> createState() => _BuildingPageDropDownState<T>();
}

class _BuildingPageDropDownState<T> extends State<BuildingPageDropDown<T>> {
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
    final GlobalKey<State<StatefulWidget>> childKey = GlobalKey();

    return FusionNeumorphicDropdown<T>(
      // color: context.colorScheme.elevation2,
      // shadowColor: Colors.transparent,
      // position: PopupMenuPosition.under,
      // tooltip: '',
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(8),
      //   side: BorderSide(color: context.colorScheme.strokeLight, width: 1),
      // ),
      // offset: const Offset(0, 10),
      // padding: EdgeInsets.zero,
      // menuPadding: EdgeInsets.zero,
      // clipBehavior: Clip.none,
      items: widget.items,
      onChanged: widget.onSelect,
      // popupOffset: const Offset(0, 10),
      itemBuilder: (BuildContext context, T option) => widget.valueBuilder != null ? widget.valueBuilder!(option) : widget.labelBuilder(option),
      // itemBuilder: (BuildContext context) {
      //   return <PopupMenuEntry<String>>[
      //     PopupMenuItem<String>(
      //       enabled: false,
      //       height: 50,
      //       padding: const EdgeInsets.all(8).copyWith(right: 0),
      //       child: Builder(
      //         builder: (BuildContext context) {
      //           if (widget.items.isEmpty) {
      //             return Padding(
      //               padding: const EdgeInsets.all(8.0),
      //               child: FusionAppText(
      //                 text: "Empty items",
      //                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
      //                   color: context.colorScheme.onSurface.withValues(alpha: 0.5),
      //                 ),
      //               ),
      //             );
      //           }

      //           return SizedBox(
      //             width: (childKey.currentContext?.findRenderObject() as RenderBox?)?.size.width, // Match trigger width
      //             child: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               mainAxisSize: MainAxisSize.min,
      //               children: <Widget>[
      //                 ...widget.items.map(
      //                   (T value) => MouseRegion(
      //                     cursor: SystemMouseCursors.click,
      //                     child: GestureDetector(
      //                       onTap: () {
      //                         widget.onSelect(value);
      //                         Navigator.of(context).pop();
      //                       },
      //                       behavior: HitTestBehavior.translucent,
      //                       child: Container(
      //                         width: double.infinity,
      //                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      //                         child: widget.valueBuilder != null ? widget.valueBuilder!(value) : widget.labelBuilder(value),
      //                       ),
      //                     ),
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           );
      //         },
      //       ),
      //     ),
      //   ];
      // },
      child: FusionContainer(
        borderRadius: 8,
        raised: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: Builder(
                  builder: (BuildContext context) {
                    if (widget.value != null) {
                      return widget.labelBuilder(widget.value as T);
                    } else {
                      return FusionAppText(
                        text: widget.hintText ?? 'Select',
                        maxLine: 1,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(
                          color: context.colorScheme.onSurface.withValues(
                            alpha: widget.value == null ? 0.5 : 1.0,
                          ),
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                LucideIcons.chevronDown200,
                color: context.colorScheme.textPrimary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
      // child: SemanticHelper.container(
      //   testId: SemanticHelper.createTestId(
      //     SemanticTypes.container,
      //     "multi_section_dropdown_${widget.hintText}",
      //   ),
      //   child: Padding(
      //     padding: const EdgeInsets.symmetric(
      //       horizontal: 4.0,
      //     ).copyWith(right: 8),
      //     child: Row(
      //       children: <Widget>[
      //         Expanded(
      //           child: Padding(
      //             padding: const EdgeInsets.symmetric(horizontal: 8.0),
      //             child: Builder(
      //               builder: (BuildContext context) {
      //                 if (widget.value != null) {
      //                   return widget.labelBuilder(widget.value as T);
      //                 } else {
      //                   return FusionAppText(
      //                     text: widget.hintText ?? 'Select',
      //                     maxLine: 1,
      //                     style: Theme.of(
      //                       context,
      //                     ).textTheme.labelLarge?.copyWith(
      //                       color: context.colorScheme.onSurface.withValues(
      //                         alpha: widget.value == null ? 0.5 : 1.0,
      //                       ),
      //                       fontWeight: FontWeight.normal,
      //                       fontSize: 12,
      //                     ),
      //                   );
      //                 }
      //               },
      //             ),
      //           ),
      //         ),
      //         SemanticHelper.container(
      //           testId: SemanticHelper.createTestId(
      //             SemanticTypes.container,
      //             "multi_section_dropdown_${widget.hintText}_arrow",
      //           ),
      //           child: Icon(
      //             Icons.keyboard_arrow_down,
      //             color: Colors.grey[600],
      //             size: 16,
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}

class DropdownSection<T> {
  final String title;
  final List<T> items;
  final bool initiallyExpanded;

  const DropdownSection({
    required this.title,
    required this.items,
    this.initiallyExpanded = true,
  });
}

class MultiSectionDropDown<T> extends StatefulWidget {
  final T? value;
  final String? hintText;
  final List<DropdownSection<T>> sections;
  final ValueChanged<T> onSelect;
  final Widget Function(T option) labelBuilder;

  const MultiSectionDropDown({
    super.key,
    this.value,
    this.hintText,
    required this.sections,
    required this.onSelect,
    required this.labelBuilder,
  });

  @override
  State<MultiSectionDropDown<T>> createState() => _MultiSectionDropDownState<T>();
}

class _MultiSectionDropDownState<T> extends State<MultiSectionDropDown<T>> {
  late Map<int, bool> _expandedSections;

  @override
  void initState() {
    super.initState();
    _expandedSections = <int, bool>{
      for (int i = 0; i < widget.sections.length; i++) i: widget.sections[i].initiallyExpanded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      semanticId: 'multi_section_dropdown_${widget.hintText}',
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          return _buildMenuContent(context, stateSetter);
        },
      ),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Builder(
                  builder: (BuildContext context) {
                    if (widget.value != null) {
                      return widget.labelBuilder(widget.value as T);
                    } else {
                      return FusionAppText(
                        text: widget.hintText ?? 'Select',
                        style: context.textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          color: context.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent(BuildContext context, StateSetter stateSetter) {
    if (widget.sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: FusionAppText(
          text: 'Empty items',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return IntrinsicWidth(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(widget.sections.length, (int index) {
            final DropdownSection<T> section = widget.sections[index];
            final bool isExpanded = _expandedSections[index] ?? false;

            final bool isLast = index == widget.sections.length - 1;

            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      isLast
                          ? BorderSide.none
                          : BorderSide(
                            color: context.colorScheme.onSurface.withOpacity(
                              0.1,
                            ),
                          ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // SECTION HEADER
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() {
                          _expandedSections[index] = !isExpanded;
                        });
                        stateSetter(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 20,
                          children: <Widget>[
                            Expanded(
                              child: FusionAppText(
                                text: section.title.toUpperCase(),
                                style: context.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // SECTION ITEMS
                    if (isExpanded) ...<Widget>[
                      ...section.items.map(
                        (T item) => GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            widget.onSelect(item);
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: widget.labelBuilder(item),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class MultiSectionMultiSelectDropDown<T> extends StatefulWidget {
  final Set<T> selectedValues; // SOURCE OF TRUTH (from parent)
  final String? hintText;
  final List<DropdownSection<T>> sections;
  final ValueChanged<Set<T>> onChanged;
  final Widget Function(T option, bool isSelected) labelBuilder;

  const MultiSectionMultiSelectDropDown({
    super.key,
    required this.selectedValues,
    this.hintText,
    required this.sections,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  State<MultiSectionMultiSelectDropDown<T>> createState() => _MultiSectionMultiSelectDropDownState<T>();
}

class _MultiSectionMultiSelectDropDownState<T> extends State<MultiSectionMultiSelectDropDown<T>> {
  late Map<int, bool> _expandedSections;

  /// TEMP state (popup only)
  late Set<T> _tempSelected;

  @override
  void initState() {
    super.initState();
    _syncTempWithParent();

    _expandedSections = <int, bool>{
      for (int i = 0; i < widget.sections.length; i++) i: widget.sections[i].initiallyExpanded,
    };
  }

  @override
  void didUpdateWidget(covariant MultiSectionMultiSelectDropDown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      _syncTempWithParent();
    }
  }

  void _syncTempWithParent() {
    _tempSelected = Set<T>.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      semanticId: 'multi_section_dropdown_${widget.hintText}',
      onDismiss: () {
        // Discard temp changes if popup closes
        _syncTempWithParent();
      },
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          return _buildMenuContent(context, stateSetter);
        },
      ),
      child: _buildTrigger(context),
    );
  }

  // ---------------------------------------------------------------------------
  // TRIGGER (USES PARENT VALUES ONLY)
  // ---------------------------------------------------------------------------

  Widget _buildTrigger(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: widget.selectedValues.isEmpty ? (widget.hintText ?? 'Select') : '${widget.selectedValues.length} selected',
                style: context.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: widget.selectedValues.isEmpty ? context.colorScheme.onSurface.withValues(alpha: 0.5) : context.colorScheme.onSurface,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MENU CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildMenuContent(BuildContext context, StateSetter stateSetter) {
    if (widget.sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: FusionAppText(
          text: 'Empty items',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return IntrinsicWidth(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ...List<Widget>.generate(widget.sections.length, (int index) {
              final DropdownSection<T> section = widget.sections[index];
              final bool isExpanded = _expandedSections[index] ?? false;
              final bool isLast = index == widget.sections.length - 1;

              return DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom:
                        isLast
                            ? BorderSide.none
                            : BorderSide(
                              color: context.colorScheme.onSurface.withOpacity(
                                0.1,
                              ),
                            ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildSectionHeader(
                        context,
                        index,
                        section.title,
                        isExpanded,
                        stateSetter,
                      ),
                      if (isExpanded)
                        ...section.items.map(
                          (T item) => _buildItem(
                            context,
                            item,
                            stateSetter,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),

            _buildActions(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION HEADER
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(
    BuildContext context,
    int index,
    String title,
    bool isExpanded,
    StateSetter stateSetter,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          _expandedSections[index] = !isExpanded;
        });
        stateSetter(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          spacing: 20,
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: title.toUpperCase(),
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ITEM (TEMP ONLY)
  // ---------------------------------------------------------------------------

  Widget _buildItem(
    BuildContext context,
    T item,
    StateSetter stateSetter,
  ) {
    final bool isSelected = _tempSelected.contains(item);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          isSelected ? _tempSelected.remove(item) : _tempSelected.add(item);
        });
        stateSetter(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: isSelected ? context.colorScheme.primary : context.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Expanded(child: widget.labelBuilder(item, isSelected)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS (ONLY EMIT EVENTS)
  // ---------------------------------------------------------------------------

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            onPressed: () {
              widget.onChanged(<T>{});
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              widget.onChanged(Set<T>.from(_tempSelected));
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class MultiSelectDropDown<T> extends StatefulWidget {
  final Set<T> selectedValues;
  final String? hintText;
  final List<T> items;
  final ValueChanged<Set<T>> onChanged;
  final Widget Function(T option, bool isSelected) labelBuilder;

  const MultiSelectDropDown({
    super.key,
    required this.selectedValues,
    this.hintText,
    required this.items,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  State<MultiSelectDropDown<T>> createState() => _MultiSelectDropDownState<T>();
}

class _MultiSelectDropDownState<T> extends State<MultiSelectDropDown<T>> {
  late Set<T> _tempSelected;

  @override
  void initState() {
    super.initState();
    _syncTempWithParent();
  }

  @override
  void didUpdateWidget(covariant MultiSelectDropDown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      _syncTempWithParent();
    }
  }

  void _syncTempWithParent() {
    _tempSelected = Set<T>.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      semanticId: 'multi_section_dropdown_${widget.hintText}',
      onDismiss: _syncTempWithParent,
      showArrow: false,
      blurAmount: 0,
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          return _buildMenuContent(context, stateSetter);
        },
      ),
      child: _buildTrigger(context),
    );
  }

  // ---------------------------------------------------------------------------
  // TRIGGER (PARENT STATE ONLY)
  // ---------------------------------------------------------------------------

  Widget _buildTrigger(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: widget.selectedValues.isEmpty ? (widget.hintText ?? 'Select') : '${widget.selectedValues.length} selected',
                style: context.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: widget.selectedValues.isEmpty ? context.colorScheme.onSurface.withValues(alpha: 0.5) : context.colorScheme.onSurface,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MENU CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildMenuContent(BuildContext context, StateSetter stateSetter) {
    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: FusionAppText(
          text: 'Empty items',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return IntrinsicWidth(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ...widget.items.map(
              (T item) => _buildItem(context, item, stateSetter),
            ),

            _buildActions(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ITEM (TEMP SELECTION ONLY)
  // ---------------------------------------------------------------------------

  Widget _buildItem(BuildContext context, T item, StateSetter stateSetter) {
    final bool isSelected = _tempSelected.contains(item);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          isSelected ? _tempSelected.remove(item) : _tempSelected.add(item);
        });
        stateSetter(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: <Widget>[
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: isSelected ? context.colorScheme.onSurface : context.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Expanded(child: widget.labelBuilder(item, isSelected)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              widget.onChanged(<T>{});
              Navigator.of(context).pop();
            },
            child: FusionAppText(
              text: 'Clear',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              widget.onChanged(Set<T>.from(_tempSelected));
              Navigator.of(context).pop();
            },
            child: FusionAppText(
              text: 'Done',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
