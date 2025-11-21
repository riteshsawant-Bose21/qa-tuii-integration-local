import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

import '../../../../core/models/products_data.dart';

class ProductsSidebar extends StatefulWidget {
  /// Sidebar width
  final double width;

  /// Data lists for each section
  final List<SpeakerData> speakers;
  final List<SourceData> sources;
  final List<ControllerData> controllers;
  final List<RackData> racks;

  /// Callbacks
  final ValueChanged<SpeakerData>? onSpeakerSelected;
  final ValueChanged<SpeakerData>? onAutoPlaceRequested;
  final ValueChanged<Source>? onSourceSelected;
  final ValueChanged<HardwareComponent>? onProductSelected;

  const ProductsSidebar({
    super.key,
    this.width = 240,
    this.speakers = SpeakerData.demoSpeakers,
    this.sources = SourceData.demoSources,
    this.controllers = ControllerData.demoControllers,
    this.racks = RackData.demoRacks,
    this.onSpeakerSelected,
    this.onAutoPlaceRequested,
    this.onProductSelected,
    this.onSourceSelected,
  });

  @override
  ProductsSidebarState createState() => ProductsSidebarState();
}

class ProductsSidebarState extends State<ProductsSidebar> {
  final Map<String, bool> _isExpanded = <String, bool>{
    'Speakers': true,
    'Sources': false,
    'Controllers': false,
    'Racks': false,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
      child: ListView(
        children:
            _isExpanded.entries.map((MapEntry<String, bool> entry) {
              final String section = entry.key;
              final bool open = entry.value;
              Widget content;
              switch (section) {
                case 'Speakers':
                  content = _buildSpeakersSection();
                  break;
                case 'Sources':
                  content = _buildSourcesSection();
                  break;
                case 'Controllers':
                  content = _buildControllersSection();
                  break;
                case 'Racks':
                  content = _buildRacksSection();
                  break;
                default:
                  content = const SizedBox.shrink();
              }
              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey<String>(section),
                  title: Text(section, style: const TextStyle(fontSize: 12)),
                  trailing: Icon(open ? Icons.remove : Icons.add),
                  initiallyExpanded: open,
                  onExpansionChanged: (bool v) => setState(() => _isExpanded[section] = v),
                  children: <Widget>[content],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSpeakersSection() {
    return _buildGrid<SpeakerData>(
      items: widget.speakers,
      onTap: widget.onSpeakerSelected,
      onSecondaryTap: widget.onAutoPlaceRequested,
      imageExtractor: (SpeakerData d) => d.assetPath,
      labelExtractor: (SpeakerData d) => d.name,
    );
  }

  Widget _buildSourcesSection() {
    return _buildGrid<SourceData>(
      items: widget.sources,
      onTap: (SourceData d) {
        widget.onSourceSelected?.call(
          Source(
            name: d.name,
            pos: Offset.zero,
            assetImagePath: d.assetPath,
            locationEntity: LocationModel(),
            type: d.type,
            connectionType: d.connectionType,
            sku: d.id,
            price: d.price,
          ),
        );
      },
      imageExtractor: (SourceData d) => d.assetPath,
      labelExtractor: (SourceData d) => d.name,
    );
  }

  Widget _buildControllersSection() {
    return _buildGrid<ControllerData>(
      items: widget.controllers,
      onTap: (ControllerData d) {
        widget.onProductSelected?.call(
          FusionController(
            name: d.name,
            pos: Offset.zero,
            assetImagePath: d.assetPath,
            locationEntity: LocationModel(),
            price: d.price,
          ),
        );
      },
      imageExtractor: (ControllerData d) => d.assetPath,
      labelExtractor: (ControllerData d) => d.name,
    );
  }

  Widget _buildRacksSection() {
    return _buildGrid<RackData>(
      items: widget.racks,
      onTap: (RackData d) {
        widget.onProductSelected?.call(
          GenericHardwareComponent(
            name: d.name,
            pos: Offset.zero,
            type: GenericHardwareComponentType.rack,
            assetImagePath: d.assetPath,
            locationEntity: LocationModel(),
            price: d.price,
          ),
        );
      },
      imageExtractor: (RackData d) => d.assetPath,
      labelExtractor: (RackData d) => d.name,
    );
  }

  Widget _buildGrid<T>({
    required List<T> items,
    ValueChanged<T>? onTap,
    ValueChanged<T>? onSecondaryTap,
    required String Function(T) imageExtractor,
    required String Function(T) labelExtractor,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext ctx, int i) {
        final T item = items[i];
        return InkWell(
          onTap: () => onTap?.call(item),
          onSecondaryTapDown: (TapDownDetails details) {
            if (onSecondaryTap != null && item is SpeakerData) {
              showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                ),
                items: const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(value: 'auto', child: Text('Auto Place')),
                ],
              ).then((String? choice) {
                if (choice == 'auto') {
                  onSecondaryTap(item);
                }
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                Expanded(child: Image.asset(imageExtractor(item), fit: BoxFit.contain)),
                const SizedBox(height: 4),
                Text(labelExtractor(item), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
