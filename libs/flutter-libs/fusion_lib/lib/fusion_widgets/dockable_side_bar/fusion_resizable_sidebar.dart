import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionResizableSidebar extends StatefulWidget {
  final List<FusionResizableSidebarSection> sections;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;

  const FusionResizableSidebar({
    super.key,
    required this.sections,
    this.initialWidth = 240,
    this.minWidth = 180,
    this.maxWidth = 480,
  });

  @override
  State<FusionResizableSidebar> createState() => _FusionResizableSidebarState();
}

class _FusionResizableSidebarState extends State<FusionResizableSidebar> {
  late double _sidebarWidth;
  late List<_SectionState> _sectionStates;
  bool _isResizingSidebar = false;
  bool _initialized = false;
  double _availableHeight = 0;

  static const double _collapsedSectionHeight = 44.0;
  static const double _minExpandedHeight = 60.0;
  static const double _dividerHeight = 12.0;

  @override
  void initState() {
    super.initState();
    _sidebarWidth = widget.initialWidth;
    // Initialize with placeholder heights - will be calculated in first build
    _sectionStates = widget.sections.map((FusionResizableSidebarSection s) => _SectionState(height: 0, isExpanded: s.initiallyExpanded)).toList();
  }

  void _initializeSectionHeights(double availableHeight) {
    if (_initialized) return;
    _initialized = true;
    _availableHeight = availableHeight;

    final int expandedCount = _sectionStates.where((_SectionState s) => s.isExpanded).length;
    final int collapsedCount = _sectionStates.length - expandedCount;
    final double dividerTotalHeight = _sectionStates.length > 1 ? (_sectionStates.length - 1) * _dividerHeight : 0.0;

    // Calculate height available for expanded sections
    final double heightForExpanded = availableHeight - (collapsedCount * _collapsedSectionHeight) - dividerTotalHeight;
    final double evenHeight = expandedCount > 0 ? heightForExpanded / expandedCount : 0;

    _sectionStates = _sectionStates.map((_SectionState s) {
      return s.copyWith(height: s.isExpanded ? evenHeight.clamp(_minExpandedHeight, double.infinity) : _collapsedSectionHeight);
    }).toList();
  }

  void _onSidebarDragUpdate(DragUpdateDetails details) {
    setState(() => _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(widget.minWidth, widget.maxWidth));
  }

  void _onSectionDividerDrag(int index, int nextIndex, DragUpdateDetails details) {
    setState(() {
      final double dy = details.delta.dy;

      // Find the expanded section above (at or before index)
      int upperExpandedIndex = -1;
      for (int i = index; i >= 0; i--) {
        if (_sectionStates[i].isExpanded) {
          upperExpandedIndex = i;
          break;
        }
      }

      // Find the expanded section below (at or after nextIndex)
      int lowerExpandedIndex = -1;
      for (int i = nextIndex; i < _sectionStates.length; i++) {
        if (_sectionStates[i].isExpanded) {
          lowerExpandedIndex = i;
          break;
        }
      }

      // Need at least one expanded section on each side to drag
      if (upperExpandedIndex < 0 || lowerExpandedIndex < 0) {
        return;
      }

      final double upperHeight = _sectionStates[upperExpandedIndex].height;
      final double lowerHeight = _sectionStates[lowerExpandedIndex].height;

      // Calculate new heights
      double newUpperHeight = upperHeight + dy;
      double newLowerHeight = lowerHeight - dy;

      // Clamp to minimum heights
      if (newUpperHeight < _minExpandedHeight) {
        final double diff = _minExpandedHeight - newUpperHeight;
        newUpperHeight = _minExpandedHeight;
        newLowerHeight -= diff;
      }
      if (newLowerHeight < _minExpandedHeight) {
        final double diff = _minExpandedHeight - newLowerHeight;
        newLowerHeight = _minExpandedHeight;
        newUpperHeight -= diff;
      }

      // Final clamp check
      newUpperHeight = newUpperHeight.clamp(_minExpandedHeight, double.infinity);
      newLowerHeight = newLowerHeight.clamp(_minExpandedHeight, double.infinity);

      _sectionStates[upperExpandedIndex] = _sectionStates[upperExpandedIndex].copyWith(height: newUpperHeight);
      _sectionStates[lowerExpandedIndex] = _sectionStates[lowerExpandedIndex].copyWith(height: newLowerHeight);

      // Normalize: give any remaining space to last expanded section
      _normalizeHeights();
    });
  }

