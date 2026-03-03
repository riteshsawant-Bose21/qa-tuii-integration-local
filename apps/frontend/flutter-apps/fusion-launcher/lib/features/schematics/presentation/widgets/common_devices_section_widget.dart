import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_launcher/features/add_source_popup/view/add_source_popup.dart';
import 'package:fusion_launcher/features/projects/widget/building/side_panel_widgets/equipment_location/equipment_location_dialog.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../projects/viewmodel/eql_products_vm.dart';
import 'add_device_expandable_popup_menu_widget.dart';

class CommonDevicesSectionWidget extends StatefulWidget {
  final double width;
  final double height;
  final String title;
  final Widget sectionContent;
  final Color backgroundColor;
  final void Function(dynamic item, String areaId, String floorId)?
  onTapAddDevice;
  final List<ListeningArea> listeningAreas;
  final String? selectedDeviceId;
  final Function(String deviceId, List<String> listeningAreaIds)?
  onAddDeviceToAreas;
  final List<ExpandableSection>? expandableSections;
  final bool enableExpandable;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String?>? onActiveExpandableSectionChanged;
  final int? searchResultCount;
  final String? searchQuery;

  const CommonDevicesSectionWidget({
    super.key,
    required this.width,
    required this.height,
    required this.title,
    required this.sectionContent,
    required this.backgroundColor,
    this.onTapAddDevice,
    this.listeningAreas = const <ListeningArea>[],
    this.selectedDeviceId,
    this.onAddDeviceToAreas,
    this.expandableSections,
    this.enableExpandable = false,
    this.onSearchChanged,
    this.onActiveExpandableSectionChanged,
    this.searchResultCount,
    this.searchQuery,
  });

  @override
  State<CommonDevicesSectionWidget> createState() =>
      _CommonDevicesSectionWidgetState();
}

