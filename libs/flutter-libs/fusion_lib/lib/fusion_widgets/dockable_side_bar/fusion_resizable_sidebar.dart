import 'dart:async';

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
  final ScrollController _outerScrollController = ScrollController();

  // Debounce for outer scroll - when active, all scroll goes to outer
  bool _outerScrollActive = false;
  Timer? _outerScrollDebounceTimer;
  static const Duration _outerScrollDebounce = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _sidebarWidth = widget.initialWidth;
    _sectionStates = widget.sections.map((FusionResizableSidebarSection s) => _SectionState(height: s.initialHeight, isExpanded: s.initiallyExpanded)).toList();
  }

  void _onSidebarDragUpdate(DragUpdateDetails details) {
    setState(() => _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(widget.minWidth, widget.maxWidth));
  }

  void _onSectionDividerDrag(int index, int nextIndex, DragUpdateDetails details) {
    setState(() {
      final double dy = details.delta.dy;
      const double minHeight = 60.0;
      const double maxHeight = 600.0;

      // Calculate new heights for both sections
      final double currentHeight = _sectionStates[index].height;
      final double nextHeight = _sectionStates[nextIndex].height;

      final double newCurrentHeight = (currentHeight + dy).clamp(minHeight, maxHeight);
      final double actualDelta = newCurrentHeight - currentHeight;
      final double newNextHeight = (nextHeight - actualDelta).clamp(minHeight, maxHeight);

      _sectionStates[index] = _sectionStates[index].copyWith(height: newCurrentHeight);
      _sectionStates[nextIndex] = _sectionStates[nextIndex].copyWith(height: newNextHeight);
    });
  }

  void _toggleSection(int index) {
    setState(() => _sectionStates[index] = _sectionStates[index].copyWith(isExpanded: !_sectionStates[index].isExpanded));
  }

  void _activateOuterScroll() {
    _outerScrollActive = true;
    _outerScrollDebounceTimer?.cancel();
    _outerScrollDebounceTimer = Timer(_outerScrollDebounce, () {
      _outerScrollActive = false;
    });
  }

  @override
  void dispose() {
    _outerScrollController.dispose();
    _outerScrollDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FusionResizableSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild section states if sections list changed
    if (oldWidget.sections.length != widget.sections.length) {
      _sectionStates = widget.sections
          .map((FusionResizableSidebarSection s) => _SectionState(height: s.initialHeight, isExpanded: s.initiallyExpanded))
          .toList();
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
              ...stickyTopIndices.asMap().entries.map((MapEntry<int, int> entry) {
                final int i = entry.key;
                final int index = entry.value;
                final bool isLast = i == stickyTopIndices.length - 1;
                final int nextIndex = !isLast ? stickyTopIndices[i + 1] : -1;

                return _SectionWidget(
                  section: widget.sections[index],
                  state: _sectionStates[index],
                  onToggle: () => _toggleSection(index),
                  onDividerDrag: !isLast ? (DragUpdateDetails d) => _onSectionDividerDrag(index, nextIndex, d) : null,
                );
              }),

              Divider(height: 1, color: context.colorScheme.strokeLight),
            ],
          ),
        ],

        // Scrollable sections fill available space
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double availableHeight = constraints.maxHeight;

              // Account for divider heights between sections (12px each, except last section has no divider)
              final double dividerTotalHeight = scrollableIndices.length > 1 ? (scrollableIndices.length - 1) * 12.0 : 0.0;

              // Height for collapsed sections (just header area ~ 44px)
              const double collapsedSectionHeight = 44.0;

              // Calculate total height of all sections using their stored heights
              double totalContentHeight = dividerTotalHeight;
              for (final int idx in scrollableIndices) {
                totalContentHeight += _sectionStates[idx].isExpanded ? _sectionStates[idx].height : collapsedSectionHeight;
              }

              final bool needsScroll = totalContentHeight > availableHeight;

              // Calculate extra space to distribute to the last expanded section
              double extraSpace = 0.0;
              if (!needsScroll && scrollableIndices.isNotEmpty) {
                extraSpace = availableHeight - totalContentHeight;
              }

              final List<Widget> sectionWidgets = scrollableIndices.asMap().entries.map((MapEntry<int, int> entry) {
                final int i = entry.key;
                final int index = entry.value;
                final bool isLast = i == scrollableIndices.length - 1;
                final bool isExpanded = _sectionStates[index].isExpanded;
                final int nextIndex = !isLast ? scrollableIndices[i + 1] : -1;

                // Determine height based on expanded state
                double height;
                if (!isExpanded) {
                  height = collapsedSectionHeight;
                } else {
                  height = _sectionStates[index].height;
                  // Give extra space to the last expanded section
                  if (isLast && extraSpace > 0) {
                    height += extraSpace;
                  }
                }

                return _SectionWidget(
                  section: widget.sections[index],
                  state: _sectionStates[index].copyWith(height: height),
                  onToggle: () => _toggleSection(index),
                  onDividerDrag: !isLast ? (DragUpdateDetails d) => _onSectionDividerDrag(index, nextIndex, d) : null,
                );
              }).toList();

              if (needsScroll) {
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    // Simple scroll chaining: when inner reaches boundary, continue with outer
                    if (notification is OverscrollNotification && notification.depth > 0) {
                      if (!_outerScrollController.hasClients) return false;

                      final double overscroll = notification.overscroll;
                      final double currentOffset = _outerScrollController.offset;
                      final double maxOffset = _outerScrollController.position.maxScrollExtent;

                      // Check if outer can scroll in the overscroll direction
                      final bool canScrollUp = overscroll < 0 && currentOffset > 0;
                      final bool canScrollDown = overscroll > 0 && currentOffset < maxOffset;

                      if (canScrollUp || canScrollDown) {
                        final double newOffset = (currentOffset + overscroll * 0.5).clamp(0.0, maxOffset);
                        _outerScrollController.jumpTo(newOffset);
                        _activateOuterScroll();
                        return true;
                      }
                    }

                    // When outer scroll is debounced, intercept inner scroll updates
                    if (_outerScrollActive && notification is ScrollUpdateNotification && notification.depth > 0 && _outerScrollController.hasClients) {
                      final double? delta = notification.scrollDelta;
                      if (delta == null || delta.abs() < 0.1) return false;

                      final double currentOffset = _outerScrollController.offset;
                      final double maxOffset = _outerScrollController.position.maxScrollExtent;

                      // Check if outer can still scroll
                      final bool canScrollUp = delta < 0 && currentOffset > 0;
                      final bool canScrollDown = delta > 0 && currentOffset < maxOffset;

                      if (canScrollUp || canScrollDown) {
                        final double newOffset = (currentOffset + delta).clamp(0.0, maxOffset);
                        _outerScrollController.jumpTo(newOffset);
                        _activateOuterScroll(); // Reset timer
                        return true;
                      } else {
                        // Can't scroll outer anymore, release control back to inner
                        _outerScrollActive = false;
                        _outerScrollDebounceTimer?.cancel();
                      }
                    }

                    return false;
                  },
                  child: ListView(
                    controller: _outerScrollController,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    children: sectionWidgets,
                  ),
                );
              }

              // Clip to prevent minor overflow from rounding errors
              return ClipRect(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: sectionWidgets,
                ),
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

              ...stickyBottomIndices.asMap().entries.map((MapEntry<int, int> entry) {
                final int i = entry.key;
                final int index = entry.value;
                final bool isLast = i == stickyBottomIndices.length - 1;
                final int nextIndex = !isLast ? stickyBottomIndices[i + 1] : -1;

                return _SectionWidget(
                  section: widget.sections[index],
                  state: _sectionStates[index],
                  onToggle: () => _toggleSection(index),
                  onDividerDrag: !isLast ? (DragUpdateDetails d) => _onSectionDividerDrag(index, nextIndex, d) : null,
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
  final double initialHeight;
  final bool enableExpandCollapse;
  final bool stickToBottom;
  final bool stickToTop;
  final Widget Function(BuildContext context, bool isExpanded, VoidCallback toggleExpand, Animation<double> expandAnimation) builder;

  FusionResizableSidebarSection({
    required this.sementicId,
    required this.builder,
    this.initiallyExpanded = true,
    this.enableExpandCollapse = true,
    this.initialHeight = 200,
    this.stickToBottom = false,
    this.stickToTop = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE HEADER WIDGET (Optional helper for users)
// ─────────────────────────────────────────────────────────────────────────────

/// A reusable header widget for sidebar sections.
///
/// Use this inside your [FusionResizableSidebarSection.builder] for quick
/// header implementation with expand/collapse chevron and optional trailing widgets.
///
/// Example:
/// ```dart
/// FusionSidebarSectionHeader(
///   title: 'FLOORS',
///   isExpanded: isExpanded,
///   onTap: toggleExpand,
///   showChevron: true,
///   trailing: GestureDetector(
///     onTap: () => addFloor(),
///     child: Icon(Icons.add),
///   ),
/// )
/// ```
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

  /// Custom title widget (overrides [title] if provided)
  final Widget? titleWidget;

  /// Custom text style for title
  final TextStyle? titleStyle;

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
    this.titleWidget,
    this.titleStyle,
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
                child:
                    titleWidget ??
                    FusionAppText(
                      text: title,
                      style:
                          titleStyle ??
                          context.textTheme.bodyMedium?.copyWith(
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
