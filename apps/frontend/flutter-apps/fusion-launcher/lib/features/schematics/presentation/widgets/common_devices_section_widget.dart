import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import 'add_device_expandable_popup_menu_widget.dart';

class CommonDevicesSectionWidget extends StatefulWidget {
  final double width;
  final double height;
  final String title;
  final Widget sectionContent;
  final Color backgroundColor;
  final void Function(dynamic item, String areaId, String floorId)? onTapAddDevice;
  final List<ListeningArea> listeningAreas;
  final List<Zone> zones;
  final String? selectedDeviceId;
  final Function(String deviceId, List<String> listeningAreaIds)? onAddDeviceToAreas;

  // New properties for expandable sections
  final List<ExpandableSection>? expandableSections;
  final bool enableExpandable;

  const CommonDevicesSectionWidget({
    super.key,
    required this.width,
    required this.height,
    required this.title,
    required this.sectionContent,
    required this.backgroundColor,
    this.onTapAddDevice,
    this.listeningAreas = const <ListeningArea>[],
    this.zones = const <Zone>[],
    this.selectedDeviceId,
    this.onAddDeviceToAreas,
    this.expandableSections,
    this.enableExpandable = false,
  });

  @override
  State<CommonDevicesSectionWidget> createState() => _CommonDevicesSectionWidgetState();
}

class _CommonDevicesSectionWidgetState extends State<CommonDevicesSectionWidget> with TickerProviderStateMixin {
  // text editing controller for search field
  final TextEditingController searchController = TextEditingController();
  bool isSearchVisible = false;

  // Animation controllers
  late AnimationController _searchAnimationController;
  late AnimationController _iconAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _iconScaleAnimation;

  List<String> _selectedListeningAreaIds = <String>[];

  // Expansion state for sections
  final Map<String, bool> _sectionExpansionState = <String, bool>{};

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Search field slide animation
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    // Icon rotation animation
    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180 degrees (0.5 * 2π)
    ).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Icon scale animation for press effect
    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize expansion states
    if (widget.expandableSections != null) {
      for (final ExpandableSection section in widget.expandableSections!) {
        _sectionExpansionState[section.title] = section.initiallyExpanded;
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchAnimationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      isSearchVisible = !isSearchVisible;
    });

    if (isSearchVisible) {
      _searchAnimationController.forward();
      _iconAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
      _iconAnimationController.reverse();
      searchController.clear();
    }
  }

  void _onSearchIconPressed() {
    /// Quick scale animation for press feedback
    _iconAnimationController.forward().then((_) {
      _iconAnimationController.reverse();
    });
    _toggleSearch();
  }

  /// Helper method to build expandable section headers
  Widget _buildExpandableHeader(String title, bool isExpanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: <Widget>[
            Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              size: 16,
              color: Colors.black,
            ),
            const SizedBox(width: 4),
            FusionAppText(
              text: title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build animated collapsible content
  Widget _buildAnimatedContent(bool isExpanded, Widget content) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isExpanded ? null : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isExpanded ? 1.0 : 0.0,
        child:
            isExpanded
                ? Column(
                  children: <Widget>[
                    const SizedBox(height: 8),
                    content,
                  ],
                )
                : const SizedBox.shrink(),
      ),
    );
  }

  /// Build expandable content sections
  Widget _buildExpandableContent() {
    if (!widget.enableExpandable || widget.expandableSections == null) {
      return widget.sectionContent;
    }

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            widget.expandableSections!.map((ExpandableSection section) {
              final bool isExpanded = _sectionExpansionState[section.title] ?? true;

              return Column(
                children: <Widget>[
                  _buildExpandableHeader(
                    section.title,
                    isExpanded,
                    () {
                      setState(() {
                        _sectionExpansionState[section.title] = !isExpanded;
                      });
                    },
                  ),
                  _buildAnimatedContent(isExpanded, section.content),
                  if (section != widget.expandableSections!.last) const SizedBox(height: 16),
                ],
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.none,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border(
          right: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// section Header
          Container(
            width: widget.width,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
              ),
            ),
            child: AnimatedBuilder(
              animation: _searchAnimation,
              builder: (BuildContext context, Widget? child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    /// Title and search field with smooth transition
                    Expanded(
                      child: Stack(
                        children: <Widget>[
                          /// Title - fades out when search is visible
                          Opacity(
                            opacity: 1.0 - _searchAnimation.value,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: FusionAppText(
                                    text: widget.title,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLine: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),

                                /// Add button with listening areas support
                                AddDeviceExpandablePopupMenuWidget(
                                  sectionTitle: widget.title,
                                  onTapAddDevice: widget.onTapAddDevice,
                                  listeningAreas: widget.listeningAreas,
                                  zones: widget.zones,
                                ),
                              ],
                            ),
                          ),
                          // Search field - slides in when visible
                          if (_searchAnimation.value > 0)
                            Opacity(
                              opacity: _searchAnimation.value,
                              child: Transform.translate(
                                offset: Offset((1.0 - _searchAnimation.value) * 50, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.greyLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  height: 36,
                                  child: FusionTextField(
                                    controller: searchController,
                                    hintText: 'Search by name, series or type...',
                                    onChanged: (String value) {
                                      setState(() {}); // Rebuild for clear button visibility
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),

                    /// Animated search button
                    AnimatedBuilder(
                      animation: Listenable.merge(<Listenable?>[_iconScaleAnimation, _iconRotationAnimation]),
                      builder: (BuildContext context, Widget? child) {
                        return Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: Transform.rotate(
                            angle: _iconRotationAnimation.value * 3.14159,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _onSearchIconPressed,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    isSearchVisible ? Icons.close_sharp : Icons.search_sharp,
                                    color: Theme.of(context).colorScheme.greyDark,
                                    size: 17,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          /// Content with expandable support
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: widget.width,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: widget.enableExpandable ? _buildExpandableContent() : widget.sectionContent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for expandable sections
class ExpandableSection {
  final String title;
  final Widget content;
  final bool initiallyExpanded;

  const ExpandableSection({
    required this.title,
    required this.content,
    this.initiallyExpanded = true,
  });
}