class _CommonDevicesSectionWidgetState extends State<CommonDevicesSectionWidget>
    with TickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool isSearchVisible = false;

  /// Animation controllers
  late AnimationController _searchAnimationController;
  late AnimationController _iconAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _iconScaleAnimation;

  /// Expansion state for sections
  final Map<String, bool> _sectionExpansionState = <String, bool>{};

  /// track current section for search scoping
  String? _activeExpandableSectionTitle;

  @override
  void initState() {
    super.initState();

    /// Initialize animation controllers
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    /// Search field slide animation
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    /// Icon rotation animation
    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180 degrees (0.5 * 2π)
    ).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    /// Icon scale animation for press effect
    _iconScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    /// Initialize expansion states
    if (widget.expandableSections != null) {
      for (final ExpandableSection section in widget.expandableSections!) {
        _sectionExpansionState[section.title] = section.initiallyExpanded;
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  /// Toggle search field visibility
  void _toggleSearch() {
    setState(() {
      isSearchVisible = !isSearchVisible;
    });

    if (isSearchVisible) {
      _searchAnimationController.forward();
      _iconAnimationController.forward();

      /// when search opens, keep current active section (last tapped) or first expanded
      if (_activeExpandableSectionTitle == null &&
          widget.expandableSections != null &&
          widget.expandableSections!.isNotEmpty) {
        final ExpandableSection firstExpanded = widget.expandableSections!
            .firstWhere(
              (ExpandableSection s) => _sectionExpansionState[s.title] == true,
              orElse: () => widget.expandableSections!.first,
            );
        _activeExpandableSectionTitle = firstExpanded.title;
      }
      widget.onActiveExpandableSectionChanged?.call(
        _activeExpandableSectionTitle,
      );

      /// request focus after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    } else {
      _searchAnimationController.reverse();
      _iconAnimationController.reverse();
      searchController.clear();
      widget.onSearchChanged?.call('');
      _activeExpandableSectionTitle = null;
      widget.onActiveExpandableSectionChanged?.call(null); // show all again
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
  Widget _buildExpandableHeader({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();

        /// set active section when header tapped (only matters while searching)
        _activeExpandableSectionTitle = title;
        if (isSearchVisible) {
          widget.onActiveExpandableSectionChanged?.call(
            _activeExpandableSectionTitle,
          );
        }
      },
      child: SemanticHelper.toggle(
        testId: SemanticHelper.createTestId(
          SemanticTypes.toggle,
          "expandable_header_$title",
        ),
        value: isExpanded,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              RotatedBox(
                quarterTurns: isExpanded ? 0 : 1,
                child: FusionSvgIcon(
                  icon: AssetSvg.expandUp,
                  size: FusionSizes.iconSize12,
                  color: context.colorScheme.iconWhite,
                ),
              ),
              const SizedBox(width: 8),
              FusionAppText(
                text: title,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.textPrimary,
                ),
              ),
              const Spacer(),

              /// Add device icon
              Builder(
                builder: (BuildContext context) {
                  if (title == "Sources") {
                    return AddSourcePopup(
                      isFromBuildingPage: false,
                      child: Icon(
                        LucideIcons.plus200,
                        size: 16,
                        color: context.colorScheme.primaryWhite,
                      ),
                    );
                  } else {
                    if (title == "Endpoints" ||
                        title == "Fusion Devices" ||
                        title == "Amplifiers") {
                      return FusionArrowPopup(
                        semanticId: 'common_device_section$title',
                        content: EquipmentLocationDialog(
                          currentFilter:
                              title == "Amplifiers"
                                  ? EQLDeviceType.amplifier
                                  : title == "Fusion Devices"
                                  ? EQLDeviceType.processor
                                  : title == "Endpoints"
                                  ? EQLDeviceType.endpoint
                                  : EQLDeviceType.endpoint,
                        ),
                        child: Icon(
                          LucideIcons.plus200,
                          size: FusionSizes.iconSize16,
                          color: context.colorScheme.primaryWhite,
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build animated collapsible content
  Widget _buildAnimatedContent(
    bool isExpanded,
    String sectionTitle,
    Widget content,
  ) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "expandable_content_$sectionTitle",
      ),
      child: AnimatedContainer(
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
      ),
    );
  }

  /// Build expandable content sections
  Widget _buildExpandableContent() {
    if (!widget.enableExpandable || widget.expandableSections == null)
      return widget.sectionContent;

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "expandable_sections_container",
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            widget.expandableSections!.map((ExpandableSection section) {
              final bool isExpanded =
                  _sectionExpansionState[section.title] ?? true;

              final int index = widget.expandableSections!.indexOf(section);

              return SemanticHelper.button(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.button,
                  "expandable_section_${section.title}_index_$index",
                ),
                child: Column(
                  children: <Widget>[
                    _buildExpandableHeader(
                      title: section.title,
                      isExpanded: isExpanded,
                      onTap: () {
                        setState(() {
                          _sectionExpansionState[section.title] = !isExpanded;
                        });
                      },
                    ),
                    _buildAnimatedContent(
                      isExpanded,
                      section.title,
                      section.content,
                    ),
                    if (section != widget.expandableSections!.last)
                      const SizedBox(height: 16),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "expandable_section_container_${widget.title.toLowerCase()}",
      ),
      child: Container(
        // padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          border: Border.all(color: context.colorScheme.elevation2, width: 1),
          borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            /// section Header
            SemanticHelper.container(
              testId: SemanticHelper.createTestId(
                SemanticTypes.container,
                "expandable_section_header_container_${widget.title.toLowerCase()}",
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                alignment: Alignment.centerLeft,
                height: 44,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: context.colorScheme.elevation2,
                    ),
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
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 1.0 - _searchAnimation.value,
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: FusionAppText(
                                          text: widget.title.toUpperCase(),
                                          maxLine: 1,
                                          style: context.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                fontSize:
                                                    FusionSizes.fontSize12,
                                                color:
                                                    context
                                                        .colorScheme
                                                        .textBody,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      /// Add button with listening areas support
                                      AddDeviceExpandablePopupMenuWidget(
                                        sectionTitle: widget.title,
                                        onTapAddDevice: widget.onTapAddDevice,
                                        listeningAreas: widget.listeningAreas,
                                        // zones: widget.zones,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// Search field - slides in when visible
                              if (_searchAnimation.value > 0)
                                Opacity(
                                  opacity: _searchAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      (1.0 - _searchAnimation.value) * 50,
                                      0,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: SemanticHelper.formControl(
                                            testId: SemanticHelper.createTestId(
                                              SemanticTypes.textInput,
                                              "section_search_${widget.title.toLowerCase()}",
                                            ),
                                            child: FusionTextField(
                                              semanticFieldId:
                                                  "section_search_${widget.title.toLowerCase()}",
                                              color:
                                                  context
                                                      .colorScheme
                                                      .elevation2,
                                              controller: searchController,
                                              hintText:
                                                  widget.title == 'Speakers'
                                                      ? 'Search zones'
                                                      : 'Search devices',
                                              focusNode: _searchFocusNode,
                                              onChanged: (String value) {
                                                setState(() {});
                                                widget.onSearchChanged?.call(
                                                  value.trim(),
                                                );
                                                if (isSearchVisible) {
                                                  widget
                                                      .onActiveExpandableSectionChanged
                                                      ?.call(
                                                        _activeExpandableSectionTitle,
                                                      );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 4),

                        /// Animated search button
                        AnimatedBuilder(
                          animation: Listenable.merge(<Listenable?>[
                            _iconScaleAnimation,
                            _iconRotationAnimation,
                          ]),
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
                                    child: SemanticHelper.button(
                                      testId: SemanticHelper.createTestId(
                                        SemanticTypes.button,
                                        isSearchVisible
                                            ? "${widget.title.toLowerCase()}_search_close_icon"
                                            : "${widget.title.toLowerCase()}_search_icon",
                                      ),
                                      child: Icon(
                                        isSearchVisible
                                            ? Icons.close_sharp
                                            : Icons.search_sharp,
                                        color: context.colorScheme.primaryWhite,
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
            ),

            const SizedBox(height: 8),

            /// Content with expandable support
            Flexible(
              child: SemanticHelper.container(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.container,
                  "expandable_section_content_container_${widget.title.toLowerCase()}",
                ),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: widget.width,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          /// Search results message (only when active & query not empty)
                          if (isSearchVisible &&
                              (widget.searchQuery != null &&
                                  widget.searchQuery!.isNotEmpty)) ...<Widget>[
                            SemanticHelper.container(
                              testId: SemanticHelper.createTestId(
                                SemanticTypes.container,
                                "search_results_message_container",
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  bottom: 6.0,
                                  right: 16.0,
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                    children: <InlineSpan>[
                                      TextSpan(
                                        text:
                                            '${widget.searchResultCount ?? 0} results found for ',
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  context
                                                      .colorScheme
                                                      .primaryWhite,
                                            ),
                                      ),
                                      TextSpan(
                                        text: '"${widget.searchQuery}"',
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              backgroundColor:
                                                  Colors.orange[200],
                                              color: Colors.black,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // const SizedBox(height: 8),
                          ],

                          /// Original content (expandable / static)
                          Builder(
                            builder: (BuildContext context) {
                              if (widget.enableExpandable) {
                                return _buildExpandableContent();
                              } else {
                                return widget.sectionContent;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Data class for expandable sections
class ExpandableSection {
  final String title;
  final Widget content;
  final bool initiallyExpanded;
  final void Function()? onAddDevice;

  const ExpandableSection({
    required this.title,
    required this.content,
    this.initiallyExpanded = true,
    this.onAddDevice,
  });
}
