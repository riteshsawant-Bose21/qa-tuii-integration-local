import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/location_entity.dart';
import 'package:fusion_launcher/core/models/products_data.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/models/floor_entity.dart';
import '../../../../../core/models/source_entity.dart';
import 'source_widget.dart';

class SourceOptions {
  final String name;
  final SourceType type;
  final String assetImagePath;

  SourceOptions({required this.name, required this.type, required this.assetImagePath});
}

class SourcesColumn extends StatefulWidget {
  final List<Source> sources;
  final void Function(Source) onSourceChanged;
  final void Function(Source) onSourceDeleted;
  final void Function(Source) onSourceAdded;
  final void Function(Floor) onFloorUpdated;
  final void Function(Floor) onFloorAdded;
  final bool isControlMode;

  const SourcesColumn({
    super.key,
    required this.sources,
    required this.onSourceChanged,
    required this.onSourceDeleted,
    required this.onSourceAdded,
    required this.onFloorUpdated,
    required this.onFloorAdded,
    required this.isControlMode,
  });

  @override
  State<SourcesColumn> createState() => _SourcesColumnState();
}

class _SourcesColumnState extends State<SourcesColumn> {
  @override
  void didUpdateWidget(covariant SourcesColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize the state if the sources list changes
    if (oldWidget.sources != widget.sources) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppLayout.sectionWidth,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _header(),
          Divider(
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.input_sharp,
                size: 18,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Sources',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          if (!widget.isControlMode)
            PopupMenuButton<SourceData>(
              tooltip: 'Add Source',
              onSelected: (SourceData selectedBlock) {
                final Source source = Source(
                  name: selectedBlock.name,
                  pos: null,
                  type: selectedBlock.type,
                  assetImagePath: selectedBlock.assetPath,
                  locationEntity: LocationEntity(),
                  sku: selectedBlock.id,
                  price: selectedBlock.price,
                );
                _addSource(source);
              },
              color: Colors.white,
              itemBuilder: (BuildContext context) {
                return SourceData.demoSources.map((SourceData block) {
                  return PopupMenuItem<SourceData>(
                    value: block,
                    child: Row(
                      children: <Widget>[
                        Image.asset(
                          block.assetPath,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(block.name),
                      ],
                    ),
                  );
                }).toList();
              },
              child: IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
                onPressed: null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (widget.sources.isEmpty) {
      return const Center(
        child: Text(
          'No sources added\nClick + to add',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      itemCount: widget.sources.length,
      itemBuilder: (BuildContext ctx, int i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SourceWidget(
            key: ValueKey<String>(widget.sources[i].id),
            source: widget.sources[i],
            isControlMode: widget.isControlMode,
            onSourceChanged: (Source s) => _updateSource(s),
            onDelete: () => _deleteSource(widget.sources[i]),
            onFloorUpdated: (Floor floorEntity) {
              widget.onFloorUpdated(floorEntity);
            },
            onFloorAdded: (Floor newFloor) {
              widget.onFloorAdded(newFloor);
            },
          ),
        );
      },
    );
  }

  void _addSource(Source source) {
    widget.onSourceAdded(source);
  }

  void _updateSource(Source s) {
    print("called updated sources");
    widget.onSourceChanged(s);
  }

  void _deleteSource(Source source) {
    widget.onSourceDeleted(source);
  }
}
