import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_sources.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_zones_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../core/widgets/configuration_widgets/drag_divider.dart';
import '../viewModel/sources_viewmodel/config_sources_viewmodel.dart';
import '../viewModel/source_sets_viewmodel/config_source_sets_viewmodel.dart';
import '../viewModel/zones_viewmodel/config_zones_state.dart';
import '../viewModel/zones_viewmodel/config_zones_viewmodel.dart';
import '../widgets/source_set_section.dart';
import '../widgets/sources_section.dart';
import '../widgets/zone_card.dart';

class ConfigurationProcessingPage extends StatelessWidget {
  const ConfigurationProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.processingsec),
      child: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<ConfigSourcesViewmodel>(
            create:
                (BuildContext context) => ConfigSourcesViewmodel(
                  projectViewModel: projectViewModel,
                ),
          ),
          BlocProvider<ConfigSourceSetsViewmodel>(
            create:
                (BuildContext context) => ConfigSourceSetsViewmodel(
                  projectViewModel: projectViewModel,
                ),
          ),
          BlocProvider<ConfigZonesViewmodel>(
            create:
                (BuildContext context) => ConfigZonesViewmodel(
                  projectViewModel: projectViewModel,
                ),
          ),
        ],
        child: const _ConfigurationProcessingPageBody(),
      ),
    );
  }
}

class _ConfigurationProcessingPageBody extends StatefulWidget {
  const _ConfigurationProcessingPageBody();

  @override
  State<_ConfigurationProcessingPageBody> createState() => _ConfigurationProcessingPageBodyState();
}

class _ConfigurationProcessingPageBodyState extends State<_ConfigurationProcessingPageBody> {
  final TextEditingController _sourceSetNameController = TextEditingController();
  final List<SelectedSource> _selectedSources = <SelectedSource>[];
  ConfigSourceSetsViewmodel get _sourceSetsViewmodel => context.read<ConfigSourceSetsViewmodel>();
  final ScrollController _zonesScrollController = ScrollController();
  ConfigSourcesViewmodel get _sourcesViewmodel => context.read<ConfigSourcesViewmodel>();

  ConfigZonesViewmodel get _zonesViewmodel => context.read<ConfigZonesViewmodel>();

  /// Map to store GlobalKeys for each SourceSetItem
  final Map<String, GlobalKey> _sourceSetKeys = <String, GlobalKey<State<StatefulWidget>>>{};