  /// Ensure all heights add up to available space, giving extra to last expanded section
  void _normalizeHeights() {
    if (_availableHeight <= 0) return;

    final double dividerTotalHeight = _sectionStates.length > 1 ? (_sectionStates.length - 1) * _dividerHeight : 0.0;

    // Calculate current total and find last expanded
    double totalUsedHeight = dividerTotalHeight;
    int lastExpandedIndex = -1;

    for (int i = 0; i < _sectionStates.length; i++) {
      if (_sectionStates[i].isExpanded) {
        totalUsedHeight += _sectionStates[i].height;
        lastExpandedIndex = i;
      } else {
        totalUsedHeight += _collapsedSectionHeight;
      }
    }

    // Adjust last expanded section to fill remaining space
    if (lastExpandedIndex >= 0) {
      final double difference = _availableHeight - totalUsedHeight;
      if (difference.abs() > 0.5) {
        // Only adjust if significant difference
        final double newHeight = _sectionStates[lastExpandedIndex].height + difference;
        if (newHeight >= _minExpandedHeight) {
          _sectionStates[lastExpandedIndex] = _sectionStates[lastExpandedIndex].copyWith(height: newHeight);
        }
      }
    }
  }

  void _toggleSection(int index) {
    setState(() {
      final bool wasExpanded = _sectionStates[index].isExpanded;
      final bool willExpand = !wasExpanded;

      if (willExpand) {
        // Expanding: redistribute space from other expanded sections
        final int currentExpandedCount = _sectionStates.where((_SectionState s) => s.isExpanded).length;
        if (currentExpandedCount > 0) {
          // Calculate total expanded height available
          double totalExpandedHeight = 0;
          for (int i = 0; i < _sectionStates.length; i++) {
            if (_sectionStates[i].isExpanded) {
              totalExpandedHeight += _sectionStates[i].height;
            }
          }
          // Add collapsed section's contribution
          totalExpandedHeight += _collapsedSectionHeight;

          // Distribute evenly among all (including newly expanded)
          final double newHeight = totalExpandedHeight / (currentExpandedCount + 1);
          final double clampedHeight = newHeight.clamp(_minExpandedHeight, double.infinity);

          for (int i = 0; i < _sectionStates.length; i++) {
            if (i == index) {
              _sectionStates[i] = _sectionStates[i].copyWith(height: clampedHeight, isExpanded: true);
            } else if (_sectionStates[i].isExpanded) {
              _sectionStates[i] = _sectionStates[i].copyWith(height: clampedHeight);
            }
          }
        } else {
          // No other expanded sections, give all available space
          final double dividerTotalHeight = _sectionStates.length > 1 ? (_sectionStates.length - 1) * _dividerHeight : 0.0;
          final int collapsedCount = _sectionStates.length - 1; // All others are collapsed
          final double heightForExpanded = _availableHeight - (collapsedCount * _collapsedSectionHeight) - dividerTotalHeight;
          _sectionStates[index] = _sectionStates[index].copyWith(
            height: heightForExpanded.clamp(_minExpandedHeight, double.infinity),
            isExpanded: true,
          );
        }
      } else {
        // Collapsing: redistribute freed space to remaining expanded sections
        final double freedHeight = _sectionStates[index].height - _collapsedSectionHeight;
        final int remainingExpandedCount = _sectionStates.where((_SectionState s) => s.isExpanded).length - 1;

        _sectionStates[index] = _sectionStates[index].copyWith(
          height: _collapsedSectionHeight,
          isExpanded: false,
        );

        if (remainingExpandedCount > 0) {
          final double extraPerSection = freedHeight / remainingExpandedCount;
          for (int i = 0; i < _sectionStates.length; i++) {
            if (i != index && _sectionStates[i].isExpanded) {
              _sectionStates[i] = _sectionStates[i].copyWith(
                height: _sectionStates[i].height + extraPerSection,
              );
            }
          }
        }
      }

      // Ensure heights fill available space
      _normalizeHeights();
    });
  }

