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

  @override
  void initState() {
    super.initState();
    _sidebarWidth = widget.initialWidth;
    _sectionStates = widget.sections.map((FusionResizableSidebarSection s) => _SectionState(height: s.initialHeight, isExpanded: s.initiallyExpanded)).toList();
  }

  void _onSidebarDragUpdate(DragUpdateDetails details) {
    setState(() => _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(widget.minWidth, widget.maxWidth));
  }

  void _onSectionDividerDrag(int index, DragUpdateDetails details) {
    setState(() {
      final double dy = details.delta.dy;
      const double minHeight = 60.0;
      const double maxHeight = 600.0;
      final double newHeight = (_sectionStates[index].height + dy).clamp(minHeight, maxHeight);
      _sectionStates[index] = _sectionStates[index].copyWith(height: newHeight);
    });
  }

  void _toggleSection(int index) {
    setState(() => _sectionStates[index] = _sectionStates[index].copyWith(isExpanded: !_sectionStates[index].isExpanded));
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
    final List<int> scrollableIndices = [];
    final List<int> stickyTopIndices = [];
    final List<int> stickyBottomIndices = [];

    for (int i = 0; i < widget.sections.length; i++) {
      if (widget.sections[i].stickToTop) {
        stickyTopIndices.add(i);
      } else if (widget.sections[i].stickToBottom) {
        stickyBottomIndices.add(i);
      } else {
        scrollableIndices.add(i);
      }
    }

    return Column(
      children: [
        // Sticky sections pinned at top, always visible
        if (stickyTopIndices.isNotEmpty) ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...stickyTopIndices.map((int index) {
                return _SectionWidget(
                  section: widget.sections[index],
                  state: _sectionStates[index],
                  onToggle: () => _toggleSection(index),
                  onDividerDrag: null, // sticky sections don't need dividers
                );
              }),

              Divider(height: 1, color: context.colorScheme.strokeLight),
            ],
          ),
        ],

        // Scrollable sections fill available space
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            itemCount: scrollableIndices.length,
            itemBuilder: (BuildContext context, int i) {
              final int index = scrollableIndices[i];
              return _SectionWidget(
                section: widget.sections[index],
                state: _sectionStates[index],
                onToggle: () => _toggleSection(index),
                onDividerDrag: i < scrollableIndices.length - 1 ? (DragUpdateDetails d) => _onSectionDividerDrag(index, d) : null,
              );
            },
          ),
        ),

        // Sticky sections pinned at bottom, always visible
        if (stickyBottomIndices.isNotEmpty) ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(height: 1, color: context.colorScheme.strokeLight),

              ...stickyBottomIndices.map((int index) {
                return _SectionWidget(
                  section: widget.sections[index],
                  state: _sectionStates[index],
                  onToggle: () => _toggleSection(index),
                  onDividerDrag: null,
                );
              }),
            ],
          ),
        ],
      ],
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
          // Section header
          MouseRegion(
            cursor: widget.section.enableExpandCollapse ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: widget.section.enableExpandCollapse ? widget.onToggle : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: <Widget>[
                    // Expand/collapse chevron
                    if (widget.section.enableExpandCollapse) ...[
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
                    Expanded(child: widget.section.headerBuilder(context)),
                  ],
                ),
              ),
            ),
          ),

          // Animated content
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1,
            child: SizedBox(
              height: widget.state.height,
              child: widget.section.childBuilder(context),
            ),
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
        // Transparent 12px tall hit area so drag is easy to grab
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
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

class FusionResizableSidebarSection {
  final String sementicId;
  final bool initiallyExpanded;
  final double initialHeight;
  final bool enableExpandCollapse;
  final Widget Function(BuildContext context) headerBuilder;
  final Widget Function(BuildContext context) childBuilder;
  final bool stickToBottom;
  final bool stickToTop;

  FusionResizableSidebarSection({
    required this.sementicId,
    this.initiallyExpanded = true,
    this.enableExpandCollapse = true,
    required this.headerBuilder,
    required this.childBuilder,
    this.initialHeight = 200,
    this.stickToBottom = false,
    this.stickToTop = false,
  });
}
