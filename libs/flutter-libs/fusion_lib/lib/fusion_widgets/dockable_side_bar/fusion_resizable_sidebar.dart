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
  bool _isDraggingDivider = false;
  bool _isWindowResizing = false;
  bool _isSectionsChanging = false;
  bool _initialized = false;
  double _availableHeight = 0;
  final Set<String> _newSectionIds = {};
  final List<_DyingSection> _dyingSections = [];

  static const double _collapsedSectionHeight = 44.0;
  static const double _minExpandedHeight = 72.0;
  static const double _minNewSectionContentHeight = 300.0;
  static const double _dividerHeight = 12.0;
  static const double _minCollapsedVisibleHeight = _collapsedSectionHeight;

  // New sections must show at least header + minimum content area.
  double get _minNewSectionVisibleHeight => _collapsedSectionHeight + _minNewSectionContentHeight;

  bool _isCollapsible(int index) {
    if (index < 0 || index >= widget.sections.length) return true;
    return widget.sections[index].enableExpandCollapse;
  }

  @override
  void initState() {
    super.initState();
    _sidebarWidth = widget.initialWidth;
    // Initialize with placeholder heights - will be calculated in first build
    _sectionStates = widget.sections
        .map((FusionResizableSidebarSection s) => _SectionState(height: 0, isExpanded: s.initiallyExpanded || !s.enableExpandCollapse))
        .toList();
  }

  /// Proportionally rescale expanded section heights when the available
  /// height changes (e.g. window resize). Collapsed sections keep their
  /// fixed height; only expanded sections are scaled.
  void _rescaleSectionHeights(double newAvailableHeight) {
    final double oldExpandedTotal = _sectionStates.where((_SectionState s) => s.isExpanded).fold(0.0, (double t, _SectionState s) => t + s.height);
    final double collapsedTotal = _sectionStates.where((_SectionState s) => !s.isExpanded).fold(0.0, (double t, _SectionState s) => t + s.height);
    final double dividerTotalHeight = _sectionStates.length > 1 ? (_sectionStates.length - 1) * _dividerHeight : 0.0;

    final double oldHeightForExpanded = oldExpandedTotal;
    final double newHeightForExpanded = newAvailableHeight - collapsedTotal - dividerTotalHeight;

    if (oldHeightForExpanded <= 0 || newHeightForExpanded <= 0) return;

    final double scaleFactor = newHeightForExpanded / oldHeightForExpanded;

    _sectionStates = _sectionStates.map((_SectionState s) {
      if (!s.isExpanded) return s;
      return s.copyWith(height: (s.height * scaleFactor).clamp(_minExpandedHeight, double.infinity));
    }).toList();
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

  int _findExpandedAtOrAbove(int startIndex) {
    for (int i = startIndex; i >= 0; i--) {
      if (_sectionStates[i].isExpanded) return i;
    }
    return -1;
  }

  int _findExpandedAtOrBelow(int startIndex) {
    for (int i = startIndex; i < _sectionStates.length; i++) {
      if (_sectionStates[i].isExpanded) return i;
    }
    return -1;
  }

  void _onSectionDividerDrag(int index, int nextIndex, DragUpdateDetails details) {
    setState(() {
      final double dy = details.delta.dy;

      if (index < 0 || nextIndex < 0 || index >= _sectionStates.length || nextIndex >= _sectionStates.length) {
        return;
      }

      // Prefer resizing the nearest expanded section above and below the divider.
      // This makes collapsed neighbors move with the drag instead of stretching
      // and showing blank space.
      final int upperExpandedIndex = _findExpandedAtOrAbove(index);
      final int lowerExpandedIndex = _findExpandedAtOrBelow(nextIndex);

      if (upperExpandedIndex >= 0 && lowerExpandedIndex >= 0 && upperExpandedIndex != lowerExpandedIndex) {
        final _SectionState upperExpanded = _sectionStates[upperExpandedIndex];
        final _SectionState lowerExpanded = _sectionStates[lowerExpandedIndex];

        double newUpperHeight = upperExpanded.height + dy;
        double newLowerHeight = lowerExpanded.height - dy;

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

        newUpperHeight = newUpperHeight.clamp(_minExpandedHeight, double.infinity);
        newLowerHeight = newLowerHeight.clamp(_minExpandedHeight, double.infinity);

        _sectionStates[upperExpandedIndex] = upperExpanded.copyWith(height: newUpperHeight);
        _sectionStates[lowerExpandedIndex] = lowerExpanded.copyWith(height: newLowerHeight);
        return;
      }

      final _SectionState upperState = _sectionStates[index];
      final _SectionState lowerState = _sectionStates[nextIndex];

      // During drag, keep at least a little content visible for expanded sections.
      // New-section strict minimum is only for first insertion, not drag.
      final bool upperCollapsible = _isCollapsible(index);
      final bool lowerCollapsible = _isCollapsible(nextIndex);
      final double upperMinHeight = (!upperCollapsible || upperState.isExpanded) ? _minExpandedHeight : _collapsedSectionHeight;
      final double lowerMinHeight = (!lowerCollapsible || lowerState.isExpanded) ? _minExpandedHeight : _collapsedSectionHeight;
      final double upperMaxHeight = upperState.isExpanded ? double.infinity : _collapsedSectionHeight;
      final double lowerMaxHeight = lowerState.isExpanded ? double.infinity : _collapsedSectionHeight;

      double newUpperHeight = upperState.height + dy;
      double newLowerHeight = lowerState.height - dy;

      // If upper hits its floor, clamp and give the excess back to lower.
      if (newUpperHeight < upperMinHeight) {
        newLowerHeight += newUpperHeight - upperMinHeight;
        newUpperHeight = upperMinHeight;
      }

      // If lower hits its floor, clamp and give the excess back to upper.
      if (newLowerHeight < lowerMinHeight) {
        newUpperHeight += newLowerHeight - lowerMinHeight;
        newLowerHeight = lowerMinHeight;
      }

      // Collapsed sections should remain header-sized while dragging.
      if (newUpperHeight > upperMaxHeight) {
        final double overflow = newUpperHeight - upperMaxHeight;
        newUpperHeight = upperMaxHeight;
        newLowerHeight += overflow;
      }

      if (newLowerHeight > lowerMaxHeight) {
        final double overflow = newLowerHeight - lowerMaxHeight;
        newLowerHeight = lowerMaxHeight;
        newUpperHeight += overflow;
      }

      // Hard clamp — don't allow negative redistribution.
      newUpperHeight = newUpperHeight.clamp(upperMinHeight, upperMaxHeight);
      newLowerHeight = newLowerHeight.clamp(lowerMinHeight, lowerMaxHeight);

      _sectionStates[index] = upperState.copyWith(height: newUpperHeight);
      _sectionStates[nextIndex] = lowerState.copyWith(height: newLowerHeight);
      // Do NOT call _normalizeHeights here — it fights the drag and causes jumps.
    });
  }

  void _onSectionDividerDragEnd(int index, int nextIndex) {
    setState(() {
      // After drag ends, normalize so heights fill available space cleanly.
      _normalizeHeights();
    });
  }

  /// Ensure all heights add up to available space:
  /// - If under-filled: give extra to last expanded section.
  /// - If over-filled: shrink expanded sections from the bottom up to remove overflow.
  void _normalizeHeights() {
    if (_availableHeight <= 0) return;

    final double dividerTotalHeight = _sectionStates.length > 1 ? (_sectionStates.length - 1) * _dividerHeight : 0.0;

    // Calculate current total and find last expanded
    double totalUsedHeight = dividerTotalHeight;
    int lastExpandedIndex = -1;

    for (int i = 0; i < _sectionStates.length; i++) {
      totalUsedHeight += _sectionStates[i].height;
      if (_sectionStates[i].isExpanded) {
        lastExpandedIndex = i;
      }
    }

    final double difference = _availableHeight - totalUsedHeight;

    if (difference > 0.5) {
      // Under-filled: give extra space to last expanded section
      if (lastExpandedIndex >= 0) {
        _sectionStates[lastExpandedIndex] = _sectionStates[lastExpandedIndex].copyWith(
          height: _sectionStates[lastExpandedIndex].height + difference,
        );
      }
    } else if (difference < -0.5) {
      // Over-filled: shrink expanded sections from the bottom up
      double overflow = -difference;
      for (int i = _sectionStates.length - 1; i >= 0 && overflow > 0; i--) {
        if (!_sectionStates[i].isExpanded) continue;
        final double minHeight = _sectionStates[i].isExpanded ? _minExpandedHeight : _collapsedSectionHeight;
        final double shrinkable = (_sectionStates[i].height - minHeight).clamp(0.0, double.infinity);
        if (shrinkable <= 0) continue;
        final double delta = shrinkable < overflow ? shrinkable : overflow;
        _sectionStates[i] = _sectionStates[i].copyWith(height: _sectionStates[i].height - delta);
        overflow -= delta;
      }

      // If still over-filled, shrink collapsed sections down to the minimum
      // visible height so dividers stay usable and sections can be recovered.
      for (int i = _sectionStates.length - 1; i >= 0 && overflow > 0; i--) {
        if (_sectionStates[i].isExpanded) continue;
        final double shrinkable = (_sectionStates[i].height - _minCollapsedVisibleHeight).clamp(0.0, double.infinity);
        if (shrinkable <= 0) continue;
        final double delta = shrinkable < overflow ? shrinkable : overflow;
        _sectionStates[i] = _sectionStates[i].copyWith(height: _sectionStates[i].height - delta);
        overflow -= delta;
      }

      // Final safety net: if constraints are still impossible, force all
      // sections to share available space and collapse them. This guarantees
      // no persistent overflow or hidden, unreachable sections.
      if (overflow > 0 && _sectionStates.isNotEmpty) {
        final double perSection = ((_availableHeight - dividerTotalHeight) / _sectionStates.length).clamp(0.0, double.infinity);
        for (int i = 0; i < _sectionStates.length; i++) {
          _sectionStates[i] = _sectionStates[i].copyWith(
            height: perSection,
            isExpanded: false,
          );
        }
      }
    }
  }

  double _calculateTotalUsedHeight(List<_SectionState> states) {
    final double dividerTotalHeight = states.length > 1 ? (states.length - 1) * _dividerHeight : 0.0;
    double totalUsedHeight = dividerTotalHeight;
    for (final _SectionState state in states) {
      totalUsedHeight += state.height;
    }
    return totalUsedHeight;
  }

  List<_SectionState> _redistributeForAddedSections(
    List<_SectionState> states,
    List<FusionResizableSidebarSection> sections,
    Set<String> newlyAddedIds,
    double availableHeight,
  ) {
    if (availableHeight <= 0 || newlyAddedIds.isEmpty) return states;

    final List<_SectionState> redistributed = List<_SectionState>.from(states);

    final List<int> newIndexes = <int>[];
    final List<int> existingIndexes = <int>[];
    for (int i = 0; i < redistributed.length; i++) {
      if (newlyAddedIds.contains(sections[i].sementicId)) {
        newIndexes.add(i);
      } else {
        existingIndexes.add(i);
      }
    }

    // New sections always start expanded at the first-time minimum height.
    for (final int idx in newIndexes) {
      redistributed[idx] = redistributed[idx].copyWith(
        height: _minNewSectionVisibleHeight,
        isExpanded: true,
      );
    }

    // Keep existing section offsets/heights whenever the new section fits.
    final double currentTotalUsed = _calculateTotalUsedHeight(redistributed);
    if (currentTotalUsed <= availableHeight + 0.5) {
      return redistributed;
    }

    final double dividerTotalHeight = redistributed.length > 1 ? (redistributed.length - 1) * _dividerHeight : 0.0;
    final double heightReservedForNew = newIndexes.length * _minNewSectionVisibleHeight;
    final double remainingForExisting = (availableHeight - dividerTotalHeight - heightReservedForNew).clamp(0.0, double.infinity);

    if (existingIndexes.isNotEmpty) {
      final double evenExistingHeight = (remainingForExisting / existingIndexes.length).clamp(0.0, double.infinity);
      for (final int idx in existingIndexes) {
        final bool collapsible = sections[idx].enableExpandCollapse;
        redistributed[idx] = redistributed[idx].copyWith(
          height: evenExistingHeight,
          isExpanded: collapsible ? redistributed[idx].isExpanded : true,
        );
      }
    }

    return redistributed;
  }

  /// Shrink sections only when needed to fit available height.
  /// Preference order:
  /// 1) shrink/collapse existing sections
  /// 2) keep newly-added sections at least header + minimum content visible
  /// Newly-added sections are never reduced below _minNewSectionVisibleHeight.
  List<_SectionState> _fitStatesToAvailableHeight(
    List<_SectionState> states,
    List<FusionResizableSidebarSection> sections,
    Set<String> newlyAddedIds,
    double availableHeight,
  ) {
    if (availableHeight <= 0) return states;

    final List<_SectionState> fitted = List<_SectionState>.from(states);
    double overflow = _calculateTotalUsedHeight(fitted) - availableHeight;
    if (overflow <= 0) return fitted;

    // Pass 1: collapse existing expanded sections toward header height first.
    // This preserves minimum visible content in newly-added sections.
    for (int i = 0; i < fitted.length && overflow > 0; i++) {
      if (!fitted[i].isExpanded || newlyAddedIds.contains(sections[i].sementicId)) {
        continue;
      }
      final double shrinkable = (fitted[i].height - _collapsedSectionHeight).clamp(0.0, double.infinity);
      if (shrinkable <= 0) continue;
      final double delta = shrinkable < overflow ? shrinkable : overflow;
      final double newHeight = fitted[i].height - delta;
      final bool shouldCollapse = sections[i].enableExpandCollapse && newHeight <= _collapsedSectionHeight + 0.5;
      fitted[i] = fitted[i].copyWith(
        height: shouldCollapse ? _collapsedSectionHeight : newHeight,
        isExpanded: shouldCollapse ? false : fitted[i].isExpanded,
      );
      overflow -= delta;
    }

    // Pass 2: if still overflowing, shrink newly-added expanded sections only
    // down to minimum visible-content height.
    for (int i = 0; i < fitted.length && overflow > 0; i++) {
      if (!fitted[i].isExpanded || !newlyAddedIds.contains(sections[i].sementicId)) {
        continue;
      }
      final double shrinkable = (fitted[i].height - _minNewSectionVisibleHeight).clamp(0.0, double.infinity);
      if (shrinkable <= 0) continue;
      final double delta = shrinkable < overflow ? shrinkable : overflow;
      fitted[i] = fitted[i].copyWith(height: fitted[i].height - delta);
      overflow -= delta;
    }

    // Pass 3: if still overflowing, proportionally shrink all remaining expanded sections
    // down to minimum expanded height.
    if (overflow > 0) {
      final List<int> expandedIndexes = <int>[];
      double totalShrinkable = 0;
      for (int i = 0; i < fitted.length; i++) {
        if (!fitted[i].isExpanded) continue;
        final double minHeight = newlyAddedIds.contains(sections[i].sementicId) ? _minNewSectionVisibleHeight : _minExpandedHeight;
        final double shrinkable = (fitted[i].height - minHeight).clamp(0.0, double.infinity);
        if (shrinkable > 0) {
          expandedIndexes.add(i);
          totalShrinkable += shrinkable;
        }
      }

      if (totalShrinkable > 0) {
        for (final int idx in expandedIndexes) {
          final double minHeight = newlyAddedIds.contains(sections[idx].sementicId) ? _minNewSectionVisibleHeight : _minExpandedHeight;
          final double shrinkable = (fitted[idx].height - minHeight).clamp(0.0, double.infinity);
          final double share = shrinkable / totalShrinkable;
          final double delta = (overflow * share).clamp(0.0, shrinkable);
          fitted[idx] = fitted[idx].copyWith(height: fitted[idx].height - delta);
        }

        overflow = _calculateTotalUsedHeight(fitted) - availableHeight;
      }
    }

    // Pass 4: if still overflowing, collapse existing (non-new) expanded sections
    // from min-expanded down to collapsed header height to preserve new content visibility.
    for (int i = 0; i < fitted.length && overflow > 0; i++) {
      if (!fitted[i].isExpanded || newlyAddedIds.contains(sections[i].sementicId)) {
        continue;
      }
      final double shrinkable = (fitted[i].height - _collapsedSectionHeight).clamp(0.0, double.infinity);
      if (shrinkable <= 0) continue;
      final double delta = shrinkable < overflow ? shrinkable : overflow;
      final double newHeight = fitted[i].height - delta;
      final bool shouldCollapse = sections[i].enableExpandCollapse && newHeight <= _collapsedSectionHeight + 0.5;
      fitted[i] = fitted[i].copyWith(
        height: shouldCollapse ? _collapsedSectionHeight : newHeight,
        isExpanded: shouldCollapse ? false : fitted[i].isExpanded,
      );
      overflow -= delta;
    }

    // Pass 5: if still overflowing, shrink existing collapsed sections as well.
    // This avoids requiring manual drag just to reveal new content.
    for (int i = 0; i < fitted.length && overflow > 0; i++) {
      if (fitted[i].isExpanded || newlyAddedIds.contains(sections[i].sementicId)) {
        continue;
      }
      final double shrinkable = (fitted[i].height - _minCollapsedVisibleHeight).clamp(0.0, double.infinity);
      if (shrinkable <= 0) continue;
      final double delta = shrinkable < overflow ? shrinkable : overflow;
      fitted[i] = fitted[i].copyWith(height: fitted[i].height - delta);
      overflow -= delta;
    }

    // Pass 6 (guaranteed fit): if still overflowing due hard constraints,
    // force all sections to share space and collapse them.
    if (overflow > 0 && fitted.isNotEmpty) {
      final double dividerTotalHeight = fitted.length > 1 ? (fitted.length - 1) * _dividerHeight : 0.0;
      final double perSection = ((availableHeight - dividerTotalHeight) / fitted.length).clamp(0.0, double.infinity);
      for (int i = 0; i < fitted.length; i++) {
        fitted[i] = fitted[i].copyWith(
          height: perSection,
          isExpanded: false,
        );
      }
    }

    return fitted;
  }

  void _toggleSection(int index) {
    setState(() {
      if (!_isCollapsible(index)) {
        return;
      }

      final bool wasExpanded = _sectionStates[index].isExpanded;
      final bool willExpand = !wasExpanded;

      if (willExpand) {
        // Expanding by toggle should open with first-time minimum visible content.
        final double desiredExpandedHeight = _minNewSectionVisibleHeight;
        double currentHeight = _sectionStates[index].height;

        _sectionStates[index] = _sectionStates[index].copyWith(isExpanded: true);

        double needed = (desiredExpandedHeight - currentHeight).clamp(0.0, double.infinity);
        if (needed > 0) {
          final List<int> donorOrder = <int>[];

          // Prefer donors below, then above, to keep movement intuitive.
          for (int i = index + 1; i < _sectionStates.length; i++) {
            donorOrder.add(i);
          }
          for (int i = index - 1; i >= 0; i--) {
            donorOrder.add(i);
          }

          for (final int donorIndex in donorOrder) {
            if (needed <= 0) break;

            final _SectionState donor = _sectionStates[donorIndex];
            final double donorMin = donor.isExpanded ? _minExpandedHeight : _collapsedSectionHeight;
            final double shrinkable = (donor.height - donorMin).clamp(0.0, double.infinity);
            if (shrinkable <= 0) continue;

            final double granted = shrinkable < needed ? shrinkable : needed;
            _sectionStates[donorIndex] = donor.copyWith(height: donor.height - granted);
            currentHeight += granted;
            needed -= granted;
          }
        }

        final double minHeight = _minExpandedHeight;
        _sectionStates[index] = _sectionStates[index].copyWith(
          height: currentHeight.clamp(minHeight, double.infinity),
          isExpanded: true,
        );
      } else {
        // Collapsing: give freed space only to the first expanded section below,
        // so it moves up to fill the gap. Fall back to the nearest expanded section above.
        final double freedHeight = _sectionStates[index].height - _collapsedSectionHeight;

        _sectionStates[index] = _sectionStates[index].copyWith(
          height: _collapsedSectionHeight,
          isExpanded: false,
        );

        // Find the first expanded section below the collapsed one
        int targetIndex = -1;
        for (int i = index + 1; i < _sectionStates.length; i++) {
          if (_sectionStates[i].isExpanded) {
            targetIndex = i;
            break;
          }
        }

        // If none below, fall back to the nearest expanded section above
        if (targetIndex < 0) {
          for (int i = index - 1; i >= 0; i--) {
            if (_sectionStates[i].isExpanded) {
              targetIndex = i;
              break;
            }
          }
        }

        if (targetIndex >= 0) {
          _sectionStates[targetIndex] = _sectionStates[targetIndex].copyWith(
            height: _sectionStates[targetIndex].height + freedHeight,
          );
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
      final List<_SectionState> oldStates = List<_SectionState>.from(_sectionStates);
      final Set<String> oldIds = oldWidget.sections.map((FusionResizableSidebarSection s) => s.sementicId).toSet();
      final Set<String> newIds = widget.sections.map((FusionResizableSidebarSection s) => s.sementicId).toSet();
      final Set<String> removedIds = oldIds.difference(newIds);

      // Track newly added sections so they can play an enter animation
      _newSectionIds
        ..clear()
        ..addAll(
          newIds.difference(oldIds),
        );

      // Build next states by preserving all existing section heights by id.
      // New sections are inserted with their natural initial height.
      List<_SectionState> nextStates = widget.sections.map((FusionResizableSidebarSection s) {
        final int oldIdx = oldWidget.sections.indexWhere((FusionResizableSidebarSection o) => o.sementicId == s.sementicId);
        if (oldIdx >= 0 && oldIdx < oldStates.length) {
          final _SectionState restored = oldStates[oldIdx];
          return restored.copyWith(
            isExpanded: s.enableExpandCollapse ? restored.isExpanded : true,
          );
        }
        // Newly added sections should always start with minimum content visible.
        if (_newSectionIds.contains(s.sementicId)) {
          return _SectionState(
            height: _minNewSectionVisibleHeight,
            isExpanded: true,
          );
        }
        return _SectionState(
          height: s.initiallyExpanded || !s.enableExpandCollapse ? _minExpandedHeight : _collapsedSectionHeight,
          isExpanded: s.initiallyExpanded || !s.enableExpandCollapse,
        );
      }).toList();

      // For additions, keep new sections at default visible height and
      // distribute required shrinkage evenly across existing sections first.
      if (_newSectionIds.isNotEmpty) {
        nextStates = _redistributeForAddedSections(nextStates, widget.sections, _newSectionIds, _availableHeight);
      }

      // Only resize existing sections if there is not enough room.
      nextStates = _fitStatesToAvailableHeight(nextStates, widget.sections, _newSectionIds, _availableHeight);

      // Track removed sections so they can play an exit animation before disappearing.
      // Compute the y-offset of each removed section by summing heights of sections above it
      // so it can be rendered as an absolutely-positioned overlay (out of flow).
      double runningY = 0;
      for (int i = 0; i < oldWidget.sections.length; i++) {
        final FusionResizableSidebarSection old = oldWidget.sections[i];
        final double sectionHeight = i < oldStates.length ? oldStates[i].height : _collapsedSectionHeight;
        if (removedIds.contains(old.sementicId)) {
          _dyingSections.add(
            _DyingSection(
              section: old,
              height: sectionHeight,
              yOffset: runningY,
              finalStates: nextStates,
            ),
          );
        }
        // Count divider height between sections
        runningY += sectionHeight + (i < oldWidget.sections.length - 1 ? _dividerHeight : 0);
      }

      // Preserve positions while transition runs, and apply fitted states.
      _isSectionsChanging = true;
      _sectionStates = nextStates;
      _initialized = true;
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

        if (!_initialized) {
          // First build: initialise evenly
          _availableHeight = availableHeight;
          _initializeSectionHeights(availableHeight);
          _isWindowResizing = false;
        } else if ((availableHeight - _availableHeight).abs() > 0.5) {
          // Window resized: scale expanded sections proportionally, no animation
          _isWindowResizing = true;
          _rescaleSectionHeights(availableHeight);
          _availableHeight = availableHeight;
        } else {
          _isWindowResizing = false;
        }

        // ── Render-time height fit ──────────────────────────────────────────
        // Compute render heights from stored state and guarantee they fit
        // exactly within availableHeight so the Column never overflows.
        final double dividerTotalHeight = widget.sections.length > 1 ? (widget.sections.length - 1) * _dividerHeight : 0.0;
        final List<double> renderHeights = List<double>.generate(
          _sectionStates.length,
          (int i) => _sectionStates[i].height,
        );

        // 1) Fill any under-used space into the last expanded section.
        int lastExpandedIndex = -1;
        double totalRender = dividerTotalHeight;
        for (int i = 0; i < renderHeights.length; i++) {
          totalRender += renderHeights[i];
          if (_sectionStates[i].isExpanded) lastExpandedIndex = i;
        }
        final double slack = availableHeight - totalRender;
        if (slack > 0.5 && lastExpandedIndex >= 0) {
          renderHeights[lastExpandedIndex] += slack;
          totalRender = availableHeight;
        }

        // 2) If total still exceeds available, scale expanded sections down
        //    proportionally while keeping every section at least its header height.
        if (totalRender > availableHeight + 0.5 && renderHeights.isNotEmpty) {
          double overflow = totalRender - availableHeight;
          for (int i = renderHeights.length - 1; i >= 0 && overflow > 0; i--) {
            final double floor = _sectionStates[i].isExpanded ? _minExpandedHeight : _collapsedSectionHeight;
            final double shrinkable = (renderHeights[i] - floor).clamp(0.0, double.infinity);
            if (shrinkable <= 0) continue;
            final double delta = shrinkable < overflow ? shrinkable : overflow;
            renderHeights[i] -= delta;
            overflow -= delta;
          }
          // If still over (every section at its floor), scale equally ignoring floors.
          if (overflow > 0.5) {
            final double available = (availableHeight - dividerTotalHeight).clamp(0.0, double.infinity);
            final double perSection = (available / renderHeights.length).clamp(0.0, double.infinity);
            for (int i = 0; i < renderHeights.length; i++) {
              renderHeights[i] = perSection;
            }
          }
        }
        // ────────────────────────────────────────────────────────────────────

        final List<Widget> sectionWidgets = [];

        for (int i = 0; i < widget.sections.length; i++) {
          final bool isLast = i == widget.sections.length - 1;
          final int nextIndex = !isLast ? i + 1 : -1;

          final double height = renderHeights[i];

          sectionWidgets.add(
            _SectionWidget(
              key: ValueKey<String>(widget.sections[i].sementicId),
              section: widget.sections[i],
              state: _sectionStates[i].copyWith(height: height),
              isEntering: _newSectionIds.contains(widget.sections[i].sementicId),
              animateHeight: !_isDraggingDivider && !_isWindowResizing && !_isSectionsChanging,
              onToggle: () => _toggleSection(i),
              onDividerDrag: !isLast ? (DragUpdateDetails d) => _onSectionDividerDrag(i, nextIndex, d) : null,
              onDividerDragStart: !isLast ? () => setState(() => _isDraggingDivider = true) : null,
              onDividerDragEnd: !isLast
                  ? () {
                      setState(() => _isDraggingDivider = false);
                      _onSectionDividerDragEnd(i, nextIndex);
                    }
                  : null,
            ),
          );
        }

        // Dying sections are rendered as absolutely-positioned Stack overlays so
        // they never contribute to the Column's layout height (avoids overflow).
        final List<Widget> dyingOverlays = _dyingSections.map((_DyingSection dying) {
          return Positioned(
            top: dying.yOffset,
            left: 0,
            right: 0,
            height: dying.height,
            child: _DyingSectionWidget(
              key: ValueKey<String>('dying_${dying.section.sementicId}'),
              section: dying.section,
              startHeight: dying.height,
              onDone: () {
                if (mounted) {
                  setState(() {
                    // Apply the final redistributed heights now that exit animation is done
                    if (dying.finalStates != null && dying.finalStates!.length == _sectionStates.length) {
                      _sectionStates = List<_SectionState>.from(dying.finalStates!);
                    }
                    _dyingSections.removeWhere((_DyingSection d) => d.section.sementicId == dying.section.sementicId);
                  });
                }
              },
            ),
          );
        }).toList();

        return SizedBox(
          height: availableHeight,
          child: ClipRect(
            child: Builder(
              builder: (BuildContext ctx) {
                // Clear the sections-changing flag after this frame so subsequent
                // height changes (e.g. toggle) animate normally.
                if (_isSectionsChanging) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _isSectionsChanging = false;
                        _newSectionIds.clear();
                      });
                    }
                  });
                }
                return Stack(
                  children: <Widget>[
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      children: sectionWidgets,
                    ),
                    ...dyingOverlays,
                  ],
                );
              },
            ),
          ),
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
// DYING SECTION (exit animation)
// ─────────────────────────────────────────────────────────────────────────────