  @override
  void didUpdateWidget(covariant FusionResizableSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild section states if sections list changed
    if (oldWidget.sections.length != widget.sections.length) {
      _initialized = false;
      _sectionStates = widget.sections.map((FusionResizableSidebarSection s) => _SectionState(height: 0, isExpanded: s.initiallyExpanded)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _sidebarWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Sidebar body
          _buildSections(),

          // Right edge resize handle
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => setState(() => _isResizingSidebar = true),
                onHorizontalDragUpdate: _onSidebarDragUpdate,
                onHorizontalDragEnd: (_) => setState(() => _isResizingSidebar = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4,
                  color: _isResizingSidebar ? context.colorScheme.elevation5 : Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSections() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableHeight = constraints.maxHeight;
        _availableHeight = availableHeight;

        // Initialize section heights evenly on first build
        _initializeSectionHeights(availableHeight);

        // Calculate total used height and find last expanded section
        final double dividerTotalHeight = widget.sections.length > 1 ? (widget.sections.length - 1) * _dividerHeight : 0.0;
        double totalUsedHeight = dividerTotalHeight;
        int lastExpandedIndex = -1;

        for (int i = 0; i < _sectionStates.length; i++) {
          if (_sectionStates[i].isExpanded) {
            totalUsedHeight += _sectionStates[i].height;
            lastExpandedIndex = i;
          } else {
            totalUsedHeight += _collapsedSectionHeight;
          }
        }

        // Calculate extra space to give to last expanded section
        final double extraSpace = (availableHeight - totalUsedHeight).clamp(0.0, double.infinity);

        final List<Widget> sectionWidgets = [];

        for (int i = 0; i < widget.sections.length; i++) {
          final bool isLast = i == widget.sections.length - 1;
          final bool isExpanded = _sectionStates[i].isExpanded;
          final int nextIndex = !isLast ? i + 1 : -1;

          // Use stored height, add extra space to last expanded section
          double height = isExpanded ? _sectionStates[i].height : _collapsedSectionHeight;
          if (i == lastExpandedIndex && extraSpace > 0) {
            height += extraSpace;
          }

          sectionWidgets.add(
            _SectionWidget(
              section: widget.sections[i],
              state: _sectionStates[i].copyWith(height: height),
              onToggle: () => _toggleSection(i),
              onDividerDrag: !isLast ? (DragUpdateDetails d) => _onSectionDividerDrag(i, nextIndex, d) : null,
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: sectionWidgets,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION STATE
// ─────────────────────────────────────────────────────────────────────────────

class _SectionState {
  final double height;
  final bool isExpanded;

  const _SectionState({required this.height, required this.isExpanded});

  _SectionState copyWith({double? height, bool? isExpanded}) {
    return _SectionState(
      height: height ?? this.height,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _SectionWidget extends StatefulWidget {
  final FusionResizableSidebarSection section;
  final _SectionState state;
  final VoidCallback onToggle;
  final void Function(DragUpdateDetails)? onDividerDrag;

  const _SectionWidget({
    required this.section,
    required this.state,
    required this.onToggle,
    this.onDividerDrag,
  });

  @override
  State<_SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<_SectionWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnim;
  bool _isDividerHovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: widget.state.isExpanded ? 1.0 : 0.0);
    _expandAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_SectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isExpanded != oldWidget.state.isExpanded) {
      if (widget.state.isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpanded = widget.state.isExpanded;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "resizable_section_${widget.section.sementicId}"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // User's custom builder with all necessary params
          SizedBox(
            height: widget.state.height,
            child: widget.section.builder(context, isExpanded, widget.onToggle, _expandAnim),
          ),

          // Draggable divider between sections
          if (widget.onDividerDrag != null) _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      onEnter: (_) => setState(() => _isDividerHovered = true),
      onExit: (_) => setState(() => _isDividerHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: widget.onDividerDrag,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: _isDividerHovered ? 6 : 1,
            decoration: BoxDecoration(
              color: context.colorScheme.strokeLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR SECTION CONFIG
// ─────────────────────────────────────────────────────────────────────────────

class FusionResizableSidebarSection {
  final String sementicId;
  final bool initiallyExpanded;
  final bool enableExpandCollapse;
  final bool stickToBottom;
  final bool stickToTop;
  final Widget Function(BuildContext context, bool isExpanded, VoidCallback toggleExpand, Animation<double> expandAnimation) builder;

  FusionResizableSidebarSection({
    required this.sementicId,
    required this.builder,
    this.initiallyExpanded = true,
    this.enableExpandCollapse = true,
    this.stickToBottom = false,
    this.stickToTop = false,
  });
}

class FusionSidebarSectionHeader extends StatelessWidget {
  /// The title text displayed in the header
  final String title;

  /// Current expansion state
  final bool isExpanded;

  /// Callback when header is tapped (typically toggleExpand)
  final VoidCallback? onTap;

  /// Whether to show the expand/collapse chevron icon
  final bool showChevron;

  /// Optional widget displayed at the end of the header (e.g., action buttons)
  final Widget? trailing;

  /// Header height (default: 44)
  final double height;

  /// Horizontal padding
  final EdgeInsetsGeometry padding;

  const FusionSidebarSectionHeader({
    super.key,
    this.title = '',
    required this.isExpanded,
    this.onTap,
    this.showChevron = true,
    this.trailing,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          padding: padding,
          child: Row(
            children: <Widget>[
              // Expand/collapse chevron
              if (showChevron) ...[
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.25,
                  duration: const Duration(milliseconds: 180),
                  child: FusionSvgIcon(
                    icon: "packages/fusion_lib/lib/assets/svgs/expand_up.svg",
                    size: 10,
                    color: context.colorScheme.iconDefault,
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Title
              Expanded(
                child: FusionAppText(
                  text: title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),

              // Trailing widget (action buttons, etc.)
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