  /// Map to store GlobalKeys for each ZoneCard
  final Map<String, GlobalKey> _zoneKeys = <String, GlobalKey<State<StatefulWidget>>>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double screenHeight = MediaQuery.of(context).size.height;
    _sourcesViewmodel.initializeSourcesHeight(screenHeight);
  }

  void _updateSourcesHeight(double delta) {
    final double screenHeight = MediaQuery.of(context).size.height;
    _sourcesViewmodel.updateSourcesHeight(delta, screenHeight);
  }

  @override
  void dispose() {
    _sourceSetNameController.dispose();
    _zonesScrollController.dispose();
    _sourceSetKeys.clear();
    _zoneKeys.clear();
    super.dispose();
  }

  /// Scroll expanded zone into view using GlobalKey for accurate positioning
  void _scrollZoneIntoView(String zoneId) {
    final GlobalKey? zoneKey = _zoneKeys[zoneId];
    if (zoneKey?.currentContext == null || !_zonesScrollController.hasClients) {
      return;
    }

    final RenderObject? renderObject = zoneKey!.currentContext!.findRenderObject();
    if (renderObject is! RenderBox) return;

    // Get the position of the zone relative to the scroll view
    final RenderObject? scrollViewRenderObject = _zonesScrollController.position.context.storageContext.findRenderObject();
    if (scrollViewRenderObject is! RenderBox) return;

    try {
      // Get zone position relative to the scrollable area
      final Offset zonePosition = renderObject.localToGlobal(Offset.zero, ancestor: scrollViewRenderObject);
      final double zoneTop = zonePosition.dy + _zonesScrollController.offset;

      // Get viewport dimensions
      final double viewportHeight = _zonesScrollController.position.viewportDimension;
      final double currentScrollOffset = _zonesScrollController.offset;

      // Calculate the expanded content height (estimated)
      final List<SubZone> subZones = _zonesViewmodel.getSubZonesForZone(parentZoneId: zoneId);
      final double expandedContentHeight = (subZones.length * 100.0).clamp(200.0, 400.0);
      final double totalZoneHeight = 32.0 + expandedContentHeight; // header + content

      // Check if zone fits in current viewport
      final double zoneBottom = zoneTop + totalZoneHeight;
      final double viewportTop = currentScrollOffset;
      final double viewportBottom = currentScrollOffset + viewportHeight;

      // Calculate optimal scroll position
      double targetScrollPosition = currentScrollOffset;

      if (zoneTop < viewportTop) {
        // Zone starts above viewport, scroll up to show zone at top with padding
        targetScrollPosition = zoneTop - 20; // 20px padding
      } else if (zoneBottom > viewportBottom) {
        // Zone extends below viewport, scroll down to fit the zone
        if (totalZoneHeight <= viewportHeight) {
          // Zone fits in viewport, position it optimally
          targetScrollPosition = zoneBottom - viewportHeight + 20; // 20px padding from bottom
        } else {
          // Zone is larger than viewport, just ensure the header is visible at top
          targetScrollPosition = zoneTop - 20;
        }
      }

      // Clamp to valid scroll range
      targetScrollPosition = targetScrollPosition.clamp(0.0, _zonesScrollController.position.maxScrollExtent);

      // Animate to target position if it's different from current
      if ((targetScrollPosition - currentScrollOffset).abs() > 5) {
        _zonesScrollController.animateTo(
          targetScrollPosition,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      // Fallback to index-based scrolling if GlobalKey method fails
      final int zoneIndex = _zonesViewmodel.getZoneIndex(zoneId);
      if (zoneIndex != -1) {
        _scrollToZone(zoneIndex);
      }
    }
  }

  /// Fallback scroll method using zone index
  void _scrollToZone(int zoneIndex) {
    if (_zonesScrollController.hasClients) {
      // Calculate the position of the zone
      final double zoneHeaderHeight = 32.0; // Height of zone header
      final double estimatedPosition = zoneIndex * zoneHeaderHeight;

      // Add some padding and scroll to the estimated position
      _zonesScrollController.animateTo(
        (estimatedPosition - 50.0).clamp(0.0, _zonesScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {
        /// Sync all cubits when ProjectViewModel state changes
        context.read<ConfigSourcesViewmodel>().syncWithProjectViewModel();
        context.read<ConfigSourceSetsViewmodel>().syncWithProjectViewModel();
        context.read<ConfigZonesViewmodel>().syncWithProjectViewModel();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryBlack,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;

            if (isWideScreen) {
              return Row(
                children: <Widget>[
                  SizedBox(width: constraints.maxWidth * 0.3, child: _buildInputPanel(context)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildOutputPanel()),
                ],
              );
            } else {
              return Column(
                children: <Widget>[
                  Expanded(flex: 1, child: _buildInputPanel(context)),
                  Expanded(flex: 2, child: _buildOutputPanel()),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// Build Input Panel
  Widget _buildInputPanel(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.inputspan),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          children: <Widget>[
            /// Sources Section
            const SourcesSection(),

            /// Draggable divider
            DragDivider(onDragUpdate: _updateSourcesHeight),

            /// Sources Sets Section
            const SourceSetSection(),
          ],
        ),
      ),
    );
  }

  /// Build Output Panel
  Widget _buildOutputPanel() {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        FusionTestKeys.instance.zonesec,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.primaryBlack,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border(
            left: BorderSide(color: context.colorScheme.elevation2, width: 1),
            right: BorderSide(color: context.colorScheme.elevation2, width: 1),
            bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
          ),
        ),
        child: Column(
          children: <Widget>[
            /// Zones Section
            SectionHeader(
              semanticLabel: FusionTestKeys.instance.zonehead,
              title: 'Zones',
              assetPath: 'assets/images/zone_icon.png',
            ),

            /// Zones List
            Expanded(
              child: BlocBuilder<ConfigZonesViewmodel, ConfigZonesState>(
                builder: (BuildContext context, ConfigZonesState state) {
                  return state.zones.isEmpty
                      ? SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.zoneempty),
                        child: Padding(
                          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
                          child: FusionAppText(
                            text: 'No zones added yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      : SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.zonedata),
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          controller: _zonesScrollController,
                          child: ReorderableListView.builder(
                            proxyDecorator: (Widget child, int index, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation.drive(Tween<double>(begin: 0.95, end: 1.0)),
                                child: Material(
                                  color: context.colorScheme.primaryBlack,
                                  child: SizedBox(
                                    width: 220,
                                    // child: child,
                                    child: MultiBlocProvider(
                                      providers: <BlocProvider<dynamic>>[
                                        BlocProvider<ConfigZonesViewmodel>.value(value: _zonesViewmodel),
                                        BlocProvider<ConfigSourcesViewmodel>.value(value: _sourcesViewmodel),
                                        BlocProvider<ConfigSourceSetsViewmodel>.value(value: _sourceSetsViewmodel),
                                      ],
                                      child: child,
                                    ),
                                  ),
                                ),
                              );
                            },
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: state.zones.length,
                            onReorder: (int oldIndex, int newIndex) {
                              _zonesViewmodel.reorderZones(oldIndex, newIndex);
                            },
                            itemBuilder: (BuildContext context, int index) {
                              final Zone zoneData = state.zones[index];

                              // Ensure we have a GlobalKey for each zone
                              _zoneKeys[zoneData.id] ??= GlobalKey();
                              final GlobalKey zoneKey = _zoneKeys[zoneData.id]!;

                              return ReorderableDragStartListener(
                                key: ValueKey<String>(zoneData.id),
                                index: index,
                                child: ZoneCard(
                                  index: index,
                                  key: zoneKey,
                                  zoneId: zoneData.id,
                                  zoneName: zoneData.name,
                                  bgColor: zoneData.color,
                                  zoneData: zoneData,
                                  onExpansionChanged: (bool isExpanded) {
                                    if (isExpanded) {
                                      // Small delay to allow the widget to expand first
                                      Future<void>.delayed(const Duration(milliseconds: 100), () {
                                        _scrollZoneIntoView(zoneData.id);
                                      });
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