class _DyingSection {
  final FusionResizableSidebarSection section;
  final double height;
  final double yOffset;

  /// Heights to restore on surviving sections once this exit animation completes.
  final List<_SectionState>? finalStates;

  _DyingSection({required this.section, required this.height, required this.yOffset, this.finalStates});
}

class _DyingSectionWidget extends StatefulWidget {
  final FusionResizableSidebarSection section;
  final double startHeight;
  final VoidCallback onDone;

  const _DyingSectionWidget({
    super.key,
    required this.section,
    required this.startHeight,
    required this.onDone,
  });

  @override
  State<_DyingSectionWidget> createState() => _DyingSectionWidgetState();
}

class _DyingSectionWidgetState extends State<_DyingSectionWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _heightFactor = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65)));
    _controller.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Positioned parent already constrains width & height.
    // We animate opacity + a downward slide — no SizedBox shrink needed
    // since the section is out of flow and clipped by the parent ClipRect.
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, widget.startHeight * (1.0 - _heightFactor.value) * 0.4),
            child: child,
          ),
        );
      },
      child: widget.section.builder(
        context,
        false,
        () {},
        const AlwaysStoppedAnimation<double>(0.0),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _SectionWidget extends StatefulWidget {
  final FusionResizableSidebarSection section;
  final _SectionState state;
  final bool isEntering;
  final bool animateHeight;
  final VoidCallback onToggle;
  final void Function(DragUpdateDetails)? onDividerDrag;
  final VoidCallback? onDividerDragStart;
  final VoidCallback? onDividerDragEnd;

  const _SectionWidget({
    super.key,
    required this.section,
    required this.state,
    required this.onToggle,
    this.isEntering = false,
    this.animateHeight = true,
    this.onDividerDrag,
    this.onDividerDragStart,
    this.onDividerDragEnd,
  });

  @override
  State<_SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<_SectionWidget> with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _enterController;
  late Animation<double> _expandAnim;
  late Animation<double> _enterOpacity;
  late Animation<Offset> _enterSlide;
  bool _isDividerHovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: widget.state.isExpanded ? 1.0 : 0.0);
    _expandAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    // Enter animation: slide up from slightly below + fade in
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.isEntering ? 0.0 : 1.0,
    );
    _enterOpacity = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _enterSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));

    if (widget.isEntering) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _enterController.forward();
      });
    }
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
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpanded = widget.state.isExpanded;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "resizable_section_${widget.section.sementicId}"),
      child: FadeTransition(
        opacity: _enterOpacity,
        child: SlideTransition(
          position: _enterSlide,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // User's custom builder with all necessary params
              AnimatedContainer(
                duration: widget.animateHeight ? const Duration(milliseconds: 200) : Duration.zero,
                curve: Curves.easeInOut,
                height: widget.state.height,
                child: widget.section.builder(context, isExpanded, widget.onToggle, _expandAnim),
              ),

              // Draggable divider between sections
              if (widget.onDividerDrag != null) _buildDivider(),
            ],
          ),
        ),
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
        onVerticalDragStart: (_) => widget.onDividerDragStart?.call(),
        onVerticalDragUpdate: widget.onDividerDrag,
        onVerticalDragEnd: (_) => widget.onDividerDragEnd?.call(),
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
                  child: FusionIcon.svg(
                    "packages/fusion_lib/lib/assets/svgs/expand_up.svg",
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
                  style: context.textTheme.l1Medium.copyWith(
                    color: context.colorScheme.textBody,
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
